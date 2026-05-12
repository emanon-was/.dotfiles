# Dotfiles Tasks

このファイルは、今後の作業で参照する未完了タスクをまとめる場所です。
現在仕様は [SPEC.md](./SPEC.md) にまとめます。
完了済みの移行履歴はここには残さず、必要な情報は README と git log を参照します。

## 未完了タスク

現時点では未完了タスクなし。

新しい作業を始める場合は、この section に `- [ ] ...` として追加します。

## 注意点

- ユーザーの未コミット変更を勝手に戻さない。
- `dist/` を直接編集しない。
- `gsettings` や `doom install` のような副作用コマンドを Home Manager activation に入れない。
- `doom sync` は `dotfiles flake switch` から明示的に呼び出す。Home Manager module の評価や activation に重いネットワーク処理を混ぜない。
