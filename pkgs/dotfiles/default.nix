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

  sharedRuntimeInputs = [
    bash
    coreutils
    diffutils
    git
    gnugrep
    gnused
    nix
    home-manager.packages.${stdenv.hostPlatform.system}.home-manager
  ];

  doctor = mkDotfilesCommand "dotfiles-doctor" sharedRuntimeInputs ./scripts/dotfiles-doctor.sh;
  switch = mkDotfilesCommand "dotfiles-switch" sharedRuntimeInputs ./scripts/dotfiles-switch.sh;
  check = mkDotfilesCommand "dotfiles-check" sharedRuntimeInputs ./scripts/dotfiles-check.sh;
  update = mkDotfilesCommand "dotfiles-update" (sharedRuntimeInputs ++ [ check ]) ./scripts/dotfiles-update.sh;
  configure = mkDotfilesCommand "dotfiles-configure" sharedRuntimeInputs ./scripts/dotfiles-configure.sh;
  project = mkDotfilesCommand "dotfiles-project" sharedRuntimeInputs ./scripts/dotfiles-project.sh;
  subcommands = [
    doctor
    switch
    check
    update
    configure
    project
  ];
  dispatcher = mkDotfilesCommand "dotfiles" (sharedRuntimeInputs ++ subcommands) ./scripts/dotfiles.sh;
in
symlinkJoin {
  name = "dotfiles";
  paths = [ dispatcher ] ++ subcommands;

  meta = {
    description = "Dotfiles management helper";
    license = lib.licenses.mit;
  };
}
