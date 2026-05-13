# Doom Emacs helpers for dotfiles configure/doctor commands.
#
# Composition:
# - Loaded after scripts/lib/common.sh by pkgs/dotfiles/default.nix.
# - Used by dotfiles-configure.sh and dotfiles-doctor.sh.
#
# Depends on common.sh:
# - dotfiles_home_dir_source
# - dotfiles_managed_home_dir_source
#
# Environment inputs:
# - HOME: used to derive default DOOM_HOME and active ~/.config/doom fallback
# - DOOM_HOME: Doom Emacs checkout; defaults to $HOME/.config/emacs
# - DOTFILES_PORTABLE_DIST, DOTFILES_BUILT_HOME_FILES, DOTFILES_HOME: consumed
#   indirectly by common.sh source resolver functions
#
# Provides:
# - DOOM_HOME, DOOM_BIN
# - doom_config_dir_source
# - doom_managed_config_dir_source
# - doom_installed

DOOM_HOME="${DOOM_HOME:-$HOME/.config/emacs}"
DOOM_BIN="$DOOM_HOME/bin/doom"

doom_config_dir_source() {
  dotfiles_home_dir_source ".config/doom" || printf '%s\n' "$HOME/.config/doom"
}

doom_managed_config_dir_source() {
  dotfiles_managed_home_dir_source ".config/doom"
}

doom_installed() {
  [ -x "$DOOM_BIN" ]
}
