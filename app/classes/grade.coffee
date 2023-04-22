fs      = require 'fs'
path    = require 'path'
shell   = require 'shelljs'
request = require 'request'

baseUrl = "#{ENV.API_SERVER_URL}/publicidades"

module.exports = ->
  ctrl =
    tvIds: []
    data: {}
    checkTv: (tvId) ->
      url = "#{baseUrl}/check_tv.json?id=#{tvId}"
      console.log "/check_tv.json"
      request url, (error, response, body)=>
        if error || response?.statusCode != 200
          return
        resp = JSON.parse(body)
        @_restartGrade(resp)
    getList: (tvId) ->
      Download.createFolders(tvId)

      @tvIds.push(tvId)
      @tvIds = @tvIds.flatten().unique()

      url = "#{baseUrl}/grade.json?id=#{tvId}"
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
        scPrint.success "tv_id: #{ENV.TV_ID}"
        scPrint.success "============================"

        @handlelist(jsonData)
        @saveLogo(tvId, jsonData.logo_url)
        @saveDataJson(tvId)

        global.versionsControl.exec(atualizarPlayer)
        global.feeds.getList(tvId)
    _restartGrade: (opt) ->
      # opt.restart_player = true
      # console.log 'xxxxxxxxxxxxxxxxxxxxxxxxxxx'
      # console.log opt.restart_player
      if opt.restart_player
        tvId = opt.id
        # scPrint.warning tvId
        return unless tvId
        global.restart_tv_ids ||= []
        global.restart_tv_ids.push parseInt(tvId)
        scPrint.warning "Baixando nova grade de TV ##{opt.id}"
        @getList(tvId)

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
        current_version: global.versionsControl?.currentVersion

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

        switch vinculo.tipo_midia
          when 'musica', 'midia' then @handleMidia(tvId, vinculo, item)
          when 'informativo'     then @handleInformativo(tvId, vinculo, item)
          when 'playlist'        then @handlePlaylist(tvId, vinculo, item)
          when 'mensagem'        then @handleMensagem(tvId, vinculo, item)
          when 'clima'           then @handleClima(tvId, vinculo, item)
          when 'feed'            then @handleFeed(tvId, vinculo, item)
      return
    handleMidia: (tvId, vinculo, item, lista=null)->
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
      nome_arquivo = "#{vinculo.midia.id}.#{vinculo.midia.extension}"
      nome_arquivo = @ajustImageNameToWebp item if item.is_image

      item.nome_arquivo = nome_arquivo

      filePath = getTvFolder(tvId)
      filePath = "#{filePath}/#{pasta}" if pasta
      filePath = "#{filePath}/#{nome_arquivo}"
      item.filePath = filePath
      # item.saveOn = filePath

      lista ||= @data[tvId]
      lista[vinculo.posicao] ||= []
      lista[vinculo.posicao].push item
      item.tvId = tvId
      Download.exec(item)
      return
    handleInformativo: (tvId, vinculo, item, lista=null)->
      return unless vinculo.mensagem

      item.mensagem = vinculo.mensagem
      lista ||= @data[tvId]
      lista[vinculo.posicao] ||= []
      lista[vinculo.posicao].push item
      return
    handlePlaylist: (tvId, vinculo, item)->
      return unless (vinculo.playlist.vinculos || []).any()

      for vinc in (vinculo.playlist.vinculos || []).sortByField('ordem')
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

      @data[tvId][vinculo.posicao] ||= []
      @data[tvId][vinculo.posicao].push item
      return
    handleMensagem: (tvId, vinculo, item)->
      return unless vinculo.mensagem
      item.mensagem = vinculo.mensagem.texto

      @data[tvId][vinculo.posicao] ||= []
      @data[tvId][vinculo.posicao].push item
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
      @data[tvId].logo = {}
      return unless downloadUrl
      nome_arquivo = @ajustImageNameToWebp(nome_arquivo: 'logo')
      filePath = "#{getTvFolder(tvId)}/#{nome_arquivo}"
      @data[tvId].logo.filePath = filePath

      params =
        tvId: tvId
        url: downloadUrl
        filePath: filePath
        is_logo: true
        nome_arquivo: nome_arquivo

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

      global.logs.create 'Grade -> Pegando grade de grade.json'
      try
        @data[tvId] = JSON.parse(fs.readFileSync("#{folder}/grade.json", 'utf8') || '{}')
      catch e
        global.logs.error "Grade -> getDataOffline -> #{e}", tags: class: 'grade'
      return
    apagarAntigos: ->
      @getDataOffline()
      data = global.grade.data
      return if Object.empty(data || {})
      # console.log data

      # itensAtuais = []
      # for fonte, categorias of data
      #   for categoria, items of categorias || []
      #     itensAtuais.push item.nome_arquivo for item in items || []
      # console.log itensAtuais
      # return if itensAtuais.empty()
      # removerMidiasAntigas 'feeds', itensAtuais


    # init: ->
    #   ctrl.getList()
    #   setInterval ->
    #     return if global.versionsControl.updating
    #     global.logs.create 'Grade -> Atualizando lista!'
    #     ctrl.getList()
    #   , 1000 * 60 * (ENV.TEMPO_ATUALIZAR || 5)

    init: ->
      setInterval =>
        for tvId in @tvIds.flatten().unique()
          ctrl.checkTv(tvId)
      , 10000
  ctrl.init()
  global.grade = ctrl
