############# HOW TO USE ###############
# require('./scErrorsHandle')
# scErrorsHandle(err)
############# HOW TO USE ###############

global.scErrorsHandle = (err) ->
  error = err?.stack || err?.message || err
  scPrint.error error
