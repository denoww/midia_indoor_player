## Config windows

Ao ligar mini pc configure: 
<br>lingua inglesa
<br>teclado portuquese (Brazil ABNT2)
<br>quando pedir login clique em offline account e depois em limited experience
<br>nome do pc: TV
<br>senha: DEIXE VAZIO (importante não precisar de senha para logar)
<br>não usar speech recognition
<br>marcar não e skip em tudo a partir de agora (exceto gps localization)



Instale o Chrome
https://www.google.pt/intl/pt-PT/chrome

criar o executavel
<br>
no desktop -> botão direito no chrome -> criar atalho-> renomear para de tv -> botao direito -> propriedades -> no campo target ou destino colocar -> "C:\Program Files\Google\Chrome\Application\chrome.exe" --kiosk http://midiaindoor.seucondominio.com.br:4001/?tvId=45 -> troque o tvId

abrir executavel  no boot
<br>
teclas -> windows + r -> escreva -> shell:startup -> copie o atalho criado no desktop e cole nessa pasta que abriu

windows update automático (sem abrir caixas na frente do player)
<br>
Windows + R -> Digite services.msc -> "Serviços" -> role para baixo até encontrar o serviço "Windows Update" -> botão direito em "Windows Update" -> "Propriedades" -> "Geral" -> "startup type" -> "startup type" -> "Automático (delayed start)"-> "Aplicar" -> depois "OK"

Teamviewer
<br>Baixe a versão HOST
<br>https://download.teamviewer.com/download/TeamViewer_Host_Setup.exe
<br>Para não pedir password 
<br>opções >> avançada >> acess controll >> tire o show confirmation e coloque desativado
<br>opções >> security >> marque grant easy access
<br>opções >> random password >> desabilitar

beelink religar em queda de energia
<br>
aperte DEL no boot -> aba chipset -> south cluster configuration ->  restore ac power loss -> power on -> salve


## Oranges

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



