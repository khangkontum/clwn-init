#!/usr/bin/env bash

configure_git() {
  if ! run_as_user bash -lc 'command -v git >/dev/null 2>&1'; then
    warn "git is not installed; skipping git setup"
    return 0
  fi

  configure_git_identity
  install_git_hooks
}

configure_git_identity() {
  git_name="${CLWN_INIT_GIT_NAME:-Hoang-Khang Nguyen}"
  git_email="${CLWN_INIT_GIT_EMAIL:-git@nhkhang.com}"

  log "configuring git identity: $git_name <$git_email>"
  run_as_user git config --global user.name "$git_name"
  run_as_user git config --global user.email "$git_email"
}

install_git_hooks() {
  hook_src="$script_dir/lib/git-hooks/commit-msg"
  hook_dir="$home_dir/.config/git/hooks"
  hook_dst="$hook_dir/commit-msg"

  if [ ! -f "$hook_src" ]; then
    warn "git commit-msg hook missing at $hook_src; skipping hook setup"
    return 0
  fi

  log "installing git commit-msg hook to strip Co-Authored-by trailers"
  mkdir -p "$hook_dir"
  cp "$hook_src" "$hook_dst"
  chmod 0755 "$hook_dst"
  chown_user_files "$hook_dir" "$hook_dst"

  run_as_user git config --global core.hooksPath "$hook_dir"
}
