# Architecture

Visão geral da arquitetura do N5Pro.

---

## Estrutura base

O projeto é dividido em três camadas principais:

1. Repositório (source of truth)
2. Runtime (binários instalados)
3. Sistema (Proxmox + VMs)

---

## 1. Repositório

Local:
/opt/n5pro

Contém:
- scripts finais (final/)
- documentação (docs/)
- código legacy (legacy/)

---

## 2. Runtime

Instalado em:
/usr/local/bin
/usr/local/lib/n5pro

Componentes:

Core:
- n5pro
- n5pro-update
- n5pro-doctor
- n5pro-post

Auxiliares:
- n5pro-backup
- n5pro-bootstrap-pbs
- n5pro-cron
- n5pro-heal
- n5pro-log
- n5pro-repo-safe
- n5pro-ssh-setup-pbs
- n5pro-version

---

## 3. Configuração

Ficheiro:
/etc/n5pro.conf

Define:
- rede (IPs)
- storage
- paths
- parâmetros de runtime

---

## 4. Fluxo de funcionamento

1. Repo é atualizado (git)
2. n5pro-update valida estrutura
3. Backup automático é criado
4. Runtime é instalado/atualizado
5. Self-check valida integridade
6. Doctor valida sistema

---

## 5. Filosofia

- Repo = fonte única de verdade
- Runtime = descartável e regenerável
- Sistema = configurado via scripts

---

## 6. Segurança

- backups automáticos antes de update
- validação de sintaxe antes de instalar
- proteção contra overwrite com repo sujo
- comandos idempotentes

---

## 7. Recovery model

Se falhar:

1. garantir repo em /opt/n5pro
2. reinstalar runtime
3. validar com doctor

---

## 8. Separação de responsabilidades

Repo:
- código
- scripts
- docs

Runtime:
- execução
- CLI
- operações

Sistema:
- VMs
- storage
- rede

---

## 9. Estado atual

- arquitetura estável
- runtime modular
- update system funcional
- pronto para produção
