# Dotfiles Specification

このリポジトリの現在仕様をまとめます。

## 方針

- 普段使う環境は Home Manager で管理する。
- NixOS system 側は stable を使い、Home Manager 側は `nixos-unstable` を使う。
- Nix や Home Manager が使えない環境では、Nix build 済みの `dist/` を使う。
- 副作用のある処理は Home Manager activation に入れず、`dotfiles` CLI の明示コマンドで実行する。

## ディレクトリ

- `home/`
  - Home Manager module と、その module が使う設定ファイルの生成元。
  - `home/config/` に tmux、screen、Doom Emacs などの手書き設定を置く。
- `pkgs/dotfiles/`
  - `dotfiles` CLI package の生成元。
  - `scripts/` に `dotfiles-*` subcommand を置く。
  - `scripts/lib/` に command へ結合する shell helper を置く。
  - `templates/` に `dotfiles project init ...` 用テンプレートを置く。
- `pkgs/dist/`
  - `dotfiles-dist` package の生成元。
  - `scripts/` に `dist/install.sh` と `dist/uninstall.sh` の生成元を置く。
- `dist/`
  - `make dist` で再生成される配布用成果物。
  - Nix なし環境へ持ち出せるように commit する。
  - 手で編集しない。変更したい場合は生成元を直して `make dist` を実行する。
- `notes/`
  - Home Manager 管理対象ではない個人メモを置く。

## Home Manager

- `flake.nix` は Home Manager standalone profile を提供する。
- 任意ユーザー向けの profile は `homeConfigurations.current` として定義する。
- `current` profile は `DOTFILES_USERNAME` と `DOTFILES_HOME_DIRECTORY` から username と home directory を決める。
- `dist` profile は `dotfiles-dist` 生成用。
- `dotfiles` CLI の既定 profile は `current`。
- `dotfiles` CLI は `DOTFILES_USERNAME` の既定値に `$USER`、`DOTFILES_HOME_DIRECTORY` の既定値に `$HOME` を使う。
- `dotfiles flake switch <user>` は `<user>` を `DOTFILES_USERNAME` として扱う。
- `DOTFILES_HOME_DIRECTORY` が明示されていない場合、`root` は `/root`、それ以外は `/home/<user>` を home directory にする。
- `home/default.nix` から機能別 module を import する。
- shell、git、tmux、screen、Emacs、GNOME 関連は Home Manager module で管理する。
- bash と zsh の prompt は左側 2 行表示で揃え、zsh の right prompt は使わない。
- `home/screen.nix` と `home/tmux.nix` は分離する。
- `home/dotfiles.nix` は `dotfilesPackage` から以下を配置する。
  - `$HOME/.local/bin`
  - `$HOME/.local/share/dotfiles/templates`
- Doom Emacs の `config.el` は `home/config/doom/config.el` を生成元にして Home Manager で配置する。
- Doom の `init.el` と `packages.el` は Doom 側の更新対象として扱い、この repo では管理しない。
- Emacs package は terminal 用の `emacs-nox` を使う。
- shell の `emacs` alias は起動時に判定し、`emacs-nox` の場合は alias しない。それ以外の Emacs では `emacs -nw` にする。

## dotfiles CLI

- `dotfiles` は Cargo 風 dispatcher。
- `dotfiles <name>` は、同じ directory または PATH 上の `dotfiles-<name>` を実行する。
- flake 依存コマンドは `dotfiles flake ...` 配下に置く。
- flake 操作は `dotfiles flake check/update/switch` を使う。

主要コマンド:

```sh
dotfiles doctor
dotfiles flake check
dotfiles flake update
dotfiles flake switch [--skip-doom-sync] [current|dist|user]
dotfiles flake doctor
dotfiles configure gnome
dotfiles configure doom install [--check]
dotfiles configure doom sync
dotfiles configure doom upgrade
dotfiles project init <nix|docker> [destination]
```

## CLI Package

- `pkgs/dotfiles/default.nix` は Nix package 版 command と dist 用 portable command を同じ command 定義から生成する。
- Nix package 版 command は `writeShellApplication` で生成する。
- dist 用 portable command は `share/dotfiles/portable-bin` に生成する。
- project templates は `share/dotfiles/templates` に生成する。
- Nix package 版の `dotfiles-project` は package 内の `share/dotfiles/templates` を参照する。
- dist 用 portable command には `DOTFILES_PORTABLE_DIST=1` を埋め込み、`dist/home-files/.local/share/dotfiles/templates` を参照する。

## Doom Emacs

- Doom checkout は `$HOME/.config/emacs` を使う。
- Doom 初回 clone/install は `dotfiles configure doom install` で明示実行する。
- `dotfiles configure doom sync` は `$HOME/.config/emacs/bin/doom sync` を実行する。
- `dotfiles configure doom upgrade` は upgrade 後に sync する。
- `dotfiles flake switch` 成功後は通常 `doom sync` も実行する。
- `dotfiles flake switch --skip-doom-sync` で Doom sync を飛ばせる。
- install/upgrade 時は Home Manager 管理の `config.el` symlink を一時的に外す。
- Doom が生成した `config.el` と `home/config/doom/config.el` の差分を確認してから symlink を戻す。
- Doom config の差分が出た場合は `var/doom-config-diffs/*.patch` に保存する。
- `dotfiles configure doom install --check` は一時 directory で install flow を検証し、実環境を変更しない。

## dist

- `dist/` は `make dist` で生成する。
- `dist/` は home files の展開専用とする。
- `dist/install.sh` は `dist/home-files` から `$HOME` へ直接 symlink する。
- `$HOME/home-files` のような managed copy は作らない。
- Home Manager 由来の `.config/systemd` は `dist` に含めない。
- command は `dist/home-files/.local/bin` に含め、install 時は `$HOME/.local/bin` へ symlink する。
- project init 用テンプレートは `dist/home-files/.local/share/dotfiles/templates` に含める。
- 既存ファイルや既存 symlink は `.backup`, `.backup.1`, ... に退避してから symlink する。
- 既存ディレクトリは残し、その配下の対象ファイルを個別に symlink する。
- 既存ディレクトリ symlink は `.backup` へ退避し、実ディレクトリを作って配下に symlink する。
- `dist/uninstall.sh` は管理対象 symlink を削除し、対応する `.backup` があれば元の名前へ復元する。
- uninstall 時に元の名前へ別ファイルがある場合は上書きせず復元を skip する。
- dist 生成時には `/nix/store` と固定 home path が成果物に残らないことを検査する。

## Project Templates

- テンプレート生成元は `pkgs/dotfiles/templates/`。
- 対応テンプレートは `nix` と `docker`。
- `dotfiles project init <template> [destination]` で展開する。
- `destination` を省略した場合は現在の directory に展開する。
- Nix package 版は package 内の templates を参照する。
- Home Manager 版と dist 版では `$HOME/.local/share/dotfiles/templates` 配下を参照する。

## Makefile

- root `Makefile` は repo の検証、ビルド、生成用。

主要 target:

```sh
make flake-check
make dotfiles-build
make dist-build
make home-build
make dist
```

## 運用ルール

- `dist/` は直接編集しない。
- `gsettings` や `doom install` のような副作用コマンドを Home Manager activation に入れない。
- `doom sync` は `dotfiles flake switch` から明示的に呼び出す。
- Home Manager module の評価や activation に重いネットワーク処理を混ぜない。
- 変更後は影響範囲に応じて `make flake-check`、`make dist-build`、`make dist`、dist install/uninstall の一時 HOME テストを実行する。
