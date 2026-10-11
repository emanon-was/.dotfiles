# .dotfiles

シェル、エディタ、ターミナルなどの設定と、普段使うパッケージを管理する個人用リポジトリです。

設定ファイルの配置とパッケージの導入は、別々に適用します。

- 設定ファイル：`make init` でホームディレクトリに配置します。
- パッケージ：Home Manager で導入します。

## セットアップ

- 必要なコマンドは Git、Make、flakes を使える Nix です。
- `home-manager` コマンドを事前に導入する必要はありません。
- Nix の依存関係：
  - Nixpkgs はルートの `flake.nix` に宣言した `nixos-unstable` を使います。
  - Nixpkgs と Home Manager は flake input として取得し、`flake.lock` でリビジョンを固定します。
  - Home Manager は同じ Nixpkgs を共有します。
  - システムやユーザーの channel に依存しません。
- 実行ユーザー：
  - Home Manager は実行ユーザーの `USER` と `HOME` を使います。
  - Nix を直接実行するときは、この環境変数を読み込むために `--impure` が必要です。

### 1. 設定ファイルを配置する

```sh
git clone https://github.com/emanon-was/.dotfiles.git "$HOME/.dotfiles"
cd "$HOME/.dotfiles"
make init
```

- 既存ファイルは上書きしません。
  - 配置先が管理対象と同じ状態なら、そのまま使います。
  - 配置先が管理対象と異なる場合は、競合として報告します。
- `make init` は同梱の `generated/` を使います。
  - 別の環境向けにビルドし直す必要がある場合は、先に `make build` を実行してください。

### 2. パッケージを導入する

まず Home Manager の設定をビルドして確認します。

```sh
nix build --impure .#homeConfigurations.default.activationPackage --no-link
```

成功したら適用します。

```sh
./generated/.local/bin/dotfiles flake switch
```

- この操作でパッケージを導入し、Home Manager の設定を有効にします。
- 完了後はシェルやエディタを開き直してください。
- `$HOME/.local/bin` に PATH が通っていれば、以後は `dotfiles` として実行できます。

## 設定を変更する

| 変更したいもの | 編集する場所 | 反映方法 |
| --- | --- | --- |
| シンボリックリンクで配置する設定 | `static/ln/` | 既存ファイルの内容は直接反映。追加したら `make init` |
| コピーで配置する設定 | `static/cp/` | 配置先と内容を確認して反映。`make init` は異なる内容を上書きしない |
| 導入するパッケージ | `home.nix` | `dotfiles flake switch` |
| Go 製コマンドや補完の生成元 | `nix/`、`default.nix` | `make build` → `make check` → `make init` |

- `static/ln/` と `static/cp/` は、ホームディレクトリと同じ構成です。
  - 例えば `static/ln/.config/nvim/init.lua` は `~/.config/nvim/init.lua` に配置されます。
- アプリが設定を読み直すには、再起動や再読み込みが必要な場合があります。
- `generated/` は生成物なので直接編集しません。
- 同じ設定ファイルを Home Manager の `home.file` などでも配置すると競合します。

よく使うコマンドは次のとおりです。`make` はリポジトリのルートで実行します。

| コマンド | 用途 |
| --- | --- |
| `make init` | 設定ファイルと生成済みコマンドを配置する |
| `make build` | `generated/` を再生成する |
| `make check` | Nix 経由でテストと生成物の検証を行う |
| `dotfiles flake switch` | Home Manager の設定をビルドして適用する |
| `dotfiles --help` | 利用できるコマンドを確認する |

### 依存関係を更新する

リポジトリのルートで、次の順に実行します。

1. `nix flake update` で依存関係を更新します。
2. `make build` で生成物を再ビルドします。
3. `make check` で検証します。
4. `flake.lock` と生成物を commit します。

## 主な設定

### Neovim と LazyVim

- 導入するパッケージ：
  - Neovim は Home Manager で導入します。
  - Linux では、クリップボード連携用の `wl-clipboard` と `xclip` も導入します。
