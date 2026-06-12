{ runCommand
, coreutils
, dotfilesBinProfilePackage
}:

let
  dotfilesEtc = ./etc;
in
runCommand "dotfiles-profile"
{
  nativeBuildInputs = [
    coreutils
  ];
} ''
  mkdir -p "$out/.local/bin"

  cp -RL ${dotfilesEtc}/. "$out"/
  chmod -R u+w "$out"
  rm -f "$out/.local/bin"/dotfiles*
  mkdir -p "$out/.local/bin"
  cp -RL ${dotfilesBinProfilePackage}/bin/. "$out/.local/bin"/

  mkdir -p "$out/.local/share/dotfiles"
  touch "$out/.local/share/dotfiles/.keep"
  mkdir -p "$out/.local/share/bash-completion/completions"
  mkdir -p "$out/.local/share/zsh/site-functions"
  cp -RL ${dotfilesBinProfilePackage}/share/bash-completion/completions/. "$out/.local/share/bash-completion/completions"/
  cp -RL ${dotfilesBinProfilePackage}/share/zsh/site-functions/. "$out/.local/share/zsh/site-functions"/
  chmod -R u+w "$out"

  if grep -R '/nix/store' "$out"; then
    printf 'error: generated profile contains Nix store paths\n' >&2
    exit 1
  fi
  if grep -R '/home/[[:alnum:]_.-]' "$out"; then
    printf 'error: generated profile contains fixed home paths\n' >&2
    exit 1
  fi
''
