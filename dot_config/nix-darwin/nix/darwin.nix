{
  pkgs,
  username,
  ...
}:

{
  imports = [
    ./packages.nix
  ];

  # Determinate Nix manages the daemon and nix.conf.
  nix.enable = false;

  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
    overlays = import ./overlays.nix;
  };

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  programs.zsh.enable = true;

  environment.shells = [
    pkgs.zsh
  ];

  environment.etc."zshrc.local".text = ''
    if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
  '';

  system = {
    primaryUser = username;
    stateVersion = 6;

    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
      };

      dock = {
        autohide = true;
        mru-spaces = false;
        show-recents = false;
      };

      finder = {
        AppleShowAllFiles = true;
        FXDefaultSearchScope = "SCcf";
        FXPreferredViewStyle = "Nlsv";
        ShowPathbar = true;
        ShowStatusBar = true;
      };
    };
  };
}
