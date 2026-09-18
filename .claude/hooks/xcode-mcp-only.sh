#!/bin/bash
# OPT-IN PreToolUse hook (matcher: Bash) — for projects that standardize on the Xcode
# MCP: blocks CLI builds/tests and pbxproj-manipulating tools so all project operations
# go through MCP (structured diagnostics, no log-parsing, fewer tokens).
# Do NOT enable in projects that build via CLI/CI on purpose. exit 2 = block.

CMD=$(python3 -c '
import json,sys
data = json.load(sys.stdin)
print(data.get("tool_input", {}).get("command", ""))
')

[ -z "$CMD" ] && exit 0

# git/gh commands are always fine
echo "$CMD" | grep -qE '^\s*(git|gh)\s' && exit 0

deny() { echo "BLOCKED: $1" >&2; exit 2; }

echo "$CMD" | grep -qE '(^|[;&|(]\s*)(xcrun\s+)?xcodebuild\b' && \
  deny "use the Xcode MCP (BuildProject / RunAllTests / RunSomeTests / GetBuildLog) instead of xcodebuild."
echo "$CMD" | grep -qE '(^|[;&|(]\s*)swift\s+(build|test)\b' && \
  deny "use the Xcode MCP instead of swift build/test in this project."
echo "$CMD" | grep -qE 'xcodegen|gem\s+.*xcodeproj|ruby\s+.*xcodeproj' && \
  deny "project file manipulation tools are not allowed. Use Xcode MCP file operations."

exit 0
