#
# Prompt
#
PS1="\u@\h:\w\$ "

#
# Share Config
#
source_file=~/.profile;
if [ -e $source_file ]; then
    source $source_file;
fi
unset source_file;

if [ ! -z "$(command -v direnv)" ]; then
    eval "$(direnv hook bash)";
fi
