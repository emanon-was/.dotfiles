# .dotfiles

自分用の dotfiles 管理リポジトリです。

`nix/` から配布用の `profile/` を生成し、`profile/` を `$HOME` へ symlink 展開して使います。build には Nix を使いますが、生成済みの `profile/` を展開するだけなら Nix は不要です。

Home Manager 設定も `profile/.config/home-manager/` に含めますが、このリポジトリだけで Home Manager 管理を完結させる前提ではありません。展開後の `$HOME/.config/home-manager` を標準配置として使います。

## ディレクトリ構成

```text
.
├── Makefile        # 初期化、アンインストール、ビルド、検証の入口
├── flake.nix       # パッケージ、profile 生成、検証の入口
├── nix/            # profile 生成 builder と Nix package 生成元
├── nix/etc/        # profile/ と同じ layout の dotfiles source
├── profile/        # Nix build 済みの配布用成果物
├── notes/          # 管理対象外のメモや作業用断片
├── SPEC.md         # 現在仕様
└── TASKS.md        # 未完了タスク
```

`profile/` は自動生成される成果物です。直接編集せず、`nix/etc/`、`nix/bin/` などの生成元を変更してから `make build` で再生成します。

## Profile

### セットアップ

```sh
git clone https://github.com/emanon-was/.dotfiles.git "$HOME/.dotfiles"
cd "$HOME/.dotfiles"
make init
```

`make init` は `profile/` を `$HOME` へ symlink 展開します。既存ファイルは上書きせず conflict として扱います。

### 使い方

`make init` 後は `$HOME/.local/bin` に `dotfiles` dispatcher と関連 command が入ります。

```sh
dotfiles --help
dotfiles configure --help
dotfiles flake --help
```

`dotfiles` dispatcher は実行場所から dotfiles の root を検出し、子 command に環境変数を渡します。

`DOTFILES_HOME` には検出した repository root または profile root が入ります。repository root は `flake.nix` と `nix/` がある directory、profile root は `.local/bin` と `.local/share/dotfiles` がある directory です。

`DOTFILES_HOME` を外部から指定した場合も repository root または profile root として検証されます。

`dotfiles flake` は、Home Manager 標準配置に対する `check` / `build` / `switch` を短く呼ぶための便利 command です。Home Manager 自体は通常の `nix` / `home-manager` command でそのまま使います。

### アンインストール

`profile/` で展開した symlink を外す場合:

```sh
make clean
```

profile install/uninstall は `symsync` を使います。既存ファイルは上書きも退避もせず conflict として扱い、uninstall は `profile` 配下を指す symlink だけを削除します。

## Home Manager

`profile/` には Home Manager の標準配置も含めます。

```sh
profile/.config/home-manager/flake.nix
profile/.config/home-manager/home.nix
```

profile 展開後は `$HOME/.config/home-manager` として使えます。Home Manager の実運用は展開済みの `$HOME/.config/home-manager` が主体です。repo 内の `nix/etc/.config/home-manager` は seed / build check 用です。

Home Manager を使う場合は、展開後の `$HOME/.config/home-manager` を通常の Home Manager flake として扱います。

この Home Manager flake は `USER` と `HOME` から `home.username` と `home.homeDirectory` を決めます。そのため、実行時は `--impure` を付けて実環境の値を渡します。`--impure` なしで `USER` または `HOME` が読めない場合は評価エラーになります。

```sh
nix flake check --impure "$HOME/.config/home-manager"
home-manager --impure --flake "$HOME/.config/home-manager#default" build
home-manager --impure --flake "$HOME/.config/home-manager#default" switch
```

### Tips

Home Manager の操作は、repo 内の `nix/etc/.config/home-manager` ではなく、展開済みの `$HOME/.config/home-manager` に対して行います。

初回や大きい変更後は、先に `build` で評価と build を確認してから `switch` します。

Home Manager の flake は、内部的に次の出力を持ちます。

```text
homeConfigurations.default.activationPackage
```

これは Home Manager 設定を適用するための成果物です。Nix で直接 build できます。

```sh
nix build --impure "$HOME/.config/home-manager#homeConfigurations.default.activationPackage"
```

build された成果物には `activate` script が入っています。

```sh
./result/activate
```

つまり `home-manager --flake ... switch` は、おおまかには activation package を build して、その中の `activate` script を実行する便利 command として扱えます。

この Home Manager 設定は package 管理を中心にし、dotfiles の file/symlink 配置は `profile/` と `symsync` に任せます。`home.file` などで同じ path を管理すると conflict の原因になります。

## ドキュメント

- [SPEC.md](./SPEC.md): 現在仕様
- [TASKS.md](./TASKS.md): 未完了タスクと作業時の注意
- [ROADMAP.md](./ROADMAP.md): タスク化前の方向性、マイルストーン、設計メモ
- [nix/etc](./nix/etc): `profile/` と同じ layout の dotfiles source
- [nix/README.md](./nix/README.md): `profile/` 生成
- [nix/bin/README.md](./nix/bin/README.md): command package 生成元
- [nix/bin/dotfiles/README.md](./nix/bin/dotfiles/README.md): `dotfiles` CLI
- [notes/README.md](./notes/README.md): 管理対象外メモ

## 開発

build と検証には Nix を使います。Go の開発ツールは flake の dev shell で提供します。

```sh
nix develop
gopls version
```

repo root の `go.work` で `nix/bin/dotfiles/src` と `nix/bin/symsync/src` を workspace として扱います。

`profile/` は `make build` で再生成される成果物です。直接編集せず、生成元を変更してから再生成します。
