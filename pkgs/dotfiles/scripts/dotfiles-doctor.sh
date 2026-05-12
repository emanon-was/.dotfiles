doctor_commands() {
  failed=0

  for cmd in nix home-manager git direnv; do
    if have "$cmd"; then
      ok "$cmd: $(command -v "$cmd")"
    else
      missing "$cmd"
      failed=1
    fi
  done

  if have gsettings; then
    ok "gsettings: $(command -v gsettings)"
  else
    skip "gsettings: not available"
  fi

  return "$failed"
}

doctor_dotfiles_home() {
  if [ -d "$DOTFILES_HOME" ]; then
    ok "DOTFILES_HOME: $DOTFILES_HOME"
  else
    missing "DOTFILES_HOME: $DOTFILES_HOME"
    return 1
  fi

  if [ -f "$DOTFILES_HOME/flake.nix" ]; then
    ok "flake.nix: $DOTFILES_HOME/flake.nix"
  else
    missing "flake.nix: $DOTFILES_HOME/flake.nix"
    return 1
  fi
}

doctor_home_manager() {
  if ! have home-manager; then
    missing "Home Manager command is unavailable"
    return 1
  fi

  if generation="$(home-manager generations 2>/dev/null | sed -n '1p')" && [ -n "$generation" ]; then
    ok "Home Manager current generation: $generation"
  else
    warn "Home Manager generation was not found"
  fi

  if [ -d "$DOTFILES_HOME" ]; then
    ok "Home Manager profile: $DOTFILES_HOME#$DOTFILES_PROFILE"
  fi
}

doctor_flake_inputs() {
  flake_file="$DOTFILES_HOME/flake.nix"
  [ -f "$flake_file" ] || return 1

  nixpkgs_url="$(sed -n 's/.*nixpkgs.url = "\(.*\)";.*/\1/p' "$flake_file" | sed -n '1p')"
  home_manager_url="$(sed -n 's/.*url = "\(github:nix-community\/home-manager\/.*\)";.*/\1/p' "$flake_file" | sed -n '1p')"

  if [ "$nixpkgs_url" = "github:NixOS/nixpkgs/nixos-unstable" ]; then
    ok "home nixpkgs input: $nixpkgs_url"
  elif [ -n "$nixpkgs_url" ]; then
    warn "home nixpkgs input is not nixos-unstable: $nixpkgs_url"
  else
    missing "home nixpkgs input"
    return 1
  fi

  if [ "$home_manager_url" = "github:nix-community/home-manager/master" ]; then
    ok "home-manager input: $home_manager_url"
  elif [ -n "$home_manager_url" ]; then
    warn "home-manager input is not master: $home_manager_url"
  else
    missing "home-manager input"
    return 1
  fi

  status "[info] NixOS system should remain stable outside this Home Manager flake"
}

doctor_doom_checkout() {
  failed=0

  if [ -d "$DOOM_HOME" ]; then
    ok "Doom checkout path: $DOOM_HOME"
  else
    missing "Doom checkout path: $DOOM_HOME"
    return 1
  fi

  if [ -d "$DOOM_HOME/.git" ]; then
    branch="$(git -C "$DOOM_HOME" branch --show-current 2>/dev/null || true)"
    head="$(git -C "$DOOM_HOME" rev-parse --short HEAD 2>/dev/null || true)"
    if [ -n "$branch" ]; then
      ok "Doom checkout git: $branch ${head:-unknown}"
    else
      warn "Doom checkout git is detached: ${head:-unknown}"
    fi
  else
    missing "Doom checkout git metadata: $DOOM_HOME/.git"
    failed=1
  fi

  if doom_installed; then
    ok "Doom executable: $DOOM_BIN"
  else
    missing "Doom executable: $DOOM_BIN"
    failed=1
  fi

  return "$failed"
}

doctor_doom_config() {
  failed=0
  dotfiles_config="$DOTFILES_HOME/home/config/doom/config.el"
  active_config="$HOME/.config/doom/config.el"

  if [ -f "$dotfiles_config" ]; then
    ok "Doom config source: $dotfiles_config"
  else
    missing "Doom config source: $dotfiles_config"
    return 1
  fi

  if [ -L "$active_config" ]; then
    ok "Doom active config symlink: $active_config -> $(readlink "$active_config")"
  elif [ -e "$active_config" ]; then
    warn "Doom active config is not a symlink: $active_config"
  else
    missing "Doom active config: $active_config"
    return 1
  fi

  if cmp -s "$dotfiles_config" "$active_config"; then
    ok "Doom active config matches dotfiles source"
  else
    missing "Doom active config differs from dotfiles source"
    failed=1
  fi

  for file in init.el packages.el; do
    path="$HOME/.config/doom/$file"
    if [ -f "$path" ]; then
      ok "Doom bootstrap file: $path"
    else
      missing "Doom bootstrap file: $path"
      failed=1
    fi
  done

  return "$failed"
}

doctor_straight_repositories() {
  recipes_dir="$DOOM_HOME/.local/straight/repos"
  [ -d "$recipes_dir" ] || {
    skip "straight recipe repositories: $recipes_dir"
    return 0
  }

  for repo in org-elpa melpa nongnu-elpa gnu-elpa-mirror el-get emacsmirror-mirror; do
    repo_path="$recipes_dir/$repo"
    if [ ! -d "$repo_path/.git" ]; then
      skip "straight recipe repository not present: $repo"
      continue
    fi

    branch="$(git -C "$repo_path" branch --show-current 2>/dev/null || true)"
    remote="$(git -C "$repo_path" remote get-url origin 2>/dev/null || true)"
    upstream="$(git -C "$repo_path" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)"

    if [ -z "$branch" ]; then
      warn "straight recipe repository detached: $repo"
    elif [ -z "$upstream" ]; then
      warn "straight recipe repository has no upstream: $repo branch=$branch remote=${remote:-none}"
    else
      ok "straight recipe repository: $repo branch=$branch upstream=$upstream"
    fi
  done
}

failed=0

doctor_commands || failed=1
doctor_dotfiles_home || failed=1
doctor_home_manager || true
doctor_flake_inputs || failed=1
doctor_doom_checkout || failed=1
doctor_doom_config || failed=1
doctor_straight_repositories || true

exit "$failed"
