{ username, homeDirectory, ... }:

{
  imports = [
    ./packages.nix
    ./shells.nix
    ./git.nix
    ./tmux.nix
    ./emacs.nix
    ./gnome.nix
  ];

  home = {
    inherit username homeDirectory;
    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;
}
