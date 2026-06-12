# zsh login shell でも POSIX shell 向けの共通 profile を読む。
[ -r "$HOME/.profile" ] && . "$HOME/.profile"
