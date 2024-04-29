profile () { exit 0; }

load () { if [ -e $1 ]; then source $1; fi }
load ~/.nix-profile/etc/profile.d/nix.sh
load ~/.profile.d/export.sh
load ~/.profile.d/alias.sh

## for WSL
if [ ! -z "$WSL_DISTRO_NAME" ]; then
    source ~/.bashrc
fi
