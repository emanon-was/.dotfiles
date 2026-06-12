# interactive shell でだけ適用する設定。
[[ $- == *i* ]] || return

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
if [ -d "$dotfiles_completion_dir" ]; then
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

  PS1="\[\e[35m\][bash]\[\e[0m\] \[\e[32m\]\u@\h\[\e[0m\] \[\e[34m\]\w\[\e[0m\]\[\e[33m\]$(__dotfiles_prompt_git)\[\e[0m\]\[\e[31m\]$prompt_status\[\e[0m\]\n\\$ "
}
PROMPT_COMMAND=__dotfiles_prompt_command

# shell hook の組み込み。
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook bash)"
fi
