## Midia Indoor CLOUD - instale na núvem

entre no ssh da numvem

```
cd /var/lib; sudo chmod 7777 -R . ;sudo git clone https://github.com/denoww/midia_indoor_player.git; cd /var/lib/midia_indoor_player/; sudo chown -R $(whoami) .
```
### instale node

[https://github.com/nodesource/distributions/#debinstall
](https://nodesource.com/products/distributions)

### arrumar pastas node

```
mkdir "${HOME}/.npm-global"
npm config set prefix "${HOME}/.npm-global"
export PATH="$HOME/.npm-global/bin:$PATH"
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```


Reinicie

```
cd /var/lib/midia_indoor_player
cp .env_sample .env
```
```
npm install pm2 -g
```
```
npm install -g coffeescript
```
```
npm install
```

```
npm run pm2_start_prod
```
```
pm2 startup
```
Copie o codigo gerado

```
pm2 save
```
```
pm2 logs
```

#### Atualizar Load Balance

1. Abra o link:  
   [Run Workflow](https://github.com/denoww/midia_indoor_player/actions/workflows/aws_deploy.yml)

2. Clique em **"Run workflow"** na branch master



==================

==================

==================

FIM

==================

==================

==================

## trocar logo

1. $ midiaindoorcloudssh
2. $ cd /var/lib/midia_indoor_player/public
3. apague a pasta da tv (pasta 45 por exemplo)
4. entre na tela de grade e playlist -> edite e salve (não precisa modificar nada)
5. entre na tela de tv e clique em reiniciar player


## Config android tv

1. Adquira o modelo android tv: pro eletronic smart prosb-3000/16
2. conecte na internet (wifi ou cabo): no caso de wifi >> configuracoes >> rede e internet >> entre no sru wifi
3. Baixe o app: google play -> corpflix ..OU.. faça por APK >> abra o google chrome >> modo mouse (aperte ícone do mouse do controle remoto) >> na barra de endereço do chrome coloque >> http://bit.ly/corpflix >> baixe  >> instale >> abra o app >> clique em ligar tv >> coloque o codigo da sua tv ou coloque 58 (tv teste)
4. Garanta que app reabra em queda de energia: >> configurações >> apps >> acesso especial a apps >> sobrepor a outros apps >> marcar corpflix >> desligar >> ligar >> apos ligar completamente esperar mais 2 minutos até abrir

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

beelink religar em queda de energia
<br>
fique apertando DEL no boot até abrir a tela de configurações "azul com cinza" -> aba chipset -> aperte ENTER -> south cluster configuration -> aperte ENTER ->  restore ac power loss -> aperte ENTER -> power on -> aperte ENTER -> aperte ESC -> aba save & exit > save changes and exit 


Teamviewer 
<br>deixe pro Rodrigo fazer esse passo
<br>Baixe a versão HOST
<br>https://download.teamviewer.com/download/TeamViewer_Host_Setup.exe
<br>Para não pedir password 
<br>opções >> avançada >> acess controll >> tire o show confirmation e coloque desativado
<br>opções >> security >> marque grant easy access
<br>opções >> security >> random password >> desabilitar



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

```
cp ~/workspace/midia_indoor_player/.env_sample ~/workspace/midia_indoor_player/.env;
midiaindoors
```


## startup on boot machine

$ cd /var/lib/midia_indoor_player/; node start_on_machine_boot.js

## remover startup on boot machine

$ sudo rm ~/.config/autostart/init.sh.desktop



## ligue o servidor produção

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



