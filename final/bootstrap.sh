#!/usr/bin/env bash

set -e

REPO_BASE="https://raw.githubusercontent.com/ForsteriDeaf/N5Pro/main/final"
RUNTIME_BASE="${REPO_BASE}/runtime"

echo "[INFO] N5Pro Bootstrap iniciado..."

# criar pasta temporária
TMP_DIR="/tmp/n5pro-bootstrap"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

echo "[INFO] Download dos binários..."

FILES=(
    n5pro
    n5pro-post
    n5pro-doctor
    n5pro-update
    n5pro-backup
    n5pro-version
    n5pro-bootstrap-pbs
    n5pro-repo-safe
)

# download
for f in "${FILES[@]}"; do
    curl --fail --silent --show-error --location --retry 3 -o "$f" "${RUNTIME_BASE}/${f}"
    chmod +x "$f"
done

# validação
for f in "${FILES[@]}"; do
    if [[ ! -f "$f" ]]; then
        echo "[ERRO] Falhou download de $f"
        exit 1
    fi
done

echo "[INFO] Instalar em /usr/local/bin..."

for f in "${FILES[@]}"; do
    cp "$f" /usr/local/bin/
done

echo "[INFO] Criar config base (se não existir)..."

if [[ ! -f /etc/n5pro.conf ]]; then
    cat > /etc/n5pro.conf <<EOF
N5PRO_REPO_BASE="${REPO_BASE}"
EOF
    echo "[OK] /etc/n5pro.conf criado"
else
    echo "[INFO] /etc/n5pro.conf já existe, mantido."
fi

echo "[OK] Bootstrap concluído!"
echo
echo "👉 Executa: n5pro"
