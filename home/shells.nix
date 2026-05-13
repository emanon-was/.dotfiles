{ config, ... }:

let
  home = config.home.homeDirectory;
  promptGit = ''
    __dotfiles_prompt_git() {
      command -v git >/dev/null 2>&1 || return 0
      git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

      branch="$(git branch --show-current 2>/dev/null)"
      if [ -z "$branch" ]; then
        branch="$(git rev-parse --short HEAD 2>/dev/null)"
      fi
      [ -n "$branch" ] || return 0

      dirty=""
      if ! git diff --quiet --ignore-submodules -- 2>/dev/null || ! git diff --cached --quiet --ignore-submodules -- 2>/dev/null; then
        dirty="*"
      fi

      printf ' [git:%s%s]' "$branch" "$dirty"
    }
  '';
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
      ${promptGit}

      __dotfiles_prompt_command() {
        exit_code="$?"
        status=""
        if [ "$exit_code" -ne 0 ]; then
          status=" [exit:$exit_code]"
        fi

        PS1="\[\e[32m\]\u@\h\[\e[0m\] \[\e[34m\]\w\[\e[0m\]\[\e[33m\]$(__dotfiles_prompt_git)\[\e[0m\]\[\e[31m\]$status\[\e[0m\]\n\\$ "
      }
      PROMPT_COMMAND=__dotfiles_prompt_command

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
      ${promptGit}

      setopt prompt_subst
      unset RPROMPT RPS1

      __dotfiles_prompt_precmd() {
        exit_code="$?"
        status=""
        if [ "$exit_code" -ne 0 ]; then
          status=" [exit:$exit_code]"
        fi

        PROMPT="%F{green}%n@%m%f %F{blue}%~%f%F{yellow}$(__dotfiles_prompt_git)%f%F{red}$status%f"$'\n'"%# "
      }
      if [[ " ''${precmd_functions[*]} " != *" __dotfiles_prompt_precmd "* ]]; then
        precmd_functions+=(__dotfiles_prompt_precmd)
      fi

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
