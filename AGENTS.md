# Dotfiles Agents

LLM が coding task で起こしがちなミスを減らすための作業規範です。必要に応じて `SPEC.md`、`TASKS.md`、各 README の repo 固有ルールと合わせて使います。

速度より慎重さを少し優先します。小さな作業では過剰にせず、状況に応じて判断します。

## 1. コードを書く前に考える

推測で進めない。不明点を隠さない。前提と tradeoff を明示します。

実装前に確認すること:

- 前提を明確にする。不確実なら確認する。
- 解釈が複数ある場合は、黙って一つを選ばず候補を示す。
- より単純な方法がある場合は伝える。
- 依頼内容が曖昧なら止まり、何が曖昧かを具体的に言う。

この repo では特に、`static/`、`generated/`、Home Manager 標準配置、Nix package のどれに関わる変更なのかを分けて考えます。

## 2. シンプルさを優先する

依頼を満たす最小の変更にします。推測で機能を増やしません。

- 求められていない機能を追加しない。
- 1回しか使わない処理に抽象化を足さない。
- 要求されていない柔軟性や設定項目を増やさない。
- 実際には起きない状況のために複雑な error handling を足さない。
- 変更が大きくなりすぎたら、より小さくできないか見直す。

この repo では、`dotfiles` CLI の dispatcher 構造を保ちます。`static/.local/bin/` 配下の個別 command 名や挙動は拡張領域として扱い、作業規範や repo 全体仕様へ固定しません。

## 3. 変更を局所化する

必要な箇所だけを触ります。ついでの改善や無関係な整形はしません。

既存 code を編集するとき:

- 隣接 code、comment、format をついでに改善しない。
- 壊れていないものを refactor しない。
- 既存 style に合わせる。
- 無関係な dead code に気づいた場合は、勝手に消さずに報告する。

自分の変更で不要になったものは片付けます。

- 自分の変更で未使用になった import、変数、関数は削除する。
- もともと存在した不要 code は、依頼がない限り削除しない。

この repo では、`generated/` を直接編集せず、生成元を直して必要なら `make build` を実行します。

## 4. 目標から逆算して実行する

成功条件を決め、確認できるところまで進めます。

曖昧な作業を検証可能な目標に変換します。

- 「validation を追加する」なら、無効 input の test を書き、それを通す。
- 「bug を直す」なら、再現する test または確認手順を作り、それを通す。
- 「refactor する」なら、前後で既存 test が通ることを確認する。

複数 step の作業では、短い plan と各 step の確認方法を持ちます。

例:

```text
1. 生成元を変更する -> verify: focused diff
2. generated を再生成する -> verify: make build
3. 挙動を確認する -> verify: make check
```

この repo では通常 `make check` を使います。`generated/` 生成に関わる変更では `make build` 後に `make check` を実行します。Makefile の挙動変更では必要に応じて `make -n ...` で確認します。

## 5. 仕様と生成物を同期する

挙動を変えたら、仕様、docs、tests、生成物を同期します。

- 現在仕様は `SPEC.md` に書く。
- 未完了の作業は `TASKS.md` に書く。
- 利用者向け説明は README に書く。
- `generated/` に影響する変更は、生成元を変更してから `make build` で反映する。
- 生成済み `generated/` に `/nix/store` や固定の `/home/<user>` path を残さない。
- `nix/dotfiles` の dispatcher 挙動を変えた場合は、Go の標準に合わせて同じ package 配下の `*_test.go` を更新する。

この規範がうまく機能している状態とは、差分が小さく、不要な変更が少なく、曖昧な点が実装後ではなく実装前に表面化している状態です。

## 6. Repo 固有の絶対ルール

- `generated/` は直接編集しない。必ず生成元を変更してから `make build` で再生成する。
- `nix/dotfiles/` は dispatcher package として完結させる。shell subcommand を含めない。
- `static/.local/bin/` は shell subcommand の source 置き場とし、dispatcher package へ依存させない。
- repo 全体の仕様、docs、tests、flake check は `static/.local/bin/` 配下の個別 file 名や中身に依存させない。
- root `default.nix` は `generated/` 成果物の生成に集中させ、個別 command package の内部構造へ直接依存させない。
- `nix/dotfiles/`、`nix/symsync/`、`static/.local/bin/` の間に相互依存を作らない。共有が必要な場合は、どの aggregate 層に置くべきかを先に確認する。
- `static/` は `$HOME` に置くファイルの source tree とし、command package や completion の生成元を置かない。
- `nix/dotfiles` のテストは Go test として `nix/dotfiles/src` 配下に置く。shell helper や `static/.local/bin/` の個別テストは、明示的な必要がない限り追加しない。
- `symsync` の挙動は `nix/symsync/src` 配下の Go test で検査する。`generated/` のテストは成果物の基本構成確認に留め、`symsync apply/unapply` の詳細挙動を generated 側で検査しない。
- Home Manager の build / switch に外部環境へ副作用を起こす処理を入れない。
- Home Manager は任意ユーザーと `root` で動くことを前提にする。`/home/nixos` や `/home/emanon` のような固定 path を埋め込まない。
- `static/` / `generated/` 展開では既存ファイルを上書きせず conflict として扱う。Home Manager の `.hm-backup` はこの repo の Makefile で manifest 管理しない。
- 挙動を変えた場合は `SPEC.md` を更新し、残作業や懸念は `TASKS.md` に追加する。
- tests は Nix 前提。通常は `make check`、`generated/` 生成が絡む場合は `make build` 後に `make check` を実行する。
- `AGENTS.md` には作業規範だけを書く。詳細仕様は `SPEC.md`、利用者向け説明は README に分ける。
