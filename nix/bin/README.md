# nix/bin

Nix package の生成元です。

## 役割

`nix/bin/default.nix` は `dotfiles` dispatcher、`symsync`、shell 製 subcommand をまとめた `dotfiles-bin` package を生成します。

`nix/bin/dotfiles/` は Go 製 `dotfiles` dispatcher を生成します。shell 製 subcommand は `nix/bin/default.nix` が source として読み込んで command 化します。

`nix/bin/dotfiles/` は dispatcher package として完結し、subcommand の実行可能 package への集約は `nix/bin/default.nix` の責務です。

`nix/bin/symsync/` は profile install/uninstall に使う `symsync` を生成します。

配布用 `profile/` は `nix/` で生成します。生成された `profile/` は成果物なので直接編集しません。

shell completion は各 command package 配下の `completions/` を生成元にします。

## 構成

- `dotfiles/`: `dotfiles` CLI package。
- `scripts/`: 拡張用 shell subcommand の source。
- `symsync/`: `symsync` package。

## 方針

- `profile/` 直下の成果物は直接編集しません。
- `dotfiles` dispatcher を変える場合は `nix/bin/dotfiles/` を編集します。
- `nix/bin/scripts/` 配下の個別 file 名や中身を、この README や repo 全体仕様では固定しません。
- `symsync` を変える場合は `nix/bin/symsync/` を編集します。
- `profile/` の生成内容を変える場合は `nix/` を編集します。
- 変更後は必要に応じて `make build` で成果物を再生成します。

## 確認

```sh
make build
```
