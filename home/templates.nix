{ dotfilesPackage, ... }:

{
  home.file.".local/share/dotfiles/templates".source = "${dotfilesPackage}/share/dotfiles/templates";
}
