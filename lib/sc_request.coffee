# Substituto do `request` (depreciado desde 2020; puxava a árvore vulnerável
# tough-cookie/form-data/qs via url-exists) mantendo a MESMA assinatura de
# callback usada neste repo, por cima de axios — padrão PSC-27 (contrato
# preservado, igual ao RequestService do sc_linker).
#
# Cobre somente as formas usadas nos call-sites daqui:
#   request(url, cb)                          -> GET, body string
#   request({url, timeout}, cb)               -> GET, body string
#   request.get({url, qs, timeout}, cb)       -> GET com querystring
#   request.get(url, {encoding: null}, cb)    -> GET binário, body Buffer
#   request.post({url, body, headers, timeout}, cb) -> POST body cru (string)
#   request.head(url, cb)                     -> HEAD (substitui url-exists)
#
# cb = (error, response, body) com response.statusCode. Igual ao `request`:
# status HTTP != 2xx NÃO vira error (validateStatus true) — error só de rede.
axios = require 'axios'

normalize = (opts) ->
  if typeof opts == 'string' then { url: opts } else (opts || {})

exec = (method, opts, cb) ->
  opts = normalize(opts)
  config =
    method: method
    url: opts.url
    params: opts.qs
    headers: opts.headers
    timeout: opts.timeout || 0     # request não tinha timeout default
    validateStatus: -> true
    maxRedirects: 10               # request seguia até 10 redirects em GET

  if opts.encoding == null
    config.responseType = 'arraybuffer'
  else
    # body como string crua — call-sites fazem JSON.parse como antes
    config.responseType = 'text'
    config.transformResponse = [(d) -> d]

  if opts.body?
    config.data = opts.body
    # não re-serializar: `request` mandava body cru (string/Buffer)
    config.transformRequest = [(d) -> d]

  axios(config)
    .then (resp) ->
      body = resp.data
      body = Buffer.from(body) if config.responseType == 'arraybuffer' && body?
      cb(null, { statusCode: resp.status, headers: resp.headers }, body)
    .catch (error) ->
      cb(error)
  return

request = (opts, cb) -> exec('get', opts, cb)

request.get = (opts, extraOrCb, maybeCb) ->
  if typeof extraOrCb == 'function'
    exec('get', opts, extraOrCb)
  else
    exec('get', Object.assign({}, normalize(opts), extraOrCb || {}), maybeCb)

request.post = (opts, cb) -> exec('post', opts, cb)
request.head = (opts, cb) -> exec('head', opts, cb)

module.exports = request
