#!/usr/bin/env bash
set -euo pipefail

# Tiny clwn setup-script entrypoint. clwn stores this in cloud-init and runs it
# on each new cloud-init VM. The larger, personal setup lives in this repo.

if [ -z "${BASH_VERSION:-}" ]; then
  if command -v bash >/dev/null 2>&1; then
    exec bash "$0" "$@"
  fi
  echo "clwn-init requires bash" >&2
  exit 1
fi

repo="${CLWN_INIT_REPO:-khangkontum/clwn-init}"
ref="${CLWN_INIT_REF:-master}"
url="${CLWN_INIT_URL:-https://github.com/${repo}/archive/${ref}.tar.gz}"

tmp="$(mktemp -d)"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT

archive="$tmp/clwn-init.tar.gz"
work="$tmp/src"
mkdir -p "$work"

curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors "$url" -o "$archive"
tar -xzf "$archive" -C "$work" --strip-components=1

exec bash "$work/setup.sh"
