.PHONY: switch check update doctor configure-gnome configure-doom dist

DOTFILES := nix run .#dotfiles --

switch:
	@$(DOTFILES) switch

check:
	@$(DOTFILES) check

update:
	@$(DOTFILES) update

doctor:
	@$(DOTFILES) doctor

configure-gnome:
	@$(DOTFILES) configure gnome

configure-doom:
	@$(DOTFILES) configure doom sync

dist:
	@chmod -R u+w dist 2>/dev/null || true
	@rm -rf dist
	@set -e; \
	out="$$(nix build .#dotfiles-dist --no-link --print-out-paths)"; \
	cp -R "$$out" dist
