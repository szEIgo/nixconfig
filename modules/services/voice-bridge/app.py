"""Claude Voice Bridge — WebSocket relay between browser voice and claude CLI."""

import asyncio
import json
import shutil
from pathlib import Path

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse

app = FastAPI()

CLAUDE_BIN = shutil.which("claude") or "/run/current-system/sw/bin/claude"


@app.get("/")
async def root():
    return HTMLResponse((Path(__file__).parent / "index.html").read_text())


@app.get("/health")
async def health():
    return {"status": "ok", "claude": CLAUDE_BIN}


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    session_id = None

    try:
        while True:
            data = await websocket.receive_json()

            if data.get("type") == "query":
                prompt = data["text"]
                session_id = await run_claude(websocket, prompt, session_id)

    except WebSocketDisconnect:
        pass
    except Exception as e:
        try:
            await websocket.send_json({"type": "error", "message": str(e)})
        except Exception:
            pass


async def run_claude(ws: WebSocket, prompt: str, session_id: str | None) -> str | None:
    """Run claude -p and stream output back via websocket. Returns session_id for multi-turn."""

    args = [
        CLAUDE_BIN, "-p",
        "--output-format", "stream-json",
        "--verbose",
        "--include-partial-messages",
    ]

    if session_id:
        args.extend(["--resume", session_id])

    process = await asyncio.create_subprocess_exec(
        *args,
        stdin=asyncio.subprocess.PIPE,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )

    # Send prompt via stdin
    process.stdin.write(prompt.encode())
    await process.stdin.drain()
    process.stdin.close()

    new_session_id = session_id

    # Stream stdout line-by-line
    buffer = b""
    while True:
        chunk = await process.stdout.read(4096)
        if not chunk:
            break
        buffer += chunk

        while b"\n" in buffer:
            line, buffer = buffer.split(b"\n", 1)
            line_str = line.decode().strip()
            if not line_str:
                continue

            try:
                event = json.loads(line_str)
            except json.JSONDecodeError:
                await ws.send_json({"type": "raw", "content": line_str})
                continue

            # Extract session_id from init event
            if event.get("type") == "system" and event.get("subtype") == "init":
                new_session_id = event.get("session_id", session_id)
                await ws.send_json({
                    "type": "init",
                    "session_id": new_session_id,
                    "model": event.get("model", "unknown"),
                })
                continue

            # Forward assistant messages (streaming content)
            if event.get("type") == "assistant":
                msg = event.get("message", {})
                content_blocks = msg.get("content", [])
                text_parts = [b["text"] for b in content_blocks if b.get("type") == "text"]
                if text_parts:
                    await ws.send_json({
                        "type": "assistant_text",
                        "text": "".join(text_parts),
                        "partial": msg.get("stop_reason") is None,
                    })
                # Forward tool use blocks
                tool_blocks = [b for b in content_blocks if b.get("type") == "tool_use"]
                for tb in tool_blocks:
                    await ws.send_json({
                        "type": "tool_use",
                        "name": tb.get("name", ""),
                        "input": tb.get("input", {}),
                    })
                continue

            # Forward tool results
            if event.get("type") == "tool_result":
                await ws.send_json({
                    "type": "tool_result",
                    "name": event.get("tool_name", ""),
                    "content": event.get("content", ""),
                })
                continue

            # Forward final result
            if event.get("type") == "result":
                await ws.send_json({
                    "type": "result",
                    "text": event.get("result", ""),
                    "cost": event.get("total_cost_usd"),
                    "duration_ms": event.get("duration_ms"),
                    "is_error": event.get("is_error", False),
                })
                continue

    # Handle remaining buffer
    if buffer.strip():
        try:
            event = json.loads(buffer.decode().strip())
            if event.get("type") == "result":
                await ws.send_json({
                    "type": "result",
                    "text": event.get("result", ""),
                    "cost": event.get("total_cost_usd"),
                })
        except (json.JSONDecodeError, UnicodeDecodeError):
            pass

    # Read stderr for errors
    stderr = await process.stderr.read()
    if stderr:
        err_text = stderr.decode().strip()
        if err_text:
            await ws.send_json({"type": "stderr", "content": err_text})

    await process.wait()
    await ws.send_json({"type": "done"})

    return new_session_id
