#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f /usr/local/lib/n5pro/common.sh ]]; then
  # shellcheck disable=SC1091
  source /usr/local/lib/n5pro/common.sh
elif [[ -f "${SCRIPT_DIR}/../lib/common.sh" ]]; then
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/../lib/common.sh"
else
  RED="\033[38;5;196m"
  GREEN="\033[38;5;10m"
  YELLOW="\033[38;5;11m"
  BLUE="\033[38;5;21m"
  MAGENTA="\033[38;5;13m"
  CYAN="\033[38;5;14m"
  RESET="\033[0m"
  BOLD="\033[1m"
  LINE="==========================================================="
  info(){ echo -e "${CYAN}[INFO]${RESET} $*"; }
  ok(){ echo -e "${GREEN}[OK]${RESET} $*"; }
  warn(){ echo -e "${YELLOW}[WARN]${RESET} $*"; }
  die(){ echo -e "${RED}[ERRO]${RESET} $*"; exit 1; }
  print_header(){ echo -e "$LINE"; echo -e "${GREEN}${BOLD} $*${RESET}"; echo -e "$LINE"; }
  print_step(){ echo -e "\n${YELLOW}[$1] $2${RESET}"; }
  backup_file(){ local f="$1"; [[ -f "$f" ]] || return 0; local d="/root/.script-backups"; local r="${f#/}"; local dst="${d}/${r}.bak.$(date +%Y%m%d-%H%M%S)"; mkdir -p "$(dirname "$dst")"; cp -a "$f" "$dst"; }
  confirm(){ local prompt="$1"; local reply; read -rp "$(echo -e "${YELLOW}${prompt} [y/N]: ${RESET}")" reply; [[ "${reply,,}" =~ ^y(es)?$ ]]; }
  require_cmds(){ local cmd; for cmd in "$@"; do command -v "$cmd" >/dev/null 2>&1 || die "Comando em falta: ${cmd}"; done; }
fi

print_header "N5Pro Host Post-Install PRO v1.0"

[[ "$EUID" -eq 0 ]] || die "Corre este script como root."
command -v pveversion >/dev/null 2>&1 || die "Isto não parece ser um host Proxmox."
require_cmds lsblk sgdisk wipefs pvcreate vgcreate lvcreate findmnt apt pvesm grep sed awk curl

N5PRO_REPO_BASE="${N5PRO_REPO_BASE:-https://raw.githubusercontent.com/ForsteriDeaf/N5Pro/main/final}"

PVE_IP="${PVE_IP:-192.168.50.99}"
UNRAID_IP="${UNRAID_IP:-192.168.50.100}"
PBS_IP="${PBS_IP:-192.168.50.110}"
GATEWAY="${GATEWAY:-192.168.50.1}"
BRIDGE="${BRIDGE:-vmbr0}"

UNRAID_MAC="${UNRAID_MAC:-BC:24:11:05:01:00}"
PBS_MAC="${PBS_MAC:-BC:24:11:05:01:10}"

UNRAID_VMID="${UNRAID_VMID:-100}"
PBS_VMID="${PBS_VMID:-110}"

UNRAID_CORES="${UNRAID_CORES:-8}"
UNRAID_MEMORY="${UNRAID_MEMORY:-16384}"
PBS_CORES="${PBS_CORES:-4}"
PBS_MEMORY="${PBS_MEMORY:-8192}"
PBS_SYSTEM_DISK_GB="${PBS_SYSTEM_DISK_GB:-32}"
PBS_ISO_FILE="${PBS_ISO_FILE:-proxmox-backup-server_4.1-1.iso}"

VM_STORAGE="${VM_STORAGE:-NVMe-Containers}"
ISO_STORAGE="${ISO_STORAGE:-local}"

