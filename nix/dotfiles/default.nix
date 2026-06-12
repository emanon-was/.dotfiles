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
  pname = "dotfiles";
  version = "0";
  src = srcGo;
  vendorHash = null;
  subPackages = [
    "cmd/dotfiles"
    "cmd/dotfiles-configure"
  ];
  tags = [ "timetzdata" ];
  buildFlags = [ "-trimpath" ];
  ldflags = [ "-s" "-w" ];
  nativeBuildInputs = [
    perl
    removeReferencesTo
  ];
  postInstall = ''
    remove-references-to -t ${tzdata} "$out/bin/dotfiles"
    remove-references-to -t ${tzdata} "$out/bin/dotfiles-configure"
    perl -0pi -e 's#/nix/store/#/usr/share/#g' "$out/bin/dotfiles" "$out/bin/dotfiles-configure"

    install -Dm0644 ${srcCompletions}/bash/dotfiles "$out/share/bash-completion/completions/dotfiles"
    install -Dm0644 ${srcCompletions}/zsh/_dotfiles "$out/share/zsh/site-functions/_dotfiles"
  '';

  meta = {
    description = "Dotfiles management helper";
    license = lib.licenses.mit;
  };
}
