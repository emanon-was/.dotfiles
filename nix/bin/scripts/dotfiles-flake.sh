# This script is composed by nix/bin/default.nix.

default_home_manager_flake() {
  if [ -n "${DOTFILES_HOME:-}" ]; then
    if [ -d "$DOTFILES_HOME/profile/.config/home-manager" ]; then
      printf '%s\n' "$DOTFILES_HOME/profile/.config/home-manager"
      return 0
    fi

    if [ -d "$DOTFILES_HOME/.config/home-manager" ]; then
      printf '%s\n' "$DOTFILES_HOME/.config/home-manager"
      return 0
    fi
  fi

  printf '%s\n' "$HOME/.config/home-manager"
}

HOME_MANAGER_FLAKE="${HOME_MANAGER_FLAKE:-$(default_home_manager_flake)}"

usage_flake() {
  cat <<'USAGE'
Usage:
  dotfiles flake check
  dotfiles flake build
  dotfiles flake switch

Description:
  check   Home Manager 標準配置の flake check を --impure 付きで実行します。
  build   Home Manager 標準配置の activation package を --impure 付きで build します。
          result symlink は作りません。
  switch  Home Manager 標準配置の activation package を build して activate します。

Environment:
  HOME_MANAGER_FLAKE  Home Manager flake path.
                      Default: $DOTFILES_HOME/profile/.config/home-manager in repository mode,
                      $DOTFILES_HOME/.config/home-manager in profile mode,
                      otherwise $HOME/.config/home-manager.
USAGE
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

have() {
  command -v "$1" >/dev/null 2>&1
}

require_home_manager_flake() {
  [ -d "$HOME_MANAGER_FLAKE" ] || fail "Home Manager flake directory does not exist: $HOME_MANAGER_FLAKE"
  [ -f "$HOME_MANAGER_FLAKE/flake.nix" ] || fail "Home Manager flake.nix does not exist: $HOME_MANAGER_FLAKE/flake.nix"
}

prepare_nix_cache() {
  mkdir -p "$HOME/.cache/nix"
}

activation_package_ref() {
  printf '%s\n' "$HOME_MANAGER_FLAKE#homeConfigurations.default.activationPackage"
}

flake_check() {
  have nix || fail "nix is not available"
  require_home_manager_flake
  prepare_nix_cache
  nix flake check --impure "$HOME_MANAGER_FLAKE"
}

flake_build() {
  have nix || fail "nix is not available"
  require_home_manager_flake
  prepare_nix_cache
  nix build --impure --no-link --print-out-paths "$(activation_package_ref)"
}

flake_switch() {
  have nix || fail "nix is not available"
  require_home_manager_flake
  prepare_nix_cache
  activation_package="$(nix build --impure --no-link --print-out-paths "$(activation_package_ref)")"
  "$activation_package/activate"
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
  -h|--help|help|"")
    usage_flake
    ;;
  *)
    usage_flake
    exit 2
    ;;
esac
