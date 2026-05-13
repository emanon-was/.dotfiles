# home/config

Home Manager で `$HOME` 配下へ配置する手書き設定の生成元です。

## 役割

Home Manager がこの directory の内容を `$HOME` 配下へ配置します。

- `doom/` -> `~/.config/doom/`
- `tmux/tmux.conf` -> `~/.config/tmux/tmux.conf`
- `screen/screenrc` -> `~/.screenrc`

## 反映

反映:

```sh
dotfiles flake switch
# or
make init.flake
```

## dist への反映

非 Nix 環境では、この directory を直接参照しません。

`make dist` により Home Manager の build 成果物から `dist/home-files/` が作られ、`dist/install.sh` がそこから `$HOME` へ symlink します。

`dist/` は出力成果物なので直接編集しません。設定ファイルを変える場合はこの directory の生成元を編集してから `make dist` を実行します。

```sh
make dist
make init.dist
```

## 方針

- ここにはアプリケーションが読む設定ファイルを置きます。
- Home Manager module のロジックは `home/*.nix` に置きます。
- Doom Emacs は `doom/` 配下全体を管理対象として扱います。
- dist 版にも必要なものは Home Manager の build 成果物を経由して `dist/home-files` に入ります。

## 注意

`dist/` 側を直接直さず、この directory か `home/*.nix` を変更してから `make dist` を実行します。
