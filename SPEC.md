# Dotfiles Specification

このリポジトリの現在仕様をまとめます。利用手順は [README.md](./README.md)、作業規範は [AGENTS.md](./AGENTS.md)、未完了の作業は [TASKS.md](./TASKS.md) を参照してください。

ここでは管理範囲、配置・ビルドの契約、ツール間の依存関係を記録する。単独で完結する alias、キー割り当て、表示設定などは設定ファイルを正とし、列挙しない。具体的な設定値は、他のツールとの連携に必要な場合に理由と併せて記載する。

## 管理範囲と構成

設定ファイルの配置と Home Manager によるパッケージ管理は、別々に適用する。`static/` は手で編集する設定の生成元、`generated/` は Nix で生成して commit する成果物とする。

| 場所 | 役割 |
| --- | --- |
| `static/ln/` | `$HOME` と同じ構成で置く、symlink 配置用の設定 |
| `static/cp/` | `$HOME` と同じ構成で置く、copy 配置用の設定 |
| `generated/` | ビルド済みコマンド、補完、local root 検出用 marker |
| `nix/dotfiles/` | `dotfiles` と `dotfiles configure` の dispatcher package |
| `nix/dotfiles-ln/`、`nix/dotfiles-cp/` | symlink / copy 配置を行う package |
| `default.nix` | `generated/` の構成を定義する集約層 |
| `home.nix` | Home Manager 設定 |
| `flake.nix` | packages / checks / devShells / apps と Home Manager の出力 |
| `Makefile` | 配置・削除・ビルド・検証の入口 |
| `notes/` | Home Manager 管理対象外の個人メモ。`templates/` は project 用の参考ファイル |

副作用のある外部環境の操作は明示的なコマンドで実行し、Home Manager activation や build check に組み込まない。Home Manager の build / switch に重いネットワーク処理を混ぜない。

## 設定ファイルの配置と削除

- `make init` は `static/ln/` と `generated/` を `dotfiles-ln`、`static/cp/` を `dotfiles-cp` で `$HOME` に配置する。
- `make clean` は `generated/`、`static/cp/`、`static/ln/` の順に管理対象を外す。
- 配置対象は各 tree 内の directory、file、symlink とする。manifest や `$HOME/home-files` のような managed copy は作らない。
- 既存 path が管理対象と異なる場合は、退避や上書きをせず conflict とする。conflict がある場合、そのコマンドは filesystem を変更せず失敗する。
- `--dry-run` は filesystem を変更せず、実行予定の操作と conflict を表示する。
- init / clean 系は、再実行しても既存の状態ファイルを空にしたり、管理対象 entry を失ったりしない。

| コマンド | 動作 |
| --- | --- |
| `dotfiles-ln apply/unapply` | symlink tree を配置・削除する |
| `dotfiles-cp apply` | 未配置 file を copy し、同一内容なら保持する。異なる既存 path は conflict とする |
| `dotfiles-cp unapply` | 生成元と内容が同一の配置先 file だけを削除する。変更済み file は conflict とする |

詳細は [dotfiles-ln](./nix/dotfiles-ln/README.md) と [dotfiles-cp](./nix/dotfiles-cp/README.md) を参照する。

## Nix と Home Manager

### 評価環境

- root flake は `github:NixOS/nixpkgs/nixos-unstable` を input に宣言し、`flake.lock` を commit してリビジョンを固定する。Nixpkgs の取得元はシステムやユーザーの channel、`NIX_PATH` に依存しない。
- lock の更新は明示的な操作で行い、生成物の再ビルドや Home Manager の適用とは分ける。
- Home Manager は `github:nix-community/home-manager` を input に宣言し、`flake.lock` で固定する。Home Manager の Nixpkgs input は dotfiles の `nixpkgs` input に follows させ、管理する package にも同じ `pkgs` を渡す。
- `builtins.currentSystem` により、実行 host 向けの packages / checks / devShells / apps を出力する。cross build や pure flake としての利用は対象外とする。
- `homeConfigurations.default` は、実環境の `USER` と `HOME` から username と home directory を決める。`--impure` を前提とし、どちらかが空なら評価エラーにする。仮の既定値や固定の home path は使わない。
- Home Manager activation package を直接 build する場合は、`result` symlink を作らず store path を使う。

## dotfiles CLI

`dotfiles` は Go 製の Cargo 風 dispatcher とする。`dotfiles <name>` は同じ directory または PATH 上の `dotfiles-<name>` を実行し、`dotfiles configure` は `dotfiles-configure-<command>` を呼び出す。

shell subcommand は `static/ln/.local/bin/` に置く任意の拡張とする。個別コマンドの名前・内容・構造は repo 全体の仕様や checks に固定しない。

### Root の検出と環境変数

| Root | 判定に使う構成 |
| --- | --- |
| repository root | `flake.nix`、`home.nix`、`nix/` がある directory |
| local root | `.local/bin` と `.local/share/dotfiles` がある directory |

- executable から上位 directory を探索する。repository root より手前で local root が見つかった場合は local root を採用する。
- 検出した root を `DOTFILES_HOME` として子コマンドに渡す。
- 外部から渡された `DOTFILES_HOME` も、いずれかの root として検証する。検証に失敗した場合は子コマンドを実行せず、usage error として終了する。

## ビルドと検証

### 生成物

`make build` は `generated/` を再生成する。生成物は直接編集しない。

