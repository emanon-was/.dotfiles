.dotfiles
======================
 
    $ git clone https://github.com/emanon-was/.dotfiles.git $HOME
    $ chmod +x .dotfiles/setup.sh
 
Usage
------
### Install ###
    $ bash(or zsh) ~/.dotfiles/setup.sh install
It will move existing files, create symbolic links.
 
### Restore ###
    $ bash(or zsh) ~/.dotfiles/setup.sh restore
It will remove symbolic links, and then restore the old files.
 
 
Warning
------
setup.sh depends on Bash or Zsh.
 
