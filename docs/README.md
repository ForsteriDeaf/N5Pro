# 🚀 N5Pro – Proxmox Homelab Automation Platform

> Transform your Proxmox + PBS homelab into a self-healing, automated infrastructure.

---

## ✨ Features

* 📊 **Interactive Dashboard (n5pro)**
* 🩺 **Doctor (n5pro-doctor)**

  * Diagnostics
  * Guided fix
  * Auto-fix mode
* 🔄 **Update System (n5pro-update)**

  * Version check (local vs remote)
  * Safe update with backup
* 💾 **Backup System (n5pro-backup)**

  * Full environment backup
  * PBS-ready
* ⚙️ **Automation Ready**
* 🧠 **Self-healing architecture**
* 🔐 SSH + PBS bootstrap ready

---

## 🧩 Components

| Tool                  | Description          |
| --------------------- | -------------------- |
| `n5pro`               | Main dashboard       |
| `n5pro-doctor`        | Diagnostics & repair |
| `n5pro-update`        | Update system        |
| `n5pro-backup`        | Backup system        |
| `n5pro-bootstrap-pbs` | Deploy tools to PBS  |

---

## ⚡ Quick Start (1 command)

```bash
bash <(curl -s https://raw.githubusercontent.com/ForsteriDeaf/N5Pro-Wizard/main/final/bootstrap.sh)
```

---

## 🖥️ Dashboard Preview

![Dashboard](screenshots/dashboard.png)

---

## 🧠 Philosophy

N5Pro is designed around:

* **Observability first**
* **Self-healing systems**
* **Minimal manual intervention**
* **Enterprise-grade homelab practices**

---

## 🔄 Update System

```bash
n5pro-update --install
```

✔ automatic backup
✔ version validation
✔ safe deployment

---

## 🩺 Doctor Modes

```bash
n5pro-doctor
n5pro-doctor --fix
n5pro-doctor --auto
n5pro-doctor --fix --dry-run
```

---

## 💾 Backup

```bash
n5pro-backup
```

---

## 🛰️ PBS Integration

```bash
n5pro-bootstrap-pbs
```

---

## 🔐 Requirements

* Proxmox VE 8+
* Proxmox Backup Server (optional)
* Root access
* SSH enabled

---

## 📁 Configuration

File:

```
/etc/n5pro.conf
```

---

## 🧪 Versioning

```bash
n5pro-version check
```

---

## 🛡️ Safety

* All updates create backups
* Doctor supports dry-run mode
* Non-destructive by default

---

## 🗺️ Roadmap

* [ ] Web UI
* [ ] Multi-node cluster support
* [ ] Metrics integration (Prometheus)
* [ ] Alerting system

---

## 🤝 Contributing

Pull requests are welcome.

---

## 📜 License

MIT License

---

## 💬 Author

Built with ❤️ for homelab automation
