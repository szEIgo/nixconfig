# K8s Cluster Build Plan — 25,000 DKK Budget

**Date:** 2026-04-09
**Goal:** Maximum bang-for-buck Kubernetes worker nodes in rack form factor

---

## Recommended Build: 7x Cisco UCS C220 M4

| Spec | Value |
|------|-------|
| **Nodes** | 7 |
| **Total cores** | 280 cores / 560 threads |
| **RAM per node** | 64 GB |
| **Total cluster RAM** | 448 GB |
| **Form factor** | 1U each (7U total rack space) |
| **Estimated total** | ~€3,255 (~24,280 DKK) |

---

## Shopping List

### From Renewtech (Denmark) — [renewtech.com](https://www.renewtech.com)

Configure 7x servers here: [Cisco UCS C220 M4 Configurator](https://www.renewtech.com/servers/cisco-ucs-c220-m4.html)

| Item | Qty | Unit Price | Total |
|------|-----|-----------|-------|
| Cisco C220 M4 SFF chassis (barebones) | 7 | €140 | €980 |
| Intel Xeon E5-2698v4 (20C/40T, 2.2GHz) | 14 | €77 | €1,078 |
| 12G SAS Modular RAID Controller | 7 | €21 | €147 |
| 300GB 15K SAS HDD (boot drive) | 7 | €28 | €196 |
| **Subtotal** | | | **€2,401** |

> **Note:** The configurator shows a "32GB RDIMM Samsung" at €0 — ask Renewtech if this is real before ordering. If it is, select 2x per node for 64GB free RAM and skip the eBay RAM purchase.

### From eBay DE — [ebay.de](https://www.ebay.de)

| Item | Search Link | Qty | Unit Price | Total |
|------|------------|-----|-----------|-------|
| 16GB DDR4-2400 ECC RDIMM | [Search eBay DE](https://www.ebay.de/sch/i.html?_nkw=DDR4+16GB+2400+ECC+RDIMM&_sop=15&LH_BIN=1) | 28 | ~€20 | ~€560 |
| Cisco UCSC-PSU1-770W PSU | [Search eBay DE](https://www.ebay.de/sch/i.html?_nkw=UCSC-PSU1-770W&_sop=15&LH_BIN=1) | 14 | ~€21 | ~€294 |
| **Subtotal** | | | | **~€854** |

### Optional Extras

| Item | Search Link | Qty | Est. Price |
|------|------------|-----|-----------|
| Cisco C220 M4 Rail Kit | [Search eBay DE](https://www.ebay.de/sch/i.html?_nkw=cisco+c220+m4+rail+kit&LH_BIN=1) | 7 | ~€20-30 each |
| Mellanox ConnectX-3 10GbE SFP+ (if needed) | [Search eBay DE](https://www.ebay.de/sch/i.html?_nkw=mellanox+connectx-3+10gbe+sfp%2B&_sop=15&LH_BIN=1) | 7 | ~€20-30 each |

---

## CPU Choice Rationale

The E5-2698v4 offers the best cores-per-euro at this budget level:

| CPU | Cores | GHz | Price (Renewtech) | 2x/node | Cores/node | 7-node total cores |
|-----|-------|-----|--------------------|---------|------------|--------------------|
| E5-2690v4 | 14 | 2.6 | €28 | €56 | 28 | 196 |
| E5-2697v4 | 18 | 2.3 | €63 | €126 | 36 | 252 |
| **E5-2698v4** | **20** | **2.2** | **€77** | **€154** | **40** | **280** |
| E5-2699v4 | 22 | 2.2 | €126 | €252 | 44 | 308 (over budget) |

---

## Alternative Configurations

### Option A: Fewer nodes, more RAM (128GB each)

| Nodes | CPU | Cores | RAM/node | Total RAM | Total Cost |
|-------|-----|-------|----------|-----------|------------|
| 6 | 2x E5-2698v4 | 240 | 128GB | 768GB | ~€3,270 |

### Option B: Maximum nodes, less RAM (32GB each)

| Nodes | CPU | Cores | RAM/node | Total RAM | Total Cost |
|-------|-----|-------|----------|-----------|------------|
| 8 | 2x E5-2690v4 | 224 | 32GB | 256GB | ~€2,936 |

### Option C: Complete servers (no assembly)

| Server | Store | CPU | Cores | RAM | Price | Link |
|--------|-------|-----|-------|-----|-------|------|
| Dell R730xd | ServerShop24 | 2x E5-2690v4 | 28 | 32GB | €571 | [servershop24.de](https://www.servershop24.de/en/server/) |
| HPE DL380 Gen10 | ServerShop24 | 2x Gold 6138 | 40 | 32GB | €891 | [servershop24.de](https://www.servershop24.de/en/server/) |

---

## European Refurb Stores — Full List

### Stores with Best Prices

| Store | Country | Specialty | Warranty | Link |
|-------|---------|-----------|----------|------|
| **Renewtech** | Denmark | Servers, CPUs, configurator | Standard | [renewtech.com](https://www.renewtech.com) |
| **ServerShop24** | Germany | Complete servers, components | Standard | [servershop24.de](https://www.servershop24.de/en/) |
| **Intelligent Servers** | UK | AMD EPYC, servers | 3 years | [intelligentservers.co.uk](https://intelligentservers.co.uk) |
| **GEKKO Computer** | Germany (Berlin) | Servers, same-day shipping | 12 months | [gekko-computer.de](https://www.gekko-computer.de/en/) |
| **Bargain Hardware** | UK | Rack servers, also on eBay | 90 days | [bargainhardware.co.uk](https://www.bargainhardware.co.uk) |
| **Epoka** | Denmark | Intel CPUs | Standard | [epoka.com](https://epoka.com/collections/intel-processors-cpu) |
| **Servermall** | Lithuania | Complete servers, EU-wide | Up to 5 years | [servermall.com](https://servermall.com) |

### Best AMD EPYC Deals (for future reference)

| CPU | Cores | GHz | Store | Price | Per Core | Link |
|-----|-------|-----|-------|-------|----------|------|
| EPYC 7301 | 16 | 2.2 | Renewtech | €28 | €1.75 | [renewtech.com/amd](https://www.renewtech.com/amd/cpu-processors-vrm.html) |
| EPYC 7351 | 16 | 2.4 | Intelligent Servers | £48 | ~€3.50 | [intelligentservers.co.uk/amd-processors](https://intelligentservers.co.uk/amd-processors) |
| EPYC 7402 | 24 | 2.8 | Renewtech | €140 | €5.83 | [renewtech.com/amd](https://www.renewtech.com/amd/cpu-processors-vrm.html) |
| EPYC 7402 | 24 | 2.8 | Intelligent Servers | £120 | ~€5.83 | [intelligentservers.co.uk/amd-processors](https://intelligentservers.co.uk/amd-processors) |
| EPYC 7352 | 24 | 2.3 | Intelligent Servers | £115 | ~€5.58 | [intelligentservers.co.uk/amd-processors](https://intelligentservers.co.uk/amd-processors) |
| EPYC 7452 | 32 | 2.35 | Intelligent Servers | £241 | ~€8.78 | [intelligentservers.co.uk/amd-processors](https://intelligentservers.co.uk/amd-processors) |
| EPYC 7452 | 32 | 2.35 | Renewtech | €490 | €15.31 | [renewtech.com/amd](https://www.renewtech.com/amd/cpu-processors-vrm.html) |
| EPYC 7552 | 48 | 2.2 | Renewtech | €630 | €13.13 | [renewtech.com/amd](https://www.renewtech.com/amd/cpu-processors-vrm.html) |
| EPYC 7763 | 64 | 2.45 | Renewtech | €1,519 | €23.73 | [renewtech.com/amd](https://www.renewtech.com/amd/cpu-processors-vrm.html) |

### Best Intel Xeon Deals

| CPU | Cores | GHz | Store | Price | Per Core | Link |
|-----|-------|-----|-------|-------|----------|------|
| Xeon Platinum 8176 | 28 | 2.1 | ServerShop24 | €126 | €4.50 | [servershop24.de](https://www.servershop24.de/en/components/cpus-processors/intel/) |
| Xeon Gold 6148 | 20 | 2.4 | ServerShop24 | €63 | €3.15 | [servershop24.de](https://www.servershop24.de/en/components/cpus-processors/intel/) |
| Xeon E5-2620v4 | 8 | 2.1 | ServerShop24 | €17 | €2.10 | [servershop24.de](https://www.servershop24.de/en/components/cpus-processors/intel/) |

---

## Important Notes

1. **PSU shipping** — Buy from German eBay sellers to avoid UK post-Brexit customs
2. **Power draw** — Expect ~100-120W idle per node (~700-840W total for 7 nodes)
3. **Networking** — Onboard 1GbE included; 10GbE optional via Mellanox cards
4. **RAM compatibility** — C220 M4 supports DDR4-2400 and DDR4-2133 ECC RDIMMs; max 24 DIMM slots (1.5TB max)
5. **The Samsung €0 RAM** — Contact Renewtech before ordering to verify if this is a real option or a website error
6. **EPYC alternative** — If you later want to switch to AMD EPYC, you'd need SP3 socket motherboards (~€200-300 used) + different chassis. The Cisco path is cheaper overall for this budget.

---

## Per-Node Spec Summary

```
Server:    Cisco UCS C220 M4 SFF (1U rackmount)
CPU:       2x Intel Xeon E5-2698v4 (20C/40T @ 2.2GHz, Broadwell)
RAM:       64GB DDR4-2400 ECC (4x 16GB RDIMM)
Storage:   1x 300GB 15K SAS
Network:   Onboard 1GbE (upgrade to 10GbE optional)
PSU:       2x 770W redundant hot-swap
```
