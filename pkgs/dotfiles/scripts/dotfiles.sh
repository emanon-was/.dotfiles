usage() {
  cat <<'USAGE'
Usage:
  dotfiles doctor
  dotfiles switch [--skip-doom-sync] [profile]
  dotfiles check
  dotfiles update
  dotfiles configure gnome
  dotfiles configure doom install [--check]
  dotfiles configure doom sync
  dotfiles configure doom upgrade
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
    executable="dotfiles-$subcommand"

    dotfiles_path="$(command -v dotfiles 2>/dev/null || true)"
    if [ -n "$dotfiles_path" ]; then
      sibling_executable="$(dirname "$dotfiles_path")/$executable"
    else
      sibling_executable=""
    fi

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
