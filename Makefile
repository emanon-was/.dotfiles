.PHONY: init clean build check

NIX_CACHE_HOME ?= $(CURDIR)/.cache

# static/ln と generated/ を symlink、static/cp を copy で $HOME へ展開する。
init:
	./generated/.local/bin/dotfiles-ln apply --src static/ln --dest "$(HOME)"
	./generated/.local/bin/dotfiles-cp apply --src static/cp --dest "$(HOME)"
	./generated/.local/bin/dotfiles-ln apply --src generated --dest "$(HOME)"

# static/ と generated/ で展開した file と symlink を外す。
clean:
	./generated/.local/bin/dotfiles-ln unapply --src generated --dest "$(HOME)"
	./generated/.local/bin/dotfiles-cp unapply --src static/cp --dest "$(HOME)"
	./generated/.local/bin/dotfiles-ln unapply --src static/ln --dest "$(HOME)"

# 主要な非破壊チェックをまとめて実行する。
check:
	mkdir -p "$(NIX_CACHE_HOME)/nix"
	XDG_CACHE_HOME="$(NIX_CACHE_HOME)" nix flake check --impure

# generated/ を Nix build の成果物で再生成する。
build:
	@set -e; \
	mkdir -p "$(NIX_CACHE_HOME)/nix"; \
	out="$$(XDG_CACHE_HOME="$(NIX_CACHE_HOME)" nix build --impure .#dotfiles-generated --no-link --print-out-paths)"; \
	tmp_generated=".generated.tmp.$$$$"; \
	old_generated=".generated.old.$$$$"; \
	rm -rf "$$tmp_generated" "$$old_generated"; \
	trap 'rm -rf "$$tmp_generated"; if [ -e "$$old_generated" ] && [ ! -e generated ]; then mv "$$old_generated" generated; fi' EXIT; \
	cp -R "$$out" "$$tmp_generated"; \
	chmod -R u+w "$$tmp_generated"; \
	if [ -e generated ]; then mv generated "$$old_generated"; fi; \
	mv "$$tmp_generated" generated; \
	if [ -e "$$old_generated" ]; then chmod -R u+w "$$old_generated"; rm -rf "$$old_generated"; fi; \
	trap - EXIT
