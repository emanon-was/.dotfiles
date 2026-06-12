# This script is composed by nix/bin/default.nix.

DOOM_HOME="${DOOM_HOME:-$HOME/.config/emacs}"
DOOM_BIN="$DOOM_HOME/bin/doom"

usage_doom() {
  cat <<'USAGE'
Usage:
  dotfiles configure doom install
  dotfiles configure doom uninstall
  dotfiles configure doom sync
  dotfiles configure doom upgrade

Description:
  install    Doom Emacs を $DOOM_HOME に clone し、doom install と doom sync を実行します。
  uninstall  $DOOM_HOME の Doom Emacs checkout だけを削除します。$HOME/.config/doom は削除しません。
  sync       既存の Doom Emacs checkout で doom sync を実行します。
  upgrade    既存の Doom Emacs checkout で doom upgrade と doom sync を実行します。
USAGE
}

status() {
  printf '%s\n' "$*"
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

doom_installed() {
  [ -x "$DOOM_BIN" ]
}

directory_empty() {
  [ -d "$1" ] && [ -z "$(find "$1" -mindepth 1 -maxdepth 1 -print -quit)" ]
}

doom_checkout_ready() {
  [ -d "$DOOM_HOME/.git" ] && doom_installed
}

doom_clone() {
  if [ ! -e "$DOOM_HOME" ]; then
    status "[doom] cloning Doom Emacs into $DOOM_HOME"
    git clone --depth 1 https://github.com/doomemacs/doomemacs "$DOOM_HOME"
  elif directory_empty "$DOOM_HOME"; then
    status "[doom] cloning Doom Emacs into empty directory $DOOM_HOME"
    git clone --depth 1 https://github.com/doomemacs/doomemacs "$DOOM_HOME"
  elif doom_checkout_ready; then
    status "[doom] checkout already exists: $DOOM_HOME"
  else
    fail "$DOOM_HOME exists but is not a usable Doom Emacs checkout"
  fi
}

doom_uninstall() {
  if [ ! -e "$DOOM_HOME" ]; then
    status "[doom] checkout is not installed: $DOOM_HOME"
    return 0
  fi

  if [ ! -d "$DOOM_HOME/.git" ]; then
    fail "$DOOM_HOME exists but is not a Doom checkout"
  fi

  if ! doom_installed; then
    fail "$DOOM_HOME exists but Doom executable is missing: $DOOM_BIN"
  fi

  status "[doom] removing Doom Emacs checkout: $DOOM_HOME"
  rm -rf "$DOOM_HOME"
}

doom_sync() {
  if ! doom_installed; then
    fail "Doom Emacs is not installed at $DOOM_HOME. Run: dotfiles configure doom install"
  fi
  doom_sync_raw
}

doom_workdir() {
  if [ -d "${HOME:-}" ]; then
    printf '%s\n' "$HOME"
  else
    printf '%s\n' /tmp
  fi
}

doom_run() {
  workdir="$(doom_workdir)"
  (
    cd "$workdir"
    "$DOOM_BIN" "$@"
  )
}

doom_sync_raw() {
  status "[doom] syncing Doom profile"
  doom_run sync
}

cmd_doom() {
  case "${1:-}" in
    install)
      shift
      [ "$#" -eq 0 ] || fail "unexpected argument for doom install: $1"
      status "[doom] ensuring Doom Emacs checkout"
      doom_clone
      status "[doom] running Doom install"
      doom_run install --force
      doom_sync
      ;;
    uninstall)
      shift
      [ "$#" -eq 0 ] || fail "unexpected argument for doom uninstall: $1"
      doom_uninstall
      ;;
    sync)
      doom_sync
      ;;
    upgrade)
      if ! doom_installed; then
        fail "Doom Emacs is not installed at $DOOM_HOME. Run: dotfiles configure doom install"
      fi
      status "[doom] upgrading Doom Emacs"
      doom_run upgrade --force
      doom_sync
      ;;
    -h|--help|help|"")
      usage_doom
      ;;
    *)
      usage_doom
      exit 2
      ;;
  esac
}

if [ "${DOTFILES_TEST_SOURCE_ONLY:-0}" -eq 1 ]; then
  return 0 2>/dev/null || exit 0
fi

cmd_doom "$@"
