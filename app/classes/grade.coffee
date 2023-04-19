fs      = require 'fs'
path    = require 'path'
shell   = require 'shelljs'
request = require 'request'

module.exports = ->
  ctrl =
    data: {}
    checkTv: ->
      url = "#{ENV.API_SERVER_URL}/publicidades/check_tv.json?id=#{ENV.TV_ID}"
      console.log "/check_tv.json"
      request url, (error, response, body)=>
        if error || response?.statusCode != 200
          return
        data = JSON.parse(body)
        @_restartAppSeNecessario(data)
    getList: ->
      url = "#{ENV.API_SERVER_URL}/publicidades/grade.json?id=#{ENV.TV_ID}"
      global.logs.create "URL: #{url}"

      @getDataOffline()
      @data.offline = true

      request url, (error, response, body)=>
        if error || response?.statusCode != 200
          erro = 'Request Failed.'
          erro += " Status Code: #{response.statusCode}." if response?.statusCode
          erro += " #{error}" if error
          global.logs.create "Grade -> getList -> #{erro}"
          global.feeds.getList()
          return

        @data.offline = false
        jsonData = JSON.parse(body)

        if Object.empty(jsonData || {})
          return global.logs.create 'Grade -> Erro: Não existe Dados da Grade!'

        atualizarPlayer = @data?.versao_player? &&
          @data.versao_player != jsonData.versao_player

        scPrint.success "============================"
        scPrint.success "cliente_id: #{jsonData.cliente_id}"
        scPrint.success "tv_id: #{ENV.TV_ID}"
        scPrint.success "============================"

        @handlelist(jsonData)
        @saveLogo(jsonData.logo_url)
        @saveDataJson()

        global.versionsControl.exec(atualizarPlayer)
        global.feeds.getList()
    _restartAppSeNecessario: (data) ->
      # data.restart_player = true
      xSegundos = 1
      # console.log 'xxxxxxxxxxxxxxxxxxxxxxxxxxx'
      # console.log data.restart_player
      @data.restart_player = data.restart_player
      if data.restart_player
        scPrint.warning "App vai reiniciar daqui #{xSegundos} segundos"
        setInterval =>
          restartApp()
        , xSegundos*1000

    handlelist: (jsonData)->
      configPath = global.configPath
      configPath = configPath.split('\\').join('/') if process.platform == 'win32'

      @data =
        id:        jsonData.id
        cor:       jsonData.cor
        path:      configPath
        layout:    jsonData.layout
        cidade:    jsonData.cidade
        offline:   false
        resolucao: jsonData.resolucao
        informacoes: jsonData.informacoes
        versao_player: jsonData.versao_player
        current_version: global.versionsControl?.currentVersion

      @data.finance = jsonData.finance if jsonData.finance
      @data.weather = jsonData.weather if jsonData.weather

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
          when 'musica', 'midia' then @handleMidia(vinculo, item)
          when 'informativo'     then @handleInformativo(vinculo, item)
          when 'playlist'        then @handlePlaylist(vinculo, item)
          when 'mensagem'        then @handleMensagem(vinculo, item)
          when 'clima'           then @handleClima(vinculo, item)
          when 'feed'            then @handleFeed(vinculo, item)
      return
    handleMidia: (vinculo, item, lista=null)->
      return unless vinculo.midia

      item.url      = vinculo.midia.original
      item.size     = vinculo.midia.size
      item.midia_id = vinculo.midia.id
      item.extensao = vinculo.midia.extension
      item.is_audio = vinculo.midia.is_audio
      item.is_image = vinculo.midia.is_image
      item.is_video = vinculo.midia.is_video

      item.pasta = "videos" if item.is_video
      item.pasta = "audios" if item.is_audio
      item.pasta = "images" if item.is_image


      item.content_type = vinculo.midia.content_type
      item.nome_arquivo = "#{vinculo.midia.id}.#{vinculo.midia.extension}"
      item.nome_arquivo = @ajustImageNameToWebp item if item.is_image

      lista ||= @data
      lista[vinculo.posicao] ||= []
      lista[vinculo.posicao].push item
      Download.exec(item)
      return
    handleInformativo: (vinculo, item, lista=null)->
      return unless vinculo.mensagem

      item.mensagem = vinculo.mensagem
      lista ||= @data
      lista[vinculo.posicao] ||= []
      lista[vinculo.posicao].push item
      return
    handlePlaylist: (vinculo, item)->
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
          when 'midia' then @handleMidia(vinc, subItem, item)
          when 'clima' then @handleClima(vinc, subItem, item)
          when 'feed'  then @handleFeed(vinc, subItem, item)
          when 'informativo' then @handleInformativo(vinc, subItem, item)

      @data[vinculo.posicao] ||= []
      @data[vinculo.posicao].push item
      return
    handleMensagem: (vinculo, item)->
      return unless vinculo.mensagem
      item.mensagem = vinculo.mensagem.texto

      @data[vinculo.posicao] ||= []
      @data[vinculo.posicao].push item
      return
    handleClima: (vinculo, item, lista=null)->
      return unless vinculo.clima
      lista ||= @data

      item.uf      = vinculo.clima.uf
      item.nome    = vinculo.clima.nome
      item.country = vinculo.clima.country
      lista[vinculo.posicao] ||= []
      lista[vinculo.posicao].push item
      return
    handleFeed: (vinculo, item, lista=null)->
      return unless vinculo.feed
      lista ||= @data

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
    saveLogo: (logoUrl)->
      return @data.logo_nome = null unless logoUrl
      @data.logo_nome = @ajustImageNameToWebp nome_arquivo: logoUrl

      params =
        url: logoUrl
        is_logo: true
        nome_arquivo: @data.logo_nome

      Download.exec(params)
    saveDataJson: ->
      dados = JSON.stringify @data, null, 2
      try
        fs.writeFile 'grade.json', dados, (error)->
          return global.logs.error "Grade -> saveDataJson -> #{error}", tags: class: 'grade' if error
          global.logs.create 'Grade -> grade.json salvo com sucesso!'
      catch e
        global.logs.error "Grade -> saveDataJson -> #{e}", tags: class: 'grade'
      return
    getDataOffline: ->
      global.logs.create 'Grade -> Pegando grade de grade.json'
      try
        @data = JSON.parse(fs.readFileSync('grade.json', 'utf8') || '{}')
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

  setInterval ->
    return if global.versionsControl.updating
    global.logs.create 'Grade -> Atualizando lista!'
    ctrl.getList()
  , 1000 * 60 * (ENV.TEMPO_ATUALIZAR || 5)

  setInterval ->
    ctrl.checkTv()
  , 10000

  ctrl.getList()
  global.grade = ctrl
