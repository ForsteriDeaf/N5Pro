# N5Pro

N5Pro é um toolkit automatizado para deploy, gestão e manutenção de ambientes Proxmox (PVE) e Proxmox Backup Server (PBS).

Foca-se em:
- instalação consistente
- runtime modular
- automação segura
- recuperação rápida
- operações guiadas

---

## Componentes principais

- Host setup (PVE)
- Criação de VMs (PBS / Unraid)
- Configuração de storage e backup
- Runtime CLI (n5pro)
- Sistema de update inteligente

---

## Estrutura do projeto

/opt/n5pro
├── docs/
├── final/
│   ├── host/
│   ├── pve/
│   ├── pbs/
│   ├── runtime/
│   └── lib/
├── legacy/
├── README.md
└── VERSION

---

## Runtime instalado

/usr/local/bin        → comandos n5pro*
/usr/local/lib/n5pro  → common.sh + VERSION
/etc/n5pro.conf       → configuração local

---

## Comandos principais

n5pro
n5pro-update --check
n5pro-update --install
n5pro-update --self-check
n5pro-update --doctor

---

## Extras

n5pro-backup
n5pro-log
n5pro-cron
n5pro-heal
n5pro-version

---

## Fluxo recomendado

1. Instalar runtime
n5pro-update --install

2. Validar
n5pro-update --self-check
n5pro-update --doctor

3. Utilizar
n5pro

---

## Documentação

docs/INSTALL.md
docs/RUNTIME.md
docs/RECOVERY.md
docs/ARCHITECTURE.md

---

## Estado do projeto

- Estrutura estabilizada
- Runtime completo
- Sistema de update funcional
- Self-check e doctor operacionais

Projeto pronto para uso real.
