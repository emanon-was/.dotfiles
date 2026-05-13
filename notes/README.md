# notes

Home Manager 管理対象ではない個人メモ置き場です。

## 役割

Home Manager 管理対象ではない個人メモ置き場です。

## 管理対象との関係

ここに置いたファイルは `dotfiles flake switch` では `$HOME` に配置されません。

正式に管理したい設定に昇格する場合は、対応する生成元へ移動します。

- Doom Emacs: `home/config/doom/`
- Home Manager module: `home/*.nix`

ここに置いたファイルは `dist/install.sh` でも `$HOME` に配置されません。

非 Nix 環境へ持ち出したい内容にする場合は、notes ではなく Home Manager / dist の生成対象へ移します。

## 現在の内容

- `emacs/emacs.el`: Doom Emacs の正式設定には入れない Emacs Lisp のメモ。
