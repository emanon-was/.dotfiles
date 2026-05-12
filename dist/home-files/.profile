




# Portable Home Manager session variables.
export CARGO_HOME="$HOME/.cargo"
export DOOM_EMACS_HOME="$HOME/.config/emacs"
export DOTFILES_HOME="$HOME/.dotfiles"
export GOPATH="$HOME/.go"
export TMUX_TMPDIR="${XDG_RUNTIME_DIR:-"/run/user/$(id -u)"}"
export XDG_LOCAL_HOME="$HOME/.local"
export PATH="$HOME/.go/bin:$HOME/.cargo/bin:$HOME/.config/emacs/bin:$HOME/.local/bin${PATH:+:}$PATH"
