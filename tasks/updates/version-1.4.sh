#!/bin/bash
# ⚠️ DESCONTINUADO (19/09/2026) — modo de instalação Linux/Raspberry Pi /
# Orange Pi. Sem manutenção real desde 2023, sem evidência de nenhum device
# vivo em produção hoje. O parque atual roda no app Android `corpflix`
# (repo denoww/corpflix) ou, como frota legada ainda viva, em Windows via
# Chrome kiosk (ver README § "Config windows" — esse SIM continua em uso,
# ~30 TVs, e o Chrome dele se autoatualiza sozinho, sem ação necessária).
# Contexto completo: ROADMAP_dependencias_criticas.md item #26 (repo
# seucondominio).

# aumentando tamanho da memoria swap
echo -e "CONF_SWAPSIZE=1024" | sudo /usr/bin/tee /etc/dphys-swapfile
sudo /etc/init.d/dphys-swapfile restart

# configurando crontab para reiniciar de o player desligar
sudo /bin/cp /var/lib/midia_indoor_player/device_configs/crontab-sc-player /etc/cron.d/
sudo /bin/chown root:root /etc/cron.d/crontab-sc-player

# removendo inicio automatico pelo lxde (cron vai iniciar o player)
sudo /bin/cp /var/lib/midia_indoor_player/device_configs/lxde-autostart /etc/xdg/lxsession/LXDE-pi/autostart
