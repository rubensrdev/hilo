#!/bin/bash
# SessionStart hook — injects cheap, high-value repo context at the start of each
# session so the agent doesn't burn tool calls discovering it. stdout is added to
# the session context. Always exit 0.

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

echo "## Repo snapshot (SessionStart hook)"
echo "Branch and status:"
git status -sb 2>/dev/null | head -15
echo ""
echo "Last 5 commits:"
git log --oneline -5 2>/dev/null
echo ""
TODOS=$(grep -rn "TODO\|FIXME" --include="*.swift" . 2>/dev/null | grep -v ".build/" | wc -l | tr -d ' ')
echo "Open TODO/FIXME markers in Swift files: $TODOS"

exit 0
