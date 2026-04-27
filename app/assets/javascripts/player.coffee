# player.coffee

# Sentry.init
#   dsn: 'https://ac78f87fac094b808180f86ad8867f61@sentry.io/1519364'
#   integrations: [new Sentry.Integrations.Vue({Vue, attachProps: true})]

# Sentry.configureScope (scope)->
#   scope.setUser id: "TV_ID_#{process.env.TV_ID}_FRONTEND"

# alert('2')

# ============================================================================
# Callbacks do NativePlayer (Corpflix Android — JS bridge)
#
# Chamados pelo WebView host quando o ExoPlayer nativo termina ou erra. Em
# Chrome Kiosk em Pi/PC essas funções existem mas nunca são invocadas (não há
# host Java pra disparar). Nada quebra se forem redefinidas pela aplicação.
# ============================================================================

# Vídeo terminou no ExoPlayer. No-op por design: o `@promessa = setTimeout`
# da timeline já avança a playlist baseado em `itemAtual.segundos`. Manter
# este callback registrado evita que `evaluateJavascript("window.onNativeVideoEnded()")`
# do lado Android lance ReferenceError.
window.onNativeVideoEnded = ->
  console.log "NativePlayer: onNativeVideoEnded (ignorado — timer da timeline cuida do avanço)"
  return

# Erro de decode/buffer no ExoPlayer. Pula a faixa imediatamente pra não
# deixar a TV num buraco visual até o timer expirar.
window.onNativeVideoError = (code, msg) ->
  console.warn "NativePlayer: onNativeVideoError code=#{code} msg=#{msg} — forçando avanço"
  try
    timelineConteudoSuperior?.executar?()
  catch e
    console.error 'falha ao avançar timeline após erro do NativePlayer', e
  return

# Estado do ExoPlayer mudou (buffering / playing / paused). Hook opcional
# pra sincronizar overlays no futuro; hoje no-op.
window.onNativeVideoStateChange = (state) ->
  console.log "NativePlayer: onNativeVideoStateChange state=#{state}"
  return

# Retângulo (CSS pixels) onde o vídeo deveria pintar dentro do layout.
# Usado pelo Corpflix Android pra posicionar a SurfaceView do ExoPlayer
# em vez de fullscreen — preserva sidebar/feed/branding visíveis durante
# o vídeo (paridade com Chrome Kiosk).
#
# Race: `playVideo` é chamado de forma síncrona quando a timeline decide
# trocar de item, mas o `<video v-if="item.is_video">` só entra no DOM
# no próximo tick do Vue. Logo, `#video-player-<id>` quase nunca existe
# nesse instante. Resolvido preferindo o container **estável** (`.content-player`)
# que tem o tamanho do slot do vídeo (o `<video>` ocupa 100% via CSS) —
# o rect resultante é equivalente em todos os layouts.
#
# Fallback final retorna {0,0,0,0}; o bridge nativo trata como "use
# fullscreen" pra evitar SurfaceView 0×0 (tela preta).
#
# Lista de candidatos (mais específico → mais genérico). Iterada toda:
# se o primeiro existe mas mediu 0×0 (acontece em transição de layout),
# os seguintes salvam o frame em vez de cair no fallback fullscreen.
nativePlayerCandidates = (videoId) ->
  out = []
  getters = [
    -> document.querySelector('.content-player')
    -> if videoId? then document.getElementById("video-player-#{videoId}") else null
    -> document.querySelector('.player-item')
    -> document.getElementById('content-main')
  ]
  for getter in getters
    el = getter()
    out.push(el) if el and el not in out
  out

nativePlayerVideoRect = (videoId) ->
  candidates = nativePlayerCandidates(videoId)
  return {left: 0, top: 0, width: 0, height: 0} if candidates.length is 0

  # Retorna o primeiro candidato com rect não-zero. Se todos zerados,
  # devolve o do primeiro pra o caller logar info de quem tá zerado.
  fallback = null
  for el in candidates
    r = el.getBoundingClientRect()
    rect = {
      left:   Math.round(r.left)
      top:    Math.round(r.top)
      width:  Math.round(r.width)
      height: Math.round(r.height)
    }
    return rect if rect.width > 0 and rect.height > 0
    fallback ?= {el, rect}

  cs = getComputedStyle(fallback.el)
  console.warn "rect zerado em #{fallback.el.tagName}.#{fallback.el.className or '(no-class)'} — " +
               "display=#{cs.display} visibility=#{cs.visibility} " +
               "offsetParent=#{fallback.el.offsetParent?.tagName or '(null)'} " +
               "client=#{fallback.el.clientWidth}x#{fallback.el.clientHeight}"
  fallback.rect

# Mede o rect e chama o callback. Se rect der 0×0 (race com layout pass do
# browser logo após vm.loaded virar true, ou Vue v-if pré-mount), tenta de
# novo em até [maxRetries] frames via requestAnimationFrame. Após metade
# dos retries, alterna pra setTimeout — cobre o caso de RAF estar pausado
# (Chrome Kiosk em tab background, ou WebView com page visibility=hidden
# durante transição de Activity). Custo no happy-path é 0 — quando o rect
# já é válido na primeira medida, callback roda síncrono.
nativePlayerMeasureRect = (videoId, callback, maxRetries = 5) ->
  attempt = (left, viaTimeout = false) ->
    rect = nativePlayerVideoRect(videoId)
    if (rect.width is 0 or rect.height is 0) and left > 0
      console.log "nativePlayerVideoRect 0×0, retry em #{if viaTimeout then 'setTimeout' else 'RAF'} (#{left} restantes)"
      # Alterna RAF → setTimeout depois de gastar metade dos retries.
      switchToTimeout = viaTimeout or left <= Math.ceil(maxRetries / 2)
      if switchToTimeout
        setTimeout((-> attempt(left - 1, true)), 16)
      else
        requestAnimationFrame -> attempt(left - 1, false)
      return
    callback(rect)
  attempt(maxRetries)

timezoneGlobal = null

data =
  body:    undefined
  loaded:  false
  loading: true

  # Loader sutil durante a transição entre items da playlist — evita
  # falsa sensação de travamento. Toggled pelo timelineConteudoSuperior
  # .executar() (ver player.coffee). CSS em .transition-loader (canto
  # superior direito do .content-player). Auto-hide via setTimeout.
  transitioning: false

  indexConteudoSuperior: 0
  indexConteudoMensagem: 0

  listaConteudoSuperior: []
  listaConteudoMensagem: []

  online: true

  now:  new Date()
  hora: '--:--'
  timezone: null

  grade:
    data:
      cor: 'black'
      layout: 'layout-2'
      weather: {}
      logo: {}

