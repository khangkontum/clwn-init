#!/usr/bin/env bash

claude_env_file="${CLWN_INIT_CLAUDE_ENV_FILE:-$home_dir/.claude/claude-env.sh}"

configure_claude() {
  case "${CLWN_INIT_CLAUDE_ENABLE:-1}" in
    0|false|False|no|No)
      log "skipping Claude Code setup because CLWN_INIT_CLAUDE_ENABLE=${CLWN_INIT_CLAUDE_ENABLE}"
      return 0
      ;;
  esac

  install_claude_onboarding
  install_claude_shell_env
}

install_claude_onboarding() {
  claude_json="$home_dir/.claude.json"

  log "marking Claude Code onboarding complete in $claude_json"
  if [ -s "$claude_json" ] && command -v python3 >/dev/null 2>&1; then
    if python3 - "$claude_json" <<'PYEOF'
import json
import sys

path = sys.argv[1]
with open(path) as f:
    data = json.load(f)
data["hasCompletedOnboarding"] = True
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PYEOF
    then
      chown_user_files "$claude_json"
      return 0
    fi
    backup="$claude_json.bak.$(date +%Y%m%d-%H%M%S)"
    cp "$claude_json" "$backup"
    chown_user_files "$backup"
    warn "could not merge $claude_json; backed it up to $backup and rewrote it"
  fi

  printf '{\n  "hasCompletedOnboarding": true\n}\n' >"$claude_json"
  chmod 0600 "$claude_json"
  chown_user_files "$claude_json"
}

install_claude_shell_env() {
  if [ -z "${CLWN_INIT_CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
    warn "CLWN_INIT_CLAUDE_CODE_OAUTH_TOKEN is empty; skipping Claude Code shell env"
    return 0
  fi

  log "installing Claude Code shell env to $claude_env_file"
  mkdir -p "$(dirname "$claude_env_file")"
  {
    printf 'export CLAUDE_CODE_OAUTH_TOKEN='
    printf '%q\n' "$CLWN_INIT_CLAUDE_CODE_OAUTH_TOKEN"
  } >"$claude_env_file"
  chmod 0600 "$claude_env_file"
  chown_user_files "$(dirname "$claude_env_file")" "$claude_env_file"
}
