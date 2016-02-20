source-safe() { if [ -e $1 ]; then source $1; fi }

source-profiles ()
{
    for P in $@; do
        if [ -n "$P" -a -e $P ]; then
            if   [ -f $P ]; then
                source-safe $P;
            elif [ -d $P ]; then
                D=$P; if [ -L $P ]; then D=`readlink $P`; fi
                for F in `find $D -name "*.sh"`; do source-safe $F; done
            fi
        fi
    done
}

source-profiles ~/.profile.d ~/.nix-profile/etc/profile.d/nix.sh

auto-ssh-agent;
auto-ssh-add;

