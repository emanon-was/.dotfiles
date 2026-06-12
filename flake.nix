{
  description = "Dotfiles packages and profile artifacts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      dotfilesDispatcherPackage = pkgs.callPackage ./nix/bin/dotfiles { };
      symsyncPackage = pkgs.callPackage ./nix/bin/symsync { };
      dotfilesBin = pkgs.callPackage ./nix/bin {
        inherit dotfilesDispatcherPackage;
        inherit symsyncPackage;
      };
      dotfilesProfile = pkgs.callPackage ./nix {
        dotfilesBinProfilePackage = dotfilesBin.profilePackage;
      };
    in
    {
      packages.${system} = {
        dotfiles = dotfilesDispatcherPackage;
        symsync = symsyncPackage;
        dotfiles-bin = dotfilesBin.package;
        dotfiles-profile = dotfilesProfile;
        default = dotfilesBin.package;
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
            cd ${self.outPath}/nix/bin/dotfiles/src
            go test ./...
            cd ${self.outPath}/nix/bin/symsync/src
            go test ./...
            test -x ${dotfilesProfile}/.local/bin/dotfiles
            test -x ${dotfilesProfile}/.local/bin/dotfiles-configure
            test -x ${dotfilesProfile}/.local/bin/symsync
            test -f ${dotfilesProfile}/.local/share/bash-completion/completions/dotfiles
            test -f ${dotfilesProfile}/.local/share/bash-completion/completions/symsync
            test -f ${dotfilesProfile}/.local/share/zsh/site-functions/_dotfiles
            test -f ${dotfilesProfile}/.local/share/zsh/site-functions/_symsync
            test -f ${dotfilesProfile}/.local/share/dotfiles/.keep
            touch "$out"
          '';
      };

      apps.${system} = {
        dotfiles = {
          type = "app";
          program = "${dotfilesBin.package}/bin/dotfiles";
          meta.description = "Dotfiles management helper";
        };
        default = self.apps.${system}.dotfiles;
      };
    };
}
