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
- Doom Emacs の設定は `home/config/doom/` を生成元にして Home Manager で配置する。
- `home/config/doom/` 配下のファイルを管理対象として扱う。
- Emacs package は terminal 用の `emacs-nox` を使う。
- shell の `emacs` alias は起動時に判定し、`emacs-nox` の場合は alias しない。それ以外の Emacs では `emacs -nw` にする。

## dotfiles CLI

- `dotfiles` は Cargo 風 dispatcher。
- `dotfiles <name>` は、同じ directory または PATH 上の `dotfiles-<name>` を実行する。
- flake 依存コマンドは `dotfiles flake ...` 配下に置く。
- flake 操作は `dotfiles flake check/update/switch` を使う。
- Home Manager 管理をやめる場合は `home-manager uninstall` を使う。Makefile では `make clean.flake` として用意する。

主要コマンド:

```sh
dotfiles flake check
dotfiles flake update
dotfiles flake switch [current|dist|user]
dotfiles flake doctor
dotfiles configure doctor
dotfiles configure gnome
dotfiles configure gnome doctor
dotfiles configure doom install [--check]
dotfiles configure doom sync
dotfiles configure doom upgrade
dotfiles configure doom repair
dotfiles configure doom doctor
dotfiles project init <nix|docker> [destination]
```

## CLI Package

- `pkgs/dotfiles/default.nix` は Nix package 版 command と dist 用 portable command を同じ command 定義から生成する。
- Nix package 版 command は `writeShellApplication` で生成する。
- dist 用 portable command は `share/dotfiles/portable-bin` に生成する。
- `pkgs/dotfiles/scripts/dotfiles-*.sh` は単体では実行せず、`default.nix` が `scripts/lib/common.sh` と必要な lib を前置して command 化する。
- 各 `dotfiles-*.sh` の冒頭には、前置される lib と注入される変数をコメントで明記する。
- 汎用の `dotfiles doctor` は置かず、flake 診断は `dotfiles flake doctor`、configure 診断は `dotfiles configure doctor` に分ける。
- project templates は `share/dotfiles/templates` に生成する。
- Nix package 版の `dotfiles-project` は package 内の `share/dotfiles/templates` を参照する。
- dist 用 portable command には `DOTFILES_PORTABLE_DIST=1` を埋め込み、`dist/home-files/.local/share/dotfiles/templates` を参照する。
- 実行時の設定ファイル参照は、作業ツリーの生成元ではなく配置済みまたはビルド済み成果物を優先する。
- dist 版は `dist/home-files`、Home Manager 版は `$HOME` に配置済みの file/link、Nix package 版は package 内の `share/dotfiles/home-files` を参照する。

## Doom Emacs

- Doom checkout は `$HOME/.config/emacs` を使う。
- Doom 初回 clone/install は `dotfiles configure doom install` で明示実行する。
- `dotfiles configure doom sync` は `$HOME/.config/emacs/bin/doom sync` を実行する。
- `dotfiles configure doom upgrade` は upgrade 後に sync する。
- Doom install/upgrade は `--force` を付けて実行し、Doom 側の確認 prompt を自動承認する。
- `dotfiles configure doom repair` は保存済みの Doom 初期 config を `~/.config/doom/` に復元して修復する。
- `dotfiles flake switch` は Doom sync を実行しない。Doom 操作は `dotfiles configure doom ...` で明示実行する。
- Doom install/upgrade 時は一時 `--doomdir` で Doom の初期 config を生成し、実際の `~/.config/doom` に触れずに `$HOME/.local/state/dotfiles/doom-initial/` へ保存する。
- `doom-initial` は現在の Doom 初期 config のみを保持し、timestamp 履歴は持たない。
- Doom install/upgrade 時は managed source 側の `.config/doom` 配下にあるファイルを `~/.config/doom/` へリンクする。
- Home Manager が同じ内容の Nix store symlink を既に配置している場合は置き換えない。
- straight recipe repository の事前更新は best-effort とし、失敗しても warning で継続する。
- `dotfiles configure doom install --check` は一時 directory で install flow を検証し、実環境を変更しない。
- `dotfiles configure doom doctor` は Doom checkout、Doom executable、管理対象 `.config/doom`、straight recipe repository を診断する。
- `dotfiles configure gnome doctor` は `gsettings` と GNOME interface schema/key を診断する。`gsettings` がない環境は正常に skip する。
- `dotfiles configure doctor` は configure 系の総合診断として GNOME と Doom の診断を実行する。

## dist

- `dist/` は `make dist` で生成する。
- `dist/` は home files の展開専用とする。
- `dist/install.sh` は `dist/home-files` から `$HOME` へ直接 symlink する。
- `$HOME/home-files` のような managed copy は作らない。
- Home Manager 由来の `.config/systemd` は `dist` に含めない。
- command は `dist/home-files/.local/bin` に含め、install 時は `$HOME/.local/bin` へ symlink する。
- project init 用テンプレートは `dist/home-files/.local/share/dotfiles/templates` に含める。
- 既存ファイルや既存 symlink は `.backup`, `.backup.1`, ... に退避してから symlink する。
- install 時の symlink と backup は `$HOME/.local/state/dotfiles/install-manifest.tsv` に記録する。
- 既存ディレクトリは残し、その配下の対象ファイルを個別に symlink する。
- 既存ディレクトリ symlink は `.backup` へ退避し、実ディレクトリを作って配下に symlink する。
- `dist/uninstall.sh` は install manifest を参照して管理対象 symlink を削除し、install 時に退避した backup を元の名前へ復元する。
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
- `nix flake check` は `checks.x86_64-linux.dotfiles-tests` を実行し、Nix sandbox 内で dotfiles CLI と dist install/uninstall の非破壊テストを行う。

主要 target:

```sh
make check
make flake-check
make dotfiles-build
make dist-build
make home-build
make dist
make init
make init.flake
make init.dist
make init.doom
make clean.flake
make clean.dist
```

## 運用ルール

- `dist/` は直接編集しない。
- `gsettings` や `doom install` のような副作用コマンドを Home Manager activation に入れない。
- `doom sync` は `dotfiles flake switch` から呼び出さない。
- Home Manager module の評価や activation に重いネットワーク処理を混ぜない。
- 変更後は影響範囲に応じて `make check`、`make dist-build`、`make dist` を実行する。
- `dotfiles flake switch` の対象解決は `make switch-check` で検査する。任意ユーザー、`root`、`dist`、旧 `DOTFILES_PROFILE=<user>`、不正引数を条件に含める。
- `dotfiles` CLI の主要 subcommand は `make command-check` で検査する。dispatcher と project init を対象にする。
- dist install/uninstall の復元処理は `make dist-install-check` で検査する。
- tests は Nix 環境でのみ build / 実行する。非 Nix 環境に持ち出した `dist/` 上で実行する前提にはしない。
