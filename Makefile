.PHONY: init init.flake init.dist init.doom clean clean.flake clean.dist restore.flake flake-check dotfiles-build dist-build home-build switch-check command-check dist-install-check check dist

PROFILE ?= current
DOTFILES_USERNAME ?= $(shell id -un)
DOTFILES_HOME_DIRECTORY ?= $(HOME)
DOTFILES_STATE_DIR ?= $(HOME)/.local/state/dotfiles
DOTFILES_INIT_MODE_FILE ?= $(DOTFILES_STATE_DIR)/init-mode
DOTFILES_HM_BACKUPS_FILE ?= $(DOTFILES_STATE_DIR)/hm-backups.tsv

# flake が使える環境では init.flake、使えない環境では init.dist を実行する。
init:
	@if command -v nix >/dev/null 2>&1 && nix flake metadata . >/dev/null 2>&1; then \
		$(MAKE) init.flake; \
	else \
		$(MAKE) init.dist; \
	fi

# Home Manager / flake 環境の初期化を実行する。
init.flake:
	nix run .#dotfiles -- flake doctor
	@set -e; \
	mkdir -p "$(DOTFILES_STATE_DIR)"; \
	before="$(DOTFILES_HM_BACKUPS_FILE).before"; \
	after="$(DOTFILES_HM_BACKUPS_FILE).after"; \
	cleanup() { rm -f "$$before" "$$after"; }; \
	trap cleanup EXIT; \
	find "$(HOME)" -xdev -name '*.hm-backup' -print | sort > "$$before"; \
	switch_status=0; \
	nix run .#dotfiles -- flake switch || switch_status="$$?"; \
	find "$(HOME)" -xdev -name '*.hm-backup' -print | sort > "$$after"; \
	comm -13 "$$before" "$$after" > "$(DOTFILES_HM_BACKUPS_FILE)"; \
	if [ "$$switch_status" -ne 0 ]; then \
		exit "$$switch_status"; \
	fi
	@mkdir -p "$(DOTFILES_STATE_DIR)"
	@printf '%s\n' flake > "$(DOTFILES_INIT_MODE_FILE)"

# dist を使う非 Nix 環境向けの初期化を実行する。
init.dist:
	./dist/install.sh
	@mkdir -p "$(DOTFILES_STATE_DIR)"
	@printf '%s\n' dist > "$(DOTFILES_INIT_MODE_FILE)"

# Doom Emacs の初回セットアップを実行する。
init.doom:
	nix run .#dotfiles -- configure doom install

# Home Manager の管理をやめる。
# home-manager uninstall が失敗した場合は restore.flake へ進まない。
clean.flake:
	home-manager uninstall
	$(MAKE) restore.flake
	@rm -f "$(DOTFILES_INIT_MODE_FILE)"

# init.flake の switch で新規作成された *.hm-backup だけを上書きなしで戻す。
restore.flake:
	@if [ ! -f "$(DOTFILES_HM_BACKUPS_FILE)" ]; then \
		printf 'hm-backup manifest not found: %s\n' "$(DOTFILES_HM_BACKUPS_FILE)"; \
		exit 0; \
	fi; \
	while IFS= read -r backup_path; do \
		[ -n "$$backup_path" ] || continue; \
		target_path="$${backup_path%.hm-backup}"; \
		if [ ! -e "$$backup_path" ] && [ ! -L "$$backup_path" ]; then \
			printf 'skipped hm-backup restore, backup missing: %s\n' "$$backup_path"; \
			continue; \
		fi; \
		if [ -e "$$target_path" ] || [ -L "$$target_path" ]; then \
			printf 'skipped hm-backup restore, path exists: %s\n' "$$target_path"; \
		else \
			mv "$$backup_path" "$$target_path"; \
			printf 'restored hm-backup: %s -> %s\n' "$$backup_path" "$$target_path"; \
		fi; \
	done < "$(DOTFILES_HM_BACKUPS_FILE)"; \
	rm -f "$(DOTFILES_HM_BACKUPS_FILE)"

# dist/install.sh で展開した symlink と backup を戻す。
clean.dist:
	./dist/uninstall.sh
	@rm -f "$(DOTFILES_INIT_MODE_FILE)"

# init 時に記録した方式に合わせて clean.flake / clean.dist を実行する。
clean:
	@if [ ! -f "$(DOTFILES_INIT_MODE_FILE)" ]; then \
		printf 'error: init mode is not recorded: %s\n' "$(DOTFILES_INIT_MODE_FILE)" >&2; \
		printf 'run make clean.flake or make clean.dist explicitly\n' >&2; \
		exit 1; \
	fi; \
	mode="$$(sed -n '1p' "$(DOTFILES_INIT_MODE_FILE)")"; \
	case "$$mode" in \
		flake) $(MAKE) clean.flake ;; \
		dist) $(MAKE) clean.dist ;; \
		*) \
			printf 'error: unknown init mode: %s\n' "$$mode" >&2; \
			printf 'run make clean.flake or make clean.dist explicitly\n' >&2; \
			exit 1; \
			;; \
	esac

# flake 全体の評価と checks を確認する。
flake-check:
	nix flake check

# dotfiles CLI package を build する。
dotfiles-build:
	nix build .#dotfiles --no-link

# commit 用の dist 生成 package を build する。
dist-build:
	nix build .#dotfiles-dist --no-link

# dotfiles flake switch の内部ロジックを非破壊で検査する。
switch-check:
	nix flake check

# dotfiles CLI の主要 subcommand を非破壊で検査する。
command-check:
	nix flake check

# dist install/uninstall の manifest と復元処理を検査する。
dist-install-check:
	nix flake check

# 主要な非破壊チェックをまとめて実行する。
check: flake-check

# Home Manager activation package を build する。
# PROFILE に current/dist 以外を指定した場合は任意ユーザー名として扱い、
# flake profile は current のまま DOTFILES_USERNAME に渡す。
home-build:
	@set -e; \
	profile="$(PROFILE)"; \
	username="$(DOTFILES_USERNAME)"; \
	home_directory="$(DOTFILES_HOME_DIRECTORY)"; \
	case "$$profile" in \
		current|dist) ;; \
		root) profile="current"; username="root"; home_directory="/root" ;; \
		*) username="$$profile"; profile="current"; home_directory="/home/$$username" ;; \
	esac; \
	DOTFILES_USERNAME="$$username" DOTFILES_HOME_DIRECTORY="$$home_directory" \
		nix build ".#homeConfigurations.$$profile.activationPackage" --impure --no-link

# dist/ を Nix build の成果物で再生成する。
dist:
	@chmod -R u+w dist 2>/dev/null || true
	@rm -rf dist
	@set -e; \
	out="$$(nix build .#dotfiles-dist --no-link --print-out-paths)"; \
	cp -R "$$out" dist
