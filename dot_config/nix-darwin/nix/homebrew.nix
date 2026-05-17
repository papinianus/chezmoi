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
      "firefox@nightly"
      "google-chrome@canary"
    ];

    masApps = {
      Amphetamine = 937984704;
      Xcode = 497799835;
    };
  };
}
