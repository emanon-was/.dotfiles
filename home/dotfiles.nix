{ dotfilesPackage, ... }:

{
  home.file.".local/bin" = {
    source = "${dotfilesPackage}/bin";
    recursive = true;
  };

  home.file.".local/share/dotfiles/templates" = {
    source = "${dotfilesPackage}/share/dotfiles/templates";
    recursive = true;
  };
}
