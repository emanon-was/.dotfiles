# nix/dotfiles-cp

`dotfiles-cp` の Nix packaging です。

## 役割

`static/cp` の install/uninstall に使う `dotfiles-cp` binary を生成します。

completion はこの package の `completions/` を生成元にします。

## ファイル

- `default.nix`: Go 製 `dotfiles-cp` を生成します。
- `SPEC.md`: `dotfiles-cp` package の現在仕様。
- `completions/`: `dotfiles-cp` の bash / zsh completion。
- `src/cmd/dotfiles-cp`: Go 製 copy sync tool。

## 確認

```sh
nix build .#dotfiles-cp --no-link
make build
make check
```