- 設定とプラグイン：
  - [LazyVim の公式 starter](https://www.lazyvim.org/installation) を元にした設定を [static/ln/.config/nvim](./static/ln/.config/nvim/init.lua) から配置します。
  - 既存の Neovim 設定やデータがある場合は、リンクを配置する前に退避してください。
  - 初回起動時に lazy.nvim と LazyVim のプラグインが GitHub から取得されます。
  - プラグインの版は同ディレクトリの `lazy-lock.json` で固定します。

導入・確認は、次の順に行います。

1. `dotfiles flake switch` を実行します。
2. `./generated/.local/bin/dotfiles-ln apply --src static/ln --dest "$HOME"` で設定を配置します。
3. `nvim` を起動します。
4. Neovim で `:LazyHealth` を実行して状態を確認します。

- ファイルエクスプローラー（Snacks Explorer）：
  - `Space` → `e`：Explorer を開きます。
  - ノーマルモードの `Space` → `f` → `D`：現在のバッファーのファイルがあるディレクトリを開きます。
  - 初期状態では dot ファイルと Git で無視されたファイルを表示します。
  - Explorer 内の `H`：dot ファイルの表示を切り替えます。
  - Explorer 内の `I`：Git で無視されたファイルの表示を切り替えます。
- キャンセル操作（`Ctrl-g`）：
  - 編集中：`Esc` と同様にモードを抜けます。
  - Snacks の一覧：画面を閉じます。
  - Neovim 内のターミナル：入力モードを抜けます。

### シェルとターミナル

- シェルの共通設定：
  - 共通の環境変数は `static/ln/.profile.d/env.sh`、シェル別の設定は `.bashrc` / `.zshrc` に置きます。
  - bash / zsh は Emacs キーバインドを使用します。
  - 外部エディターは `EDITOR=nvim` / `VISUAL=nvim` に設定しています。
  - `sudoedit` 用エディターは `SUDO_EDITOR=nvim` に設定しています。
- direnv：
  - `use flake` / `use nix` は、読み込み前の `$SHELL` を保持します。
  - nix-direnv を使う場合は、その読み込み後にこのリポジトリの `direnvrc` を読み込んでください。
- ターミナル：
  - Herdr のサイドバーは、起動時に最小表示になります。
  - Zellij は復元用セッションを保存せず、スクロール履歴エディタに Neovim を使います。

### Codex

- 管理する設定：
  - グローバル指示：`static/cp/.codex/AGENTS.md` で管理します。
  - 共通の Nix 開発環境：`static/cp/.codex/flake.nix` で管理します。
  - Skill：`static/cp/.agents/skills/` で管理します。
  - 外部ツールの実行許可ルール：`static/cp/.codex/rules/external-tools.rules` で管理します。
  - 実行許可ルールの変更は、Codex を再起動すると反映されます。
- 外部エディターとの連携：
  - `Ctrl+G` で Neovim が開きます。
  - 変更前から開いているシェルでは `source ~/.profile.d/env.sh` を実行し、Codex を起動し直してください。
- 認証情報・履歴・セッション・キャッシュは管理対象に含めません。

## 設定を外す

ホームディレクトリへ配置した設定とコマンドを外すには、リポジトリのルートで実行します。

```sh
make clean
```

- `make clean` で外すもの：
  - 管理対象のリンクを削除します。
  - 配置元と内容が同じコピーを削除します。
  - 配置後に変更されたコピーは、競合として残します。
- Home Manager のパッケージ：
  - `make clean` ではパッケージや世代を削除しません。
  - パッケージを個別に外す場合は、`home.nix` から削除して `dotfiles flake switch` を実行します。

Home Manager による管理自体を終了する場合は、次を実行します。

```sh
home-manager uninstall
```

## 開発と構成

開発環境には Go と gopls が含まれています。

```sh
nix develop --impure
make check
```

- 生成元を変更した場合は、`make build` のあとに `make check` を実行します。
- ルートの `go.work` で3つの Go パッケージをまとめて扱えます。

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
