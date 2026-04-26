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
      global.grade.getList(tvId) if global.grade
      res.sendStatus(400)
      return
    res.send JSON.stringify data


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
    res.send JSON.stringify resp

  app.get '/download_new_content', (req, res) ->
    params = req.getParams()
    console.log  "Request GET /download_new_content params: #{JSON.stringify(params)}"
    tvId = params.tvId
    tvId = parseInt(tvId) if tvId
    global.grade.getList(tvId) if tvId

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
