#### orange 3: caso for cria imagem para microsd -> de preferencia para ubuntu bionic desktop por ser mais leve
#### orange 4: caso for cria imagem para microsd -> de preferencia para ubuntu jammy desktop por ser mais leve

#### Gravar cartão SD para orange pi

$ sudo nand-sata-install

# midia_indoor_player

## pt_br + teamviwer

```
sudo passwd orangepi
sudo passwd root
sudo dpkg-reconfigure keyboard-configuration
selecione portugues e marque tudo padrão
reinice pro terminal pegar portgues
faça um update no sistema operacional
baixe o linker_service
wget -O - https://raw.githubusercontent.com/denoww/linker_firmware/master/linker_service | bash -s update_service
ou
wget -O - www.seucondominio.com.br/linker_service | bash -s update_service
linker_service install_teamviewer
```

## install midia indoor

$ cd /var/lib; sudo chmod 7777 -R . ;sudo git clone https://github.com/denoww/midia_indoor_player.git; cd /var/lib/midia_indoor_player/; sudo chown -R $(whoami) .

## instale e configure a tv

```
cd /var/lib/midia_indoor_player/; tasks/./install.sh
```

## ligar modo development

$ npm run start_dev


## startup on boot machine

$ cd /var/lib/midia_indoor_player/; node start_on_machine_boot.js

## remover startup on boot machine

$ sudo rm ~/.config/autostart/init.sh.desktop



ligue o servidor produção

```
/var/lib/midia_indoor_player/tasks/init.sh
ou
npm run start_prod
```


Siga os passos de configuração, pode aceitar todas as opções na primeira instalação.

> Na opção `--> Rodar nvm install? (y/N)` será printado um comando a ser executado manualmente (porque o source ~/.bashrc não roda dentro do sh - mas deve ter um jeito de concertar), então depois de executar o comando manualmente, deve executar o `tasks/./config.sh` e dar ENTER até a próxima opção. (sinta-se à vontade para melhorar esse comportamento 😉)

Depois configure o Teamviewer nomeando o dispositivo como midia_indoor_player [ID DA TV]

Feito isso, após a reinicialização, o player já esta rodando. \o/

---

## Corrigir hora

```
sudo date -s '2022-12-15 09:47:00'
```

## Corrigir Timezone

```
sudo timedatectl set-timezone America/Sao_Paulo
```

--- OU ---

```
sudo dpkg-reconfigure tzdata
```

--- OU ---

```
sudo ln -s /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
ls -l /etc/localtime
```

## Removendo libs desnecessárias

```
sudo apt-get remove --purge wolfram-engine scratch nuscratch sonic-pi idle3 smartsim java-common minecraft-pi python-minecraftpi python3-minecraftpi libreoffice python3-thonny geany claws-mail bluej greenfoot
sudo apt-get autoremove
```

## Alterar a resolução do Raspbian

Edite o arquivo `/boot/config.txt`

```
# uncomment this if your display has a black border of unused pixels visible
# and your display can output without overscan
disable_overscan=1
```

```
# uncomment to force a console size. By default it will be display's size minus
# overscan.
framebuffer_width=1920
framebuffer_height=1080
```

## Compilar arquivos .coffee do assets

```
coffee -wc app/assets/javascripts/*.coffee
```

## Corrigir erro 405 npm

```
npm config set registry https://registry.npmjs.org
sudo npm install -g npm
```


