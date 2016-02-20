auto-ssh-agent ()
{
    savefile=~/.ssh-agent

    if [ -z `command -v ssh-agent` ]\
    || [ -z `command -v pgrep` ]\
    || [ -z `command -v pkill` ];
    then
        unset savefile;
        return 1;
    fi

    if [ -z $SSH_AUTH_SOCK ]\
    || [ -z $SSH_AGENT_PID ];
    then
        if [ -z `\pgrep ssh-agent` ];
        then
            \ssh-agent > $savefile;
        elif [ ! -e $savefile ];
        then
            \pkill ssh-agent;
            \ssh-agent > $savefile;
        fi
        source $savefile > /dev/null;
    fi

    if [ -n $SSH_AUTH_SOCK ]\
    && [ -n $SSH_AGENT_PID ];
    then
        unset savefile;
        return 0;
    else
        \pkill ssh-agent && \ssh-agent > $savefile\
        && unset savefile && return 0;
    fi
}

auto-ssh-add ()
{
    _IFS=$IFS;IFS=$'\n';
    declare directory;
    if [ -d $1 ]\
    && [ `\cd $1;\pwd` != $HOME ]\
    && [ `\cd $1;\pwd` != $HOME/.ssh ];
    then
        directory=`\cd $1;\pwd`;
    fi

    if [ ! auto-ssh-agent ];then
        IFS=$_IFS;
        unset _IFS directory;
        return;
    fi

    \ssh-add -D 2>/dev/null;
    # ~/
    if [ -d ~/ ];then
        files=(`\find ~/ -maxdepth 1 -name "*.pem"`);
        for file in ${files[*]}; do
            \chmod 600 $file;
            \ssh-add $file;
        done
    fi
    # ~/.ssh
    if [ -d ~/.ssh ];then
        files=(`\find ~/.ssh -name "*.pem"`);
        for file in ${files[*]}; do
            \chmod 600 $file;
            \ssh-add $file;
        done
    fi
    # argument
    if [ ! -z $directory ];then
        files=(`\find $directory -name "*.pem"`);
        for file in ${files[@]}; do
            \chmod 600 $file;
            \ssh-add $file;
        done
    fi
    IFS=$_IFS;
    unset _IFS directory files file;
}
