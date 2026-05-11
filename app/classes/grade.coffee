fs      = require 'fs'
path    = require 'path'
shell   = require 'shelljs'
request = require 'request'

baseUrl = "#{ENV.API_SERVER_URL}/publicidades"

module.exports = ->
  ctrl =
    tvIds: []
    data: {}
    # folderKeys: ['images', 'videos', 'audios', 'feeds']
    folderKeys: ['images', 'videos', 'feeds']
    apagarFolder: (tvId) ->
      return unless tvId
      tvFolder = "#{getTvFolderPublic(tvId)}"
      if fs.existsSync(tvFolder)
        fs.rmSync(tvFolder, { recursive: true, force: true })

    createFolders: (tvId) ->
      return unless tvId
      folders = []
      tvFolder = "#{getTvFolderPublic(tvId)}"
      folders.push tvFolder
      for it in @folderKeys
        folders.push "#{tvFolder}/#{it}/"

      for folder in folders
        if !fs.existsSync(folder)
          fs.mkdirSync(folder, { recursive: true })
      return
    checkTv: (tvId) ->
      # Server-side timer (web.coffee não chama daqui — é o setInterval
      # 10s lá embaixo). Per-tv, sem deviceId — o relay agrega devices
      # sob o mesmo tvId no cache local e não rastreia individualmente.
      # Pra rastreio per-device, o caminho é o JS do player bater 3s no
      # /check_tv com deviceId, que o web.coffee propaga upstream quando
      # tem app_versao (Corpflix Android) ou loga no console (todos).
      url = "#{baseUrl}/check_tv.json?id=#{tvId}"
      # Silenciado por default — ver `verboseLog` em web.coffee. Roda a
      # cada 10s × 30 TVs = 3 linhas/s. 95% do volume do MIDIAINDOOR-out.log.
      console.log "cloud #{url}" if process.env.DEBUG_VERBOSE_LOG == '1'
      request url, (error, response, body)=>
        if error || response?.statusCode != 200
          return
        resp = JSON.parse(body)
        @_restartGrade(resp)
    getList: (tvId, opt={}) ->
      if opt.refazerArquivos
        @apagarFolder(tvId)

      @createFolders(tvId)

      @tvIds.push(tvId)
      @tvIds = @tvIds.map (e) -> parseInt(e)
      @tvIds = @tvIds.flatten().unique()


      # Fase 1 do roadmap "Tv has many devices" (corpflix/ROADMAP.md):
      # propaga deviceId upstream pro Rails quando o caller passou em
      # opt. Permite o Rails ver qual device pediu a grade (ex: das 20
      # devices da tv_id=64, qual delas reiniciou agora). Backward
      # compat: sem opt.deviceId, URL fica idêntica ao que era antes.
      url = "#{baseUrl}/grade.json?id=#{tvId}"
      url += "&deviceId=#{opt.deviceId}" if opt.deviceId
      global.logs.create "URL: #{url}"

      @getDataOffline(tvId)
      @data[tvId].offline = true

      request url, (error, response, body)=>
        if error || response?.statusCode != 200
          erro = 'Request Failed.'
          erro += " Status Code: #{response.statusCode}." if response?.statusCode
          erro += " #{error}" if error
          global.logs.create "Grade -> getList -> #{erro}"
          global.feeds.getList(tvId)
          return

        @data[tvId].offline = false
        jsonData = JSON.parse(body)

        if Object.empty(jsonData || {})
          return global.logs.create 'Grade -> Erro: Não existe Dados da Grade!'

        atualizarPlayer = global.versao_player? &&
          global.versao_player != jsonData.versao_player

        scPrint.success "============================"
        scPrint.success "cliente_id: #{jsonData.cliente_id}"
        scPrint.success "tv_id: #{tvId}"
        scPrint.success "============================"

        console.log "entrou em @handlelist(jsonData)"
        @handlelist(jsonData)
        console.log "entrou em saveLogo"
        @saveLogo(tvId, jsonData.logo_url)
        console.log "entrou em saveDataJson"
        @saveDataJson(tvId)

        # global.versionsControl.exec(atualizarPlayer)
        console.log "entrou em getList"
        global.feeds.getList(tvId)
    _restartGrade: (opt) ->
      # opt.restart_player = true
      # console.log 'xxxxxxxxxxxxxxxxxxxxxxxxxxx'
      # console.log opt.restart_player
      tvId = opt.id
      return unless tvId
      dataTv = @data[tvId] || {}
      if opt.restart_player_em != dataTv.restart_player_em
        # # scPrint.warning tvId
        # global.restart_tv_ids ||= []
        # global.restart_tv_ids.push parseInt(tvId)
        scPrint.warning "Baixando nova grade de TV ##{tvId}:"
        @getList(tvId, refazerArquivos: true)

    handlelist: (jsonData)->
      tvId = jsonData.id

      tvPath = getTvFolder(tvId)
      tvPath = tvPath.split('\\').join('/') if process.platform == 'win32'

      global.versao_player = jsonData.versao_player

      @data[tvId] =
        id:        tvId
        cor:       jsonData.cor
        path:      tvPath
        layout:    jsonData.layout
        cidade:    jsonData.cidade
        offline:   false
        resolucao: jsonData.resolucao
        informacoes: jsonData.informacoes
        # versao_player: jsonData.versao_player
        # current_version: global.versionsControl?.currentVersion
        restart_player_em: jsonData.restart_player_em
        # `audio_enabled` (Boolean): vem do ERP por TV. Default false em todo
        # stack (ERP → relay → player → bridge Android) — overwhelmingly
        # mute é o que prédio/academia/clínica querem; áudio é opt-in
        # explícito do admin. `?? false` cobre payloads antigos que ainda
        # não trazem o campo.
        audio_enabled: jsonData.audio_enabled ? false

        # Schedule de tela ligada/desligada — vem do ERP por TV pra
        # proteger painel contra burn-in fora do horário comercial.
        #
        # Defaults industry-standard pra digital signage residencial
        # (lobby de prédio / academia / clínica): janela 06:00-23:00,
        # 7 dias, schedule LIGADO. 7h de descanso noturno (23h-6h)
        # cobre o período de tráfego mínimo na maioria dos prédios e
        # protege o painel sem impactar visibilidade.
        #
        # Sites 24/7 (portaria 24h, hospital, etc.) explicitam
        # `screen_schedule_enabled=false` na grade do ERP — opt-out
        # explícito > opt-in implícito (TVs sem config sensata por
        # default seriam o caminho que mais queima painel).
        #
        # Quando ativo, JS roda tick a cada 60s checando dia/hora
        # local; fora da janela, pinta overlay preto fullscreen +
        # chama setScreenActive(false) no bridge (Android para
        # ExoPlayer e esconde WebView). Voltar pra dentro da janela
        # remove overlay e dispara playVideoFramed do próximo item.
        screen_schedule_enabled: jsonData.screen_schedule_enabled ? true
        screen_active_days:      jsonData.screen_active_days ? '1,2,3,4,5,6,7'
        screen_active_start:     jsonData.screen_active_start ? '06:00'
        screen_active_end:       jsonData.screen_active_end ? '23:00'

      @data[tvId].finance = jsonData.finance if jsonData.finance
      @data[tvId].weather = jsonData.weather if jsonData.weather

      for vinculo in (jsonData.vinculos || []).sortByField('ordem')
        continue unless vinculo.ativado

        item =
          id:         vinculo.id
          ordem:      vinculo.ordem
          titulo:     vinculo.titulo
          ativado:    vinculo.ativado
          horarios:   vinculo.horarios
          segundos:   vinculo.segundos
          tipo_midia: vinculo.tipo_midia

        console.log "tvId #{tvId} estou em handlelist #{vinculo.tipo_midia}"

        switch vinculo.tipo_midia
          when 'musica', 'midia' then @handleMidia(tvId, vinculo, item)
          when 'informativo'     then @handleInformativo(tvId, vinculo, item)
          when 'playlist'        then @handlePlaylist(tvId, vinculo, item)
          when 'mensagem'        then @handleMensagem(tvId, vinculo, item)
          when 'clima'           then @handleClima(tvId, vinculo, item)
          when 'feed'            then @handleFeed(tvId, vinculo, item)
      return
    handleMidia: (tvId, vinculo, item, lista=null)->
      console.log "estou em handleMidia vinculo: #{vinculo}"
      return unless vinculo.midia

      item.url      = vinculo.midia.original
      item.size     = vinculo.midia.size
      item.midia_id = vinculo.midia.id
      item.extensao = vinculo.midia.extension
      item.is_audio = vinculo.midia.is_audio
      item.is_image = vinculo.midia.is_image
      item.is_video = vinculo.midia.is_video

      pasta = "videos" if item.is_video
      pasta = "audios" if item.is_audio
      pasta = "images" if item.is_image
      item.pasta = pasta




      item.content_type = vinculo.midia.content_type
      # Cache-bust: ERP envia `versao_cache` (= anexo_updated_at.to_i). Inclui
      # no filename pra que web.coffee possa servir com Cache-Control: immutable
      # e o browser da TV não re-baixe ao reiniciar. Re-upload no admin muda
      # versao_cache → filename muda → URL muda → cache miss natural.
      # Sem versao_cache (ERP antigo): cai no nome legado `<id>.<ext>`.
      sufixoVersao = if vinculo.midia.versao_cache then "-v#{vinculo.midia.versao_cache}" else ''
      nome_arquivo = "#{vinculo.midia.id}#{sufixoVersao}.#{vinculo.midia.extension}"
      nome_arquivo = @ajustImageNameToWebp item if item.is_image

      item.nome_arquivo = nome_arquivo

      if nome_arquivo
        filePath = getTvFolder(tvId)
        filePath = "#{filePath}/#{pasta}" if pasta
        filePath = "#{filePath}/#{nome_arquivo}"
        item.filePath = filePath
        console.log "tvId #{tvId} fazendo Download de:"
        console.log item
        Download.exec(item)
      # item.saveOn = filePath

      lista ||= @data[tvId]
      lista[vinculo.posicao] ||= []
      item.filePath ||= item.url

      # item.arquivoUrl = item.url || item.filePath
      item.arquivoUrl = item.filePath

      lista[vinculo.posicao].push item


      return
    handleInformativo: (tvId, vinculo, item, lista=null)->
      return unless vinculo.mensagem

      item.mensagem = vinculo.mensagem
      lista ||= @data[tvId]
      lista[vinculo.posicao] ||= []
      lista[vinculo.posicao].push item
      return
    handlePlaylist: (tvId, vinculo, item)->
      playlist = vinculo.playlist
      return if playlist?.ativado == false

      playlist.vinculos ||= []
      return if playlist.vinculos.empty()

      for vinc in playlist.vinculos.sortByField('ordem')
        continue unless vinc.ativado

        subItem =
          id:         vinc.id
          ordem:      vinc.ordem
          titulo:     vinc.titulo
          ativado:    vinc.ativado
          horarios:   vinc.horarios
          segundos:   vinc.segundos
          tipo_midia: vinc.tipo_midia

        switch vinc.tipo_midia
          when 'midia' then @handleMidia(tvId, vinc, subItem, item)
          when 'clima' then @handleClima(tvId, vinc, subItem, item)
          when 'feed'  then @handleFeed(tvId, vinc, subItem, item)
          when 'informativo' then @handleInformativo(tvId, vinc, subItem, item)
          when 'mensagem'  then @handleMensagem(tvId, vinc, subItem)

      @data[tvId][vinculo.posicao] ||= []
      @data[tvId][vinculo.posicao].push item
      return
    handleMensagem: (tvId, vinculo, item)->
      return unless vinculo.mensagem
      item.mensagem = vinculo.mensagem.texto

      @data[tvId][vinculo.posicao] ||= []
      @data[tvId][vinculo.posicao].push item
      @data[tvId][vinculo.posicao] = @data[tvId][vinculo.posicao].unique()
      return
    handleClima: (tvId, vinculo, item, lista=null)->
      return unless vinculo.clima
      lista ||= @data[tvId]

      item.uf      = vinculo.clima.uf
      item.nome    = vinculo.clima.nome
      item.country = vinculo.clima.country
      lista[vinculo.posicao] ||= []
      lista[vinculo.posicao].push item
      return
    handleFeed: (tvId, vinculo, item, lista=null)->
      return unless vinculo.feed
      lista ||= @data[tvId]

      item.url       = vinculo.feed.url
      item.fonte     = vinculo.feed.fonte
      item.categoria = vinculo.feed.categoria
      lista[vinculo.posicao] ||= []
      lista[vinculo.posicao].push item
      return
    ajustImageNameToWebp: (imageObj)->
      return null unless imageObj.nome_arquivo

      extension = imageObj.nome_arquivo.match(/\.jpg|\.jpeg|\.png|\.gif|\.webp/i)?[0] || ''
      imageNome = imageObj.nome_arquivo.split('/').pop().replace(extension, '').removeSpecialCharacters()
      # "#{imageNome}#{extension}"
      "#{imageNome}.webp"
    saveLogo: (tvId, downloadUrl)->
      logoObj = {}
      console.log "saveLogo tvId: #{tvId} url: #{downloadUrl}"
      return unless downloadUrl
      nome_arquivo = @ajustImageNameToWebp(nome_arquivo: 'logo')
      filePath = "#{getTvFolder(tvId)}/#{nome_arquivo}"
      logoObj.filePath = filePath
      logoObj.url = downloadUrl

      # logoObj.arquivoUrl = downloadUrl || filePath
      logoObj.arquivoUrl = filePath


      @data[tvId].logo = logoObj

      params =
        tvId: tvId
        url: downloadUrl
        filePath: filePath
        is_logo: true
        nome_arquivo: nome_arquivo

      console.log "saveLogo Download: #{params}"
      Download.exec(params)
    saveDataJson: (tvId) ->
      dados = JSON.stringify @data[tvId], null, 2

      folder = getTvFolderPublic(tvId)
      if !fs.existsSync(folder)
        fs.mkdirSync(folder, { recursive: true })


      try
        fs.writeFile "#{folder}/grade.json", dados, (error)->
          return global.logs.error "Grade -> saveDataJson -> #{error}", tags: class: 'grade' if error
          global.logs.create 'Grade -> grade.json salvo com sucesso!'
      catch e
        global.logs.error "Grade -> saveDataJson -> #{e}", tags: class: 'grade'
      return
    getDataOffline: (tvId) ->
      @data[tvId] ||= {}
      folder = getTvFolderPublic(tvId)

      console.log  "tv #{tvId} - pegando grade offline"
      try
        @data[tvId] = JSON.parse(fs.readFileSync("#{folder}/grade.json", 'utf8') || '{}')
      catch e
        global.logs.error "Grade -> getDataOffline -> #{e}", tags: class: 'grade'
      return
    apagarAntigos: (tvId) ->
      pastas = {}

      pastasDeConteudoSuperior = ['images', 'videos']

      ###############################################
      # utilizando @folderKeys estava apagando os feeds
      # analisarPastas = @folderKeys
      analisarPastas = pastasDeConteudoSuperior
      ###############################################

      for pasta in analisarPastas
        pastas[pasta] = []

      @getDataOffline(tvId)
      @data ||= {}
      data = @data[tvId] || {}
      for it in (data.conteudo_superior || [])
        for it2 in (it.conteudo_superior || [])
          pasta = it2.pasta
          nomeArquivo = it2.nome_arquivo
          if pasta && nomeArquivo
            # pastas[pasta] ||= []
            pastas[pasta].push nomeArquivo

      for pasta, arquivos of pastas
        # console.log pasta
        # console.log arquivos
        removerMidiasAntigas(tvId, pasta, arquivos)


    startCheckTvTimer: ->
      setInterval =>
        if process.env.DEBUG_VERBOSE_LOG == '1'
          console.log("=========================================================")
          console.log("Checar se grade mudou: chamar ctrl.checkTv de  #{@tvIds}")
          console.log("=========================================================")
        for tvId in @tvIds
          ctrl.checkTv(tvId)
      , 10000

    # Sanity check de boot: percorre todas as `public/<tvId>/grade.json` em
    # disco e re-enfileira via `Download.exec` qualquer item cujo arquivo
    # local esteja faltando. Idempotente — `Download.exec` faz `fs.stat`
    # interno e só baixa se ausente ou com tamanho divergente.
    #
    # Motivação: a EC2 relay vinha sendo rebootada em ciclos (perdendo a
    # fila in-memory do downloader) E o fluxo normal de re-download depende
    # de uma TV bater `/grade?tvId=X` PRIMEIRO ou alguém chamar
    # `/download_new_content`. Se a fila travasse com `ctrl.loading=true`
    # ou se a primeira chamada de `getList` falhasse silenciosamente upstream,
    # a TV ficava tela-preta indefinidamente até intervenção manual.
    # Incidente 2026-05-11: TV 63 ficou tela-preta pós-reboot 12:00 UTC com
    # `/63/videos/` literalmente vazia apesar de `grade.json` + `feeds/`
    # estarem atualizados; só restart manual do PM2 recuperou.
    #
    # Filtra `tvId` por `^\d+$` — `public/` acumulou subdirs com nomes
    # corrompidos (`null/`, `63\`/`, `123456789/`, etc) de requests com
    # tvId mal-formado; iterá-los só polui log.
    #
    # Roda fire-and-forget. Não bloqueia boot, não espera S3.
    warmupCacheFromDisk: ->
      try
        publicDir = pastaPublic()
        return unless fs.existsSync(publicDir)

        tvDirs = fs.readdirSync(publicDir).filter (name) ->
          /^\d+$/.test(name) &&
            fs.statSync(path.join(publicDir, name)).isDirectory()

        scPrint.warning "============================================"
        scPrint.warning "warmupCacheFromDisk: #{tvDirs.length} TVs em disco"
        scPrint.warning "============================================"

        enfileirados = 0
        for tvId in tvDirs
          gradePath = path.join(publicDir, tvId, 'grade.json')
          continue unless fs.existsSync(gradePath)

          # Popula @tvIds pra `startCheckTvTimer` já fazer `checkTv` dessas
          # TVs sem precisar esperar a primeira request bater. Sem isso, o
          # relay fica "burro" pós-reboot até cada TV se manifestar — janela
          # em que mudanças no ERP (restart_player_em) podem passar
          # despercebidas.
          tvIdInt = parseInt(tvId)
          @tvIds.push(tvIdInt) unless tvIdInt in @tvIds

          try
            gradeData = JSON.parse(fs.readFileSync(gradePath, 'utf8') || '{}')
          catch e
            global.logs?.error "warmupCacheFromDisk: grade.json inválido tv #{tvId} -> #{e}",
              tags: class: 'grade'
            continue

          @data[tvIdInt] ||= gradeData
          enfileirados += @_enfileirarFaltantes(tvId, gradeData)

        scPrint.warning "warmupCacheFromDisk: #{enfileirados} arquivos faltantes enfileirados"
      catch e
        global.logs?.error "warmupCacheFromDisk: #{e}", tags: class: 'grade'
      return

    # Percorre recursivamente `conteudo_superior` e `conteudo_mensagem` da
    # grade — playlists podem aninhar items dentro de items via `handlePlaylist`,
    # então é DFS. Pra cada item com `filePath`, verifica se existe em disco
    # com tamanho ok; se não, chama `Download.exec(item)`. Retorna número
    # de items enfileirados (pra log).
    _enfileirarFaltantes: (tvId, gradeData) ->
      enfileirados = 0
      visit = (item) =>
        return unless item && typeof item is 'object'
        if item.filePath && item.url
          fullPath = "#{pastaPublic()}/#{item.filePath}"
          precisa = true
          try
            if fs.existsSync(fullPath)
              stats = fs.statSync(fullPath)
              if item.size
                margem = 2
                precisa = !(stats.size <= (item.size + margem) &&
                            stats.size >= (item.size - margem))
              else
                precisa = stats.size <= 1024
          catch e
            precisa = true
          if precisa
            global.Download?.exec(item)
            enfileirados++
        # DFS — playlists empurram sub-items dentro do próprio item via
        # `lista[posicao]` em handleMidia (ver grade.coffee:241).
        for key in ['conteudo_superior', 'conteudo_mensagem']
          if Array.isArray(item[key])
            visit(sub) for sub in item[key]
        return

      for key in ['conteudo_superior', 'conteudo_mensagem']
        if Array.isArray(gradeData?[key])
          visit(it) for it in gradeData[key]
      enfileirados
  global.grade = ctrl
