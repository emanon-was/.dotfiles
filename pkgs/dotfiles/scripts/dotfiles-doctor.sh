doctor_commands() {
  failed=0

  for cmd in git diff cp mkdir; do
    if have "$cmd"; then
      ok "$cmd: $(command -v "$cmd")"
    else
      missing "$cmd"
      failed=1
    fi
  done

  if have direnv; then
    ok "direnv: $(command -v direnv)"
  else
    skip "direnv: not available"
  fi

  if have gsettings; then
    ok "gsettings: $(command -v gsettings)"
  else
    skip "gsettings: not available"
  fi

  if have nix; then
    ok "nix: $(command -v nix)"
  else
    skip "nix: not available; use dotfiles flake doctor for flake checks"
  fi

  return "$failed"
}

doctor_dotfiles_home() {
  failed=0

  if [ -d "$DOTFILES_HOME" ]; then
    ok "DOTFILES_HOME: $DOTFILES_HOME"
  else
    missing "DOTFILES_HOME: $DOTFILES_HOME"
    return 1
  fi

  doom_config="$(doom_config_source)"
  if [ -e "$doom_config" ]; then
    ok "dotfiles path: $doom_config"
  else
    missing "dotfiles path: $doom_config"
    failed=1
  fi

  templates_dir="$(dotfiles_templates_dir)"

  if [ -d "$templates_dir" ]; then
    for path in "$templates_dir/nix" "$templates_dir/docker"; do
      if [ -e "$path" ]; then
        ok "dotfiles path: $path"
      else
        missing "dotfiles path: $path"
        failed=1
      fi
    done
  else
    skip "project templates: $templates_dir"
  fi

  return "$failed"
}

doctor_doom_checkout() {
  failed=0

  if [ -d "$DOOM_HOME" ]; then
    ok "Doom checkout path: $DOOM_HOME"
  else
    skip "Doom checkout path: $DOOM_HOME"
    return 0
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
    warn "Doom checkout git metadata is missing: $DOOM_HOME/.git"
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
  dotfiles_config="$(doom_config_source)"
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
    skip "Doom active config: $active_config"
    return 0
  fi

  if cmp -s "$dotfiles_config" "$active_config"; then
    ok "Doom active config matches dotfiles source"
  else
    missing "Doom active config differs from dotfiles source"
    failed=1
  fi

  doom_dir="$HOME/.config/doom"
  if [ -d "$doom_dir" ]; then
    entry_count="$(find "$doom_dir" -mindepth 1 -maxdepth 1 | wc -l)"
    ok "Doom config directory entries: $entry_count"
  else
    skip "Doom config directory: $doom_dir"
  fi

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
doctor_doom_checkout || failed=1
doctor_doom_config || failed=1
doctor_straight_repositories || true

exit "$failed"
