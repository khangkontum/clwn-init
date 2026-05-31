#!/usr/bin/env bash

droid_env_file="${CLWN_INIT_DROID_ENV_FILE:-/etc/factory/droid-daemon.env}"
droid_service_name="${CLWN_INIT_DROID_SERVICE_NAME:-droid-daemon}"
droid_model="${CLWN_INIT_DROID_MODEL:-gpt-5.5}"
droid_model_id="${CLWN_INIT_DROID_MODEL_ID:-custom:${droid_model}-0}"
droid_display_name="${CLWN_INIT_DROID_DISPLAY_NAME:-gpt-5.5}"
droid_base_url="${CLWN_INIT_DROID_BASE_URL:-http://llm-gateway.int.clwn.dev/v1}"
droid_byok_env_name="${CLWN_INIT_DROID_BYOK_ENV_NAME:-DROID_BYOK_API_KEY}"
droid_byok_placeholder="${CLWN_INIT_DROID_BYOK_PLACEHOLDER:-clwn-local-placeholder}"
droid_reasoning_effort="${CLWN_INIT_DROID_REASONING_EFFORT:-high}"
droid_mission_reasoning_effort="${CLWN_INIT_DROID_MISSION_REASONING_EFFORT:-high}"
droid_mission_orchestrator_reasoning_effort="${CLWN_INIT_DROID_MISSION_ORCHESTRATOR_REASONING_EFFORT:-xhigh}"
droid_provider="${CLWN_INIT_DROID_PROVIDER:-openai}"

configure_droid() {
  case "${CLWN_INIT_DROID_ENABLE:-1}" in
    0|false|False|no|No)
      log "skipping Droid setup because CLWN_INIT_DROID_ENABLE=${CLWN_INIT_DROID_ENABLE}"
      return 0
      ;;
  esac

  install_droid_settings
  install_droid_shell_env
  install_droid_env
  register_droid_computer
  install_droid_service
}

install_droid_settings() {
  settings_dir="$home_dir/.factory"
  settings_file="$settings_dir/settings.json"

  log "installing Droid BYOK settings to $settings_file"
  mkdir -p "$settings_dir"
  if [ -f "$settings_file" ]; then
    backup="$settings_file.bak.$(date +%Y%m%d-%H%M%S)"
    cp "$settings_file" "$backup"
    chown_user_files "$backup"
    log "backed up previous Droid settings to $backup"
  fi

  cat >"$settings_file" <<EOF
{
  "customModels": [
    {
      "apiKey": "\${$droid_byok_env_name}",
      "baseUrl": "$droid_base_url",
      "displayName": "$droid_display_name",
      "id": "$droid_model_id",
      "index": 0,
      "model": "$droid_model",
      "noImageSupport": false,
      "provider": "$droid_provider"
    }
  ],
  "enabledPlugins": {
    "core@factory-plugins": true
  },
  "logoAnimation": "off",
  "missionModelSettings": {
    "skipUserTesting": false,
    "validationWorkerModel": "$droid_model_id",
    "validationWorkerReasoningEffort": "$droid_mission_reasoning_effort",
    "workerModel": "$droid_model_id",
    "workerReasoningEffort": "$droid_mission_reasoning_effort"
  },
  "missionOrchestratorModel": "$droid_model_id",
  "missionOrchestratorReasoningEffort": "$droid_mission_orchestrator_reasoning_effort",
  "modelFavorites": [
    "$droid_model_id"
  ],
  "sessionDefaultSettings": {
    "autonomyMode": "normal",
    "model": "$droid_model_id",
    "reasoningEffort": "$droid_reasoning_effort"
  }
}
EOF
  chmod 0600 "$settings_file"
  chown_user_files "$settings_dir" "$settings_file"
}

install_droid_shell_env() {
  env_file="$home_dir/.factory/droid-env.sh"
  log "installing Droid shell env to $env_file"
  mkdir -p "$(dirname "$env_file")"
  {
    if [ -n "${CLWN_INIT_DROID_API_KEY:-}" ]; then
      printf 'export FACTORY_API_KEY='
      printf '%q\n' "$CLWN_INIT_DROID_API_KEY"
    fi
    printf 'export %s=' "$droid_byok_env_name"
    printf '%q\n' "${CLWN_INIT_DROID_BYOK_API_KEY:-$droid_byok_placeholder}"
  } >"$env_file"
  chmod 0600 "$env_file"
  chown_user_files "$env_file"
}

install_droid_env() {
  if [ "$(id -u)" -ne 0 ]; then
    warn "Droid systemd setup requires root; skipping env file and service"
    return 0
  fi

  if [ -z "${CLWN_INIT_DROID_API_KEY:-}" ]; then
    if [ -f "$droid_env_file" ]; then
      warn "CLWN_INIT_DROID_API_KEY is empty; preserving existing $droid_env_file"
    else
      warn "CLWN_INIT_DROID_API_KEY is empty; skipping Droid daemon env file"
    fi
    return 0
  fi

  log "installing Droid daemon env file to $droid_env_file"
  mkdir -p "$(dirname "$droid_env_file")"
  {
    printf 'FACTORY_API_KEY=%s\n' "${CLWN_INIT_DROID_API_KEY:-}"
    printf '%s=%s\n' "$droid_byok_env_name" "${CLWN_INIT_DROID_BYOK_API_KEY:-$droid_byok_placeholder}"
  } >"$droid_env_file"
  chmod 0600 "$droid_env_file"
  chown root:root "$droid_env_file" 2>/dev/null || true
}

register_droid_computer() {
  if [ -z "${CLWN_INIT_DROID_API_KEY:-}" ]; then
    warn "CLWN_INIT_DROID_API_KEY is empty; skipping Droid computer registration"
    return 0
  fi

  computer_name="${CLWN_INIT_DROID_COMPUTER_NAME:-$(hostname)}"
  log "registering Droid computer: $computer_name"
  run_as_user env FACTORY_API_KEY="$CLWN_INIT_DROID_API_KEY" DROID_COMPUTER_NAME="$computer_name" \
    bash -lc 'export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"; droid computer register "$DROID_COMPUTER_NAME" -y' \
    || warn "Droid computer registration failed"
}

install_droid_service() {
  if [ "$(id -u)" -ne 0 ] || ! command -v systemctl >/dev/null 2>&1; then
    return 0
  fi
  if ! grep -q '^FACTORY_API_KEY=.' "$droid_env_file" 2>/dev/null; then
    warn "Droid daemon env file is missing FACTORY_API_KEY; skipping systemd service"
    return 0
  fi

  service_file="/etc/systemd/system/${droid_service_name}.service"
  log "installing Droid daemon systemd service to $service_file"
  cat >"$service_file" <<EOF
[Unit]
Description=Factory Droid remote access daemon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$user_name
Group=$user_group
WorkingDirectory=$home_dir
Environment=HOME=$home_dir
Environment=USER=$user_name
Environment=SHELL=/bin/bash
Environment=PATH=$home_dir/.local/bin:$home_dir/.local/share/mise/shims:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EnvironmentFile=$droid_env_file
ExecStart=$home_dir/.local/share/mise/shims/droid daemon --remote-access
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
  chmod 0644 "$service_file"

  systemctl daemon-reload
  systemctl enable --now "${droid_service_name}.service"
  systemctl is-active "${droid_service_name}.service" >/dev/null
}
