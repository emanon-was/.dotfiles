# .dotfiles

自分用の dotfiles 管理リポジトリです。

基本方針は、普段使う環境では Home Manager で宣言的に管理し、Nix や Home Manager を使えない環境では `dist/` に生成した成果物を展開して使う、という分け方です。

NixOS の system 側は stable を使い、このリポジトリの Home Manager 側は `nixos-unstable` を使います。system 側の `configuration.nix` には極力寄せず、ユーザー環境の設定は Home Manager と `dotfiles` コマンドへ寄せます。

## 使い分け

### Home Manager 版

メインの利用方法です。Nix と Home Manager が使える自分の環境ではこちらを使います。

- shell、tmux、screen、git、Emacs などのユーザー設定を Home Manager で管理する
- `~/.config/doom/config.el` は Home Manager 経由で管理する
- Doom Emacs の install、sync、upgrade は `dotfiles configure doom ...` で明示的に実行する
- `dotfiles flake switch` 後には Doom sync も実行する
- GNOME 設定のような副作用のある処理は Home Manager activation には入れず、`dotfiles configure gnome` として分ける

初回セットアップ:

```sh
git clone https://github.com/emanon-was/.dotfiles.git "$HOME/.dotfiles"
cd "$HOME/.dotfiles"
nix run .#dotfiles -- doctor
nix run .#dotfiles -- flake switch
```

Doom Emacs が未セットアップの場合:

```sh
nix run .#dotfiles -- configure doom install
nix run .#dotfiles -- flake switch
```

通常の更新:

```sh
dotfiles flake update
dotfiles flake switch
```

`dotfiles flake switch` は内部で次のような処理を行います。

```sh
home-manager -b hm-backup --flake "$DOTFILES_HOME#nixos" switch
dotfiles configure doom sync
```

Doom sync を一時的に飛ばしたい場合:

```sh
dotfiles flake switch --skip-doom-sync
```

### Nix なし / Home Manager なしの環境

Nix を使わない環境では `dist/` を使います。`dist/` は Nix build で生成した成果物で、直接編集しません。

```sh
./dist/install.sh
```

デフォルトでは以下に `home-files` が配置されます。

```text
$HOME
```

`dotfiles` コマンド群は以下へ配置されます。

```text
$HOME/.bin
```

必要ならインストール先を指定できます。

```sh
./dist/install.sh "$HOME/.local/share/dotfiles"
```

`DOTFILES_BIN_DIR` を指定すると、コマンドの symlink 先を変えられます。

```sh
DOTFILES_BIN_DIR="$HOME/bin" ./dist/install.sh
```

`dist/home-files/` には Home Manager から生成した `$HOME` 用 dotfiles が入ります。Nix なし環境で使う場合は、この内容を確認して必要なものだけ `$HOME` に配置します。
`install.sh` は `home-files` の内容をコピーせず、`$HOME/.bashrc` などから `home-files` 内のファイルへ symlink を作成します。
`project-templates/` と `home/config/` は `dist/` には含まれますが、`install.sh` では展開しません。

アンインストールする場合:

```sh
./dist/uninstall.sh
```

`install.sh` と同じ `prefix` や `DOTFILES_BIN_DIR` を指定していた場合は、同じ値を渡します。

## dotfiles コマンド

`dotfiles` は Cargo 風の dispatcher です。`dotfiles doctor` を実行すると、PATH 上の `dotfiles-doctor` が実行されます。

```sh
dotfiles doctor
dotfiles flake check
dotfiles flake update
dotfiles flake switch [--skip-doom-sync] [profile]
dotfiles flake doctor
dotfiles configure gnome
dotfiles configure doom install [--check]
dotfiles configure doom sync
dotfiles configure doom upgrade
dotfiles project init <nix|docker> [destination]
```

## Doom Emacs

Doom Emacs 本体は `~/.config/emacs` に置きます。Doom の `init.el` や `packages.el` は Doom 側の更新で変わる可能性があるため、このリポジトリでは管理しません。

このリポジトリで管理する Doom 設定は以下です。

```text
home/config/doom/config.el
```

`dotfiles configure doom install` と `dotfiles configure doom upgrade` では、Doom が生成・更新する `config.el` と `home/config/doom/config.el` の差分を確認してから、Home Manager 管理の symlink を戻します。

初回 install の流れだけを検証したい場合:

```sh
dotfiles configure doom install --check
```

## project templates

プロジェクト用テンプレートは `project-templates/` にあります。

```sh
dotfiles project init nix
dotfiles project init docker
dotfiles project init nix path/to/project
dotfiles project init docker path/to/project
```

`destination` を省略すると現在のディレクトリに展開します。

## リポジトリ開発

root の `Makefile` は `dotfiles` コマンドの互換ではなく、このリポジトリを Nix で検証・ビルド・生成するためのものです。

```sh
make flake-check
make dotfiles-build
make dist-build
make home-build
make dist
```

`make dist` は `.#dotfiles-dist` をビルドし、その成果物で `dist/` を再生成します。`dist/` 配下は生成物なので、修正が必要な場合は `pkgs/dotfiles/`、`project-templates/`、`home/` などの生成元を編集します。

## メモ

Home Manager 管理対象ではない Emacs Lisp のメモは `notes/emacs/` に置きます。
