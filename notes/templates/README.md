# templates

project 用の参考ファイルです。

## 役割

ここにあるファイルは `static/` / `generated/` へ配置しません。必要になったときに手で参照する個人メモとして扱います。

## 追加ルール

- template 名は directory 名と一致させます。
- template 内に Makefile 相当を置く場合は、用途が分かる名前にします。

## 現在の template

- `nix`: flake / direnv 用の最小構成。
- `docker`: Dockerfile、entrypoint、docker 用 make fragment。
