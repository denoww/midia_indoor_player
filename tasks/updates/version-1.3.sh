#!/bin/bash
# ⚠️ DESCONTINUADO (19/09/2026) — modo de instalação Linux/Raspberry Pi /
# Orange Pi. Sem manutenção real desde 2023, sem evidência de nenhum device
# vivo em produção hoje. O parque atual roda no app Android `corpflix`
# (repo denoww/corpflix) ou, como frota legada ainda viva, em Windows via
# Chrome kiosk (ver README § "Config windows" — esse SIM continua em uso,
# ~30 TVs, e o Chrome dele se autoatualiza sozinho, sem ação necessária).
# Contexto completo: ROADMAP_dependencias_criticas.md item #26 (repo
# seucondominio).

# atualizando midia_indoor_update_diario
sudo /bin/cp /var/lib/midia_indoor_player/device_configs/midia_indoor_update_diario /etc/cron.daily/
sudo /bin/chown root:root /etc/cron.daily/midia_indoor_update_diario

# configurando wallpaper do dispositivo
/bin/cp /var/lib/midia_indoor_player/device_configs/wallpaper.png /var/lib/Pictures/
pcmanfm --set-wallpaper="/var/lib/Pictures/wallpaper.png"
