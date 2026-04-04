#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${N5PRO_REPO_URL:-https://github.com/ForsteriDeaf/N5Pro.git}"
REPO_DIR="${N5PRO_REPO_DIR:-/opt/n5pro}"
BRANCH="${N5PRO_BRANCH:-main}"

RED="\033[38;5;196m"
GREEN="\033[38;5;10m"
YELLOW="\033[38;5;11m"
CYAN="\033[38;5;14m"
MAGENTA="\033[38;5;13m"
BOLD="\033[1m"
RESET="\033[0m"
LINE="==========================================================="

info(){ echo -e "${CYAN}[INFO]${RESET} $*"; }
ok(){ echo -e "${GREEN}[OK]${RESET} $*"; }
warn(){ echo -e "${YELLOW}[WARN]${RESET} $*"; }
die(){ echo -e "${RED}[ERRO]${RESET} $*"; exit 1; }

print_header() {
  echo -e "$LINE"
  echo -e "${GREEN}${BOLD} $*${RESET}"
  echo -e "$LINE"
}

require_root() {
  [[ "${EUID}" -eq 0 ]] || die "Corre este bootstrap como root."
}

require_proxmox_host() {
  command -v pveversion >/dev/null 2>&1 || die "Este bootstrap é para correr num host Proxmox."
}

confirm() {
  local prompt="$1"
  local reply
  read -rp "$(echo -e "${YELLOW}${prompt} [y/N]: ${RESET}")" reply
  [[ "${reply,,}" =~ ^y(es)?$ ]]
}

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

prepare_repos() {
  info "Preparar repositórios base..."

  mkdir -p /etc/apt/sources.list.d

  disable_repo_file /etc/apt/sources.list.d/pve-enterprise.list
  disable_repo_file /etc/apt/sources.list.d/pve-enterprise.sources
  disable_repo_file /etc/apt/sources.list.d/ceph.list
  disable_repo_file /etc/apt/sources.list.d/ceph.sources

  rm -f /etc/apt/sources.list.d/pve-no-subscription.list
  rm -f /etc/apt/sources.list.d/pve-no-subscription.sources

  cat >/etc/apt/sources.list.d/pve-no-subscription.sources <<'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

  ok "Repositórios preparados."
}

install_base_packages() {
  info "Instalar dependências base..."
  apt update
  apt install -y git curl ca-certificates
  ok "Dependências base instaladas."
}

git_repo_exists() {
  [[ -d "${REPO_DIR}/.git" ]]
}

show_repo_status() {
  cd "$REPO_DIR"

  local branch local_head remote_head dirty_count dirty_status
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  local_head="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
  dirty_count="$(git status --porcelain 2>/dev/null | sed '/^$/d' | wc -l | tr -d ' ')"

  if [[ "${dirty_count}" != "0" ]]; then
    dirty_status="DIRTY (${dirty_count} alterações)"
  else
    dirty_status="CLEAN"
  fi

  git fetch origin "$BRANCH" >/dev/null 2>&1 || true
  remote_head="$(git rev-parse --short "origin/${BRANCH}" 2>/dev/null || echo unknown)"

  echo -e "$LINE"
  echo -e "${MAGENTA}${BOLD} Estado do repo existente ${RESET}"
  echo -e "$LINE"
  echo "Repo       : ${REPO_DIR}"
  echo "Branch     : ${branch}"
  echo "Local HEAD : ${local_head}"
  echo "Remote HEAD: ${remote_head}"
  echo "Estado     : ${dirty_status}"

  if [[ "$local_head" == "$remote_head" ]]; then
    echo "Comparação : Local já está alinhado com origin/${BRANCH}"
  elif [[ "$remote_head" == "unknown" ]]; then
    echo "Comparação : Não foi possível obter o HEAD remoto"
  else
    echo "Comparação : Local difere de origin/${BRANCH}"
  fi
  echo -e "$LINE"
}

clone_repo_fresh() {
  info "Clonar repo para $REPO_DIR ..."
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone -b "$BRANCH" "$REPO_URL" "$REPO_DIR"
  ok "Repo clonado."
}

