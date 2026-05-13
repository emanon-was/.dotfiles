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

run_dotfiles_configure() {
  home_dir="$1"
  built_home_files="$2"
  shift 2

  HOME="$home_dir" \
    DOTFILES_HOME="$repo_root" \
    DOTFILES_BUILT_HOME_FILES="$built_home_files" \
    bash -c '
      set -euo pipefail
      repo_root="$1"
      shift
      . "$repo_root/pkgs/dotfiles/scripts/lib/common.sh"
      . "$repo_root/pkgs/dotfiles/scripts/lib/doom.sh"
      . "$repo_root/pkgs/dotfiles/scripts/dotfiles-configure.sh"
    ' _ "$repo_root" "$@"
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

assert_template_copied() {
  template="$1"
  destination="$2"
  source="$repo_root/pkgs/dotfiles/templates/$template"

  diff -ru "$source" "$destination" >/dev/null || {
    printf 'error: project template was not copied correctly: %s\n' "$template" >&2
    diff -ru "$source" "$destination" >&2 || true
    exit 1
  }
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

  sample_bash="$(command -v bash)"
  {
    printf '#!%s\n' "$sample_bash"
    cat <<'SH'
printf 'sample:%s\n' "$*"
SH
  } > "$bin_dir/dotfiles-sample"
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
  assert_template_copied nix "$nix_dest"

  run_dotfiles_project init docker "$docker_dest"
  assert_template_copied docker "$docker_dest"

  assert_fails project-missing-template run_dotfiles_project init
  assert_fails project-unknown-template run_dotfiles_project init unknown "$test_root/unknown"
  assert_fails project-extra-argument run_dotfiles_project init nix "$test_root/extra" extra

  conflict_dest="$test_root/conflict-project"
  mkdir -p "$conflict_dest"
  cp "$repo_root/pkgs/dotfiles/templates/nix/flake.nix" "$conflict_dest/flake.nix"
  assert_fails project-existing-file run_dotfiles_project init nix "$conflict_dest"
  printf '[ok] project init\n'
}

test_home_file_source() {
  home_dir="$test_root/source-home"
  dotfiles_dir="$test_root/source-dotfiles"
  built_dir="$test_root/source-built"
  mkdir -p "$home_dir/.config/example" "$dotfiles_dir/home-files/.config/example" "$built_dir/.config/example"

  printf 'home\n' > "$home_dir/.config/example/file"
  printf 'dist\n' > "$dotfiles_dir/home-files/.config/example/file"
  printf 'built\n' > "$built_dir/.config/example/file"

  output="$(
    HOME="$home_dir" \
    DOTFILES_HOME="$dotfiles_dir" \
    DOTFILES_BUILT_HOME_FILES="$built_dir" \
    bash -c '
      set -euo pipefail
      repo_root="$1"
      dotfiles_dir="$2"
      . "$repo_root/pkgs/dotfiles/scripts/lib/common.sh"
      DOTFILES_HOME="$dotfiles_dir"
      dotfiles_home_file_source ".config/example/file"
    ' _ "$repo_root" "$dotfiles_dir"
  )"
  [ "$output" = "$home_dir/.config/example/file" ] || {
    printf 'error: home file source should prefer deployed HOME file: %s\n' "$output" >&2
    exit 1
  }

  output="$(
    HOME="$home_dir" \
    DOTFILES_HOME="$dotfiles_dir" \
    DOTFILES_PORTABLE_DIST=1 \
    DOTFILES_BUILT_HOME_FILES="$built_dir" \
    bash -c '
      set -euo pipefail
      repo_root="$1"
      dotfiles_dir="$2"
      . "$repo_root/pkgs/dotfiles/scripts/lib/common.sh"
      DOTFILES_HOME="$dotfiles_dir"
      dotfiles_home_file_source ".config/example/file"
    ' _ "$repo_root" "$dotfiles_dir"
  )"
  [ "$output" = "$dotfiles_dir/home-files/.config/example/file" ] || {
    printf 'error: portable source should prefer dist home-files: %s\n' "$output" >&2
    exit 1
  }

  rm "$home_dir/.config/example/file"
  output="$(
    HOME="$home_dir" \
    DOTFILES_HOME="$test_root/missing-dotfiles" \
    DOTFILES_BUILT_HOME_FILES="$built_dir" \
    bash -c '
      set -euo pipefail
      repo_root="$1"
      . "$repo_root/pkgs/dotfiles/scripts/lib/common.sh"
      dotfiles_home_file_source ".config/example/file"
    ' _ "$repo_root"
  )"
  [ "$output" = "$built_dir/.config/example/file" ] || {
    printf 'error: nix source should use built home-files: %s\n' "$output" >&2
    exit 1
  }

  printf 'manual\n' > "$home_dir/.config/example/file"
  output="$(
    HOME="$home_dir" \
    DOTFILES_HOME="$dotfiles_dir" \
    DOTFILES_BUILT_HOME_FILES="$built_dir" \
    bash -c '
      set -euo pipefail
      repo_root="$1"
      . "$repo_root/pkgs/dotfiles/scripts/lib/common.sh"
      dotfiles_managed_home_file_source ".config/example/file"
    ' _ "$repo_root"
  )"
  [ "$output" = "$built_dir/.config/example/file" ] || {
    printf 'error: managed source should not use deployed HOME file: %s\n' "$output" >&2
    exit 1
  }

  printf '[ok] home file source\n'
}

