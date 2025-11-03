# player.coffee

# Sentry.init
#   dsn: 'https://ac78f87fac094b808180f86ad8867f61@sentry.io/1519364'
#   integrations: [new Sentry.Integrations.Vue({Vue, attachProps: true})]

# Sentry.configureScope (scope)->
#   scope.setUser id: "TV_ID_#{process.env.TV_ID}_FRONTEND"

# alert('2')
timezoneGlobal = null

data =
  body:    undefined
  loaded:  false
  loading: true

  indexConteudoSuperior: 0
  indexConteudoMensagem: 0

  listaConteudoSuperior: []
  listaConteudoMensagem: []

  online: true

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
FORCE_BLOB_PLAYBACK = true

# caches
blobCache     = new Map()   # key -> { url, type, size }
pendingBlobs  = new Map()   # key -> Promise que resolve quando blob estiver pronto
preAquecerSet = new Set()
preAquecerCache = new Set()

preAquecerVideo = (url) ->
  return unless url?
  key = keyForUrl(url)
  return if preAquecerSet.has(key) or blobCache.has(key)
  preAquecerSet.add(key)

  if FORCE_BLOB_PLAYBACK
    p = fetch(url, {mode:'cors', credentials:'omit', cache:'force-cache'})
      .then (r) ->
        throw new Error("HTTP #{r.status}") unless r.ok
        Promise.all([r.arrayBuffer(), getContentType(r)])
      .then ([buf, type]) ->
        blob = new Blob([buf], {type})
        blobUrl = URL.createObjectURL(blob)
        blobCache.set(key, {url: blobUrl, type, size: buf.byteLength})
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
#   return item?.arquivoUrl unless FORCE_BLOB_PLAYBACK and item?.is_video
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
  if item.is_video and item.arquivoUrl then preAquecerVideo(item.arquivoUrl)
  else if item.is_image and item.arquivoUrl then preAquecerImagem(item.arquivoUrl)


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
  ultimoVideo: null
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


  # =============== Loop ===============

  executar: ->
    clearTimeout @promessa if @promessa

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
  playVideo: (itemAtual) ->
    @ultimoVideo = "video-player-#{itemAtual.id}"
    clearTimeout(@playTimer1) if @playTimer1?
    clearTimeout(@playTimer2) if @playTimer2?

    key       = keyForUrl(itemAtual.arquivoUrl)
    pend      = pendingBlobs.get(key)

    chooseAndPlay = (v) =>
      entry = blobCache.get(key)
      finalUrl = if FORCE_BLOB_PLAYBACK and entry?.url then entry.url else itemAtual.arquivoUrl
      ctype   = entry?.type or itemAtual.content_type or 'video/mp4'
      injectSource(v, finalUrl, ctype)
      v.currentTime = 0
      v.play().catch (e) -> console.warn('play falhou', e)

    @playTimer1 = setTimeout =>
      v = document.getElementById(@ultimoVideo)
      return unless v?

      # Se existir um blob pendente, aguarda até 10s; usa blob somente se ficar pronto.
      if FORCE_BLOB_PLAYBACK and pend? and not blobCache.get(key)?
        Promise.race([
          pend.then -> 'ok'
          new Promise (res) -> setTimeout (-> res('timeout')), 10000
        ]).finally =>
          chooseAndPlay(v)   # se blob não existir ainda, cairá na URL original
      else
        chooseAndPlay(v)
    , 0

    @playTimer2 = setTimeout =>
      v = document.getElementById(@ultimoVideo)
      v?.paused and v.play().catch (e) -> console.warn('replay falhou', e)
    , 1000

    return


  # revoga blob ao parar, eliminando vazamento e caches velhos
  # NÃO remove nem revoga blob do cache: apenas pausa e limpa o <video>
  stopUltimoVideo: ->
    return unless @ultimoVideo
    v = document.getElementById(@ultimoVideo)
    if v?
      try v.pause() catch e then null
      try
        v.removeAttribute('src')
        while v.firstChild? then v.removeChild(v.firstChild)  # remove <source>
        v.load()  # desaloca o decoder sem mexer no blobCache
      catch e then null
    @ultimoVideo = null
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
#     @ultimoVideo = "video-player-#{itemAtual.id}"

#     clearTimeout(@playTimer1) if @playTimer1?
#     clearTimeout(@playTimer2) if @playTimer2?

#     getUltimoVideo = -> document.getElementById(@ultimoVideo)

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
#   #   @ultimoVideo = "video-player-#{itemAtual.id}"

#   #   setTimeout =>
#   #     video = document.getElementById(@ultimoVideo)
#   #     if video
#   #       video.currentTime = 0
#   #       video.play()

#   #   setTimeout =>
#   #     video = document.getElementById(@ultimoVideo)
#   #     video.play() if video?.paused
#   #   , 1000
#   #   return
#   stopUltimoVideo: ->
#     videoId = @ultimoVideo
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
#     @ultimoVideo = null

#     # limpa timers de play (ver D)
#     clearTimeout(@playTimer1) if @playTimer1?
#     clearTimeout(@playTimer2) if @playTimer2?
#     @playTimer1 = @playTimer2 = null
#     return

#   # stopUltimoVideo: ->
#   #   videoId = @ultimoVideo
#   #   return unless videoId

#   #   video = document.getElementById(videoId)
#   #   video.pause() if video
#   #   @ultimoVideo = null
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


descobrirTimezone = (callback) ->
  # fallback em caso de erro
  done = (tz) ->
    timezoneGlobal = tz or "America/Sao_Paulo"
    callback?(timezoneGlobal)

  try
    tz = Intl.DateTimeFormat().resolvedOptions().timeZone
    if tz
      return done(tz)
  catch e
    console.warn "Intl timezone falhou:", e

  fetch('http://ip-api.com/json')
    .then((r) -> r.json())
    .then((j) ->
      if j?.timezone
        done(j.timezone)
      else
        throw new Error("timezone não encontrado")
    )
    .catch ->
      fetch('https://worldtimeapi.org/api/ip')
        .then((r) -> r.json())
        .then((j) -> done(j?.timezone))
        .catch((e) ->
          console.warn "Falha ao detectar timezone:", e
          done("America/Sao_Paulo")
        )

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


relogio =
  exec: ->

    descobrirTimezone (timezone) ->
      console.log "Timezone: #{timezone}"

      # now = moment.tz(new Date, 'America/Los_Angeles');
      now = moment.tz(new Date, timezone);
      hour = now.get('hour')
      min  =  now.get('minute')

      # hour = now.get('hour')
      # min  = now.get('minute')
      # sec  = now.getSeconds()

      hour = "0#{hour}" if hour < 10
      min  = "0#{min}"  if min < 10
      # sec  = "0#{sec}"  if sec < 10

      @elemHora ||= document.getElementById('hora')
      @elemHora.innerHTML = hour + ':' + min if @elemHora
      @timer = setTimeout relogio.exec, 1000 * 60 # 1 minuto
      # @elemHora.innerHTML = hour + ':' + min + ':' + sec if @elemHora
      # setTimeout relogio.exec, 1000


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
  computed:
    now: -> Date.now()
  mounted: ->
    @loading = true
    @mouse()
    relogio.exec()



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


