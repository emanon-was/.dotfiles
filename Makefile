.PHONY: init clean build check

# static/ と generated/ を $HOME へ展開する。
init:
	./generated/.local/bin/symsync apply --src static --dest "$(HOME)"
	./generated/.local/bin/symsync apply --src generated --dest "$(HOME)"

# static/ と generated/ で展開した symlink を外す。
clean:
	./generated/.local/bin/symsync unapply --src generated --dest "$(HOME)"
	./generated/.local/bin/symsync unapply --src static --dest "$(HOME)"

# 主要な非破壊チェックをまとめて実行する。
check:
	mkdir -p .cache/nix
	XDG_CACHE_HOME="$(CURDIR)/.cache" nix flake check --impure

# generated/ を Nix build の成果物で再生成する。
build:
	@set -e; \
	out="$$(nix build .#dotfiles-generated --no-link --print-out-paths)"; \
	tmp_generated=".generated.tmp.$$$$"; \
	old_generated=".generated.old.$$$$"; \
	rm -rf "$$tmp_generated" "$$old_generated"; \
	trap 'rm -rf "$$tmp_generated"; if [ -e "$$old_generated" ] && [ ! -e generated ]; then mv "$$old_generated" generated; fi' EXIT; \
	cp -R "$$out" "$$tmp_generated"; \
	if [ -e generated ]; then mv generated "$$old_generated"; fi; \
	mv "$$tmp_generated" generated; \
	if [ -e "$$old_generated" ]; then chmod -R u+w "$$old_generated"; rm -rf "$$old_generated"; fi; \
	trap - EXIT
