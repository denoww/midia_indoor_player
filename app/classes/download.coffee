fs      = require 'fs'
Jimp    = require 'jimp'
http    = require 'http'
path    = require 'path'
https   = require 'https'
sharp   = null
request = require 'request'
  .defaults encoding: null

module.exports = ->
  # Watchdog do `ctrl.loading`. Histórico: o flag era setado pra `true`
  # antes de baixar imagem e revertido no callback do download. Mas
  # callbacks podem ser pulados em paths não-felizes:
  #   - `convertBufferToWebp` jogando exceção síncrona dentro do callback
  #     de `sharp.metadata` (metadata vazia → `metadata.width / metadata.height`
  #     → TypeError) — exceção escapa do try/catch de `doDownloadToBuffer`
  #     porque é assíncrona;
  #   - `image.toFile` no branch `is_logo` recebendo erro mas exception em
  #     `createLogError` antes do `callback?()`.
  # Resultado: `ctrl.loading` ficava `true` pra sempre; fila empilhava sem
  # consumir; tela-preta na TV até reboot/restart manual. Incidente
  # 2026-05-11 com TV 63 foi o caso clássico.
  #
  # Watchdog em paralelo com o reset normal: cada vez que setamos
  # `loading=true`, agenda timeout que força reset + retoma a fila depois
  # de `LOADING_WATCHDOG_MS`. Idempotente (clearTimeout cancela quando
  # o callback de sucesso roda).
  #
  # 2 minutos cobre download lento de imagem (~10MB com sharp resize)
  # 4× sobre o caso normal — falso-positivo é raríssimo. Se a EC2 estiver
  # tão lenta a ponto de baixar+resize de 1 imagem demorar mais que isso,
  # o relay já está em estado degradado e re-tentar é melhor que travar.
  LOADING_WATCHDOG_MS = 2 * 60 * 1000
  watchdogTimer = null

  setLoading = (val) ->
    ctrl.loading = val
    clearTimeout(watchdogTimer) if watchdogTimer?
    watchdogTimer = null
    if val
      watchdogTimer = setTimeout ->
        return unless ctrl.loading
        logs?.error "Download watchdog: ctrl.loading travado " +
          "por #{LOADING_WATCHDOG_MS/1000}s — forçando reset e processando fila",
          tags: class: 'download'
        ctrl.loading = false
        next()
      , LOADING_WATCHDOG_MS

  ctrl =
    fila: []
    loading: false
    exec: (params, opts={})->
      unless params.filePath
        # logs.error "Download -> exec -> faltou passar argumento \"filePath\" para #{params.nome_arquivo}!"
        return

      # fullPath = params.saveOn || params.filePath
      fullPath = "#{pastaPublic()}/#{params.filePath}"
      fs.stat fullPath, (error, stats)=>
        return next() if !error && alreadyExists(params, stats.size) && !opts.force
        return ctrl.fila.push Object.assign {}, params, opts if ctrl.loading
        return next() unless ctrl.validURL(params.url)

        if params.is_video || params.is_audio
          setLoading(true)
          doDownloadAlternative params, fullPath, ->
            setLoading(false)
            next()
          return

        setLoading(true)
        if ['5', 5].includes(ENV.TV_ID) && global.grade?.data && global.grade.data.versao_player < 1.8
          doDownload params, fullPath, ->
            setLoading(false)
            next()
          return

        doDownloadToBuffer params, fullPath, ->
          setLoading(false)
          next()
    validURL: (url)->
      pattern = new RegExp('^(http|https):\\/\\/(\\w+:{0,1}\\w*)?(\\S+)(:[0-9]+)?(\\/|\\/([\\w#!:.?+=&%!\\-\\/]))?', 'i')
      patternYoutube = new RegExp('youtube\\.com|youtu\\.be', 'i')
      patternScripts = new RegExp('\\.js|\\.css', 'i')
      !!pattern.test(url) && !patternYoutube.test(url) && !patternScripts.test(url)

  # depracated
  doDownload = (params, fullPath, callback)->
    Jimp.read params.url, (error, image)->
      if error
        logs.create "Download -> Jimp #{error}", extra: params: params
        doDownloadAlternative(params, callback)
        return

      logs.create "Download iniciado -> #{params.nome_arquivo}, URL: #{params.url}"

      posicaoCover = Jimp.VERTICAL_ALIGN_MIDDLE
      if image.bitmap.width / image.bitmap.height < 0.7
        posicaoCover = Jimp.VERTICAL_ALIGN_TOP

      image
        .cover(1648, 927, Jimp.HORIZONTAL_ALIGN_CENTER | posicaoCover)
        .quality(80)
        .write fullPath, (error, img)->
          return callback?() unless error
          logs.error "Download -> image #{error}", extra: params: params
          doDownloadAlternative(params, callback)
    return

  doDownloadAlternative = (params, fullPath, callback)->
    protocolo = http
    protocolo = https if params.url.match(/https/)
    logs.create "Download alternativo -> #{params.nome_arquivo}, URL: #{params.url}"

    protocolo.get params.url, (res)->
      # Aborta sem escrever o arquivo se o servidor não respondeu 200.
      #
      # Sem essa checagem, qualquer body de erro (ex: XML AccessDenied de
      # 263 bytes do S3 quando ACL não está pública) era gravado como se
      # fosse o vídeo. ExoPlayer das TVs falhava parsear → Source error
      # 3003 → loop infinito de skips. Incidente 2026-04-28: 240 vídeos
      # quebrados em produção por ~6h até diagnóstico, ver commit
      # `seucondominio:71a7459e22`.
      #
      # `doDownloadToBuffer` (caminho de imagem, abaixo) já fazia esse
      # check via `request.get`. O `doDownloadAlternative` (caminho de
      # vídeo/áudio via http nativo) não fazia — agora faz.
      #
      # `res.resume()` drena o body de erro pro socket fechar limpo
      # (sem isso, request fica em half-open até timeout do TCP).
      if res.statusCode != 200
        logs.create "Download alternativo HTTP #{res.statusCode} (skip) " +
          "-> #{params.nome_arquivo}, URL: #{params.url}"
        res.resume()
        callback?()
        return

      file = fs.createWriteStream(fullPath)
      res.on 'data', (data)->
        file.write data
      .on 'end', ->
        file.end()
        callback?()
      .on 'error', (error)->
        createLogError('doDownloadAlternative', error, params, callback)
    .on 'error', (error)->
      createLogError('doDownloadAlternative', error, params, callback)

  doDownloadToBuffer = (params, fullPath, callback)->
    logs.create "Download Buffer -> #{params.nome_arquivo}, URL: #{params.url}"

    return unless params.url
    url = encodeURI params.url.trim()

    request.get url, encoding: null, (error, resp, buffer)->
      if error || resp.statusCode != 200
        return createLogError('doDownloadToBuffer', error, params, callback)

      try
        convertBufferToWebp(buffer, params, fullPath, callback)
      catch error
        createLogError('doDownloadToBuffer', error, params, callback)
    return

  convertBufferToWebp = (buffer, params, fullPath, callback)->
    sharp ||= require 'sharp'
    image = sharp(buffer).toFormat('webp').webp(quality: 75)

    if params.is_logo
      try
        image.toFile fullPath, (error, info)->
          createLogError('convertBufferToWebp', error, params)
          callback?()
      catch e
        # Exceção síncrona de `sharp` (buffer corrompido, formato não
        # suportado, etc) escapa em paths não-felizes. Sem este catch o
        # callback nunca disparava e `ctrl.loading` ficava travado.
        createLogError('convertBufferToWebp', e, params, callback)
      return

    # `image.metadata` é assíncrona — qualquer throw síncrono dentro deste
    # callback escapa do try/catch de `doDownloadToBuffer` (que envolve
    # apenas a chamada síncrona inicial). Wrap explícito + validação de
    # metadata pra não cair em `null.width / null.height = TypeError` em
    # imagens parcialmente baixadas. Garante que `callback` SEMPRE roda,
    # mesmo em paths anômalos — pré-requisito pra `setLoading(false)`
    # liberar a fila.
    image.metadata (error, metadata) ->
      return if createLogError('convertBufferToWebp', error, params, callback)

      unless metadata?.width and metadata?.height
        return createLogError('convertBufferToWebp',
          new Error("metadata sem width/height: #{JSON.stringify(metadata)}"),
          params, callback)

      try
        position = sharp.gravity.center
        position = sharp.gravity.north if metadata.width / metadata.height < 0.8

        image.resize
          fit:      sharp.fit.cover
          width:    1648
          height:   927
          position: position
        .flatten background: '#000000'
        .toFile fullPath, (error, info)->
          createLogError('convertBufferToWebp', error, params)
          callback?()
      catch e
        createLogError('convertBufferToWebp', e, params, callback)
    return

  createLogError = (method, error, params, callback)->
    return unless error
    logs.error "Download -> #{method}: #{error}",
      extra: path: params.url
      tags: class: 'download'
    callback?()
    return true

  next = ->
    return unless ctrl.fila.length
    ctrl.exec(ctrl.fila.shift())

  alreadyExists = (params, size=null)->
    return size > 1024 unless params.size
    margem = 2
    size <= (params.size + margem) &&
    size >= (params.size - margem)

  # ctrl.init()

  global.Download = ctrl
