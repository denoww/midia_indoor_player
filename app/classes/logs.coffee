shell  = require 'shelljs'
Sentry = require './sentry'

module.exports = (showConsole=false)->
  ctrl =
    create: (message, options={})->
      return if !message
      console.log message #if showConsole || ENV.NODE_ENV == 'development'

      #Sentry.log message, options if options.send
      return
    info: (message, options={})->
      options.send  = true
      options.level = 'info'
      @create message, options
    debug: (message, options={})->
      options.send  = true
      options.level = 'debug'
      @create message, options
    error: (message, options={})->
      options.send  = true
      options.level = 'error'
      @create message, options
    fatal: (message, options={})->
      options.send  = true
      options.level = 'fatal'
      @create message, options
    warning: (message, options={})->
      options.send  = true
      options.level = 'warning'
      @create message, options
  global.logs = ctrl
