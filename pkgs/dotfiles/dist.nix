{ runCommand
, coreutils
}:

let
  scripts = [
    "dotfiles"
    "dotfiles-check"
    "dotfiles-configure"
    "dotfiles-doctor"
    "dotfiles-project"
    "dotfiles-switch"
    "dotfiles-update"
  ];

  common = ./scripts/common.sh;
  scriptPath = name: ./scripts/${name}.sh;

  installScript = name: ''
    {
      printf '%s\n' '#!/usr/bin/env bash'
      cat ${common}
      printf '\n'
      cat ${scriptPath name}
    } > "$out/bin/${name}"
    chmod +x "$out/bin/${name}"
  '';
in
runCommand "dotfiles-dist"
{
  nativeBuildInputs = [
    coreutils
  ];
} ''
  mkdir -p "$out/bin" "$out/project-templates" "$out/home-files/.config/doom"

  ${builtins.concatStringsSep "\n" (map installScript scripts)}

  cp -R ${../../project-templates}/. "$out/project-templates"/
  cp ${../../config/tmux/tmux.conf} "$out/home-files/.tmux.conf"
  cp ${../../config/screen/screenrc} "$out/home-files/.screenrc"
  cp ${../../config/doom/config.el} "$out/home-files/.config/doom/config.el"
  cp ${./dist/install.sh} "$out/install.sh"
  chmod +x "$out/install.sh"

  cat > "$out/home-files/.profile" <<'PROFILE'
profile () { exit 0; }

load () { if [ -e "$1" ]; then source "$1"; fi; }
load "$HOME/.nix-profile/etc/profile.d/nix.sh"

export GOPATH="$HOME/.go"
export CARGO_HOME="$HOME/.cargo"
export DOOM_EMACS_HOME="$HOME/.config/emacs"
export XDG_LOCAL_HOME="$HOME/.local"
export DOTFILES_HOME="$HOME/.dotfiles"
export PATH="$GOPATH/bin:$CARGO_HOME/bin:$DOOM_EMACS_HOME/bin:$XDG_LOCAL_HOME/bin:$PATH"

if [ -n "''${WSL_DISTRO_NAME:-}" ]; then
  export GDK_SCALE=2
  export GDK_DPI_SCALE=0.75
fi
PROFILE

  cat > "$out/home-files/.bashrc" <<'BASHRC'
PS1="\u@\h:\w\$ "

if [ -f "$HOME/.profile" ]; then
  source "$HOME/.profile"
fi

alias la='ls -a'
alias ll='ls -la'
alias ps='ps ux'
alias psgrep='ps aux | grep -v grep | grep --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias netstat='netstat -antup'
alias du='du -h'
alias df='df -h'
alias su='su -l'
alias nano='nano -Suwik'
alias emacs='emacs -nw'

if ls --help 2>&1 | grep -q -- --color; then
  alias ls='ls --color=auto -F'
else
  alias ls='ls -FG'
fi

if command -v trash >/dev/null 2>&1; then
  alias rm='trash-put'
fi

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook bash)"
fi
BASHRC

  cat > "$out/home-files/.zshrc" <<'ZSHRC'
if [ -f "$HOME/.profile" ]; then
  source "$HOME/.profile"
fi

autoload colors
colors
PROMPT="%n@%m%# "
RPROMPT="%B%{''${fg[red]}%}[%~]%{''${reset_color}%}%b"

HISTFILE="$HOME/.zsh_history"
HISTSIZE=65535
SAVEHIST=65535
setopt hist_ignore_dups
setopt share_history
setopt complete_aliases

alias la='ls -a'
alias ll='ls -la'
alias ps='ps ux'
alias psgrep='ps aux | grep -v grep | grep --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias netstat='netstat -antup'
alias du='du -h'
alias df='df -h'
alias su='su -l'
alias nano='nano -Suwik'
alias emacs='emacs -nw'

if ls --help 2>&1 | grep -q -- --color; then
  alias ls='ls --color=auto -F'
else
  alias ls='ls -FG'
fi

if command -v trash >/dev/null 2>&1; then
  alias rm='trash-put'
fi

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi
ZSHRC

  if grep -R '/nix/store' "$out"; then
    printf 'error: generated dist contains Nix store paths\n' >&2
    exit 1
  fi
''
