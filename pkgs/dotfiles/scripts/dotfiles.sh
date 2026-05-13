# This script is composed by pkgs/dotfiles/default.nix.
# Prepended dependencies:
# - scripts/lib/common.sh
# Subcommands are provided as dotfiles-* executables on PATH.

usage() {
  cat <<'USAGE'
Usage:
  dotfiles doctor
  dotfiles flake check
  dotfiles flake update
  dotfiles flake switch [--skip-doom-sync] [current|dist|user]
  dotfiles flake doctor
  dotfiles configure gnome
  dotfiles configure doom install [--check]
  dotfiles configure doom sync
  dotfiles configure doom upgrade
  dotfiles configure doom repair
  dotfiles project init <nix|docker> [destination]
USAGE
}

case "${1:-}" in
  -h|--help|help|"")
    usage
    ;;
  -*)
    usage
    exit 2
    ;;
  *)
    subcommand="$1"
    shift

    case "$subcommand" in
      check|update|switch)
        printf 'error: dotfiles %s was moved under dotfiles flake\n' "$subcommand" >&2
        printf 'usage: dotfiles flake %s\n' "$subcommand" >&2
        exit 2
        ;;
    esac

    executable="dotfiles-$subcommand"

    dotfiles_path="$0"
    if command -v readlink >/dev/null 2>&1; then
      dotfiles_path="$(readlink -f "$dotfiles_path" 2>/dev/null || printf '%s\n' "$dotfiles_path")"
    fi
    sibling_executable="$(dirname "$dotfiles_path")/$executable"

    if [ -n "$sibling_executable" ] && [ -x "$sibling_executable" ]; then
      exec "$sibling_executable" "$@"
    fi

    if ! command -v "$executable" >/dev/null 2>&1; then
      printf 'error: unknown dotfiles command: %s\n' "$subcommand" >&2
      usage >&2
      exit 2
    fi
    exec "$executable" "$@"
    ;;
esac
