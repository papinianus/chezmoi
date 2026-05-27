# Mac setup

新しい Apple Silicon Mac を `nix-darwin`、`home-manager`、`nix-homebrew`、`chezmoi` でセットアップする手順です。
Nix は Determinate Nix Installer で導入し、Nix daemon と `nix.conf` は Determinate 側で管理します。
nix-darwin では `nix.enable = false;` にして、Determinate Nix と競合しないようにします。

## 1. Nix をインストール

```sh
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

インストール後、案内に従って shell を開き直すか、設定を読み込みます。

```sh
exec $SHELL -l
```

Nix が使えることを確認します。

```sh
nix --version
```

Determinate Nix Installer は zsh から Nix を使えるように、通常 `/etc/zshrc` から
`/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh` を読み込みます。
このリポジトリでは `nix.enable = false;` のまま nix-darwin 管理の zsh を使うため、
`/etc/zshrc.local` から同じファイルを読み込む設定を入れています。

## 2. chezmoi を一時的に用意

このリポジトリを取得するために、まず Nix 経由で `chezmoi` を一時実行します。

```sh
DOTFILES_REPO="https://github.com/papinianus/chezmoi.git"
nix run nixpkgs#chezmoi -- init "$DOTFILES_REPO"
```

内容を確認します。

```sh
nix run nixpkgs#chezmoi -- diff
```

問題なければ適用します。

```sh
nix run nixpkgs#chezmoi -- apply
```

これで `~/.config/nix-darwin` に Nix 設定が配置されます。

## 3. nix-darwin をビルド

共通設定として `macos` を使います。

```sh
cd ~/.config/nix-darwin
sudo -H nix run 'github:LnL7/nix-darwin#darwin-rebuild' -- build --flake '.#macos'
```

## 4. nix-darwin を適用

Mac に適用します。

```sh
cd ~/.config/nix-darwin
sudo -H nix run 'github:LnL7/nix-darwin#darwin-rebuild' -- switch --flake '.#macos'
```

適用後は `darwin-rebuild` が使えるようになります。
`chezmoi` など Home Manager で入るコマンドもこの時点でインストールされますが、
現在の shell には新しい profile の PATH がまだ反映されていない場合があります。
一度 shell を開き直します。

```sh
exec $SHELL -l
```

```sh
darwin-rebuild --version
nix --version
chezmoi --version
```

以降の更新は次のコマンドで行います。

```sh
cd ~/.config/nix-darwin
sudo -H darwin-rebuild switch --flake '.#macos'
```

## 5. 適用後の確認

Homebrew Cask と Mac App Store アプリの管理対象を確認します。

```sh
brew list --cask
mas list
```

Nix / Home Manager 側のコマンドを確認します。

```sh
git --version
chezmoi --version
direnv --version
zsh --version
```

## 6. 運用

### 他の端末での更新を取り込む

他の端末で変更を push しただけでは、この Mac の `~/.config/nix-darwin` は更新されません。
まず chezmoi の source repository を更新し、実ファイルへ適用します。

```sh
cd ~/.local/share/chezmoi
git pull --ff-only
chezmoi diff
chezmoi apply
```

Nix 設定を含む変更を取り込んだ場合は、nix-darwin を再適用します。

```sh
cd ~/.config/nix-darwin
sudo -H darwin-rebuild switch --flake '.#macos'
```

一括で更新する場合は `chezmoi update` も使えます。

```sh
chezmoi update
cd ~/.config/nix-darwin
sudo -H darwin-rebuild switch --flake '.#macos'
```

### Nix パッケージを追加する

CLI ツールは `home-manager` 側に追加します。

```sh
$EDITOR ~/.config/nix-darwin/nix/home.nix
cd ~/.config/nix-darwin
sudo -H darwin-rebuild switch --flake '.#macos'
```

システム共通に必要なものだけ `nix/packages.nix` に追加します。

```sh
$EDITOR ~/.config/nix-darwin/nix/packages.nix
cd ~/.config/nix-darwin
sudo -H darwin-rebuild switch --flake '.#macos'
```

### Homebrew / App Store アプリを追加する

GUI アプリは `homebrew.casks` に追加します。Mac App Store アプリは `homebrew.masApps` に追加します。

```sh
$EDITOR ~/.config/nix-darwin/nix/homebrew.nix
cd ~/.config/nix-darwin
sudo -H darwin-rebuild switch --flake '.#macos'
```

`masApps` に追加する App ID は `mas search` で確認します。

```sh
mas search "Xcode"
```

### chezmoi の更新と push

`~/.config/nix-darwin` を変更したら chezmoi に反映します。

```sh
chezmoi add ~/.config/nix-darwin
chezmoi diff
chezmoi apply
```

リポジトリへコミットします。

```sh
cd ~/.local/share/chezmoi
git status
git add .
git commit -m "Update nix-darwin configuration"
git push
```

### Nix / Homebrew パッケージを更新する

Nix input を更新します。

```sh
cd ~/.config/nix-darwin
nix flake update
sudo -H darwin-rebuild switch --flake '.#macos'
```

Determinate Nix を使うため、nix-darwin 側では `nix.enable = false;` にしています。`nix.settings` は nix-darwin では管理しません。

Homebrew Cask、Homebrew formula、Mac App Store アプリは `darwin-rebuild switch` 時に nix-darwin の Homebrew module が更新します。

```nix
homebrew.onActivation = {
  autoUpdate = true;
  cleanup = "none";
  upgrade = true;
};
```

更新した `flake.lock` も chezmoi に反映します。

```sh
chezmoi add ~/.config/nix-darwin
cd ~/.local/share/chezmoi
git add .
git commit -m "Update nix inputs"
git push
```

## トラブルシュート

### 手順 4 の後に `nix` が見つからない

既に nix-darwin を適用済みで、再起動後や新しい shell で `nix` が見つからない場合は、
Nix 本体ではなく PATH 初期化が反映されていない可能性があります。
まず一時的に Determinate Nix の profile script を読み込みます。

```sh
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
nix --version
```

その後、このリポジトリの最新変更を取得して適用します。

```sh
cd ~/.local/share/chezmoi
git pull --ff-only
chezmoi apply
```

最後に nix-darwin を再適用します。

```sh
cd ~/.config/nix-darwin
sudo -H darwin-rebuild switch --flake '.#macos'
```

この設定では `nix.enable = false;` のまま Determinate Nix を使います。
nix-darwin が生成する `/etc/zshrc` は `/etc/zshrc.local` を読み込むため、
このリポジトリでは `/etc/zshrc.local` から
`/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh` を読み込むようにしています。

### Nix をリセットして手順 1 からやり直す

Determinate Nix Installer で入れた Nix をリセットする場合でも、
nix-darwin が入っている環境では先に nix-darwin をアンインストールします。
まず Nix の PATH が現在の shell に入っていることを確認します。

```sh
nix --version
```

`nix` が見つからない場合は、一時的に Determinate Nix の profile script を読み込みます。

```sh
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
nix --version
```

nix-darwin の最新 uninstaller を実行します。

```sh
sudo nix --extra-experimental-features "nix-command flakes" run github:LnL7/nix-darwin#darwin-uninstaller
```

上のコマンドが動かない場合は、ローカルに入っている uninstaller を使います。

```sh
sudo darwin-uninstaller
```

その後、`/nix` を手で削除せず、Determinate Nix Installer 付属のアンインストーラで Nix を削除します。

```sh
/nix/nix-installer uninstall
```

アンインストール後、shell を開き直して `nix` が見つからないことを確認します。

```sh
exec $SHELL -l
command -v nix
```

`command -v nix` が何も表示しなければ、手順 1 から再開します。

```sh
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
exec $SHELL -l
nix --version
```

`~/.local/share/chezmoi` と `~/.config/nix-darwin` が残っている場合は、
手順 2 の `chezmoi init` は不要です。最新化してから手順 3 へ進みます。

```sh
cd ~/.local/share/chezmoi
git pull --ff-only
nix run nixpkgs#chezmoi -- apply
```

## 構成

```text
~/.config/nix-darwin/
  flake.nix
  nix/
    darwin.nix
    home.nix
    homebrew.nix
    packages.nix
    overlays.nix
```

- `nix-darwin`: macOS defaults、system packages、Homebrew Cask、Mac App Store アプリ
- `home-manager`: git、zsh、direnv などのユーザー環境
- `nix-homebrew`: Homebrew 自体の管理
- `chezmoi`: dotfiles と Nix 設定ファイルの同期
- `devbox`: プロジェクト単位の開発環境で必要になった時に導入