onLoaded = ->
  vm.loaded ||= gradeObj.loaded && feedsObj.loaded
  vm.loading = false if vm.loaded

  timelineConteudoSuperior.init()
  timelineConteudoMensagem.init()

@getTvId = ->
  uri = window.location.search.substring(1)
  params = new URLSearchParams(uri)
  tvId = params.get("tvId")
  return tvId

@checkTv = ->
  success = (resp)=>
    data = resp.data
    # console.log data
    restartPlayerSeNecessario(data)

  error = (resp) => console.log resp



  Vue.http.get('/check_tv?tvId='+getTvId()).then success, error

# resto “sempre positivo”
mod = (a, b) -> ((a % b) + b) % b


# === config flag ===
# === flag
# === config flag ===
USAR_VIDEO_COM_BLOB_CACHE = true

# caches
blobCache     = new Map()   # key -> { url, type, size }
pendingBlobs  = new Map()   # key -> Promise que resolve quando blob estiver pronto
preAquecerSet = new Set()
preAquecerCache = new Set()

preAquecerVideo = (url, sizeBytes) ->
  return unless url?
  key = keyForUrl(url)
  return if preAquecerSet.has(key) or blobCache.has(key)
  preAquecerSet.add(key)

  # Caminho preferido no Corpflix Android: warmCache nativo popula o
  # SimpleCache do ExoPlayer **em disco**. Quando playVideoFramed chega,
  # ExoPlayer encontra o vídeo localmente e o primeiro frame sai sem
  # round-trip de rede. Sem blob em RAM = economia de memória no chipset
  # barato (~40MB médios * 2-3 vídeos prefetched = 100MB+ no Pi/Mi Box).
  #
  # Fallback Chrome Kiosk em Pi/PC continua usando blob HTML5 (path antigo
  # USAR_VIDEO_COM_BLOB_CACHE) — bridge não existe lá, ramo é ignorado.
  if window.NativePlayer? and window.NativePlayer.warmCache?
    try
      window.NativePlayer.warmCache(url, sizeBytes or 0)
    catch e
      console.warn 'NativePlayer.warmCache falhou — sem prefetch, ExoPlayer baixa on-demand', e
      preAquecerSet.delete(key)
    return

  if USAR_VIDEO_COM_BLOB_CACHE
    p = fetch(url, {mode:'cors', credentials:'omit', cache:'force-cache'})
      .then (r) ->
        throw new Error("HTTP #{r.status}") unless r.ok
        Promise.all([r.arrayBuffer(), getContentType(r)])
      .then ([buf, type]) ->
        blob = new Blob([buf], {type})
        blobUrl = URL.createObjectURL(blob)
        blobCache.set(key, {cachedUrl: blobUrl, type, size: buf.byteLength})
        console.log "blob pronto", key, blobUrl
        blobUrl
      .catch (e) ->
        console.warn 'preAquecerVideo(blob) falhou', url, e
        preAquecerSet.delete(key)
        null

    pendingBlobs.set(key, p)
    p.finally -> pendingBlobs.delete(key)
  else
    fetch(url, {mode:'cors', credentials:'omit', cache:'force-cache'})
      .catch (e) -> preAquecerSet.delete(key)


# getPlayUrl = (item) ->
#   return item?.arquivoUrl unless USAR_VIDEO_COM_BLOB_CACHE and item?.is_video
#   key = keyForUrl(item.arquivoUrl)
#   cached = blobCache.get(key)
#   cached?.url or item.arquivoUrl

injectSource = (v, url, type) ->
  while v.firstChild? then v.removeChild(v.firstChild)
  s = document.createElement('source')
  s.src  = url
  s.type = type or 'video/mp4'
  v.appendChild(s)
  v.load()

preAquecerImagem = (url) ->
  return unless url?
  return if preAquecerCache.has(url)
  preAquecerCache.add(url)

  fetch(url,
    method: 'GET'
    mode: 'cors'
    credentials: 'omit'
    cache: 'force-cache'
  ).catch (e) ->
    preAquecerCache.delete(url)

  # Fallback (também usa cache do navegador)
  try
    img = new Image()
    img.decoding = 'async'
    img.referrerPolicy = 'no-referrer'
    img.src = url
  catch e then null


preAquecerMidia = (item) ->
  return unless item?
  if item.is_video and item.arquivoUrl
    # Passa midia.size pra warmCache nativo (governança/log). Pro fallback
    # HTML5 blob, size é ignorado — fetch lê Content-Length do servidor.
    preAquecerVideo(item.arquivoUrl, item.midia?.size or 0)
  else if item.is_image and item.arquivoUrl
    preAquecerImagem(item.arquivoUrl)


# === helpers de URL/cache ===
keyForUrl = (u) ->
  try
    url = new URL(u, window.location.href)
    # mesma origem, mesmo path; ignora search e hash
    return "#{url.origin}#{url.pathname}"
  catch e
    # fallback bruto
    return (u.split('?')[0] or u).split('#')[0]

getContentType = (resp) -> resp?.headers?.get('Content-Type') or 'video/mp4'


# ============================================================================
# Schedule de tela ligada/desligada — anti burn-in
#
# Vem do ERP em `vm.grade.data`:
#   screen_schedule_enabled: Boolean — master toggle
#   screen_active_days:      String  — CSV ISO weekdays (Mon=1..Sun=7)
#   screen_active_start:     String  — "HH:MM" local time
#   screen_active_end:       String  — "HH:MM" local time
#
# Quando habilitado e o relógio LOCAL está fora da janela, aplicamos:
#  1. Overlay preto fullscreen (DOM, z-index máximo) — funciona em qualquer
#     host (Pi/Chrome legado e Corpflix Android).
#  2. NativePlayer.setScreenActive(false) — Android para ExoPlayer e esconde
#     WebView via Compose (defesa em profundidade — bug do JS aqui não
#     queima painel).
#  3. NativePlayer.stopVideo() — garante que decode pare mesmo se o JS
#     estava no meio de um clip.
#
# Tick: 60s. Aplicado também a cada gradeObj.handle (pra reagir
# imediatamente quando admin muda a config no ERP).
# ============================================================================

