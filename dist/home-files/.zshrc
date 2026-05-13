typeset -U path cdpath fpath manpath
for profile in ${(z)NIX_PROFILES}; do
  fpath+=($profile/share/zsh/site-functions $profile/share/zsh/$ZSH_VERSION/functions $profile/share/zsh/vendor-completions)
done


autoload -U compinit && compinit
ZSH_AUTOSUGGEST_STRATEGY=(history)


# History options should be set in .zshrc and after oh-my-zsh sourcing.
# See https://github.com/nix-community/home-manager/issues/177.
HISTSIZE="65535"
SAVEHIST="65535"

HISTFILE="$HOME/.zsh_history"
mkdir -p "$(dirname "$HISTFILE")"

# Set shell options
set_opts=(
  HIST_FCNTL_LOCK HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY
  NO_APPEND_HISTORY NO_EXTENDED_HISTORY NO_HIST_EXPIRE_DUPS_FIRST
  NO_HIST_FIND_NO_DUPS NO_HIST_IGNORE_ALL_DUPS NO_HIST_SAVE_NO_DUPS
)
for opt in "${set_opts[@]}"; do
  setopt "$opt"
done
unset opt set_opts

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


setopt prompt_subst
unset RPROMPT RPS1

__dotfiles_prompt_precmd() {
  exit_code="$?"
  status=""
  if [ "$exit_code" -ne 0 ]; then
    status=" [exit:$exit_code]"
  fi

  PROMPT="%F{green}%n@%m%f %F{blue}%~%f%F{yellow}$(__dotfiles_prompt_git)%f%F{red}$status%f"$'\n'"%# "
}
if [[ " ${precmd_functions[*]} " != *" __dotfiles_prompt_precmd "* ]]; then
  precmd_functions+=(__dotfiles_prompt_precmd)
fi

setopt complete_aliases

if ls --help 2>&1 | grep -q -- --color; then
  alias ls='ls --color=auto -F'
else
  alias ls='ls -FG'
fi

if command -v trash >/dev/null 2>&1; then
  alias rm='trash-put'
fi

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

if [ -n "${WSL_DISTRO_NAME:-}" ]; then
  export GDK_SCALE=2
  export GDK_DPI_SCALE=0.75
fi


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
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main)


