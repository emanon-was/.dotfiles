{
  description = "Dotfiles packages and generated artifacts";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager }:
    let
      system = builtins.currentSystem;
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
      dotfilesCpPackage = pkgs.callPackage ./nix/dotfiles-cp { };
      dotfilesLnPackage = pkgs.callPackage ./nix/dotfiles-ln { };
      dotfilesGenerated = pkgs.callPackage ./default.nix {
        inherit dotfilesCpPackage dotfilesLnPackage dotfilesPackage;
      };
    in
    {
      packages.${system} = {
        dotfiles = dotfilesPackage;
        dotfiles-cp = dotfilesCpPackage;
        dotfiles-ln = dotfilesLnPackage;
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
          bashInteractive
          coreutils
          findutils
          git
          go
          gopls
          gnumake
          gnused
          nix
          python3
          python3Packages.pyyaml
          ripgrep
          zellij
        ];
      };

      checks.${system} = {
        dotfiles-tests = pkgs.runCommand "dotfiles-tests"
          {
            nativeBuildInputs = with pkgs; [
              bash
              coreutils
              go
              gnumake
            ];
          }
          ''
            export GOCACHE="$TMPDIR/go-cache"
            export HOME="$TMPDIR/home"
            cd ${self.outPath}/nix/dotfiles/src
            go test ./...
            cd ${self.outPath}/nix/dotfiles-cp/src
            go test ./...
            cd ${self.outPath}/nix/dotfiles-ln/src
            go test ./...
            test -x ${dotfilesGenerated}/.local/bin/dotfiles
            test -x ${dotfilesGenerated}/.local/bin/dotfiles-configure
            test -x ${dotfilesGenerated}/.local/bin/dotfiles-cp
            test -x ${dotfilesGenerated}/.local/bin/dotfiles-ln
            test -f ${dotfilesGenerated}/.local/share/bash-completion/completions/dotfiles
            test -f ${dotfilesGenerated}/.local/share/bash-completion/completions/dotfiles-cp
            test -f ${dotfilesGenerated}/.local/share/bash-completion/completions/dotfiles-ln
            test -f ${dotfilesGenerated}/.local/share/zsh/site-functions/_dotfiles
            test -f ${dotfilesGenerated}/.local/share/zsh/site-functions/_dotfiles-cp
            test -f ${dotfilesGenerated}/.local/share/zsh/site-functions/_dotfiles-ln
            test -f ${dotfilesGenerated}/.local/share/dotfiles/.keep

            mkdir -p "$TMPDIR/build-test/bin" "$TMPDIR/build-test/fixture" "$TMPDIR/build-test/generated"
            mkdir -p "$TMPDIR/build-test/fixture/nested"
            printf 'old\n' > "$TMPDIR/build-test/fixture/nested/file"
            chmod -R a-w "$TMPDIR/build-test/fixture"
            touch "$TMPDIR/build-test/generated/original"
            printf '%s\n' '#!${pkgs.runtimeShell}' 'printf "%s\n" "$TMPDIR/build-test/fixture"' > "$TMPDIR/build-test/bin/nix"
            printf '%s\n' '#!${pkgs.runtimeShell}' \
              'if [ ! -e "$TMPDIR/build-test/moved" ]; then' \
              '  touch "$TMPDIR/build-test/moved"' \
              '  exec ${pkgs.coreutils}/bin/mv "$@"' \
              'fi' \
              'if [ ! -e "$TMPDIR/build-test/failed" ] && [ "$2" = generated ]; then' \
              '  touch "$TMPDIR/build-test/failed"' \
              '  exit 1' \
              'fi' \
              'exec ${pkgs.coreutils}/bin/mv "$@"' > "$TMPDIR/build-test/bin/mv"
            chmod +x "$TMPDIR/build-test/bin/nix" "$TMPDIR/build-test/bin/mv"
            if cd "$TMPDIR/build-test" && PATH="$TMPDIR/build-test/bin:$PATH" make -f ${self.outPath}/Makefile build; then
              printf 'error: make build unexpectedly succeeded when replacement failed\n' >&2
              exit 1
            fi
            test -e "$TMPDIR/build-test/generated/original"
            test -z "$(find "$TMPDIR/build-test" -maxdepth 1 \( -name '.generated.tmp.*' -o -name '.generated.old.*' \) -print -quit)"
            PATH="$TMPDIR/build-test/bin:$PATH" make -f ${self.outPath}/Makefile build
            test ! -e "$TMPDIR/build-test/generated/original"
            printf 'new\n' > "$TMPDIR/build-test/generated/nested/file"
            rm "$TMPDIR/build-test/generated/nested/file"
            rmdir "$TMPDIR/build-test/generated/nested"
            test -z "$(find "$TMPDIR/build-test" -maxdepth 1 \( -name '.generated.tmp.*' -o -name '.generated.old.*' \) -print -quit)"
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
