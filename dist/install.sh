#!/usr/bin/env bash
set -eu

usage() {
  cat <<'USAGE'
Usage:
  ./install.sh [prefix]

Environment:
  DOTFILES_BIN_DIR  Directory for dotfiles command symlinks.

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

dist_root="$(cd "$(dirname "$0")" && pwd -P)"
prefix="${1:-$HOME/.local/share/dotfiles}"
bin_dir="${DOTFILES_BIN_DIR:-$HOME/.local/bin}"

[ -d "$dist_root/bin" ] || {
  printf 'error: dist bin directory not found: %s\n' "$dist_root/bin" >&2
  exit 1
}

[ -d "$dist_root/project-templates" ] || {
  printf 'error: dist project-templates directory not found: %s\n' "$dist_root/project-templates" >&2
  exit 1
}

[ -d "$dist_root/home" ] || {
  printf 'error: dist home directory not found: %s\n' "$dist_root/home" >&2
  exit 1
}

mkdir -p "$prefix/bin" "$prefix/project-templates" "$prefix/home" "$prefix/home-files" "$bin_dir"

chmod -R u+w "$prefix/bin" "$prefix/project-templates" "$prefix/home" "$prefix/home-files" 2>/dev/null || true
rm -rf "$prefix/bin" "$prefix/project-templates" "$prefix/home" "$prefix/home-files"
mkdir -p "$prefix/bin" "$prefix/project-templates" "$prefix/home" "$prefix/home-files"

cp -R "$dist_root/bin"/. "$prefix/bin"/
cp -R "$dist_root/project-templates"/. "$prefix/project-templates"/
cp -R "$dist_root/home"/. "$prefix/home"/
if [ -d "$dist_root/home-files" ]; then
  cp -R "$dist_root/home-files"/. "$prefix/home-files"/
fi
chmod +x "$prefix"/bin/dotfiles*

for command_path in "$prefix"/bin/dotfiles*; do
  command_name="$(basename "$command_path")"
  ln -sf "$command_path" "$bin_dir/$command_name"
done

printf 'installed: %s\n' "$prefix"
printf 'linked commands: %s/dotfiles*\n' "$bin_dir"
printf 'ensure this directory is on PATH: %s\n' "$bin_dir"
