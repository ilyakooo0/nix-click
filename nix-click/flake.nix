{
  description = "Flake utils demo";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nix-bundle = {
      url =
        "github:ilyakooo0/nix-bundle?rev=db4b8ca5af5ccdb3a4ff8be4a2390fecc7c58134";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, nix-bundle }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        packages = rec {
          buildAll = { name, supportedPlatforms ? {
            arm64 = true;
            amd64 = false;
            armhf = false;
          } }:
            f:
            let
              f_ = { arch, staticPkgs, targetSystem }:
                let args = f staticPkgs;
                in if args == null || !(supportedPlatforms ? ${arch})
                || supportedPlatforms.${arch} == null
                || !supportedPlatforms.${arch} then
                  null
                else {
                  name = "${arch}.click";
                  path = build (args // {
                    manifest = args.manifest // { architecture = arch; };
                    inherit targetSystem;
                  });
                };
            in pkgs.linkFarm name (builtins.filter (x: x != null) (builtins.map
              (args:
                let res = builtins.tryEval (f_ args);
                in if res.success then res.value else null) [{
                  arch = "arm64";
                  staticPkgs = (import nixpkgs { system = "aarch64-linux"; });
                  targetSystem = "aarch64-linux";
                }
                {
                  arch = "armhf";
                  staticPkgs = (import nixpkgs { system = "armv7l-linux"; });
                  targetSystem = "armv7l-linux";
                }
                {
                  arch = "amd64";
                  staticPkgs = (import nixpkgs { system = "x86_64-linux"; });
                  targetSystem = "x86_64-linux";
                }
              ]));
          build = { targetSystem, exec, contents ? [ ], manifest ? null
            , apparmor, icon ? ./icon.svg }:
            let
              contentsList = if builtins.typeOf contents == "list" then
                contents
              else
                [ contents ];
              getObj = src: arg:
                if arg == null then
                # should be read from src
                  builtins.fromJSON (builtins.readFile src)
                else
                # specified as an argument
                if builtins.typeOf arg == "path" then
                  builtins.fromJSON (builtins.readFile manifest)
                else if builtins.typeOf arg == "set" then
                  arg
                else
                  builtins.throw "Could not read ${src}";
              desktopName = "${manifestObjectRaw.name}.desktop";
              apparomrName = "${manifestObjectRaw.name}.apparmor";
              desktopFile = pkgs.writeTextFile {
                name = desktopName;
                text = ''
                  [Desktop Entry]
                  Name=${manifestObject.title}
                  Exec=nix-user-chroot -n ./nix -- ${exec}
                  Icon=${builtins.baseNameOf icon}
                  Terminal=false
                  Type=Application
                  X-Ubuntu-Touch=true
                '';
              };
              manifestObjectRaw = getObj "manifest.json" manifest;
              manifestObject = manifestObjectRaw // {
                hooks = {
                  "${manifestObjectRaw.name}" = {
                    apparmor = apparomrName;
                    desktop = desktopName;
                  };
                };
              };
              manifestFile = pkgs.writeTextFile {
                name = "manifest.json";
                text = builtins.toJSON manifestObject;
              };
              allDeps = pkgs.concatTextFile {
                name = "${manifest.name}-deps";
                files = builtins.map pkgs.writeReferencesToFile
                  (contentsList ++ [ exec ]);
              };
              targetPkgs = import nixpkgs { system = targetSystem; };
              nix-user-chroot = (import nix-bundle {
                nixpkgs = targetPkgs.pkgsStatic;
              }).nix-user-chroot.override { postFixup = ""; };
            in pkgs.runCommand "${manifest.name}-${manifest.version}.click"
            { } ''
              cat ${allDeps} | uniq >deps
              mkdir build
              while read p; do
                echo "copying $p"
                cp -r --parents $p build
              done <deps
              cp ${nix-user-chroot}/bin/nix-user-chroot build/nix-user-chroot
              cp ${apparmor} build/${apparomrName}
              cp ${desktopFile} build/${desktopName}
              cp ${manifestFile} build/manifest.json
              cp ${icon} build/${builtins.baseNameOf icon}
              chmod -R 777 build
              ${pkgs.ubports-click}/bin/click build build
              cp *.click $out
            '';
        };
      });
}
