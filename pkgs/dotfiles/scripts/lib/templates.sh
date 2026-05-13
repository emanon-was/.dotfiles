# Project template helpers for dotfiles project/doctor commands.
#
# Composition:
# - Loaded after scripts/lib/common.sh by pkgs/dotfiles/default.nix.
# - Used by dotfiles-project.sh and dotfiles-doctor.sh.
#
# Depends on common.sh:
# - DOTFILES_HOME initialization
#
# Environment inputs:
# - DOTFILES_TEMPLATES: explicit template root override
# - DOTFILES_BUILT_TEMPLATES: Nix-built template root when available
# - DOTFILES_PORTABLE_DIST: disables repository fallback probing when set
# - DOTFILES_HOME: repository or portable dist root
# - HOME: final repository fallback probe under $HOME/.dotfiles
#
# Provides:
# - dotfiles_templates_dir

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
