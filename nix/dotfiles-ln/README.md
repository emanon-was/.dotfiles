# nix/dotfiles-ln

`dotfiles-ln` の Nix packaging です。

## 役割

`static/ln` と `generated` の install/uninstall に使う `dotfiles-ln` binary を生成します。

completion はこの package の `completions/` を生成元にします。

## ファイル

- `default.nix`: Go 製 `dotfiles-ln` を生成します。
- `SPEC.md`: `dotfiles-ln` package の現在仕様。
- `completions/`: `dotfiles-ln` の bash / zsh completion。
- `src/cmd/dotfiles-ln`: Go 製 symlink sync tool。

## 確認

```sh
nix build .#dotfiles-ln --no-link
make build
make check
```
