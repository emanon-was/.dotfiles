{ runCommand
, coreutils
, dotfilesPackage
, symsyncPackage
}:

runCommand "dotfiles-generated"
{
  nativeBuildInputs = [
    coreutils
  ];
} ''
  mkdir -p "$out/.local/bin"
  cp ${dotfilesPackage}/bin/dotfiles "$out/.local/bin/dotfiles"
  cp ${dotfilesPackage}/bin/dotfiles-configure "$out/.local/bin/dotfiles-configure"
  cp ${symsyncPackage}/bin/symsync "$out/.local/bin/symsync"

  mkdir -p "$out/.local/share/bash-completion/completions"
  mkdir -p "$out/.local/share/zsh/site-functions"
  cp ${dotfilesPackage}/share/bash-completion/completions/dotfiles "$out/.local/share/bash-completion/completions/dotfiles"
  cp ${symsyncPackage}/share/bash-completion/completions/symsync "$out/.local/share/bash-completion/completions/symsync"
  cp ${dotfilesPackage}/share/zsh/site-functions/_dotfiles "$out/.local/share/zsh/site-functions/_dotfiles"
  cp ${symsyncPackage}/share/zsh/site-functions/_symsync "$out/.local/share/zsh/site-functions/_symsync"

  mkdir -p "$out/.local/share/dotfiles"
  touch "$out/.local/share/dotfiles/.keep"
  chmod -R u+w "$out"

  if grep -R '/nix/store' "$out"; then
    printf 'error: generated files contain Nix store paths\n' >&2
    exit 1
  fi
  if grep -R '/home/[[:alnum:]_.-]' "$out"; then
    printf 'error: generated files contain fixed home paths\n' >&2
    exit 1
  fi
''
