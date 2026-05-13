# pkgs

Nix package の生成元です。

## 役割

`pkgs/dotfiles/` は Home Manager から参照され、`~/.local/bin` と `~/.local/share/dotfiles/templates` に配置される `dotfiles` CLI を生成します。

`pkgs/dist/` は非 Nix 環境へ持ち出す `dist/` を生成します。生成された `dist/` は成果物なので直接編集しません。

## CLI package build

```sh
make dotfiles-build
make setup-flake
```

## dist 生成

```sh
make dist-build
make dist
make setup-dist
```

## 構成

- `dotfiles/`: `dotfiles` CLI package。
- `dist/`: Nix なし環境へ持ち出す `dist/` の package。

## 方針

- `dist/` 直下の成果物は直接編集しません。
- CLI や portable command を変える場合は `pkgs/dotfiles/` を編集します。
- `dist/install.sh` / `dist/uninstall.sh` を変える場合は `pkgs/dist/` を編集します。
- 変更後は必要に応じて `make dist` で成果物を再生成します。

## 確認

```sh
make dotfiles-build
make dist-build
make dist
```
