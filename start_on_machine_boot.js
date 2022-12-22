// startup on boot (da lib auto-launch)
var AutoLaunch, autoLauncher;

AutoLaunch = require('auto-launch');

projectPath = process.cwd();

autoLauncher = new AutoLaunch({
  name: 'midia_indoor_player',
  path: projectPath+'/tasks/init.sh'
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

console.log('Criado startup em ~/.config/autostart/init.sh.desktop')
