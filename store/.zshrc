zshrc () { exit 0; }

#
# Prompt
#
autoload colors
colors
PROMPT="%n@%m%# "
RPROMPT="%B%{${fg[red]}%}[%~]%{${reset_color}%}%b"

#
# History
#
HISTFILE=~/.zsh_history
HISTSIZE=65535
SAVEHIST=65535
setopt hist_ignore_dups
setopt share_history

#
# Completion
#
autoload -U compinit
setopt complete_aliases
compinit

if [ -z "$(command -v profile)" ]; then
    source ~/.profile
fi

if [ ! -z "$(command -v direnv)" ]; then
    eval "$(direnv hook zsh)";
fi
