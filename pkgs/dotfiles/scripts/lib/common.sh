# shellcheck disable=SC2329
set -u

if [ -n "${DOTFILES_PORTABLE_DIST:-}" ] || [ -z "${DOTFILES_HOME:-}" ]; then
  dotfiles_command_path="$0"
  if [ -n "$dotfiles_command_path" ] && command -v readlink >/dev/null 2>&1; then
    dotfiles_command_path="$(readlink -f "$dotfiles_command_path" 2>/dev/null || printf '%s\n' "$dotfiles_command_path")"
  fi
  dotfiles_bin_dir="$(dirname "${dotfiles_command_path:-$0}")"
  dotfiles_search_dir="$dotfiles_bin_dir"
  DOTFILES_HOME=""
  dotfiles_home_candidate=""
  while [ -n "$dotfiles_search_dir" ] && [ "$dotfiles_search_dir" != "/" ]; do
    if [ -d "$dotfiles_search_dir/pkgs/dotfiles/templates" ]; then
      if [ -n "${DOTFILES_PORTABLE_DIST:-}" ] && [ -n "$dotfiles_home_candidate" ]; then
        DOTFILES_HOME="$dotfiles_home_candidate"
      else
        DOTFILES_HOME="$dotfiles_search_dir"
      fi
      break
    fi
    if [ -z "$dotfiles_home_candidate" ] && [ -d "$dotfiles_search_dir/home-files" ]; then
      dotfiles_home_candidate="$dotfiles_search_dir"
    fi
    dotfiles_search_dir="$(dirname "$dotfiles_search_dir")"
  done
  DOTFILES_HOME="${DOTFILES_HOME:-${dotfiles_home_candidate:-$HOME/.dotfiles}}"
fi
DOTFILES_PROFILE="${DOTFILES_PROFILE:-nixos}"

status() {
  printf '%s\n' "$*"
}

ok() {
  status "[ok] $*"
}

warn() {
  status "[warn] $*"
}

missing() {
  status "[missing] $*"
}

skip() {
  status "[skip] $*"
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

have() {
  command -v "$1" >/dev/null 2>&1
}

require_dotfiles_home() {
  [ -d "$DOTFILES_HOME" ] || fail "DOTFILES_HOME does not exist: $DOTFILES_HOME"
}
