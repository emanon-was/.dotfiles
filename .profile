load() { if [ -e $1 ]; then source $1; fi }

load ~/.nix-profile/etc/profile.d/nix.sh
load ~/.profile.d/export.sh
load ~/.profile.d/alias.sh


