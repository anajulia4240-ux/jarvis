#!/usr/bin/env bash
# =============================================================
#  Jarvis - setup inicial da VPS (AlmaLinux 9)
#  Seguro rodar mais de uma vez (idempotente).
#  Uso no servidor:  bash setup.sh
# =============================================================
set -euo pipefail

LOG=/root/jarvis-setup.log
exec > >(tee -a "$LOG") 2>&1

ok()   { echo -e "\n\033[1;32m[OK]\033[0m $*"; }
step() { echo -e "\n\033[1;36m==> $*\033[0m"; }

SSH_PORT=22022

# -------------------------------------------------------------
step "1/6  Swap de 2 GB (memoria reserva no disco)"
# -------------------------------------------------------------
if ! swapon --show | grep -q /swapfile; then
  dd if=/dev/zero of=/swapfile bs=1M count=2048 status=none
  chmod 600 /swapfile
  mkswap /swapfile >/dev/null
  swapon /swapfile
fi
grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
# usa swap so quando a RAM estiver quase cheia
sysctl -q vm.swappiness=10
grep -q '^vm.swappiness' /etc/sysctl.conf || echo 'vm.swappiness=10' >> /etc/sysctl.conf
ok "Swap ativo: $(swapon --show --noheadings | awk '{print $3}')"

# -------------------------------------------------------------
step "2/6  Atualizando o sistema"
# -------------------------------------------------------------
dnf -y -q update
dnf -y -q install epel-release
dnf -y -q install git curl wget nano htop tar firewalld fail2ban dnf-automatic
ok "Sistema atualizado"

# -------------------------------------------------------------
step "3/6  Firewall (libera so SSH, web e HTTPS)"
# -------------------------------------------------------------
systemctl enable --now firewalld
firewall-cmd -q --permanent --add-port=${SSH_PORT}/tcp
firewall-cmd -q --permanent --add-service=ssh
firewall-cmd -q --permanent --add-service=http
firewall-cmd -q --permanent --add-service=https
firewall-cmd -q --reload
# o Docker precisa ser reiniciado depois do firewalld subir
systemctl restart docker
ok "Firewall ativo: $(firewall-cmd --list-ports) $(firewall-cmd --list-services)"

# -------------------------------------------------------------
step "4/6  Fail2ban (bloqueia quem erra a senha do SSH varias vezes)"
# -------------------------------------------------------------
cat > /etc/fail2ban/jail.local <<EOF
[sshd]
enabled  = true
port     = ${SSH_PORT}
maxretry = 5
findtime = 10m
bantime  = 1h
EOF
systemctl enable --now fail2ban
systemctl restart fail2ban
ok "Fail2ban ativo"

# -------------------------------------------------------------
step "5/6  Atualizacoes de seguranca automaticas"
# -------------------------------------------------------------
sed -i 's/^upgrade_type.*/upgrade_type = security/' /etc/dnf/automatic.conf
sed -i 's/^apply_updates.*/apply_updates = yes/' /etc/dnf/automatic.conf
systemctl enable --now dnf-automatic.timer
ok "Atualizacoes de seguranca automaticas ligadas"

# -------------------------------------------------------------
step "6/6  Node.js 20 + PM2 (roda o Jarvis 24h)"
# -------------------------------------------------------------
if ! command -v node >/dev/null || ! node -v | grep -q '^v2[0-9]'; then
  dnf -y -q module reset nodejs || true
  dnf -y -q module enable nodejs:20
  dnf -y -q install nodejs
fi
command -v pm2 >/dev/null || npm install -g pm2 --silent
pm2 startup systemd -u root --hp /root >/dev/null 2>&1 || true
ok "Node $(node -v) | PM2 $(pm2 -v)"

# -------------------------------------------------------------
echo
echo "============================================================"
echo "  SETUP CONCLUIDO"
echo "============================================================"
free -h | head -3
echo
docker ps --format 'table {{.Names}}\t{{.Status}}'
echo
echo "Log completo em: $LOG"
