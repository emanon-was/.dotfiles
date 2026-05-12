# .dotfiles

Home Manager based dotfiles.

NixOS system configuration is expected to stay on a stable NixOS channel.
This Home Manager flake intentionally follows `nixos-unstable` for user packages and tools.

Personal Emacs Lisp notes that are not part of the active Doom Emacs configuration live under `notes/emacs`.

## Setup

```sh
git clone https://github.com/emanon-was/.dotfiles.git "$HOME/.dotfiles"
cd "$HOME/.dotfiles"
nix run .#dotfiles -- doctor
nix run .#dotfiles -- switch
```

`dotfiles switch` runs `home-manager -b hm-backup --flake "$DOTFILES_HOME#nixos" switch` and then runs the Doom configuration step.
Before switching, it moves legacy links such as `~/.bashrc -> ~/.dotfiles/store/.bashrc` to `*.hm-backup`.

If Doom Emacs is not installed yet:

```sh
nix run .#dotfiles -- configure doom install
nix run .#dotfiles -- switch
```

`configure doom install` reuses an existing Doom checkout and config bootstrap files when they are already present, then runs Doom sync.
Before Doom sync/install/upgrade runs, `dotfiles` verifies that the active `~/.config/doom/config.el` matches `config/doom/config.el`; if not, it prints a unified diff and asks you to run `dotfiles switch`.

To switch without running Doom sync:

```sh
nix run .#dotfiles -- switch --skip-doom-sync
```

## Commands

```sh
dotfiles doctor
dotfiles switch [--skip-doom-sync] [profile]
dotfiles check
dotfiles update
dotfiles configure gnome
dotfiles configure doom install
dotfiles configure doom sync
dotfiles configure doom upgrade
dotfiles template copy <nix|docker> [destination]
```
