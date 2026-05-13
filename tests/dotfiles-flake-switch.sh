#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

run_switch_case() {
  name="$1"
  initial_profile="$2"
  expected_profile="$3"
  expected_args="$4"
  expected_username="$5"
  expected_home="$6"
  shift 6

  output="$(
    DOTFILES_TEST_SOURCE_ONLY=1 \
    DOTFILES_HOME="$repo_root" \
    DOTFILES_PROFILE="$initial_profile" \
    HOME="/home/tester" \
    USER="tester" \
      bash -c '
        set -euo pipefail
        . "$1/pkgs/dotfiles/scripts/lib/common.sh"
        . "$1/pkgs/dotfiles/scripts/dotfiles-flake.sh"
        shift
        flake_switch_resolve "$@"
        printf "profile=%s\n" "$DOTFILES_SWITCH_PROFILE"
        printf "home_manager_args=%s\n" "$DOTFILES_SWITCH_HOME_MANAGER_ARGS"
        printf "username=%s\n" "$DOTFILES_USERNAME"
        printf "home_directory=%s\n" "$DOTFILES_HOME_DIRECTORY"
      ' _ "$repo_root" "$@"
  )"

  printf '%s\n' "$output" | grep -Fx "profile=$expected_profile" >/dev/null
  printf '%s\n' "$output" | grep -Fx "home_manager_args=$expected_args" >/dev/null
  printf '%s\n' "$output" | grep -Fx "username=$expected_username" >/dev/null
  printf '%s\n' "$output" | grep -Fx "home_directory=$expected_home" >/dev/null
  printf '[ok] %s\n' "$name"
}

run_switch_case \
  default \
  current \
  current \
  --impure \
  tester \
  /home/tester

run_switch_case \
  dotuser \
  current \
  current \
  --impure \
  dotuser \
  /home/dotuser \
  dotuser

run_switch_case \
  root \
  current \
  current \
  --impure \
  root \
  /root \
  root

run_switch_case \
  dist \
  current \
  dist \
  "" \
  tester \
  /home/tester \
  dist

run_switch_case \
  legacy-profile-env \
  nixos \
  current \
  --impure \
  nixos \
  /home/nixos

run_switch_case \
  explicit-current-keeps-user \
  current \
  current \
  --impure \
  tester \
  /home/tester \
  current

assert_switch_fails() {
  name="$1"
  shift
  if DOTFILES_TEST_SOURCE_ONLY=1 \
    DOTFILES_HOME="$repo_root" \
    DOTFILES_PROFILE=current \
    HOME="/home/tester" \
    USER="tester" \
      bash -c '
        set -euo pipefail
        . "$1/pkgs/dotfiles/scripts/lib/common.sh"
        . "$1/pkgs/dotfiles/scripts/dotfiles-flake.sh"
        shift
        flake_switch_resolve "$@"
      ' _ "$repo_root" "$@" >/dev/null 2>&1; then
    printf 'error: switch case should have failed: %s\n' "$name" >&2
    exit 1
  fi
  printf '[ok] %s\n' "$name"
}

assert_switch_fails unknown-option --unknown
assert_switch_fails duplicate-target dotuser bob

printf 'dotfiles flake switch behavior checks passed\n'
