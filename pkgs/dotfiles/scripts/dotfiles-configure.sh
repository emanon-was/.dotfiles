usage_configure() {
  cat <<'USAGE'
Usage:
  dotfiles configure gnome
  dotfiles configure doom install [--check]
  dotfiles configure doom sync
  dotfiles configure doom upgrade
USAGE
}

cmd_doom() {
  case "${1:-}" in
    install)
      shift
      case "${1:-}" in
        --check)
          shift
          [ "$#" -eq 0 ] || fail "unexpected argument for doom install --check: $1"
          doom_install_check
          return
          ;;
        "")
          ;;
        *)
          fail "unknown option for doom install: $1"
          ;;
      esac
      status "[doom] ensuring Doom Emacs checkout"
      doom_clone
      if doom_config_ready; then
        status "[doom] config bootstrap files already exist"
      else
        status "[doom] running Doom install"
        doom_run_with_generated_config_check "$DOOM_BIN" install
      fi
      doom_sync
      ;;
    sync)
      doom_sync
      ;;
    upgrade)
      if ! doom_installed; then
        fail "Doom Emacs is not installed at $DOOM_HOME. Run: dotfiles configure doom install"
      fi
      doom_refresh_recipe_repositories
      status "[doom] upgrading Doom Emacs"
      doom_run_with_generated_config_check "$DOOM_BIN" upgrade
      doom_sync
      ;;
    *)
      usage_configure
      exit 2
      ;;
  esac
}

case "${1:-}" in
  gnome)
    shift
    if [ "$#" -gt 0 ]; then
      usage_configure
      exit 2
    fi
    gnome_configure
    ;;
  doom)
    shift
    cmd_doom "$@"
    ;;
  -h|--help|help|"")
    usage_configure
    ;;
  *)
    usage_configure
    exit 2
    ;;
esac
