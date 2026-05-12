.PHONY: switch check update doctor gnome-configure gnome-apply doom-install doom-sync doom-upgrade plan init clean backup restore

PWD := $(shell pwd)
STORE := $(PWD)/store
STORE_LIST := $(PWD)/store.list
BACKUP := $(PWD)/backup
DOTFILES := nix run .#dotfiles --

switch:
	@$(DOTFILES) switch

check:
	@$(DOTFILES) check

update:
	@$(DOTFILES) update

doctor:
	@$(DOTFILES) doctor

gnome-configure:
	@$(DOTFILES) gnome configure

gnome-apply:
	@$(DOTFILES) gnome configure

doom-install:
	@$(DOTFILES) doom install

doom-sync:
	@$(DOTFILES) doom sync

doom-upgrade:
	@$(DOTFILES) doom upgrade

plan:
	@bin/.dotfiles-plan.sh $(STORE) $(STORE_LIST)

init:
	@bin/.dotfiles-init.sh $(STORE) $(STORE_LIST)

clean:
	@bin/.dotfiles-clean.sh $(STORE) $(STORE_LIST)

backup:
	@bin/.dotfiles-backup.sh $(BACKUP) $(STORE_LIST)

restore:
	@bin/.dotfiles-restore.sh $(BACKUP) $(STORE_LIST)