ensureScreenOffOverlayEl = ->
  el = document.getElementById('screen-off-overlay')
  return el if el
  el = document.createElement('div')
  el.id = 'screen-off-overlay'
  Object.assign el.style,
    position:      'fixed'
    top:           '0'
    left:          '0'
    right:         '0'
    bottom:        '0'
    background:    '#000'
    zIndex:        '2147483647'
    pointerEvents: 'none'
    display:       'none'
  document.body?.appendChild(el)
  el

# 'HH:MM' -> minutos-do-dia (0..1439). null/inválido -> null.
hhmmToMinutes = (s) ->
  return null unless typeof s is 'string'
  parts = s.split(':')
  return null unless parts.length is 2
  h = parseInt(parts[0], 10)
  m = parseInt(parts[1], 10)
  return null if isNaN(h) or isNaN(m)
  return null if h < 0 or h > 23 or m < 0 or m > 59
  h * 60 + m

# Janela inclusiva nos dois extremos: [start, end]. Quando end < start,
# entende como "atravessa meia-noite" (ex: 22:00 → 04:00).
screenIsActiveNow = (daysCSV, startStr, endStr, now = new Date()) ->
  isoDay = ((now.getDay() + 6) % 7) + 1  # JS 0=Sun..6=Sat → ISO 7,1..6
  daysOk = String(daysCSV or '')
    .split(',')
    .map (s) -> parseInt(s.trim(), 10)
    .filter (n) -> not isNaN(n)
  return false if daysOk.length is 0
  return false unless isoDay in daysOk

  startMin = hhmmToMinutes(startStr) ? 0
  endMin   = hhmmToMinutes(endStr)   ? (24*60 - 1)
  nowMin   = now.getHours() * 60 + now.getMinutes()

  if startMin <= endMin
    nowMin >= startMin and nowMin <= endMin
  else
    nowMin >= startMin or nowMin <= endMin

applyScreenSchedule = ->
  d = window.vm?.grade?.data
  return unless d  # grade ainda não carregou — overlay default invisível

  shouldHide = false
  if d.screen_schedule_enabled
    active = screenIsActiveNow(
      d.screen_active_days,
      d.screen_active_start,
      d.screen_active_end,
    )
    shouldHide = not active

  el = ensureScreenOffOverlayEl()
  desired = if shouldHide then 'block' else 'none'
  return if el.style.display is desired  # idempotente

  el.style.display = desired
  console.log "screenSchedule: overlay=#{desired} " +
    "(enabled=#{d.screen_schedule_enabled}, " +
    "days=#{d.screen_active_days}, " +
    "#{d.screen_active_start}-#{d.screen_active_end})"

  # Bridge defesa em profundidade — Android para ExoPlayer e esconde WebView.
  if window.NativePlayer?.setScreenActive?
    try window.NativePlayer.setScreenActive(not shouldHide) catch e then null

  # Pausa o decode em curso ao entrar em off-hours.
  if shouldHide and window.NativePlayer?.stopVideo?
    try window.NativePlayer.stopVideo() catch e then null
  return

screenScheduleLoopStarted = false
startScreenScheduleLoop = ->
  return if screenScheduleLoopStarted
  screenScheduleLoopStarted = true
  applyScreenSchedule()
  setInterval applyScreenSchedule, 60_000


@gradeObj =
  tentar: 10
  tentativas: 0
  restart_player_em: null

  get: (onSuccess, onError)->
    return if @loading
    @loading = true

    success = (resp)=>
      if @tentativas > 0
        restartBrowserAposXSegundos(30)

      @loading    = false
      @tentativas = 0

      @handle resp.data
      onSuccess?()
      @mountWeatherData()
      @loaded = true
      onLoaded()

    error = (resp)=>
      @loading = false
      onLoaded()
      console.error 'Grade:', resp

      @tentativas++
      if @tentativas > @tentar
        console.error 'Grade: Não foi possível comunicar com o servidor!'
        return

      @tentarNovamenteEm = 1000 * @tentativas
      console.warn "Grade: Tentando em #{@tentarNovamenteEm / 1000} segundos"
      setTimeout ->
        gradeObj.get()
      , @tentarNovamenteEm
      onError?()

    Vue.http.get('/grade?tvId='+getTvId()).then success, error
    return
  downloadNewContent: ->
    success = (resp)=>
      @get ->
        console.log "Novo Conteúdo baixado"
    error = (resp) => console.log resp

    Vue.http.get('/download_new_content?tvId='+getTvId()).then success, error
  handle: (data)->
    @restart_player_em = data.restart_player_em
    vm.grade.data = @data = data

    # Sobe o loop de schedule de tela (idempotente — só faz setInterval
    # uma vez) e re-avalia imediatamente, pra reagir já no próximo grade
    # refresh quando admin muda config no ERP.
    startScreenScheduleLoop()
    applyScreenSchedule()

    return
  mountWeatherData: ->
    vm.grade.data.weather ||= {}
    return unless (vm.grade.data.weather.proximos_dias || []).length

    dataHoje = new Date
    dia = "#{dataHoje.getDate()}".rjust(2, '0')
    mes = "#{dataHoje.getMonth() + 1}".rjust(2, '0')
    dataHoje = "#{dia}/#{mes}"

    dia = vm.grade.data.weather.proximos_dias[0]
    if dia.data == dataHoje
      dia = vm.grade.data.weather.proximos_dias.shift()
      vm.grade.data.weather.max = dia.max
      vm.grade.data.weather.min = dia.min

    vm.grade.data.weather.proximos_dias = vm.grade.data.weather.proximos_dias.slice(0,4)
    return

@feedsObj =
  data: {}
  tentar: 10
  tentativas: 0
  posicoes: ['conteudo_superior', 'conteudo_mensagem']
  get: (onSuccess, onError)->
    return if @loading
    @loading = true

    success = (resp)=>
      @loading    = false
      @tentativas = 0

      @handle(resp.data)
      @verificarNoticias()
      onSuccess?()
      @loaded = true
      onLoaded()

    error = (resp)=>
      @loading = false
      onLoaded()
      console.error 'Feeds:', resp

      @tentativas++
      if @tentativas > @tentar
        console.error 'Feeds: Não foi possível comunicar com o servidor!'
        return

      @tentarNovamenteEm = 1000 * @tentativas
      console.warn "Feeds: Tentando em #{@tentarNovamenteEm / 1000} segundos"
      setTimeout (-> feedsObj.get()), @tentarNovamenteEm
      onError?()

    Vue.http.get('/feeds?tvId='+getTvId()).then success, error
    return
  handle: (data)->
    @data = data
    # pre-montar a estrutura dos feeds com base na grade para ser usado em verificarNoticias()

    for posicao in @posicoes
      vm.grade.data[posicao] ||= []
      feeds = vm.grade.data[posicao].select?((e)-> e.tipo_midia == 'feed') || []

      for feed in feeds
        @data[feed.fonte] ||= {}
        @data[feed.fonte][feed.categoria] ||= []
    return
  verificarNoticias: ->
    # serve para remover feeds que nao tem noticias
    for fonte, categorias of @data
      for categoria, noticias of categorias
        if (noticias || []).empty()
          for posicao in @posicoes
            continue unless vm.grade.data[posicao]

            vm.grade.data[posicao] ||= []
            items = vm.grade.data[posicao].select?((e)-> e.fonte == fonte && e.categoria == categoria)
            vm.grade.data[posicao].removeById item.id for item in items || []
    return

