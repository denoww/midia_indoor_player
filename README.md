# midia_indoor_player

## TUTORIAL DE CONFIGURAÇÃO

Primeiramente clone o repositório
```
cd /var/lib; git clone https://github.com/denoww/midia_indoor_player.git; cd ~/midia_indoor_player/
```

Execute a tarefa .config

```
cd /var/lib/midia_indoor_player/; tasks/./config.sh
```

Caso queira ligar o servidor na mão

```
cd /var/lib/midia_indoor_player/; npm start
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

## Conexão SSH no Raspberry

Habilite o SSH nas configurações do Raspberry se não estiver habilitado.

```
ssh pi@IP_DO_RASPBERRY
```

## SSH sem senha

Execute `ssh-keygen` no seu PC.
Faça upload do id_rsa.pub para o Raspberry PI.

```
scp ~/.ssh/id_rsa.pub pi@IP_DO_RASPBERRY:.ssh/authorized_keys
```

## Montar imagem do Raspberry

Crie a pasta Raspberry no diretório /home/$USER

```
mkdir /home/$USER/Raspberry/
```

Agora é só executar o comando abaixo

```
sshfs pi@IP_DO_RASPBERRY: /home/$USER/Raspberry/
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
