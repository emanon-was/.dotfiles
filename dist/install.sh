#!/usr/bin/env bash
set -eu

usage() {
  cat <<'USAGE'
Usage:
  ./install.sh
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
manifest_tmp="$(mktemp)"

cleanup() {
  rm -f "$manifest_tmp"
}
trap cleanup EXIT

if [ -f "$manifest" ]; then
  cp "$manifest" "$manifest_tmp"
fi

[ -d "$source_root" ] || {
  printf 'error: dist home-files directory not found: %s\n' "$source_root" >&2
  exit 1
}

[ -d "$source_root/.local/bin" ] || {
  printf 'error: dist home-files bin directory not found: %s\n' "$source_root/.local/bin" >&2
  exit 1
}

backup_path() {
  original_path="$1"
  backup_candidate="$original_path.backup"
  index=1

  while [ -e "$backup_candidate" ] || [ -L "$backup_candidate" ]; do
    backup_candidate="$original_path.backup.$index"
    index=$((index + 1))
  done

  printf '%s\n' "$backup_candidate"
}

move_aside() {
  target_path="$1"
  backup_target="$(backup_path "$target_path")"
  mv "$target_path" "$backup_target"
  record_manifest "backup	$target_path	$backup_target"
  printf 'moved existing path: %s -> %s\n' "$target_path" "$backup_target"
}

record_manifest() {
  line="$1"
  grep -F -x "$line" "$manifest_tmp" >/dev/null 2>&1 || printf '%s\n' "$line" >> "$manifest_tmp"
}

find "$source_root" -mindepth 1 -type d | while IFS= read -r source_path; do
  relative_path="${source_path#"$source_root/"}"
  target_path="$HOME/$relative_path"

  if [ -L "$target_path" ]; then
    move_aside "$target_path"
    mkdir -p "$target_path"
    record_manifest "dir	$target_path"
  elif [ -d "$target_path" ]; then
    :
  elif [ -e "$target_path" ]; then
    move_aside "$target_path"
    mkdir -p "$target_path"
    record_manifest "dir	$target_path"
  else
    mkdir -p "$target_path"
    record_manifest "dir	$target_path"
  fi
done

find "$source_root" -mindepth 1 \( -type f -o -type l \) | while IFS= read -r source_path; do
  relative_path="${source_path#"$source_root/"}"
  target_path="$HOME/$relative_path"
  mkdir -p "$(dirname "$target_path")"

  if [ -L "$target_path" ]; then
    current_target="$(readlink "$target_path")"
    if [ "$current_target" = "$source_path" ]; then
      continue
    fi
    case "$current_target" in
      "$source_root/"*)
        rm "$target_path"
        ;;
      *)
        move_aside "$target_path"
        ;;
    esac
  elif [ -e "$target_path" ]; then
    move_aside "$target_path"
  fi

  ln -s "$source_path" "$target_path"
  record_manifest "link	$target_path	$source_path"
  printf 'linked home file: %s -> %s\n' "$target_path" "$source_path"
done

mkdir -p "$state_dir"
cp "$manifest_tmp" "$manifest"

printf 'installed from: %s\n' "$source_root"
printf 'init manifest: %s\n' "$manifest"
printf 'command links: %s/.local/bin/dotfiles*\n' "$HOME"
printf 'ensure this directory is on PATH: %s/.local/bin\n' "$HOME"
