# .dotfiles

自分用の dotfiles 管理リポジトリです。

`static/ln/` と `generated/` は `$HOME` へ symlink 展開し、`static/cp/` は file copy で展開します。`static/` は手で編集する dotfiles source、`generated/` は Nix build で生成する command / completion です。

Home Manager 設定は repository root の `home.nix` と `flake.nix` で管理します。dotfiles の file/symlink 配置は `static/`、`generated/`、`dotfiles-ln`、`dotfiles-cp` に任せ、Home Manager は package 管理を中心に使います。

## ディレクトリ構成

```text
.
├── Makefile        # 初期化、アンインストール、ビルド、検証の入口
├── default.nix     # generated/ 生成 package
├── flake.nix       # パッケージ、generated 生成、検証の入口
├── home.nix        # Home Manager 設定
├── static/         # ln/ と cp/ に分けた手書き dotfiles
├── generated/      # Nix build 済み command / completion
├── nix/            # dotfiles / dotfiles-ln / dotfiles-cp package 生成元
├── notes/          # 管理対象外のメモや作業用断片
├── SPEC.md         # 現在仕様
└── TASKS.md        # 未完了タスク
```

`static/ln/` と `static/cp/` は、それぞれ `$HOME` layout を直接編集します。`generated/` は `make build` または `dotfiles flake build` で再生成される成果物なので直接編集しません。

Codex のグローバル指示は `static/ln/.codex/`、共通のNix開発環境は `static/cp/.codex/flake.nix` で管理します。`flake.lock`、認証情報、履歴、セッション、キャッシュなどの実行時データは管理しません。

ユーザー共通の Codex Skill は `static/cp/.agents/skills/` で管理し、通常ファイルとして配置します。現在は Zellij のセッション、タブ、ペインを操作する `zellij` Skill を含みます。

Codex の外部ツールの実行許可ルールは `static/cp/.codex/rules/external-tools.rules` で管理します。配置後に Codex を再起動すると、`zellij` / `herdr` / `nix build` / `nix flake check` / `nix flake metadata` の実行時の承認確認を省略できます。

## セットアップ

Doom Emacs の端末版でも WSL / macOS / Wayland / X11 のクリップボードを自動選択します。Evil の `y` / `p` と `"+y` / `"+p`、Emacs 標準の `M-w` / `C-w` / `C-y` が連携します。Linux 用ツールは Vim と共通で Home Manager が導入します。設定反映には Emacs を再起動してください（`doom sync` は不要）。GUI 版は標準のクリップボード連携を使います。

Zellij は終了したセッションを一覧に残さないよう、復元用データの保存を無効にしています。

Vim の `y` / `yy` / `"+y` はシステムのクリップボードへコピーし、`p` / `"+p` はそこから貼り付けます。通常の削除・変更もクリップボードを更新します。Vim9script と Vim の clipboard provider 機能を使い、WSL は `clip.exe` / `powershell.exe` / `iconv`、macOS は `pbcopy` / `pbpaste`、Linux は Wayland の `wl-copy` / `wl-paste` または X11 の `xclip` を自動選択します。Linux 用ツールは Home Manager で導入します。`make init` で `.config/vim/vimrc` を配置し、Home Manager の switch 後に Vim を開き直してください。連携先のない端末環境では自動連携しません。SSH 先では接続先のクリップボードが対象です。

```sh
git clone https://github.com/emanon-was/.dotfiles.git "$HOME/.dotfiles"
cd "$HOME/.dotfiles"
make init
```

`make init` は `static/ln/` と `generated/` をsymlink、`static/cp/` をcopyで `$HOME` へ展開します。既存pathは管理対象と同じ状態ならkeepし、異なる場合は上書きせずconflictとして扱います。

`make init` 後は `$HOME/.local/bin` に `dotfiles` dispatcher と関連 command が入ります。

```sh
dotfiles --help
dotfiles configure --help
dotfiles flake --help
```

`dotfiles` dispatcher は実行場所から dotfiles の root を検出し、子 command に環境変数を渡します。

`DOTFILES_HOME` には検出した repository root または local root が入ります。repository root は `flake.nix`、`home.nix`、`nix/` がある directory、local root は `.local/bin` と `.local/share/dotfiles` がある directory です。

