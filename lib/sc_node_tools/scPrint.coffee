############# HOW TO USE ###############
# require('./lib/scPrint')
# scPrint.error('It Broken')
# scPrint.warning('Caution')
# scPrint.info('Caution')
# scPrint.success('Caution')
############# HOW TO USE ###############

global.scPrint =
  error:   (msg) -> _print msg, color: 'red'
  warning: (msg) -> _print msg, color: 'yellow'
  info:    (msg) -> _print msg, color: 'cian'
  success: (msg) -> _print msg, color: 'green'

  db: (msg)->
    _print msg, type: 'db         |', color: 'cian-dark'
  web: (msg)->
    _print msg, type: 'web        |', color: 'blue-light'
  channel: (msg)->
    _print msg, type: 'channel    |', color: 'green-light'
  guarita: (msg)->
    _print msg, type: 'guarita    |', color: 'gray-light'
  anviz: (msg)->
    _print msg, type: 'anviz      |', color: 'cian'
  henry: (msg)->
    _print msg, type: 'henry      |', color: 'yellow-light'
  linker: (msg)->
    _print msg, type: 'linker      |', color: 'blue-lighter'
  monitoramento: (msg)->
    _print msg, type: 'monitoram..|', color: 'blue'
  sincronizacao: (msg)->
    _print msg, type: 'sincroniz..|', color: 'yellow-light'

# private

_print = (msg, opt={}) ->
  colorText = "\x1b[38;5;#{_codeColors[opt.color]}m%s\x1b[0m"

  if opt.type
    console.log "#{colorText} %s", opt.type, msg
  else
    console.log "#{colorText}", msg

_codeColors =
  'black':          '232'
  'white':          '231'

  'gray-darker':    '235'
  'gray-dark':      '240'
  'gray':           '245'
  'gray-light':     '250'
  'gray-lighter':   '255'

  'blue-darker':    '21'
  'blue-dark':      '27'
  'blue':           '33'
  'blue-light':     '39'
  'blue-lighter':   '45'

  'cian-darker':    '51'
  'cian-dark':      '87'
  'cian':           '123'
  'cian-light':     '159'
  'cian-lighter':   '195'

  'green-darker':   '22'
  'green-dark':     '28'
  'green':          '34'
  'green-light':    '40'
  'green-lighter':  '46'

  'red-darker':     '52'
  'red-dark':       '88'
  'red':            '124'
  'red-light':      '160'
  'red-lighter':    '196'

  'yellow-darker':  '202'
  'yellow-dark':    '208'
  'yellow':         '214'
  'yellow-light':   '220'
  'yellow-lighter': '226'

  # black:   '30'
  # red:     '31'
  # green:   '32'
  # yellow:  '33'
  # blue:    '34'
  # magenta: '35'
  # cyan:    '36'
  # white:   '37'
