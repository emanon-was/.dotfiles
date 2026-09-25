# dotfiles-ln Package Specification

`nix/dotfiles-ln` の現在仕様をまとめます。

## 方針

- この package は `dotfiles-ln` binary package として完結する。
- `dotfiles` dispatcher package とは別 package とし、相互依存させない。
- `static/ln` / `generated` 展開で利用する symlink tree synchronization の挙動は、この package の Go test で検査する。
- generated 成果物側のテストでは `dotfiles-ln apply/unapply` の詳細挙動を検査しない。
- completion はこの package の `completions/` を生成元にする。

## 成果物

- `dotfiles-ln`
  - source tree を destination tree に symlink で反映する command。
- bash completion
  - `share/bash-completion/completions/dotfiles-ln`
- zsh completion
  - `share/zsh/site-functions/_dotfiles-ln`

## CLI

```sh
dotfiles-ln apply --src <src> --dest <dest> [--dry-run]
dotfiles-ln unapply --src <src> --dest <dest> [--dry-run]
```

- `--src` は source tree を指定する。
- `--dest` は destination tree を指定する。
- `--dry-run` は filesystem を変更せず、予定される action を表示する。
- `--src` と `--dest` は必須。
- `src` は directory でなければならない。
- `src` と `dest` は absolute clean path に正規化して扱う。

## apply

- `src` 配下の directory は `dest` 側に directory として作成する。
- `src` 配下の file と symlink は `dest` 側に symlink として作成する。
- symlink target は対応する `src` entry の absolute path とする。
- `dest` 側に通常 directory が既にある場合は keep する。
- `dest` 側に同じ `src` entry を指す managed symlink が既にある場合は keep する。
- `dest` 側に既存 file、既存の非 directory path、別 target の symlink がある場合は conflict とする。
- conflict がある場合、filesystem を変更せず exit code 1 で終了する。

## unapply

- `src` 配下に対応する `dest` 側 symlink のうち、target が `src` 配下を指すものだけを削除する。
- 通常 file、通常 directory、`src` 配下を指さない symlink は削除しない。
- relative symlink は destination path から解決し、解決後 target が `src` 配下であれば削除対象にする。
- directory は削除しない。

## Action

- `link`
  - symlink を作成する。
- `mkdir`
  - directory を作成する。
- `keep`
  - 既存 entry をそのまま使う。
- `conflict`
  - 既存 entry または traversal error により反映できない。
- `unlink`
  - managed symlink を削除する。

## 生成元

- `default.nix`
  - Go binary と completion を package 化する。
- `src/cmd/dotfiles-ln`
  - symlink synchronization tool。
- `completions/bash/dotfiles-ln`
  - bash completion。
- `completions/zsh/_dotfiles-ln`
  - zsh completion。

## テスト

- dotfiles-ln の挙動テストは Go の標準に合わせ、`src/cmd/dotfiles-ln/main_test.go` に置く。
- `make check` は `nix/dotfiles-ln/src` で `go test ./...` を実行する。
- generated 構造テストでは、`dotfiles-ln` binary と completion が含まれることだけを確認する。