@timelineConteudoSuperior =
  promessa:  null
  nextIndex: 0
  feedIndex: {}
  playlistIndex: {}
  elUltimoVideo: null
  playTimer1: null
  playTimer2: null

  init: ->
    return unless vm.loaded
    @executar() unless @promessa?

  # =============== Núcleo unificado ===============

  # Resolve o item da faixa superior no índice atual.
  # opts:
  #   consuming: true/false  -> avança índices?
  #   offset:    inteiro     -> 0 = atual, 1 = próximo, 2 = +2, ...
  resolveNextItem: (opts = { consuming: true, offset: 0 }) ->
    lista = vm.grade.data.conteudo_superior || []
    return null unless lista.length

    varOffset = opts.offset ? 0
    idxLista = mod(@nextIndex + varOffset, lista.length)
    raw = lista[idxLista]

    item = @resolveItem(raw, opts)
    return null unless item

    if opts.consuming and varOffset is 0
      # só consome quando offset é 0 (o "agora")
      @nextIndex = mod(@nextIndex + 1, lista.length)

    item

  # Resolve um item: simples, feed ou playlist
  resolveItem: (rawItem, opts) ->
    return null unless rawItem?
    switch rawItem?.tipo_midia
      when 'feed'     then @resolveFeedItem(rawItem, opts)
      when 'playlist' then @resolvePlaylistItem(rawItem, opts)
      else rawItem  # midia/informativo/mensagem etc.

  # Feed com índice por (fonte,categoria), id estável
  resolveFeedItem: (rawItem, opts = {}) ->
    fonte = rawItem.fonte
    categ = rawItem.categoria
    feeds = feedsObj.data[fonte]?[categ] || []
    return null unless feeds.length

    @feedIndex[fonte] ?= {}
    idx = @feedIndex[fonte][categ]
    idx = 0 unless Number.isInteger(idx)

    feed = feeds[Math.min(idx, feeds.length - 1)]
    return null unless feed

    item = Object.assign({}, rawItem)
    item.id           = "feed-#{fonte}-#{categ}"  # **id estável**
    item.data         = feed.data
    item.qrcode       = feed.qrcode
    item.titulo       = feed.titulo
    item.titulo_feed  = feed.titulo_feed
    item.categoria_feed = feed.categoria_feed
    item.nome_arquivo = feed.nome_arquivo
    item.arquivoUrl   = feed.arquivoUrl ? feed.filePath

    if opts.consuming
      @feedIndex[fonte][categ] = mod(idx + 1, feeds.length)

    item

  # Playlist mantém um índice por playlist.id
  resolvePlaylistItem: (playlist, opts = {}) ->
    contentSup = playlist.conteudo_superior || []
    return null unless contentSup.length

    @playlistIndex[playlist.id] ?= 0
    idx = @playlistIndex[playlist.id]
    idx = 0 unless Number.isInteger(idx)

    cand = contentSup[Math.min(idx, contentSup.length - 1)]

    if opts.consuming
      @playlistIndex[playlist.id] = mod(idx + 1, contentSup.length)

    return cand if cand?.tipo_midia != 'feed'
    # se o item da playlist for feed, resolve via feed (sem consumir duas vezes)
    # Passa consuming do call original (para avançar feedIndex somente se consumir)
    @resolveFeedItem(cand, opts)

  # Apenas olha o próximo sem avançar índices
  peekNextItem: ->
    @resolveNextItem({ consuming: false, offset: 1 })

  # ============= Atalhos de QA (Corpflix Android) =============
  #
  # Chamados pelo app Corpflix Android via webView.evaluateJavascript quando
  # o operador aperta seta direita/esquerda no controle remoto. Ver
  # corpflix/app/.../PlayerScreen.kt seção "QA shortcuts".
  #
  # Comportamento: salta pro item [atual + delta] da faixa conteudo_superior
  # de forma circular (wraparound natural via mod). Cancela o timer pendente
  # e dispara executar() imediatamente — operador não precisa esperar a
  # duração do item atual acabar.
  #
  # Estado: durante a execução normal, @nextIndex aponta pro PRÓXIMO item
  # a ser consumido (resolveNextItem incrementa após pegar o atual).
  # Pra reproduzir [atual + delta] precisamos voltar 1 (pro 'atual') e somar
  # delta. delta=+1 mantém @nextIndex onde está → toca o próximo (que era
  # o que ia tocar de qualquer jeito, só sem esperar). delta=-1 retrocede
  # 2 → toca o anterior.
  #
  # Limitação conhecida: feedIndex/playlistIndex (índices internos de feed
  # e playlist) NÃO são revertidos no prev — voltar pro item anterior pode
  # mostrar a próxima notícia do feed em vez da que tinha aparecido antes.
  # Suficiente pra QA de playlist; ajustar se virar pedido de produto.
  jumpTo: (delta) ->
    lista = vm.grade.data.conteudo_superior || []
    return unless lista.length
    @nextIndex = mod(@nextIndex - 1 + delta, lista.length)
    @executar()
    return


  # =============== Loop ===============

  executar: ->
    clearTimeout @promessa if @promessa

    # Loader sutil durante a transição — feedback visual de "trocando
    # item" pra evitar falsa sensação de travamento, especialmente
    # durante carregamento do próximo vídeo/imagem. Auto-hide em 900ms,
    # cobre a maioria dos casos com pre-aquecimento ativo. Se o tempo
    # de carga for maior, o loader some antes da mídia aparecer (não
    # ideal, mas evita "loader eterno" se algum evento falha).
    vm.transitioning = true
    clearTimeout(@_transTimer) if @_transTimer
    @_transTimer = setTimeout (-> vm.transitioning = false), 900

    itemAtual = @resolveNextItem({ consuming: true })
    return console.error "resolveNextItem() retornou null" unless itemAtual

    # Mantém SOMENTE o atual no v-for
    vm.listaConteudoSuperior = [itemAtual]
    vm.indexConteudoSuperior = 0

    @stopUltimoVideo()

    # agenda próximo ciclo
    segundos = (itemAtual.segundos * 1000) || 5000
    @promessa = setTimeout (-> timelineConteudoSuperior.executar()), segundos

    # Pré-aquecer N itens à frente (vídeo ou imagem)
    # preaquecerQtdMidiasAFrente = 2
    preaquecerQtdMidiasAFrente = 1

    console.log "preaquecer proximos video/imagem qtd: #{preaquecerQtdMidiasAFrente}"
    for k in [1..preaquecerQtdMidiasAFrente]
      cand = @resolveNextItem({ consuming: false, offset: k })
      # console.log cand
      if cand?.arquivoUrl and (cand.is_video or cand.is_image)
        preAquecerMidia(cand)

    # Toca o atual (se for vídeo)
    @playVideo(itemAtual) if itemAtual.is_video
    return

  # =============== Vídeo ===============

  # playVideo injeta a <source> dinâmica
  # =============== Vídeo ===============
  #
  # Hook NativePlayer (Corpflix Android) — coexistência com Chrome Kiosk:
  #
  # Quando rodando dentro do Corpflix Android (WebView com `addJavascriptInterface`),
  # `window.NativePlayer.isAvailable()` devolve true e delegamos o decode pro
  # ExoPlayer nativo (SurfaceView por cima do WebView). Em qualquer outro
  # ambiente — Chrome Kiosk em Pi/PC, browser desktop pra preview, etc. — a
  # interface não existe e caímos no <video> HTML5 padrão. Mesmo deploy serve
  # os dois mundos. Contrato em corpflix/PRD.md seção "Arquitetura híbrida".
  #
  # O timer de avanço da playlist (`@promessa = setTimeout ..., segundos`) já
  # cuida de avançar quando o vídeo "termina" — não dependemos de evento
  # `ended` nem do callback `onNativeVideoEnded`. Esse callback existe na
  # interface do native pra eventualmente fast-forwardar quando o vídeo real
  # termina antes de `segundos`, mas é opt-in.
  playVideo: (itemAtual) ->
    videoId = itemAtual.id
    @elUltimoVideo = "video-player-#{itemAtual.id}"
    clearTimeout(@playTimer1) if @playTimer1?
    clearTimeout(@playTimer2) if @playTimer2?

    if window.NativePlayer? and (try window.NativePlayer.isAvailable() catch e then false)
      durationMs = (itemAtual.segundos * 1000) || 5000
      versaoCache = itemAtual.midia?.versao_cache or null
      console.log "Play video id #{videoId} via NativePlayer (ExoPlayer)"
      console.log "arquivoUrl: #{itemAtual.arquivoUrl}, durationMs: #{durationMs}"

      # Áudio é opt-in explícito (digital signage default = mute):
      # — `vm.grade.data.audio_enabled` vem do ERP por TV (campo gerenciado
      #   no admin /gerenciar/cd/.../publicidade/tvs).
      # — `!!` força boolean: undefined/null/false → false; só `true` libera.
      # — `setAudioEnabled?` proteção pra Corpflix Android < 3.1.82 (sem o
      #   método ainda); silently no-op nessas versões, mas elas já tocam
      #   muted por default no bridge novo, então sem regressão visual.
      audioEnabled = !!(vm?.grade?.data?.audio_enabled)
      if window.NativePlayer.setAudioEnabled?
        try window.NativePlayer.setAudioEnabled(audioEnabled) catch e then null
      # Mede rect com retry em RAF — cobre race com layout pass do browser
      # logo após vm.loaded virar true, ou Vue v-if pré-mount.
      nativePlayerMeasureRect videoId, (rect) =>
        try
          if rect.width > 0 and rect.height > 0 and window.NativePlayer.playVideoFramed?
            console.log "playVideoFramed rect=#{JSON.stringify(rect)}"
            window.NativePlayer.playVideoFramed(itemAtual.arquivoUrl, durationMs, String(versaoCache or ''),
                                                rect.left, rect.top, rect.width, rect.height)
          else
            console.warn "rect inválido (#{rect.width}x#{rect.height}) ou playVideoFramed ausente — fullscreen legado"
            window.NativePlayer.playVideo(itemAtual.arquivoUrl, durationMs, String(versaoCache or ''))
        catch e
          console.warn 'NativePlayer.playVideo* falhou — fallback pra <video> HTML5', e
          @_playVideoHtml5(itemAtual, videoId)
      return

    @_playVideoHtml5(itemAtual, videoId)
    return

  _playVideoHtml5: (itemAtual, videoId) ->
    key  = keyForUrl(itemAtual.arquivoUrl)
    pend = pendingBlobs.get(key)

    chooseAndPlay = (v) =>
      entry = blobCache.get(key)
      finalVideoUrl = if USAR_VIDEO_COM_BLOB_CACHE and entry?.cachedUrl then entry.cachedUrl else itemAtual.arquivoUrl

      console.log "Play video id #{videoId}"
      console.log "finalVideoUrl: #{finalVideoUrl}"
      console.log "arquivoUrl: #{itemAtual.arquivoUrl}"

      ctype = entry?.type or itemAtual.content_type or 'video/mp4'
      injectSource(v, finalVideoUrl, ctype)
      v.currentTime = 0
      v.play().catch (e) -> console.warn('play falhou', e)

    @playTimer1 = setTimeout =>
      v = document.getElementById(@elUltimoVideo)
      return unless v?

      # Se existir um blob pendente, aguarda até 10s; usa blob somente se ficar pronto.
      if USAR_VIDEO_COM_BLOB_CACHE and pend? and not blobCache.get(key)?
        Promise.race([
          pend.then -> 'ok'
          new Promise (res) -> setTimeout (-> res('timeout')), 10000
        ]).finally =>
          chooseAndPlay(v)   # se blob não existir ainda, cairá na URL original
      else
        chooseAndPlay(v)
    , 0

    @playTimer2 = setTimeout =>
      v = document.getElementById(@elUltimoVideo)
      v?.paused and v.play().catch (e) -> console.warn('replay falhou', e)
    , 1000

    return


  # revoga blob ao parar, eliminando vazamento e caches velhos
  # NÃO remove nem revoga blob do cache: apenas pausa e limpa o <video>
  stopUltimoVideo: ->
    # Native (Corpflix Android): para ExoPlayer e esconde SurfaceView. Idempotente.
    if window.NativePlayer? and (try window.NativePlayer.isAvailable() catch e then false)
      try window.NativePlayer.stopVideo() catch e then null

    return unless @elUltimoVideo
    v = document.getElementById(@elUltimoVideo)
    if v?
      try v.pause() catch e then null
      try
        v.removeAttribute('src')
        while v.firstChild? then v.removeChild(v.firstChild)  # remove <source>
        v.load()  # desaloca o decoder sem mexer no blobCache
      catch e then null
    @elUltimoVideo = null
    clearTimeout(@playTimer1) if @playTimer1?
    clearTimeout(@playTimer2) if @playTimer2?
    @playTimer1 = @playTimer2 = null
    return



