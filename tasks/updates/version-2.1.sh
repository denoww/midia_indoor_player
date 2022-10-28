#!/bin/bash
export DISPLAY=":0"

# alterando o wallpaper
sh -c 'cp /var/lib/midia_indoor_player/device_configs/wallpaper.png /var/lib/Pictures/wallpaper.png'
sh -c 'pcmanfm --set-wallpaper="/var/lib/Pictures/wallpaper.png"'
# echo -e "[*]\nwallpaper_mode=fit\nwallpaper_common=1\nwallpaper=/var/lib/Pictures/wallpaper.png\ndesktop_bg=#222222\ndesktop_fg=#dddddd\ndesktop_shadow=#222222\ndesktop_font=PibotoLt 12\nshow_wm_menu=0\nsort=mtime;ascending;\nshow_documents=0\nshow_trash=0\nshow_mounts=1" > /var/lib/.config/pcmanfm/LXDE-pi/desktop-items-0.conf

# alterando a logo de inicializacao
sh -c 'sudo cp /var/lib/midia_indoor_player/device_configs/splash.png /usr/share/plymouth/themes/pix/splash.png'

# adiciona 'logo.nologo' no /boot/cmdline.txt para remover a logo do raspberry
TEM_LOGO=$(grep -rnw /boot/cmdline.txt -e 'logo.nologo')
if [[ $TEM_LOGO ]]; then
  echo '/boot/cmdline.txt já está atualizado!'
else
  sh -c 'sudo sed -i "s/$/ logo.nologo/" /boot/cmdline.txt'
fi
