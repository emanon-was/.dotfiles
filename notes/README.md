# notes

Home Manager 管理対象ではない個人メモ置き場です。

## 役割

Home Manager 管理対象ではない個人メモ置き場です。

## 管理対象との関係

ここに置いたファイルは `$HOME` に配置する管理対象ではありません。

正式に管理したい設定に昇格する場合は、対応する生成元へ移動します。

- dotfiles: `static/`
- command: `static/.local/bin/`

ここに置いたファイルは `static/` / `generated/` にも含めません。

管理対象に含めたい内容にする場合は、notes ではなく `static/` などの生成対象へ移します。

## 現在の内容

- `emacs/emacs.el`: Doom Emacs の正式設定には入れない Emacs Lisp のメモ。
- `templates/`: project 用の参考ファイル。
