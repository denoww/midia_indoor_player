# web.coffee

express = require 'express'
path    = require 'path'
bodyParser = require 'body-parser'
fs = require 'fs'

module.exports = (opt={}) ->
  app = express()
  server = app.listen(ENV.HTTP_PORT)
  scPrint.success("http://localhost:#{ENV.HTTP_PORT} ligado")

  # Revalidação para coisas que mudam com o mesmo nome (assets legados sem versão).
  revalidateCache =
    etag: true
    lastModified: true
    setHeaders: (res, p) ->
      res.setHeader 'Cache-Control', 'public, max-age=0, must-revalidate'
      res.setHeader 'Access-Control-Allow-Origin', '*'

  # Cache "smart": arquivos versionados (`<id>-v<unix_ts>.<ext>`, gerados pelo
  # grade.coffee a partir de `versao_cache` do ERP) ganham 1 ano + immutable —
  # browser da TV nem revalida. Arquivos sem `-v<n>` no nome (TVs antigas, ou
  # payload do ERP antes do versionamento) caem em revalidate, comportamento
  # legado preservado. Re-upload no admin → updated_at muda → filename muda →
  # cache miss natural sem precisar limpar cache do browser.
  smartCache =
    etag: true
    lastModified: true
    setHeaders: (res, p) ->
      res.setHeader 'Access-Control-Allow-Origin', '*'
      if /-v\d+\.(mp4|webm|m4v|webp|jpg|jpeg|png|gif|mp3|ogg)$/i.test(p)
        res.setHeader 'Cache-Control', 'public, max-age=31536000, immutable'
      else
        res.setHeader 'Cache-Control', 'public, max-age=0, must-revalidate'

  app.use express.static(path.join(__dirname, '../assets/'), revalidateCache)
  app.use express.static(path.join(__dirname, '../../public/'), smartCache)

  # ====== Middleware genérico (não force JSON em tudo)
  app.all '*', (req, res, next) ->
    # só define JSON se AINDA não tem Content-Type
    res.setHeader('Access-Control-Allow-Origin', '*')
    res.setHeader('Access-Control-Allow-Methods', 'OPTIONS,GET,POST,PUT,DELETE')
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With')
    res.setHeader('Vary', 'Origin')  # boa prática de CORS

    req.getParams = ->
      resp = Object.assign(@body || {}, @query || {}, @params || {})
      format = resp?.format?.replace('.', '')
      delete resp['0']
      resp.format = format if format
      resp

    return res.sendStatus(200) if req.method == 'OPTIONS'
    next()

  app.get '/', (req, res) ->
    params = req.getParams()
    console.log "GET / params: #{JSON.stringify(params)}"
    res.type 'text/html'
    res.sendFile path.join(__dirname, '../assets/templates/index.html')

# express = require 'express'
# path    = require 'path'
# bodyParser = require('body-parser')


# module.exports = (opt={}) ->
#   app = express()
#   # global.logs.info "Iniciando servidor HTTP! Versão #{versao}"
#   server = app.listen(ENV.HTTP_PORT)
#   scPrint.success("#{"http://localhost:#{ENV.HTTP_PORT}"} ligado")

#   setTimeout ->
#     # require("#{process.cwd()}/start_player");
#   , 7000


#   # versao = global.versionsControl?.currentVersion || global.versao_player || '--'
#   # global.server_started = true

#   app.use express.static(path.join( __dirname, '../assets/'))
#   app.use express.static(path.join( __dirname, '../../public/'))


#   # Resolve o erro do CROSS de Access-Control-Allow-Origin
#   app.all '*', (req, res, next)->
#     res.header 'Content-Type', 'application/json'
#     res.header 'Access-Control-Allow-Origin', '*'
#     res.header 'Access-Control-Allow-Methods', 'OPTIONS,GET,POST,PUT,DELETE'
#     res.header 'Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With'

#     req.getParams = ->
#       resp = Object.assign( @body || {}, @query || {}, @params || {} )
#       format = resp?.format?.replace('.', '')
#       delete resp['0']
#       resp.format = format if format
#       resp

#     return res.sendStatus(200) if req.method == 'OPTIONS'
#     next()

