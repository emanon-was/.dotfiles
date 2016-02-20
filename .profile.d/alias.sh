if ls -d --color=auto . > /dev/null 2>&1; then
    alias ls='\ls --color=auto';
elif ls -d -G . > /dev/null 2>&1; then
    alias ls='\ls -G';
fi

alias la='ls -a';
alias lf='ls -F';
alias ll='ls -la';

alias ps='\ps ux';
alias psgrep='\ps aux | \grep -v grep | \grep --color=auto';
alias grep='\grep --color=auto';
alias fgrep='\fgrep --color=auto';
alias egrep='\egrep --color=auto';
alias netstat='\netstat -antup';
alias du='\du -h';
alias df='\df -h';
alias su='\su -l';

alias rm='\trash-put';
alias tput='\trash-put';
alias tls='\trash-list';
alias trs='\trash-restore';
alias trm='\trash-remove';
alias tdel='\trash-empty';

alias emacs='\emacs -nw';
alias emacsd='\emacs --daemon';
alias emacsc='\emacsclient -ct';
alias emacsk='\emacsclient -e "(kill-emacs)"';
alias emacsp='\ps ux | \grep -v grep | \grep --color=auto emacs';
alias nano='\nano -Suwik';

