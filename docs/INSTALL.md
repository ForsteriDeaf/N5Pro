# Installation

## Requirements

* Proxmox VE host
* root access
* internet access
* `curl` available

## Option 1: bootstrap installer

```bash
bash <(curl -s https://raw.githubusercontent.com/ForsteriDeaf/N5Pro-Wizard/main/final/bootstrap.sh)
```

This installs the main N5Pro commands into `/usr/local/bin` and creates `/etc/n5pro.conf` if it does not already exist.

## Option 2: repo-based install

```bash
apt update
apt install -y git curl
cd /root
git clone https://github.com/ForsteriDeaf/N5Pro-Wizard.git
cd /opt/n5pro/final
bash 01-PVE_Host-PostInstall.sh
n5pro-update --install
```

## Validate installation

```bash
n5pro
n5pro-version check
n5pro-doctor
```

## PBS bootstrap

From PVE:

```bash
n5pro-bootstrap-pbs
```

If needed, configure SSH first:

```bash
n5pro-ssh-setup-pbs
```

## Notes

* The main runtime config is `/etc/n5pro.conf`
* The repo update source is controlled by `N5PRO_REPO_BASE`
* Use `n5pro-backup` before major changes
