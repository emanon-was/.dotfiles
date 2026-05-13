usage_project() {
  cat <<'USAGE'
Usage:
  dotfiles project init <nix|docker> [destination]
USAGE
}

ensure_project_destination_clear() {
  source_dir="$1"
  destination_dir="$2"

  find "$source_dir" -mindepth 1 -print | while IFS= read -r source_path; do
    relative_path="${source_path#"$source_dir/"}"
    target_path="$destination_dir/$relative_path"

    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
      fail "project init would overwrite existing path: $target_path"
    fi
  done
}

case "${1:-}" in
  init)
    template="${2:-}"
    destination="${3:-.}"
    [ -n "$template" ] || fail "project template name is required"
    [ "$#" -le 3 ] || fail "unexpected argument for project init: $4"
    templates_dir="$(dotfiles_templates_dir)"
    source="$templates_dir/$template"
    [ -d "$source" ] || fail "unknown project template: $template"
    ensure_project_destination_clear "$source" "$destination"
    mkdir -p "$destination"
    cp -R "$source"/. "$destination"/
    ;;
  -h|--help|help|"")
    usage_project
    ;;
  *)
    usage_project
    exit 2
    ;;
esac
