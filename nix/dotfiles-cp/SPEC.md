# dotfiles-cp Package Specification

`nix/dotfiles-cp` の現在仕様をまとめます。

## 方針

- この package は `dotfiles-cp` binary package として完結する。
- `dotfiles` dispatcher package や `dotfiles-ln` package とは相互依存させない。
- `static/cp` 展開で利用する copy tree synchronization の挙動は、この package の Go test で検査する。
- generated 成果物側のテストでは `dotfiles-cp apply/unapply` の詳細挙動を検査しない。
- completion はこの package の `completions/` を生成元にする。

## 成果物

- `dotfiles-cp`
  - source tree を destination tree に file copy で反映する command。
- bash completion
  - `share/bash-completion/completions/dotfiles-cp`
- zsh completion
  - `share/zsh/site-functions/_dotfiles-cp`

## CLI

```sh
dotfiles-cp apply --src <src> --dest <dest> [--dry-run]
dotfiles-cp unapply --src <src> --dest <dest> [--dry-run]
```

- `--src` は source tree を指定する。
- `--dest` は destination tree を指定する。
- `--dry-run` は filesystem を変更せず、予定される action を表示する。
- `--src` と `--dest` は必須。
- `src` は directory でなければならない。
- `src` と `dest` は absolute clean path に正規化して扱う。

## apply

- `src` 配下の directory は `dest` 側に directory として作成する。
- `src` 配下の file は対応する `dest` path に copy する。
- source file が symlink の場合は target の内容と permission を copy し、destination には通常 file を作る。
- `dest` 側に通常 directoryが既にある場合は keep する。
- `dest` 側に source と同一内容の通常 file がある場合は keep する。
- file permission の差だけでは conflict としない。
- `dest` 側に内容の異なる file、symlink、既存の非 directory path がある場合は conflict とする。
- conflict がある場合、filesystem を変更せず exit code 1 で終了する。

## unapply

- `src` 配下の file に対応する `dest` 側の通常 fileを、source と内容が同一の場合だけ削除する。
- 内容が異なる file、symlink、その他の path は conflict とする。
- 対応する destination が存在しない場合は何もしない。
- directory は削除しない。
- conflict がある場合、filesystem を変更せず exit code 1 で終了する。

## Action

- `copy`
  - file を新規作成する。
- `mkdir`
  - directory を作成する。
- `keep`
  - 既存 entry をそのまま使う。
- `conflict`
  - 既存 entry、内容差分、または traversal error により反映できない。
- `remove`
  - source と同一内容の destination file を削除する。

## 生成元

- `default.nix`
  - Go binary と completion を package 化する。
- `src/cmd/dotfiles-cp`
  - copy synchronization tool。
- `completions/bash/dotfiles-cp`
  - bash completion。
- `completions/zsh/_dotfiles-cp`
  - zsh completion。

## テスト

- dotfiles-cp の挙動テストは Go の標準に合わせ、`src/cmd/dotfiles-cp/main_test.go` に置く。
- `make check` は `nix/dotfiles-cp/src` で `go test ./...` を実行する。
- generated 構造テストでは、`dotfiles-cp` binary と completion が含まれることだけを確認する。
