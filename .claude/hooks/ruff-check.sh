#!/usr/bin/env bash
# Claude Code PostToolUse hook (Edit|Write|MultiEdit): run Ruff on edited Python
# files when this is a uv-backed Python project. Missing tools, non-Python
# files, and absent pyproject files are treated as no-ops so early project
# setup is not blocked.

set -u

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')

case "$file_path" in
  *.py) ;;
  *) exit 0 ;;
esac

if [[ -z "$file_path" || ! -f "$file_path" ]]; then
  exit 0
fi

if ! command -v uv >/dev/null 2>&1; then
  exit 0
fi

project_dir=$(dirname "$file_path")
while [[ "$project_dir" != "/" && ! -f "$project_dir/pyproject.toml" ]]; do
  project_dir=$(dirname "$project_dir")
done

if [[ ! -f "$project_dir/pyproject.toml" ]]; then
  exit 0
fi

rel_path="${file_path#"$project_dir/"}"
raw_output=$(cd "$project_dir" && uv run --quiet ruff check --output-format=concise --no-fix "$rel_path" 2>&1)
status=$?
output=$(printf '%s' "$raw_output" | sed -E $'s/\x1B\\[[0-9;]*[a-zA-Z]//g')

if [[ $status -eq 0 ]]; then
  exit 0
fi

context="ruff check failed for ${rel_path} (from ${project_dir}):

${output}

Fix these lint issues before continuing."

jq -n --arg ctx "$context" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: $ctx
  }
}'
exit 0
