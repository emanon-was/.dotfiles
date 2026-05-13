.PHONY: init init.flake init.dist init.doom clean.flake clean.dist flake-check dotfiles-build dist-build home-build switch-check command-check dist-install-check check dist

PROFILE ?= current
DOTFILES_USERNAME ?= $(shell id -un)
DOTFILES_HOME_DIRECTORY ?= $(HOME)

# flake が使える環境では init.flake、使えない環境では init.dist を実行する。
init:
	@if command -v nix >/dev/null 2>&1 && nix flake metadata . >/dev/null 2>&1; then \
		$(MAKE) init.flake; \
	else \
		$(MAKE) init.dist; \
	fi

# Home Manager / flake 環境の初期化を実行する。
init.flake:
	nix run .#dotfiles -- flake doctor
	nix run .#dotfiles -- configure doctor
	nix run .#dotfiles -- flake switch

# dist を使う非 Nix 環境向けの初期化を実行する。
init.dist:
	./dist/install.sh

# Doom Emacs の初回セットアップを実行する。
init.doom:
	nix run .#dotfiles -- configure doom install

# Home Manager の管理をやめる。
# 退避された *.hm-backup の復元が必要な場合は内容を確認して手で戻す。
clean.flake:
	home-manager uninstall

# dist/install.sh で展開した symlink と backup を戻す。
clean.dist:
	./dist/uninstall.sh

# flake 全体の評価と checks を確認する。
flake-check:
	nix flake check

# dotfiles CLI package を build する。
dotfiles-build:
	nix build .#dotfiles --no-link

# commit 用の dist 生成 package を build する。
dist-build:
	nix build .#dotfiles-dist --no-link

# dotfiles flake switch の内部ロジックを非破壊で検査する。
switch-check:
	nix flake check

# dotfiles CLI の主要 subcommand を非破壊で検査する。
command-check:
	nix flake check

# dist install/uninstall の manifest と復元処理を検査する。
dist-install-check:
	nix flake check

# 主要な非破壊チェックをまとめて実行する。
check: flake-check

# Home Manager activation package を build する。
# PROFILE に current/dist 以外を指定した場合は任意ユーザー名として扱い、
# flake profile は current のまま DOTFILES_USERNAME に渡す。
home-build:
	@set -e; \
	profile="$(PROFILE)"; \
	username="$(DOTFILES_USERNAME)"; \
	home_directory="$(DOTFILES_HOME_DIRECTORY)"; \
	case "$$profile" in \
		current|dist) ;; \
		root) profile="current"; username="root"; home_directory="/root" ;; \
		*) username="$$profile"; profile="current"; home_directory="/home/$$username" ;; \
	esac; \
	DOTFILES_USERNAME="$$username" DOTFILES_HOME_DIRECTORY="$$home_directory" \
		nix build ".#homeConfigurations.$$profile.activationPackage" --impure --no-link

# dist/ を Nix build の成果物で再生成する。
dist:
	@chmod -R u+w dist 2>/dev/null || true
	@rm -rf dist
	@set -e; \
	out="$$(nix build .#dotfiles-dist --no-link --print-out-paths)"; \
	cp -R "$$out" dist
