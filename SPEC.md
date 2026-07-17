# Dotfiles Specification

このリポジトリの現在仕様をまとめます。

## 方針

- `static/` と `generated/` を `$HOME` へ symlink 展開して使う。
- `static/` は手で編集する `$HOME` layout の dotfiles source とする。
- `generated/` は Nix build 済み command / completion の成果物として commit する。
- Home Manager 設定は root の `home.nix` と `flake.nix` で管理する。
- 副作用のある処理は自動処理に入れず、`dotfiles` CLI の明示コマンドで実行する。

## ディレクトリ

- `static/`
  - `$HOME` に置く静的 dotfiles source tree。
  - shell、git、tmux、screen、Doom Emacs、Zellij、shell scripts を置く。
- `generated/`
  - `make build` または `dotfiles flake build` で再生成する成果物。
  - Go binary、completion、local root marker を置く。
  - 手で編集しない。
- `nix/dotfiles/`
  - `dotfiles` dispatcher と `dotfiles configure` dispatcher の package 生成元。
- `nix/symsync/`
  - `symsync` package の生成元。
- `default.nix`
  - `generated/` layout を生成する package 定義。
- `home.nix`
  - Home Manager 設定を置く。
- `notes/`
  - Home Manager 管理対象ではない個人メモを置く。
  - `notes/templates/` に project 用の参考ファイルを置く。

## Static Files

- 共通環境変数は `static/.profile.d/env.sh` に置く。
- session env の断片は `static/.profile.d/*.sh` に置き、`.bashrc` / `.zshrc` から読み込む。
- `.profile.d/env.sh` は PATH entry を重複させないように追加する。
- zsh login shell は `.zprofile` のあと `.zshrc` を読み込む。
- bash login shell は `.bash_profile` から `.bashrc` を読み込む。
- bash と zsh の共通 alias は `static/.config/shell/aliases.sh` に置く。
- `.bashrc` と `.zshrc` には shell 固有の history、completion、prompt wiring を置く。
- git、tmux、screen の設定は `$HOME` 直下の `.gitconfig`、`.tmux.conf`、`.screenrc` に置く。
- bash と zsh の prompt は shell 名を含む左側 2 行表示で揃え、zsh の right prompt は使わない。
- bash は `~/.local/share/bash-completion/completions` 配下の completion を読み込む。
- zsh は `compinit` 前に `~/.local/share/zsh/site-functions` を `fpath` に追加する。
- Doom Emacs の設定は `static/.config/doom/` を生成元にする。
- Emacs package は terminal 用の `emacs-nox` を使う。
- shell の `emacs` alias は起動時に判定し、`emacs-nox` の場合は alias しない。それ以外の Emacs では `emacs -nw` にする。

## Home Manager

- root の `flake.nix` は `homeConfigurations.default` を出力する。
- root の `flake.nix` は `builtins.currentSystem` を使い、評価している host system 向けの packages / checks / devShells / apps を出力する。
- この flake は個人 dotfiles 用で、Home Manager 設定も実行環境の `USER` と `HOME` を読む `--impure` 前提である。そのため、複数 system を明示列挙するより、実行 host の system に合わせる単純な構成を採用する。
- cross build や pure flake としての利用は現在の目的に含めない。
- Home Manager flake は `USER` と `HOME` から username と home directory を決める。
- Home Manager flake は `--impure` 前提で使い、実環境の `USER` と `HOME` を読む。
- `USER` または `HOME` が空の場合、Home Manager flake は評価エラーにする。
- Home Manager flake は username と home directory の fake default を持たない。
- Home Manager activation package を直接 build する場合は、`result` symlink を作らず store path を使う。
- root の `flake.lock` を Home Manager と generated 生成で共有する。

## dotfiles CLI

