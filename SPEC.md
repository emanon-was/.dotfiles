# Dotfiles Specification

このリポジトリの現在仕様をまとめます。

## 方針

- `nix/` から配布用の `profile/` を生成し、`profile/` を `$HOME` へ symlink 展開して使う。
- build と検証には Nix を使い、生成済みの `profile/` 展開は Nix に依存しない。
- Home Manager 設定は root の `home.nix` と `flake.nix` で管理し、`profile/` には含めない。
- 副作用のある処理は自動処理に入れず、`dotfiles` CLI の明示コマンドで実行する。

## ディレクトリ

- `nix/etc/`
  - `profile/` と同じ layout の source tree。
  - `$HOME` に置く dotfiles、Doom Emacs、git、tmux、screen の設定を置く。
- `nix/bin/scripts/`
  - shell 製 `dotfiles-*` subcommand の source 置き場。
  - repo 全体の仕様、docs、tests は、この配下の個別 file 名や中身に依存しない。
- `nix/bin/default.nix`
  - Nix 環境用 command と profile 用 command を生成する。
- `nix/bin/dotfiles/`
  - `dotfiles` dispatcher と `dotfiles configure` dispatcher を生成する Nix packaging。
  - Go 製 command の生成元をこの配下に置く。
- `nix/bin/symsync/`
  - `symsync` package の生成元。
  - Go 製 command の生成元をこの配下に置く。
- `nix/`
  - `dotfiles-profile` package の生成元。
  - `profile` と profile 用 command を生成する。
- `profile/`
  - `make build` で再生成される配布用成果物。
  - build 済み成果物として commit する。
  - 手で編集しない。変更したい場合は生成元を直して `make build` を実行する。
- `notes/`
  - Home Manager 管理対象ではない個人メモを置く。
  - `notes/templates/` に project 用の参考ファイルを置く。
- `home.nix`
  - Home Manager 設定を置く。

## Home Manager

- root の `flake.nix` は `homeConfigurations.default` を出力する。
- Home Manager flake は `USER` と `HOME` から username と home directory を決める。
- Home Manager flake は `--impure` 前提で使い、実環境の `USER` と `HOME` を読む。
- `USER` または `HOME` が空の場合、Home Manager flake は評価エラーにする。
- Home Manager flake は username と home directory の fake default を持たない。
- Home Manager activation package を直接 build する場合は、`result` symlink を作らず store path を使う。
- root の `flake.lock` を Home Manager と profile 生成で共有する。
- shell、git、tmux、screen、Emacs 関連の dotfiles は `nix/etc/` を source of truth にする。
- 共通環境変数は `nix/etc/.profile.d/env.sh` に置く。
- session env の断片は `nix/etc/.profile.d/*.sh` に置き、`.bashrc` / `.zshrc` から読み込む。
- `.profile.d/env.sh` は PATH entry を重複させないように追加する。
- zsh login shell は `.zprofile` のあと `.zshrc` を読み込む。
- bash login shell は `.bash_profile` から `.bashrc` を読み込む。
- bash と zsh の共通 alias は `nix/etc/.config/shell/aliases.sh` に置く。
- `.bashrc` と `.zshrc` には shell 固有の history、completion、prompt wiring を置く。
- git、tmux、screen の設定は `$HOME` 直下の `.gitconfig`、`.tmux.conf`、`.screenrc` に置く。
- bash と zsh の prompt は shell 名を含む左側 2 行表示で揃え、zsh の right prompt は使わない。
- bash は `~/.local/share/bash-completion/completions` 配下の completion を読み込む。
- zsh は `compinit` 前に `~/.local/share/zsh/site-functions` を `fpath` に追加する。
- Doom Emacs の設定は `nix/etc/.config/doom/` を生成元にする。
- `nix/etc/.config/doom/` 配下のファイルを管理対象として扱う。
- Emacs package は terminal 用の `emacs-nox` を使う。
- shell の `emacs` alias は起動時に判定し、`emacs-nox` の場合は alias しない。それ以外の Emacs では `emacs -nw` にする。

## dotfiles CLI

- `dotfiles` は Go 製の Cargo 風 dispatcher。
- `dotfiles <name>` は、同じ directory または PATH 上の `dotfiles-<name>` を実行する。
- `make init` は `profile/` を symsync で `$HOME` へ展開する。
- `make clean` は `profile/` 由来の symlink を外す。
- `nix/bin/scripts/` 配下の subcommand は拡張領域として扱い、repo 全体仕様では個別 command の存在や挙動を規定しない。

## CLI Package

