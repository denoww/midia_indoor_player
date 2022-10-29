# midia_indoor_player

#### caso for cria imagem para microsd -> de preferencia para ubuntu bionic por ser mais leve

## para NÂO iniciar mais no boot da maquina apague o arquivo que foi gerado pela lib npm auto-launch

$ sudo rm ~/.config/autostart/init.sh.desktop

## TUTORIAL DE CONFIGURAÇÃO

Primeiramente clone o repositório
```
cd /var/lib; sudo git clone https://github.com/denoww/midia_indoor_player.git; cd /var/lib/midia_indoor_player/; sudo chmod 7777 -R .
```

Execute a tarefa .config

```
cd /var/lib/midia_indoor_player/; tasks/./config.sh
```

ligue o servidor 

```
cd /var/lib/midia_indoor_player/; npm start
```

## starup on boot e reabrir se quebrar em erro


```
============================================
Crie um service para chamar o start da midia_indoor_player
============================================
sudo nano /etc/systemd/system/midia_indoor_player.service

=================================
Coloque o conteúdo
=================================


[Unit]
Description=midia_indoor_player

[Service]
Restart=always
RestartSec=0
ExecStart=/usr/bin/sudo /bin/bash -lc '/var/lib/midia_indoor_player/tasks/./init.sh'

[Install]
WantedBy=multi-user.target


=================================
Execute
=================================
sudo systemctl enable midia_indoor_player; sudo systemctl start midia_indoor_player
Veja se ligou (tente acessar no navegador)
reinicie o servidor


=================================
Stop se necessário
=================================

sudo systemctl stop midiaindoor

```

Siga os passos de configuração, pode aceitar todas as opções na primeira instalação.

> Na opção `--> Rodar nvm install? (y/N)` será printado um comando a ser executado manualmente (porque o source ~/.bashrc não roda dentro do sh - mas deve ter um jeito de concertar), então depois de executar o comando manualmente, deve executar o `tasks/./config.sh` e dar ENTER até a próxima opção. (sinta-se à vontade para melhorar esse comportamento 😉)

Depois configure o Teamviewer nomeando o dispositivo como midia_indoor_player [ID DA TV]

Feito isso, após a reinicialização, o player já esta rodando. \o/

---



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
