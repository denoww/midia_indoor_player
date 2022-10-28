# handle setupevents as quickly as possible
setupEvents = require './installers/setupEvents'
if setupEvents.handleSquirrelEvent()
  # squirrel event handled and app will exit in 1000ms, so don't do anything else
  return

{ app, dialog, protocol, BrowserWindow } = require 'electron'
contextMenu = require 'electron-context-menu'
appWindow = null

createWindow = ->
  windowOptions =
    show:            false
    icon:            "#{__dirname}/app/assets/images/icon.png"
    kiosk:           true
    minWidth:        640
    minHeight:       360
    darkTheme:       true
    alwaysOnTop:     true
    autoplayPolicy:  'no-user-gesture-required'
    useContentSize:  true
    autoHideMenuBar: true
    backgroundColor: '#222'
    webPreferences:
      # webSecurity:     false
      nodeIntegration: true

  if ENV.NODE_ENV == 'development'
    windowOptions.kiosk       = false
    windowOptions.width       = 640
    windowOptions.height      = 360
    windowOptions.alwaysOnTop = true

  logs.info "Iniciando janela do Electron!"
  appWindow = new BrowserWindow windowOptions

  appWindow.loadURL "http://localhost:#{ENV.HTTP_PORT}"
  appWindow.focus()
  appWindow.once 'ready-to-show', -> appWindow.show()

  # criando protoco seguro para carregar arquivos locais
  protocolName = 'sc-protocol'
  protocol.registerFileProtocol protocolName, (request, callback)->
    url = request.url.replace("#{protocolName}://", '')
    try
      return callback(decodeURIComponent(url))
    catch error
      logs.error(error)

  # atualizar a tela a cada 3 horas para limpar o cache
  setInterval ->
    logs.create 'Electron -> Atualização preventiva (3h)!'
    appWindow.reload()
  , 1000 * 60 * 60 * 3 # 3 horas

  appWindow.webContents.on 'crashed', ->
    logs.warning 'webContents crashed'
    setTimeout (-> appWindow.reload()), 500

  appWindow.webContents.on 'did-fail-load', ->
    logs.warning 'webContents did-fail-load'
    setTimeout (-> appWindow.reload()), 1000

  appWindow.webContents.on 'new-window', ->                      logs.debug 'webContents new-window'
  appWindow.webContents.on 'will-navigate', ->                   logs.debug 'webContents will-navigate'
  appWindow.webContents.on 'unresponsive', ->                    logs.debug 'webContents unresponsive'
  appWindow.webContents.on 'responsive', ->                      logs.debug 'webContents responsive'
  appWindow.webContents.on 'enter-html-full-screen', ->          logs.debug 'webContents enter-html-full-screen'
  appWindow.webContents.on 'leave-html-full-screen', ->          logs.debug 'webContents leave-html-full-screen'
  appWindow.webContents.on 'certificate-error', ->               logs.debug 'webContents certificate-error'
  appWindow.webContents.on 'select-client-certificate', ->       logs.debug 'webContents select-client-certificate'
  appWindow.webContents.on 'login', ->                           logs.debug 'webContents login'
  appWindow.webContents.on 'remote-require', ->                  logs.debug 'webContents remote-require'
  appWindow.webContents.on 'remote-get-global', ->               logs.debug 'webContents remote-get-global'
  appWindow.webContents.on 'remote-get-builtin', ->              logs.debug 'webContents remote-get-builtin'
  appWindow.webContents.on 'remote-get-current-window', ->       logs.debug 'webContents remote-get-current-window'
  # appWindow.webContents.on 'did-fail-provisional-load', ->       logs.debug 'webContents did-fail-provisional-load'
  appWindow.webContents.on 'will-redirect', ->                   logs.debug 'webContents will-redirect'
  appWindow.webContents.on 'did-redirect-navigation', ->         logs.debug 'webContents did-redirect-navigation'
  appWindow.webContents.on 'did-navigate-in-page', ->            logs.debug 'webContents did-navigate-in-page'
  appWindow.webContents.on 'will-prevent-unload', ->             logs.debug 'webContents will-prevent-unload'
  appWindow.webContents.on 'plugin-crashed', ->                  logs.debug 'webContents plugin-crashed'
  appWindow.webContents.on 'destroyed', ->                       logs.debug 'webContents destroyed'
  appWindow.webContents.on 'zoom-changed', ->                    logs.debug 'webContents zoom-changed'
  appWindow.webContents.on 'found-in-page', ->                   logs.debug 'webContents found-in-page'
  appWindow.webContents.on 'did-change-theme-color', ->          logs.debug 'webContents did-change-theme-color'
  appWindow.webContents.on 'cursor-changed', ->                  logs.debug 'webContents cursor-changed'
  appWindow.webContents.on 'context-menu', ->                    logs.debug 'webContents context-menu'
  appWindow.webContents.on 'select-bluetooth-device', ->         logs.debug 'webContents select-bluetooth-device'
  appWindow.webContents.on 'paint', ->                           logs.debug 'webContents paint'
  appWindow.webContents.on 'will-attach-webview', ->             logs.debug 'webContents will-attach-webview'
  appWindow.webContents.on 'did-attach-webview', ->              logs.debug 'webContents did-attach-webview'
  appWindow.webContents.on 'preload-error', ->                   logs.debug 'webContents preload-error'
  appWindow.webContents.on 'ipc-message', ->                     logs.debug 'webContents ipc-message'
  appWindow.webContents.on 'ipc-message-sync', ->                logs.debug 'webContents ipc-message-sync'
  appWindow.webContents.on 'desktop-capturer-get-sources', ->    logs.debug 'webContents desktop-capturer-get-sources'
  appWindow.webContents.on 'remote-get-current-web-contents', -> logs.debug 'webContents remote-get-current-web-contents'
  appWindow.webContents.on 'remote-get-guest-web-contents', ->   logs.debug 'webContents remote-get-guest-web-contents'
  # appWindow.webContents.on 'did-finish-load', ->                 logs.debug 'webContents did-finish-load'

  appWindow.onerror = (error, url, lineNumber)->
    logs.error "Error: #{error} Script: #{url} Line: #{lineNumber}"

  # Open the DevTools
  # appWindow.webContents.openDevTools()