- `nix/bin/default.nix` は dispatcher、`symsync`、shell subcommand をまとめた `dotfiles-bin` package と profile 用 command package を生成する。
- `dotfiles` dispatcher と `dotfiles configure` dispatcher は Go binary として生成する。
- `nix/bin/dotfiles` は dispatcher package として完結し、shell subcommand は含めない。
- shell subcommand の集約は `nix/bin/default.nix` の責務とする。
- Home Manager 操作は root flake に対する通常の `nix` / `home-manager` command でも実行できる。
- `dotfiles-flake build` は root flake の `dotfiles-profile` package から `profile/` を再生成する。
- `dotfiles-flake switch` は root flake の Home Manager activation package を build して activate する。
- `dotfiles-flake update` は root flake の `flake.lock` を更新する。
- `symsync` は `nix/bin/symsync` で別 package として生成する。
- `dotfiles configure` は `dotfiles-configure-<command>` を呼ぶ dispatcher とする。
- profile 用 command と completion は `nix/bin/default.nix` の profile 用 package に集約する。
- `dotfiles` の bash / zsh completion は `nix/bin/dotfiles/completions/` を生成元にする。
- `symsync` の bash / zsh completion は `nix/bin/symsync/completions/` を生成元にする。
- 実行時の設定ファイル参照は、作業ツリーの生成元ではなく配置済みまたはビルド済み成果物を優先する。
- profile 由来の実行では `profile/` 配下に配置済みの file/link を参照する。

## Dispatcher Environment

- `dotfiles` dispatcher は repository root または profile root を検出し、子 command に環境変数を渡す。
- repository root は `flake.nix`、`home.nix`、`nix/` がある directory とする。
- profile root は `.local/bin` と `.local/share/dotfiles` がある directory とする。
- repository root を検出した場合、子 command に `DOTFILES_HOME=<repository root>` を渡す。
- profile root を検出した場合、子 command に `DOTFILES_HOME=<profile root>` を渡す。
- executable から上位 directory を探索し、repository root より手前で profile root が見つかった場合は profile root を採用する。
- 外部から渡された `DOTFILES_HOME` は repository root または profile root として validation する。
- validation に失敗した場合、dispatcher は子 command を実行せず usage error として終了する。

## Development Shell

- `devShells.x86_64-linux.default` は Go 開発用に `go` と `gopls` を提供する。
- repository root の `go.work` は `nix/bin/dotfiles/src` と `nix/bin/symsync/src` を workspace として扱う。

## Profile

- `profile/` は `make build` で生成する。
- `profile/` は profile mode 用 home files の展開専用成果物とする。
- `profile/` の静的な dotfiles は `nix/etc/` から生成する。
- `profile/.profile` は置かない。
- `profile/install.sh` と `profile/uninstall.sh` は置かない。
- `profile/.local/bin/symsync` を profile install/uninstall に使う。
- `symsync apply --src <src> --dest <dest>` は src tree を dest tree へ symlink で反映する。
- `symsync unapply --src <src> --dest <dest>` は src tree 由来の dest 側 symlink を削除する。
- `symsync apply --dry-run` と `symsync unapply --dry-run` は filesystem を変更せず、実行予定の操作と conflict を表示する。
- `$HOME/home-files` のような managed copy は作らない。
- command は `profile/.local/bin` に含め、`symsync apply` 時は `$HOME/.local/bin` へ symlink する。
- `profile/.local/share/dotfiles/.keep` は profile root 検出用 marker として含める。
- install 対象は `profile` 配下の directory、file、symlink とする。
- profile install/uninstall は manifest を使わない。
- 既存ファイル、既存 symlink、既存の非 directory path は退避せず conflict とする。
- conflict がある場合、`symsync apply` は filesystem を変更せず失敗する。
- `symsync unapply` は src 配下を指す dest 側 symlink だけを削除する。
- profile 生成時には `/nix/store` と固定 home path が成果物に残らないことを検査する。

## Makefile

- root `Makefile` は repo の検証、ビルド、生成用。
- `make check` は `nix flake check --impure` を実行する。
- `nix flake check --impure` は `checks.x86_64-linux.dotfiles-tests` を実行し、Nix sandbox 内で `dotfiles` / `symsync` の Go test と profile 成果物の smoke check を行う。

## 運用ルール

- `profile/` は直接編集しない。
- 外部環境へ副作用を起こす処理を Home Manager activation や build check に入れない。
- Home Manager の build / switch に重いネットワーク処理を混ぜない。
- profile init / install / uninstall 系は、再実行しても既存の状態ファイルを空にしたり管理対象 entry を失ったりしない。
- 変更後は影響範囲に応じて `make check`、`make build` を実行する。
- `make check` は `dotfiles` dispatcher と `symsync` の Go test、profile 成果物の dispatcher / `symsync` / completion / marker を検査する。
- tests は Nix 環境でのみ build / 実行する。生成済み `profile/` 上で実行する前提にはしない。
