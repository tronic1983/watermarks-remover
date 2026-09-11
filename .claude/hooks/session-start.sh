#!/bin/bash
set -uo pipefail

# Only auto-provision in Claude Code on the web (remote) sessions.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

REPO="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Make the remove-ai-marks skill visible to Claude Code without duplicating
# its source: symlink the repo's own skills/remove-ai-marks into .claude/skills/.
mkdir -p "$REPO/.claude/skills"
ln -sfn "$REPO/skills/remove-ai-marks" "$REPO/.claude/skills/remove-ai-marks"

# Start the watermarks-remover HTTP service if it isn't already up.
if ! curl -sf http://127.0.0.1:8765/health >/dev/null 2>&1; then
  nohup python3 "$REPO/service/scripts/server.py" --host 127.0.0.1 --port 8765 \
    > /tmp/watermarks-remover-service.log 2>&1 &
  disown

  for _ in $(seq 1 10); do
    curl -sf http://127.0.0.1:8765/health >/dev/null 2>&1 && break
    sleep 0.5
  done
fi

exit 0
