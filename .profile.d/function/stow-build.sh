stow-build-init ()
{
    prefix=/usr/local/stow
    if [ `\id -u` = 0 ];then
        if [ ! -d $prefix ];then
           \mkdir $prefix;
        fi
        \chmod 777 $prefix;
    fi
    if [ -n `command -v sudo` ];then
        if [ ! -d $prefix ];
        then
            \sudo mkdir $prefix;
        fi
        \sudo chmod 777 $prefix;
    fi
    unset prefix;
}

stow-build ()
{
    opt=(`echo $* | awk '{$1="";print}'`);
    current=`pwd`;
    # command
    if [ -z `command -v gcc ` ]\
    || [ -z `command -v make` ];
    then
        \echo "[caution] prepare gcc,make.";
        unset current;return;
    fi

    # prefix
    prefix=/usr/local/stow;
    if [ ! -d $prefix ] || [ ! -w $prefix ];then
        \echo "[caution] permission denied. $prefix";
        unset current prefix;return;
    fi

    # argument
    directory=$current;
    if [ -n $1 ] && [ -d $1 ]; then
        \cd $1;directory=`\pwd`;
    fi

    # phase
    declare compile
    if [ -f $directory/Makefile ]; then
        compile=Makefile;
    fi
    if [ -x $directory/configure ]; then
        compile=configure;
    fi

    # action
    if [ -z $compile ]; then
        \echo "[caution] wrong target. $directory";
        \cd $current;unset current prefix directory compile;return;
    fi


    pkgname=`\basename $directory`;
    if [ $compile = configure ]; then
        ./configure --prefix=$prefix/$pkgname ${opt[*]} && make && make install;
    fi
    if [ $compile = Makefile ]; then
        `\make && \make install --prefix=$prefix/$pkgname ${opt[*]}`;
    fi

    \cd $current;
    unset current prefix directory compile pkgname;
}
