.PHONY: init clean build check

# profile を $HOME へ展開する。
init:
	./profile/.local/bin/symsync apply --src profile --dest "$(HOME)"

# profile で展開した symlink を外す。
clean:
	./profile/.local/bin/symsync unapply --src profile --dest "$(HOME)"

# 主要な非破壊チェックをまとめて実行する。
check:
	nix flake check --impure

# profile/ を Nix build の成果物で再生成する。
build:
	@set -e; \
	out="$$(nix build .#dotfiles-profile --no-link --print-out-paths)"; \
	tmp_profile=".profile.tmp.$$$$"; \
	rm -rf "$$tmp_profile"; \
	trap 'rm -rf "$$tmp_profile"' EXIT; \
	cp -R "$$out" "$$tmp_profile"; \
	chmod -R u+w profile 2>/dev/null || true; \
	rm -rf profile; \
	mv "$$tmp_profile" profile; \
	trap - EXIT
