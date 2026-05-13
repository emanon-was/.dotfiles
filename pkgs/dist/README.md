# pkgs/dist

Nix なし環境へ持ち出す `dist/` の生成元です。

## 役割

`dotfiles-dist` package を作り、その成果物から repository root の `dist/` を再生成します。

`dist/` は成果物なので直接編集しません。install/uninstall の挙動を変える場合は、この directory の生成元を編集します。

## 確認

Home Manager / flake 環境では通常 `dist/` を直接使いません。

この directory は、非 Nix 環境用の成果物を Nix で生成するために使います。

```sh
make dist-build
make dist
```

## 非 Nix 環境での使い方

生成された repository root の `dist/` を非 Nix 環境へ持ち出して使います。

```sh
make init.dist
make clean.dist
```

## ファイル

- `default.nix`: `dotfiles-dist` package の定義。
- `scripts/install.sh`: `dist/install.sh` の生成元。
- `scripts/uninstall.sh`: `dist/uninstall.sh` の生成元。

## install

`dist/install.sh` は `dist/home-files/` の内容を `$HOME` へ直接 symlink します。

- `$HOME/home-files` のような managed copy は作りません。
- 既存ファイルや既存 symlink は `.backup`, `.backup.1`, ... に退避します。
- 既存ディレクトリは残し、配下の対象ファイルを個別に symlink します。
- install manifest は `$HOME/.local/state/dotfiles/install-manifest.tsv` に保存します。

## uninstall

`dist/uninstall.sh` は install manifest を参照します。

- 管理対象 symlink を削除します。
- install 時に退避した backup があれば元の名前へ戻します。
- 元の名前に別ファイルがある場合は上書きせず skip します。

## 生成

```sh
make dist-build
make dist
```

`make dist` 後は `dist/` の差分を確認します。
