global.restartApp = ->
  scPrint.warning '-----------------------------------------'
  scPrint.warning 'Reiniciando app...'
  scPrint.warning '-----------------------------------------'
  restartFile = require('path').resolve(process.cwd(), 'restart.js')
  shell = require("child_process").exec
  shell "touch #{restartFile}"

