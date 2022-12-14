const createWindowsInstaller = require('electron-winstaller').createWindowsInstaller
const path = require('path')

getInstallerConfig()
  .then(createWindowsInstaller)
  .catch((error) => {
    console.error(error.message || error)
    process.exit(1)
  })

function getInstallerConfig () {
  console.log('creating windows installer')
  const rootPath = path.join('./')
  const outPath = path.join(rootPath, 'dist')

  return Promise.resolve({
    appDirectory: path.join(outPath, 'midia_indoor_player-win32-ia32/'),
    noMsi: true,
    outputDirectory: path.join(outPath, 'windows-installer'),
    exe: 'midia_indoor_player.exe',
    setupExe: 'midia_indoor_player.exe',
    setupIcon: path.join(rootPath, 'app/assets/images/icon.ico')
  })
}