update_existing_repo() {
  cd "$REPO_DIR"

  local dirty
  dirty="$(git status --porcelain 2>/dev/null || true)"

  if [[ -n "$dirty" ]]; then
    warn "O repo tem alterações locais."
    warn "Atualização automática cancelada para proteger o trabalho local."
    return 1
  fi

  info "Atualizar repo existente..."
  git fetch origin
  git checkout "$BRANCH"
  git pull --rebase origin "$BRANCH"
  ok "Repo atualizado."
}

reinstall_repo_clean() {
  warn "Reinstalação limpa selecionada."
  rm -rf "$REPO_DIR"
  clone_repo_fresh
}

choose_repo_action() {
  if ! git_repo_exists; then
    clone_repo_fresh
    return 0
  fi

  show_repo_status

  while true; do
    echo "Escolhe uma ação:"
    echo "1) Manter repo local atual"
    echo "2) Atualizar repo existente"
    echo "3) Reinstalar repo limpo"
    echo "0) Sair"
    read -rp "Escolha: " opt

    case "$opt" in
      1)
        info "Repo local mantido."
        return 0
        ;;
      2)
        update_existing_repo && return 0
        warn "Repo não foi atualizado."
        if confirm "Queres voltar ao menu de opções do repo?"; then
          continue
        else
          return 0
        fi
        ;;
      3)
        if confirm "Isto vai apagar ${REPO_DIR}. Continuar"; then
          reinstall_repo_clean
          return 0
        fi
        ;;
      0)
        die "Bootstrap cancelado pelo utilizador."
        ;;
      *)
        warn "Opção inválida."
        ;;
    esac
  done
}

install_runtime_symlinks() {
  info "Criar symlinks do runtime..."

  [[ -f "$REPO_DIR/final/lib/common.sh" ]] || die "Falta $REPO_DIR/final/lib/common.sh"
  [[ -f "$REPO_DIR/final/runtime/n5pro-update" ]] || die "Falta $REPO_DIR/final/runtime/n5pro-update"

  mkdir -p /usr/local/lib/n5pro
  mkdir -p /usr/local/bin

  local f
  for f in n5pro n5pro-post n5pro-update n5pro-doctor; do
    if [[ -f "$REPO_DIR/final/runtime/$f" ]]; then
      rm -f "/usr/local/bin/$f"
      ln -s "$REPO_DIR/final/runtime/$f" "/usr/local/bin/$f"
      chmod +x "$REPO_DIR/final/runtime/$f"
      ok "Ligado: $f"
    else
      warn "Runtime core em falta no repo: $f"
    fi
  done

  rm -f /usr/local/lib/n5pro/common.sh
  ln -s "$REPO_DIR/final/lib/common.sh" /usr/local/lib/n5pro/common.sh
  chmod 644 "$REPO_DIR/final/lib/common.sh"
  ok "Ligado: common.sh"

  if [[ -f "$REPO_DIR/final/runtime/VERSION" ]]; then
    rm -f /usr/local/lib/n5pro/VERSION
    ln -s "$REPO_DIR/final/runtime/VERSION" /usr/local/lib/n5pro/VERSION
    ok "Ligado: VERSION (runtime)"
  elif [[ -f "$REPO_DIR/VERSION" ]]; then
    rm -f /usr/local/lib/n5pro/VERSION
    ln -s "$REPO_DIR/VERSION" /usr/local/lib/n5pro/VERSION
    ok "Ligado: VERSION (repo)"
  else
    warn "VERSION não encontrado no repo."
  fi
}

run_full_install() {
  info "Executar instalação completa..."
  /usr/local/bin/n5pro-update --install
  ok "Instalação completa concluída."
}

run_validation() {
  info "Validar instalação..."
  /usr/local/bin/n5pro-update --self-check
  /usr/local/bin/n5pro-update --doctor
  ok "Validação concluída."
}

show_next_steps() {
  echo -e "$LINE"
  ok "Bootstrap automático concluído."
  echo
  echo "Próximos comandos úteis:"
  echo "  n5pro"
  echo "  n5pro-post"
  echo "  n5pro-update --self-check"
  echo "  n5pro-update --doctor"
  echo -e "$LINE"
}

main() {
  print_header "N5Pro Bootstrap"
  require_root
  require_proxmox_host
  prepare_repos
  install_base_packages
  choose_repo_action
  install_runtime_symlinks
  run_full_install
  run_validation
  show_next_steps
}

main "$@"
