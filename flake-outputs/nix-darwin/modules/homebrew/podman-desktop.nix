{lib, ...}: {
  homebrew.casks = ["podman-desktop"];

  # Podman Desktop installs the podman CLI through its own macOS installer,
  # which drops the binaries into /opt/podman/bin without linking them into
  # /usr/local/bin, so `podman` is invisible to the shell without this.
  #
  # Ordered after the nix profiles (1000) but before /usr/local/bin and friends
  # (1200), so anything nix-managed still wins.
  environment.systemPath = lib.mkOrder 1100 ["/opt/podman/bin"];
}
