# Dotfiles Modernization Tasks

このファイルは、次のエージェントがこの dotfiles リポジトリを Home Manager ベースへ移行するための作業タスクです。

## 現状メモ

- 旧 `store/` は廃止済み。
- 旧 `store.list` ベースの symlink 管理は廃止済み。
- `Makefile` は repo 開発用の Nix build/check/dist 操作に使う。
- `dotfiles` CLI は Cargo 風に `dotfiles-<subcommand>` executable へ dispatch する。
- 旧 `bin/` スクリプトは廃止済み。
- `home/config/doom/config.el` に Home Manager 管理の Doom Emacs 設定がある。
- Doom の `init.el` と `packages.el` は Doom 側の更新対象として扱い、この repo では管理しない。
- `project-templates/` にはプロジェクト用テンプレートがある。

## 方針

- symlink 管理を Home Manager の宣言的設定へ置き換え済み。
- 副作用のある処理は Home Manager 評価時に実行しない。
- `gsettings`、Doom Emacs install、テンプレートコピーなどは `dotfiles` CLI の明示サブコマンドにする。
- Emacs 本体と Doom Emacs の設定ファイルは Home Manager で管理する。
- Doom Emacs の更新・設定変更後には `doom sync` を実行できる導線を用意する。
- tmux/screen などの手書き設定は `home/config/` 配下に置く。
- Nix の構成は flake ベースにする。

## Phase 1: Home Manager の入口を作る

- [x] `flake.nix` を追加する。
  - Home Manager standalone で利用できる構成にする。
  - まずは現在のホスト/ユーザー向け profile を 1 つ定義する。
  - `home-manager switch --flake .#<profile>` で切り替えできる形にする。

- [x] `home/default.nix` を追加する。
  - `home.stateVersion` を明示する。
  - `imports` で分割 module を読み込める構成にする。

- [x] Home Manager module の置き場を作る。
  - 例:

    ```text
    home/
      default.nix
      packages.nix
      shells.nix
      git.nix
      tmux.nix
      gnome.nix
      emacs.nix
    ```

## Phase 2: 既存 dotfiles を Home Manager へ移す

- [x] shell 設定を移行する。
  - 移行先:

    ```nix
    programs.bash
    programs.zsh
    home.shellAliases
    home.sessionVariables
    home.sessionPath
    ```

  - 完了条件:
    - bash/zsh 起動時に既存の alias、PATH、direnv hook が再現される。
    - 旧 shell 設定の内容が Home Manager module に反映される。

- [x] tmux 設定を移行する。
  - `home/config/tmux/tmux.conf` を `programs.tmux.extraConfig` で読む。
  - 完了条件:
    - prefix、status line、copy mode、pane keybind が再現される。

- [x] screen 設定を移行する。
  - `home/config/screen/screenrc` を `home.file.".screenrc".source` で管理する。
  - 利用頻度が低ければ無理に module 化しない。

- [x] git 設定を移行する。
  - `bin/git-config-global.sh` の内容を `programs.git` へ移す。
  - 設定値:

    ```nix
    programs.git = {
      enable = true;
      userName = "Daigo Kawasaki";
      userEmail = "emanon.was@gmail.com";
    };
    ```

- [x] `store.list` ベースの symlink 管理を廃止する。
  - `store.list` を削除する。
  - `bin/.dotfiles-*` の symlink 操作用スクリプトを削除する。
  - `make plan/init/clean/backup/restore` を削除する。

## Phase 3: `dotfiles` CLI を作る

- [x] Nix で `dotfiles` コマンドを提供する。
  - `writeShellApplication` などを使う。
  - `home.packages` に追加して利用可能にする。
  - `dotfiles` 本体は dispatcher にし、`dotfiles-<subcommand>` を PATH から実行する。

- [x] `dotfiles doctor` を実装する。
  - 確認項目:
    - `nix`
    - `home-manager`
    - `git`
    - `direnv`
    - `gsettings`
    - Doom Emacs の checkout 状態
    - `$DOTFILES_HOME`
  - 完了条件:
    - 不足しているものを exit code とメッセージで判別できる。

- [x] `dotfiles flake switch` を実装する。
  - `home-manager -b hm-backup --flake "$DOTFILES_HOME#<profile>" switch` を呼ぶ。
  - profile 指定方法は引数または環境変数で決める。

- [x] `dotfiles flake check` を実装する。
  - `nix flake check` を実行する。
  - 必要なら Home Manager の評価チェックも追加する。

- [x] `dotfiles flake update` を実装する。
  - `nix flake update` を実行する。
  - 実行後に `dotfiles flake check` を促すか、自動実行するか決める。

- [x] `dotfiles configure gnome` を実装する。
  - 既存の `bin/gnome-settings.sh` 相当を移す。
  - `gsettings` が存在しない環境では分かりやすく失敗する。
  - 将来的に `dconf.settings` へ移行できる余地を残す。

