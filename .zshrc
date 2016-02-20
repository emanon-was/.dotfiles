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

#
# Share Config
#
source_file=~/.profile;
if [ -e $source_file ]; then
    source $source_file;
fi
unset source_file;

