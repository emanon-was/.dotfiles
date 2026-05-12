{ lib
, stdenv
, writeShellApplication
, bash
, coreutils
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

    backup_legacy_link() {
      relative_path="$1"
      target_path="$HOME/$relative_path"
      legacy_path="$DOTFILES_HOME/store/$relative_path"
      backup_path="$target_path.hm-backup"

      if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$legacy_path" ]; then
        if [ -e "$backup_path" ] || [ -L "$backup_path" ]; then
          fail "backup already exists: $backup_path"
        fi
        mv "$target_path" "$backup_path"
        status "[backup] $target_path -> $backup_path"
      fi
    }

    backup_legacy_links() {
      backup_legacy_link ".bashrc"
      backup_legacy_link ".profile"
      backup_legacy_link ".zshrc"
      backup_legacy_link ".screenrc"
      backup_legacy_link ".tmux.conf"
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

      backup_legacy_links
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
            "$DOOM_BIN" install
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
          status "[doom] upgrading Doom Emacs"
          "$DOOM_BIN" upgrade
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