UNRAID_SATA_PCI="${UNRAID_SATA_PCI:-0000:c1:00.0}"
UNRAID_NVME_PCI="${UNRAID_NVME_PCI:-0000:c3:00.0}"
UNRAID_USB_ID="${UNRAID_USB_ID:-04e8:6300}"
PBS_USB_BACKUP_ID="${PBS_USB_BACKUP_ID:-skip}"

PBS_DATASTORE="${PBS_DATASTORE:-usb-temp}"
PBS_DATASTORE_MOUNT="${PBS_DATASTORE_MOUNT:-/mnt/datastore}"
PBS_DATASTORE_FS="${PBS_DATASTORE_FS:-ext4}"
PBS_BACKUP_DEVICE="${PBS_BACKUP_DEVICE:-/dev/sdb}"

ENABLE_IOMMU="${ENABLE_IOMMU:-true}"
REMOVE_LOCAL_LVM_DEFAULT="${REMOVE_LOCAL_LVM_DEFAULT:-false}"
CREATE_NVME_CONTAINERS_DEFAULT="${CREATE_NVME_CONTAINERS_DEFAULT:-true}"

disable_repo_file() {
  local f="$1"
  [[ -e "$f" ]] || return 0
  if [[ -e "${f}.disabled" ]]; then
    rm -f "$f"
    info "Removido duplicado ativo: $f"
  else
    mv "$f" "${f}.disabled"
    info "Desativado: $f"
  fi
}

detect_bootloader() {
  if [[ -d /sys/firmware/efi ]] && command -v proxmox-boot-tool >/dev/null 2>&1 && [[ -f /etc/kernel/cmdline ]]; then
    echo "systemd-boot"
  else
    echo "grub"
  fi
}

detect_cpu_vendor() {
  if grep -qi 'AuthenticAMD' /proc/cpuinfo; then
    echo "amd"
  elif grep -qi 'GenuineIntel' /proc/cpuinfo; then
    echo "intel"
  else
    echo "unknown"
  fi
}

install_common_local() {
  print_step "STEP 0" "Instalar common.sh local"
  mkdir -p /usr/local/lib/n5pro
  if [[ -f "${SCRIPT_DIR}/../lib/common.sh" ]]; then
    cp -a "${SCRIPT_DIR}/../lib/common.sh" /usr/local/lib/n5pro/common.sh
    chmod 644 /usr/local/lib/n5pro/common.sh
    ok "common.sh instalado em /usr/local/lib/n5pro/common.sh"
  else
    warn "common.sh do repo não encontrado; a execução continua com o common já carregado."
  fi
}

write_config() {
  print_step "STEP 8" "Gravar /etc/n5pro.conf"
  backup_file /etc/n5pro.conf
  cat >/etc/n5pro.conf <<EOF
N5PRO_REPO_BASE="${N5PRO_REPO_BASE}"
PVE_IP="${PVE_IP}"
UNRAID_IP="${UNRAID_IP}"
PBS_IP="${PBS_IP}"
GATEWAY="${GATEWAY}"
BRIDGE="${BRIDGE}"
UNRAID_MAC="${UNRAID_MAC}"
PBS_MAC="${PBS_MAC}"
UNRAID_VMID="${UNRAID_VMID}"
PBS_VMID="${PBS_VMID}"
UNRAID_CORES="${UNRAID_CORES}"
UNRAID_MEMORY="${UNRAID_MEMORY}"
PBS_CORES="${PBS_CORES}"
PBS_MEMORY="${PBS_MEMORY}"
PBS_SYSTEM_DISK_GB="${PBS_SYSTEM_DISK_GB}"
PBS_ISO_FILE="${PBS_ISO_FILE}"
VM_STORAGE="${VM_STORAGE}"
ISO_STORAGE="${ISO_STORAGE}"
UNRAID_SATA_PCI="${UNRAID_SATA_PCI}"
UNRAID_NVME_PCI="${UNRAID_NVME_PCI}"
UNRAID_USB_ID="${UNRAID_USB_ID}"
PBS_USB_BACKUP_ID="${PBS_USB_BACKUP_ID}"
PBS_DATASTORE="${PBS_DATASTORE}"
PBS_DATASTORE_MOUNT="${PBS_DATASTORE_MOUNT}"
PBS_DATASTORE_FS="${PBS_DATASTORE_FS}"
PBS_BACKUP_DEVICE="${PBS_BACKUP_DEVICE}"
ENABLE_IOMMU="${ENABLE_IOMMU}"
REMOVE_LOCAL_LVM_DEFAULT="${REMOVE_LOCAL_LVM_DEFAULT}"
CREATE_NVME_CONTAINERS_DEFAULT="${CREATE_NVME_CONTAINERS_DEFAULT}"
EOF
  chmod 600 /etc/n5pro.conf
  ok "/etc/n5pro.conf criado/atualizado."
}

