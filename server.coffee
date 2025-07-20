# server.coffee

process.on 'SIGTERM', -> console.log "🔴 Recebeu SIGTERM externo para matar servidor !"
process.on 'SIGINT',  -> console.log "🔴 Recebeu SIGINT externo para matar servidor !"
process.on 'exit', (code) -> console.log "⚠️ Processo finalizado com código #{code}"



global.homePath = (process.env.HOME or process.env.USERPROFILE or process.env.HOMEPATH) + '/'

path = require 'path'

require 'coffeescript/register'
require './env'
require 'sc-node-tools'
require('./app/classes/logs')(true)

require './app/classes/commons'
require('./app/classes/download')()
require('./app/classes/grade')()
require('./app/classes/feeds')()
require('./app/servers/web')()
# global.grade.startCheckTvTimer()


# Garante que o processo continue vivo (mesmo sem requisições)
# setInterval ->
#   console.log "⏳ Servidor ainda ativo: #{new Date()}"
# , 60000
