# nix-click

Nix infrastructure to build click packages for Ubuntu Touch

## How to build an application

1. Install nix: [nixos.org/download](https://nixos.org/download.html)
2. Enable flakes: [nixos.wiki/wiki/Flakes](https://nixos.wiki/wiki/Flakes#Enable_flakes)
3. Build the package by running the following command in the directory of this project:
	 ```shell
	 nix build
	 ```
4. A symlink `result` will be created with the built click packages

## How to change the package being built

1. Find a package already packaged for nix: [search.nixos.org/packages](https://search.nixos.org/packages)
2. Replace `gnome.gnome-weather` in the `exec` field of the `flake.nix` file with the package you found in the previous step
3. Change other attributes like package name, title and version as necessary
4. Build the package
