#!/usr/bin/env bash

set -euo pipefail

deny_patterns=(
  'rm -rf *'
  '*resolveReviewThread*'
  'aws sso login*'
  'aws configure*'
  '*pr merge*'
)

if [[ $# -eq 1 && $1 == --claude-deny-list ]]; then
  printf '%s\n' "${deny_patterns[@]}" | jq -Rsc 'split("\n")[:-1] | map("Bash(" + . + ")")'
  exit 0
fi

if [[ $# -ne 0 ]]; then
  printf 'Usage: %s [--claude-deny-list]\n' "$0" >&2
  exit 2
fi

if ! command=$(jq -ers '
  if length == 1
    and (.[0] | type) == "object"
    and .[0].tool_name == "Bash"
    and (.[0].tool_input | type) == "object"
    and (.[0].tool_input.command | type) == "string"
  then .[0].tool_input.command
  else error("Expected one Bash hook event with a command string")
  end
' 2>/dev/null); then
  printf 'Deny hook could not validate the Bash command.\n' >&2
  exit 2
fi

for pattern in "${deny_patterns[@]}"; do
  if [[ "$command" == $pattern ]]; then
    printf 'Blocked by deny list: %s\n' "$pattern" >&2
    exit 2
  fi
done
