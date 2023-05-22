#!/bin/bash
# cd /var/lib/midia_indoor_player/
# > cron.log # reseta arquivo de logs para economizar espaço

# atualiza o npm
# sudo npm install -g npm

# apaga as imagens antigas dos feeds
/usr/bin/npm run apagar_arquivos_antigos
sleep 2

# atualiza o repositorio
/var/lib/midia_indoor_player/tasks/./update_repository.sh

# atualizar chrome
sudo apt-get update -y
sudo apt --only-upgrade -y install chromium-browser

/var/lib/midia_indoor_player/tasks/./init.sh
# reinicia o equipamento
# sudo /sbin/reboot
# /sbin/reboot
