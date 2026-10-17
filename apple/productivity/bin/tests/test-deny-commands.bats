#!/usr/bin/env bats

setup() {
  SCRIPT_PATH="${BATS_TEST_DIRNAME}/../deny_commands.sh"
  SETUP_PATH="${BATS_TEST_DIRNAME}/../../setup.sh"
}

check_command() {
  local payload
  payload=$(jq -nc --arg command "$1" '{tool_name: "Bash", tool_input: {command: $command}}')
  run bash "$SCRIPT_PATH" <<<"$payload"
}

hook_registration() {
  local registration
  registration=$(sed -n '/^deny_hook_command=/,/^$/p' "$SETUP_PATH")
  registration="${registration//~\/.codex\/config.toml/\"\$1\"}"
  bash -c "$registration" register-deny-hook "$1"
}

@test "blocks recursive force deletion" {
  check_command 'rm -rf /tmp/example'
  [ "$status" -eq 2 ]
  [[ "$output" == 'Blocked by deny list:'* ]]
}

@test "blocks resolving review threads inside a GraphQL command" {
  check_command "gh api graphql -f query='mutation { resolveReviewThread(input: {}) { thread { id } } }'"
  [ "$status" -eq 2 ]
}

@test "blocks AWS SSO login" {
  check_command 'aws sso login --profile example'
  [ "$status" -eq 2 ]
}

@test "blocks AWS configuration" {
  check_command 'aws configure set region us-east-1'
  [ "$status" -eq 2 ]
}

@test "blocks pull request merges inside a compound command" {
  check_command 'git status && gh pr merge 123 --squash'
  [ "$status" -eq 2 ]
}

@test "allows ordinary commands and nearby operations" {
  for command in 'git status --short' 'gh pr view 123' 'aws sts get-caller-identity' 'aws sso logout' 'rm -r /tmp/example' 'printf "hello"'; do
    check_command "$command"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
  done
}

@test "blocks malformed, missing, non-string, and multiple input events" {
  for payload in '' 'invalid' '[]' '{}' '{"tool_name":"Bash","tool_input":null}' '{"tool_name":"Bash","tool_input":{"command":42}}' '{"tool_name":"Other","tool_input":{"command":"git status"}}' '{"tool_name":"Bash","tool_input":{"command":"git status"}} {}'; do
    run bash "$SCRIPT_PATH" <<<"$payload"
    [ "$status" -eq 2 ]
    [[ "$output" == 'Deny hook could not validate'* ]]
  done
}

@test "exports the shared patterns in Claude permission syntax" {
  run bash "$SCRIPT_PATH" --claude-deny-list
  [ "$status" -eq 0 ]
  [[ "$output" == '["Bash(rm -rf *)","Bash(*resolveReviewThread*)","Bash(aws sso login*)","Bash(aws configure*)","Bash(*pr merge*)"]' ]]
}

@test "setup merges shared Claude denies without dropping local entries or settings" {
  local settings="${BATS_TEST_TMPDIR}/settings.json"
  printf '%s\n' '{"local":true,"permissions":{"allow":["Read"],"deny":["Bash(local-command*)","Bash(rm -rf *)"]}}' >"$settings"
  local registration
  registration=$(sed -n '/^jq --arg cmd /,/^$/p' "$SETUP_PATH")
  registration="${registration//~\/.claude\/settings.json/\"\$1\"}"
  export agent_deny_list
  agent_deny_list=$(bash "$SCRIPT_PATH" --claude-deny-list)
  run bash -c "$registration" merge-claude-denies "$settings"
  [ "$status" -eq 0 ]
  local first
  first=$(cat "$settings")
  run bash -c "$registration" merge-claude-denies "$settings"
  [ "$status" -eq 0 ]
  [ "$(cat "$settings")" = "$first" ]
  [ "$(jq '.local' "$settings")" = true ]
  [ "$(jq -r '.permissions.allow[0]' "$settings")" = Read ]
  [ "$(jq '.permissions.deny | length' "$settings")" -eq 6 ]
  [ "$(jq '.permissions.deny | index("Bash(local-command*)") != null' "$settings")" = true ]
}

@test "rejects unsupported arguments" {
  run bash "$SCRIPT_PATH" --unknown
  [ "$status" -eq 2 ]
  [[ "$output" == Usage:* ]]
}

@test "setup registers the hook with empty Codex configuration" {
  local config="${BATS_TEST_TMPDIR}/config.toml"
  touch "$config"
  run hook_registration "$config"
  [ "$status" -eq 0 ]
  [ "$(yq -p=toml '.features.hooks' "$config")" = true ]
  [ "$(yq -p=toml '.hooks.PreToolUse | length' "$config")" -eq 1 ]
  [ "$(yq -p=toml '.hooks.PreToolUse[0].matcher' "$config")" = '^Bash$' ]
  [ "$(yq -p=toml '.hooks.PreToolUse[0].hooks[0].command' "$config")" = "\"$HOME/bin/deny_commands.sh\"" ]
}

@test "setup preserves existing hooks, trust records, settings, and order on rerun" {
  local config="${BATS_TEST_TMPDIR}/config.toml"
  cat >"$config" <<'TOML'
model = "example"

[[hooks.PreToolUse]]
matcher = "*"

[[hooks.PreToolUse.hooks]]
type = "command"
command = "sidepulse hook"

[[hooks.PostToolUse]]

[[hooks.PostToolUse.hooks]]
type = "command"
command = "zenable hook"

[hooks.state.existing]
enabled = true
trusted_hash = "example"
TOML
  run hook_registration "$config"
  [ "$status" -eq 0 ]
  local first
  first=$(cat "$config")
  run hook_registration "$config"
  [ "$status" -eq 0 ]
  [ "$(cat "$config")" = "$first" ]
  [ "$(yq -p=toml '.model' "$config")" = example ]
  [ "$(yq -p=toml '.hooks.PreToolUse | length' "$config")" -eq 2 ]
  [ "$(yq -p=toml '.hooks.PreToolUse[0].hooks[0].command' "$config")" = 'sidepulse hook' ]
  [ "$(yq -p=toml '.hooks.PostToolUse[0].hooks[0].command' "$config")" = 'zenable hook' ]
  [ "$(yq -p=toml '.hooks.state.existing.trusted_hash' "$config")" = example ]
}
