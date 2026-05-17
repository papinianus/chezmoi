{
  pkgs,
  username,
  ...
}:

{
  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
    stateVersion = "25.05";

    packages = with pkgs; [
      bat
      chezmoi
      fd
      fzf
      gh
      ghq
      gibo
      jq
      mise
      peco
      podman
      ripgrep
      tree
      wget
      yq
      zoxide
    ];
  };

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };
}
