#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

test_root="$(mktemp -d)"
cleanup() {
  rm -rf "$test_root"
}
trap cleanup EXIT

run_dotfiles_project() {
  DOTFILES_HOME="$repo_root" \
    bash -c '
      set -euo pipefail
      repo_root="$1"
      . "$repo_root/pkgs/dotfiles/scripts/lib/common.sh"
      . "$repo_root/pkgs/dotfiles/scripts/lib/templates.sh"
      shift
      . "$repo_root/pkgs/dotfiles/scripts/dotfiles-project.sh"
    ' _ "$repo_root" "$@"
}

assert_file() {
  [ -f "$1" ] || {
    printf 'error: expected file does not exist: %s\n' "$1" >&2
    exit 1
  }
}

assert_fails() {
  name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    printf 'error: command should have failed: %s\n' "$name" >&2
    exit 1
  fi
  printf '[ok] %s\n' "$name"
}

test_dispatcher() {
  bin_dir="$test_root/dispatcher-bin"
  mkdir -p "$bin_dir"

  {
    cat "$repo_root/pkgs/dotfiles/scripts/lib/common.sh"
    printf '\n'
    cat "$repo_root/pkgs/dotfiles/scripts/dotfiles.sh"
  } > "$bin_dir/dotfiles"
  chmod +x "$bin_dir/dotfiles"

  cat > "$bin_dir/dotfiles-sample" <<'SH'
#!/usr/bin/env bash
printf 'sample:%s\n' "$*"
SH
  chmod +x "$bin_dir/dotfiles-sample"

  output="$("$bin_dir/dotfiles" sample one two)"
  [ "$output" = "sample:one two" ] || {
    printf 'error: dispatcher output mismatch: %s\n' "$output" >&2
    exit 1
  }

  assert_fails dispatcher-unknown "$bin_dir/dotfiles" missing
  assert_fails dispatcher-moved-switch "$bin_dir/dotfiles" switch
  printf '[ok] dispatcher\n'
}

test_project_init() {
  nix_dest="$test_root/nix-project"
  docker_dest="$test_root/docker-project"

  run_dotfiles_project init nix "$nix_dest"
  assert_file "$nix_dest/flake.nix"
  assert_file "$nix_dest/Makefile"
  assert_file "$nix_dest/.envrc"

  run_dotfiles_project init docker "$docker_dest"
  assert_file "$docker_dest/docker.mk"

  assert_fails project-missing-template run_dotfiles_project init
  assert_fails project-unknown-template run_dotfiles_project init unknown "$test_root/unknown"
  assert_fails project-extra-argument run_dotfiles_project init nix "$test_root/extra" extra
  printf '[ok] project init\n'
}

test_dispatcher
test_project_init

printf 'dotfiles command behavior checks passed\n'
