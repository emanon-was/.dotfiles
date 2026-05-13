# home/config

Home Manager で `$HOME` 配下へ配置する手書き設定の生成元です。

## Home Manager / flake

### 仕様

Home Manager がこの directory の内容を `$HOME` 配下へ配置します。

- `doom/` -> `~/.config/doom/`
- `tmux/tmux.conf` -> `~/.config/tmux/tmux.conf`
- `screen/screenrc` -> `~/.screenrc`

### 使い方

反映:

```sh
dotfiles flake switch
```

## dist / 非 Nix

### 仕様

非 Nix 環境では、この directory を直接参照しません。

`make dist` により Home Manager の build 成果物から `dist/home-files/` が作られ、`dist/install.sh` がそこから `$HOME` へ symlink します。

### 使い方

```sh
make dist
./dist/install.sh
```

## 方針

- ここにはアプリケーションが読む設定ファイルを置きます。
- Home Manager module のロジックは `home/*.nix` に置きます。
- Doom Emacs は `doom/` 配下全体を管理対象として扱います。
- dist 版にも必要なものは Home Manager の build 成果物を経由して `dist/home-files` に入ります。

## 注意

`dist/` 側を直接直さず、この directory か `home/*.nix` を変更してから `make dist` を実行します。
