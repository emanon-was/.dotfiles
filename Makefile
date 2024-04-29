.PHONY: plan init clean backup restore git.config.global gnome.init doomemacs.init

PWD := $(shell pwd)
STORE := $(PWD)/store
STORE_LIST := $(PWD)/store.list
BACKUP := $(PWD)/backup

plan:
	@bin/plan.sh $(STORE) $(STORE_LIST)

init:
	@bin/init.sh $(STORE) $(STORE_LIST)

clean:
	@bin/clean.sh $(STORE) $(STORE_LIST)

backup:
	@bin/backup.sh $(BACKUP) $(STORE_LIST)

restore:
	@bin/restore.sh $(BACKUP) $(STORE_LIST)

git.config.global:
	@bin/git-config-global.sh

gnome.init:
	@bin/gnome-init.sh

doomemacs.init:
	@bin/doomemacs-init.sh
