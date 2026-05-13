# .dotfiles

自分用の dotfiles 管理リポジトリです。

普段使う環境では Home Manager と flake でユーザー環境を宣言的に管理し、Nix や Home Manager を使えない環境では `dist/` に生成した成果物を展開して使います。

NixOS の system 側は stable、このリポジトリの Home Manager 側は `nixos-unstable` を使います。system 側の `configuration.nix` には極力寄せず、ユーザー環境の設定は Home Manager と `dotfiles` コマンドへ寄せます。

## Home Manager / flake

### セットアップ

```sh
git clone https://github.com/emanon-was/.dotfiles.git "$HOME/.dotfiles"
cd "$HOME/.dotfiles"
make init
# or explicitly:
make init.flake
```

Doom Emacs が未セットアップの場合は、Home Manager 反映後に Doom 本体を用意します。

```sh
make init.doom
```

### 使い方

通常の更新:

```sh
dotfiles flake update
dotfiles flake switch
```

診断:

```sh
dotfiles flake doctor
dotfiles configure doctor
dotfiles configure doom doctor
dotfiles configure gnome doctor
```

Doom Emacs:

```sh
dotfiles configure doom install
dotfiles configure doom sync
dotfiles configure doom upgrade
dotfiles configure doom repair
```

GNOME:

```sh
dotfiles configure gnome
```

プロジェクトテンプレート:

```sh
dotfiles project init nix [destination]
dotfiles project init docker [destination]
```

### リストア

Home Manager でファイル衝突が起きた場合、`dotfiles flake switch` は `home-manager -b hm-backup` を使うため、既存ファイルは `.hm-backup` 付きで退避されます。必要に応じて退避ファイルを確認して戻します。

Home Manager の管理をやめる場合:

```sh
make clean.flake
```

この操作は Home Manager が管理している symlink や profile を外します。`.hm-backup` へ退避されたファイルを戻す必要がある場合は、内容を確認してから手で戻します。

Doom Emacs の管理設定で起動できなくなった場合:

```sh
dotfiles configure doom repair
```

## dist / 非 Nix

### セットアップ

```sh
make init
# or explicitly:
make init.dist
```

`dist/` は Nix build 済みの成果物です。Nix / Home Manager を使えない環境では、この内容を `$HOME` へ symlink して使います。

### 使い方

`dist/install.sh` 後は `$HOME/.local/bin` に `dotfiles` コマンド群が入ります。

```sh
dotfiles configure doctor
dotfiles configure doom doctor
dotfiles configure gnome doctor
dotfiles configure doom sync
dotfiles project init nix [destination]
dotfiles project init docker [destination]
```

flake / Home Manager に依存する操作は dist 前提では使いません。

```sh
dotfiles flake update
dotfiles flake switch
```

これらが必要な環境では Home Manager / flake 版を使います。

### リストア

`dist/install.sh` で展開した内容を戻す場合:

```sh
make clean.dist
```

`dist` の install/uninstall は `$HOME/.local/state/dotfiles/install-manifest.tsv` を使って、作成した symlink と退避した backup を管理します。

## ドキュメント

- [SPEC.md](./SPEC.md): 現在仕様
- [TASKS.md](./TASKS.md): 未完了タスクと作業時の注意
- [home/README.md](./home/README.md): Home Manager module と配置する設定ファイル
- [pkgs/README.md](./pkgs/README.md): Nix package 生成元
- [pkgs/dotfiles/README.md](./pkgs/dotfiles/README.md): `dotfiles` CLI
- [pkgs/dist/README.md](./pkgs/dist/README.md): `dist/` 生成
- [tests/README.md](./tests/README.md): テスト
- [notes/README.md](./notes/README.md): 管理対象外メモ

## 開発

```sh
make check
make flake-check
make dotfiles-build
make dist-build
make home-build
make dist
make init
make init.flake
make init.dist
make init.doom
make clean.flake
make clean.dist
```

`dist/` は `make dist` で再生成される成果物です。直接編集せず、生成元を変更してから再生成します。
