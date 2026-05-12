{ dotfilesPackage, pkgs, ... }:

{
  home.packages = [
    dotfilesPackage
    pkgs.direnv
    pkgs.git
    pkgs.ripgrep
    pkgs.fd
    pkgs.gnumake
    pkgs.tmux
    pkgs.screen
  ];
}
