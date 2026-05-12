{ lib
, stdenv
, runCommand
, symlinkJoin
, writeShellApplication
, bash
, coreutils
, diffutils
, git
, gnugrep
, gnused
, nix
, home-manager
}:

let
  common = ./scripts/common.sh;

  templates = runCommand "dotfiles-templates" { } ''
    mkdir -p "$out/share/dotfiles/templates"
    cp -R ${./templates}/. "$out/share/dotfiles/templates"/
  '';

  mkDotfilesCommand = name: runtimeInputs: script: extraText:
    writeShellApplication {
      inherit name runtimeInputs;
      excludeShellChecks = [ "SC2329" ];
      text = extraText + builtins.readFile common + "\n" + builtins.readFile script;
    };

  baseRuntimeInputs = [
    bash
    coreutils
    diffutils
    git
    gnugrep
    gnused
  ];

  flakeRuntimeInputs = baseRuntimeInputs ++ [
    nix
    home-manager.packages.${stdenv.hostPlatform.system}.home-manager
  ];

  doctor = mkDotfilesCommand "dotfiles-doctor" baseRuntimeInputs ./scripts/dotfiles-doctor.sh "";
  flake = mkDotfilesCommand "dotfiles-flake" flakeRuntimeInputs ./scripts/dotfiles-flake.sh "";
  configure = mkDotfilesCommand "dotfiles-configure" baseRuntimeInputs ./scripts/dotfiles-configure.sh "";
  project = mkDotfilesCommand "dotfiles-project" baseRuntimeInputs ./scripts/dotfiles-project.sh ''
    DOTFILES_BUILT_TEMPLATES="${templates}/share/dotfiles/templates"
  '';
  subcommands = [
    doctor
    flake
    configure
    project
  ];
  dispatcher = mkDotfilesCommand "dotfiles" (baseRuntimeInputs ++ subcommands) ./scripts/dotfiles.sh "";
in
symlinkJoin {
  name = "dotfiles";
  paths = [ dispatcher templates ] ++ subcommands;

  meta = {
    description = "Dotfiles management helper";
    license = lib.licenses.mit;
  };
}
