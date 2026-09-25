{ lib
, buildGoModule
, removeReferencesTo
, perl
, tzdata
}:

let
  srcGo = ./src;
  srcCompletions = ./completions;
in
buildGoModule {
  pname = "dotfiles-ln";
  version = "0";
  src = srcGo;
  vendorHash = null;
  subPackages = [
    "cmd/dotfiles-ln"
  ];
  buildFlags = [ "-trimpath" ];
  ldflags = [ "-s" "-w" ];
  nativeBuildInputs = [
    perl
    removeReferencesTo
  ];
  postInstall = ''
    remove-references-to -t ${tzdata} "$out/bin/dotfiles-ln"
    perl -0pi -e 's#/nix/store/#/usr/share/#g' "$out/bin/dotfiles-ln"

    install -Dm0644 ${srcCompletions}/bash/dotfiles-ln "$out/share/bash-completion/completions/dotfiles-ln"
    install -Dm0644 ${srcCompletions}/zsh/_dotfiles-ln "$out/share/zsh/site-functions/_dotfiles-ln"
  '';

  meta = {
    description = "Symlink tree synchronization helper";
    license = lib.licenses.mit;
  };
}