install_runtime() {
  print_step "STEP 9" "Instalar runtime N5Pro"
  if command -v n5pro-update >/dev/null 2>&1; then
    n5pro-update --install
    ok "Runtime instalado com n5pro-update --install"
  else
    warn "n5pro-update não encontrado; instala o runtime com bootstrap/update depois."
  fi
}

configure_repos() {
  print_step "STEP 1" "Configurar repositórios limpos"
  mkdir -p /etc/apt/sources.list.d

  disable_repo_file /etc/apt/sources.list.d/pve-enterprise.list
  disable_repo_file /etc/apt/sources.list.d/pve-enterprise.sources
  disable_repo_file /etc/apt/sources.list.d/ceph.list
  disable_repo_file /etc/apt/sources.list.d/ceph.sources

  rm -f /etc/apt/sources.list.d/pve-no-subscription.list
  rm -f /etc/apt/sources.list.d/pve-no-subscription.sources

  if [[ -f /etc/apt/sources.list.d/debian.sources ]]; then
    backup_file /etc/apt/sources.list.d/debian.sources
    cat >/etc/apt/sources.list.d/debian.sources <<'EOF'
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie trixie-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
    : > /etc/apt/sources.list
    info "debian.sources atualizado."
  fi

  cat >/etc/apt/sources.list.d/pve-no-subscription.sources <<'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

  ok "Repositórios configurados."
}

system_upgrade() {
  print_step "STEP 2" "Atualizar sistema"
  apt update
  apt dist-upgrade -y
  ok "Sistema atualizado."
}

handle_local_lvm() {
  print_step "STEP 3" "Remover local-lvm e expandir root (opcional)"

  if ! pvesm status 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx 'local-lvm'; then
    info "local-lvm não existe; passo ignorado."
    return 0
  fi

  local default_reply="n"
  [[ "${REMOVE_LOCAL_LVM_DEFAULT}" == "true" ]] && default_reply="y"

  read -rp "$(echo -e "${YELLOW}Queres remover local-lvm agora? [default=${default_reply}] [y/N]: ${RESET}")" REMOVE_LVM
  REMOVE_LVM="${REMOVE_LVM:-$default_reply}"

  [[ "${REMOVE_LVM,,}" =~ ^y(es)?$ ]] || { info "local-lvm mantido."; return 0; }

  pvesm remove local-lvm 2>/dev/null || true
  lvremove -f /dev/pve/data 2>/dev/null || true
  lvextend -l +100%FREE /dev/pve/root || true

  local fs root_src
  fs="$(findmnt -n -o FSTYPE /)"
  root_src="$(findmnt -n -o SOURCE /)"

  if [[ "$fs" == "xfs" ]]; then
    xfs_growfs /
  elif [[ "$fs" =~ ^ext(2|3|4)$ ]]; then
    resize2fs "$root_src" || true
  else
    warn "Filesystem do root não suportado automaticamente: ${fs}"
    info "Origem do root: ${root_src}"
  fi

  ok "local-lvm removido e root expandido."
}

