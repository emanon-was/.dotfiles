# home

Home Manager module と、Home Manager で配置する設定ファイルの生成元です。

## Home Manager / flake

### 仕様

- ユーザー環境の設定はできるだけ Home Manager module として管理します。
- 副作用のある処理は activation に入れず、`dotfiles configure ...` で明示実行します。
- `dotfiles flake switch` は Doom sync などの重い処理を実行しません。
- 任意ユーザーで動くように、固定の `/home/<name>` ではなく `username` / `homeDirectory` 引数を使います。

### 使い方

実環境への反映:

```sh
dotfiles flake switch
```

Home Manager profile の build:

```sh
make home-build
```

### module

- `default.nix`: Home Manager module の入口。
- `dotfiles.nix`: `dotfiles` package から `.local/bin` と template を配置します。
- `emacs.nix`: Emacs / Doom Emacs 関連。
- `git.nix`: Git 設定。
- `gnome.nix`: GNOME 関連の宣言的に置ける設定。
- `packages.nix`: ユーザー環境に入れる package。
- `screen.nix`: GNU Screen 設定。
- `shells.nix`: bash / zsh / prompt / alias。
- `tmux.nix`: tmux 設定。

### config

`config/` は Home Manager で配置する手書き設定の生成元です。

- `config/doom/`: `~/.config/doom/`
- `config/tmux/tmux.conf`: `~/.config/tmux/tmux.conf`
- `config/screen/screenrc`: `~/.screenrc`

Doom Emacs の設定は `config/doom/` 配下全体を管理対象として扱います。ファイルを追加した場合も同じ規則で `~/.config/doom/` へ配置されます。

## dist / 非 Nix

### 仕様

`home/` の module は非 Nix 環境では直接評価されません。

非 Nix 環境へ持ち出す内容は、Home Manager の build 成果物から `dist/home-files/` に生成されます。非 Nix 環境で挙動を変えたい場合も、基本的には `home/` または `pkgs/` 側の生成元を変更してから `make dist` を実行します。

### 使い方

```sh
make dist
./dist/install.sh
```
