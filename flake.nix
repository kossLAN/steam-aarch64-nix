{
  description = "Native arm64 Steam desktop client for NixOS";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "aarch64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      packages.${system} = {
        steam-aarch64 = pkgs.callPackage ./package.nix { };
        default = self.packages.${system}.steam-aarch64;
      };

      overlays.default = final: _prev: {
        steam-aarch64 = final.callPackage ./package.nix { };
      };

      nixosModules = {
        steam-aarch64 = ./module.nix;
        default = self.nixosModules.steam-aarch64;
      };

      formatter.${system} = pkgs.nixfmt-tree;
    };
}
