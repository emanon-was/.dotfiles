{ config, ... }:

let
  home = config.home.homeDirectory;
in
{
  home = {
    sessionVariables = {
      GOPATH = "${home}/.go";
      CARGO_HOME = "${home}/.cargo";
      DOOM_EMACS_HOME = "${home}/.config/emacs";
      XDG_LOCAL_HOME = "${home}/.local";
      DOTFILES_HOME = "${home}/.dotfiles";
    };

    sessionPath = [
      "${home}/.go/bin"
      "${home}/.cargo/bin"
      "${home}/.config/emacs/bin"
      "${home}/.local/bin"
    ];

    shellAliases = {
      la = "ls -a";
      ll = "ls -la";
      ps = "ps ux";
      psgrep = "ps aux | grep -v grep | grep --color=auto";
      grep = "grep --color=auto";
      fgrep = "fgrep --color=auto";
      egrep = "egrep --color=auto";
      netstat = "netstat -antup";
      du = "du -h";
      df = "df -h";
      su = "su -l";
      nano = "nano -Suwik";
      emacs = "emacs -nw";
    };
  };

  programs.bash = {
    enable = true;
    initExtra = ''
      PS1="\u@\h:\w\$ "

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

      if [ -n "''${WSL_DISTRO_NAME:-}" ]; then
        export GDK_SCALE=2
        export GDK_DPI_SCALE=0.75
      fi
    '';
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      path = "${home}/.zsh_history";
      size = 65535;
      save = 65535;
      ignoreDups = true;
      share = true;
    };
    initContent = ''
      autoload colors
      colors
      PROMPT="%n@%m%# "
      RPROMPT="%B%{''${fg[red]}%}[%~]%{''${reset_color}%}%b"

      setopt complete_aliases

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

      if [ -n "''${WSL_DISTRO_NAME:-}" ]; then
        export GDK_SCALE=2
        export GDK_DPI_SCALE=0.75
      fi
    '';
  };

  programs.direnv.enable = true;
}
