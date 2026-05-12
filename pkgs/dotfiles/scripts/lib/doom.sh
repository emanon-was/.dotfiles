DOOM_HOME="${DOOM_HOME:-$HOME/.config/emacs}"
DOOM_BIN="$DOOM_HOME/bin/doom"

doom_config_source() {
  if [ -f "$DOTFILES_HOME/home/config/doom/config.el" ]; then
    printf '%s\n' "$DOTFILES_HOME/home/config/doom/config.el"
  elif [ -f "$DOTFILES_HOME/home-files/.config/doom/config.el" ]; then
    printf '%s\n' "$DOTFILES_HOME/home-files/.config/doom/config.el"
  else
    printf '%s\n' "$DOTFILES_HOME/home/config/doom/config.el"
  fi
}

doom_installed() {
  [ -x "$DOOM_BIN" ]
}
