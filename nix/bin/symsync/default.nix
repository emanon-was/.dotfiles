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
  pname = "symsync";
  version = "0";
  src = srcGo;
  vendorHash = null;
  subPackages = [
    "cmd/symsync"
  ];
  buildFlags = [ "-trimpath" ];
  ldflags = [ "-s" "-w" ];
  nativeBuildInputs = [
    perl
    removeReferencesTo
  ];
  postInstall = ''
    remove-references-to -t ${tzdata} "$out/bin/symsync"
    perl -0pi -e 's#/nix/store/#/usr/share/#g' "$out/bin/symsync"

    install -Dm0644 ${srcCompletions}/bash/symsync "$out/share/bash-completion/completions/symsync"
    install -Dm0644 ${srcCompletions}/zsh/_symsync "$out/share/zsh/site-functions/_symsync"
  '';

  meta = {
    description = "Symlink tree synchronization helper";
    license = lib.licenses.mit;
  };
}
