.PHONY: flake-check dotfiles-build dist-build home-build switch-check check dist

PROFILE ?= current
DOTFILES_USERNAME ?= $(shell id -un)
DOTFILES_HOME_DIRECTORY ?= $(HOME)

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
	tests/dotfiles-flake-switch.sh

# 主要な非破壊チェックをまとめて実行する。
check: flake-check switch-check

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
