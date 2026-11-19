# Jarvis — gestor de tráfego IA

Agente que monitora as campanhas Meta Ads via UTMify 24h, analisa com IA e manda alertas no WhatsApp (Evolution API).

## Setup da VPS (AlmaLinux 9)

No console do servidor, rodar (só minúsculas, funciona no console web):

```
curl -fso s.sh --location raw.githubusercontent.com/anajulia4240-ux/jarvis/main/setup.sh; bash s.sh
```

O script instala: swap 2 GB, atualizações, firewall, fail2ban, atualizações automáticas de segurança, Node 20 e PM2.
Nenhuma chave/senha fica neste repositório — elas ficam só no `.env` dentro do servidor.
