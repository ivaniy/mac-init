# macOS Bootstrap Playbook (Intel & Apple silicon)

This playbook provisions a **fresh macOS** workstation using **official installers** wherever possible (Chrome, Slack, JetBrains, Docker, etc.), installs a few CLIs (Terraform, kubectl, jq, gcloud, AWS CLI, Auth0), and wires your shell so everything works the same on **bash** and **zsh**. It supports **Intel** and **Apple silicon** Macs.

It’s designed to be **idempotent** and safe to re-run.

---

## Contents

* [What it installs](#what-it-installs)
* [Prereqs](#prereqs)
* [How to run](#how-to-run)
* [Variables](#variables)
* [Tags](#tags)
* [Apple silicon notes (Rosetta & PATH)](#apple-silicon-notes-rosetta--path)
* [Terraform & kubectl Version Managers](#terraform--kubectl-version-managers)
* [Troubleshooting](#troubleshooting)

---

## What it installs

* **Shell setup**

  * Optional default shell change (to `/bin/bash`)
  * `.bash_profile` → sources `.bashrc`
  * History tuning for bash/zsh
  * On Apple silicon, adds Homebrew’s `/opt/homebrew/{bin,sbin}` to system PATH

* **Apps (official downloads)**

  * Google Chrome (pkg)
  * Visual Studio Code (zip) + extensions 
  * Sublime Text (zip)
  * Slack (pkg)
  * PyCharm Community (dmg)
  * Zoom (pkg)
  * KeePassXC (dmg)
  * Docker Desktop (dmg)

* **CLIs**

  * Terraform (official zip + checksum; optional **tfvm** helper)
  * kubectl (official binary + checksum; optional **kubvm** helper)
  * jq (official release binary)
  * Google Cloud SDK (official tarball; silent install) (require Homebrew for GNU tar)
  * AWS CLI v2 (official pkg)
  * Auth0 CLI (via Homebrew)
  * Ansible (via Homebrew)

* **Homebrew**

  * Installs Homebrew (official script) 
  * Runs `brew update` + `brew upgrade` before brew installs

---

## Prereqs

* **Target Mac**

  * macOS with **SSH enabled** (Remote Login) and your user in `com.apple.access_ssh`
  * Your SSH key in `~/.ssh/authorized_keys`
  * If using Apple silicon Rosetta will be handled by the playbook

## How to run

Run with your SSH user:

```bash
ansible-playbook install_software.yml -i "<macbook_address>," -e "ansible_user=<ssh_user>" -K
```

* To override variables inline:

```bash
ansible-playbook install_software.yml -i "<macbook_address>," -e "ansible_user=<ssh_user>" -K \
  -e '{"chrome_install": false, "terraform_version": "1.10.5"}'
```

* Or edit **`ansible_vars.json`** (recommended).

* To run only certain sections, use **tags**, e.g.:

```bash
ansible-playbook install_software.yml -i "<macbook_address>," -e "ansible_user=<ssh_user>" -K \
  -t chrome_install,vscode_install
```

---

## Variables

Put your desired values in **`ansible_vars.json`**. Below are the most important ones you’ll use.

### Shell & profile

| Variable               | Type   | Default       | Meaning                                          |
| ---------------------- | ------ | ------------- | ------------------------------------------------ |
| `change_default_shell` | bool   | `true`        | If `true`, change login shell to `target_shell`. |
| `target_shell`         | string | `/bin/bash`   | Target login shell.                              |
| `set_profile_config`   | bool   | `true`        | Ensure `.bash_profile` sources `.bashrc`.        |
| `set_history_config`   | bool   | `true`        | Configure history size for bash/zsh.             |
| `history_size`         | string | `10000`       | `HISTSIZE` (bash/zsh).                           |
| `history_file_size`    | string | `10000`       | `HISTFILESIZE` (bash) / `SAVEHIST` (zsh).        |

### App toggles

| Variable                  | Type | Default | Notes                                               |
| ------------------------- | ---- | ------- | --------------------------------------------------- |
| `chrome_install`          | bool | `true`  | Install Google Chrome (pkg).                        |
| `vscode_install`          | bool | `true`  | Install Visual Studio Code (zip). + cli             |
| `vscode_install_packages` | bool | `true`  | Install VS Code extensions from `vscode_packages`.  |
| `vscode_packages`         | list | `[]`    | Extension IDs (optionally `publisher.ext`).         |
| `sublime_install`         | bool | `true`  | Install Sublime Text (zip).                         |
| `slack_install`           | bool | `true`  | Install Slack (pkg).                                |
| `pycharm_install`         | bool | `true`  | Install PyCharm CE (dmg).                           |
| `zoom_install`            | bool | `true`  | Install Zoom (pkg).                                 |
| `keepassxc_install`       | bool | `true`  | Install KeePassXC (dmg).                            |
| `docker_install`          | bool | `true`  | Install Docker Desktop (dmg).                       |

### CLI toggles

| Variable                    | Type   | Default                   | Meaning                            |
| --------------------------- | ------ | ------------------------- | ---------------------------------- |
| `terraform_install`         | bool   | `true`                    | Install Terraform.                 |
| `terraform_version`         | string | (set in vars)             | Version like `1.10.5`.             |
| `terraform_version_manager` | bool   | `true`                    | Use **tfvm** helper and symlink.   |
| `kubectl_install`           | bool   | `true`                    | Install kubectl (official binary). |
| `kubectl_version`           | string | `stable`                  | Version like`1.33.0` or `stable`   |
| `kubectl_version_manager`   | bool   | `true`                    | Use **kubvm** helper and symlink.  |
| `jq_install`                | bool   | `true`                    | Install jq (official binary).      |
| `jq_version`                | string | `1.8.1`                   | jq version to install.             |
| `gcloud_cli_install`        | bool   | `true`                    | Install Google Cloud SDK.          |
| `aws_cli_install`           | bool   | `true`                    | Install AWS CLI v2 (pkg).          |
| `auth0_cli_install`         | bool   | `true`                    | Install Auth0 CLI via Homebrew.    |
| `ansible_install`           | bool   | `true`                    | Install Ansible via Homebrew.      |

### Homebrew & housekeeping

| Variable             | Type | Default | Meaning                                              |
| -------------------- | ---- | ------- | ---------------------------------------------------- |
| `homebrew_install`   | bool | `true`  | Install Homebrew (official script) if missing.       |
| `cleanup_installers` | bool | `false` | Remove the temporary installer workspace at the end. |

> **Architecture variables** like `is_arm64`, `brew_prefix`, `brew_bin_dir` are computed automatically.

---

## Tags

Use tags to run only parts of the play:

| Tag                         | Scope / What it does                                            |
| --------------------------- | --------------------------------------------------------------- |
| `change_default_shell`      | Sets login shell to `target_shell`.                             |
| `set_profile_config`        | Ensures `.bash_profile` sources `.bashrc`.                      |
| `set_history_config`        | Writes shell history settings.                                  |
| `chrome_install`            | Installs Chrome.                                                |
| `terraform_install`         | Installs Terraform.                                             |
| `terraform_version_manager` | Installs `tfvm.sh` and sources it.                              |
| `vscode_install`            | Installs VS Code.                                               |
| `vscode_install_packages`   | Installs **missing** VS Code extensions from `vscode_packages`. |
| `sublime_install`           | Installs Sublime Text.                                          |
| `homebrew_install`          | Installs Homebrew if missing; also runs brew maintenance later. |
| `slack_install`             | Installs Slack.                                                 |
| `pycharm_install`           | Installs PyCharm CE.                                            |
| `zoom_install`              | Installs Zoom.                                                  |
| `keepassxc_install`         | Installs KeePassXC.                                             |
| `docker_install`            | Installs Docker Desktop.                                        |
| `ansible_install`           | Installs Ansible via Homebrew.                                  |
| `jq_install`                | Installs jq.                                                    |
| `gcloud_cli_install`        | Installs Google Cloud SDK.                                      |
| `aws_cli_install`           | Installs AWS CLI v2.                                            |
| `auth0_cli_install`         | Installs Auth0 CLI via Homebrew.                                |
| `kubectl_install`           | Installs kubectl.                                               |
| `kubectl_version_manager`   | Installs `kubvm.sh` and sources it.                             |
| `cleanup_installers`        | Removes the temp installers dir.                                |

### Dependency map

* `gcloud_cli_install`: Requires homebrew. Runs `brew update` + `brew upgrade`. Auto-installs **gnu-tar** when missing.
* `auth0_cli_install`: Requires homebrew. Runs `brew update` + `brew upgrade`. Uses the `auth0/auth0-cli` tap and installs the `auth0` cli
* `ansible_install`:  Requires homebrew. Runs `brew update` + `brew upgrade`. 
* `homebrew_install`: Skip `brew update` and `brew upgrade`. Don't reinstall if exist
* `zoom_install`: Rosetta required on Apple Silicon
* `aws_cli_install`: Rosetta required on Apple Silicon
* `keepassxc_install`: Doesn't start on Screen Sharing. Require `--allow-screencapture`
* `terraform_install`: If enabled `terraform_version_manager` places versions under `~/.tfvm/<ver>` and symlinks `/usr/local/bin/terraform`.  Else places as `/usr/local/bin/terraform`
* `kubectl_install`: `kubectl_version_manager`  places versions under `~/.kubvm/<ver>` and symlinks `/usr/local/bin/kubectl`. Else places as `/usr/local/bin/kubectl`
* `vscode_install_packages`: Installs VS Code CLI when if VS Code installed. Skip when VS Code is not installed.

## Apple silicon notes (Rosetta & PATH)

* **Rosetta 2**
  On Apple silicon, the playbook copies and runs `files/install_rosetta.sh`, which **installs Rosetta** idempotently. It’s required for Intel-only PKGs / apps (some Zoom/AWS CLI releases, etc.).

* **Homebrew PATH**
  On ARM, Homebrew lives in **`/opt/homebrew`**. The playbook writes `/etc/paths.d/20-homebrew` so **bash** and **zsh** find brew tools uniformly. Zsh typically works out of the box; this also fixes Bash login shells.

---

## Terraform & kubectl Version Managers

If enabled:

* **tfvm**

  * Installs Terraform to `~/.tfvm/<version>/terraform`
  * Symlinks `/usr/local/bin/terraform` → selected version
  * `~/.tfvm/tfvm.sh` function is sourced in your shell

* **kubvm**

  * Installs kubectl to `~/.kubvm/<vX.Y.Z>/kubectl` (from dl.k8s.io, checksum verified)
  * Symlinks `/usr/local/bin/kubectl` → selected version
  * `~/.kubvm/kubvm.sh` function is sourced in your shell

> Both helpers live in **`files/tfvm.sh`** and **`files/kubvm.sh`**. Customize them there if needed.
