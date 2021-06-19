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
alias nano='\nano -Suwik';

if [ -z "$(command -v trash)" ]; then
    alias rm='\trash-put';
fi
