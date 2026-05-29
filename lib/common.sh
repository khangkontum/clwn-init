#!/usr/bin/env bash

log() { printf '[clwn-init] %s\n' "$*"; }
warn() { printf '[clwn-init] warning: %s\n' "$*" >&2; }

user_name="${CLWN_INIT_USER:-${SUDO_USER:-${USER:-$(id -un)}}}"
home_dir="${CLWN_INIT_HOME:-${HOME:-}}"

if [ -z "$home_dir" ] || [ "$home_dir" = / ]; then
  home_dir="$(getent passwd "$user_name" | cut -d: -f6 || true)"
fi
if [ -z "$home_dir" ] || [ ! -d "$home_dir" ]; then
  home_dir="${HOME:-/root}"
fi

user_group="$(id -gn "$user_name" 2>/dev/null || printf '%s' "$user_name")"

run_as_user() {
  if [ "$(id -un)" = "$user_name" ]; then
    env HOME="$home_dir" USER="$user_name" SHELL=/bin/bash "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo -H -u "$user_name" env HOME="$home_dir" USER="$user_name" SHELL=/bin/bash "$@"
  elif command -v runuser >/dev/null 2>&1; then
    runuser -u "$user_name" -- env HOME="$home_dir" USER="$user_name" SHELL=/bin/bash "$@"
  else
    su -s /bin/bash "$user_name" -c "$(printf '%q ' env HOME="$home_dir" USER="$user_name" SHELL=/bin/bash "$@")"
  fi
}

replace_managed_block() {
  file="$1"
  block="$2"
  start='# >>> clwn-init >>>'
  end='# <<< clwn-init <<<'

  mkdir -p "$(dirname "$file")"
  touch "$file"

  tmp="$(mktemp)"
  awk -v start="$start" -v end="$end" '
    $0 == start {skip=1; next}
    $0 == end {skip=0; next}
    !skip {print}
  ' "$file" >"$tmp"

  {
    cat "$tmp"
    printf '\n%s\n%s\n%s\n' "$start" "$block" "$end"
  } >"$file"
  rm -f "$tmp"
}

chown_user_files() {
  chown "$user_name:$user_group" "$@" 2>/dev/null || true
}
