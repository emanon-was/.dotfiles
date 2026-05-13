# tests

`nix flake check` から実行する非破壊テストです。

## 役割

`nix flake check` から実行する非破壊テストです。

## 実行環境

`make check` は `nix flake check` を実行し、Nix sandbox 内でテストします。

tests は Nix 環境でのみ build / 実行する前提です。非 Nix 環境では実行対象にしません。

`tests/*.sh` は repository 開発用です。`nix flake check` 経由でのみ実行でき、直接実行した場合は失敗します。非 Nix 環境に持ち出した `dist/` 上で実行するものではありません。

## 実行

```sh
make check
```

Home Manager switch そのものは実行せず、profile / user 解決など副作用のない範囲を検査します。

dist install/uninstall のテストも Nix sandbox 内で一時 HOME を使って実行します。

非 Nix 環境で直接テストを走らせる前提ではありません。非 Nix 向けの成果物は `make dist` 後に `dist/` の差分として確認します。

```sh
make dist-install-check
```

## ファイル

- `dotfiles-flake-switch.sh`: `dotfiles flake switch` の profile / user 解決を検査します。
- `dotfiles-commands.sh`: dispatcher、project init、source resolver、configure doctor を検査します。
- `dotfiles-dist-install.sh`: `dist/install.sh` / `dist/uninstall.sh` の symlink と restore を一時 HOME で検査します。

## 方針

- 実ユーザーの `$HOME` は変更しません。
- dist install/uninstall は一時 directory の HOME だけを使います。
- network や実際の Doom install は実行しません。
- flake switch は対象解決を検査し、実際の Home Manager switch は実行しません。

## target

```sh
make check
make command-check
make switch-check
make dist-install-check
```

これらの Makefile target も内部では `nix flake check` を実行します。
