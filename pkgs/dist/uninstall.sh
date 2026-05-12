#!/usr/bin/env bash
set -eu

usage() {
  cat <<'USAGE'
Usage:
  ./uninstall.sh
USAGE
}

case "${1:-}" in
  -h|--help|help)
    usage
    exit 0
    ;;
esac

[ "$#" -eq 0 ] || {
  printf 'error: unexpected argument: %s\n' "$1" >&2
  usage >&2
  exit 2
}

dist_root="$(cd "$(dirname "$0")" && pwd -P)"
source_root="$dist_root/home-files"

[ -d "$source_root" ] || {
  printf 'error: dist home-files directory not found: %s\n' "$source_root" >&2
  exit 1
}

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
    "$source_root/"*)
      rm "$link_path"
      printf 'removed home link: %s\n' "$link_path"
      restore_backup "$link_path"
      ;;
    *) ;;
  esac
}

find "$source_root" -mindepth 1 \( -type f -o -type l \) | while IFS= read -r source_path; do
  relative_path="${source_path#"$source_root/"}"
  remove_link "$HOME/$relative_path"
done

find "$source_root" -mindepth 1 -type d | sort -r | while IFS= read -r source_path; do
  relative_path="${source_path#"$source_root/"}"
  target_path="$HOME/$relative_path"
  rmdir "$target_path" 2>/dev/null || true
  restore_backup "$target_path"
done

printf 'removed managed links from: %s\n' "$HOME"
