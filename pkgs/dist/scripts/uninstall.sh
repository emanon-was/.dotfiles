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
state_dir="$HOME/.local/state/dotfiles"
manifest="$state_dir/init-manifest.tsv"

[ -d "$source_root" ] || {
  printf 'error: dist home-files directory not found: %s\n' "$source_root" >&2
  exit 1
}

restore_backup() {
  original_path="$1"
  backup_path="$2"

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
  expected_target="$2"
  [ -L "$link_path" ] || return 0

  link_target="$(readlink "$link_path")"
  [ "$link_target" = "$expected_target" ] || return 0

  rm "$link_path"
  printf 'removed home link: %s\n' "$link_path"
}

[ -f "$manifest" ] || {
  printf 'init manifest not found: %s\n' "$manifest"
  printf 'nothing to uninstall\n'
  exit 0
}

awk -F '\t' '$1 == "link" { print $2 "\t" $3 }' "$manifest" | while IFS="$(printf '\t')" read -r target_path source_path; do
  remove_link "$target_path" "$source_path"
done

awk -F '\t' '$1 == "dir" { print $2 }' "$manifest" | sort -r | while IFS= read -r target_path; do
  rmdir "$target_path" 2>/dev/null || true
done

awk -F '\t' '$1 == "backup" { print $2 "\t" $3 }' "$manifest" | while IFS="$(printf '\t')" read -r target_path backup_path; do
  restore_backup "$target_path" "$backup_path"
done

rm "$manifest"
rmdir "$state_dir" 2>/dev/null || true

printf 'removed managed links from: %s\n' "$HOME"
