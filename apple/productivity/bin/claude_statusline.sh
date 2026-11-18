#!/usr/bin/env bash
# Claude Code status line. Managed in jonzeolla/configs; setup.sh installs it to ~/.claude/statusline.sh.
# Renders: [Model] dir  branch  ctx N%  $cost
# No PR here: Claude Code prints its own clickable "PR #N" under this line.

input="$(cat)"

# One jq pass; @tsv keeps paths-with-spaces intact under IFS=tab.
IFS=$'\t' read -r model cwd ctx cost < <(
  printf '%s' "$input" | jq -r '
    [ (.model.display_name // "?"),
      (.workspace.current_dir // "."),
      (.context_window.used_percentage // 0 | floor),
      (.cost.total_cost_usd // 0)
    ] | @tsv'
)

dir="${cwd##*/}"
branch="$(git -C "$cwd" branch --show-current 2>/dev/null)"

cost_fmt="$(printf '%.2f' "$cost" 2>/dev/null || echo 0.00)"

line="[$model] $dir"
[ -n "$branch" ] && line="$line  $branch"
line="$line  ctx ${ctx}%  \$$cost_fmt"
printf '%s\n' "$line"
