.PHONY: plan init clean backup restore

PWD := $(shell pwd)
STORE := $(PWD)/store
STORE_LIST := $(PWD)/store.list
BACKUP := $(PWD)/backup

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
