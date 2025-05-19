{
  services = {
    aerospace = {
      enable = false;
      settings = builtins.fromTOML (builtins.readFile ./.aerospace.toml);
    };
  };
}
