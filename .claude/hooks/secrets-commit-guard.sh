#!/bin/bash
# PreToolUse hook (matcher: Bash) — when the agent runs `git commit`, scans the STAGED
# diff for secret patterns and blocks the commit if any are found. exit 2 = block.

CMD=$(python3 -c '
import json,sys
data = json.load(sys.stdin)
print(data.get("tool_input", {}).get("command", ""))
')

echo "$CMD" | grep -qE '(^|[;&|]\s*)git\s+commit' || exit 0

STAGED=$(git diff --cached --unified=0 2>/dev/null | grep '^+' | grep -v '^+++') || exit 0

FOUND=$(echo "$STAGED" | grep -nE \
  '(api[_-]?key|apikey|password|passwd|secret|token)\s*[:=]\s*["'"'"'][^"'"'"']{8,}|"sk-[a-zA-Z0-9]{10,}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY' \
  | grep -viE 'placeholder|example|your[_-]?key|<[^>]+>|\$\{|\$\(|ProcessInfo|environment')

if [ -n "$FOUND" ]; then
  echo "BLOCKED: possible secrets in the staged diff. Remove them (use Keychain/env/config outside the repo) before committing:" >&2
  echo "$FOUND" | head -10 >&2
  exit 2
fi

exit 0
