usage_configure() {
  cat <<'USAGE'
Usage:
  dotfiles configure gnome
  dotfiles configure doom install [--check]
  dotfiles configure doom sync
  dotfiles configure doom upgrade
  dotfiles configure doom restore-defaults
USAGE
}

directory_empty() {
  [ -d "$1" ] && [ -z "$(find "$1" -mindepth 1 -maxdepth 1 -print -quit)" ]
}

timestamp() {
  date '+%Y%m%d-%H%M%S'
}

dotfiles_state_dir() {
  printf '%s\n' "${DOTFILES_STATE_DIR:-$HOME/.local/state/dotfiles}"
}

doom_checkout_ready() {
  [ -d "$DOOM_HOME/.git" ] && doom_installed
}

doom_config_ready() {
  [ -f "$HOME/.config/doom/init.el" ] && [ -f "$HOME/.config/doom/packages.el" ]
}

doom_config_file_source() {
  config_file="$1"
  dotfiles_home_file_source ".config/doom/$config_file"
}

doom_backup_path() {
  original_path="$1"
  backup_dir="$(dotfiles_state_dir)/doom-link-backups/$(timestamp)"
  backup_path="$backup_dir/$(basename "$original_path")"
  index=1

  while [ -e "$backup_path" ] || [ -L "$backup_path" ]; do
    backup_path="$backup_dir/$(basename "$original_path").$index"
    index=$((index + 1))
  done

  mkdir -p "$backup_dir"
  printf '%s\n' "$backup_path"
}

doom_link_dotfiles_config() {
  require_dotfiles_home

  for config_file in config.el init.el packages.el; do
    source_path="$(doom_config_file_source "$config_file" 2>/dev/null || true)"
    [ -n "$source_path" ] || continue

    target_path="$HOME/.config/doom/$config_file"
    mkdir -p "$(dirname "$target_path")"

    if [ "$source_path" = "$target_path" ]; then
      status "[doom] dotfiles config already deployed: $target_path"
      continue
    fi

    if [ -L "$target_path" ]; then
      current_target="$(readlink "$target_path")"
      if [ "$current_target" = "$source_path" ]; then
        status "[doom] dotfiles link already exists: $target_path -> $source_path"
      elif [ -f "$target_path" ] && cmp -s "$target_path" "$source_path"; then
        status "[doom] existing symlink content matches dotfiles source: $target_path -> $current_target"
      else
        warn "[doom] existing symlink differs; leaving it in place: $target_path -> $current_target"
      fi
      continue
    fi

    if [ -e "$target_path" ]; then
      if cmp -s "$target_path" "$source_path"; then
        rm "$target_path"
      else
        backup_path="$(doom_backup_path "$target_path")"
        mv "$target_path" "$backup_path"
        status "[doom] moved existing config aside: $target_path -> $backup_path"
      fi
    fi

    ln -s "$source_path" "$target_path"
    status "[doom] linked dotfiles config: $target_path -> $source_path"
  done
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
  doom_sync_raw
}

doom_sync_raw() {
  status "[doom] syncing Doom profile"
  "$DOOM_BIN" sync
}

doom_save_default_config() {
  require_dotfiles_home

  if ! doom_installed; then
    fail "Doom Emacs is not installed at $DOOM_HOME. Run: dotfiles configure doom install"
  fi

  defaults_dir="$(dotfiles_state_dir)/doom-defaults"
  check_root="$(mktemp -d)"

  (
    set -e

    real_doomdir="$HOME/.config/doom"
    temp_backup="$check_root/backup"
    temp_doomlocaldir="$check_root/doom-local"

    cleanup_default_capture() {
      for config_file in config.el init.el packages.el; do
        config_path="$real_doomdir/$config_file"
        if [ -e "$temp_backup/$config_file" ] || [ -L "$temp_backup/$config_file" ]; then
          rm -f "$config_path"
          mv "$temp_backup/$config_file" "$config_path"
        fi
      done
      rm -rf "$check_root"
    }
    trap cleanup_default_capture EXIT

    mkdir -p "$temp_backup" "$temp_doomlocaldir" "$real_doomdir"

    for config_file in config.el init.el packages.el; do
      config_path="$real_doomdir/$config_file"
      if [ -e "$config_path" ] || [ -L "$config_path" ]; then
        mv "$config_path" "$temp_backup/$config_file"
        status "[doom] temporarily moved existing config: $config_path"
      fi
    done

    status "[doom] generating Doom default config in isolated local state"
    HOME="$HOME" DOOMLOCALDIR="$temp_doomlocaldir" "$DOOM_BIN" --doomdir "$real_doomdir" install --force --no-env --no-install --no-hooks

    rm -rf "$defaults_dir.tmp"
    mkdir -p "$defaults_dir.tmp"
    for config_file in config.el init.el packages.el; do
      generated_path="$real_doomdir/$config_file"
      [ -f "$generated_path" ] || fail "Doom install did not generate $config_file: $generated_path"
      cp "$generated_path" "$defaults_dir.tmp/$config_file"
      rm -f "$generated_path"
      if [ -e "$temp_backup/$config_file" ] || [ -L "$temp_backup/$config_file" ]; then
        mv "$temp_backup/$config_file" "$generated_path"
        status "[doom] restored existing config: $generated_path"
      fi
    done

    rm -rf "$defaults_dir"
    mv "$defaults_dir.tmp" "$defaults_dir"
    status "[doom] saved Doom default config: $defaults_dir"
  )
}

