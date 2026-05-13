#!/usr/bin/env bash
set -euo pipefail

if [ -z "${NIX_BUILD_TOP:-}" ]; then
  printf 'error: tests must be run through nix flake check\n' >&2
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dist_root="${DOTFILES_TEST_DIST_ROOT:-$repo_root/dist}"
test_root="$(mktemp -d)"

cleanup() {
  rm -rf "$test_root"
}
trap cleanup EXIT

home="$test_root/home"
mkdir -p "$home/.cache" "$test_root/config-original"
ln -s "$test_root/config-original" "$home/.config"

printf 'existing bashrc\n' > "$home/.bashrc"
printf 'preexisting backup\n' > "$home/.bashrc.backup"

HOME="$home" bash "$dist_root/install.sh" >/dev/null

manifest="$home/.local/state/dotfiles/init-manifest.tsv"
[ -f "$manifest" ] || {
  printf 'error: init manifest was not created: %s\n' "$manifest" >&2
  exit 1
}

[ -L "$home/.bashrc" ] || {
  printf 'error: .bashrc was not linked\n' >&2
  exit 1
}

grep -F -x "link	$home/.bashrc	$dist_root/home-files/.bashrc" "$manifest" >/dev/null
grep -F -x "backup	$home/.bashrc	$home/.bashrc.backup.1" "$manifest" >/dev/null
grep -F -x "backup	$home/.config	$home/.config.backup" "$manifest" >/dev/null
grep -F -x "dir	$home/.config" "$manifest" >/dev/null

grep -F -x 'existing bashrc' "$home/.bashrc.backup.1" >/dev/null
grep -F -x 'preexisting backup' "$home/.bashrc.backup" >/dev/null

HOME="$home" bash "$dist_root/uninstall.sh" >/dev/null

[ ! -e "$manifest" ] || {
  printf 'error: init manifest was not removed\n' >&2
  exit 1
}

[ ! -L "$home/.bashrc" ] || {
  printf 'error: .bashrc link was not removed\n' >&2
  exit 1
}

grep -F -x 'existing bashrc' "$home/.bashrc" >/dev/null
grep -F -x 'preexisting backup' "$home/.bashrc.backup" >/dev/null
[ ! -e "$home/.bashrc.backup.1" ] || {
  printf 'error: numbered backup was not restored\n' >&2
  exit 1
}

[ -L "$home/.config" ] || {
  printf 'error: preexisting directory symlink was not restored: %s\n' "$home/.config" >&2
  exit 1
}
[ "$(readlink "$home/.config")" = "$test_root/config-original" ] || {
  printf 'error: restored directory symlink points to an unexpected target\n' >&2
  exit 1
}

[ -d "$home/.cache" ] || {
  printf 'error: preexisting directory was removed: %s\n' "$home/.cache" >&2
  exit 1
}

printf 'dotfiles dist install checks passed\n'