- `dotfiles` は Go 製の Cargo 風 dispatcher。
- `dotfiles <name>` は、同じ directory または PATH 上の `dotfiles-<name>` を実行する。
- `dotfiles configure` は `dotfiles-configure-<command>` を呼ぶ dispatcher とする。
- shell script subcommand は `static/.local/bin/` に置く。
- `dotfiles-flake build` は root flake の `dotfiles-generated` package から `generated/` を再生成する。
- `dotfiles-flake switch` は root flake の Home Manager activation package を build して activate する。
- `dotfiles-flake update` は root flake の `flake.lock` を更新する。

## Dispatcher Environment

- `dotfiles` dispatcher は repository root または local root を検出し、子 command に環境変数を渡す。
- repository root は `flake.nix`、`home.nix`、`nix/` がある directory とする。
- local root は `.local/bin` と `.local/share/dotfiles` がある directory とする。
- repository root を検出した場合、子 command に `DOTFILES_HOME=<repository root>` を渡す。
- local root を検出した場合、子 command に `DOTFILES_HOME=<local root>` を渡す。
- executable から上位 directory を探索し、repository root より手前で local root が見つかった場合は local root を採用する。
- 外部から渡された `DOTFILES_HOME` は repository root または local root として validation する。
- validation に失敗した場合、dispatcher は子 command を実行せず usage error として終了する。

## Generated

- `generated/` は `make build` で生成する。
- `generated/.local/bin/dotfiles`、`generated/.local/bin/dotfiles-configure`、`generated/.local/bin/symsync` を含める。
- bash / zsh completion は `generated/.local/share/` に含める。
- `generated/.local/share/dotfiles/.keep` は local root 検出用 marker として含める。
- generated 生成時には `/nix/store` と固定 home path が成果物に残らないことを検査する。

## Install

- `make init` は `static/` と `generated/` を symsync で `$HOME` へ展開する。
- `make clean` は `generated/`、`static/` の順に symlink を外す。
- `symsync apply --src <src> --dest <dest>` は src tree を dest tree へ symlink で反映する。
- `symsync unapply --src <src> --dest <dest>` は src tree 由来の dest 側 symlink だけを削除する。
- `symsync apply --dry-run` と `symsync unapply --dry-run` は filesystem を変更せず、実行予定の操作と conflict を表示する。
- `$HOME/home-files` のような managed copy は作らない。
- install 対象は `static/` と `generated/` 配下の directory、file、symlink とする。
- install/uninstall は manifest を使わない。
- 既存ファイル、既存 symlink、既存の非 directory path は退避せず conflict とする。
- conflict がある場合、`symsync apply` は filesystem を変更せず失敗する。

## Development Shell

- `devShells.<current system>.default` は Go 開発用に `go` と `gopls` を提供する。
- repository root の `go.work` は `nix/dotfiles/src` と `nix/symsync/src` を workspace として扱う。

## Makefile

- root `Makefile` は repo の検証、ビルド、生成用。
- `make build` と `make check` は `NIX_CACHE_HOME`（既定値は repository root の `.cache`）を `XDG_CACHE_HOME` とし、`--impure` を付けて Nix を実行する。
- `make build` は `generated/` を再生成する。
- `make build` は新しい成果物を準備してから既存の `generated/` を置換し、置換に失敗した場合は既存成果物を復元する。
- `make check` は `nix flake check --impure` を実行する。
- `nix flake check --impure` は `checks.<current system>.dotfiles-tests` を実行し、Nix sandbox 内で `dotfiles` / `symsync` の Go test、generated 成果物の smoke check、`make build` の失敗時復元を検査する。
- `static/.local/bin/` の shell subcommand は任意の拡張として扱い、repo 全体の checks から名前、内容、構造を参照しない。

## 運用ルール

- `static/` は直接編集する。
- `generated/` は直接編集しない。
- 外部環境へ副作用を起こす処理を Home Manager activation や build check に入れない。
- Home Manager の build / switch に重いネットワーク処理を混ぜない。
- init / clean 系は、再実行しても既存の状態ファイルを空にしたり管理対象 entry を失ったりしない。
- 変更後は影響範囲に応じて `make check`、`make build` を実行する。
- tests は Nix 環境でのみ build / 実行する。生成済み `generated/` 上で実行する前提にはしない。
