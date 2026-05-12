#!/usr/bin/env bash
set -eu

usage() {
  cat <<'USAGE'
Usage:
  ./uninstall.sh [prefix]

Environment:
  DOTFILES_BIN_DIR  Directory containing dotfiles command symlinks.

Default:
  prefix            $HOME/.local/share/dotfiles
  DOTFILES_BIN_DIR  $HOME/.local/bin
USAGE
}

case "${1:-}" in
  -h|--help|help)
    usage
    exit 0
    ;;
esac

prefix="${1:-$HOME/.local/share/dotfiles}"
bin_dir="${DOTFILES_BIN_DIR:-$HOME/.local/bin}"

case "$prefix" in
  ""|"/"|"$HOME")
    printf 'error: refusing to remove unsafe prefix: %s\n' "$prefix" >&2
    exit 1
    ;;
esac

remove_link() {
  link_path="$1"
  [ -L "$link_path" ] || return 0

  link_target="$(readlink "$link_path")"
  case "$link_target" in
    "$prefix"/bin/dotfiles*)
      rm "$link_path"
      printf 'removed link: %s\n' "$link_path"
      ;;
    *)
      printf 'skipped link with unexpected target: %s -> %s\n' "$link_path" "$link_target"
      ;;
  esac
}

if [ -d "$bin_dir" ]; then
  for link_path in "$bin_dir"/dotfiles*; do
    remove_link "$link_path"
  done
fi

if [ -e "$prefix" ]; then
  chmod -R u+w "$prefix" 2>/dev/null || true
  rm -rf "$prefix"
  printf 'removed: %s\n' "$prefix"
else
  printf 'already absent: %s\n' "$prefix"
fi
