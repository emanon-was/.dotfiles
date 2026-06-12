{ username, homeDirectory, pkgs, ... }:

{
  # この seed は最小限に保つ。package は Home Manager、file はこの repo の profile 生成で管理する。
  home = {
    inherit username homeDirectory;
    stateVersion = "25.11";

    packages = [
      pkgs.direnv
      pkgs.git
      pkgs.ripgrep
      pkgs.fd
      pkgs.gnumake
      pkgs.tmux
      pkgs.screen
      pkgs.emacs-nox
    ];
  };

  programs.home-manager.enable = true;
}
