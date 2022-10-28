if (process.versions.electron) {
  delete process.env.ELECTRON_ENABLE_SECURITY_WARNINGS;
  process.env.ELECTRON_DISABLE_SECURITY_WARNINGS = true;
  process.env.ELECTRON_ENABLE_STACK_DUMPING = true;
}

global.homePath = (process.env.HOME || process.env.USERPROFILE || process.env.HOMEPATH) + '/';
global.configPath = global.homePath + '.config/sc_player/';

require('coffeescript').register();
require('./env');
require('sc-node-tools');
require('./app/classes/logs')(true);

if (process.versions.electron) {
  require('./application');
} else {
  require('./app/classes/versions_control')();
  require('./app/classes/download')();
  require('./app/classes/grade')();
  require('./app/classes/feeds')();
  require('./app/servers/web')();
}

process.on('uncaughtException', function (error) {
  logs.error("UncaughtException: " + error);
});
