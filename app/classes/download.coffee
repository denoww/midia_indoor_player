fs      = require 'fs'
Jimp    = require 'jimp'
http    = require 'http'
path    = require 'path'
https   = require 'https'
sharp   = null
request = require 'request'
  .defaults encoding: null

module.exports = ->
  ctrl =
    fila: []
    loading: false
    init: ->
      folders  = []
      folders.push global.homePath + '.config/'
      basePath = global.homePath + '.config/sc_player/'

      folders.push basePath
      folders.push basePath + 'downloads'
      folders.push basePath + ENV.DOWNLOAD_VIDEOS
      folders.push basePath + ENV.DOWNLOAD_IMAGES
      folders.push basePath + ENV.DOWNLOAD_AUDIOS
      folders.push basePath + ENV.DOWNLOAD_FEEDS

      for folder in folders
        if !fs.existsSync(folder)
          fs.mkdirSync(folder)
      return
    exec: (params, opts={})->
      pasta = global.configPath + ENV.DOWNLOAD_VIDEOS if params.is_video
      pasta = global.configPath + ENV.DOWNLOAD_IMAGES if params.is_image
      pasta = global.configPath + ENV.DOWNLOAD_AUDIOS if params.is_audio
      pasta = global.configPath + ENV.DOWNLOAD_FEEDS  if params.is_feed || opts.is_feed
      pasta = global.configPath + 'downloads/' if params.is_logo || opts.is_logo

      unless pasta
        logs.error "Download -> exec -> Nenhuma pasta encontrada para #{params.nome_arquivo}!"
        return

      fullPath = pasta + params.nome_arquivo
      fs.stat fullPath, (error, stats)=>
        return next() if !error && alreadyExists(params, stats.size) && !opts.force
        return ctrl.fila.push Object.assign {}, params, opts if ctrl.loading
        return next() unless ctrl.validURL(params.url)

        if params.is_video || params.is_audio
          doDownloadAlternative params, fullPath, ->
            ctrl.loading = false
            next()
          return

        ctrl.loading = true
        if ['5', 5].includes(ENV.TV_ID) && global.grade?.data && global.grade.data.versao_player < 1.8
          doDownload params, fullPath, ->
            ctrl.loading = false
            next()
          return

        doDownloadToBuffer params, fullPath, ->
          ctrl.loading = false
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

      logs.create "Download -> #{params.nome_arquivo}, URL: #{params.url}"

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
    file      = fs.createWriteStream(fullPath)
    protocolo = http
    protocolo = https if params.url.match(/https/)
    logs.create "Download -> #{params.nome_arquivo}, URL: #{params.url}"

    protocolo.get params.url, (res)->
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
      image.toFile fullPath, (error, info)->
        createLogError('convertBufferToWebp', error, params)
        callback?()
      return

    image.metadata (error, metadata) ->
      return if createLogError('convertBufferToWebp', error, params, callback)

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

  ctrl.init()

  global.Download = ctrl
