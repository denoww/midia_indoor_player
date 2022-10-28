Sentry = require '@sentry/node'

Sentry.init
  dsn:              'https://ac78f87fac094b808180f86ad8867f61@sentry.io/1519364'
  release:          ENV.npm_package_version
  environment:      ENV.NODE_ENV
  attachStacktrace: true

Sentry.configureScope (scope)->
  scope.setTag 'tv_id', ENV.TV_ID

ctrl =
  instance: Sentry
  log: (message, options={})->
    tags  = options.tags || {}
    extra = options.extra || {}
    Sentry.withScope (scope)->
      Object.keys(tags).forEach (key)->
        scope.setTag(key, tags[key])

      Object.keys(extra).forEach (key)->
        scope.setExtra(key, extra[key])

      Sentry.captureEvent
        level:   options.level || 'info'
        message: "TV [ID: #{ENV.TV_ID}] #{message}"
  info: (message, options={})->
    options.level = 'info'
    @log message, options
  debug: (message, options={})->
    options.level = 'debug'
    @log message, options
  error: (message, options={})->
    options.level = 'error'
    @log message, options
  fatal: (message, options={})->
    options.level = 'fatal'
    @log message, options
  warning: (message, options={})->
    options.level = 'warning'
    @log message, options

module.exports = ctrl