doom_restore_defaults() {
  defaults_dir="$(dotfiles_state_dir)/doom-defaults"
  [ -d "$defaults_dir" ] || fail "Doom defaults are not saved yet: $defaults_dir"

  mkdir -p "$HOME/.config/doom"

  for config_file in config.el init.el packages.el; do
    source_path="$defaults_dir/$config_file"
    target_path="$HOME/.config/doom/$config_file"

    [ -f "$source_path" ] || fail "Doom default file does not exist: $source_path"

    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
      backup_path="$(doom_backup_path "$target_path")"
      mv "$target_path" "$backup_path"
      status "[doom] moved existing config aside: $target_path -> $backup_path"
    fi

    cp "$source_path" "$target_path"
    status "[doom] restored Doom default config: $target_path"
  done
}

doom_install_check() {
  require_dotfiles_home

  original_home="$HOME"
  original_doom_home="$DOOM_HOME"
  original_doom_bin="$DOOM_BIN"
  check_root="$(mktemp -d)"

  # shellcheck disable=SC2329
  cleanup_doom_install_check() {
    HOME="$original_home"
    DOOM_HOME="$original_doom_home"
    DOOM_BIN="$original_doom_bin"
    rm -rf "$check_root"
  }
  trap cleanup_doom_install_check RETURN

  HOME="$check_root/home"
  DOOM_HOME="$HOME/.config/emacs"
  DOOM_BIN="$DOOM_HOME/bin/doom"
  DOTFILES_DOOM_CONFIG_SOURCE="$(doom_config_source)"
  export DOTFILES_HOME
  export DOTFILES_DOOM_CONFIG_SOURCE

  status "[doom-check] using temporary HOME: $HOME"
  mkdir -p "$DOOM_HOME/.git" "$DOOM_HOME/bin" "$HOME/.config/doom"

  cat > "$DOOM_BIN" <<'FAKE_DOOM'
#!/usr/bin/env bash
set -euo pipefail

doomdir="${DOOMDIR:-$HOME/.config/doom}"
command=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --doomdir)
      doomdir="$2"
      shift 2
      ;;
    --emacsdir)
      shift 2
      ;;
    --*)
      shift
      ;;
    *)
      command="$1"
      shift
      break
      ;;
  esac
done

case "$command" in
  install)
    mkdir -p "$doomdir"
    if [ ! -e "$doomdir/config.el" ]; then
      cp "$DOTFILES_DOOM_CONFIG_SOURCE" "$doomdir/config.el"
    fi
    touch "$doomdir/init.el" "$doomdir/packages.el"
    ;;
  sync)
    ;;
  upgrade)
    ;;
  *)
    printf 'unexpected fake doom command: %s\n' "$command" >&2
    exit 2
    ;;
esac
FAKE_DOOM
  chmod +x "$DOOM_BIN"

  status "[doom-check] verifying isolated Doom checkout detection"
  doom_checkout_ready || fail "temporary Doom checkout was not detected as ready"

  status "[doom-check] verifying default config capture"
  doom_save_default_config
  [ -f "$HOME/.local/state/dotfiles/doom-defaults/config.el" ] || fail "Doom default config was not saved"

  status "[doom-check] verifying dotfiles config link"
  doom_link_dotfiles_config
  [ -L "$HOME/.config/doom/config.el" ] || fail "Doom config.el was not linked"

  status "[doom-check] verifying install flow"
  "$DOOM_BIN" install
  doom_sync_raw

  status "[doom-check] verifying bootstrap config detection"
  doom_config_ready || fail "temporary Doom bootstrap files were not created"

  status "[doom-check] verifying sync preflight check"
  doom_sync

  status "[doom-check] verifying default config restore"
  doom_restore_defaults
  [ ! -L "$HOME/.config/doom/config.el" ] || fail "Doom default restore should replace config link with a file"

  status "[doom-check] install check passed"
}

gnome_configure() {
  have gsettings || fail "gsettings is not available"
  gsettings set org.gnome.desktop.interface gtk-key-theme "Emacs"
  gsettings set org.gnome.desktop.interface document-font-name "Sans 11"
  gsettings set org.gnome.desktop.interface font-name "Sans-serif 10"
  gsettings set org.gnome.desktop.interface monospace-font-name "Monospace 11"
}

cmd_doom() {
  case "${1:-}" in
    install)
      shift
      case "${1:-}" in
        --check)
          shift
          [ "$#" -eq 0 ] || fail "unexpected argument for doom install --check: $1"
          doom_install_check
          return
          ;;
        "")
          ;;
        *)
          fail "unknown option for doom install: $1"
          ;;
      esac
      status "[doom] ensuring Doom Emacs checkout"
      doom_clone
      doom_save_default_config
      doom_link_dotfiles_config
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
      doom_refresh_recipe_repositories
      status "[doom] upgrading Doom Emacs"
      "$DOOM_BIN" upgrade
      doom_save_default_config
      doom_link_dotfiles_config
      doom_sync
      ;;
    restore-defaults)
      doom_restore_defaults
      ;;
    *)
      usage_configure
      exit 2
      ;;
  esac
}

case "${1:-}" in
  gnome)
    shift
    if [ "$#" -gt 0 ]; then
      usage_configure
      exit 2
    fi
    gnome_configure
    ;;
  doom)
    shift
    cmd_doom "$@"
    ;;
  -h|--help|help|"")
    usage_configure
    ;;
  *)
    usage_configure
    exit 2
    ;;
esac
