{ runCommand
, coreutils
, homeFiles
, homeSessionVars
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
  mkdir -p "$out/bin" "$out/project-templates" "$out/home/config" "$out/home-files"

  ${builtins.concatStringsSep "\n" (map installScript scripts)}

  cp -R ${../../project-templates}/. "$out/project-templates"/
  cp -R ${../../home/config}/. "$out/home/config"/
  cp -RL ${homeFiles}/. "$out/home-files"/
  chmod -R u+w "$out/home-files"
  cp ${./dist/install.sh} "$out/install.sh"
  chmod +x "$out/install.sh"

  # Home Manager generated files can contain store paths for activation-time
  # helpers and managed shell plugins. The dist payload is meant to be usable
  # without Nix, so keep the generated dotfiles but normalize those references
  # to PATH-based hooks or remove Nix-only environment fragments.
  rm -rf "$out/home-files/.config/environment.d"
  rm -f "$out/home-files/.zshenv"
  sed -i \
    -e '/BASH_COMPLETION_VERSINFO/,/^fi$/d' \
    -e '/\/nix\/store\/.*direnv hook bash/d' \
    "$out/home-files/.bashrc"
  sed -i \
    -e '/^HELPDIR="\/nix\/store\//d' \
    -e '/zsh-autosuggestions\.zsh/d' \
    -e '/zsh-syntax-highlighting\.zsh/d' \
    -e '/\/nix\/store\/.*direnv hook zsh/d' \
    "$out/home-files/.zshrc"
  sed -i \
    -e '/hm-session-vars.sh/d' \
    "$out/home-files/.profile"
  {
    printf '\n# Portable Home Manager session variables.\n'
    grep '^export ' ${homeSessionVars} \
      | grep -v '^export __HM_SESS_VARS_SOURCED=' \
      | grep -v '^export LOCALE_ARCHIVE' \
      | sed -E 's#/home/[^/:"]+#$HOME#g'
  } >> "$out/home-files/.profile"

  if grep -R '/nix/store' "$out"; then
    printf 'error: generated dist contains Nix store paths\n' >&2
    exit 1
  fi
''
