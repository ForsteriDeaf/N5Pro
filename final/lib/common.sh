#!/usr/bin/env bash
# ===========================================================
# common.sh
# Helpers partilhados para o N5Pro
# ===========================================================

N5PRO_CONFIG_FILE="/etc/n5pro.conf"
N5PRO_LIB_DIR="/usr/local/lib/n5pro"
N5PRO_BIN_DIR="/usr/local/bin"
N5PRO_LOG_DIR="/var/log/n5pro"
N5PRO_LOG_FILE="${N5PRO_LOG_DIR}/n5pro.log"
N5PRO_BACKUP_DIR="/root/.n5pro-update-backups"

LINE="==========================================================="
CYAN="\033[38;5;14m"
MAGENTA="\033[38;5;13m"
BLUE="\033[38;5;21m"
GREEN="\033[38;5;10m"
YELLOW="\033[38;5;11m"
RED="\033[38;5;196m"
RESET="\033[0m"
BOLD="\033[1m"

info()       { echo -e "${CYAN}[INFO]${RESET} $*"; }
ok()         { echo -e "${GREEN}[OK]${RESET} $*"; }
warn()       { echo -e "${YELLOW}[WARN]${RESET} $*"; }
die()        { echo -e "${RED}[ERRO]${RESET} $*"; exit 1; }

section()    { echo -e "${MAGENTA}$1${RESET}"; }
check_line() { echo -e "${BLUE}[CHECK]${RESET} $1"; }
ok_line()    { echo -e "${GREEN}[OK]${RESET} $1"; }
warn_line()  { echo -e "${YELLOW}[WARN]${RESET} $1"; }
fail_line()  { echo -e "${RED}[FAIL]${RESET} $1"; }
issue_line() { echo -e "${YELLOW}[ISSUE]${RESET} $1"; }
fixed_line() { echo -e "${GREEN}[FIXED]${RESET} $1"; }
pending_line(){ echo -e "${MAGENTA}[PENDING]${RESET} $1"; }

print_header() {
  echo -e "$LINE"
  echo -e "${GREEN}${BOLD} $*${RESET}"
  echo -e "$LINE"
}

print_step() {
  echo -e "\n${YELLOW}[$1] $2${RESET}"
}

confirm() {
  local prompt="$1"
  local reply
  read -rp "$(echo -e "${YELLOW}${prompt} [y/N]: ${RESET}")" reply
  [[ "${reply,,}" =~ ^y(es)?$ ]]
}

ask_default() {
  local prompt="$1"
  local default="$2"
  local reply

  if [[ "${AUTO_MODE:-false}" == "true" ]]; then
    echo "$default"
    return 0
  fi

  read -rp "${prompt} [${default}]: " reply
  echo "${reply:-$default}"
}

require_cmds() {
  local cmd
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || die "Comando em falta: ${cmd}"
  done
}

need_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || warn "Comando não encontrado: ${cmd}"
}

backup_file() {
  local f="$1"
  [[ -f "$f" ]] || return 0

  local d="/root/.script-backups"
  local r="${f#/}"
  local dst="${d}/${r}.bak.$(date +%Y%m%d-%H%M%S)"

  mkdir -p "$(dirname "$dst")"
  cp -a "$f" "$dst"
}

acquire_lock() {
  local lock_name="${1:-n5pro.lock}"
  local lock_file="/tmp/${lock_name}"

  exec 9>"$lock_file"
  flock -n 9 || die "Outro processo já está em execução: ${lock_file}"
}

load_n5pro_config() {
  if [[ -f "$N5PRO_CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$N5PRO_CONFIG_FILE"
  fi

  : "${N5PRO_REPO_BASE:=https://raw.githubusercontent.com/ForsteriDeaf/N5Pro/main/final}"
  : "${REPO_ROOT:=/opt/n5pro}"

  : "${PVE_IP:=192.168.50.99}"
  : "${PBS_IP:=192.168.50.110}"
  : "${UNRAID_IP:=192.168.50.100}"
  : "${GATEWAY:=192.168.50.1}"
  : "${BRIDGE:=vmbr0}"

  : "${UNRAID_VMID:=100}"
  : "${PBS_VMID:=110}"

  : "${UNRAID_MAC:=BC:24:11:05:01:00}"
  : "${PBS_MAC:=BC:24:11:05:01:10}"

  : "${VM_STORAGE:=NVMe-Containers}"
  : "${ISO_STORAGE:=local}"

  : "${PBS_DATASTORE:=usb-temp}"
  : "${PBS_DATASTORE_MOUNT:=/mnt/datastore}"
  : "${PBS_BACKUP_DEVICE:=/dev/sdb}"
  : "${PBS_ISO_FILE:=proxmox-backup-server_4.1-1.iso}"

  : "${ENABLE_IOMMU:=true}"
  : "${REMOVE_LOCAL_LVM_DEFAULT:=false}"
  : "${CREATE_NVME_CONTAINERS_DEFAULT:=true}"
}

save_n5pro_config() {
  mkdir -p "$(dirname "$N5PRO_CONFIG_FILE")"

  cat > "$N5PRO_CONFIG_FILE" <<EOF
N5PRO_REPO_BASE="${N5PRO_REPO_BASE}"
REPO_ROOT="${REPO_ROOT}"

PVE_IP="${PVE_IP}"
PBS_IP="${PBS_IP}"
UNRAID_IP="${UNRAID_IP}"
GATEWAY="${GATEWAY}"
BRIDGE="${BRIDGE}"

UNRAID_VMID="${UNRAID_VMID}"
PBS_VMID="${PBS_VMID}"

UNRAID_MAC="${UNRAID_MAC}"
PBS_MAC="${PBS_MAC}"

VM_STORAGE="${VM_STORAGE}"
ISO_STORAGE="${ISO_STORAGE}"

PBS_DATASTORE="${PBS_DATASTORE}"
PBS_DATASTORE_MOUNT="${PBS_DATASTORE_MOUNT}"
PBS_BACKUP_DEVICE="${PBS_BACKUP_DEVICE}"
PBS_ISO_FILE="${PBS_ISO_FILE}"

ENABLE_IOMMU="${ENABLE_IOMMU}"
REMOVE_LOCAL_LVM_DEFAULT="${REMOVE_LOCAL_LVM_DEFAULT}"
CREATE_NVME_CONTAINERS_DEFAULT="${CREATE_NVME_CONTAINERS_DEFAULT}"
EOF

  chmod 600 "$N5PRO_CONFIG_FILE"
}

hybrid_source_common() {
  local caller_dir
  caller_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"

  if [[ -f /usr/local/lib/n5pro/common.sh ]]; then
    # shellcheck disable=SC1091
    source /usr/local/lib/n5pro/common.sh
  elif [[ -f "${caller_dir}/../lib/common.sh" ]]; then
    # shellcheck disable=SC1091
    source "${caller_dir}/../lib/common.sh"
  elif [[ -f "${caller_dir}/lib/common.sh" ]]; then
    # shellcheck disable=SC1091
    source "${caller_dir}/lib/common.sh"
  elif [[ -f "${caller_dir}/common.sh" ]]; then
    # shellcheck disable=SC1091
    source "${caller_dir}/common.sh"
  else
    echo "[ERRO] common.sh não encontrado." >&2
    exit 1
  fi
}
