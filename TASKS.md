# Dotfiles Tasks

このファイルは、今後の作業で参照する未完了タスクをまとめる場所です。
現在仕様は [SPEC.md](./SPEC.md) にまとめます。
タスク化前の方向性やマイルストーンは [ROADMAP.md](./ROADMAP.md) に残します。

## 未完了タスク

- [ ] flake 出力を `x86_64-linux` 固定から複数 system 対応へ広げるか検討する。

## 注意点

- ユーザーの未コミット変更を勝手に戻さない。
- `profile/` の生成済み成果物を直接編集しない。
- profile init / install / uninstall 系は、再実行しても既存の状態ファイルを空にしたり管理対象 entry を失ったりしないようにする。
- `gsettings` や `doom install` のような副作用コマンドを自動処理に入れない。
- Home Manager の build / switch に重いネットワーク処理を混ぜない。
