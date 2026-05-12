profile () { exit 0; }

load () { if [ -e "$1" ]; then source "$1"; fi; }
load "$HOME/.nix-profile/etc/profile.d/nix.sh"

export GOPATH="$HOME/.go"
export CARGO_HOME="$HOME/.cargo"
export DOOM_EMACS_HOME="$HOME/.config/emacs"
export XDG_LOCAL_HOME="$HOME/.local"
export DOTFILES_HOME="$HOME/.dotfiles"
export PATH="$GOPATH/bin:$CARGO_HOME/bin:$DOOM_EMACS_HOME/bin:$XDG_LOCAL_HOME/bin:$PATH"

if [ -n "${WSL_DISTRO_NAME:-}" ]; then
  export GDK_SCALE=2
  export GDK_DPI_SCALE=0.75
fi