test_doom_config_dir_source() {
  home_dir="$test_root/doom-source-home"
  dotfiles_dir="$test_root/doom-source-dotfiles"
  built_dir="$test_root/doom-source-built"
  mkdir -p "$home_dir/.config/doom" "$dotfiles_dir/home-files/.config/doom" "$built_dir/.config/doom"
  printf 'home doom config\n' > "$home_dir/.config/doom/home-file"
  printf 'built doom config\n' > "$built_dir/.config/doom/built-file"

  output="$(
    HOME="$home_dir" \
    DOTFILES_HOME="$dotfiles_dir" \
    DOTFILES_BUILT_HOME_FILES="$built_dir" \
    bash -c '
      set -euo pipefail
      repo_root="$1"
      . "$repo_root/pkgs/dotfiles/scripts/lib/common.sh"
      . "$repo_root/pkgs/dotfiles/scripts/lib/doom.sh"
      doom_config_dir_source
    ' _ "$repo_root"
  )"
  [ "$output" = "$home_dir/.config/doom" ] || {
    printf 'error: doom config dir source should prefer deployed HOME directory: %s\n' "$output" >&2
    exit 1
  }

  output="$(
    HOME="$home_dir" \
    DOTFILES_HOME="$dotfiles_dir" \
    DOTFILES_BUILT_HOME_FILES="$built_dir" \
    bash -c '
      set -euo pipefail
      repo_root="$1"
      . "$repo_root/pkgs/dotfiles/scripts/lib/common.sh"
      . "$repo_root/pkgs/dotfiles/scripts/lib/doom.sh"
      doom_managed_config_dir_source
    ' _ "$repo_root"
  )"
  [ "$output" = "$built_dir/.config/doom" ] || {
    printf 'error: managed doom config dir source should prefer built home-files: %s\n' "$output" >&2
    exit 1
  }

  printf '[ok] doom config dir source\n'
}

test_configure_doctor() {
  home_dir="$test_root/configure-home"
  built_dir="$test_root/configure-built"
  mkdir -p "$home_dir" "$built_dir/.config/doom"
  printf 'doom config\n' > "$built_dir/.config/doom/config.el"

  run_dotfiles_configure "$home_dir" "$built_dir" doctor >/dev/null
  run_dotfiles_configure "$home_dir" "$built_dir" doom doctor >/dev/null
  run_dotfiles_configure "$home_dir" "$built_dir" gnome doctor >/dev/null

  assert_fails configure-doctor-extra run_dotfiles_configure "$home_dir" "$built_dir" doctor extra
  assert_fails doom-doctor-extra run_dotfiles_configure "$home_dir" "$built_dir" doom doctor extra
  assert_fails gnome-doctor-extra run_dotfiles_configure "$home_dir" "$built_dir" gnome doctor extra

  printf '[ok] configure doctor\n'
}

test_dispatcher
test_project_init
test_home_file_source
test_doom_config_dir_source
test_configure_doctor

printf 'dotfiles command behavior checks passed\n'