# @timelineConteudoSuperior =
#   promessa:  null
#   nextIndex: 0
#   feedIndex: {}
#   playlistIndex: {}
#   init: ->
#     return unless vm.loaded
#     @executar() unless @promessa?
#   executar: ->
#     clearTimeout @promessa if @promessa

#     itemAtual = @getNextItemConteudoSuperior()
#     return console.error "@getNextItemConteudoSuperior() - itemAtual é indefinido!", itemAtual unless itemAtual

#     vm.indexConteudoSuperior = vm.listaConteudoSuperior.getIndexByField 'id', itemAtual.id
#     if !vm.indexConteudoSuperior?

#       # console.log itemAtual
#       vm.listaConteudoSuperior = [itemAtual] # mantém a lista com *apenas* o item atual
#       vm.indexConteudoSuperior = 0

#       # vm.listaConteudoSuperior.push itemAtual
#       # vm.indexConteudoSuperior = vm.listaConteudoSuperior.length - 1

#     @stopUltimoVideo()

#     segundos = (itemAtual.segundos * 1000) || 5000
#     @promessa = setTimeout ->
#       timelineConteudoSuperior.executar()
#     , segundos

#     @playVideo(itemAtual) if itemAtual.is_video
#     return
#   playVideo: (itemAtual)->
#     @elUltimoVideo = "video-player-#{itemAtual.id}"

