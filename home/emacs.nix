{ pkgs, ... }:

{
  programs.emacs = {
    enable = true;
    package = pkgs.emacs;
  };

  home.packages = with pkgs; [
    # Doom Emacs commonly shells out to these tools.
    git
    ripgrep
    fd
  ];

  home.file.".config/doom/config.el".source = ../config/doom/config.el;
}
