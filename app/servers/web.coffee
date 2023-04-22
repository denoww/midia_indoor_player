express = require 'express'
path    = require 'path'
bodyParser = require('body-parser')


module.exports = (opt={}) ->
  app = express()
  server = app.listen(ENV.HTTP_PORT)
  scPrint.success("#{"http://localhost:#{ENV.HTTP_PORT}"} ligado")

  versao = global.versionsControl?.currentVersion || global.versao_player || '--'
  global.logs.info "Iniciando servidor HTTP! Versão #{versao}"
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
    global.logs.create "Request GET / params: #{JSON.stringify(params)}"
    res.type "text/html"
    res.sendFile path.join( __dirname, '../assets/templates/index.html')

  app.get '/grade', (req, res) ->
    params = req.getParams()
    global.logs.create "Request GET /grade params: #{JSON.stringify(params)}"
    tvId = params.tvId
    data = global.grade.data[tvId] || {}
    if Object.empty data
      global.grade.getList(tvId)
      res.sendStatus(400)
      return
    res.send JSON.stringify data


  app.get '/check_tv', (req, res) ->
    params = req.getParams()
    global.logs.create "Request GET /check_tv params: #{JSON.stringify(params)}"
    tvId = params.tvId
    tvId = parseInt(tvId) if tvId
    resp = {}
    global.restart_tv_ids ||= []

    deveReiniciar = global.restart_tv_ids.includes(tvId) if tvId
    if deveReiniciar
      global.restart_tv_ids.remove(tvId)
      xSegundos = 20
      resp.restart_player_em_x_segundos = xSegundos
      scPrint.warning "tv ##{tvId} -> Player web será reiniciado em #{xSegundos} segundos"
      # global.server_started = false
    res.send JSON.stringify resp

  app.get '/feeds', (req, res) ->
    params = req.getParams()
    global.logs.create "Request GET /feeds params: #{JSON.stringify(params)}"
    tvId = params.tvId
    data = global.feeds.data[tvId] || {}
    if Object.empty data
      global.feeds.getList(tvId)
      res.sendStatus(400)
      return
    res.send JSON.stringify data
