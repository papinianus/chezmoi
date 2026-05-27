{ ... }:

{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      cleanup = "none";
      upgrade = true;
    };

    brews = [
      "mas"
    ];

    casks = [
      "aquaskk"
      "arc"
      "claude"
      "claude-code@latest"
      "codex"
      "codex-app"
      "discord@canary"
      "firefox@nightly"
      "flux-app"
      "ghostty"
      "google-chrome@canary"
      "slack@beta"
      "thebrowsercompany-dia"
    ];

    masApps = {
      Amphetamine = 937984704;
      Xcode = 497799835;
    };
  };
}
