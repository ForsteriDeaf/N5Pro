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
  [[ "$EUID" -eq 0 ]] || die "Corre este bootstrap como root."
}

install_base_packages() {
  info "Instalar dependências base..."
  apt update
  apt install -y git curl ca-certificates
  ok "Dependências base instaladas."
}

clone_or_update_repo() {
  if [[ -d "$REPO_DIR/.git" ]]; then
    info "Repo já existe em $REPO_DIR"

    cd "$REPO_DIR"

    if [[ -n "$(git status --porcelain 2>/dev/null || true)" ]]; then
      warn "O repo já existe mas tem alterações locais."
      warn "Bootstrap automático não vai fazer reset para evitar perder trabalho."
      warn "Se queres reinstalação limpa, apaga $REPO_DIR e corre novamente."
      return 0
    fi

    info "Atualizar repo existente..."
    git fetch origin
    git checkout "$BRANCH"
    git pull --rebase origin "$BRANCH"
    ok "Repo atualizado."
  else
    info "Clonar repo para $REPO_DIR ..."
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone -b "$BRANCH" "$REPO_URL" "$REPO_DIR"
    ok "Repo clonado."
  fi
}

install_min_runtime() {
  info "Instalar runtime mínimo..."

  [[ -f "$REPO_DIR/final/lib/common.sh" ]] || die "Falta $REPO_DIR/final/lib/common.sh"
  [[ -f "$REPO_DIR/final/runtime/n5pro-update" ]] || die "Falta $REPO_DIR/final/runtime/n5pro-update"

  mkdir -p /usr/local/lib/n5pro
  mkdir -p /usr/local/bin

  cp "$REPO_DIR/final/lib/common.sh" /usr/local/lib/n5pro/common.sh
  chmod 644 /usr/local/lib/n5pro/common.sh

  cp "$REPO_DIR/final/runtime/n5pro-update" /usr/local/bin/n5pro-update
  chmod +x /usr/local/bin/n5pro-update

  ok "Runtime mínimo instalado."
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
  echo "  n5pro-update --self-check"
  echo "  n5pro-update --doctor"
  echo -e "$LINE"
}

main() {
  print_header "N5Pro Bootstrap"
  require_root
  install_base_packages
  clone_or_update_repo
  install_min_runtime
  run_full_install
  run_validation
  show_next_steps
}

main "$@"
