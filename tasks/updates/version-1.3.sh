#!/bin/bash

# atualizando midia_indoor_update_diario
sudo /bin/cp /var/lib/midia_indoor_player/device_configs/midia_indoor_update_diario /etc/cron.daily/
sudo /bin/chown root:root /etc/cron.daily/midia_indoor_update_diario

# configurando wallpaper do dispositivo
/bin/cp /var/lib/midia_indoor_player/device_configs/wallpaper.png /var/lib/Pictures/
pcmanfm --set-wallpaper="/var/lib/Pictures/wallpaper.png"
