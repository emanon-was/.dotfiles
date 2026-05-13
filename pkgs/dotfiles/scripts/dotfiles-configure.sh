# This script is composed by pkgs/dotfiles/default.nix.
# Prepended dependencies:
# - scripts/lib/common.sh
# - scripts/lib/doom.sh
# Injected Nix variables:
# - DOTFILES_BUILT_HOME_FILES

usage_configure() {
  cat <<'USAGE'
Usage:
  dotfiles configure doctor
  dotfiles configure gnome
  dotfiles configure gnome doctor
  dotfiles configure doom install [--check]
  dotfiles configure doom sync
  dotfiles configure doom upgrade
  dotfiles configure doom repair
  dotfiles configure doom doctor
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
  source_dir="$(dotfiles_managed_home_dir_source ".config/doom" 2>/dev/null || true)"
  target_dir="$HOME/.config/doom"

  if [ -z "$source_dir" ]; then
    status "[doom] dotfiles doom config directory is not available"
    return 0
  fi

  if [ "$source_dir" = "$target_dir" ]; then
    status "[doom] dotfiles doom config already deployed: $target_dir"
    return 0
  fi

  mkdir -p "$target_dir"

  find "$source_dir" -mindepth 1 -type d | while IFS= read -r source_path; do
    relative_path="${source_path#"$source_dir/"}"
    mkdir -p "$target_dir/$relative_path"
  done

  find "$source_dir" -mindepth 1 \( -type f -o -type l \) | while IFS= read -r source_path; do
    relative_path="${source_path#"$source_dir/"}"
    target_path="$target_dir/$relative_path"
    mkdir -p "$(dirname "$target_path")"

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
        if ! git -C "$repo_path" fetch origin "$branch"; then
          warn "[doom] failed to fetch recipe repository, skipping: $repo"
          continue
        fi
        if ! git -C "$repo_path" merge --ff-only "origin/$branch"; then
          warn "[doom] failed to fast-forward recipe repository, skipping: $repo"
          continue
        fi
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

doom_workdir() {
  if [ -d "${HOME:-}" ]; then
    printf '%s\n' "$HOME"
  else
    printf '%s\n' /tmp
  fi
}

doom_run() {
  workdir="$(doom_workdir)"
  (
    cd "$workdir"
    "$DOOM_BIN" "$@"
  )
}

doom_sync_raw() {
  status "[doom] syncing Doom profile"
  doom_run sync
}

doom_save_initial_config() {
  require_dotfiles_home

  if ! doom_installed; then
    fail "Doom Emacs is not installed at $DOOM_HOME. Run: dotfiles configure doom install"
  fi

  initial_dir="$(dotfiles_state_dir)/doom-initial"
  check_root="$(mktemp -d)"

  (
    set -e

    temp_doomdir="$check_root/doomdir"
    temp_doomlocaldir="$check_root/doom-local"

    cleanup_initial_capture() {
      rm -rf "$check_root"
    }
    trap cleanup_initial_capture EXIT

    mkdir -p "$temp_doomdir" "$temp_doomlocaldir"

    status "[doom] generating Doom initial config in isolated local state"
    workdir="$(doom_workdir)"
    (
      cd "$workdir"
      HOME="$HOME" DOOMLOCALDIR="$temp_doomlocaldir" "$DOOM_BIN" --doomdir "$temp_doomdir" install --force --no-env --no-install --no-hooks
    )

    if ! find "$temp_doomdir" -mindepth 1 -print -quit | grep -q .; then
      fail "Doom install did not generate config files in: $temp_doomdir"
    fi

    rm -rf "$initial_dir.tmp"
    mkdir -p "$initial_dir.tmp"
    cp -R "$temp_doomdir"/. "$initial_dir.tmp"/
    rm -rf "$initial_dir"
    mv "$initial_dir.tmp" "$initial_dir"
    status "[doom] saved Doom initial config: $initial_dir"
  )
}

doom_repair_config() {
  initial_dir="$(dotfiles_state_dir)/doom-initial"
  [ -d "$initial_dir" ] || fail "Doom initial config is not saved yet: $initial_dir"

  target_dir="$HOME/.config/doom"
  mkdir -p "$target_dir"

  find "$target_dir" -mindepth 1 -maxdepth 1 | while IFS= read -r target_path; do
    backup_path="$(doom_backup_path "$target_path")"
    mv "$target_path" "$backup_path"
    status "[doom] moved existing config aside: $target_path -> $backup_path"
  done

  cp -R "$initial_dir"/. "$target_dir"/
  status "[doom] repaired Doom config from initial config: $target_dir"
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
  DOTFILES_FAKE_DOOM_INITIAL_SOURCE="$check_root/fake-doom-initial"
  mkdir -p "$DOTFILES_FAKE_DOOM_INITIAL_SOURCE"
  printf 'fake initial doom config\n' > "$DOTFILES_FAKE_DOOM_INITIAL_SOURCE/generated.el"
  export DOTFILES_HOME
  export DOTFILES_FAKE_DOOM_INITIAL_SOURCE

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
    # This fake Doom command is used only by `dotfiles configure doom install --check`.
    # It simulates Doom creating files under the configured doomdir without touching
    # the real Doom checkout, real user config, or network.
    mkdir -p "$doomdir"
    cp -R "$DOTFILES_FAKE_DOOM_INITIAL_SOURCE"/. "$doomdir"/
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

  status "[doom-check] verifying initial config capture"
  doom_save_initial_config
  if ! find "$HOME/.local/state/dotfiles/doom-initial" -mindepth 1 -print -quit | grep -q .; then
    fail "Doom initial config was not saved"
  fi

  status "[doom-check] verifying dotfiles config link"
  doom_link_dotfiles_config
  if ! find "$HOME/.config/doom" -mindepth 1 -type l -print -quit | grep -q .; then
    fail "Doom config was not linked"
  fi

  status "[doom-check] verifying install flow"
  doom_run install --force
  doom_sync_raw

  status "[doom-check] verifying sync preflight check"
  doom_sync

  status "[doom-check] verifying config repair"
  doom_repair_config
  if find "$HOME/.config/doom" -mindepth 1 -type l -print -quit | grep -q .; then
    fail "Doom repair should replace config links with files"
  fi

  status "[doom-check] verifying relink after repair"
  doom_link_dotfiles_config
  if ! find "$HOME/.config/doom" -mindepth 1 -type l -print -quit | grep -q .; then
    fail "Doom config was not relinked after repair"
  fi

  status "[doom-check] install check passed"
}

configure_doctor_commands() {
  failed=0

  for cmd in git cp mkdir; do
    if have "$cmd"; then
      ok "$cmd: $(command -v "$cmd")"
    else
      missing "$cmd"
      failed=1
    fi
  done

  return "$failed"
}

configure_doctor_home() {
  if [ -d "$DOTFILES_HOME" ]; then
    ok "DOTFILES_HOME: $DOTFILES_HOME"
  else
    missing "DOTFILES_HOME: $DOTFILES_HOME"
    return 1
  fi
}

doom_doctor_checkout() {
  failed=0

  if [ -d "$DOOM_HOME" ]; then
    ok "Doom checkout path: $DOOM_HOME"
  else
    skip "Doom checkout path: $DOOM_HOME"
    return 0
  fi

  if [ -d "$DOOM_HOME/.git" ]; then
    branch="$(git -C "$DOOM_HOME" branch --show-current 2>/dev/null || true)"
    head="$(git -C "$DOOM_HOME" rev-parse --short HEAD 2>/dev/null || true)"
    if [ -n "$branch" ]; then
      ok "Doom checkout git: $branch ${head:-unknown}"
    else
      warn "Doom checkout git is detached: ${head:-unknown}"
    fi
  else
    warn "Doom checkout git metadata is missing: $DOOM_HOME/.git"
  fi

  if doom_installed; then
    ok "Doom executable: $DOOM_BIN"
  else
    missing "Doom executable: $DOOM_BIN"
    failed=1
  fi

  return "$failed"
}

doom_doctor_config() {
  failed=0
  dotfiles_config_dir="$(doom_managed_config_dir_source 2>/dev/null || true)"
  active_config_dir="$HOME/.config/doom"

  if [ -n "$dotfiles_config_dir" ] && [ -d "$dotfiles_config_dir" ]; then
    ok "Doom config source: $dotfiles_config_dir"
  else
    missing "Doom config source directory"
    return 1
  fi

  if [ ! -d "$active_config_dir" ]; then
    skip "Doom config directory: $active_config_dir"
    return 0
  fi

  find "$dotfiles_config_dir" -mindepth 1 -type d | while IFS= read -r source_path; do
    relative_path="${source_path#"$dotfiles_config_dir/"}"
    target_path="$active_config_dir/$relative_path"
    if [ -d "$target_path" ]; then
      ok "Doom config directory exists: $target_path"
    else
      missing "Doom config directory missing: $target_path"
      exit 1
    fi
  done || failed=1

  find "$dotfiles_config_dir" -mindepth 1 \( -type f -o -type l \) | while IFS= read -r source_path; do
    relative_path="${source_path#"$dotfiles_config_dir/"}"
    target_path="$active_config_dir/$relative_path"

    if [ -L "$target_path" ]; then
      ok "Doom config symlink: $target_path -> $(readlink "$target_path")"
    elif [ -e "$target_path" ]; then
      warn "Doom config file is not a symlink: $target_path"
    else
      missing "Doom config file missing: $target_path"
      exit 1
    fi

    if cmp -s "$source_path" "$target_path"; then
      ok "Doom config matches dotfiles source: $relative_path"
    else
      missing "Doom config differs from dotfiles source: $relative_path"
      exit 1
    fi
  done || failed=1

  entry_count="$(find "$active_config_dir" -mindepth 1 -maxdepth 1 | wc -l)"
  ok "Doom config directory entries: $entry_count"

  return "$failed"
}

doom_doctor_straight_repositories() {
  recipes_dir="$DOOM_HOME/.local/straight/repos"
  [ -d "$recipes_dir" ] || {
    skip "straight recipe repositories: $recipes_dir"
    return 0
  }

  for repo in org-elpa melpa nongnu-elpa gnu-elpa-mirror el-get emacsmirror-mirror; do
    repo_path="$recipes_dir/$repo"
    if [ ! -d "$repo_path/.git" ]; then
      skip "straight recipe repository not present: $repo"
      continue
    fi

    branch="$(git -C "$repo_path" branch --show-current 2>/dev/null || true)"
    remote="$(git -C "$repo_path" remote get-url origin 2>/dev/null || true)"
    upstream="$(git -C "$repo_path" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)"

    if [ -z "$branch" ]; then
      warn "straight recipe repository detached: $repo"
    elif [ -z "$upstream" ]; then
      warn "straight recipe repository has no upstream: $repo branch=$branch remote=${remote:-none}"
    else
      ok "straight recipe repository: $repo branch=$branch upstream=$upstream"
    fi
  done
}

doom_doctor() {
  failed=0

  configure_doctor_commands || failed=1
  configure_doctor_home || failed=1
  doom_doctor_checkout || failed=1
  doom_doctor_config || failed=1
  doom_doctor_straight_repositories || true

  return "$failed"
}

gnome_doctor() {
  if ! have gsettings; then
    skip "gsettings: not available"
    return 0
  fi

  ok "gsettings: $(command -v gsettings)"

  if ! gsettings list-schemas | grep -qx "org.gnome.desktop.interface"; then
    warn "GNOME schema is not available: org.gnome.desktop.interface"
    return 0
  fi

  ok "GNOME schema: org.gnome.desktop.interface"

  for key in gtk-key-theme document-font-name font-name monospace-font-name; do
    if gsettings list-keys org.gnome.desktop.interface | grep -qx "$key"; then
      ok "GNOME key: org.gnome.desktop.interface $key"
    else
      warn "GNOME key is not available: org.gnome.desktop.interface $key"
    fi
  done
}

configure_doctor() {
  failed=0

  configure_doctor_commands || failed=1
  configure_doctor_home || failed=1
  gnome_doctor || true
  doom_doctor_checkout || failed=1
  doom_doctor_config || failed=1
  doom_doctor_straight_repositories || true

  return "$failed"
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
      doom_save_initial_config
      doom_link_dotfiles_config
      status "[doom] running Doom install"
      doom_run install --force
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
      doom_run upgrade --force
      doom_save_initial_config
      doom_link_dotfiles_config
      doom_sync
      ;;
    repair)
      doom_repair_config
      ;;
    doctor)
      shift
      [ "$#" -eq 0 ] || fail "unexpected argument for doom doctor: $1"
      doom_doctor
      ;;
    *)
      usage_configure
      exit 2
      ;;
  esac
}

case "${1:-}" in
  doctor)
    shift
    [ "$#" -eq 0 ] || fail "unexpected argument for configure doctor: $1"
    configure_doctor
    ;;
  gnome)
    shift
    case "${1:-}" in
      doctor)
        shift
        [ "$#" -eq 0 ] || fail "unexpected argument for gnome doctor: $1"
        gnome_doctor
        ;;
      "")
        gnome_configure
        ;;
      *)
        usage_configure
        exit 2
        ;;
    esac
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
