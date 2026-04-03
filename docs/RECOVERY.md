# Recovery

Guia de recuperação do N5Pro em caso de falha, reinstalação ou perda de runtime.

---

## Cenários comuns

- Perda de binários em /usr/local/bin
- common.sh removido ou corrompido
- Repo /opt/n5pro intacto mas runtime quebrado
- Sistema reinstalado (Proxmox novo)
- Erro após update

---

## Recovery rápido (runtime)

Se o repo ainda existe em /opt/n5pro:

cd /opt/n5pro

cp final/lib/common.sh /usr/local/lib/n5pro/common.sh
cp final/runtime/n5pro-update /usr/local/bin/n5pro-update

chmod 644 /usr/local/lib/n5pro/common.sh
chmod +x /usr/local/bin/n5pro-update

n5pro-update --install

---

## Validar recuperação

n5pro-update --self-check
n5pro-update --doctor

---

## Recovery completo (do zero)

Se o sistema foi reinstalado:

cd /opt
git clone https://github.com/ForsteriDeaf/N5Pro.git n5pro
cd /opt/n5pro

mkdir -p /usr/local/lib/n5pro

cp final/lib/common.sh /usr/local/lib/n5pro/common.sh
cp final/runtime/n5pro-update /usr/local/bin/n5pro-update

chmod 644 /usr/local/lib/n5pro/common.sh
chmod +x /usr/local/bin/n5pro-update

n5pro-update --install

---

## Recuperar configuração

Se existir backup de /etc/n5pro.conf:

cp backup/n5pro.conf /etc/n5pro.conf

Caso contrário:
executar novamente o setup via n5pro

---

## Diagnóstico

n5pro-update --doctor

---

## Logs

Ver logs do sistema:
/var/log/
/root/

---

## Notas importantes

- /opt/n5pro é a fonte de verdade
- runtime pode ser recriado a qualquer momento
- backups são guardados em:
  /root/.n5pro-update-backups

---

## Regra de ouro

Se algo falhar:

1. garantir repo OK
2. reinstalar runtime
3. correr doctor

Nunca editar manualmente /usr/local/bin sem atualizar o repo
