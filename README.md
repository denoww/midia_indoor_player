## Config windows

criar o executavel
ache chrome -> criar atalho no desktop -> renomear para de tv -> botao direito -> propriedades -> no campo target ou destino colocar -> "C:\Program Files\Google\Chrome\Application\chrome.exe" --kiosk http://midiaindoor.seucondominio.com.br:4001/?tvId=45 -> troque o tvId

abrir executavel  no boot
teclas -> windows + r -> escreva -> shell:startup -> no espaço vazio -> botão direito -> novo -> shortcut ou atalho -> coloque o tv que criou no desktop

beelink religar em queda de energia
aperte DEL no boot -> aba chipset -> south cluster configuration ->  restore ac power loss -> power on -> salve

## Orangtes

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

## install midia indoor mini pc

$ cd /var/lib; sudo chmod 7777 -R . ;sudo git clone --depth 1 https://github.com/denoww/midia_indoor_player.git; cd /var/lib/midia_indoor_player/; sudo chown -R $(whoami) .

## instale e configure a tv

```
cd /var/lib/midia_indoor_player/; tasks/./install.sh
```

## ligar modo development

$ npm run start


## startup on boot machine

$ cd /var/lib/midia_indoor_player/; node start_on_machine_boot.js

## remover startup on boot machine

$ sudo rm ~/.config/autostart/init.sh.desktop



ligue o servidor produção

```
/var/lib/midia_indoor_player/tasks/init.sh
ou
npm run start_fullscreen
```


Siga os passos de configuração, pode aceitar todas as opções na primeira instalação.

> Na opção `--> Rodar nvm install? (y/N)` será printado um comando a ser executado manualmente (porque o source ~/.bashrc não roda dentro do sh - mas deve ter um jeito de concertar), então depois de executar o comando manualmente, deve executar o `tasks/./config.sh` e dar ENTER até a próxima opção. (sinta-se à vontade para melhorar esse comportamento 😉)

Depois configure o Teamviewer nomeando o dispositivo como midia_indoor_player [ID DA TV]

Feito isso, após a reinicialização, o player já esta rodando. \o/

---

## Midia Indoor CLOUD - instale na núvem

```
sccamerasproductionssh
cd /var/lib; sudo chmod 7777 -R . ;sudo git clone https://github.com/denoww/midia_indoor_player.git; cd /var/lib/midia_indoor_player/; sudo chown -R $(whoami) .
cd /var/lib/midia_indoor_player/; tasks/./install.sh

Reinicie

cd /var/lib/midia_indoor_player
npm install pm2 -g
npm run pm2_start_prod
pm2 startup
Copie o codigo gerado
pm2 save
pm2 logs
```



