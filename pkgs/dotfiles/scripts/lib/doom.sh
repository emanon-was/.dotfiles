DOOM_HOME="${DOOM_HOME:-$HOME/.config/emacs}"
DOOM_BIN="$DOOM_HOME/bin/doom"

doom_config_source() {
  dotfiles_home_file_source ".config/doom/config.el" || printf '%s\n' "$HOME/.config/doom/config.el"
}

doom_installed() {
  [ -x "$DOOM_BIN" ]
}
