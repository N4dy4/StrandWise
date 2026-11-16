# Source this file from ~/.zshrc or ~/.bashrc (see README "Run with Supabase").
# Makes `flutter run` inside this repo automatically pass the Supabase
# credentials from the gitignored .env file as --dart-define flags.

_STRANDWISE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")/.." && pwd)"

_strandwise_env() {
  # Reads a single KEY=value from .env without sourcing the whole file.
  local line
  line="$(grep -E "^[[:space:]]*$1[[:space:]]*=" "$_STRANDWISE_ROOT/.env" 2>/dev/null | tail -n 1)" || return 0
  line="$(printf '%s' "${line#*=}" | tr -d '[:space:]')"
  line="${line%\"}"; line="${line#\"}"
  line="${line%\'}"; line="${line#\'}"
  printf '%s' "$line"
}

flutter() {
  if [ "$1" = "run" ] && [[ "$PWD/" == "$_STRANDWISE_ROOT/"* ]]; then
    case " $* " in
      *" --dart-define=SUPABASE_URL="*) command flutter "$@"; return ;;
    esac
    local url key
    url="$(_strandwise_env SUPABASE_URL)"
    key="$(_strandwise_env SUPABASE_PUBLISHABLE_KEY)"
    if [ -n "$url" ] && [ -n "$key" ]; then
      shift
      command flutter run \
        --dart-define=SUPABASE_URL="$url" \
        --dart-define=SUPABASE_PUBLISHABLE_KEY="$key" "$@"
      return
    fi
    echo "strandwise: SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY missing in .env; running in local mode." >&2
  fi
  command flutter "$@"
}
