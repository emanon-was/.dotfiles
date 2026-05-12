.PHONY: flake-check dotfiles-build dist-build home-build dist

PROFILE ?= $(shell id -un)

# flake 全体の評価と checks を確認する。
flake-check:
	nix flake check

# dotfiles CLI package を build する。
dotfiles-build:
	nix build .#dotfiles --no-link

# commit 用の dist 生成 package を build する。
dist-build:
	nix build .#dotfiles-dist --no-link

# Home Manager activation package を build する。
home-build:
	nix build .#homeConfigurations.$(PROFILE).activationPackage --no-link

# dist/ を Nix build の成果物で再生成する。
dist:
	@chmod -R u+w dist 2>/dev/null || true
	@rm -rf dist
	@set -e; \
	out="$$(nix build .#dotfiles-dist --no-link --print-out-paths)"; \
	cp -R "$$out" dist
