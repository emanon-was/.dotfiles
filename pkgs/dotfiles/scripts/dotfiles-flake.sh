usage_flake() {
  cat <<'USAGE'
Usage:
  dotfiles flake check
  dotfiles flake update
  dotfiles flake switch [--skip-doom-sync] [current|dist|user]
  dotfiles flake doctor
USAGE
}

flake_check() {
  require_dotfiles_home
  nix flake check "$DOTFILES_HOME"
}

flake_update() {
  require_dotfiles_home
  nix flake update --flake "$DOTFILES_HOME"
  flake_check
}

flake_switch() {
  require_dotfiles_home

  skip_doom_sync=0
  normalize_home_manager_profile
  profile="$DOTFILES_PROFILE"
  switch_target_seen=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --skip-doom-sync)
        skip_doom_sync=1
        ;;
      -*)
        fail "unknown option for flake switch: $1"
        ;;
      *)
        [ "$switch_target_seen" -eq 0 ] || fail "unexpected argument for flake switch: $1"
        switch_target_seen=1
        case "$1" in
          current|dist)
            profile="$1"
            ;;
          root)
            profile="current"
            DOTFILES_USERNAME="root"
            if [ "${DOTFILES_HOME_DIRECTORY_DEFAULTED:-0}" -eq 1 ]; then
              DOTFILES_HOME_DIRECTORY="/root"
            fi
            export DOTFILES_USERNAME DOTFILES_HOME_DIRECTORY
            ;;
          *)
            profile="current"
            DOTFILES_USERNAME="$1"
            if [ "${DOTFILES_HOME_DIRECTORY_DEFAULTED:-0}" -eq 1 ]; then
              DOTFILES_HOME_DIRECTORY="/home/$1"
            fi
            export DOTFILES_USERNAME DOTFILES_HOME_DIRECTORY
            ;;
        esac
        ;;
    esac
    shift
  done

  home_manager_args=""
  if [ "$profile" = "current" ]; then
    home_manager_args="--impure"
  fi

  # shellcheck disable=SC2086
  home-manager -b hm-backup --flake "$DOTFILES_HOME#$profile" $home_manager_args switch

  if [ "$skip_doom_sync" -eq 0 ]; then
    dotfiles_path="$0"
    if command -v readlink >/dev/null 2>&1; then
      dotfiles_path="$(readlink -f "$dotfiles_path" 2>/dev/null || printf '%s\n' "$dotfiles_path")"
    fi
    configure_command="$(dirname "$dotfiles_path")/dotfiles-configure"
    if [ ! -x "$configure_command" ]; then
      configure_command="dotfiles-configure"
    fi
    "$configure_command" doom sync
  else
    status "[skip] doom sync"
  fi
}

flake_doctor_commands() {
  failed=0

  for cmd in nix home-manager git; do
    if have "$cmd"; then
      ok "$cmd: $(command -v "$cmd")"
    else
      missing "$cmd"
      failed=1
    fi
  done

  return "$failed"
}

flake_doctor_home() {
  if [ -d "$DOTFILES_HOME" ]; then
    ok "DOTFILES_HOME: $DOTFILES_HOME"
  else
    missing "DOTFILES_HOME: $DOTFILES_HOME"
    return 1
  fi

  if [ -f "$DOTFILES_HOME/flake.nix" ]; then
    ok "flake.nix: $DOTFILES_HOME/flake.nix"
  else
    missing "flake.nix: $DOTFILES_HOME/flake.nix"
    return 1
  fi
}

flake_doctor_home_manager() {
  normalize_home_manager_profile

  if ! have home-manager; then
    missing "Home Manager command is unavailable"
    return 1
  fi

  if generation="$(home-manager generations 2>/dev/null | sed -n '1p')" && [ -n "$generation" ]; then
    ok "Home Manager current generation: $generation"
  else
    warn "Home Manager generation was not found"
  fi

  if [ -d "$DOTFILES_HOME" ]; then
    ok "Home Manager profile: $DOTFILES_HOME#$DOTFILES_PROFILE"
    if [ "$DOTFILES_PROFILE" = "current" ]; then
      ok "Home Manager user: $DOTFILES_USERNAME"
      ok "Home Manager home: $DOTFILES_HOME_DIRECTORY"
    fi
  fi
}

flake_doctor_inputs() {
  flake_file="$DOTFILES_HOME/flake.nix"
  [ -f "$flake_file" ] || return 1

  nixpkgs_url="$(sed -n 's/.*nixpkgs.url = "\(.*\)";.*/\1/p' "$flake_file" | sed -n '1p')"
  home_manager_url="$(sed -n 's/.*url = "\(github:nix-community\/home-manager\/.*\)";.*/\1/p' "$flake_file" | sed -n '1p')"

  if [ "$nixpkgs_url" = "github:NixOS/nixpkgs/nixos-unstable" ]; then
    ok "home nixpkgs input: $nixpkgs_url"
  elif [ -n "$nixpkgs_url" ]; then
    warn "home nixpkgs input is not nixos-unstable: $nixpkgs_url"
  else
    missing "home nixpkgs input"
    return 1
  fi

  if [ "$home_manager_url" = "github:nix-community/home-manager/master" ]; then
    ok "home-manager input: $home_manager_url"
  elif [ -n "$home_manager_url" ]; then
    warn "home-manager input is not master: $home_manager_url"
  else
    missing "home-manager input"
    return 1
  fi

  status "[info] NixOS system should remain stable outside this Home Manager flake"
}

flake_doctor() {
  failed=0

  flake_doctor_commands || failed=1
  flake_doctor_home || failed=1
  flake_doctor_home_manager || true
  flake_doctor_inputs || failed=1

  return "$failed"
}

case "${1:-}" in
  check)
    shift
    [ "$#" -eq 0 ] || fail "unexpected argument for flake check: $1"
    flake_check
    ;;
  update)
    shift
    [ "$#" -eq 0 ] || fail "unexpected argument for flake update: $1"
    flake_update
    ;;
  switch)
    shift
    flake_switch "$@"
    ;;
  doctor)
    shift
    [ "$#" -eq 0 ] || fail "unexpected argument for flake doctor: $1"
    flake_doctor
    ;;
  -h|--help|help|"")
    usage_flake
    ;;
  *)
    usage_flake
    exit 2
    ;;
esac
