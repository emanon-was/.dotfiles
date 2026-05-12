{ pkgs, ... }:

{
  home.packages = [
    pkgs.direnv
    pkgs.git
    pkgs.ripgrep
    pkgs.fd
    pkgs.gnumake
    pkgs.tmux
    pkgs.screen
  ];
}
