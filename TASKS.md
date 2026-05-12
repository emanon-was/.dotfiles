# Dotfiles Tasks

このファイルは、今後の作業で参照するための現在仕様と未完了タスクをまとめる場所です。
完了済みの移行履歴はここには残さず、必要な情報は README と git log を参照します。

## 現在仕様

### 全体方針

- 普段使う環境は Home Manager で管理する。
- NixOS system 側は stable、Home Manager 側は `nixos-unstable` を使う。
- Nix や Home Manager が使えない環境向けには `dist/` を使う。
- 副作用のある処理は Home Manager activation に入れず、`dotfiles` CLI の明示コマンドとして実行する。
- 旧 `store/`、`store.list`、旧 `bin/` スクリプト、旧 symlink 管理は廃止済み。

### ディレクトリ構成

- `home/`
  - Home Manager module と、Home Manager が使う設定ファイルの生成元。
  - `home/config/` に tmux、screen、Doom Emacs などの手書き設定を置く。
- `pkgs/dotfiles/`
  - `dotfiles` CLI と `dist` package の生成元。
  - `pkgs/dotfiles/scripts/` に `dotfiles-*` サブコマンドを置く。
  - `pkgs/dotfiles/dist/` に `dist/install.sh` などの生成元を置く。
- `project-templates/`
  - `dotfiles project init ...` で使うテンプレート。
- `notes/`
  - Home Manager 管理対象ではない個人メモ。
- `dist/`
  - `make dist` で再生成される配布用成果物。
  - Nix なし環境へ持ち出すために commit する。
  - 手で編集しない。変更したい場合は生成元を直して `make dist` を実行する。

### Home Manager

- `flake.nix` は Home Manager standalone profile を提供する。
- profile の既定値は `nixos`。
- `home/default.nix` から機能別 module を import する。
- shell、git、tmux、screen、Emacs、GNOME 関連は Home Manager module で管理する。
- `home/screen.nix` と `home/tmux.nix` は分離する。
- Doom Emacs の `config.el` は `home/config/doom/config.el` を生成元にして Home Manager で配置する。
- Doom の `init.el` と `packages.el` は Doom 側の更新対象として扱い、この repo では管理しない。

### dotfiles CLI

- `dotfiles` は Cargo 風 dispatcher。
- `dotfiles <name>` は同じ directory または PATH 上の `dotfiles-<name>` を実行する。
- flake 依存コマンドは `dotfiles flake ...` 配下に置く。
- 旧 `dotfiles check/update/switch` は使わず、`dotfiles flake check/update/switch` を使う。

主要コマンド:

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

### Doom Emacs

- Doom checkout は `~/.config/emacs` を使う。
- Doom 初回 clone/install は `dotfiles configure doom install` で明示実行する。
- `dotfiles configure doom sync` は `~/.config/emacs/bin/doom sync` を実行する。
- `dotfiles configure doom upgrade` は upgrade 後に sync する。
- `dotfiles flake switch` 成功後は通常 `doom sync` も実行する。
- `--skip-doom-sync` で Doom sync を飛ばせる。
- install/upgrade 時は Home Manager 管理の `config.el` symlink を一時的に外し、Doom が生成した `config.el` と `home/config/doom/config.el` の差分を確認してから symlink を戻す。
- Doom config の差分が出た場合は `var/doom-config-diffs/*.patch` に保存する。
- `dotfiles configure doom install --check` は一時 directory で install flow を検証し、実環境を変更しない。

### dist

- `dist/` は `make dist` で生成する。
- `dist/install.sh` は `home-files` を install 対象にする。
- command の生成先は `dist/home-files/.local/bin`。
- `project-templates/` は `dist/` に含めても、`install.sh` では展開しない。
- default prefix は `$HOME`。
- `home-files` は `$prefix/home-files` に配置し、`$HOME/.bashrc` などから symlink する。
- command は `home-files` の通常展開として `$HOME/.local/bin` に symlink する。
- 既存ファイルや既存 symlink は `.backup`, `.backup.1`, ... に退避してから symlink する。
- 既存ディレクトリは残し、その配下の対象ファイルを個別に symlink する。
- 既存ディレクトリ symlink は `.backup` へ退避し、実ディレクトリを作って配下に symlink する。
- `dist/uninstall.sh` は管理対象 symlink を削除し、対応する `.backup` があれば元の名前へ復元する。
- uninstall 時に元の名前へ別ファイルがある場合は上書きせず復元を skip する。

### Makefile

- root `Makefile` は repo 開発用。
- `dotfiles` CLI の互換 wrapper としては使わない。

主要 target:

```sh
make flake-check
make dotfiles-build
make dist-build
make home-build
make dist
```

## 未完了タスク

現時点では未完了タスクなし。

新しい作業を始める場合は、この section に `- [ ] ...` として追加する。

## 注意点

- ユーザーの未コミット変更を勝手に戻さない。
- `dist/` を直接編集しない。
- `gsettings` や `doom install` のような副作用コマンドを Home Manager activation に入れない。
- `doom sync` は `dotfiles flake switch` から明示的に呼び出す。Home Manager module の評価や activation に重いネットワーク処理を混ぜない。
