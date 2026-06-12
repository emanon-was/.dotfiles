# This script is composed by nix/bin/default.nix.

usage_build() {
  cat <<'USAGE'
Usage:
  dotfiles build

Description:
  repository の dotfiles-profile package を build し、profile/ を再生成します。
  make build と同じ用途の便利 command です。
USAGE
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

have() {
  command -v "$1" >/dev/null 2>&1
}

prepare_nix_cache() {
  mkdir -p "$HOME/.cache/nix"
}

repository_root() {
  if [ -n "${DOTFILES_HOME:-}" ]; then
    if [ -f "$DOTFILES_HOME/flake.nix" ] && [ -f "$DOTFILES_HOME/home.nix" ] && [ -d "$DOTFILES_HOME/nix" ]; then
      printf '%s\n' "$DOTFILES_HOME"
      return 0
    fi
    fail "dotfiles build requires repository root; DOTFILES_HOME is not a repository root: $DOTFILES_HOME"
  fi

  if [ -f ./flake.nix ] && [ -f ./home.nix ] && [ -d ./nix ]; then
    pwd
    return 0
  fi

  fail "dotfiles build requires repository root"
}

dotfiles_build() {
  set -e

  have nix || fail "nix is not available"
  have chmod || fail "chmod is not available"
  have rm || fail "rm is not available"
  have cp || fail "cp is not available"

  repo="$(repository_root)"
  profile="$repo/profile"
  tmp_profile="$repo/.profile.tmp.$$"

  prepare_nix_cache
  out="$(nix build "$repo#dotfiles-profile" --no-link --print-out-paths)"

  rm -rf "$tmp_profile"
  trap 'rm -rf "$tmp_profile"' EXIT
  cp -R "$out" "$tmp_profile"

  chmod -R u+w "$profile" 2>/dev/null || true
  rm -rf "$profile"
  mv "$tmp_profile" "$profile"
  trap - EXIT
}

case "${1:-}" in
  -h|--help|help)
    usage_build
    ;;
  "")
    dotfiles_build
    ;;
  *)
    usage_build
    exit 2
    ;;
esac
