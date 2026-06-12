# interactive shell でだけ適用する設定。
[[ $- == *i* ]] || return

# 共通環境変数と session env の断片。
dotfiles_profile_dir="$HOME/.profile.d"
if [ -d "$dotfiles_profile_dir" ]; then
  for dotfiles_profile in "$dotfiles_profile_dir"/*.sh; do
    [ -r "$dotfiles_profile" ] && . "$dotfiles_profile"
  done
fi
unset dotfiles_profile dotfiles_profile_dir

HISTFILESIZE=100000
HISTSIZE=10000

# bash の history と glob 設定。
shopt -s histappend
shopt -s extglob
shopt -s globstar
shopt -s checkjobs

# bash/zsh 共通 alias。
dotfiles_aliases="$HOME/.config/shell/aliases.sh"
[ -r "$dotfiles_aliases" ] && . "$dotfiles_aliases"
unset dotfiles_aliases

# profile の command が配置した bash completion。
dotfiles_completion_dir="$HOME/.local/share/bash-completion/completions"
if type complete >/dev/null 2>&1 && type compgen >/dev/null 2>&1 && [ -d "$dotfiles_completion_dir" ]; then
  for dotfiles_completion in "$dotfiles_completion_dir"/*; do
    [ -r "$dotfiles_completion" ] && . "$dotfiles_completion"
  done
fi
unset dotfiles_completion dotfiles_completion_dir

# PS1 の escape が bash 固有なので prompt helper は bashrc に置く。
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
  prompt_status=""
  if [ "$exit_code" -ne 0 ]; then
    prompt_status=" [exit:$exit_code]"
  fi

  local magenta green blue yellow red reset
  magenta=$'\001\033[35m\002'
  green=$'\001\033[32m\002'
  blue=$'\001\033[34m\002'
  yellow=$'\001\033[33m\002'
  red=$'\001\033[31m\002'
  reset=$'\001\033[0m\002'

  PS1="${magenta}[bash]${reset} ${green}\u@\h${reset} ${blue}\w${reset}${yellow}$(__dotfiles_prompt_git)${reset}${red}${prompt_status}${reset}"$'\n'"\\$ "
}
PROMPT_COMMAND=__dotfiles_prompt_command

# shell hook の組み込み。
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook bash)"
fi
