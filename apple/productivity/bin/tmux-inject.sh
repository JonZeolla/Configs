#!/usr/bin/env bash
set -euo pipefail

PANES=0
FORCE_PANES=0
DRY_RUN=0

usage() {
  cat <<'EOF'
tmux-aws-inject: inject AWS creds from CURRENT SHELL into tmux

It expects these to already be set in your current shell:
  AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY
  AWS_SESSION_TOKEN

USAGE:
  tmux-aws-inject
  tmux-aws-inject --panes
  tmux-aws-inject --force-panes
  tmux-aws-inject --dry-run

NOTES:
  - Without --panes: updates tmux server env only (new panes/windows inherit).
  - With --panes: types `export ...` into existing panes (bash/zsh/sh by default).
EOF
}

for a in "$@"; do
  case "$a" in
  --panes) PANES=1 ;;
  --force-panes)
    FORCE_PANES=1
    PANES=1
    ;;
  --dry-run) DRY_RUN=1 ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown arg: $a" >&2
    usage
    exit 2
    ;;
  esac
done

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

require_tmux() {
  command -v tmux >/dev/null 2>&1 || {
    echo "tmux not found." >&2
    exit 1
  }
  tmux list-sessions >/dev/null 2>&1 || {
    echo "No running tmux server/sessions found." >&2
    exit 1
  }
}

REQUIRED_VARS=(AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN)
OPTIONAL_VARS=(
  ANTHROPIC_AUTH_TOKEN
  ANTHROPIC_BASE_URL
  ANTHROPIC_MODEL
  ANTHROPIC_DEFAULT_SONNET_MODEL
  ANTHROPIC_DEFAULT_HAIKU_MODEL
  ANTHROPIC_DEFAULT_OPUS_MODEL
  ANTHROPIC_CUSTOM_HEADERS
)

# Verify required vars exist in current shell
missing=()
for v in "${REQUIRED_VARS[@]}"; do
  [[ -n "${!v-}" ]] || missing+=("$v")
done
if [[ "${#missing[@]}" -gt 0 ]]; then
  echo "Missing env vars in current shell: ${missing[*]}" >&2
  echo "Set them first, then run: tmux-aws-inject" >&2
  exit 1
fi

# Collect optional vars that are set
ACTIVE_OPTIONAL=()
for v in "${OPTIONAL_VARS[@]}"; do
  [[ -n "${!v-}" ]] && ACTIVE_OPTIONAL+=("$v")
done

VARS=("${REQUIRED_VARS[@]}" "${ACTIVE_OPTIONAL[@]}")

require_tmux

# Inject into tmux server env (global)
for v in "${VARS[@]}"; do
  run tmux set-environment -g "$v" "${!v}"
done

# Ensure attach/new windows can pull these too
current="$(tmux show-option -gv update-environment 2>/dev/null || true)"
new="$current"
for v in "${VARS[@]}"; do
  [[ " $current " == *" $v "* ]] || new="${new} ${v}"
done
new="${new#"${new%%[![:space:]]*}"}"
new="${new%"${new##*[![:space:]]}"}"
run tmux set-option -g update-environment "$new"

# Optional: push into existing panes (best-effort)
if [[ "$PANES" -eq 1 ]]; then
  export_cmd=""
  for v in "${VARS[@]}"; do
    export_cmd+="export ${v}=$(printf %q "${!v}"); "
  done
  export_cmd="${export_cmd%; }"

  tmux list-panes -a -F '#{pane_id} #{pane_current_command}' | while IFS= read -r pane_id cmd; do
    if [[ "$FORCE_PANES" -eq 1 ]]; then
      run tmux send-keys -t "$pane_id" "$export_cmd" C-m
    else
      case "$cmd" in
      bash | zsh | sh) run tmux send-keys -t "$pane_id" "$export_cmd" C-m ;;
      *) : ;; # skip non-shell panes
      esac
    fi
  done
fi

injected="${VARS[*]}"
echo "Injected ${injected} into tmux (and panes: $PANES)."
