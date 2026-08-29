#!/usr/bin/env bash
# Codex uses native footer fields rather than a command-backed status line.

set -euo pipefail

codex_dir="${CODEX_HOME:-${HOME}/.codex}"
config="${codex_dir}/config.toml"
mkdir -p "$codex_dir"
touch "$config"

python3 - "$config" <<'PY'
import os
from pathlib import Path
import re
import sys
import tempfile

config = Path(sys.argv[1])
text = config.read_text()
status_line = (
    'status_line = ["model-with-reasoning", "current-dir", "git-branch", '
    '"context-used", "five-hour-limit", "weekly-limit", "fast-mode"]\n'
)
section_pattern = re.compile(r"(?m)^[ \t]*\[([^\]\n]+)\][ \t]*(?:#.*)?$")
sections = list(section_pattern.finditer(text))
tui = next((section for section in sections if section.group(1).strip() == "tui"), None)

if tui is None:
    nested_tui = next(
        (section for section in sections if section.group(1).strip().startswith("tui.")),
        None,
    )
    offset = nested_tui.start() if nested_tui else len(text)
    prefix = text[:offset]
    suffix = text[offset:]
    separator = "" if not prefix or prefix.endswith("\n\n") else "\n"
    text = f"{prefix}{separator}[tui]\n{status_line}\n{suffix}"
else:
    following = next((section for section in sections if section.start() > tui.start()), None)
    start = tui.end()
    end = following.start() if following else len(text)
    body = text[start:end]
    setting_pattern = re.compile(
        r'(?ms)^[ \t]*status_line[ \t]*=[ \t]*\[[^\]]*\][ \t]*(?:#.*)?(?:\n|$)'
    )
    if setting_pattern.search(body):
        body = setting_pattern.sub(status_line, body, count=1)
    else:
        body = f"\n{status_line}{body.lstrip(chr(10))}"
    text = f"{text[:start]}{body}{text[end:]}"

mode = config.stat().st_mode
with tempfile.NamedTemporaryFile(
    mode="w", dir=config.parent, prefix=f".{config.name}.", delete=False
) as temporary:
    temporary.write(text)
    temporary_path = Path(temporary.name)
os.chmod(temporary_path, mode)
temporary_path.replace(config)
PY
