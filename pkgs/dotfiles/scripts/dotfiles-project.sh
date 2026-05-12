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
    project_init_dir="${DOTFILES_PROJECT_INIT:-$DOTFILES_HOME/project-init}"
    if [ ! -d "$project_init_dir" ] && [ -d "$(dirname "$DOTFILES_HOME")/project-init" ]; then
      project_init_dir="$(dirname "$DOTFILES_HOME")/project-init"
    fi
    if [ ! -d "$project_init_dir" ] && [ -d "$HOME/.dotfiles/project-init" ]; then
      project_init_dir="$HOME/.dotfiles/project-init"
    fi
    source="$project_init_dir/$template"
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
