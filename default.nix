{ runCommand
, coreutils
, dotfilesPackage
, dotfilesCpPackage
, dotfilesLnPackage
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
  cp ${dotfilesCpPackage}/bin/dotfiles-cp "$out/.local/bin/dotfiles-cp"
  cp ${dotfilesLnPackage}/bin/dotfiles-ln "$out/.local/bin/dotfiles-ln"

  mkdir -p "$out/.local/share/bash-completion/completions"
  mkdir -p "$out/.local/share/zsh/site-functions"
  cp ${dotfilesPackage}/share/bash-completion/completions/dotfiles "$out/.local/share/bash-completion/completions/dotfiles"
  cp ${dotfilesCpPackage}/share/bash-completion/completions/dotfiles-cp "$out/.local/share/bash-completion/completions/dotfiles-cp"
  cp ${dotfilesLnPackage}/share/bash-completion/completions/dotfiles-ln "$out/.local/share/bash-completion/completions/dotfiles-ln"
  cp ${dotfilesPackage}/share/zsh/site-functions/_dotfiles "$out/.local/share/zsh/site-functions/_dotfiles"
  cp ${dotfilesCpPackage}/share/zsh/site-functions/_dotfiles-cp "$out/.local/share/zsh/site-functions/_dotfiles-cp"
  cp ${dotfilesLnPackage}/share/zsh/site-functions/_dotfiles-ln "$out/.local/share/zsh/site-functions/_dotfiles-ln"

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
