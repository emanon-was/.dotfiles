PS1="\u@\h:\w\$ "

if [ -f "$HOME/.profile" ]; then
  source "$HOME/.profile"
fi

alias la='ls -a'
alias ll='ls -la'
alias ps='ps ux'
alias psgrep='ps aux | grep -v grep | grep --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias netstat='netstat -antup'
alias du='du -h'
alias df='df -h'
alias su='su -l'
alias nano='nano -Suwik'
alias emacs='emacs -nw'

if ls --help 2>&1 | grep -q -- --color; then
  alias ls='ls --color=auto -F'
else
  alias ls='ls -FG'
fi

if command -v trash >/dev/null 2>&1; then
  alias rm='trash-put'
fi

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook bash)"
fi
