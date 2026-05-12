{ lib
, stdenv
, writeShellApplication
, bash
, coreutils
, diffutils
, git
, gnugrep
, gnused
, nix
, home-manager
}:

writeShellApplication {
  name = "dotfiles";

  runtimeInputs = [
    bash
    coreutils
    diffutils
    git
    gnugrep
    gnused
    nix
    home-manager.packages.${stdenv.hostPlatform.system}.home-manager
  ];

  text = ''
    set -u

    DOTFILES_HOME="''${DOTFILES_HOME:-$HOME/.dotfiles}"
    DOTFILES_PROFILE="''${DOTFILES_PROFILE:-nixos}"
    DOOM_HOME="''${DOOM_HOME:-$HOME/.config/emacs}"
    DOOM_BIN="$DOOM_HOME/bin/doom"

    usage() {
      cat <<'USAGE'
    Usage:
      dotfiles doctor
      dotfiles switch [--skip-doom-sync] [profile]
      dotfiles check
      dotfiles update
      dotfiles configure gnome
      dotfiles configure doom install
      dotfiles configure doom sync
      dotfiles configure doom upgrade
      dotfiles template copy <nix|docker> [destination]
    USAGE
    }

    have() {
      command -v "$1" >/dev/null 2>&1
    }

    status() {
      printf '%s\n' "$*"
    }

    fail() {
      printf 'error: %s\n' "$*" >&2
      exit 1
    }

    require_dotfiles_home() {
      [ -d "$DOTFILES_HOME" ] || fail "DOTFILES_HOME does not exist: $DOTFILES_HOME"
    }

    doom_installed() {
      [ -x "$DOOM_BIN" ]
    }

    directory_empty() {
      [ -d "$1" ] && [ -z "$(find "$1" -mindepth 1 -maxdepth 1 -print -quit)" ]
    }

    doom_checkout_ready() {
      [ -d "$DOOM_HOME/.git" ] && doom_installed
    }

    doom_config_ready() {
      [ -f "$HOME/.config/doom/init.el" ] && [ -f "$HOME/.config/doom/packages.el" ]
    }

    doom_check_config_current() {
      dotfiles_config="$DOTFILES_HOME/config/doom/config.el"
      active_config="$HOME/.config/doom/config.el"

      [ -f "$dotfiles_config" ] || fail "Doom config source does not exist: $dotfiles_config"

      if [ ! -e "$active_config" ]; then
        status "[doom] config.el is not installed yet: $active_config"
        fail "Run: dotfiles switch"
      fi

      if cmp -s "$dotfiles_config" "$active_config"; then
        if [ -L "$active_config" ]; then
          status "[doom] config.el is current: $active_config -> $(readlink "$active_config")"
        else
          status "[doom] config.el is current: $active_config"
        fi
        return 0
      fi

      status "[doom] config.el differs from dotfiles source"
      diff -u "$active_config" "$dotfiles_config" || true
      fail "Run: dotfiles switch"
    }

    doom_unlink_managed_config() {
      DOOM_CONFIG_WAS_LINK=0
      DOOM_CONFIG_LINK_TARGET=""
      active_config="$HOME/.config/doom/config.el"

      if [ -L "$active_config" ]; then
        DOOM_CONFIG_WAS_LINK=1
        DOOM_CONFIG_LINK_TARGET="$(readlink "$active_config")"
        status "[doom] temporarily removing managed config.el symlink"
        rm "$active_config"
      elif [ -e "$active_config" ]; then
        status "[doom] config.el is not a symlink; leaving it in place"
      else
        status "[doom] config.el is absent before Doom command"
      fi
    }

    doom_compare_generated_config_and_restore() {
      dotfiles_config="$DOTFILES_HOME/config/doom/config.el"
      active_config="$HOME/.config/doom/config.el"
      diff_status=0

      [ -f "$dotfiles_config" ] || fail "Doom config source does not exist: $dotfiles_config"

      if [ -f "$active_config" ] && [ ! -L "$active_config" ]; then
        if cmp -s "$active_config" "$dotfiles_config"; then
          status "[doom] generated config.el matches dotfiles source"
        else
          status "[doom] generated config.el differs from dotfiles source"
          diff -u "$active_config" "$dotfiles_config" || true
          diff_status=1
        fi
      else
        status "[doom] no generated config.el to compare"
      fi

      if [ "$DOOM_CONFIG_WAS_LINK" -eq 1 ]; then
        if [ -e "$active_config" ] || [ -L "$active_config" ]; then
          rm "$active_config"
        fi
        ln -s "$DOOM_CONFIG_LINK_TARGET" "$active_config"
        status "[doom] restored managed config.el symlink"
      fi

      if [ "$diff_status" -ne 0 ]; then
        fail "Review generated config.el diff before continuing"
      fi
    }

    doom_run_with_generated_config_check() {
      doom_unlink_managed_config
      set +e
      "$@"
      command_status="$?"
      set -e
      doom_compare_generated_config_and_restore
      return "$command_status"
    }

    doom_refresh_recipe_repositories() {
      recipes_dir="$DOOM_HOME/.local/straight/repos"
      [ -d "$recipes_dir" ] || return 0

      status "[doom] refreshing straight recipe repositories"
      for repo in org-elpa melpa nongnu-elpa gnu-elpa-mirror el-get emacsmirror-mirror; do
        repo_path="$recipes_dir/$repo"
        if [ -d "$repo_path/.git" ]; then
          status "[doom] updating recipe repository: $repo"
          branch="$(git -C "$repo_path" branch --show-current)"
          if [ -z "$branch" ]; then
            status "[doom] recipe repository is detached, skipping: $repo"
          else
            git -C "$repo_path" fetch origin "$branch"
            git -C "$repo_path" merge --ff-only "origin/$branch"
          fi
        else
          status "[doom] recipe repository not present: $repo"
        fi
      done
    }

    doom_clone() {
      if [ ! -e "$DOOM_HOME" ]; then
        status "[doom] cloning Doom Emacs into $DOOM_HOME"
        git clone --depth 1 https://github.com/doomemacs/doomemacs "$DOOM_HOME"
      elif directory_empty "$DOOM_HOME"; then
        status "[doom] cloning Doom Emacs into empty directory $DOOM_HOME"
        git clone --depth 1 https://github.com/doomemacs/doomemacs "$DOOM_HOME"
      elif doom_checkout_ready; then
        status "[doom] checkout already exists: $DOOM_HOME"
      else
        fail "$DOOM_HOME exists but is not a usable Doom Emacs checkout"
      fi
    }

    doom_sync() {
      if ! doom_installed; then
        fail "Doom Emacs is not installed at $DOOM_HOME. Run: dotfiles configure doom install"
      fi
      doom_check_config_current
      status "[doom] syncing Doom profile"
      "$DOOM_BIN" sync
    }

    gnome_configure() {
      have gsettings || fail "gsettings is not available"
      gsettings set org.gnome.desktop.interface gtk-key-theme "Emacs"
      gsettings set org.gnome.desktop.interface document-font-name "Sans 11"
      gsettings set org.gnome.desktop.interface font-name "Sans-serif 10"
      gsettings set org.gnome.desktop.interface monospace-font-name "Monospace 11"
    }

    cmd_doctor() {
      failed=0

      for cmd in nix home-manager git direnv; do
        if have "$cmd"; then
          status "[ok] $cmd: $(command -v "$cmd")"
        else
          status "[missing] $cmd"
          failed=1
        fi
      done

      if have gsettings; then
        status "[ok] gsettings: $(command -v gsettings)"
      else
        status "[skip] gsettings: not available"
      fi

      if [ -d "$DOTFILES_HOME" ]; then
        status "[ok] DOTFILES_HOME: $DOTFILES_HOME"
      else
        status "[missing] DOTFILES_HOME: $DOTFILES_HOME"
        failed=1
      fi

      if doom_installed; then
        status "[ok] Doom Emacs: $DOOM_BIN"
      else
        status "[missing] Doom Emacs: $DOOM_BIN"
        failed=1
      fi

      return "$failed"
    }

    cmd_switch() {
      require_dotfiles_home

      skip_doom_sync=0
      profile="$DOTFILES_PROFILE"

      while [ "$#" -gt 0 ]; do
        case "$1" in
          --skip-doom-sync)
            skip_doom_sync=1
            ;;
          -*)
            fail "unknown option for switch: $1"
            ;;
          *)
            profile="$1"
            ;;
        esac
        shift
      done

      home-manager -b hm-backup --flake "$DOTFILES_HOME#$profile" switch

      if [ "$skip_doom_sync" -eq 0 ]; then
        doom_sync
      else
        status "[skip] doom sync"
      fi
    }

    cmd_check() {
      require_dotfiles_home
      nix flake check "$DOTFILES_HOME"
    }

    cmd_update() {
      require_dotfiles_home
      nix flake update --flake "$DOTFILES_HOME"
      cmd_check
    }

    cmd_configure() {
      case "''${1:-}" in
        gnome)
          shift
          if [ "$#" -gt 0 ]; then
            usage
            exit 2
          fi
          gnome_configure
          ;;
        doom)
          shift
          cmd_doom "$@"
          ;;
        *)
          usage
          exit 2
          ;;
      esac
    }

    cmd_doom() {
      case "''${1:-}" in
        install)
          status "[doom] ensuring Doom Emacs checkout"
          doom_clone
          if doom_config_ready; then
            status "[doom] config bootstrap files already exist"
          else
            status "[doom] running Doom install"
            doom_run_with_generated_config_check "$DOOM_BIN" install
          fi
          doom_sync
          ;;
        sync)
          doom_sync
          ;;
        upgrade)
          if ! doom_installed; then
            fail "Doom Emacs is not installed at $DOOM_HOME. Run: dotfiles configure doom install"
          fi
          doom_refresh_recipe_repositories
          status "[doom] upgrading Doom Emacs"
          doom_run_with_generated_config_check "$DOOM_BIN" upgrade
          doom_sync
          ;;
        *)
          usage
          exit 2
          ;;
      esac
    }

    cmd_template() {
      case "''${1:-}" in
        copy)
          template="''${2:-}"
          destination="''${3:-.}"
          [ -n "$template" ] || fail "template name is required"
          source="$DOTFILES_HOME/template/$template"
          [ -d "$source" ] || fail "unknown template: $template"
          mkdir -p "$destination"
          cp -R "$source"/. "$destination"/
          ;;
        *)
          usage
          exit 2
          ;;
      esac
    }

    case "''${1:-}" in
      doctor)
        shift
        cmd_doctor "$@"
        ;;
      switch)
        shift
        cmd_switch "$@"
        ;;
      check)
        shift
        cmd_check "$@"
        ;;
      update)
        shift
        cmd_update "$@"
        ;;
      configure)
        shift
        cmd_configure "$@"
        ;;
      template)
        shift
        cmd_template "$@"
        ;;
      -h|--help|help|"")
        usage
        ;;
      *)
        usage
        exit 2
        ;;
    esac
  '';

  meta = {
    description = "Dotfiles management helper";
    license = lib.licenses.mit;
  };
}
