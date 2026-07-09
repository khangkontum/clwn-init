#!/usr/bin/env bash

ensure_bash_shell() {
  if [ ! -x /bin/bash ]; then
    warn "/bin/bash is missing; skipping shell change"
    return 0
  fi

  current_shell="$(getent passwd "$user_name" | cut -d: -f7 || true)"
  if [ "$current_shell" = /bin/bash ]; then
    return 0
  fi

  log "setting $user_name login shell to /bin/bash"
  if command -v usermod >/dev/null 2>&1; then
    sudo usermod -s /bin/bash "$user_name" 2>/dev/null || usermod -s /bin/bash "$user_name" 2>/dev/null || warn "could not change login shell"
  elif command -v chsh >/dev/null 2>&1; then
    sudo chsh -s /bin/bash "$user_name" 2>/dev/null || chsh -s /bin/bash "$user_name" 2>/dev/null || warn "could not change login shell"
  else
    warn "neither usermod nor chsh is available; could not change login shell"
  fi
}

install_bash_profile_blocks() {
  replace_managed_block "$home_dir/.bash_profile" 'if [ -r "$HOME/.claude/claude-env.sh" ]; then
  . "$HOME/.claude/claude-env.sh"
fi
if [ -f "$HOME/.bashrc" ]; then
  . "$HOME/.bashrc"
fi'

  replace_managed_block "$home_dir/.profile" 'if [ -n "$BASH_VERSION" ] && [ -r "$HOME/.claude/claude-env.sh" ]; then
  . "$HOME/.claude/claude-env.sh"
fi
if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
  . "$HOME/.bashrc"
fi'

  chown_user_files "$home_dir/.bash_profile" "$home_dir/.profile"
}
