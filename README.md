# steam-aarch64-nix

The native arm64 Steam desktop client on NixOS (`aarch64-linux`).

It uses the arm64 Steam client that Valve ships for the Steam Frame and runs it as the regular desktop client inside the nixpkgs Steam FHS environment. This means it include compatibility tools for running steam games through FEX all in the client. 

## Usage

Add the flake as an input and import the module:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    steam-aarch64 = {
      url = "github:kossLAN/steam-aarch64-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, steam-aarch64, ... }:
    {
      nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          steam-aarch64.nixosModules.default
          ./configuration.nix
        ];
      };
    };
}
```

Then enable it in your configuration:

```nix
{
  programs.steam-aarch64.enable = true;

  # Steam is unfree
  nixpkgs.config.allowUnfree = true;
}
```
