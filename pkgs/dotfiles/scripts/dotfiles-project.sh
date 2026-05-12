usage_project() {
  cat <<'USAGE'
Usage:
  dotfiles project init <nix|docker> [destination]
USAGE
}

case "${1:-}" in
  init)
    template="${2:-}"
    destination="${3:-.}"
    [ -n "$template" ] || fail "project template name is required"
    [ "$#" -le 3 ] || fail "unexpected argument for project init: $4"
    templates_dir="$(dotfiles_templates_dir)"
    source="$templates_dir/$template"
    [ -d "$source" ] || fail "unknown project template: $template"
    mkdir -p "$destination"
    cp -R "$source"/. "$destination"/
    ;;
  -h|--help|help|"")
    usage_project
    ;;
  *)
    usage_project
    exit 2
    ;;
esac
