#!/bin/bash

# atualizando tarefa_diaria
sudo /bin/cp /var/lib/sc_player/device_configs/tarefa_diaria /etc/cron.daily/
sudo /bin/chown root:root /etc/cron.daily/tarefa_diaria

# configurando wallpaper do dispositivo
/bin/cp /var/lib/sc_player/device_configs/wallpaper.png /var/lib/Pictures/
pcmanfm --set-wallpaper="/var/lib/Pictures/wallpaper.png"
