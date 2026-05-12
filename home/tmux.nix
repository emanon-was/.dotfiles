{
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    extraConfig = builtins.readFile ./config/tmux/tmux.conf;
  };
}
