{ username, homeDirectory, dotfilesPackage, ... }:

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

  home.file.".local/share/dotfiles/templates".source = "${dotfilesPackage}/share/dotfiles/templates";

  programs.home-manager.enable = true;
}
