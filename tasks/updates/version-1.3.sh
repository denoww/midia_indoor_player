#!/bin/bash

# atualizando tarefa_diaria
sudo /bin/cp /home/pi/sc_player/device_configs/tarefa_diaria /etc/cron.daily/
sudo /bin/chown root:root /etc/cron.daily/tarefa_diaria

# configurando wallpaper do dispositivo
/bin/cp /home/pi/sc_player/device_configs/wallpaper.png /home/pi/Pictures/
pcmanfm --set-wallpaper="/home/pi/Pictures/wallpaper.png"
