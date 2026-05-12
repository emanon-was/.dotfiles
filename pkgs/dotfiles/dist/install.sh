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

[ -d "$dist_root/bin" ] || {
  printf 'error: dist bin directory not found: %s\n' "$dist_root/bin" >&2
  exit 1
}

[ -d "$dist_root/home-files" ] || {
  printf 'error: dist home-files directory not found: %s\n' "$dist_root/home-files" >&2
  exit 1
}

command_store="$prefix/bin"
if [ "$prefix" = "$HOME" ]; then
  command_store="$HOME/.bin"
fi

mkdir -p "$command_store" "$prefix/home-files" "$bin_dir"

chmod -R u+w \
  "$command_store" \
  "$prefix/home-files" 2>/dev/null || true
rm -rf "$prefix/home-files"
mkdir -p "$command_store" "$prefix/home-files"

cp -R "$dist_root/home-files"/. "$prefix/home-files"/

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
        printf 'error: refusing to replace symlink with unexpected target: %s -> %s\n' "$target_path" "$current_target" >&2
        exit 1
        ;;
    esac
  elif [ -e "$target_path" ]; then
    printf 'error: refusing to replace existing file: %s\n' "$target_path" >&2
    exit 1
  fi

  ln -s "$source_path" "$target_path"
  printf 'linked home file: %s -> %s\n' "$target_path" "$source_path"
done

find "$dist_root/bin" -mindepth 1 -maxdepth 1 -type f | while IFS= read -r source_path; do
  command_name="$(basename "$source_path")"
  command_path="$command_store/$command_name"

  if [ -L "$command_path" ]; then
    current_target="$(readlink "$command_path")"
    if [ "$current_target" = "$source_path" ]; then
      :
    else
      case "$current_target" in
        "$dist_root/bin/"*)
          rm "$command_path"
          ln -s "$source_path" "$command_path"
          ;;
        *)
          printf 'error: refusing to replace command symlink with unexpected target: %s -> %s\n' "$command_path" "$current_target" >&2
          exit 1
          ;;
      esac
    fi
  elif [ -f "$command_path" ] && cmp -s "$command_path" "$source_path"; then
    rm "$command_path"
    ln -s "$source_path" "$command_path"
  elif [ -e "$command_path" ]; then
    printf 'error: refusing to replace existing command file: %s\n' "$command_path" >&2
    exit 1
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
