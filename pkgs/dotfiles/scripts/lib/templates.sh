dotfiles_templates_dir() {
  templates_dir="${DOTFILES_TEMPLATES:-${DOTFILES_BUILT_TEMPLATES:-$DOTFILES_HOME/home-files/.local/share/dotfiles/templates}}"

  if [ -z "${DOTFILES_PORTABLE_DIST:-}" ] && [ ! -d "$templates_dir" ] && [ -d "$DOTFILES_HOME/pkgs/dotfiles/templates" ]; then
    templates_dir="$DOTFILES_HOME/pkgs/dotfiles/templates"
  fi
  if [ -z "${DOTFILES_PORTABLE_DIST:-}" ] && [ ! -d "$templates_dir" ] && [ -d "$(dirname "$DOTFILES_HOME")/pkgs/dotfiles/templates" ]; then
    templates_dir="$(dirname "$DOTFILES_HOME")/pkgs/dotfiles/templates"
  fi
  if [ -z "${DOTFILES_PORTABLE_DIST:-}" ] && [ ! -d "$templates_dir" ] && [ -d "$HOME/.dotfiles/pkgs/dotfiles/templates" ]; then
    templates_dir="$HOME/.dotfiles/pkgs/dotfiles/templates"
  fi

  printf '%s\n' "$templates_dir"
}
