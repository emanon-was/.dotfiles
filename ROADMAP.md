# Dotfiles Roadmap

このファイルは、まだ `TASKS.md` に入れるほど確定していない方向性、マイルストーン、設計メモを残す場所です。

## 使い分け

- `SPEC.md`: 現在の仕様。
- `TASKS.md`: 実装する前提がある未完了タスク。
- `ROADMAP.md`: まだ判断材料が足りない方向性、マイルストーン、将来案。
- `notes/`: Home Manager 管理対象ではない個人メモ。

## 書き方

- 具体的な作業に落ちたら `TASKS.md` へ移す。
- 現在仕様として固まったら `SPEC.md` へ移す。
- 解決済み、不要、採用しないと判断したものは削除する。

## マイルストーン候補

- profile 直下を `$HOME` へ symlink する layout は単純だが、`profile/` 自体に README や metadata を置きにくい。将来 metadata が必要になった場合は、管理対象外にする場所を別途決める。
