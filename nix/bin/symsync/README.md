# nix/bin/symsync

`symsync` の Nix packaging です。

## 役割

profile install/uninstall に使う `symsync` binary を生成します。

completion はこの package の `completions/` を生成元にします。

## ファイル

- `default.nix`: Go 製 `symsync` を生成します。
- `SPEC.md`: `symsync` package の現在仕様。
- `completions/`: `symsync` の bash / zsh completion。
- `src/cmd/symsync`: Go 製 symlink sync tool。

## 確認

```sh
nix build .#symsync --no-link
make build
make check
```
