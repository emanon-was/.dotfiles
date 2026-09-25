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
  pname = "dotfiles-cp";
  version = "0";
  src = srcGo;
  vendorHash = null;
  subPackages = [
    "cmd/dotfiles-cp"
  ];
  buildFlags = [ "-trimpath" ];
  ldflags = [ "-s" "-w" ];
  nativeBuildInputs = [
    perl
    removeReferencesTo
  ];
  postInstall = ''
    remove-references-to -t ${tzdata} "$out/bin/dotfiles-cp"
    perl -0pi -e 's#/nix/store/#/usr/share/#g' "$out/bin/dotfiles-cp"

    install -Dm0644 ${srcCompletions}/bash/dotfiles-cp "$out/share/bash-completion/completions/dotfiles-cp"
    install -Dm0644 ${srcCompletions}/zsh/_dotfiles-cp "$out/share/zsh/site-functions/_dotfiles-cp"
  '';

  meta = {
    description = "Copy tree synchronization helper";
    license = lib.licenses.mit;
  };
}
