.PHONY: flake-check dotfiles-build dist-build home-build dist

flake-check:
	nix flake check

dotfiles-build:
	nix build .#dotfiles --no-link

dist-build:
	nix build .#dotfiles-dist --no-link

home-build:
	nix build .#homeConfigurations.nixos.activationPackage --no-link

dist:
	@chmod -R u+w dist 2>/dev/null || true
	@rm -rf dist
	@set -e; \
	out="$$(nix build .#dotfiles-dist --no-link --print-out-paths)"; \
	cp -R "$$out" dist
