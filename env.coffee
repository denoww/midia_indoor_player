fs = require 'fs'


process.env.NODE_ENV ||= 'development'
# switch process.env.NODE_ENV
#   when 'development'
#     env = require('node-env-file')
#     env(__dirname + '/.env')

envFile = __dirname + '/.env'
if fs.existsSync(envFile)
  env = require('node-env-file')
  console.log "ENV: Carregando #{envFile}"
  env(envFile)

global.ENV = process.env # vars. ambiente neste arquivo .env
global.ENV.NAME = process.env.NODE_ENV

console.log  "#{global.ENV.NAME} enviroment"
