

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


__dotfiles_prompt_git() {
  command -v git >/dev/null 2>&1 || return 0
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

  branch="$(git branch --show-current 2>/dev/null)"
  if [ -z "$branch" ]; then
    branch="$(git rev-parse --short HEAD 2>/dev/null)"
  fi
  [ -n "$branch" ] || return 0

  dirty=""
  if ! git diff --quiet --ignore-submodules -- 2>/dev/null || ! git diff --cached --quiet --ignore-submodules -- 2>/dev/null; then
    dirty="*"
  fi

  printf ' [git:%s%s]' "$branch" "$dirty"
}


__dotfiles_prompt_command() {
  exit_code="$?"
  status=""
  if [ "$exit_code" -ne 0 ]; then
    status=" [exit:$exit_code]"
  fi

  PS1="\[\e[32m\]\u@\h\[\e[0m\] \[\e[34m\]\w\[\e[0m\]\[\e[33m\]$(__dotfiles_prompt_git)\[\e[0m\]\[\e[31m\]$status\[\e[0m\]\n\\$ "
}
PROMPT_COMMAND=__dotfiles_prompt_command

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


