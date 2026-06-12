# .dotfiles

自分用の dotfiles 管理リポジトリです。

`nix/` から配布用の `profile/` を生成し、`profile/` を `$HOME` へ symlink 展開して使います。build には Nix を使いますが、生成済みの `profile/` を展開するだけなら Nix は不要です。

Home Manager 設定は repository root の `home.nix` と `flake.nix` で管理します。dotfiles の file/symlink 配置は `profile/` と `symsync` に任せ、Home Manager は package 管理を中心に使います。

## ディレクトリ構成

```text
.
├── Makefile        # 初期化、アンインストール、ビルド、検証の入口
├── flake.nix       # パッケージ、profile 生成、検証の入口
├── home.nix        # Home Manager 設定
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

`DOTFILES_HOME` には検出した repository root または profile root が入ります。repository root は `flake.nix`、`home.nix`、`nix/` がある directory、profile root は `.local/bin` と `.local/share/dotfiles` がある directory です。

`DOTFILES_HOME` を外部から指定した場合も repository root または profile root として検証されます。

`dotfiles flake` は、この repository の root flake に対する操作を短く呼ぶための便利 command です。`dotfiles flake build` は `profile/` を再生成します。Home Manager 自体は通常の `nix` / `home-manager` command でも使えます。

### アンインストール

`profile/` で展開した symlink を外す場合:

```sh
make clean
```

profile install/uninstall は `symsync` を使います。既存ファイルは上書きも退避もせず conflict として扱い、uninstall は `profile` 配下を指す symlink だけを削除します。

## Home Manager

Home Manager 設定は repository root の `home.nix` に置き、root の `flake.nix` が `homeConfigurations.default` を出力します。`profile/` には Home Manager flake を含めません。

この Home Manager flake は `USER` と `HOME` から `home.username` と `home.homeDirectory` を決めます。そのため、実行時は `--impure` を付けて実環境の値を渡します。`--impure` なしで `USER` または `HOME` が読めない場合は評価エラーになります。

```sh
nix flake check --impure "$HOME/.dotfiles"
home-manager --impure --flake "$HOME/.dotfiles#default" build
home-manager --impure --flake "$HOME/.dotfiles#default" switch
```

初回や大きい変更後は、先に `build` で評価と build を確認してから `switch` します。

Home Manager の flake は、内部的に次の出力を持ちます。

```text
homeConfigurations.default.activationPackage
```

これは Home Manager 設定を適用するための成果物です。Nix で直接 build できます。

```sh
nix build --impure "$HOME/.dotfiles#homeConfigurations.default.activationPackage"
```

build された成果物には `activate` script が入っています。

```sh
./result/activate
```

つまり `home-manager --flake ... switch` は、おおまかには activation package を build して、その中の `activate` script を実行する便利 command として扱えます。

`dotfiles flake switch` は `home-manager` command に依存せず、activation package を `nix build --no-link` で build して `activate` を実行します。`dotfiles flake update` は root flake の `flake.lock` を更新します。

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

## Tips

bash の login shell は `.bash_profile` を読みますが、`.bashrc` は自動では読みません。そのため、bash login shell でも interactive 設定を使う場合は、`.bash_profile` から `.bashrc` を読み込ませます。

```text
bash login interactive
  -> .bash_profile
       -> .bashrc
            -> .profile.d/*.sh
```

bash の non-login interactive shell は `.bashrc` だけを読みます。この構成では `.bashrc` から `.profile.d/*.sh` を読み込みます。

zsh の login interactive shell は、login 用の `.zprofile` と interactive 用の `.zshrc` を段階的に読みます。そのため、`.zprofile` から `.zshrc` を読み込ませる必要はありません。

```text
zsh login interactive
  -> .zprofile
  -> .zshrc
       -> .profile.d/*.sh
```

zsh の non-login interactive shell は `.zshrc` だけを読みます。この構成では `.zshrc` から `.profile.d/*.sh` を読み込みます。

共通環境変数は `.profile.d/env.sh` に置き、shell 固有の history、completion、prompt などは `.bashrc` / `.zshrc` に置きます。PATH は重複しないよう、不足している entry だけ追加します。
