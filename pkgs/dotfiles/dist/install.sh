#!/usr/bin/env bash
set -eu

usage() {
  cat <<'USAGE'
Usage:
  ./install.sh [prefix]

Environment:
  DOTFILES_BIN_DIR  Directory for dotfiles command symlinks.

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

dist_root="$(cd "$(dirname "$0")" && pwd -P)"
prefix="${1:-$HOME}"
bin_dir="${DOTFILES_BIN_DIR:-$HOME/.bin}"

[ -d "$dist_root/home-files" ] || {
  printf 'error: dist home-files directory not found: %s\n' "$dist_root/home-files" >&2
  exit 1
}

[ -d "$dist_root/home-files/.local/bin" ] || {
  printf 'error: dist home-files bin directory not found: %s\n' "$dist_root/home-files/.local/bin" >&2
  exit 1
}

command_store="$prefix/bin"
if [ "$prefix" = "$HOME" ]; then
  command_store="$HOME/.bin"
fi

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

mkdir -p "$command_store" "$prefix/home-files" "$bin_dir"

chmod -R u+w \
  "$command_store" \
  "$prefix/home-files" 2>/dev/null || true
rm -rf "$prefix/home-files"
mkdir -p "$command_store" "$prefix/home-files"

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

find "$dist_root/home-files/.local/bin" -mindepth 1 -maxdepth 1 -type f | while IFS= read -r source_path; do
  command_name="$(basename "$source_path")"
  command_path="$command_store/$command_name"

  if [ -L "$command_path" ]; then
    current_target="$(readlink "$command_path")"
    if [ "$current_target" = "$source_path" ]; then
      :
    else
      case "$current_target" in
        "$dist_root/home-files/.local/bin/"*)
          rm "$command_path"
          ln -s "$source_path" "$command_path"
          ;;
        *)
          move_aside "$command_path"
          ln -s "$source_path" "$command_path"
          ;;
      esac
    fi
  elif [ -f "$command_path" ] && cmp -s "$command_path" "$source_path"; then
    rm "$command_path"
    ln -s "$source_path" "$command_path"
  elif [ -e "$command_path" ]; then
    move_aside "$command_path"
    ln -s "$source_path" "$command_path"
  else
    ln -s "$source_path" "$command_path"
  fi

  if [ "$bin_dir/$command_name" = "$command_path" ]; then
    continue
  fi
  ln -sf "$command_path" "$bin_dir/$command_name"
done

printf 'installed: %s\n' "$prefix"
printf 'command links: %s/dotfiles*\n' "$command_store"
printf 'linked commands: %s/dotfiles*\n' "$bin_dir"
printf 'ensure this directory is on PATH: %s\n' "$bin_dir"