- [x] `dotfiles configure doom install` を実装する。
  - 既存の `bin/doomemacs-init.sh` 相当を移す。
  - 既に使える `~/.config/emacs` checkout が存在する場合は再利用する。
  - 空の `~/.config/emacs` が存在する場合は clone 先として使う。
  - 壊れた `~/.config/emacs` が存在する場合は明示的に失敗する。
  - `~/.config/doom/init.el` と `packages.el` が存在する場合は `doom install` をスキップし、`doom sync` を実行する。
  - `doom install` 実行時は `config.el` symlink を一時的に外し、Doom が生成した `config.el` と `home/config/doom/config.el` の差分を確認してから symlink を戻す。
  - clone と install を分けるか検討する。

- [x] テンプレート操作を CLI 化する。
  - 例:

    ```sh
    dotfiles project init nix
    dotfiles project init docker
    ```

  - コピー先が既に存在する場合の挙動を明示する。

## Phase 4: Emacs/Doom の扱いを決める

- [x] Doom Emacs を Home Manager 管理へ移行する。
  - `programs.emacs.enable = true;` を使って Emacs 本体を管理する。
  - 必要な Emacs package、フォント、補助ツールがあれば `home.packages` に追加する。
  - `home/config/doom/config.el` を正式管理対象として扱い、`home.file.".config/doom/config.el"` で配置する。
  - `init.el` と `packages.el` は Doom の更新で変わりうるため Home Manager 管理に含めない。
  - 完了条件:
    - `~/.config/doom/config.el` が Home Manager 経由で管理される。
    - Doom Emacs が Home Manager 管理の Emacs で起動できる。
    - `doom doctor` が大きな問題なく通る。

- [x] Doom Emacs 本体の checkout を管理する。
  - 既存の `~/.config/emacs` を Doom Emacs の checkout 先として使う。
  - Home Manager で git clone を直接 activation に埋め込むか、`dotfiles configure doom install` に限定するかを決める。
  - 推奨:
    - 初回 clone は `dotfiles configure doom install` で明示実行する。
    - 設定ファイルは Home Manager で管理する。
    - activation では重いネットワーク処理を避ける。

- [x] `dotfiles configure doom sync` を実装する。
  - `~/.config/emacs/bin/doom sync` を実行する。
  - `~/.config/emacs` が存在しない場合は `dotfiles configure doom install` を促す。
  - 実行前に `~/.config/doom/config.el` と `home/config/doom/config.el` の差分を確認する。
  - 差分がある場合は unified diff を表示し、`dotfiles flake switch` を促して停止する。
  - Doom コマンドが失敗した場合は exit code をそのまま返す。

- [x] `dotfiles configure doom upgrade` を実装する。
  - `~/.config/emacs/bin/doom upgrade` を実行する。
  - `doom upgrade` 実行時は `config.el` symlink を一時的に外し、Doom が生成した `config.el` と `home/config/doom/config.el` の差分を確認してから symlink を戻す。
  - upgrade 後に `doom sync` を実行するか、明示的に案内するか決める。
  - 推奨は `dotfiles configure doom upgrade` 内で `doom upgrade` 後に `doom sync` を実行する。

- [x] Home Manager 更新後に Doom sync を実行する導線を作る。
  - `dotfiles flake switch` の中で `home-manager switch` 成功後に `dotfiles configure doom sync` 相当を呼ぶ。
  - または `--skip-doom-sync` のようなオプションを用意し、通常は sync する。
  - 完了条件:
    - Doom 設定変更後に `dotfiles flake switch` だけで `doom sync` まで完了する。
    - Doom 未インストール環境では分かりやすいメッセージで止まるか、skip できる。

- [x] `scrap/.emacs.d` の扱いを決める。
  - 旧 Emacs 設定としては廃止する。
  - 落書き用に残したい `emacs.el` だけ `notes/emacs/emacs.el` へ移す。
  - `notes/emacs` は Home Manager 管理対象ではなく、個人用メモ置き場として扱う。

## Phase 5: 旧構成の整理

- [x] `Makefile` を整理する。
  - `dotfiles` CLI の互換ラッパーではなく、repo 開発用の Nix build/check/dist 操作に限定する。
  - 例:

    ```make
    flake-check:
    	nix flake check

    home-build:
    	nix build .#homeConfigurations.nixos.activationPackage --no-link

    dist:
    	nix build .#dotfiles-dist --no-link
    ```

- [x] 旧スクリプトを統合する。
  - 対象:

    ```text
    bin/git-config-global.sh
    bin/gnome-settings.sh
    bin/doomemacs-init.sh
    ```

  - Home Manager または `dotfiles` CLI に移せたため削除する。
  - Doom 関連は `dotfiles configure doom install`, `dotfiles configure doom sync`, `dotfiles configure doom upgrade` に統合する。

