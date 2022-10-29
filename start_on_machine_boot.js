// startup on boot (da lib auto-launch)
var AutoLaunch, autoLauncher;

AutoLaunch = require('auto-launch');

autoLauncher = new AutoLaunch({
  name: 'midia_indoor_player',
  path: '/var/lib/midia_indoor_player/tasks/init.sh'
});

autoLauncher.enable();

autoLauncher.isEnabled().then(function(isEnabled) {
  if (isEnabled) {
    return;
  }
  autoLauncher.enable();
}).catch(function(err) {
  throw err;
});
