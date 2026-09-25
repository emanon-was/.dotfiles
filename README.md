# .dotfiles

シェル、エディタ、ターミナルなどの設定と、普段使うパッケージを管理する個人用リポジトリです。

設定ファイルは `make init` でホームディレクトリに配置し、パッケージは Home Manager で導入します。この2つは別々に適用します。

## セットアップ

Git、Make、flakes を使える Nix が必要です。Nixpkgs は root の `flake.nix` に宣言した `nixos-unstable` を使い、`flake.lock` でリビジョンを固定します。Home Manager も flake input として取得・固定し、同じ Nixpkgs を共有するため、最初から `home-manager` コマンドが入っている必要はありません。

### 1. 設定ファイルを配置する

```sh
git clone https://github.com/emanon-was/.dotfiles.git "$HOME/.dotfiles"
cd "$HOME/.dotfiles"
make init
```

既存ファイルは上書きしません。配置先が管理対象と同じ状態ならそのまま使い、異なる場合は競合として報告します。

`make init` は同梱の `generated/` を使います。別の環境向けにビルドし直す必要がある場合は、先に `make build` を実行してください。

### 2. パッケージを導入する

まず Home Manager の設定をビルドして確認します。

```sh
nix build --impure .#homeConfigurations.default.activationPackage --no-link
```

成功したら適用します。

```sh
./generated/.local/bin/dotfiles flake switch
```

この操作はパッケージを導入し、Home Manager の設定を有効にします。完了後はシェルやエディタを開き直してください。`$HOME/.local/bin` に PATH が通っていれば、以後は `dotfiles` として実行できます。

Home Manager は実行ユーザーの `USER` と `HOME` を使います。Nix を直接実行するときに `--impure` が必要なのはこのためです。Nixpkgs と Home Manager はシステムやユーザーの channel に依存しません。更新する場合はリポジトリで `nix flake update` を実行し、`make build` と `make check` で確認して `flake.lock` と生成物を commit します。

## 設定を変更する

| 変更したいもの | 編集する場所 | 反映方法 |
| --- | --- | --- |
| シンボリックリンクで配置する設定 | `static/ln/` | 既存ファイルの内容は直接反映。追加したら `make init` |
| コピーで配置する設定 | `static/cp/` | 配置先と内容を確認して反映。`make init` は異なる内容を上書きしない |
| 導入するパッケージ | `home.nix` | `dotfiles flake switch` |
| Go 製コマンドや補完の生成元 | `nix/`、`default.nix` | `make build` → `make check` → `make init` |

`static/ln/` と `static/cp/` は、ホームディレクトリと同じ構成です。例えば `static/ln/.config/vim/vimrc` は `~/.config/vim/vimrc` に配置されます。アプリが設定を読み直すには、再起動や再読み込みが必要な場合があります。

`generated/` は生成物なので直接編集しません。また、同じ設定ファイルを Home Manager の `home.file` などでも配置すると競合します。

よく使うコマンドは次のとおりです。`make` はリポジトリのルートで実行します。

| コマンド | 用途 |
| --- | --- |
| `make init` | 設定ファイルと生成済みコマンドを配置する |
| `make build` | `generated/` を再生成する |
| `make check` | Nix 経由でテストと生成物の検証を行う |
| `dotfiles flake switch` | Home Manager の設定をビルドして適用する |
| `dotfiles --help` | 利用できるコマンドを確認する |

## 主な設定

### エディタとクリップボード

Vim と端末版 Doom Emacs は、WSL・macOS・Wayland・X11 に合わせてシステムのクリップボードへ接続します。Linux 用の `wl-clipboard` と `xclip` は Home Manager で導入します。WSL では Windows の `clip.exe` / `powershell.exe`、Vim では加えて `iconv` が PATH 上に必要です。

設定元は [Vim](./static/ln/.config/vim/vimrc) と [Doom Emacs](./static/ln/.config/doom/config.el) です。Vim は Vim9script と clipboard provider 機能を使います。通常のコピー・貼り付けに加え、削除・切り取りもクリップボードを更新します。SSH 先では接続先のクリップボードが対象です。

Doom Emacs の GUI 版は標準の連携を使います。クリップボード設定の反映は Emacs の再起動だけでよく、`doom sync` は不要です。

### ターミナルとシェル

- Herdr のサイドバーは、起動時に最小表示になります。
- Zellij は復元用セッションを保存せず、スクロール履歴エディタに Vim を使います。
- 共通の環境変数は `static/ln/.profile.d/env.sh`、シェル別の設定は `.bashrc` / `.zshrc` に置きます。
- bash / zsh は Emacs キーバインドを使用します。
- 外部エディターは `EDITOR=vim` / `VISUAL=vim` に設定しています。Codex の `Ctrl+G` でも Vim が開きます。変更前から開いているシェルでは `source ~/.profile.d/env.sh` を実行し、Codex を起動し直してください。
- direnv の `use flake` / `use nix` は、読み込み前の `$SHELL` を保持します。nix-direnv を使う場合は、その読み込み後にこのリポジトリの `direnvrc` を読み込んでください。

### Codex

グローバル指示は `static/ln/.codex/`、共通の Nix 開発環境は `static/cp/.codex/flake.nix`、Skill は `static/cp/.agents/skills/` で管理します。認証情報・履歴・セッション・キャッシュは管理対象に含めません。

外部ツールの実行許可ルールは `static/cp/.codex/rules/external-tools.rules` にあります。変更は Codex を再起動すると反映されます。

## 設定を外す

ホームディレクトリへ配置した設定とコマンドを外すには、リポジトリのルートで実行します。

```sh
make clean
```

管理対象のリンクと、配置元と内容が同じコピーを削除します。配置後に変更されたコピーは競合として残します。Home Manager のパッケージや世代は削除しません。

パッケージを個別に外す場合は `home.nix` から削除して `dotfiles flake switch` を実行します。Home Manager による管理自体を終了する場合は、次を実行します。

```sh
home-manager uninstall
```

## 開発と構成

開発環境には Go と gopls が含まれています。

```sh
nix develop --impure
make check
```

生成元を変更した場合は `make build` のあとに `make check` を実行します。ルートの `go.work` で3つの Go パッケージをまとめて扱えます。

| 場所 | 役割 |
| --- | --- |
| `static/ln/`、`static/cp/` | 手で編集する設定ファイル |
| `generated/` | 生成済みのコマンドと補完 |
| `nix/` | `dotfiles`、`dotfiles-ln`、`dotfiles-cp` の実装 |
| `default.nix` | `generated/` の生成定義 |
| `home.nix` | Home Manager の設定 |
| `flake.nix` | パッケージ・開発環境・検証の入口 |
| `Makefile` | 配置・削除・ビルド・検証の入口 |
| `notes/` | ホームへの配置対象外のメモ |

詳しい仕様や個別コマンドの説明は、以下を参照してください。

- [SPEC.md](./SPEC.md)：現在の仕様と設定の詳細
- [TASKS.md](./TASKS.md)：未完了の作業と注意点
- [ROADMAP.md](./ROADMAP.md)：今後の方向性
- [dotfiles](./nix/dotfiles/README.md)：コマンドの振り分け
- [dotfiles-ln](./nix/dotfiles-ln/README.md)：シンボリックリンクの配置・削除
- [dotfiles-cp](./nix/dotfiles-cp/README.md)：ファイルのコピー・削除
- [notes](./notes/README.md)：メモの扱い
