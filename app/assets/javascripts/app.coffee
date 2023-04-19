# Sentry.init
#   dsn: 'https://ac78f87fac094b808180f86ad8867f61@sentry.io/1519364'
#   integrations: [new Sentry.Integrations.Vue({Vue, attachProps: true})]

# Sentry.configureScope (scope)->
#   scope.setUser id: "TV_ID_#{process.env.TV_ID}_FRONTEND"

# alert('2')

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

onLoaded = ->
  vm.loaded ||= gradeObj.loaded && feedsObj.loaded
  vm.loading = false if vm.loaded

  timelineConteudoSuperior.init()
  timelineConteudoMensagem.init()

@checkTv = ->
  success = (resp)=>
    data = resp.data
    # console.log data
    restartPlayerSeNecessario(data)

  error = (resp) => console.log resp

  Vue.http.get('/check_tv').then success, error

@gradeObj =
  tentar: 10
  tentativas: 0
  get: (onSuccess, onError)->
    return if @loading
    @loading = true

    success = (resp)=>
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
      setTimeout (-> gradeObj.get()), @tentarNovamenteEm
      onError?()

    Vue.http.get('/grade').then success, error
    return
  handle: (data)->
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

    Vue.http.get('/feeds').then success, error
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
  init: ->
    return unless vm.loaded
    @executar() unless @promessa?
  executar: ->
    clearTimeout @promessa if @promessa

    itemAtual = @getNextItem()
    return console.error "@getNextItem() - itemAtual é indefinido!", itemAtual unless itemAtual

    vm.indexConteudoSuperior = vm.listaConteudoSuperior.getIndexByField 'id', itemAtual.id
    if !vm.indexConteudoSuperior?
      vm.listaConteudoSuperior.push itemAtual
      vm.indexConteudoSuperior = vm.listaConteudoSuperior.length - 1

    @stopUltimoVideo()

    segundos = (itemAtual.segundos * 1000) || 5000
    @promessa = setTimeout ->
      timelineConteudoSuperior.executar()
    , segundos

    @playVideo(itemAtual) if itemAtual.is_video
    return
  playVideo: (itemAtual)->
    @ultimoVideo = "video-player-#{itemAtual.id}"

    setTimeout =>
      video = document.getElementById(@ultimoVideo)
      if video
        video.currentTime = 0
        video.play()

    setTimeout =>
      video = document.getElementById(@ultimoVideo)
      video.play() if video?.paused
    , 1000
    return
  stopUltimoVideo: ->
    videoId = @ultimoVideo
    return unless videoId

    video = document.getElementById(videoId)
    video.pause() if video
    @ultimoVideo = null
    return
  getNextItem: ->
    lista = vm.grade.data.conteudo_superior || []
    total = lista.length
    return console.warn "vm.grade.data.conteudo_superior está vazio!", lista unless total

    index = @nextIndex
    index = 0 if index >= total

    @nextIndex++
    @nextIndex = 0 if @nextIndex >= total

    currentItem = lista[index]
    switch currentItem.tipo_midia
      when 'feed'     then @getItemFeed(currentItem)
      when 'playlist' then @getItemPlaylist(currentItem)
      else currentItem
  getItemFeed: (currentItem)->
    feedItems = feedsObj.data[currentItem.fonte]?[currentItem.categoria] || []
    if feedItems.empty()
      console.warn "Feeds de #{currentItem.fonte} #{currentItem.categoria} está vazio"
      timelineConteudoSuperior.promessa = setTimeout ->
        timelineConteudoSuperior.executar()
      , 2000
      return

    fonte = currentItem.fonte
    categ = currentItem.categoria
    @feedIndex[fonte] ||= {}

    if !@feedIndex[fonte][categ]?
      @feedIndex[fonte][categ] = 0
    else
      @feedIndex[fonte][categ]++

    if @feedIndex[fonte][categ] >= feedItems.length
      @feedIndex[fonte][categ] = 0

    index = @feedIndex[fonte][categ]
    feed = feedItems[index] || feedItems[0]

    return unless feed
    currentItem.id     = "#{currentItem.id}#{feed.nome_arquivo}"
    currentItem.data   = feed.data
    currentItem.qrcode = feed.qrcode
    currentItem.titulo = feed.titulo
    currentItem.titulo_feed = feed.titulo_feed
    currentItem.categoria_feed = feed.categoria_feed
    currentItem.nome_arquivo = feed.nome_arquivo
    currentItem
  getItemPlaylist: (playlist)->
    if !@playlistIndex[playlist.id]?
      @playlistIndex[playlist.id] = 0
    else
      @playlistIndex[playlist.id]++

    if @playlistIndex[playlist.id] >= playlist.conteudo_superior.length
      @playlistIndex[playlist.id] = 0

    currentItem = playlist.conteudo_superior[@playlistIndex[playlist.id]]

    return currentItem if currentItem.tipo_midia != 'feed'
    @getItemFeed(currentItem)

@timelineConteudoMensagem =
  promessa:  null
  nextIndex: 0
  playlistIndex: {}
  init: ->
    return unless vm.loaded
    @executar() unless @promessa?
  executar: ->
    clearTimeout @promessa if @promessa

    itemAtual = @getNextItem()
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
  getNextItem: ->
    lista = vm.grade.data.conteudo_mensagem || []
    total = lista.length
    return unless total

    index = @nextIndex
    index = 0 if index >= total

    @nextIndex++
    @nextIndex = 0 if @nextIndex >= total

    currentItem = lista[index]
    switch currentItem.tipo_midia
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
    currentItem

descobrirTimezone = (callback) ->
  console.log "Descobrindo timezone..."

  timezone = 'America/Sao_Paulo'
  error = ->
    console.log 'erro em descobrirTimezone'
    callback(timezone)
  success = (resp)=>
    success = resp.status == 200
    if success
      data = resp.data
      timezone = data.timezone
    callback(timezone)

  url = 'http://ip-api.com/json'
  Vue.http.get(url).then success, error


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

    updateOnlineStatus = ->
      vm.online = navigator.onLine

    setInterval ->
      # return if vm.loaded
      checkTv()
    , 1000 * 3 # 1 segundo

    setTimeout ->
      return if vm.loaded
      updateOnlineStatus()
      gradeObj.get ->
        feedsObj.get ->
          vm.loading = false
          vm.loaded = true
    , 1000 * 1 # 1 segundo

    setInterval ->
      updateOnlineStatus()
      gradeObj.get ->
        feedsObj.get ->
          vm.loading = false
          vm.loaded = true
    , 1000 * 60 * 2 # a cada 2 minutos

    window.addEventListener 'online',  updateOnlineStatus
    window.addEventListener 'offline',  updateOnlineStatus
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


restartPlayerSeNecessario = (data) ->
  xSegundos = data.restart_player_em_x_segundos
  return unless xSegundos
  console.log "restart_player será executado em #{xSegundos} segundos"
  _exec = -> window.location.reload()
  setTimeout =>
    _exec()
  , xSegundos*1000

    # @timers = []
    # @timers.push = setTimeout => @exec(), 2000