`dotfiles flake` は、この repository の root flake に対する操作を `--impure` 付きで短く呼ぶための便利 command です。`dotfiles flake build` は `generated/` を再生成します。Home Manager 自体は通常の `nix` / `home-manager` command でも使えます。

## アンインストール

`static/` と `generated/` で展開したfileとsymlinkを外す場合:

```sh
make clean
```

symlinkのinstall/uninstallには `dotfiles-ln`（`dotfiles ln`）、copyには `dotfiles-cp`（`dotfiles cp`）を使います。既存ファイルは上書きも退避もしません。`dotfiles-cp unapply` はsourceと内容が同一のcopyだけを削除し、変更済みfileはconflictとして残します。

## Home Manager

Home Manager 設定は repository root の `home.nix` に置き、root の `flake.nix` が `homeConfigurations.default` を出力します。

Nixpkgs は `NIX_PATH` の `<nixpkgs>` を使います。Home Manager 自体も同じ Nixpkgs に含まれる `pkgs.home-manager` から取得するため、Nixpkgs channel の更新に合わせて両方が更新されます。root flake は input と `flake.lock` を持ちません。

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

`dotfiles flake switch` は `home-manager` command に依存せず、activation package を `nix build --no-link` で build して `activate` を実行します。

この Home Manager 設定は package 管理を中心にし、dotfiles の file/symlink 配置は `static/`、`generated/`、`dotfiles-ln`、`dotfiles-cp` に任せます。`home.file` などで同じpathを管理するとconflictの原因になります。

### Home Manager の無効化

Home Manager で有効にした package や option を外す場合は、`home.nix` から該当項目を削除してから再度 switch します。

```sh
home-manager --impure --flake "$HOME/.dotfiles#default" switch
```

または:

```sh
dotfiles flake switch
```

Home Manager は世代管理なので、直前の状態に戻したい場合は generation を確認し、戻したい generation の `activate` を実行します。

```sh
home-manager generations
/nix/store/...-home-manager-generation/activate
```

古い generation が不要になったら、必要に応じて削除します。

```sh
home-manager expire-generations '-30 days'
```

Home Manager 管理自体をこの user から外したい場合は、Home Manager の uninstall command を使います。

```sh
home-manager uninstall
```

古い導入方法や手動 cleanup で user profile に `home-manager-path` が残っている場合は、Nix profile から削除します。

```sh
nix-env -q
nix-env -e home-manager-path
```

`make clean` は `static/` と `generated/` の管理対象fileとsymlinkを外すだけで、Home Manager の package や generation は変更しません。

## ドキュメント

- [SPEC.md](./SPEC.md): 現在仕様
- [TASKS.md](./TASKS.md): 未完了タスクと作業時の注意
- [ROADMAP.md](./ROADMAP.md): タスク化前の方向性、マイルストーン、設計メモ
- [static](./static): symlink用 `ln/` とcopy用 `cp/` に分けた `$HOME` layoutのdotfiles
- [generated](./generated): Nix build 済み command / completion
- [nix/dotfiles](./nix/dotfiles): `dotfiles` CLI package
- [nix/dotfiles-ln](./nix/dotfiles-ln): `dotfiles-ln` package
- [nix/dotfiles-cp](./nix/dotfiles-cp): `dotfiles-cp` package
- [notes/README.md](./notes/README.md): 管理対象外メモ

## 開発

build と検証には Nix を使います。Go の開発ツールは flake の dev shell で提供します。

共通の `~/.config/direnv/direnvrc` は `use flake` / `use nix` を読み込む前の `$SHELL` を保持します。nix-direnv を使う場合は、その読み込み後にこの設定を読み込んでください。直接の `nix develop` / `nix-shell` は対象外です。すでに `$SHELL` が変わった環境を復元する処理は含みません。

```sh
nix develop --impure
gopls version
```

repo root の `go.work` で `nix/dotfiles/src`、`nix/dotfiles-ln/src`、`nix/dotfiles-cp/src` をworkspaceとして扱います。

`generated/` は `make build` で再生成される成果物です。直接編集せず、生成元を変更してから再生成します。
再生成時にはコピー先に所有者の書き込み権限を付与するため、その後の `git pull` でも成果物を更新できます。

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
