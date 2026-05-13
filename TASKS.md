# Dotfiles Tasks

このファイルは、今後の作業で参照する未完了タスクをまとめる場所です。
現在仕様は [SPEC.md](./SPEC.md) にまとめます。

## 未完了タスク

- [ ] `dotfiles project init` が既存ファイルを黙って上書きしないようにする。既存ファイルがある場合は失敗させ、必要なら将来 `--force` を追加する。
- [ ] `dist/install.sh` と `dist/uninstall.sh` の復元処理を state/manifest ベースにする。install 時に作成した symlink、退避した backup path、元の path を記録し、uninstall 時はその manifest を参照して正確に戻す。
- [ ] dist install state の保存先を決める。候補は `$HOME/.local/state/dotfiles/install-manifest.tsv` または `$HOME/.local/state/dotfiles/dist-install.tsv`。XDG state としては `.local/state/dotfiles/` が自然。
- [ ] [home/gnome.nix](./home/gnome.nix) のコメントを現行コマンド `dotfiles configure gnome` に合わせる。

## 注意点

- ユーザーの未コミット変更を勝手に戻さない。
- `dist/` を直接編集しない。
- `gsettings` や `doom install` のような副作用コマンドを Home Manager activation に入れない。
- `doom sync` は `dotfiles flake switch` から明示的に呼び出す。Home Manager module の評価や activation に重いネットワーク処理を混ぜない。
