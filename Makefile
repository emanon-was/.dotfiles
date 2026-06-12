.PHONY: init clean build check

# profile を $HOME へ展開する。
init:
	./profile/.local/bin/symsync apply --src profile --dest "$(HOME)"

# profile で展開した symlink を外す。
clean:
	./profile/.local/bin/symsync unapply --src profile --dest "$(HOME)"

# 主要な非破壊チェックをまとめて実行する。
check:
	nix flake check

# profile/ を Nix build の成果物で再生成する。
build:
	@chmod -R u+w profile 2>/dev/null || true
	@rm -rf profile
	@set -e; \
	out="$$(nix build .#dotfiles-profile --no-link --print-out-paths)"; \
	cp -R "$$out" profile
