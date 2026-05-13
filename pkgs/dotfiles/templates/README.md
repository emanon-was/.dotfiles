# templates

`dotfiles project init ...` で展開するプロジェクトテンプレートです。

## Home Manager / flake

### 仕様

Nix package では template が `share/dotfiles/templates` に入り、Home Manager が `~/.local/share/dotfiles/templates` へ配置します。

### 使い方

```sh
dotfiles project init nix [destination]
dotfiles project init docker [destination]
```

## dist / 非 Nix

### 仕様

`make dist` 後、template は `dist/home-files/.local/share/dotfiles/templates` に含まれます。

`dist/install.sh` 後は、Home Manager 版と同じように `~/.local/share/dotfiles/templates` から参照されます。

### 使い方

```sh
dotfiles project init nix [destination]
dotfiles project init docker [destination]
```

## 利用

```sh
dotfiles project init nix [destination]
dotfiles project init docker [destination]
```

`destination` を省略すると現在の directory に展開します。

## 配置

- Nix package: `share/dotfiles/templates`
- Home Manager / dist: `~/.local/share/dotfiles/templates`

## 追加ルール

- template 名は directory 名と一致させます。
- テストは特定ファイル名に強く依存せず、template directory 全体の copy 結果を比較します。
- template 内に Makefile 相当を置く場合は、用途が分かる名前にします。

## 現在の template

- `nix`: flake / direnv 用の最小構成。
- `docker`: Dockerfile、entrypoint、docker 用 make fragment。
