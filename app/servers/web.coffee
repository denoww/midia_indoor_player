express = require 'express'
path    = require 'path'

module.exports = (opt={}) ->
  app = express()
  server = app.listen(ENV.HTTP_PORT)
  scPrint.success("#{"http://localhost:#{ENV.HTTP_PORT}"} ligado")

  versao = global.versionsControl?.currentVersion || global.grade?.data?.versao_player || '--'
  global.logs.info "Iniciando servidor HTTP! Versão #{versao}"

  app.use express.static(path.join( __dirname, '../assets/'))
  app.use express.static(path.join( __dirname, '../public/'))

  # Resolve o erro do CROSS de Access-Control-Allow-Origin
  app.all '*', (req, res, next)->
    res.header 'Content-Type', 'application/json'
    res.header 'Access-Control-Allow-Origin', '*'
    res.header 'Access-Control-Allow-Methods', 'OPTIONS,GET,POST,PUT,DELETE'
    res.header 'Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With'
    return res.sendStatus(200) if req.method == 'OPTIONS'
    next()

  app.get '/', (req, res) ->
    global.logs.create "Request GET / params: #{JSON.stringify(req.body || {})}"
    res.type "text/html"
    res.sendFile path.join( __dirname, '../assets/templates/index.html')

  app.get '/grade', (req, res) ->
    global.logs.create "Request GET /grade params: #{JSON.stringify(req.body || {})}"
    if Object.empty global.grade.data
      global.grade.getList()
      res.sendStatus(400)
      return
    res.send JSON.stringify global.grade.data

  app.get '/feeds', (req, res) ->
    global.logs.create "Request GET /feeds params: #{JSON.stringify(req.body || {})}"
    if Object.empty global.feeds.data
      global.feeds.getList()
      res.sendStatus(400)
      return
    res.send JSON.stringify global.feeds.data
