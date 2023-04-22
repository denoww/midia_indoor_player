#!/bin/bash
cd /var/lib/midia_indoor_player/
> cron.log # reseta arquivo de logs para economizar espaço

# reinicia o equipamento
sudo /sbin/reboot
# /sbin/reboot
