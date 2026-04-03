# Recovery

## Reinstalling Proxmox VE

After reinstalling Proxmox VE, follow this sequence.

## Base preparation

```bash
apt update
apt install -y git curl
```

## Clone repo

```bash
cd /root
git clone https://github.com/ForsteriDeaf/N5Pro-Wizard.git
```

## Bootstrap host

```bash
cd /opt/n5pro/final
bash 01-PVE_Host-PostInstall.sh
```

## Restore config

If you have a backup, restore it. Otherwise recreate:

```bash
nano /etc/n5pro.conf
```

## Reinstall local binaries

```bash
n5pro-update --install
```

## Validate

```bash
n5pro
n5pro-doctor
```

## Restore PBS integration

```bash
n5pro-bootstrap-pbs
```

## Reconfigure Git SSH if needed

If the host was reinstalled, SSH keys may need to be recreated:

```bash
ssh-keygen -t ed25519 -C "root@pve"
cat ~/.ssh/id_ed25519.pub
```

Then add the public key to GitHub.

## Recommended final step

```bash
n5pro-backup
```
