require_dotfiles_home

skip_doom_sync=0
profile="$DOTFILES_PROFILE"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --skip-doom-sync)
      skip_doom_sync=1
      ;;
    -*)
      fail "unknown option for switch: $1"
      ;;
    *)
      profile="$1"
      ;;
  esac
  shift
done

home-manager -b hm-backup --flake "$DOTFILES_HOME#$profile" switch

if [ "$skip_doom_sync" -eq 0 ]; then
  doom_sync
else
  status "[skip] doom sync"
fi
