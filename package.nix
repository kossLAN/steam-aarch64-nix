{
  lib,
  steam,
  steam-unwrapped,
  buildFHSEnv,
  fetchurl,
  runCommand,
  writeShellScript,
  zstd,
}:
let
  version = "r1790377368+bffc849f";

  client = fetchurl {
    pname = "deckard-steam-rel";
    inherit version;
    url = "https://steamdeck-packages.steamos.cloud/archlinux-deckard-hotfixes/release/0.4.x/deckard-steam-rel-${lib.escapeURL version}-1-aarch64.pkg.tar.zst";
    hash = "sha256-pa/nEtT4cMOFycFkE1vc37TmMDgKj8lCgWpAYJEQsRo=";
  };

  bootstrap =
    runCommand "steam-aarch64-bootstrap.tar.zst"
      {
        nativeBuildInputs = [ zstd ];
      }
      ''
        tar -xOf ${client} usr/lib/steam/steam.tar.zst > $out
      '';

  launcher = writeShellScript "steam" ''
    steamroot="$HOME/.local/share/Steam"
    client="$steamroot/steamrtarm64"

    if [[ ! -x "$client/steam" ]]; then
      mkdir -p "$steamroot"
      tar --zstd -xf ${bootstrap} -C "$steamroot"
    fi

    mkdir -p ~/.steam
    ln -sfnT "$steamroot" ~/.steam/steam
    ln -sfnT "$steamroot" ~/.steam/root
    ln -sfnT "$steamroot/linux32" ~/.steam/sdk32
    ln -sfnT "$steamroot/linux64" ~/.steam/sdk64
    ln -sfnT "$steamroot/linuxarm64" ~/.steam/sdkarm64
    ln -sfnT "$steamroot/ubuntu12_32" ~/.steam/bin32
    ln -sfnT "$steamroot/ubuntu12_64" ~/.steam/bin64
    ln -sfnT "$client" ~/.steam/binarm64

    export LD_LIBRARY_PATH="$client"

    export STEAM_RUNTIME="$steamroot/ubuntu12_32/steam-runtime"
    fex="$steamroot/steamapps/common/FEX-Emu/fex-compat-tool"
    if [[ -x "$fex" ]]; then
      export STEAM_RUNTIME_LIBRARY_PATH="$("$fex" run -- "$STEAM_RUNTIME/run.sh" --print-steam-runtime-library-paths)"
    fi

    cd "$steamroot"
    while true; do
      "$client/steam" "$@"
      status=$?

      if (( status != 42 )); then
        exit "$status"
      fi
    done
  '';

  unwrapped = steam-unwrapped.overrideAttrs (old: {
    pname = "steam-aarch64-unwrapped";

    postInstall = (old.postInstall or "") + ''
      rm $out/lib/steam/{bin_steam.sh,bootstraplinux_ubuntu12_32.tar.xz}
      ln -sf ${launcher} $out/bin/steam
    '';

    meta = old.meta // {
      platforms = [ "aarch64-linux" ];
    };
  });
in
steam.override {
  steam-unwrapped = unwrapped;

  # glibc_multi only exists on x86_64-linux
  buildFHSEnv =
    args:
    buildFHSEnv (
      args
      // {
        targetPkgs = pkgs: args.targetPkgs (pkgs // { glibc_multi = pkgs.glibc; });
      }
    );

  extraPkgs =
    pkgs: with pkgs; [
      lsof
      util-linux
      xwininfo
      zstd
    ];

  # The arm64 client uses host libraries rather than the steam runtime
  extraLibraries =
    pkgs: with pkgs; [
      alsa-lib
      cups
      gtk2
      ibus
      libasyncns
      libice
      libpulseaudio
      libsm
      libuuid
      libvdpau
      libxcomposite
      libxdamage
      libxfixes
      libxinerama
      libxkbcommon
      libxtst
      nss
      openal
      pipewire
      SDL2
      systemdLibs
    ];
}
