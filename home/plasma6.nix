{ lib, config, plasmaEnabled ? false, ... }:

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
              name = toString fullPath;
              value = { source = fullPath; };
            }]
      ) entries;
    in builtins.concatLists mapped;

  plasmaDir = ./configs/plasma6;

  plasmaFiles = collectConfigsRecursively plasmaDir;

  plasmaAttrs = builtins.listToAttrs (map (entry: {
    name = ".config/" + lib.removePrefix (toString plasmaDir + "/") entry.name;
    inherit (entry) value;
  }) plasmaFiles);

in {
  config = lib.mkIf plasmaEnabled {
    home.file = plasmaAttrs;
  };
}
