#!/usr/bin/env bash

mise_config_source="$script_dir/config/mise.toml"
mise_config_target="$home_dir/.config/mise/config.toml"

install_mise() {
  if run_as_user bash -lc 'command -v mise >/dev/null 2>&1'; then
    log "mise already installed"
  else
    log "installing mise"
    run_as_user bash -lc 'curl -fsSL https://mise.run | sh'
  fi

  install_mise_shell_block
  install_bash_profile_blocks
  sync_mise_config
  install_mise_tools
}

install_mise_shell_block() {
  shell_block='export SHELL=/bin/bash
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$HOME/.cargo/bin:$PATH"
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)"
fi'

  replace_managed_block "$home_dir/.bashrc" "$shell_block"
  chown_user_files "$home_dir/.bashrc"
}

sync_mise_config() {
  if [ ! -f "$mise_config_source" ]; then
    warn "mise config missing at $mise_config_source; skipping tool config"
    return 0
  fi

  log "installing mise config to $mise_config_target"
  mkdir -p "$(dirname "$mise_config_target")"

  if [ -f "$mise_config_target" ] && ! cmp -s "$mise_config_source" "$mise_config_target"; then
    backup="$mise_config_target.bak.$(date +%Y%m%d-%H%M%S)"
    cp "$mise_config_target" "$backup"
    chown_user_files "$backup"
    log "backed up previous mise config to $backup"
  fi

  cp "$mise_config_source" "$mise_config_target"
  chown_user_files "$mise_config_target" "$(dirname "$mise_config_target")"
}

install_mise_tools() {
  case "${CLWN_INIT_MISE_INSTALL_TOOLS:-1}" in
    0|false|False|no|No)
      log "skipping mise tool install because CLWN_INIT_MISE_INSTALL_TOOLS=${CLWN_INIT_MISE_INSTALL_TOOLS}"
      return 0
      ;;
  esac

  log "installing mise tools from $mise_config_target"
  run_as_user bash -lc 'export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"; mise trust "$HOME/.config/mise/config.toml" >/dev/null 2>&1 || true; mise install -y'
}
