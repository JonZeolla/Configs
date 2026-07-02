#!/usr/bin/env bash
# Claude Code status line. Managed in jonzeolla/configs; setup.sh installs it to ~/.claude/statusline.sh.
# Renders: [Model] dir  branch  <clickable PR #N | no PR>  ctx N%  $cost
#
# gh is network-bound, so the PR lookup is cached per repo+branch and refreshed
# in the background — the status line reads whatever the last refresh left and
# never blocks the terminal.

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
branch=""
pr="no PR"

if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "$cwd" branch --show-current 2>/dev/null)"

  cache_dir="${TMPDIR:-/tmp}"
  key="$(printf '%s|%s' "$cwd" "$branch" | cksum | cut -d' ' -f1)"
  cache="${cache_dir}/claude_sl_pr_${key}"
  ttl=30
  now="$(date +%s)"
  mtime=0
  [ -f "$cache" ] && mtime="$(stat -f %m "$cache" 2>/dev/null || stat -c %Y "$cache" 2>/dev/null || echo 0)"

  # Refresh in the background when stale. Empty cache file == "gh ran, no PR".
  if [ ! -f "$cache" ] || [ "$((now - mtime))" -ge "$ttl" ]; then
    ( cd "$cwd" && gh pr view --json number,url --jq '"\(.number)\t\(.url)"' 2>/dev/null >"${cache}.tmp" \
        && mv "${cache}.tmp" "$cache" || : >"$cache" ) </dev/null >/dev/null 2>&1 &
  fi

  if [ -f "$cache" ]; then
    if [ -s "$cache" ]; then
      num="$(cut -f1 "$cache")"
      url="$(cut -f2 "$cache")"
      # OSC 8 hyperlink: ESC ] 8 ;; URL ST  label  ESC ] 8 ;; ST
      pr="$(printf '\033]8;;%s\033\\PR #%s\033]8;;\033\\' "$url" "$num")"
    else
      pr="no PR"
    fi
  else
    pr="PR…"  # first paint before the background lookup lands
  fi
fi

cost_fmt="$(printf '%.2f' "$cost" 2>/dev/null || echo 0.00)"

line="[$model] $dir"
[ -n "$branch" ] && line="$line  $branch"
line="$line  $pr  ctx ${ctx}%  \$$cost_fmt"
printf '%s\n' "$line"
