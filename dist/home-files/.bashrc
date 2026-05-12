

# Commands that should be applied only for interactive shells.
[[ $- == *i* ]] || return

HISTFILESIZE=100000
HISTSIZE=10000

shopt -s histappend
shopt -s extglob
shopt -s globstar
shopt -s checkjobs

alias -- df='df -h'
alias -- du='du -h'
alias -- egrep='egrep --color=auto'
alias -- emacs='emacs -nw'
alias -- fgrep='fgrep --color=auto'
alias -- grep='grep --color=auto'
alias -- la='ls -a'
alias -- ll='ls -la'
alias -- nano='nano -Suwik'
alias -- netstat='netstat -antup'
alias -- ps='ps ux'
alias -- psgrep='ps aux | grep -v grep | grep --color=auto'
alias -- su='su -l'


PS1="\u@\h:\w\$ "

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

if [ -n "${WSL_DISTRO_NAME:-}" ]; then
  export GDK_SCALE=2
  export GDK_DPI_SCALE=0.75
fi


