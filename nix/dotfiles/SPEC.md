# dotfiles Package Specification

`nix/dotfiles` の現在仕様をまとめます。

## 方針

- この package は `dotfiles` dispatcher package として完結する。
- completion はこの package の `completions/` を生成元にする。

## 成果物

- `dotfiles`
  - Cargo 風 dispatcher。
  - `dotfiles <command> [args...]` を `dotfiles-<command>` へ dispatch する。
- `dotfiles-configure`
  - configure 用 dispatcher。
  - `dotfiles configure <command> [args...]` を `dotfiles-configure-<command>` へ dispatch する。
- bash completion
  - `share/bash-completion/completions/dotfiles`
- zsh completion
  - `share/zsh/site-functions/_dotfiles`

## Dispatcher

- subcommand は、dispatcher executable と同じ directory の sibling command を優先して探す。
- sibling command が見つからない場合は `PATH` 上の command を探す。
- `dotfiles --commands` は dispatch 可能な top-level command 名を出力する。
- `dotfiles --help` は usage と command list を出力する。
- top-level help では、親 command がある nested command を隠す。
  - 例: `dotfiles-configure` が存在する場合、`configure` は表示し、`configure-nested` は表示しない。

## Configure Dispatcher

- `dotfiles configure <command>` は `dotfiles-configure-<command>` を実行する。
- `dotfiles configure --commands` は configure command 名を出力する。
- `dotfiles configure --help` は usage と configure command list を出力する。

## Environment

- `dotfiles` dispatcher は子 command に `DOTFILES_HOME` を渡す。
- repository root は `flake.nix`、`home.nix`、`nix/` がある directory とする。
- local root は `.local/bin` と `.local/share/dotfiles` がある directory とする。
- executable から上位 directory を探索し、repository root より手前で local root が見つかった場合は local root を採用する。
- 外部から渡された `DOTFILES_HOME` は repository root または local root として validation する。
- validation に失敗した場合、dispatcher は子 command を実行せず usage error として終了する。

## 生成元

- `default.nix`
  - Go dispatcher binary と completion を package 化する。
- `src/cmd/dotfiles`
  - top-level dispatcher。
- `src/cmd/dotfiles-configure`
  - configure dispatcher。
- `completions/bash/dotfiles`
  - bash completion。
- `completions/zsh/_dotfiles`
  - zsh completion。

## テスト

- dispatcher のテストは Go の標準に合わせ、対象 package と同じ directory の `*_test.go` に置く。
- `make check` は `nix/dotfiles/src` で `go test ./...` を実行する。
