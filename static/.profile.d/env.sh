# bash/zsh の rc から読む共通環境変数。
dotfiles_prepend_path() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1${PATH:+:}$PATH" ;;
  esac
}

export XDG_LOCAL_HOME="$HOME/.local"
export DOTFILES_HOME="$HOME/.dotfiles"
export DOOM_EMACS_HOME="$HOME/.config/emacs"
export CARGO_HOME="$HOME/.cargo"
export GOPATH="$HOME/.go"
export NPM_GLOBAL="$HOME/.npm-global"
dotfiles_prepend_path "$HOME/.local/bin"
dotfiles_prepend_path "$HOME/.config/emacs/bin"
dotfiles_prepend_path "$HOME/.npm-global/bin"
dotfiles_prepend_path "$HOME/.cargo/bin"
dotfiles_prepend_path "$HOME/.go/bin"
export PATH
export TMUX_TMPDIR="${XDG_RUNTIME_DIR:-"/run/user/$(id -u)"}"
unset -f dotfiles_prepend_path
