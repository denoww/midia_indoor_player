# #!/bin/bash
# ⚠️ DESCONTINUADO (19/09/2026) — modo de instalação Linux/Raspberry Pi /
# Orange Pi. Sem manutenção real desde 2023, sem evidência de nenhum device
# vivo em produção hoje. O parque atual roda no app Android `corpflix`
# (repo denoww/corpflix) ou, como frota legada ainda viva, em Windows via
# Chrome kiosk (ver README § "Config windows" — esse SIM continua em uso,
# ~30 TVs, e o Chrome dele se autoatualiza sozinho, sem ação necessária).
# Contexto completo: ROADMAP_dependencias_criticas.md item #26 (repo
# seucondominio).
# # cd /var/lib/midia_indoor_player/
# # > cron.log # reseta arquivo de logs para economizar espaço

# # atualiza o npm
# # sudo npm install -g npm

# # apaga as imagens antigas dos feeds
# /usr/bin/npm run apagar_arquivos_antigos
# sleep 2

# # atualiza o repositorio
# /var/lib/midia_indoor_player/tasks/./update_repository.sh

# # atualizar chrome
# sudo apt-get update -y
# sudo apt --only-upgrade -y install chromium-browser

# /var/lib/midia_indoor_player/tasks/./init.sh
# # reinicia o equipamento
# # sudo /sbin/reboot
# # /sbin/reboot
