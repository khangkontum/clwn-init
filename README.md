# clwn-init

Personal setup hook for new `clwn` cloud-init VMs.

`bootstrap.sh` is the tiny script to store in clwn. It downloads this repo from
GitHub and runs `setup.sh`, keeping the clwn default setup script small.

Current setup:

- requires/re-execs with `bash`
- changes the VM user login shell to `/bin/bash` when possible
- configures global Git identity as `Hoang-Khang Nguyen <git@nhkhang.com>`
- installs a global `commit-msg` hook that strips `Co-Authored-by` trailers from commit messages
- installs `mise` for the VM user with the official installer
- writes `config/mise.toml` to `~/.config/mise/config.toml`
- installs the configured tools, currently Node.js LTS, pnpm, Python, uv, Go, Rust, and zmx
- runs `mise install -y` so the configured tools are available immediately
- adds a managed bash startup block for mise activation and a `ZMX_SESSION` prompt prefix

Layout:

- `bootstrap.sh` is the small script stored in clwn.
- `setup.sh` is the orchestrator.
- `config/mise.toml` is the global VM mise toolset.
- `lib/common.sh` contains logging, user detection, and managed-block helpers.
- `lib/shell.sh` contains shell/profile setup.
- `lib/git.sh` contains Git identity and hook setup.
- `lib/git-hooks/commit-msg` removes agent-added `Co-Authored-by` trailers.
- `lib/mise.sh` contains mise installation, global config sync, and tool install.

## Install as the clwn default setup script

After pushing this repo, run on the clwn host:

```sh
sudo clwn defaults write clwn new.setup-script < bootstrap.sh
```

Create a VM normally:

```sh
sudo clwn new --name test --image images:ubuntu/noble/cloud
```

To change the default developer tools, edit `config/mise.toml` and push the repo.
The next VM will copy that file into `~/.config/mise/config.toml` and install the
listed tools. Set `CLWN_INIT_MISE_INSTALL_TOOLS=0` in a custom wrapper if you
want to sync the config but skip the install step.

Override the downloaded repo/ref if needed by editing `bootstrap.sh` before
installing it, or by using environment variables in a custom wrapper:

```sh
CLWN_INIT_REF=main bash bootstrap.sh
```
