# server.coffee

global.homePath = (process.env.HOME or process.env.USERPROFILE or process.env.HOMEPATH) + '/'

path = require 'path'

require 'coffeescript/register'
require './env'
require 'sc-node-tools'
require('./app/classes/logs')(true)
# require('./start_on_machine_boot')

require './app/classes/commons'
require('./app/classes/versions_control')()
require('./app/classes/download')()
require('./app/classes/grade')()
require('./app/classes/feeds')()
require('./app/servers/web')()

global.grade.startCheckTvTimer()
