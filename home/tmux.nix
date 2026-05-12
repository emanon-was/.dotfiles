{
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    extraConfig = builtins.readFile ../store/.tmux.conf;
  };

  home.file.".screenrc".source = ../store/.screenrc;
}
