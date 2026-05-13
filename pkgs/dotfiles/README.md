# pkgs/dotfiles

`dotfiles` CLI package の生成元です。

## 役割

`dotfiles` CLI package の生成元です。Nix package 版 command と dist 用 portable command を同じ command 定義から生成します。

## Nix package 版

Nix package 版の `dotfiles` CLI を生成し、Home Manager が `$HOME/.local/bin` に配置します。

この場合、CLI は Nix store 内の成果物と `$HOME` に配置済みの file/link を参照します。

```sh
dotfiles flake check
dotfiles flake update
dotfiles flake switch
dotfiles flake doctor
```

## portable 版

portable command が `dist/home-files/.local/bin` に生成され、`dist/install.sh` により `$HOME/.local/bin` へ symlink されます。

この場合、CLI は dist 由来の配置済みファイルを参照します。flake / Home Manager に依存する操作は前提にしません。

```sh
dotfiles configure doctor
dotfiles configure doom doctor
dotfiles project init nix
```

## コマンド構成

`dotfiles` は Cargo 風の dispatcher です。

```sh
dotfiles <subcommand>
```

同じ directory または `PATH` 上にある `dotfiles-<subcommand>` を実行します。

主要コマンド:

```sh
dotfiles flake check
dotfiles flake update
dotfiles flake switch [current|dist|user]
dotfiles flake doctor
dotfiles configure doctor
dotfiles configure gnome
dotfiles configure gnome doctor
dotfiles configure doom install [--check]
dotfiles configure doom sync
dotfiles configure doom upgrade
dotfiles configure doom repair
dotfiles configure doom doctor
dotfiles project init <nix|docker> [destination]
```

## ファイル

- `default.nix`: Nix package 版 command と dist 用 portable command を生成します。
- `scripts/dotfiles.sh`: dispatcher。
- `scripts/dotfiles-flake.sh`: flake / Home Manager 操作。
- `scripts/dotfiles-configure.sh`: Doom / GNOME など副作用のある設定操作。
- `scripts/dotfiles-project.sh`: project template 展開。
- `scripts/lib/`: command に前置される shell helper。
- `templates/`: `dotfiles project init ...` 用 template。

## 依存関係

`scripts/dotfiles-*.sh` は単体実行ではなく、`default.nix` が `scripts/lib/common.sh` と必要な lib を前置して command 化します。

各 script の冒頭コメントに、前置される lib と Nix から注入される変数を記載します。`scripts/lib/*.sh` 側にも、読み込み順と依存する関数・環境変数を記載します。

## 設計ルール

- flake 依存の操作は `dotfiles flake ...` に置きます。
- Doom / GNOME のような設定操作は `dotfiles configure ...` に置きます。
- 汎用の `dotfiles doctor` は置かず、`dotfiles flake doctor` と `dotfiles configure doctor` に分けます。
- Nix package 版は package 内の成果物を参照します。
- Home Manager 版は `$HOME` に配置済みの file/link を参照します。
- dist 版は `dist/home-files` 由来の配置済みファイルを参照します。
- `dist/home-files/.local/bin` は生成物です。直接編集せず、`scripts/` または `default.nix` を変更して `make dist` で再生成します。

## テンプレート

生成元は `templates/` です。

- `templates/nix`
- `templates/docker`

Nix package では `share/dotfiles/templates` に入り、Home Manager / dist では `~/.local/share/dotfiles/templates` に配置されます。

## 確認

```sh
make command-check
make dotfiles-build
make check
```
