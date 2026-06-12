{
  description = "Dotfiles packages and profile artifacts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      requiredEnv = name:
        let
          value = builtins.getEnv name;
        in
        if value != "" then value else throw "home-manager configuration requires ${name}; run with --impure";
      username = requiredEnv "USER";
      homeDirectory = requiredEnv "HOME";
      dotfilesPackage = pkgs.callPackage ./nix/dotfiles { };
      symsyncPackage = pkgs.callPackage ./nix/symsync { };
      dotfilesGenerated = pkgs.callPackage ./default.nix {
        inherit dotfilesPackage;
        inherit symsyncPackage;
      };
    in
    {
      packages.${system} = {
        dotfiles = dotfilesPackage;
        symsync = symsyncPackage;
        dotfiles-generated = dotfilesGenerated;
        default = dotfilesPackage;
      };

      homeConfigurations.default = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit username homeDirectory;
        };
        modules = [
          ./home.nix
        ];
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          go
          gopls
        ];
      };

      checks.${system} = {
        dotfiles-tests = pkgs.runCommand "dotfiles-tests"
          {
            nativeBuildInputs = with pkgs; [
              bash
              coreutils
              go
              gnugrep
            ];
          }
          ''
            export GOCACHE="$TMPDIR/go-cache"
            export HOME="$TMPDIR/home"
            cd ${self.outPath}/nix/dotfiles/src
            go test ./...
            cd ${self.outPath}/nix/symsync/src
            go test ./...
            test -x ${dotfilesGenerated}/.local/bin/dotfiles
            test -x ${dotfilesGenerated}/.local/bin/dotfiles-configure
            test -x ${dotfilesGenerated}/.local/bin/symsync
            test -f ${dotfilesGenerated}/.local/share/bash-completion/completions/dotfiles
            test -f ${dotfilesGenerated}/.local/share/bash-completion/completions/symsync
            test -f ${dotfilesGenerated}/.local/share/zsh/site-functions/_dotfiles
            test -f ${dotfilesGenerated}/.local/share/zsh/site-functions/_symsync
            test -f ${dotfilesGenerated}/.local/share/dotfiles/.keep
            test -x ${self.outPath}/static/.local/bin/dotfiles-flake
            test -x ${self.outPath}/static/.local/bin/dotfiles-configure-doom
            test -x ${self.outPath}/static/.local/bin/dotfiles-configure-gnome
            touch "$out"
          '';
      };

      apps.${system} = {
        dotfiles = {
          type = "app";
          program = "${dotfilesPackage}/bin/dotfiles";
          meta.description = "Dotfiles management helper";
        };
        default = self.apps.${system}.dotfiles;
      };
    };
}
