fs = require 'fs'


process.env.NODE_ENV ||= 'development'
# switch process.env.NODE_ENV
#   when 'development'
#     env = require('node-env-file')
#     env(__dirname + '/.env')

envFile = __dirname + '/.env'
if fs.existsSync(envFile)
  # env = require('node-env-file')
  # console.log "¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨"
  # console.log "ENV: Carregando #{envFile}"
  # console.log "¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨"
  # x = env(envFile)
  # console.log x

  console.log "-----------------------------------------------------------------"
  console.log "ENV: Carregando #{envFile}"
  console.log "¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨"
  content = fs.readFileSync(envFile, 'utf-8');
  content.split(/\r?\n/).forEach (line) ->
    if line
      [k, v] = line.split('=')
      v = v.replace(/\"/, "")
      v = v.replace(/\'/, "")
      console.log "#{k}: #{v}"
      process.env[k] = v
  console.log "-----------------------------------------------------------------"

# console.log process.env

global.ENV = process.env # vars. ambiente neste arquivo .env
global.ENV.NAME = process.env.NODE_ENV

console.log  "#{global.ENV.NAME} enviroment"
