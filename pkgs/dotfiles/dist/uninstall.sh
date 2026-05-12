#!/usr/bin/env bash
set -eu

usage() {
  cat <<'USAGE'
Usage:
  ./uninstall.sh [prefix]

Environment:
  DOTFILES_BIN_DIR  Directory containing dotfiles command symlinks.

Default:
  prefix            $HOME
  DOTFILES_BIN_DIR  $HOME/.bin
USAGE
}

case "${1:-}" in
  -h|--help|help)
    usage
    exit 0
    ;;
esac

prefix="${1:-$HOME}"
bin_dir="${DOTFILES_BIN_DIR:-$HOME/.bin}"

case "$prefix" in
  ""|"/")
    printf 'error: refusing to remove unsafe prefix: %s\n' "$prefix" >&2
    exit 1
    ;;
esac

command_store="$prefix/bin"
if [ "$prefix" = "$HOME" ]; then
  command_store="$HOME/.bin"
fi

remove_link() {
  link_path="$1"
  [ -L "$link_path" ] || return 0

  link_target="$(readlink "$link_path")"
  case "$link_target" in
    "$command_store"/dotfiles*)
      rm "$link_path"
      printf 'removed command link: %s\n' "$link_path"
      ;;
    */bin/dotfiles*)
      rm "$link_path"
      printf 'removed command link: %s\n' "$link_path"
      ;;
    "$prefix/home-files/"*)
      rm "$link_path"
      printf 'removed home link: %s\n' "$link_path"
      ;;
    *)
      printf 'skipped link with unexpected target: %s -> %s\n' "$link_path" "$link_target"
      ;;
  esac
}

if [ -d "$prefix/home-files" ]; then
  find "$prefix/home-files" -mindepth 1 \( -type f -o -type l \) | while IFS= read -r source_path; do
    relative_path="${source_path#"$prefix/home-files/"}"
    remove_link "$HOME/$relative_path"
  done
fi

if [ -d "$bin_dir" ]; then
  for link_path in "$bin_dir"/dotfiles*; do
    remove_link "$link_path"
  done
fi

if [ -d "$command_store" ]; then
  for link_path in "$command_store"/dotfiles*; do
    remove_link "$link_path"
  done
fi

chmod -R u+w \
  "$prefix/home-files" 2>/dev/null || true
rm -rf "$prefix/home-files"

if [ "$prefix" = "$HOME" ]; then
  rmdir "$command_store" 2>/dev/null || true
  printf 'removed managed files from: %s\n' "$prefix"
elif [ -e "$prefix" ]; then
  chmod -R u+w "$prefix" 2>/dev/null || true
  rm -rf "$prefix"
  printf 'removed: %s\n' "$prefix"
else
  printf 'already absent: %s\n' "$prefix"
fi
