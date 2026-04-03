# Runtime

O runtime N5Pro é o conjunto de ferramentas instaladas no sistema para operação diária.

---

## Localização

/usr/local/bin        → comandos
/usr/local/lib/n5pro  → common.sh + VERSION
/etc/n5pro.conf       → configuração

---

## Runtime core

n5pro           → dashboard principal
n5pro-update    → sistema de update
n5pro-doctor    → diagnóstico
n5pro-post      → wizard operacional

---

## Runtime auxiliar

n5pro-backup
n5pro-bootstrap-pbs
n5pro-cron
n5pro-heal
n5pro-log
n5pro-repo-safe
n5pro-ssh-setup-pbs
n5pro-version

---

## Biblioteca

common.sh

Local:
/usr/local/lib/n5pro/common.sh

Funções:
- logging
- validações
- helpers
- locks
- config loader

---

## Configuração

Ficheiro:
/etc/n5pro.conf

Contém:
- IPs
- storage
- paths
- parâmetros de runtime

---

## Instalação do runtime

n5pro-update --install

---

## Verificação

n5pro-update --self-check

---

## Diagnóstico

n5pro-update --doctor

---

## Notas

- runtime é idempotente
- pode ser reinstalado sem risco
- valida estrutura automaticamente
- suporta tools opcionais