- [x] README を更新する。
  - 新しいセットアップ手順を書く。
  - 例:

    ```sh
    home-manager switch --flake .#<profile>
    dotfiles doctor
    dotfiles flake doctor
    dotfiles configure gnome
    ```

  - 旧 `make init` ベースの説明は削除する。

## Phase 6: 検証

- [x] `nix flake check` を通す。
- [x] `nix build .#homeConfigurations.nixos.activationPackage --no-link` を通す。
- [x] `home-manager switch --flake .#<profile>` を実際に適用する。
- [x] `dotfiles doctor` を実行し、期待したチェック結果になることを確認する。
- [x] bash/zsh の起動確認をする。
- [x] tmux の keybind と status line を確認する。
- [x] GNOME 環境がある場合のみ `dotfiles configure gnome` を確認する。
  - この環境では GNOME/gsettings がないため、検証は skip 扱いにする。
- [x] `dotfiles configure doom install` を確認する。
- [x] `dotfiles configure doom sync` を確認する。
- [x] `dotfiles flake switch` 後に Doom sync が実行されることを確認する。

## Phase 7: 運用改善

- [x] `dotfiles doctor` を強化する。
  - Home Manager の profile/generation 状態を確認する。
  - `~/.config/doom/config.el` の symlink 状態と参照先を確認する。
  - Doom 側で管理する `~/.config/doom/init.el` と `~/.config/doom/packages.el` の有無を確認する。
  - Doom checkout `~/.config/emacs` と `doom` executable の状態を確認する。

- [x] flake 依存コマンドを `dotfiles flake` 配下へ移動する。
  - `dotfiles flake check`
  - `dotfiles flake update`
  - `dotfiles flake switch`
  - `dotfiles flake doctor`
  - `dotfiles doctor` は Nix/Home Manager 前提ではない汎用診断にする。
  - straight recipe repositories の存在、branch、remote、追跡状態を確認する。
  - system は stable、home は unstable という運用前提を確認しやすい表示にする。

- [x] `dotfiles configure doom install --check` を追加する。
  - 新規環境を想定して、一時ディレクトリへ `HOME` と `DOOM_HOME` を向けた検証を行う。
  - 実環境の `~/.config/emacs` と `~/.config/doom` は変更しない。
  - clone/install 判定、Doom 生成 `config.el` との差分確認、symlink 復元の流れを検証する。
  - 実際の clone/install は行わず、fake Doom checkout で安全に検証する。

- [x] `project-templates/docker` の内容とファイル名を整理する。
  - `Makefile` はプロジェクト本体の作業用 `Makefile` と衝突する可能性があるため、`docker.mk` に変更する。
  - `build/push/run/shell/cmd/local-run` の責務、変数名、AWS ECR 前提、tag 生成、TTY 判定を見直す。
  - `dotfiles project init docker` は `docker.mk` を配置する。

- [x] `project-templates/nix` の Nix ファイル名を整理する。
  - `dotfiles project init nix` は direnv から `use flake` で読める devShell template として扱う。
  - `flake.nix` を標準の入口にする。
  - legacy `nix-shell` 用 template が必要になったら、`nix-shell` のように別 template として追加する。

- [x] Nix build で生成した成果物を repo に commit する配布フローを設計する。
  - Nix なしの環境でも `dotfiles` CLI や project template を展開できるようにする。
  - 生成物は `dist/` に置く。
  - 生成物は原則手編集禁止にし、生成元と再生成コマンドを README に明記する。
  - `nix build` 後に生成物を同期するコマンドとして `make dist` を用意する。
  - commit 対象は `dotfiles-*` scripts と project templates にする。
  - Nix store 固有パスや runtime dependency が生成物へ混入しないことを検証する。

- [x] screen 設定を `tmux.nix` から分離する。
  - 現状は `home/tmux.nix` に `home.file.".screenrc"` も入っており、screen 設定の所在が分かりにくい。
  - `home/screen.nix` を作り、`home/config/screen/screenrc` の配置はそこへ移す。
  - `home/default.nix` の imports に `./screen.nix` を追加する。
  - `home/tmux.nix` は tmux の設定だけを扱う。

- [x] `dist/install.sh` に対応する uninstall を実装する。
  - `dist/install.sh` で配置した `$prefix` と `$DOTFILES_BIN_DIR/dotfiles*` symlink を削除できるようにする。
  - standalone script として `dist/uninstall.sh` にする。
  - 誤ってユーザーの手書きファイルを消さないよう、symlink 先や prefix を確認してから削除する。
  - `pkgs/dotfiles/dist.nix` と README にも反映する。

## 注意点

- ユーザーの未コミット変更を勝手に戻さない。
- `gsettings` や `doom install` のような副作用コマンドを Home Manager activation に入れない。
- `doom sync` は `dotfiles flake switch` から明示的に呼び出す。Home Manager module の評価や activation に重いネットワーク処理を混ぜない。