#   app.get '/', (req, res) ->
#     params = req.getParams()
#     console.log  "Request GET / params: #{JSON.stringify(params)}"
#     res.type "text/html"
#     res.sendFile path.join( __dirname, '../assets/templates/index.html')
  
  app.get '/health', (req, res) ->
    resp = {}
    res.json resp

    
  app.get '/grade', (req, res) ->
    params = req.getParams()
    console.log  "Request GET /grade params: #{JSON.stringify(params)}"
    tvId = params.tvId
    data = global?.grade?.data?[tvId] ? {}
    return unless data?
    if Object.empty data
      # deviceId vem do JS (localStorage) ou do nativo Android. Repassa
      # pra grade.coffee#getList propagar upstream pro Rails — Fase 1
      # do roadmap "Tv has many devices".
      global.grade.getList(tvId, deviceId: params.deviceId) if global.grade
      res.sendStatus(400)
      return
    res.send JSON.stringify data


  # Cache do `versionCode` lido do `update.json` de cada canal. Releitura
  # do FS é barata (~200 bytes, OS page cache) mas com 200+ TVs do parque
  # batendo `/check_tv` a cada 3s vira ~67 stat/parse por segundo —
  # memoizar 5s amortiza pra ~0.4/s sem introduzir atraso visível na
  # propagação. TTL menor que o tick de 3s do JS = ainda multiplica I/O;
  # maior que ~10s = atraso percebido entre `upload_apk_to_midia.sh`
  # publicar e parque inteiro reagir. 5s é o ponto cego aceito.
  manifestCache = production: null, staging: null, expiresAt: 0

  readLatestVersionCodes = ->
    now = Date.now()
    return manifestCache if now < manifestCache.expiresAt
    for [channel, dir] in [['production', 'corpflix'], ['staging', 'corpflix-staging']]
      try
        p = path.join(__dirname, '..', '..', 'public', 'apks', dir, 'update.json')
        manifestCache[channel] = JSON.parse(fs.readFileSync(p, 'utf8'))?.versionCode ? null
      catch e
        # Manifesto pode não existir (canal staging nunca publicado, ou
        # FS error transitório). Silencia — retorno null vira early-return
        # no JS do player, comportamento neutro.
        manifestCache[channel] = null
    manifestCache.expiresAt = now + 5000
    manifestCache

  app.get '/check_tv', (req, res) ->
    params = req.getParams()
    console.log  "Request GET /check_tv params: #{JSON.stringify(params)}"
    tvId = params.tvId
    tvId = parseInt(tvId) if tvId
    data = global?.grade?.data?[tvId] ? {}
    return unless data?

    resp = {}
    resp.tvId = data.tvId
    resp.restart_player_em = data.restart_player_em
    # Anuncia última versão publicada em cada canal — JS do player.coffee
    # compara com `NativePlayer.appVersionCode()` e dispara
    # `triggerUpdateCheck()` se servidor anuncia versão maior. Encurta o
    # ciclo de detecção do parque de 1h (tick periódico do UpdateWorker)
    # pra ≤3s do tick do JS, sem novo canal de push.
    m = readLatestVersionCodes()
    resp.latestVersionCode =
      production: m.production
      staging: m.staging
    res.send JSON.stringify resp

    # Telemetria do Corpflix Android (TelemetryWorker, 1×/h): quando o
    # cliente nativo Kotlin manda `app_versao` + métricas de cache, o
    # relay encaminha tudo pro Rails fire-and-forget — Rails persiste em
    # publicidade_tvs e mostra em /support/tvs. Heartbeat puro do JS
    # (sem app_versao) não dispara o proxy: hotpath de 3s não pode bater
    # no Rails a cada tick (DDoS no parque inteiro).
    #
    # Resposta ao cliente já foi enviada acima — proxy é assíncrono e
    # falhas são silenciosas; se o Rails está offline ou a coluna ainda
    # não existe (migration não rodou), telemetria desta janela é
    # perdida e o próximo tick de 1h tenta de novo.
    if params.app_versao? and ENV.API_SERVER_URL
      request = require 'request'
      url = "#{ENV.API_SERVER_URL}/publicidades/check_tv.json"
      qs =
        id: tvId
        # Fase 1 do roadmap "Tv has many devices" (corpflix/ROADMAP.md):
        # nativo Android (TelemetryWorker) já manda deviceId junto com
        # app_versao — propaga upstream pro Rails persistir/logar
        # per-device em vez de "último que reportou ganha" no nível Tv.
        deviceId: params.deviceId
        app_versao: params.app_versao
        cache_video_bytes: params.cache_video_bytes
        cache_video_entradas: params.cache_video_entradas
        cache_web_bytes: params.cache_web_bytes
        cache_web_entradas: params.cache_web_entradas
        provisionado_ok: params.provisionado_ok
        device_owner: params.device_owner
      request.get {url: url, qs: qs, timeout: 5000}, (e, r, b) ->
        if e
          console.log "telemetry → Rails erro: #{e.message}"
        else if r?.statusCode != 200
          console.log "telemetry → Rails HTTP #{r?.statusCode}"

  # Validação se uma TV ID existe no ERP. Proxy direto pro Rails sem usar o
  # cache em memória do Node (`global.grade.data`) — esse cache só conhece
  # TVs que o player já carregou, então não serve pra validar TV "nova" que
  # o operador acabou de digitar na tela de configuração.
  #
  # Repassa status HTTP do Rails (200 se existe, 404 se não existe). Errors
  # de rede/Rails fora do ar viram 502 — sinaliza pro client tratar como
  # "não pôde validar" em vez de "TV não existe".
  #
  # Usado pelo Corpflix Android antes de salvar config local. Não é heartbeat
  # nem tem efeito colateral no Rails (lá em `tv_existe` não atualizamos
  # `atualizada_em`, ao contrário de check_tv).
  app.get '/tv_existe', (req, res) ->
    request = require 'request'
    params = req.getParams()
    tvId = params.tvId or params.id
    tvId = parseInt(tvId) if tvId
    unless tvId and tvId > 0
      return res.status(400).json(error: 'tvId obrigatório')

    # deviceId opcional — Fase 1 do roadmap "Tv has many devices".
    # Validação é one-shot (Corpflix Android antes de salvar config),
    # sem efeito colateral, mas propaga pra ter visibilidade no log
    # do Rails de qual device pediu validação.
    url = "#{ENV.API_SERVER_URL}/publicidades/tv_existe.json?id=#{tvId}"
    url += "&deviceId=#{params.deviceId}" if params.deviceId
    console.log "Request GET /tv_existe → proxy #{url}"
    request {url: url, timeout: 5000}, (error, response, body) ->
      if error
        console.log "  ✗ erro de rede: #{error}"
        return res.status(502).json(error: 'upstream indisponível')
      status = response?.statusCode or 502
      if status == 200
        return res.status(200).json(id: tvId)
      if status == 404
        return res.status(404).json(error: 'TV não cadastrada')
      console.log "  ✗ status inesperado: #{status}"
      res.status(502).json(error: "upstream HTTP #{status}")

  app.get '/download_new_content', (req, res) ->
    params = req.getParams()
    console.log  "Request GET /download_new_content params: #{JSON.stringify(params)}"
    tvId = params.tvId
    tvId = parseInt(tvId) if tvId
    # Repassa deviceId pra grade.coffee#getList propagar upstream —
    # Fase 1 do roadmap "Tv has many devices".
    global.grade.getList(tvId, deviceId: params.deviceId) if tvId

    resp = {}
    res.send JSON.stringify resp



  app.get '/feeds', (req, res) ->
    params = req.getParams()
    console.log  "Request GET /feeds params: #{JSON.stringify(params)}"
    tvId = params.tvId
    data = global.feeds.data[tvId] || {}
    # if Object.empty data
    #   global.feeds.getList(tvId)
    #   res.sendStatus(400)
    #   return
    res.send JSON.stringify data

  # Fase 4 do roadmap "Tv has many devices" (corpflix/ROADMAP.md):
  # proxy de upload de crash do Corpflix Android. CrashReportWorker do
  # APK (commit a partir de 3.2.32) detecta crashes.log não-vazio em
  # /sdcard/Android/data/.../files/logs/ e POSTa aqui; aqui forwardamos
  # tal-qual pro Rails persistir.
  #
  # Body é text/plain bruto (conteúdo do crashes.log do CrashHandler);
  # meta vai em querystring. bodyParser.text() limit 200KB cobre o cap
  # de 64KB do client (CrashHandler.MAX_BYTES) com folga grande.
  #
  # Sem cache aqui — fire-and-forward síncrono pro upstream. Frequência
  # baixíssima (semanas entre crashes em campo), nada justifica
  # buffering local.
  app.post '/crash_report',
    bodyParser.text(type: '*/*', limit: '200kb'),
    (req, res) ->
      console.log "Request POST /crash_report tvId=#{req.query.tvId} deviceId=#{req.query.deviceId} app_versao=#{req.query.app_versao} payloadBytes=#{req.body?.length || 0}"
      unless ENV.API_SERVER_URL
        return res.status(500).json(error: 'API_SERVER_URL não configurada')
      unless req.query.tvId
        return res.status(400).json(error: 'tvId obrigatório')
      unless req.body and req.body.length > 0
        return res.status(400).json(error: 'payload obrigatório')

      request = require 'request'
      # Forwarda como text/plain com body bruto (mesmo formato que o
      # CrashReportWorker do APK envia pro relay). Meta vai na
      # querystring. Antes tentamos `form: { ..., payload: req.body }`
      # mas a lib `request` (deprecated) codificava algo que Rails
      # rejeitava com 422+body vazio (provavelmente CSRF ou parsing de
      # tabs/newlines em form field grande). Curl com --data-urlencode
      # passava 200; `request` form: não. Text/plain raw é o caminho
      # validado em probe manual via curl --data-binary que sempre
      # retornou 200.
      params = new URLSearchParams(
        tvId: req.query.tvId
        app_versao: req.query.app_versao or ''
      )
      params.append('deviceId', req.query.deviceId) if req.query.deviceId
      url = "#{ENV.API_SERVER_URL}/publicidades/crash_report?#{params.toString()}"
      request.post {
        url: url
        body: req.body
        headers: { 'Content-Type': 'text/plain; charset=UTF-8' }
        timeout: 10000
      }, (e, r, b) ->
        if e
          console.log "  ✗ erro de rede: #{e.message}"
          return res.status(502).json(error: 'upstream indisponível')
        if r?.statusCode == 200
          # Devolve o body do Rails ({id, crashed_at}) pro cliente — o
          # CrashReportWorker do APK só usa o status code (200 → renomeia
          # crashes.log → .sent) mas devolver o JSON ajuda em debug
          # manual via curl.
          return res.status(200).type('application/json').send(b)
        console.log "  ✗ upstream HTTP #{r?.statusCode}: #{b?.toString?()?.slice(0,200) or b?.slice?(0,200)}"
        res.status(r?.statusCode or 502).type('application/json').send(b or '{}')


  # app.get  '/npm_run', (req, res) ->
  #   # GET -> http://midiaindoor.seucondominio.com.br:4001/npm_run?cmd=deploy
  #   npmCtrl.execNpmRun(req, res)

  # app.post  '/npm_run', (req, res) ->
  #   # POST -> http://midiaindoor.seucondominio.com.br:4001/npm_run?cmd=deploy
  #   npmCtrl.execNpmRun(req, res)

npmCtrl =
  execNpmRun: (req, res) ->
    params = req.getParams()
    npmRunCmd = params.cmd

    params = req.getParams()
    console.log  "/npm_run params: #{JSON.stringify(params)}"
    switch npmRunCmd
      when 'xxxxxxxxxxxxxxxxx'
        console.log 'nada aqui'
        # npmCtrl._execNpmRunPortaria(req, res)
      else
        npmCtrl._npmRun(npmRunCmd)
    res.setHeader 'Content-Type', 'application/json'
    res.send JSON.stringify({params})
  _npmRun: (npmRunCmd) ->
    return unless npmRunCmd
    command = "npm run #{npmRunCmd} --prefix /var/lib/midia_indoor_player"
    shell = require("child_process").exec
    shell command, (error, stdout, stderr) ->
      console.log error if error
      console.log stdout if stdout
      console.log stderr if stderr