| 配置先 | 内容 |
| --- | --- |
| `generated/.local/bin/` | `dotfiles`、`dotfiles-configure`、`dotfiles-ln`、`dotfiles-cp` |
| `generated/.local/share/` | bash / zsh の補完 |
| `generated/.local/share/dotfiles/.keep` | local root 検出用 marker |

- 生成時に `/nix/store` と固定 home path が成果物に残らないことを検査する。
- 新しい成果物を準備してから既存の `generated/` を置換する。置換に失敗した場合は既存成果物を復元する。
- 作業ツリーにコピーした成果物には所有者の書き込み権限を付与し、Git による更新・削除を可能にする。Nix store 内の権限は変更しない。

### 開発環境と checks

- `devShells.<current system>.default` は Go と gopls を提供する。`.envrc` は `use flake --impure` で読み込む。
- root の `go.work` は `nix/dotfiles/src`、`nix/dotfiles-ln/src`、`nix/dotfiles-cp/src` を workspace として扱う。
- `make build` と `make check` は `NIX_CACHE_HOME`（既定値は repository root の `.cache`）を `XDG_CACHE_HOME` として、Nix を `--impure` 付きで実行する。
- `make check` は `nix flake check --impure` により `checks.<current system>.dotfiles-tests` を実行する。Nix sandbox 内で3つの Go package の test、生成物の smoke check、`make build` の失敗時復元を検査する。
- tests は Nix 環境で build / 実行し、生成済み `generated/` 上での実行を前提にしない。
- 変更後は影響範囲に応じて `make check` を実行する。生成元を変更した場合は先に `make build` で反映する。

## ツール間の連携

以下の path は、特記がなければ `static/ln/` を基準とする。

### シェルと環境変数

- session 環境変数は `.profile.d/*.sh` に置き、`.bashrc` / `.zshrc` から読み込む。共通設定の `.profile.d/env.sh` は PATH entry を重複させない。
- bash login shell は `.bash_profile` から `.bashrc` を読み込む。zsh login shell は `.zprofile` のあと `.zshrc` を読み込む。
- bash / zsh の共通 alias は `.config/shell/aliases.sh` に集約する。
- zsh は `.zshrc` の `bindkey -e` で Emacs キーバインドに固定し、`EDITOR` / `VISUAL` が Vim でも `Ctrl-r` で履歴検索できるようにする。
- bash は `.bashrc` の `set -o emacs` で Emacs キーバインドに固定する。
- `generated/` から配置する補完を使うため、bash は `~/.local/share/bash-completion/completions` を読み込む。zsh は `compinit` 前に `~/.local/share/zsh/site-functions` を `fpath` に追加する。
- `.config/direnv/direnvrc` は `use flake` / `use nix` の前後で元の `$SHELL` を保持し、他の開発環境変数は通常どおり取り込む。nix-direnv と併用する場合は、その読み込み後にこの設定を読み込む。

### 外部エディタと Zellij

- `.profile.d/env.sh` は `EDITOR=vim` と `VISUAL=vim` を設定し、これらを参照するツールの外部エディタを Vim に揃える。実行に必要な `pkgs.vim` は Home Manager で導入する。
- Zellij は `.config/zellij/config.kdl` の `scrollback_editor "vim"` で Vim を明示指定する。スクロール履歴を Vim で開き、下記の clipboard 連携を通して内容をコピーできるようにする。

### エディタとクリップボード

Vim の `.config/vim/vimrc` と Doom Emacs の `.config/doom/` でシステム clipboard に接続する。Linux では必要な `pkgs.wl-clipboard` と `pkgs.xclip` を Home Manager で導入する。連携方法は、利用可能なコマンドと環境変数に応じて次の順で選ぶ。

| 優先順 | 環境 | 外部コマンド |
| --- | --- | --- |
| 1 | WSL | `clip.exe` / `powershell.exe`（Vim は加えて `iconv`） |
| 2 | macOS | `pbcopy` / `pbpaste` |
| 3 | Wayland | `wl-copy` / `wl-paste` |
| 4 | X11 | `xclip` |

WSL のコピーは UTF-16LE、読み取りは UTF-8 を使い、貼り付け時に CRLF を LF に変換する。

- Vim の外部連携は clipboard provider 機能を前提とする。WSL は `WSL_DISTRO_NAME`、Wayland は `WAYLAND_DISPLAY`、X11 は `DISPLAY` も判定に使う。
- Vim は provider または組み込み clipboard 機能が使える場合、`unnamedplus` で通常の yank / delete / change / put をシステム clipboard に接続する。外部 provider の `+` / `*` register は同じ clipboard を使う。
- Doom Emacs の端末 frame は selection backend を通して、通常の kill / yank、Evil の `y` / `p`、`+` / `*` register をシステム clipboard に接続する。GUI frame と外部コマンドが利用できない環境は標準 backend を使う。

### Codex の管理対象

この節の path は repository root を基準とする。

| 対象 | 生成元・管理範囲 |
| --- | --- |
| グローバル指示 | `static/ln/.codex/` |
| 共通の Nix 開発環境 | `static/cp/.codex/flake.nix` |
| ユーザー共通の Skill | `static/cp/.agents/skills/`。通常 file として配置する |
| 外部ツールの実行許可 | `static/cp/.codex/rules/external-tools.rules` |

個別の Skill や許可コマンドは各設定ファイルで管理する。Codex 用の `flake.lock`、認証情報、履歴、セッション、キャッシュは管理対象に含めない。

Codex の作業環境自動作成ルールは `/etc/nixos` 以下を例外とする。システム設定への作業用 flake・direnv 設定の追加を避け、作業ツールは Codex の共通開発環境で管理する。
