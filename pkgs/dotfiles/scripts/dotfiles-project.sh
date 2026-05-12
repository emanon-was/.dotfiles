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
    templates_dir="${DOTFILES_TEMPLATES:-${DOTFILES_BUILT_TEMPLATES:-$DOTFILES_HOME/home-files/.local/share/dotfiles/templates}}"
    if [ ! -d "$templates_dir" ] && [ -d "$DOTFILES_HOME/pkgs/dotfiles/templates" ]; then
      templates_dir="$DOTFILES_HOME/pkgs/dotfiles/templates"
    fi
    if [ ! -d "$templates_dir" ] && [ -d "$(dirname "$DOTFILES_HOME")/pkgs/dotfiles/templates" ]; then
      templates_dir="$(dirname "$DOTFILES_HOME")/pkgs/dotfiles/templates"
    fi
    if [ ! -d "$templates_dir" ] && [ -d "$HOME/.dotfiles/pkgs/dotfiles/templates" ]; then
      templates_dir="$HOME/.dotfiles/pkgs/dotfiles/templates"
    fi
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
