#!/bin/bash
cd /var/lib/sc_player/
rm cron.log # remover arquivo de logs

# atualiza o npm
# sudo npm install -g npm

# apaga as imagens antigas dos feeds
/usr/bin/npm run delete_old_images
sleep 2

# atualiza o repositorio
/var/lib/sc_player/tasks/./update_repository.sh

# reinicia o equipamento
sudo /sbin/reboot
