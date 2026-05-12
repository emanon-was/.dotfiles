.PHONY: switch check update doctor configure-gnome configure-doom

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
