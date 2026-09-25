profile: {
  config,
  lib,
  pkgs,
  ...
}: let
  # A GUI app launched from the Dock/Finder/Spotlight inherits its PATH from the
  # user's launchd domain, whose built-in default is only
  # /usr/bin:/bin:/usr/sbin:/sbin -- so sioyek cannot find anything from nix or
  # homebrew when it shells out. See fuckedup.md. Rather than widening the PATH
  # for the whole launchd domain, bake it into sioyek's own wrapper.
  defaultPath = "/usr/bin:/bin:/usr/sbin:/sbin";

  sioyekPath = ":/usr/local/bin";

  sioyek = pkgs.sioyek.overrideAttrs (old: {
    # nixpkgs installs sioyek's shaders and default configs into the app bundle's
    # Contents/MacOS, but sioyek looks them up under Contents/Resources, so every
    # page renders blank without this.
    postInstall =
      old.postInstall
      + ''
        resources=$out/Applications/sioyek.app/Contents/Resources
        mkdir -p $resources
        cp -r pdf_viewer/shaders $resources/shaders
        cp pdf_viewer/{prefs,keys}.config tutorial.pdf $resources/
      '';

    # sioyek is a Qt app, so wrapQtAppsHook already replaces
    # Contents/MacOS/sioyek with a makeBinaryWrapper that sets QT_PLUGIN_PATH and
    # execs .sioyek-wrapped. qtWrapperArgs appends to that same wrapper, so this
    # costs no extra layer and applies however the app is started -- Dock, Finder,
    # `open`, aerospace or straight from a shell.
    #
    # --prefix, not --set: whatever PATH the launcher provided is kept as the
    # tail, so /usr/bin and friends survive.
    qtWrapperArgs =
      (old.qtWrapperArgs or [])
      ++ [
        "--prefix PATH : ${defaultPath}:${sioyekPath}"
      ];
  });
in {
  environment.systemPackages = [
    pkgs.duti
    sioyek
    pkgs.uv
  ];

  # https://github.com/nix-darwin/nix-darwin/issues/663
  # https://github.com/nix-darwin/nix-darwin/blob/0fc4e7ac670a0ed874abacf73c4b072a6a58064b/modules/system/activation-scripts.nix#L118
  system.activationScripts = {
    # separate this out into its own moduel, e.g. register-default-app module
    # https://github.com/nix-darwin/nix-darwin/issues/1506
    # Setting default apps using nix-darwin is currently not implemented.
    # So this:
    postActivation.text = ''
      set -euo pipefail

      function set_default_app() {
        local target_bundle_id="$1"
        local uti="$2"
        local target_user="$3"

        current_default_app=$(sudo -u "$target_user" ${pkgs.duti}/bin/duti -d "$uti" || true)
        if [ "$current_default_app" != "$target_bundle_id" ]; then
          sudo -u "$target_user" ${pkgs.duti}/bin/duti -s "$target_bundle_id" "$uti" all
        fi
      }

      tuples=(
        "info.sioyek.sioyek:com.adobe.pdf"
        "com.microsoft.VSCode:public.plain-text"
        "com.microsoft.VSCode:public.source-code"
        "com.microsoft.VSCode:public.data"
      )

      for t in "''${tuples[@]}"; do
        bundle_id="''${t%%:*}"
        uti="''${t#*:}"
        set_default_app "$bundle_id" "$uti" "${profile.userName}"
      done
    '';
  };
}
