{ lib
, stdenv
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

  mkDotfilesCommand = name: runtimeInputs: script:
    writeShellApplication {
      inherit name runtimeInputs;
      excludeShellChecks = [ "SC2329" ];
      text = builtins.readFile common + "\n" + builtins.readFile script;
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

  doctor = mkDotfilesCommand "dotfiles-doctor" baseRuntimeInputs ./scripts/dotfiles-doctor.sh;
  flake = mkDotfilesCommand "dotfiles-flake" flakeRuntimeInputs ./scripts/dotfiles-flake.sh;
  configure = mkDotfilesCommand "dotfiles-configure" baseRuntimeInputs ./scripts/dotfiles-configure.sh;
  project = mkDotfilesCommand "dotfiles-project" baseRuntimeInputs ./scripts/dotfiles-project.sh;
  subcommands = [
    doctor
    flake
    configure
    project
  ];
  dispatcher = mkDotfilesCommand "dotfiles" (baseRuntimeInputs ++ subcommands) ./scripts/dotfiles.sh;
in
symlinkJoin {
  name = "dotfiles";
  paths = [ dispatcher ] ++ subcommands;

  meta = {
    description = "Dotfiles management helper";
    license = lib.licenses.mit;
  };
}
