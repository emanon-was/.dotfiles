if [ -z "$_PATH" ]; then
    export _PATH=$PATH;
fi

if [ -z "$_LD_LIBRARY_PATH" ];then
    export _LD_LIBRARY_PATH=$LD_LIBRARY_PATH;
fi

export GOPATH=$HOME/.go
export CARGO_HOME=$HOME/.cargo
export DOOM_EMACS_HOME=$HOME/.config/emacs
export XDG_LOCAL_HOME=$HOME/.local
export DOTFILES_HOME=$HOME/.dotfiles
export PATH=$GOPATH/bin:$CARGO_HOME/bin:$DOOM_EMACS_HOME/bin:$XDG_LOCAL_HOME/bin:$DOTFILES_HOME/bin:$PATH
