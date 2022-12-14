#!/bin/bash
cd /var/lib/midia_indoor_player/
> cron.log # reseta arquivo de logs para economizar espaço

# atualiza o npm
# sudo npm install -g npm

# apaga as imagens antigas dos feeds
/usr/bin/npm run delete_old_images
sleep 2

# atualiza o repositorio
/var/lib/midia_indoor_player/tasks/./update_repository.sh

# reinicia o equipamento
sudo /sbin/reboot