#     clearTimeout(@playTimer1) if @playTimer1?
#     clearTimeout(@playTimer2) if @playTimer2?

#     getUltimoVideo = -> document.getElementById(@elUltimoVideo)

#     @playTimer1 = setTimeout =>
#       v = getUltimoVideo()
#       if v?
#         v.currentTime = 0
#         v.play().catch((e)-> console.warn('play falhou', e))
#     , 0

#     @playTimer2 = setTimeout =>
#       v = getUltimoVideo()
#       if v?.paused
#         v.play().catch((e)-> console.warn('replay falhou', e))
#     , 1000
#     return

#   # playVideo: (itemAtual)->
#   #   @elUltimoVideo = "video-player-#{itemAtual.id}"

#   #   setTimeout =>
#   #     video = document.getElementById(@elUltimoVideo)
#   #     if video
#   #       video.currentTime = 0
#   #       video.play()

#   #   setTimeout =>
#   #     video = document.getElementById(@elUltimoVideo)
#   #     video.play() if video?.paused
#   #   , 1000
#   #   return
#   stopUltimoVideo: ->
#     videoId = @elUltimoVideo
#     return unless videoId

#     v = document.getElementById(videoId)
#     if v?
#       try v.pause() catch e then null
#       try
#         # remove src/source para liberar decoder/buffer
#         v.removeAttribute('src')
#         while v.firstChild?
#           v.removeChild(v.firstChild) # remove <source>
#         v.load()  # força desalocar
#       catch e then null
#     @elUltimoVideo = null

#     # limpa timers de play (ver D)
#     clearTimeout(@playTimer1) if @playTimer1?
#     clearTimeout(@playTimer2) if @playTimer2?
#     @playTimer1 = @playTimer2 = null
#     return

#   # stopUltimoVideo: ->
#   #   videoId = @elUltimoVideo
#   #   return unless videoId

#   #   video = document.getElementById(videoId)
#   #   video.pause() if video
#   #   @elUltimoVideo = null
#   #   return
#   getNextItemConteudoSuperior: ->
#     lista = vm.grade.data.conteudo_superior || []
#     listaQtd = lista.length
#     return console.error "vm.grade.data.conteudo_superior está vazio!", lista unless listaQtd

#     index = @nextIndex
#     index = 0 if index >= listaQtd

#     @nextIndex++
#     @nextIndex = 0 if @nextIndex >= listaQtd


#     currentItem = lista[index]
#     switch currentItem?.tipo_midia
#       when 'feed'
#         currentItem = @getItemFeed(currentItem)
#       when 'playlist'
#         currentItem = @getItemPlaylist(currentItem)
#         if !currentItem && listaQtd > 1
#           currentItem = @getNextItemConteudoSuperior()



#     currentItem
#   getItemFeed: (currentItem)->
#     feedItems = feedsObj.data[currentItem.fonte]?[currentItem.categoria] || []
#     if feedItems.empty()
#       console.warn "Feeds de #{currentItem.fonte} #{currentItem.categoria} está vazio"
#       timelineConteudoSuperior.promessa = setTimeout ->
#         timelineConteudoSuperior.executar()
#       , 2000
#       return

#     fonte = currentItem.fonte
#     categ = currentItem.categoria
#     @feedIndex[fonte] ||= {}

#     if !@feedIndex[fonte][categ]?
#       @feedIndex[fonte][categ] = 0
#     else
#       @feedIndex[fonte][categ]++

#     if @feedIndex[fonte][categ] >= feedItems.length
#       @feedIndex[fonte][categ] = 0

#     index = @feedIndex[fonte][categ]
#     feed = feedItems[index] || feedItems[0]

#     return unless feed
#     currentItem.id     = "#{currentItem.id}#{feed.nome_arquivo}"
#     currentItem.data   = feed.data
#     currentItem.qrcode = feed.qrcode
#     currentItem.titulo = feed.titulo
#     currentItem.titulo_feed = feed.titulo_feed
#     currentItem.categoria_feed = feed.categoria_feed
#     currentItem.nome_arquivo = feed.nome_arquivo
#     currentItem.filePath = feed.filePath
#     currentItem
#   getItemPlaylist: (playlist)->
#     contentSup = playlist.conteudo_superior || []
#     if !@playlistIndex[playlist.id]?
#       @playlistIndex[playlist.id] = 0
#     else
#       @playlistIndex[playlist.id]++