# garantindo uma unica instancia do app aberta
if !app.requestSingleInstanceLock()
  logs.warning 'Ignorando segunda instancia do app', tags: class: 'application'
  app.exit(0)
  return

# se tentar abrir uma segunda instancia, devemos focar nossa janela
app.on 'second-instance', (event, commandLine, workingDirectory)->
  if appWindow
    appWindow.restore() if appWindow.isMinimized()
    appWindow.focus()

# definindo o nome do app
app.setName 'Player'

# criar janela quando estiver pronto
app.whenReady().then ->
  createWindow()

# criar janela quando for ativado e nao existir nenhuma
app.on 'activate', ->
  createWindow() unless BrowserWindow.getAllWindows().length

# encerrar o app se não existir nenhuma janela aberta
app.on 'window-all-closed', -> app.exit(0)

# opcoes do menu do botão direito do mouse no app
contextMenu prepend: (defaultActions, params, browserWindow)->
  [
    { role: 'toggleFullScreen', label: 'Tela cheia' }
    { type: 'separator' }
    { role: 'reload', label: 'Atualizar Player' }
    {
      label: 'Reiniciar Player',
      click: ->
        app.relaunch({ args: process.argv.slice(1).concat(['--relaunch']) })
        app.exit(0)
    }
    { type: 'separator' }
    # {
    #   label: 'Atualizar Equipamento',
    #   click: ->
    #     versionsControl.exec(true)
    # }
    {
      label: 'Reiniciar Equipamento',
      click: ->
        restartDevice()
    }
    # { type: 'separator' }
    # {
    #   label: "Versão atual: #{versionsControl?.currentVersion || '--'}"
    #   enabled: false
    # }
  ]

# reiniciar equipamento
restartDevice = ->
  logs.create 'Reiniciando Player!'
  return if ENV.NODE_ENV == 'development'

  shell = require 'shelljs'
  shell.exec 'sudo /sbin/reboot', (code, out, error)->
    logs.error "restartDevice -> #{error}", tags: class: 'application' if error
  return

# Disable error dialogs by overriding
dialog.showErrorBox = (title, content)->
  logs.error "DIALOG -> #{title} #{content}"
