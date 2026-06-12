# nix/bin/dotfiles

`dotfiles` CLI の Nix packaging です。

## 役割

`dotfiles` dispatcher と `dotfiles configure` dispatcher を生成します。

completion はこの package の `completions/` を生成元にします。

## Dispatcher package

Go 製 dispatcher と completion を生成します。

## コマンド構成

`dotfiles` は Cargo 風の dispatcher です。

```sh
dotfiles <subcommand>
```

同じ directory または `PATH` 上にある `dotfiles-<subcommand>` を実行します。

`dotfiles configure` は `dotfiles-configure` dispatcher を経由します。

```sh
dotfiles configure <subcommand>
```

## Environment

dispatcher は repository root または profile root を検出し、子 command に環境変数を渡します。

`DOTFILES_HOME` には検出した root が入ります。

repository root は `flake.nix`、`home.nix`、`nix/` がある directory、profile root は `.local/bin` と `.local/share/dotfiles` がある directory です。外部から `DOTFILES_HOME` を指定した場合も同じ条件で検証します。

## ファイル

- `default.nix`: Go 製 dispatcher を生成します。
- `SPEC.md`: dispatcher package の現在仕様。
- `completions/`: `dotfiles` dispatcher の bash / zsh completion。
- `src/cmd/dotfiles`: Go 製 dispatcher。
- `src/cmd/dotfiles-configure`: Go 製 configure dispatcher。

## 設計ルール

- dispatcher は sibling command を `PATH` より優先します。
- dispatcher は repository root または profile root を検出し、子 command に environment を渡します。
- dispatcher の Go test は `src/cmd/*/*_test.go` に置きます。

## 確認

```sh
make check
```