#     if @playlistIndex[playlist.id] >= contentSup.length
#       @playlistIndex[playlist.id] = 0

#     currentItem = contentSup[@playlistIndex[playlist.id]]

#     return currentItem if currentItem?.tipo_midia != 'feed'
#     @getItemFeed(currentItem)

@timelineConteudoMensagem =
  promessa:  null
  nextIndex: 0
  playlistIndex: {}
  init: ->
    return unless vm.loaded
    @executar() unless @promessa?
  executar: ->
    clearTimeout @promessa if @promessa

    itemAtual = @getNextItemMsg()
    return unless itemAtual

    vm.indexConteudoMensagem = vm.listaConteudoMensagem.getIndexByField 'id', itemAtual.id
    if !vm.indexConteudoMensagem?
      vm.listaConteudoMensagem.push itemAtual
      vm.indexConteudoMensagem = vm.listaConteudoMensagem.length - 1

    segundos = (itemAtual.segundos * 1000) || 5000
    @promessa = setTimeout ->
      timelineConteudoMensagem.executar()
    , segundos
    return
  getNextItemMsg: ->

    lista = vm.grade.data.conteudo_mensagem || []
    total = lista.length
    return unless total

    index = @nextIndex
    index = 0 if index >= total

    @nextIndex++
    @nextIndex = 0 if @nextIndex >= total

    currentItem = lista[index]
    switch currentItem?.tipo_midia
      when 'feed' then @getItemFeed(currentItem)
      else currentItem
  getItemFeed: (currentItem)->
    feedItems = feedsObj.data[currentItem.fonte]?[currentItem.categoria] || []
    return currentItem if feedItems.empty()

    index = parseInt(Math.random() * 100) % feedItems.length
    feed = feedItems[index] || feedItems[0]

    return unless feed
    currentItem.id     = "#{currentItem.id}#{feed.titulo}"
    currentItem.data   = feed.data
    currentItem.qrcode = feed.qrcode
    currentItem.titulo = feed.titulo
    currentItem.titulo_feed = feed.titulo_feed
    currentItem.categoria_feed = feed.categoria_feed
    currentItem.filePath = feed.filePath
    currentItem


# Detecta timezone preferindo Intl (síncrono, no-network). Em browsers que
# não expõem `Intl.DateTimeFormat().resolvedOptions().timeZone` cai pra
# fetch geo-IP — com timeout curto pra não enforcar o `mounted` da TV se
# a rede estiver tossindo (Chrome Kiosk em link congestionado, WebView
# Android sem permissão pro endpoint http externo, ou DNS público filtrado).
descobrirTimezone = (callback) ->
  # Garante callback único — protege contra Intl síncrono + fetch
  # respondendo tarde duplicarem o tick do relógio.
  resolved = false
  done = (tz) ->
    return if resolved
    resolved = true
    timezoneGlobal = tz or "America/Sao_Paulo"
    callback?(timezoneGlobal)

  try
    tz = Intl?.DateTimeFormat?()?.resolvedOptions?()?.timeZone
    if tz
      return done(tz)
  catch e
    console.warn "Intl timezone falhou:", e

  # Fallback de rede com timeout. 3s passou disso é melhor cair no default
  # do que segurar o boot da TV.
  fetchWithTimeout = (url, ms = 3000) ->
    return Promise.reject(new Error("AbortController indisponível")) unless typeof AbortController is 'function'
    ctrl = new AbortController()
    timer = setTimeout((-> ctrl.abort()), ms)
    fetch(url, signal: ctrl.signal).finally(-> clearTimeout(timer))

  fetchWithTimeout('http://ip-api.com/json')
    .then((r) -> r.json())
    .then((j) ->
      if j?.timezone
        done(j.timezone)
      else
        throw new Error("ip-api sem campo timezone")
    )
    .catch (err1) ->
      fetchWithTimeout('https://worldtimeapi.org/api/ip')
        .then((r) -> r.json())
        .then((j) ->
          if j?.timezone
            done(j.timezone)
          else
            throw new Error("worldtimeapi sem campo timezone")
        )
        .catch (err2) ->
          msg1 = err1?.message or err1
          msg2 = err2?.message or err2
          console.warn "Falha ao detectar timezone (ip-api: #{msg1}; worldtimeapi: #{msg2}). Usando America/Sao_Paulo."
          done("America/Sao_Paulo")

# descobrirTimezone = (callback) ->
#   console.log "Descobrindo timezone..."

#   timezone = 'America/Sao_Paulo'
#   error = ->
#     console.log 'erro em descobrirTimezone'
#     callback(timezone)
#   success = (resp)=>
#     success = resp.status == 200
#     if success
#       data = resp.data
#       timezone = data.timezone
#     callback(timezone)

#   url = 'http://ip-api.com/json'
#   Vue.http.get(url).then success, error


# Guarda anti-race: `mounted` chama `relogio.start()` durante a execução
# de `@vm = new Vue(...)`. O `Intl.DateTimeFormat` resolve síncrono → o
# callback do `descobrirTimezone` roda síncrono → toca `vm.timezone`
# ANTES de `@vm = ` ter terminado de atribuir window.vm → ReferenceError.
# Solução: adiar a escrita pro próximo frame e checar disponibilidade.
relogio =
  start: ->
    descobrirTimezone (tz) ->
      assign = ->
        unless window.vm?
          # Race feio (mounted ainda dentro do construtor do Vue).
          # Tenta de novo no próximo frame.
          return requestAnimationFrame(assign)
        vm.timezone = tz or "America/Sao_Paulo"
        relogio.tick()         # já atualiza na hora
        relogio.timer ?= setInterval(relogio.tick, 1000)  # 1s (ou 30s/60s)
      assign()

  tick: ->
    return unless window.vm?
    tz = vm.timezone or "America/Sao_Paulo"
    m  = moment.tz(new Date(), tz)

    # atualiza reativo (dia/semana dependem disso)
    vm.now = m.toDate()

    # atualiza hora (string)
    vm.hora = m.format('HH:mm')


updateOnlineStatus = ->
  return unless @vm
  return if @vm.loading
  old = vm.online
  vm.online = navigator.onLine
  passouDeOfflineParaOnline = old != vm.online && vm.online
  if passouDeOfflineParaOnline

    @gradeObj.downloadNewContent()
    # alert('entrou')
