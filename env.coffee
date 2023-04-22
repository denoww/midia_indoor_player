return if global.envCarregado
global.envCarregado = true
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
  obj = {}
  content.split(/\r?\n/).forEach (line) ->
    if line
      [k, v] = line.split('=')
      v = v.replace(/\"/g, "")
      v = v.replace(/\'/g, "")
      # v = false if v == 'false'
      # v = true if v == 'true'
      obj[k] = v

# console.log process.env

processArgs = process?.argv?.slice?(2, 100) || [] # vem da linha de comando que LIGA server.coffee
for arg in processArgs
  # Exemplo: nodemon --inspect server.coffee -- LINKERCLOUD=true
  # Exemplo: pm2 delete portaria; pm2 start server.coffee --name=portaria -- LINKERCLOUD=true; pm2 logs
  [k, v] = arg.split('=')
  # v = false if v == 'false'
  # v = true if v == 'true'
  obj[k] = v


console.log obj
Object.assign(process.env, obj);
# console.log typeof(obj.fullscreen)
# console.log typeof(process.env.fullscreen)

global.ENV = process.env # vars. ambiente neste arquivo .env
global.ENV.NAME = process.env.NODE_ENV


console.log  "#{global.ENV.NAME} enviroment"
console.log "-----------------------------------------------------------------"
