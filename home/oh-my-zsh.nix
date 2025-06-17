{ lib, config, omzEnabled ? false, ... }:

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

  omzDir = ./configs/ohmyzsh;

  omzFiles = collectConfigsRecursively omzDir;

  omzAttrs = builtins.listToAttrs (map (entry: {
    name = ".config/" + lib.removePrefix (toString omzDir + "/") entry.name;
    inherit (entry) value;
  }) omzFiles);

in {
  config = lib.mkIf omzEnabled {
    home.file = omzAttrs;
  };
}