updateContent = ->
  return unless @vm
  # return if @vm.loading
  gradeObj.get ->
    feedsObj.get ->
      vm.loading = false
      vm.loaded = true

window.addEventListener 'online',  updateOnlineStatus
window.addEventListener 'offline',  updateOnlineStatus


@vm = new Vue
  el:   '#main-player'
  data: data
  methods:
    playVideo: timelineConteudoSuperior.playVideo
    mouse: ->
      clearTimeout(@mouseTimeout) if @mouseTimeout
      @body ||= document.getElementById('body-player')
      @body.style.cursor = 'default'

      @mouseTimeout = setTimeout =>
        @body.style.cursor = 'none'
      , 1000
  # computed:
  #   now: -> Date.now()
  mounted: ->
    @loading = true
    @mouse()
    # Defer pro próximo tick — o `@vm = new Vue(...)` ainda não terminou
    # de atribuir window.vm enquanto este `mounted` roda, e o
    # `descobrirTimezone` pode resolver síncrono (Intl) e tocar
    # `vm.timezone` na hora. `$nextTick` garante que o setup de top-level
    # já completou.
    @$nextTick -> relogio.start()



    setInterval ->
      # return if vm.loaded
      checkTv()
    , 1000 * 3 # 3 segundo

    setTimeout ->
      return if vm.loaded
      updateContent()
    , 1000 * 1 # 1 segundo

    setInterval ->
      updateContent()
      updateOnlineStatus()
    # , 1000 * 2 # a cada 2 minutos
    , 1000 * 60 * 2 # a cada 2 minutos


    return

Vue.filter 'formatDayMonth', (value)->
  moment(value).format('DD MMM') if value

Vue.filter 'formatDate', (value)->
  moment(value).format('DD/MM/YYYY') if value

Vue.filter 'formatDateTime', (value)->
  moment(value).format('DD/MM/YYYY HH:mm') if value

Vue.filter 'formatWeek', (value)->
  moment(value).format('dddd') if value

Vue.filter 'currency', (value)->
  (value || 0).toLocaleString('pt-Br', minimumFractionDigits: 2, maximumFractionDigits: 2)


restartBrowser = -> window.location.reload()

reiniciando = false
restartBrowserAposXSegundos = (xSegundos) ->
  return if reiniciando
  reiniciando = true

  console.log "Será reiniciado em #{xSegundos} segundos"
  setTimeout =>
    restartBrowser()
  , xSegundos*1000



restartPlayerSeNecessario = (data) ->
  # xSegundos = data.restart_player_em_x_segundos
  # return unless xSegundos

  # console.log 'gradeObj.restart_player_em'
  # console.log gradeObj.restart_player_em
  # console.log 'data.restart_player_em'
  # console.log data.restart_player_em

  if data.restart_player_em != gradeObj.restart_player_em
    restartBrowserAposXSegundos(20)

    # @timers = []
    # @timers.push = setTimeout => @exec(), 2000


# =====================================================================
# QA shortcuts — atalhos de navegação manual da playlist.
# =====================================================================
#
# Expostos como globais pra serem chamados pelo Corpflix Android via
# webView.evaluateJavascript("window.corpflixNext?.()") quando o operador
# aperta seta direita/esquerda no controle remoto. Ver
# /home/rodrigo/workspace/corpflix/app/src/main/java/br/com/corpflix/ui/PlayerScreen.kt
# seção "QA shortcuts".
#
# Em outros ambientes (Chrome Kiosk, browser desktop pra preview) ficam
# disponíveis no console — útil pra QA manual:
#     corpflixNext()  → próximo item
#     corpflixPrev()  → item anterior
#
# Implementação delegada a timelineConteudoSuperior.jumpTo (player.coffee
# logo após resolveNextItem).
window.corpflixNext = -> timelineConteudoSuperior.jumpTo(+1)
window.corpflixPrev = -> timelineConteudoSuperior.jumpTo(-1)


# ============= Atalhos cross-platform (touch + keyboard) =============
#
# Mesmas ações de corpflixNext/Prev, acionáveis a partir de qualquer
# cliente web — sem depender do Corpflix Android intermediar:
#
#   - **Teclado** (Chrome Kiosk em Pi/PC, browser desktop pra preview,
#     monitor com teclado USB plugado): setas →/← disparam next/prev.
#     preventDefault evita scroll horizontal acidental da página.
#
#   - **Touch swipe** (display touch standalone, kiosk touchscreen,
#     também roda de graça em qualquer outro display caso vire touch):
#     arrasta dedo direita→esquerda = next; esquerda→direita = prev.
#     Threshold de 50px filtra toques acidentais (dedo ficou no lugar).
#
# No Corpflix Android (Mi Box), o atalho D-pad é capturado pelo
# PlayerScreen.kt e disparado via evaluateJavascript — caminho
# preferencial porque pega antes do WebView consumir. Estes listeners
# ficam como caminho redundante (sem efeito colateral) caso a key chegue
# até o JS.
#
# isFormElement: skip quando o foco está em campo editável. Improvável
# no player, mas defensivo pra futuro form de debug não roubar setas.
isFormElement = (el) ->
  return false unless el
  tag = el.tagName?.toUpperCase?()
  return true if tag in ['INPUT', 'TEXTAREA', 'SELECT']
  return true if el.isContentEditable
  false

document.addEventListener 'keydown', (e) ->
  return if isFormElement(e.target)
  switch e.key
    when 'ArrowRight'
      window.corpflixNext?()
      e.preventDefault()
    when 'ArrowLeft'
      window.corpflixPrev?()
      e.preventDefault()
  return

# Swipe state — só rastreamos X porque é navegação 1D.
# Reset em touchcancel pra não vazar estado se sistema interrompe gesto.
touchStartX = null

document.addEventListener 'touchstart', (e) ->
  touchStartX = e.changedTouches?[0]?.clientX ? null
  return
, { passive: true }

document.addEventListener 'touchend', (e) ->
  startX = touchStartX
  touchStartX = null
  return unless startX?
  endX = e.changedTouches?[0]?.clientX
  return unless endX?
  dx = endX - startX
  return if Math.abs(dx) < 50
  if dx < 0
    window.corpflixNext?()  # arrastou pra esquerda → avança
  else
    window.corpflixPrev?()  # arrastou pra direita → volta
  return
, { passive: true }

document.addEventListener 'touchcancel', ->
  touchStartX = null
  return


