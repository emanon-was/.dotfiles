# Dotfiles Tasks

このファイルは、今後の作業で参照する未完了タスクをまとめる場所です。
現在仕様は [SPEC.md](./SPEC.md) にまとめます。

## 未完了タスク

- [ ] README 構成を見直す。環境を大項目にする形は root `README.md` のみにし、その他の README は各 directory の役割に合わせて適切に書き直す。
- [ ] `dist/` は出力成果物であるため、どのように扱うべきか、何を直接編集してはいけないか、生成元はどこかを関連 README に明記する。
- [ ] tests は非 Nix 環境では実行対象にしない。Nix 環境でのみ build / 実行する前提を `tests/README.md` など関連箇所に明記する。
- [ ] `dotfiles flake switch` 実行後に Home Manager 管理をやめる、または元に戻す手順を用意する。
- [ ] 各セットアップ手順に対応する Makefile target を追加する。

## 注意点

- ユーザーの未コミット変更を勝手に戻さない。
- `dist/` を直接編集しない。
- `gsettings` や `doom install` のような副作用コマンドを Home Manager activation に入れない。
- `doom sync` は `dotfiles flake switch` から明示的に呼び出す。Home Manager module の評価や activation に重いネットワーク処理を混ぜない。
