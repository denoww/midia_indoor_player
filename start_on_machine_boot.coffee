# startup on boot (da lib auto-launch)
AutoLaunch = require('auto-launch')
autoLauncher = new AutoLaunch(name: 'midia_indoor_player', path: '/var/lib/midia_indoor_player/tasks/init.sh')
autoLauncher.enable()
autoLauncher.isEnabled().then((isEnabled) ->
  if isEnabled
    return
  autoLauncher.enable()
  return
).catch (err) ->
  throw err
  return
