#!/usr/bin/env bash
set -euo pipefail

target_host="${CLWN_INIT_TARGET_HOST:?set CLWN_INIT_TARGET_HOST in mise.local.toml}"
bootstrap_path="${CLWN_INIT_BOOTSTRAP_PATH:-bootstrap.sh}"
: "${CLWN_INIT_DROID_API_KEY:?set CLWN_INIT_DROID_API_KEY in mise.local.toml}"

tmp="$(mktemp)"
cleanup() { rm -f "$tmp"; }
trap cleanup EXIT

{
  printf '#!/usr/bin/env bash\n'
  printf 'set -euo pipefail\n\n'
  printf 'export CLWN_INIT_DROID_API_KEY=%q\n' "$CLWN_INIT_DROID_API_KEY"
  printf 'export CLWN_INIT_DROID_BYOK_API_KEY=%q\n' "${CLWN_INIT_DROID_BYOK_API_KEY:-clwn-local-placeholder}"
  if [ -n "${CLWN_INIT_DROID_COMPUTER_NAME:-}" ]; then
    printf 'export CLWN_INIT_DROID_COMPUTER_NAME=%q\n' "$CLWN_INIT_DROID_COMPUTER_NAME"
  fi
  if [ -n "${CLWN_INIT_CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
    printf 'export CLWN_INIT_CLAUDE_CODE_OAUTH_TOKEN=%q\n' "$CLWN_INIT_CLAUDE_CODE_OAUTH_TOKEN"
  else
    echo "warning: CLWN_INIT_CLAUDE_CODE_OAUTH_TOKEN is empty; new VMs will skip the Claude Code shell env" >&2
  fi
  printf 'export CLWN_INIT_REPO=%q\n' "${CLWN_INIT_REPO:-khangkontum/clwn-init}"
  printf 'export CLWN_INIT_REF=%q\n\n' "${CLWN_INIT_REF:-master}"
  tail -n +2 "$bootstrap_path"
} >"$tmp"

ssh "$target_host" 'sudo /usr/local/bin/clwn defaults write clwn new.setup-script' <"$tmp"
