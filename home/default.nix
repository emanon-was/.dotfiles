{ username, homeDirectory, ... }:

{
  imports = [
    ./packages.nix
    ./shells.nix
    ./git.nix
    ./tmux.nix
    ./screen.nix
    ./emacs.nix
    ./gnome.nix
  ];

  home = {
    inherit username homeDirectory;
    stateVersion = "25.11";
  };

  programs.home-manager.enable = true;
}
