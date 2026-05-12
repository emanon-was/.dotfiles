{ runCommand
, coreutils
}:

let
  scripts = [
    "dotfiles"
    "dotfiles-check"
    "dotfiles-configure"
    "dotfiles-doctor"
    "dotfiles-project"
    "dotfiles-switch"
    "dotfiles-update"
  ];

  common = ./scripts/common.sh;
  scriptPath = name: ./scripts/${name}.sh;

  installScript = name: ''
    {
      printf '%s\n' '#!/usr/bin/env bash'
      cat ${common}
      printf '\n'
      cat ${scriptPath name}
    } > "$out/bin/${name}"
    chmod +x "$out/bin/${name}"
  '';
in
runCommand "dotfiles-dist"
{
  nativeBuildInputs = [
    coreutils
  ];
} ''
  mkdir -p "$out/bin" "$out/project-templates"

  ${builtins.concatStringsSep "\n" (map installScript scripts)}

  cp -R ${../../project-templates}/. "$out/project-templates"/
  cp ${./dist/install.sh} "$out/install.sh"
  chmod +x "$out/install.sh"

  if grep -R '/nix/store' "$out"; then
    printf 'error: generated dist contains Nix store paths\n' >&2
    exit 1
  fi
''
