#!/bin/bash

oldfiles=~/.dotfiles.old;
ignore=(.git .svn .DS_Store README);


#
# Common functions , variables
#

script=`basename $0`;
dotfiles=`dirname $0`;
dotfiles=`cd $dotfiles;pwd`;

filter ()
{
    declare opt
    for f in ${ignore[@]};do
        opt=(${opt[@]} -e $f);
    done
    if [ -e $1 ];then
        echo `ls -a $1\
              |grep -v ${script}\
              |grep -v ${opt[@]}\
              |grep -v '^\.\+$'`
    fi
    unset opt f;
}

filetype()
{
    if   [ -L $1 ]; then
        echo "link";
    elif [ -f $1 ]; then
        echo "file";
    elif [ -d $1 ]; then
        echo "dir";
    else
        echo "none";
    fi
}

pattern ()
{
    case $1 in
        "message")  # message
            echo " message  : $2";;
        "conflict") # path
            echo " conflict : $2";;
        "ignore")   # path
            echo " ignore   : $2";;
        "command")  # command
            echo " command  : $2";
            eval $2;;
        "mkdir")    # path
            if [ ! -d $2 ] ; then
                pattern "command" "mkdir -p $2";
            fi;;
        "rmdir")    # path
            if [ -d $2 ] ; then
                pattern "command" "rm -rf $2";
            fi;;
    esac
}

#
#  Install function
#
install ()
{
    dotp=$dotfiles;
    oldp=$oldfiles;
    dots=(`filter $dotp`);
    for filename in ${dots[@]};
    do
        dot="$dotp/$filename";
        home="$HOME/$filename";
        homet=`filetype $home`;
        echo "[$filename]";
        if [ "link" = $homet ] && [ $dot -ef $home ] ; then
            pattern "ignore"  "$home($homet)";
            continue;
        fi
        if [ "none" != $homet ]; then
            pattern "conflict" "$home($homet)";
            pattern "mkdir"    "$oldp";
            pattern "command"  "mv -f $home $oldp";
        fi
        pattern "command"  "ln -s $dot $HOME";
    done

    unset dot  dots dotp oldp home homet;
}

#
#  Restore function
#
restore ()
{
    dotp=$dotfiles;
    oldp=$oldfiles;
    dots=(`filter $dotp`);
    for filename in ${dots[@]};
    do
        dot="$dotp/$filename";
        home="$HOME/$filename";
        homet=`filetype $old`;
        if [ $homet = "link" ] && [ $dot -ef $home ]; then
            pattern "command" "rm -f $home";
        fi
    done
    if [ -d $oldp ]; then
        olds=(`filter $oldp`);
        for filename in ${olds};
        do
            home="$HOME/$filename";
            homet=`filetype $home`;
            old="$oldp/$filename";
            oldt=`filetype $old`;
            if [ "none" = $homet ]; then
                pattern "command"  "mv $old $HOME";
            else
                pattern "conflict" "$home($homet)";
                if [ "none" != `filetype "$home~"` ] ; then
                    pattern "conflict" "$home~(backup)";
                    pattern "command"  "rm -rf $home~";
                fi
                pattern "command"  "mv $old $home~";
            fi
        done
        pattern "rmdir" $oldp;
    fi
    unset dot  dots  dotp;
    unset old  olds  oldp  oldt;
    unset home homes homep homet;
}

#
#  Gnome functions
#
gnome-set ()
{
    gsettings set org.gnome.desktop.interface gtk-key-theme "Emacs"
    gsettings set org.gnome.desktop.interface document-font-name "Sans 11"
    gsettings set org.gnome.desktop.interface font-name "Sans-serif 10"
    gsettings set org.gnome.desktop.interface monospace-font-name "Monospace 11"
    gconftool-2 --type bool   --set /apps/gnome-terminal/profiles/Default/use_system_font false
    gconftool-2 --type string --set /apps/gnome-terminal/profiles/Default/font "Ricty 14"
}

gnome-reset ()
{
    gsettings set org.gnome.desktop.interface gtk-key-theme "Default"
    gconftool-2 --type bool   --set /apps/gnome-terminal/profiles/Default/use_system_font true
    gconftool-2 --type string --set /apps/gnome-terminal/profiles/Default/font "Monospace 12"
}

#
# Help function
#
help ()
{
    cat <<EOF

 example)

   [install]
   $ cd ~/.dotfiles
   $ bash setup.sh install

   [restore]
   $ cd ~/.dotfiles
   $ bash setup.sh restore

   [gnome]
   $ cd ~/.dotfiles
   $ bash setup.sh gnome [set|reset]

   [help]
   $ cd ~/.dotfiles
   $ bash setup.sh help


EOF
}


gnome()
{
    case $1 in
        "set")
            gnome-set;;
        "reset")
            gnome-reset;;
        *)
            help;;
    esac
}

#
# Main
#
case $1 in
    "install")
        install;;
    "restore")
        restore;;
    "gnome")
        gnome $2;;
    "help")
        help;;
    *)
        help;;
esac

unset oldfiles ignore script dotfiles;
