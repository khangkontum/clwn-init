#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
. "$script_dir/lib/common.sh"
# shellcheck source=lib/shell.sh
. "$script_dir/lib/shell.sh"
# shellcheck source=lib/mise.sh
. "$script_dir/lib/mise.sh"
# shellcheck source=lib/git.sh
. "$script_dir/lib/git.sh"
# shellcheck source=lib/droid.sh
. "$script_dir/lib/droid.sh"
# shellcheck source=lib/claude.sh
. "$script_dir/lib/claude.sh"

main() {
  log "bootstrapping for user=$user_name home=$home_dir"
  ensure_bash_shell
  configure_git
  install_mise
  configure_droid
  configure_claude
  run_as_user bash -lc 'export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"; mise --version'
  log "done"
}

main "$@"
