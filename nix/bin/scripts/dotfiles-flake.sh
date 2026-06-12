# This script is composed by nix/bin/default.nix.

default_home_manager_root() {
  if [ -n "${DOTFILES_HOME:-}" ]; then
    if [ -f "$DOTFILES_HOME/flake.nix" ] && [ -f "$DOTFILES_HOME/home.nix" ] && [ -d "$DOTFILES_HOME/nix" ]; then
      printf '%s\n' "$DOTFILES_HOME"
      return 0
    fi
  fi

  if [ -f "$HOME/.dotfiles/flake.nix" ] && [ -f "$HOME/.dotfiles/home.nix" ] && [ -d "$HOME/.dotfiles/nix" ]; then
    printf '%s\n' "$HOME/.dotfiles"
    return 0
  fi

  printf '%s\n' "$PWD"
}

HOME_MANAGER_ROOT="$(default_home_manager_root)"

usage_flake() {
  cat <<'USAGE'
Usage:
  dotfiles flake check
  dotfiles flake build
  dotfiles flake switch
  dotfiles flake update

Description:
  check   dotfiles root flake の flake check を --impure 付きで実行します。
  build   Home Manager activation package を --impure 付きで build します。
          result symlink は作りません。
  switch  Home Manager activation package を build して activate します。
  update  dotfiles root flake の flake.lock を更新します。

Root resolution:
  DOTFILES_HOME が repository root の場合はそれを使います。
  それ以外では $HOME/.dotfiles を使い、存在しなければ current directory を使います。
USAGE
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

have() {
  command -v "$1" >/dev/null 2>&1
}

require_home_manager_root() {
  [ -d "$HOME_MANAGER_ROOT" ] || fail "Home Manager root directory does not exist: $HOME_MANAGER_ROOT"
  [ -f "$HOME_MANAGER_ROOT/flake.nix" ] || fail "Home Manager root flake.nix does not exist: $HOME_MANAGER_ROOT/flake.nix"
  [ -f "$HOME_MANAGER_ROOT/home.nix" ] || fail "Home Manager root home.nix does not exist: $HOME_MANAGER_ROOT/home.nix"
}

prepare_nix_cache() {
  mkdir -p "$HOME/.cache/nix"
}

activation_package_ref() {
  printf '%s\n' "$HOME_MANAGER_ROOT#homeConfigurations.default.activationPackage"
}

flake_check() {
  have nix || fail "nix is not available"
  require_home_manager_root
  prepare_nix_cache
  nix flake check --impure "$HOME_MANAGER_ROOT"
}

flake_build() {
  have nix || fail "nix is not available"
  require_home_manager_root
  prepare_nix_cache
  nix build --impure --no-link --print-out-paths "$(activation_package_ref)"
}

flake_switch() {
  have nix || fail "nix is not available"
  require_home_manager_root
  prepare_nix_cache
  activation_package="$(nix build --impure --no-link --print-out-paths "$(activation_package_ref)")"
  "$activation_package/activate"
}

flake_update() {
  have nix || fail "nix is not available"
  require_home_manager_root
  prepare_nix_cache
  nix flake update --flake "$HOME_MANAGER_ROOT"
}

case "${1:-}" in
  check)
    shift
    [ "$#" -eq 0 ] || fail "unexpected argument for flake check: $1"
    flake_check
    ;;
  build)
    shift
    [ "$#" -eq 0 ] || fail "unexpected argument for flake build: $1"
    flake_build
    ;;
  switch)
    shift
    [ "$#" -eq 0 ] || fail "unexpected argument for flake switch: $1"
    flake_switch
    ;;
  update)
    shift
    [ "$#" -eq 0 ] || fail "unexpected argument for flake update: $1"
    flake_update
    ;;
  -h|--help|help|"")
    usage_flake
    ;;
  *)
    usage_flake
    exit 2
    ;;
esac
