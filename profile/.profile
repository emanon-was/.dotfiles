
# login shell と desktop session で共有する環境変数。
export CARGO_HOME="$HOME/.cargo"
export DOOM_EMACS_HOME="$HOME/.config/emacs"
export DOTFILES_HOME="$HOME/.dotfiles"
export GOPATH="$HOME/.go"
export NPM_GLOBAL="$HOME/.npm-global"
export TMUX_TMPDIR="${XDG_RUNTIME_DIR:-"/run/user/$(id -u)"}"
export XDG_LOCAL_HOME="$HOME/.local"
export PATH="$HOME/.go/bin:$HOME/.cargo/bin:$HOME/.npm-global/bin:$HOME/.config/emacs/bin:$HOME/.local/bin${PATH:+:}$PATH"

dotfiles_profile_dir="$HOME/.profile.d"
if [ -d "$dotfiles_profile_dir" ]; then
  for dotfiles_profile in "$dotfiles_profile_dir"/*.sh; do
    [ -r "$dotfiles_profile" ] && . "$dotfiles_profile"
  done
fi
unset dotfiles_profile dotfiles_profile_dir
