{
  description = "Dotfiles packages and generated artifacts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
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
              gnumake
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

            mkdir -p "$TMPDIR/build-test/bin" "$TMPDIR/build-test/fixture" "$TMPDIR/build-test/generated"
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
