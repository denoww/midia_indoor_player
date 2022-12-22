process.env.NODE_ENV ||= 'development'
switch process.env.NODE_ENV
  when 'development'
    env = require('node-env-file')
    env(__dirname + '/.env_DEVELOPMENT')

global.ENV = process.env # vars. ambiente neste arquivo .env_DEVELOPMENT
global.ENV.NAME = process.env.NODE_ENV

console.log  "#{global.ENV.NAME} enviroment"
