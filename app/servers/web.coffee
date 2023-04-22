express = require 'express'
path    = require 'path'
bodyParser = require('body-parser')


module.exports = (opt={}) ->
  app = express()
  global.logs.info "Iniciando servidor HTTP! Versão #{versao}"
  server = app.listen(ENV.HTTP_PORT)
  scPrint.success("#{"http://localhost:#{ENV.HTTP_PORT}"} ligado")

  setTimeout ->
    require("#{process.cwd()}/start_player");
  , 7000


  versao = global.versionsControl?.currentVersion || global.versao_player || '--'
  # global.server_started = true

  app.use express.static(path.join( __dirname, '../assets/'))
  app.use express.static(path.join( __dirname, '../../public/'))


  # Resolve o erro do CROSS de Access-Control-Allow-Origin
  app.all '*', (req, res, next)->
    res.header 'Content-Type', 'application/json'
    res.header 'Access-Control-Allow-Origin', '*'
    res.header 'Access-Control-Allow-Methods', 'OPTIONS,GET,POST,PUT,DELETE'
    res.header 'Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With'

    req.getParams = ->
      resp = Object.assign( @body || {}, @query || {}, @params || {} )
      format = resp?.format?.replace('.', '')
      delete resp['0']
      resp.format = format if format
      resp

    return res.sendStatus(200) if req.method == 'OPTIONS'
    next()

  app.get '/', (req, res) ->
    params = req.getParams()
    console.log  "Request GET / params: #{JSON.stringify(params)}"
    res.type "text/html"
    res.sendFile path.join( __dirname, '../assets/templates/index.html')

  app.get '/grade', (req, res) ->
    params = req.getParams()
    console.log  "Request GET /grade params: #{JSON.stringify(params)}"
    tvId = params.tvId
    data = global.grade.data[tvId] || {}
    if Object.empty data
      global.grade.getList(tvId)
      res.sendStatus(400)
      return
    res.send JSON.stringify data


  app.get '/check_tv', (req, res) ->
    params = req.getParams()
    console.log  "Request GET /check_tv params: #{JSON.stringify(params)}"
    tvId = params.tvId
    tvId = parseInt(tvId) if tvId
    data = global.grade.data[tvId] || {}

    resp = {}
    resp.restart_player_em = data.restart_player_em
    res.send JSON.stringify resp

  app.get '/feeds', (req, res) ->
    params = req.getParams()
    console.log  "Request GET /feeds params: #{JSON.stringify(params)}"
    tvId = params.tvId
    data = global.feeds.data[tvId] || {}
    if Object.empty data
      global.feeds.getList(tvId)
      res.sendStatus(400)
      return
    res.send JSON.stringify data


  app.get  '/npm_run', (req, res) ->
    # GET -> http://midiaindoor.seucondominio.com.br:4001/npm_run?cmd=deploy
    npmCtrl.execNpmRun(req, res)

  app.post  '/npm_run', (req, res) ->
    # POST -> http://midiaindoor.seucondominio.com.br:4001/npm_run?cmd=deploy
    npmCtrl.execNpmRun(req, res)

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
