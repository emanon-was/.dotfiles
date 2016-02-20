if [ -z $_PATH ]; then
    export _PATH=$PATH;
fi

if [ -z $_LD_LIBRARY_PATH ];then
    export _LD_LIBRARY_PATH=$LD_LIBRARY_PATH;
fi

# if [ `uname` = "Linux" ];then
# elif [ `uname` = "Darwin" ];then
# fi

export STOW_PREFIX=/usr/local/stow;
export GIT_SSL_NO_VERIFY=true;

export URL_GITHUB='https://github.com';
export URL_PKGSRC='http://ftp.netbsd.org/pub/pkgsrc/stable/pkgsrc.tar.gz';
export URL_DEBIAN='http://ftp.jp.debian.org/debian';
export URL_STOW='http://ftp.gnu.org/gnu/stow/stow-latest.tar.gz';
export URL_NODEJS='http://nodejs.org/dist/node-latest.tar.gz';
export URL_RUBY='http://ftp.ruby-lang.org/pub/ruby/stable-snapshot.tar.gz';
export URL_LEIN='https://raw.github.com/technomancy/leiningen/stable/bin/lein';
export URL_EMACS='http://ftp.gnu.org/gnu/emacs/emacs-24.5.tar.gz';
export URL_TAKAO_FONTS='https://launchpad.net/takao-fonts/003.02/003.02.01/+download/takao-fonts-ttf-003.02.01.tar.gz'

# Environment pkgsrc
# export SH=/bin/bash;
# export CVS_RSH=ssh;
# export PKGSRC=/usr/pkgsrc;
# export PKGSRC_PREFIX=/usr/pkg;
