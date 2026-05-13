{ lib
, stdenv
, runCommand
, symlinkJoin
, writeShellApplication
, bash
, coreutils
, git
, gnugrep
, gnused
, nix
, home-manager
}:

let
  common = ./scripts/lib/common.sh;

  templates = runCommand "dotfiles-templates" { } ''
    mkdir -p "$out/share/dotfiles/templates"
    cp -R ${./templates}/. "$out/share/dotfiles/templates"/
  '';

  homeFiles = runCommand "dotfiles-home-files" { } ''
    mkdir -p "$out/share/dotfiles/home-files/.config/doom"
    cp -R ${../../home/config/doom}/. "$out/share/dotfiles/home-files/.config/doom"/
  '';

  baseRuntimeInputs = [
    bash
    coreutils
    git
    gnugrep
    gnused
  ];

  flakeRuntimeInputs = baseRuntimeInputs ++ [
    nix
    home-manager.packages.${stdenv.hostPlatform.system}.home-manager
  ];

  commandText = command:
    (command.nixExtraText or "")
    + builtins.readFile common
    + "\n"
    + builtins.concatStringsSep "\n" (map builtins.readFile (command.libs or [ ]))
    + "\n"
    + builtins.readFile command.script;

  portableCommandSource = command:
    builtins.toFile "${command.name}-portable" (
      "#!/usr/bin/env bash\n"
      + "DOTFILES_PORTABLE_DIST=1\n"
      + (command.portableExtraText or "")
      + builtins.readFile common
      + "\n"
      + builtins.concatStringsSep "\n" (map builtins.readFile (command.libs or [ ]))
      + "\n"
      + builtins.readFile command.script
    );

  mkDotfilesCommand = command:
    writeShellApplication {
      inherit (command) name runtimeInputs;
      excludeShellChecks = [ "SC2317" "SC2329" ];
      text = commandText command;
    };

  commandDefinitions = [
    {
      name = "dotfiles-flake";
      runtimeInputs = flakeRuntimeInputs;
      script = ./scripts/dotfiles-flake.sh;
    }
    {
      name = "dotfiles-configure";
      runtimeInputs = baseRuntimeInputs;
      libs = [
        ./scripts/lib/doom.sh
      ];
      nixExtraText = ''
        DOTFILES_BUILT_HOME_FILES="${homeFiles}/share/dotfiles/home-files"
      '';
      script = ./scripts/dotfiles-configure.sh;
    }
    {
      name = "dotfiles-project";
      runtimeInputs = baseRuntimeInputs;
      libs = [
        ./scripts/lib/templates.sh
      ];
      script = ./scripts/dotfiles-project.sh;
      nixExtraText = ''
        DOTFILES_BUILT_HOME_FILES="${homeFiles}/share/dotfiles/home-files"
        DOTFILES_BUILT_TEMPLATES="${templates}/share/dotfiles/templates"
      '';
    }
  ];

  subcommands = map mkDotfilesCommand commandDefinitions;
  dispatcherCommand = {
    name = "dotfiles";
    runtimeInputs = baseRuntimeInputs ++ subcommands;
    script = ./scripts/dotfiles.sh;
  };
  dispatcher = mkDotfilesCommand dispatcherCommand;

  portableCommandDefinitions = [ dispatcherCommand ] ++ commandDefinitions;
  portableCommands = runCommand "dotfiles-portable-commands" { } ''
    mkdir -p "$out/share/dotfiles/portable-bin"
    ${builtins.concatStringsSep "\n" (map (command: ''
      cp ${portableCommandSource command} "$out/share/dotfiles/portable-bin/${command.name}"
      chmod +x "$out/share/dotfiles/portable-bin/${command.name}"
    '') portableCommandDefinitions)}
  '';
in
symlinkJoin {
  name = "dotfiles";
  paths = [ dispatcher templates homeFiles portableCommands ] ++ subcommands;

  meta = {
    description = "Dotfiles management helper";
    license = lib.licenses.mit;
  };
}
