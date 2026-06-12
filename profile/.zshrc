typeset -U path cdpath fpath manpath

# Nix profile 由来の zsh completion 探索 path。
for profile in ${(z)NIX_PROFILES}; do
  fpath+=($profile/share/zsh/site-functions $profile/share/zsh/$ZSH_VERSION/functions $profile/share/zsh/vendor-completions)
done

# profile の command が配置した zsh completion。
dotfiles_site_functions="$HOME/.local/share/zsh/site-functions"
if [ -d "$dotfiles_site_functions" ]; then
  fpath=("$dotfiles_site_functions" $fpath)
fi
unset dotfiles_site_functions

autoload -U compinit && compinit

ZSH_AUTOSUGGEST_STRATEGY=(history)

# zsh の history 設定。
HISTSIZE="65535"
SAVEHIST="65535"

HISTFILE="$HOME/.zsh_history"
mkdir -p "$(dirname "$HISTFILE")"

# zsh の history 挙動。
set_opts=(
  HIST_FCNTL_LOCK HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY
  NO_APPEND_HISTORY NO_EXTENDED_HISTORY NO_HIST_EXPIRE_DUPS_FIRST
  NO_HIST_FIND_NO_DUPS NO_HIST_IGNORE_ALL_DUPS NO_HIST_SAVE_NO_DUPS
)
for opt in "${set_opts[@]}"; do
  setopt "$opt"
done
unset opt set_opts

# bash/zsh 共通 alias。
dotfiles_aliases="$HOME/.config/shell/aliases.sh"
[ -r "$dotfiles_aliases" ] && . "$dotfiles_aliases"
unset dotfiles_aliases

setopt prompt_subst
unset RPROMPT RPS1

# prompt 展開が zsh 固有なので prompt helper は zshrc に置く。
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

__dotfiles_prompt_precmd() {
  exit_code="$?"
  prompt_status=""
  if [ "$exit_code" -ne 0 ]; then
    prompt_status=" [exit:$exit_code]"
  fi

  PROMPT="%F{magenta}[zsh]%f %F{green}%n@%m%f %F{blue}%~%f%F{yellow}$(__dotfiles_prompt_git)%f%F{red}$prompt_status%f"$'\n'"%# "
}
if [[ " ${precmd_functions[*]} " != *" __dotfiles_prompt_precmd "* ]]; then
  precmd_functions+=(__dotfiles_prompt_precmd)
fi

setopt complete_aliases

# shell hook の組み込み。
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

ZSH_HIGHLIGHT_HIGHLIGHTERS=(main)
