// server.js

process.on('SIGTERM', () => console.log("🔴 Recebeu SIGTERM externo para matar servidor !"));
process.on('SIGINT', () => console.log("🔴 Recebeu SIGINT externo para matar servidor !"));
process.on('exit', (code) => console.log(`⚠️ Processo finalizado com código ${code}`));

// Define o caminho home global
global.homePath = (
  process.env.HOME ||
  process.env.USERPROFILE ||
  process.env.HOMEPATH
) + '/';

const path = require('path');

// Registra suporte a CoffeeScript
require('coffeescript/register');

// Carrega configurações e módulos
require('./env');
require('sc-node-tools');
// require('./app/classes/logs')(true);

require('./app/classes/commons');
// require('./app/classes/versions_control')();

require('./app/classes/download')();
require('./app/classes/grade')();
require('./app/classes/feeds')();
require('./app/servers/web')();

global.grade.startCheckTvTimer();

// Mantém o processo vivo, se necessário
// setInterval(() => {
//   console.log(`⏳ Servidor ainda ativo: ${new Date()}`);
// }, 60000);
