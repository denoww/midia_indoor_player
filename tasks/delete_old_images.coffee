global.homePath = (process.env.HOME || process.env.USERPROFILE || process.env.HOMEPATH) + '/'
global.homePath = '/var/lib/' if global.homePath == '/root/'

path = require('path');
global.configPath = path.join( __dirname, 'public/');

require('../env')
require('sc-node-tools')
require('../app/classes/logs')()
require('../app/classes/feeds')()
global.feeds.deleteOldImages()
