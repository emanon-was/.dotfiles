# .dotfiles

自分用の dotfiles 管理リポジトリです。

基本方針は、普段使う環境では Home Manager で宣言的に管理し、Nix や Home Manager を使えない環境では `dist/` に生成した成果物を展開して使う、という分け方です。

NixOS の system 側は stable を使い、このリポジトリの Home Manager 側は `nixos-unstable` を使います。system 側の `configuration.nix` には極力寄せず、ユーザー環境の設定は Home Manager と `dotfiles` コマンドへ寄せます。

## ディレクトリ構成

```text
.
├── home/                 Home Manager の module と、その module が使う設定ファイル
│   ├── *.nix             shell、git、tmux、screen、Emacs などの Home Manager 設定
│   └── config/           Home Manager で配置する手書き設定の生成元
├── pkgs/dotfiles/        `dotfiles` CLI と `dist/` 生成 package の生成元
│   ├── scripts/          `dotfiles-*` サブコマンドの shell script
│   ├── templates/        `dotfiles project init ...` で使うテンプレート
│   └── dist/             `dist/install.sh` など配布用 script の生成元
├── notes/                Home Manager 管理対象ではない個人メモ
├── dist/                 Nix build で生成した配布用成果物
├── flake.nix             Home Manager、CLI package、dist package の入口
├── flake.lock            flake input の lock file
├── Makefile              repo 開発用の build/check/dist 操作
└── TASKS.md              作業方針と残タスク
```

基本的にメンテナンスするのは `home/`、`pkgs/dotfiles/`、`notes/`、`README.md`、`TASKS.md` です。

`dist/` は `make dist` で再生成される成果物置き場です。Nix や Home Manager が使えない環境へ持ち出すために commit しますが、手で編集する場所ではありません。`dist/` の内容を変えたい場合は、対応する生成元を編集してから `make dist` を実行します。

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

`dist/install.sh` は `dist/home-files/` の内容を `$HOME` へ直接 symlink します。`$HOME/home-files` のような管理用 copy は作りません。
`dotfiles` コマンド群も通常の home file として以下へ symlink されます。

```text
$HOME/.local/bin
```

コマンドの実体は `dist/home-files/.local/bin` に生成されます。

`dist/home-files/` には Home Manager から生成した `$HOME` 用 dotfiles が入ります。Nix なし環境で使う場合は、この内容を確認して必要なものだけ `$HOME` に配置します。
既存ファイルや既存 symlink がある場合は `.backup` 付きの別名へ退避してから symlink を作成します。既存ディレクトリは残し、その配下に必要な symlink を作成します。
`uninstall.sh` は管理対象 symlink を削除したあと、対応する `.backup` が残っていれば元の名前へ戻します。
`dist/` は home-files の展開専用です。project init 用テンプレートは `home-files/.local/share/dotfiles/templates/` に含まれます。

アンインストールする場合:

```sh
./dist/uninstall.sh
```

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

`dotfiles configure doom install` と `dotfiles configure doom upgrade` では、Doom が生成・更新する `config.el` と `home/config/doom/config.el` の差分を確認してから、Home Manager 管理の symlink を戻します。差分が出た場合は `var/doom-config-diffs/*.patch` にも保存します。

初回 install の流れだけを検証したい場合:

```sh
dotfiles configure doom install --check
```

## templates

プロジェクト用テンプレートの生成元は `pkgs/dotfiles/templates/` です。
Nix package では `share/dotfiles/templates/` に入り、Home Manager と dist では `~/.local/share/dotfiles/templates/` に配置されます。

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

`make dist` は `.#dotfiles-dist` をビルドし、その成果物で `dist/` を再生成します。`dist/` 配下は生成物なので、修正が必要な場合は `pkgs/dotfiles/`、`home/` などの生成元を編集します。

## メモ

Home Manager 管理対象ではない Emacs Lisp のメモは `notes/emacs/` に置きます。
