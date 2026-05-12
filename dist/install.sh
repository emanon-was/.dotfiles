#!/usr/bin/env bash
set -eu

usage() {
  cat <<'USAGE'
Usage:
  ./install.sh [prefix]

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

dist_root="$(cd "$(dirname "$0")" && pwd -P)"
prefix="${1:-$HOME}"

[ -d "$dist_root/home-files" ] || {
  printf 'error: dist home-files directory not found: %s\n' "$dist_root/home-files" >&2
  exit 1
}

[ -d "$dist_root/home-files/.local/bin" ] || {
  printf 'error: dist home-files bin directory not found: %s\n' "$dist_root/home-files/.local/bin" >&2
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
  printf 'moved existing path: %s -> %s\n' "$target_path" "$backup_target"
}

mkdir -p "$prefix/home-files"

chmod -R u+w \
  "$prefix/home-files" 2>/dev/null || true
rm -rf "$prefix/home-files"
mkdir -p "$prefix/home-files"

cp -R "$dist_root/home-files"/. "$prefix/home-files"/

find "$prefix/home-files" -mindepth 1 -type d | while IFS= read -r source_path; do
  relative_path="${source_path#"$prefix/home-files/"}"
  target_path="$HOME/$relative_path"

  if [ -L "$target_path" ]; then
    move_aside "$target_path"
    mkdir -p "$target_path"
  elif [ -d "$target_path" ]; then
    :
  elif [ -e "$target_path" ]; then
    move_aside "$target_path"
    mkdir -p "$target_path"
  else
    mkdir -p "$target_path"
  fi
done

find "$prefix/home-files" -mindepth 1 \( -type f -o -type l \) | while IFS= read -r source_path; do
  relative_path="${source_path#"$prefix/home-files/"}"
  target_path="$HOME/$relative_path"
  mkdir -p "$(dirname "$target_path")"

  if [ -L "$target_path" ]; then
    current_target="$(readlink "$target_path")"
    if [ "$current_target" = "$source_path" ]; then
      continue
    fi
    case "$current_target" in
      "$prefix/home-files/"*)
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
  printf 'linked home file: %s -> %s\n' "$target_path" "$source_path"
done

printf 'installed: %s\n' "$prefix"
printf 'command links: %s/.local/bin/dotfiles*\n' "$HOME"
printf 'ensure this directory is on PATH: %s/.local/bin\n' "$HOME"
