{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption literalExpression;
  inherit (lib.types) package;

  cfg = config.programs.steam-aarch64;
in
{
  options.programs.steam-aarch64 = {
    enable = mkEnableOption "the native arm64 Steam client";

    package = mkOption {
      type = package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = literalExpression "pkgs.callPackage ./package.nix { }";
      description = "The arm64 Steam package to use.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.programs.steam.enable;
        message = "programs.steam-aarch64 and programs.steam both provide `steam`, please only enable one.";
      }
      {
        assertion = pkgs.stdenv.hostPlatform.isAarch64;
        message = "programs.steam-aarch64 is only supported on aarch64-linux.";
      }
    ];

    hardware.graphics.enable = true;

    environment.systemPackages = [
      cfg.package
      cfg.package.run
    ];
  };
}
