#
# Prompt
#
PS1="\u@\h:\w\$ "

if [ ! -z "$(command -v direnv)" ]; then
    eval "$(direnv hook bash)";
fi
