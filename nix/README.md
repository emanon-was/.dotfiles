# nix

配布用 `profile/` の生成元です。

## 役割

`dotfiles-profile` package を作り、その成果物から repository root の `profile/` を再生成します。

`profile/` は成果物なので直接編集しません。挙動を変える場合は、`nix/etc/`、この directory、または `nix/bin/` 側の生成元を編集します。

`dotfiles-profile` は `nix/etc/` を source tree として使います。

## 生成

```sh
make build
```

生成された repository root の `profile/` を `$HOME` へ symlink 展開して使います。

```sh
make init
make clean
```

## 内容

- `default.nix`: `dotfiles-profile` package の定義。
- `etc/`: `profile/` と同じ layout の静的 dotfiles source。
- `etc/.config/home-manager/`: Home Manager 標準配置用の設定。
- `profile/.local/bin/`: `nix/bin` の profile 用 package から集約した command。
- `profile/.local/share/bash-completion/`: 各 command package から集約した bash completion。
- `profile/.local/share/zsh/site-functions/`: 各 command package から集約した zsh completion。

## install / uninstall

profile の展開は `symsync` で行います。

```sh
profile/.local/bin/symsync apply --src profile --dest "$HOME"
profile/.local/bin/symsync unapply --src profile --dest "$HOME"
```

`symsync apply --dry-run` と `symsync unapply --dry-run` は filesystem を変更せず、実行予定の操作と conflict を表示します。

## 検証

変更後は必要に応じて以下を実行します。

```sh
make build
make check
```

`make build` 後は `profile/` の差分を確認します。
