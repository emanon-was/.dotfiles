if [ -z "$_PATH" ]; then
    export _PATH=$PATH;
fi

if [ -z "$_LD_LIBRARY_PATH" ];then
    export _LD_LIBRARY_PATH=$LD_LIBRARY_PATH;
fi

export GOPATH=$HOME/.go
export CARGO_HOME=$HOME/.cargo
export EMACS_HOME=$HOME/.emacs.d
export XDG_LOCAL_HOME=$HOME/.local
export PATH=$GOPATH/bin:$CARGO_HOME/bin:$EMACS_HOME/bin:$XDG_LOCAL_HOME/bin:$PATH
