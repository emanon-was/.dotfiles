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
    project_templates_dir="${DOTFILES_PROJECT_TEMPLATES:-$DOTFILES_HOME/project-templates}"
    if [ ! -d "$project_templates_dir" ] && [ -d "$(dirname "$DOTFILES_HOME")/project-templates" ]; then
      project_templates_dir="$(dirname "$DOTFILES_HOME")/project-templates"
    fi
    if [ ! -d "$project_templates_dir" ] && [ -d "$HOME/.dotfiles/project-templates" ]; then
      project_templates_dir="$HOME/.dotfiles/project-templates"
    fi
    source="$project_templates_dir/$template"
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
