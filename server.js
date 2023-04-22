if (process.versions.electron) {
  delete process.env.ELECTRON_ENABLE_SECURITY_WARNINGS;
  process.env.ELECTRON_DISABLE_SECURITY_WARNINGS = true;
  process.env.ELECTRON_ENABLE_STACK_DUMPING = true;
}

global.homePath = (process.env.HOME || process.env.USERPROFILE || process.env.HOMEPATH) + '/';

path = require('path');

require('coffeescript').register();
require('./env');
require('sc-node-tools');
require('./app/classes/logs')(true);
// require('./start_on_machine_boot')

if (process.versions.electron) {
  require('./application');
} else {
  require('./app/classes/commons');
  require('./app/classes/versions_control')();
  require('./app/classes/download')();
  require('./app/classes/grade')();
  require('./app/classes/feeds')();
  require('./app/servers/web')();
}

process.on('uncaughtException', function (error) {
  logs.error("UncaughtException: " + error);
});
