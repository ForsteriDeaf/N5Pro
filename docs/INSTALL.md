# Installation

## Requisitos

- Proxmox VE instalado
- Acesso root
- Ligação à internet

---

## Clone do repositório

cd /opt
git clone https://github.com/ForsteriDeaf/N5Pro.git n5pro
cd /opt/n5pro

---

## Instalação base do runtime

mkdir -p /usr/local/lib/n5pro

cp final/lib/common.sh /usr/local/lib/n5pro/common.sh
cp final/runtime/n5pro-update /usr/local/bin/n5pro-update

chmod 644 /usr/local/lib/n5pro/common.sh
chmod +x /usr/local/bin/n5pro-update

---

## Instalar sistema completo

n5pro-update --install

---

## Validação

n5pro-update --check
n5pro-update --self-check
n5pro-update --doctor

---

## Primeira execução

n5pro

---

## Problemas comuns

### common.sh não encontrado

cp final/lib/common.sh /usr/local/lib/n5pro/common.sh

### n5pro-update não existe

cp final/runtime/n5pro-update /usr/local/bin/
chmod +x /usr/local/bin/n5pro-update

---

## Notas

Runtime instalado em:
/usr/local/bin
/usr/local/lib/n5pro

Repositório em:
/opt/n5pro
