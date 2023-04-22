# global.homePath = (process.env.HOME || process.env.USERPROFILE || process.env.HOMEPATH) + '/'
# global.homePath = '/var/lib/' if global.homePath == '/root/'

path = require('path');



require('../env')
require('sc-node-tools')
require('../app/classes/logs')()
require('../app/classes/commons')
require('../app/classes/feeds')()
# require('../app/classes/grade')()
apagarArquivosAntigosDaGrade()
