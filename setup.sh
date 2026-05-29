#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
. "$script_dir/lib/common.sh"
# shellcheck source=lib/shell.sh
. "$script_dir/lib/shell.sh"
# shellcheck source=lib/mise.sh
. "$script_dir/lib/mise.sh"

main() {
  log "bootstrapping for user=$user_name home=$home_dir"
  ensure_bash_shell
  install_mise
  run_as_user bash -lc 'mise --version'
  log "done"
}

main "$@"
