{
  description = "Flake utils demo";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nix-click.url = "./nix-click";
    nix-click.inputs.nixpkgs.url =
      "github:NixOS/nixpkgs?rev=fea42519a41102668eb215a6cb4a883a88b4b236";
  };

  outputs = { self, nixpkgs, flake-utils, nix-click }:
    flake-utils.lib.eachDefaultSystem (system: {
      packages = {
        inherit nix-click;
        default = nix-click.packages.${system}.buildAll {
          name = "yubioath";
          supportedPlatforms = {
            arm64 = true;
            amd64 = false;
            armhf = false;
          };
        } (p: {
          contents = [ ];
          exec = "${p.gnome.gnome-weather}/bin/weather";
          manifest = {
            name = "soy.iko.weather";
            version = "1.0.0";
            maintainer = "Ilia Kostiuchenko <mail@iko.soy>";
            title = "weather";
            framework = "ubuntu-sdk-20.04";
          };
          apparmor = ./example.apparmor;
        });
      };
    });
}
