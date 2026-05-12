require_dotfiles_home
nix flake update --flake "$DOTFILES_HOME"
dotfiles-check
