bashrc () { exit 0; }

#
# Prompt
#
PS1="\u@\h:\w\$ "

if [ -z "$(command -v profile)" ]; then
    source ~/.profile
fi

if [ ! -z "$(command -v direnv)" ]; then
    eval "$(direnv hook bash)";
fi
