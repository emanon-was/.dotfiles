# scripts

`dotfiles` CLI の shell script 生成元です。

## 役割

`dotfiles` CLI の shell script 生成元です。

## Nix package 版 command

Nix package 版 command は `writeShellApplication` で生成されます。runtimeInputs は `pkgs/dotfiles/default.nix` に宣言します。

Home Manager 版では、生成された command が `$HOME/.local/bin` へ配置されます。

## portable command

portable command は同じ script 生成元から作られます。

portable command には `DOTFILES_PORTABLE_DIST=1` が埋め込まれ、`dist/home-files` 由来のファイルを参照します。

`dist/home-files/.local/bin` に出る command は成果物です。直接編集せず、この directory の script を変更して `make dist` で再生成します。

## 構成

- `dotfiles.sh`: dispatcher。
- `dotfiles-flake.sh`: flake / Home Manager 操作。
- `dotfiles-configure.sh`: Doom / GNOME など configure 系操作。
- `dotfiles-project.sh`: project template 展開。
- `lib/`: 各 command に前置される helper。

## 実行モデル

この directory の script は基本的に単体実行しません。

`pkgs/dotfiles/default.nix` が以下を結合して、実行可能な command を作ります。

1. Nix から注入する変数
2. `lib/common.sh`
3. command ごとに必要な `lib/*.sh`
4. `dotfiles-*.sh`

## ルール

- script 冒頭に、前置される lib と注入変数をコメントで書きます。
- `lib/*.sh` 側には、読み込み順、依存関数、参照する環境変数を書きます。
- flake 依存は `dotfiles-flake.sh` に寄せます。
- 副作用のある設定操作は `dotfiles-configure.sh` に寄せます。
- project template 操作は `dotfiles-project.sh` に寄せます。
