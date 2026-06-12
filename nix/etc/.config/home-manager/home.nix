{ username, homeDirectory, pkgs, ... }:

{
  # この seed は最小限に保つ。package は Home Manager、file はこの repo の profile 生成で管理する。
  home = {
    inherit username homeDirectory;
    stateVersion = "26.05";

    packages = [
      # shell integration
      pkgs.direnv

      # version control
      pkgs.git

      # search and file inspection
      pkgs.ripgrep # grep
      pkgs.fd # find
      pkgs.bat # cat
      pkgs.eza # ls
      pkgs.dust # du
      pkgs.sd # sed

      # GNU-compatible tool replacements
      pkgs.uutils-coreutils
      pkgs.uutils-findutils
      pkgs.uutils-diffutils

      # build tools
      pkgs.gnumake

      # terminal multiplexers
      pkgs.tmux
      pkgs.screen
      pkgs.zellij

      # editor
      pkgs.emacs-nox
    ];
  };

  programs.home-manager.enable = true;
}
