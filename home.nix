{ username, homeDirectory, nixos-unstable, nixpkgs-master, ... }:

{
  # この seed は最小限に保つ。package は Home Manager、file はこの repo の profile 生成で管理する。
  home = {
    inherit username homeDirectory;
    stateVersion = "26.05";

    packages = with nixos-unstable; [
      # shell integration
      direnv

      # version control
      git

      # search and file inspection
      ripgrep # grep
      fd # find

      # build tools
      gnumake

      # terminal multiplexers
      screen
      tmux
      zellij
      herdr

      # AI coding tools
      nixpkgs-master.codex

      # editor
      neovim
      tree-sitter
      gcc
      curl
      fzf
      lazygit
      shfmt
      stylua
    ] ++ lib.optionals stdenv.hostPlatform.isLinux [
      wl-clipboard
      xclip
    ];
  };

  programs.home-manager.enable = true;
}
