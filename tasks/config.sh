#!/bin/bash

# configurar desktop
read -p '--> Configurar Desktop? (y/N) ' config_desktop
if [[ "$config_desktop" == "y" || "$config_desktop" == "Y" ]] ; then

  # configurando barra de tarefas
  echo '--- Configurando barra de tarefas'
  sh -c 'cp /var/lib/midia_indoor_player/device_configs/panel /var/lib/.config/lxpanel/LXDE-pi/panels/panel'

  # configurando wallpaper do dispo
  echo '--- Configurando wallpaper do dispositivo'
  sh -c 'cp /var/lib/midia_indoor_player/device_configs/wallpaper.png /var/lib/Pictures/'
  sh -c 'pcmanfm --set-wallpaper="/var/lib/Pictures/wallpaper.png"'
fi

# configurando variaveis de ambiente
read -p '--> Configurar variáveis de ambiente? (y/N) ' config_vars
if [[ "$config_vars" == "y" || "$config_vars" == "Y" ]] ; then
  sh -c 'sudo cp /var/lib/midia_indoor_player/.env_DEVELOPMENT_sample /etc/environment'
  sh -c 'sudo cp /var/lib/midia_indoor_player/.env_DEVELOPMENT_sample /var/lib/midia_indoor_player/.env_DEVELOPMENT'
  read -p '--> Informe o ID da TV: ' TV_ID
  # read -p '--> Informe a API_SERVER_URL: ' API_SERVER_URL
  # echo -e "TV_ID=$TV_ID\nAPI_SERVER_URL=$API_SERVER_URL\nNODE_ENV=production\n" | sudo tee -a /etc/environment
  echo -e "TV_ID=$TV_ID\nNODE_ENV=production\n" | sudo tee -a /etc/environment
  source /etc/environment
fi

# configurando tamanho da SWAP
read -p '--> Aumentar tamanho da SWAP? (y/N) ' increase_swap
if [[ "$increase_swap" == "y" || "$increase_swap" == "Y" ]] ; then
  # sh -c 'sudo dphys-swapfile swapoff'
  # sh -c 'sudo dphys-swapfile swapon'
  echo -e "CONF_SWAPSIZE=1024" | sudo tee /etc/dphys-swapfile
  sh -c 'sudo /etc/init.d/dphys-swapfile restart'
fi

read -p '--> Alterar logo da tela de abertura? (y/N) ' logo
if [[ "$logo" == "y" || "$logo" == "Y" ]] ; then
  # copia a logo para a pasta
  sh -c 'sudo cp /var/lib/midia_indoor_player/device_configs/splash.png /usr/share/plymouth/themes/pix/'

  # adiciona 'logo.nologo' no /boot/cmdline.txt para remover a logo do raspberry
  TEM_LOGO=$(grep -rnw /boot/cmdline.txt -e 'logo.nologo')
  if [[ $TEM_LOGO ]]; then
    echo '/boot/cmdline.txt já está atualizado!'
  else
    sh -c 'sudo sed -i "s/$/ logo.nologo/" /boot/cmdline.txt'
  fi
fi

read -p '--> Atualizar LXDE-pi para nao desligar a tela? (y/N) ' atualizar_lxde
if [[ "$atualizar_lxde" == "y" || "$atualizar_lxde" == "Y" ]] ; then
  sh -c 'sudo cp /var/lib/midia_indoor_player/device_configs/lxde-autostart /etc/xdg/lxsession/LXDE-pi/autostart'
fi

read -p '--> Instalar xdotool para posisionar o MOUSE no canto da tela? (y/N) ' instalar_xdo
if [[ "$instalar_xdo" == "y" || "$instalar_xdo" == "Y" ]] ; then
  sh -c 'sudo apt install xdotool -y'
fi

read -p '--> Instalar TeamViewer? (y/N) ' instalar_teamv
if [[ "$instalar_teamv" == "y" || "$instalar_teamv" == "Y" ]] ; then
  sh -c 'sudo apt-get update'
  sh -c 'wget https://download.teamviewer.com/download/linux/teamviewer-host_armhf.deb'
  sh -c 'sudo dpkg -i teamviewer-host_armhf.deb'
  sh -c 'sudo apt --fix-broken install'
fi

# read -p '--> Instalar nodejs? (y/N) ' instalar_node
# if [[ "$instalar_node" == "y" || "$instalar_node" == "Y" ]] ; then
#   sh -c 'curl -sL https://deb.nodesource.com/setup_12.x | sudo bash -'
#   sh -c 'sudo apt update'
#   sh -c 'sudo apt install -y nodejs'
# fi

read -p '--> Instalar nvm? (y/N) ' instalar_nvm
if [[ "$instalar_nvm" == "y" || "$instalar_nvm" == "Y" ]] ; then
  wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
fi

nodeVersion=14.20.1
read -p "--> Instalar node $nodeVersion? (y/N) " instalar_npm_install
if [[ "$instalar_npm_install" == "y" || "$instalar_npm_install" == "Y" ]] ; then
  echo ""
  echo "Execute o comando abaixo:"
  echo "source ~/.bashrc && nvm install $nodeVersion && nvm use $nodeVersion && nvm alias default $nodeVersion"
  exit
fi

read -p "--> Criar atalho para node, npm e npx em /usr/bin (v${nodeVersion})? (y/N) " instalar_atalho
if [[ "$instalar_atalho" == "y" || "$instalar_atalho" == "Y" ]] ; then
  sudo ln -s "$NVM_DIR/versions/node/v$nodeVersion/bin/node" "/usr/bin/node"
  sudo ln -s "$NVM_DIR/versions/node/v$nodeVersion/bin/npm" "/usr/bin/npm"
  sudo ln -s "$NVM_DIR/versions/node/v$nodeVersion/bin/npx" "/usr/bin/npx"
fi

# read -p '--> Instalar npm? (y/N) ' instalar_npm
# if [[ "$instalar_npm" == "y" || "$instalar_npm" == "Y" ]] ; then
#   sh -c 'sudo apt install npm -y'
# fi

# read -p '--> Executar o npm install + npx electron-rebuild? (y/N) ' executar_npm
# if [[ "$executar_npm" == "y" || "$executar_npm" == "Y" ]] ; then
#   sh -c 'npm install'
#   sh -c 'npx electron-rebuild'
# fi

read -p '--> Executar o npm install? (y/N) ' executar_npm
if [[ "$executar_npm" == "y" || "$executar_npm" == "Y" ]] ; then
  sh -c 'npm install'
fi

# configurando crontab para reiniciar server
#read -p '--> Configurando CRONTAB para reiniciar server? (y/N) ' config_crontab
#if [[ "$config_crontab" == "y" || "$config_crontab" == "Y" ]] ; then
#  sh -c 'sudo cp /var/lib/midia_indoor_player/device_configs/crontab-sc-player /etc/cron.d/'
#  sh -c 'sudo chown root:root /etc/cron.d/crontab-sc-player'
#fi

# Reinício diário
read -p '--> Configurar Reinício diário? (y/N) ' cron
if [[ "$cron" == "y" || "$cron" == "Y" ]] ; then
  sh -c 'sudo cp /var/lib/midia_indoor_player/device_configs/tarefa_diaria /etc/cron.daily/'
  sh -c 'sudo chown root:root /etc/cron.daily/tarefa_diaria'
fi

read -p '--> Reiniciar o equipamento? (y/N) ' reiniciar
if [[ "$reiniciar" == "y" || "$reiniciar" == "Y" ]] ; then
  sh -c 'sudo reboot'
fi
