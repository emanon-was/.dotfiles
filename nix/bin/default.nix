{ lib
, runCommand
, symlinkJoin
, writeShellApplication
, bash
, coreutils
, git
, gnugrep
, gnused
, dotfilesDispatcherPackage
, symsyncPackage
}:

let
  scriptsSrc = ./scripts;

  commonScriptRuntimeInputs = [
    bash
    coreutils
    git
    gnugrep
    gnused
  ];

  scriptFileNames = builtins.attrNames (lib.filterAttrs
    (name: type: type == "regular" && lib.hasSuffix ".sh" name)
    (builtins.readDir scriptsSrc));

  scriptNameFromFile = scriptFileName:
    lib.removeSuffix ".sh" scriptFileName;

  mkScriptDefinition = scriptFileName:
    let
      name = scriptNameFromFile scriptFileName;
    in
    {
      inherit name;
      runtimeInputs = commonScriptRuntimeInputs;
      script = scriptsSrc + "/${scriptFileName}";
    };

  scriptDefinitions = map mkScriptDefinition scriptFileNames;

  scriptText = script:
    builtins.readFile script.script;

  profileScriptSource = script:
    builtins.toFile "${script.name}-profile" (
      "#!/usr/bin/env bash\n"
      + builtins.readFile script.script
    );

  mkNixScriptPackage = script:
    writeShellApplication {
      inherit (script) name runtimeInputs;
      excludeShellChecks = [ "SC2317" "SC2329" ];
      text = scriptText script;
    };

  nixScriptPackages = map mkNixScriptPackage scriptDefinitions;

  nixPackage = symlinkJoin {
    name = "dotfiles-bin";
    paths = [ dotfilesDispatcherPackage symsyncPackage ] ++ nixScriptPackages;
  };

  profileScriptsPackage = runCommand "dotfiles-profile-scripts" { } ''
    mkdir -p "$out/bin"
    ${builtins.concatStringsSep "\n" (map (script: ''
      cp ${profileScriptSource script} "$out/bin/${script.name}"
      chmod +x "$out/bin/${script.name}"
    '') scriptDefinitions)}
  '';

  profilePackage = symlinkJoin {
    name = "dotfiles-profile-bin";
    paths = [
      dotfilesDispatcherPackage
      symsyncPackage
      profileScriptsPackage
    ];
  };

in
{
  package = nixPackage;
  inherit profilePackage;
}
