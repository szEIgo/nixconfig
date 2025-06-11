{ lib, config, ... }:

let
  inherit (lib) attrValues hasPrefix hasSuffix mapAttrsToList;

  collectConfigsRecursively = dir:
    let
      entries = builtins.readDir dir;
      mapped = mapAttrsToList (name: type:
        let
          fullPath = dir + "/${name}";
        in
          if type == "directory" then
            collectConfigsRecursively fullPath
          else
            [{
              name = lib.removePrefix "./" (toString fullPath);
              value = { source = fullPath; };
            }]
      ) entries;
    in builtins.concatLists mapped;

  # Adjust this path to where you store your Plasma configs
  plasmaDir = ./configs/plasma6;

  plasmaFiles = collectConfigsRecursively plasmaDir;

  plasmaAttrs = builtins.listToAttrs (map (entry: {
    name = ".config/" + lib.removePrefix "configs/plasma6/" entry.name;
    inherit (entry) value;
  }) plasmaFiles);

in {
  config = lib.mkIf config.plasmaEnabled {
    home.file = plasmaAttrs;
  };
}
