#!/usr/bin/env bash
set -eu

usage() {
  cat <<'USAGE'
Usage:
  ./uninstall.sh [prefix]

Default:
  prefix            $HOME
USAGE
}

case "${1:-}" in
  -h|--help|help)
    usage
    exit 0
    ;;
esac

prefix="${1:-$HOME}"

case "$prefix" in
  ""|"/")
    printf 'error: refusing to remove unsafe prefix: %s\n' "$prefix" >&2
    exit 1
    ;;
esac

restore_backup() {
  original_path="$1"
  backup_path="$original_path.backup"

  [ -e "$backup_path" ] || [ -L "$backup_path" ] || return 0

  if [ -e "$original_path" ] || [ -L "$original_path" ]; then
    printf 'skipped backup restore, path exists: %s\n' "$original_path"
    return 0
  fi

  mv "$backup_path" "$original_path"
  printf 'restored backup: %s -> %s\n' "$backup_path" "$original_path"
}

remove_link() {
  link_path="$1"
  [ -L "$link_path" ] || return 0

  link_target="$(readlink "$link_path")"
  case "$link_target" in
    "$prefix/home-files/"*)
      rm "$link_path"
      printf 'removed home link: %s\n' "$link_path"
      restore_backup "$link_path"
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

  find "$prefix/home-files" -mindepth 1 -type d | sort -r | while IFS= read -r source_path; do
    relative_path="${source_path#"$prefix/home-files/"}"
    target_path="$HOME/$relative_path"
    rmdir "$target_path" 2>/dev/null || true
    restore_backup "$target_path"
  done
fi

chmod -R u+w \
  "$prefix/home-files" 2>/dev/null || true
rm -rf "$prefix/home-files"

if [ "$prefix" = "$HOME" ]; then
  printf 'removed managed files from: %s\n' "$prefix"
elif [ -e "$prefix" ]; then
  chmod -R u+w "$prefix" 2>/dev/null || true
  rm -rf "$prefix"
  printf 'removed: %s\n' "$prefix"
else
  printf 'already absent: %s\n' "$prefix"
fi