create_nvme_storage() {
  print_step "STEP 4" "Criar NVMe-Containers (LVM Thin Pool)"

  [[ "${CREATE_NVME_CONTAINERS_DEFAULT}" == "true" ]] || {
    warn "CREATE_NVME_CONTAINERS_DEFAULT=false -> passo ignorado."
    return 0
  }

  if pvesm status 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "${VM_STORAGE}"; then
    info "Storage ${VM_STORAGE} já existe; passo ignorado."
    return 0
  fi

  echo -e "${BLUE}Discos NVMe disponíveis:${RESET}"
  mapfile -t NVME_DISKS < <(lsblk -d -n -o NAME,SIZE,MODEL | awk '$1 ~ /^nvme/')
  [[ ${#NVME_DISKS[@]} -gt 0 ]] || die "Nenhum disco NVMe encontrado."

  local i
  for i in "${!NVME_DISKS[@]}"; do
    echo "[$i] ${NVME_DISKS[$i]}"
  done

  read -rp "$(echo -e "${CYAN}Seleciona o índice do NVMe para ${VM_STORAGE}: ${RESET}")" DISK_INDEX
  local DISK_NAME DISK
  DISK_NAME="$(echo "${NVME_DISKS[$DISK_INDEX]}" | awk '{print $1}')"
  DISK="/dev/${DISK_NAME}"

  [[ -b "$DISK" ]] || die "Disco inválido: ${DISK}"

  echo -e "${YELLOW}O disco selecionado é: ${DISK}${RESET}"
  confirm "Confirmas apagar este disco para ${VM_STORAGE}?" || die "Operação cancelada."

  pvesm remove "${VM_STORAGE}" 2>/dev/null || true
  lvremove -f "${VM_STORAGE}/thin-pool" 2>/dev/null || true
  vgremove -f "${VM_STORAGE}" 2>/dev/null || true
  pvremove -ff "$DISK" 2>/dev/null || true
  wipefs -a "$DISK"
  sgdisk --zap-all "$DISK"

  pvcreate "$DISK"
  vgcreate "${VM_STORAGE}" "$DISK"
  lvcreate -l 100%FREE -T "${VM_STORAGE}/thin-pool" --chunksize 128K --zero n
  pvesm add lvmthin "${VM_STORAGE}" --vgname "${VM_STORAGE}" --thinpool thin-pool

  ok "${VM_STORAGE} criado em ${DISK}."
}

configure_iommu() {
  print_step "STEP 5" "Ativar IOMMU"

  [[ "${ENABLE_IOMMU}" == "true" ]] || {
    warn "ENABLE_IOMMU=false -> passo ignorado."
    return 0
  }

  local bootloader cpu_vendor iommu_args changed="false"
  bootloader="$(detect_bootloader)"
  cpu_vendor="$(detect_cpu_vendor)"

  info "Bootloader detetado: ${bootloader}"
  info "CPU detetado: ${cpu_vendor}"

  if [[ "$cpu_vendor" == "intel" ]]; then
    iommu_args="intel_iommu=on iommu=pt"
  elif [[ "$cpu_vendor" == "amd" ]]; then
    iommu_args="amd_iommu=on iommu=pt"
  else
    iommu_args="iommu=pt"
  fi

  if [[ "$bootloader" == "systemd-boot" ]]; then
    backup_file /etc/kernel/cmdline
    if ! grep -Eq 'iommu=pt|intel_iommu=on|amd_iommu=on' /etc/kernel/cmdline; then
      sed -i "s/$/ ${iommu_args}/" /etc/kernel/cmdline
      changed="true"
      info "Parâmetros IOMMU adicionados a /etc/kernel/cmdline"
    else
      info "Parâmetros IOMMU já estavam presentes."
    fi
    proxmox-boot-tool refresh || true
  else
    backup_file /etc/default/grub
    if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub; then
      if ! grep -Eq 'iommu=pt|intel_iommu=on|amd_iommu=on' /etc/default/grub; then
        sed -i "s/^\(GRUB_CMDLINE_LINUX_DEFAULT=\".*\)\"/\1 ${iommu_args}\"/" /etc/default/grub
        changed="true"
      fi
    else
      echo "GRUB_CMDLINE_LINUX_DEFAULT=\"quiet ${iommu_args}\"" >> /etc/default/grub
      changed="true"
    fi
    update-grub || true
  fi

  cat >/etc/modules-load.d/vfio.conf <<'EOF'
vfio
vfio_iommu_type1
vfio_pci
EOF

  update-initramfs -u -k all || true

  if [[ "$changed" == "true" ]]; then
    ok "IOMMU preparada. Reboot recomendado."
  else
    ok "IOMMU já estava configurada."
  fi
}

configure_timezone() {
  print_step "STEP 5.1" "Confirmar timezone"
  local current_tz
  current_tz="$(timedatectl show -p Timezone --value 2>/dev/null || true)"

  if [[ -z "$current_tz" ]]; then
    warn "Não foi possível detetar o timezone atual."
    return 0
  fi

  info "Timezone atual detetado: ${current_tz}"
  read -rp "$(echo -e "${YELLOW}Manter este timezone? [Y/n]: ${RESET}")" KEEP_TZ

  if [[ ! "${KEEP_TZ,,}" =~ ^n(o)?$ ]]; then
    ok "Timezone mantido: ${current_tz}"
    return 0
  fi

  read -rp "$(echo -e "${CYAN}Introduz o timezone pretendido (ex: Europe/Lisbon, Atlantic/Azores): ${RESET}")" NEW_TZ
  if timedatectl list-timezones | grep -qx "$NEW_TZ"; then
    timedatectl set-timezone "$NEW_TZ"
    ok "Timezone alterado para: ${NEW_TZ}"
  else
    die "Timezone inválido: ${NEW_TZ}"
  fi
}

install_packages() {
  print_step "STEP 6" "Instalar firmware e ferramentas essenciais"
  apt install -y \
    amd64-microcode \
    pve-firmware \
    fastfetch \
    btop \
    iotop \
    iftop \
    htop \
    unzip \
    zip \
    dos2unix \
    etherwake \
    nvme-cli \
    pciutils \
    usbutils \
    curl \
    wget \
    git \
    jq \
    tree \
    vim \
    nano \
    mc \
    lsof \
    rsync \
    nfs-common \
    smartmontools \
    sshpass \
    ethtool
  ok "Ferramentas instaladas."
}

configure_bash() {
  print_step "STEP 7" "Configurar Bash com cores"
  backup_file /root/.bashrc
  cat <<'EOF' > /root/.bashrc
export TERM=xterm-256color
PS1='\[\033[38;5;196m\]\u\[\033[38;5;10m\]@\[\033[38;5;11m\]\h\[\033[00m\]:\[\033[38;5;21m\]\w\[\033[38;5;11m\]\$\[\033[00m\] '
alias ll='ls -la --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias btop='btop --utf-force'
EOF
  ok "Bash configurado."
}

install_common_local
configure_repos
system_upgrade
handle_local_lvm
create_nvme_storage
configure_iommu
configure_timezone
install_packages
configure_bash
write_config
install_runtime

echo -e "\n$LINE"
echo -e "${GREEN}${BOLD}✅ Host post-install concluído.${RESET}"
echo -e "${CYAN}Repo base guardado em /etc/n5pro.conf:${RESET} ${N5PRO_REPO_BASE}"
echo -e "${YELLOW}${BOLD}REBOOT RECOMENDADO${RESET}"
echo -e "${GREEN}Depois do reboot, corre: n5pro${RESET}"
echo -e "${GREEN}Depois usa: n5pro-post${RESET}"
echo -e "$LINE"
