# Dotfiles Agents

この repo の作業規範です。`SPEC.md`、`TASKS.md`、各 README と合わせて使います。速度より慎重さを少し優先し、小さな作業では過剰にしません。

## 作業の判断と変更範囲

- 推測で進めず、前提と tradeoff を明示する。不確実な点は確認し、解釈が複数あれば候補を示す。依頼が曖昧なら止まり、曖昧な点を具体的に伝える。
- 変更対象が `static/`、`generated/`、Home Manager 標準配置、Nix package のどれに関わるかを確認する。
- 依頼を満たす最小の変更にする。より単純な方法があれば伝え、変更が大きくなりすぎたら見直す。
- 求められていない機能、柔軟性、設定項目、1 回しか使わない処理の抽象化、実際には起きない状況への複雑な error handling を追加しない。
- 既存 style に合わせる。無関係な code、comment、format を変更せず、壊れていないものを refactor しない。
- 自分の変更で不要になった import、変数、関数は削除する。もともと存在する無関係な dead code は、依頼がない限り削除せず報告する。

## パッケージとソースの責務

- `nix/dotfiles/` は dispatcher package として完結させ、shell subcommand を含めない。
- `static/ln/.local/bin/` は shell subcommand の source 置き場とし、dispatcher package へ依存させない。個別 command 名や挙動は拡張領域として扱い、作業規範や repo 全体仕様へ固定しない。
- repo 全体の仕様、docs、tests、flake check は、`static/ln/.local/bin/` 配下の個別 file 名や中身に依存させない。
- `nix/dotfiles/`、`nix/dotfiles-ln/`、`nix/dotfiles-cp/`、`static/ln/.local/bin/` の間に相互依存を作らない。共有が必要な場合は、どの aggregate 層に置くべきかを先に確認する。
- root `default.nix` は `generated/` 成果物の生成に集中させ、個別 command package の内部構造へ直接依存させない。
- `static/` は `$HOME` に置くファイルの source tree とし、command package や completion の生成元を置かない。
- `static/cp/.codex/flake.nix` はコピー元の雛形として、基本的にツール宣言を追加しない。AI の作業ツールは実際の `$CODEX_HOME/flake.nix`（未設定なら `~/.codex/flake.nix`）に追加する。

## 生成物と Home Manager の配置

- `generated/` は直接編集しない。必ず生成元を変更してから `make build` で再生成する。
- 生成済み `generated/` に `/nix/store` や固定の `/home/<user>` path を残さない。
- Home Manager の build / switch に外部環境へ副作用を起こす処理を入れない。
- Home Manager は任意ユーザーと `root` で動くことを前提にし、固定のユーザー home path を埋め込まない。
- `static/` / `generated/` の展開では既存ファイルを上書きせず conflict として扱う。Home Manager の `.hm-backup` は、この repo の Makefile で manifest 管理しない。

## 検証とテストの責務

- 作業前に成功条件を決める。複数 step の作業では、短い plan と各 step の確認方法を持つ。
- validation の追加では無効 input の test を通す。bug 修正では再現 test または確認手順を用意して通し、refactor では前後で既存 test が通ることを確認する。
- tests は Nix 前提とし、通常は `make check` を実行する。`generated/` 生成が絡む場合は `make build` 後に `make check` を実行する。Makefile の挙動変更では必要に応じて `make -n ...` で確認する。
- `nix/dotfiles` のテストは `nix/dotfiles/src` 配下の Go test とする。dispatcher の挙動変更では、同じ Go package の `*_test.go` を更新する。
- `dotfiles-ln` と `dotfiles-cp` の挙動は、それぞれの `nix/<command>/src` 配下の Go test で検査する。
- `generated/` のテストは成果物の基本構成確認に留め、`apply/unapply` の詳細挙動を検査しない。
- shell helper や `static/ln/.local/bin/` の個別テストは、明示的な必要がない限り追加しない。

## 仕様と文書の更新

- 挙動を変えたら、仕様、docs、tests、生成物を同期する。
- `AGENTS.md` には作業規範だけを書く。現在の詳細仕様は `SPEC.md`、利用者向け説明は README に分ける。
- 挙動変更は `SPEC.md` に反映し、未完了の作業や懸念は `TASKS.md` に記載する。
