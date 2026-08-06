############# HOW TO USE ###############
# require('./scErrorsHandle')
# isArray([])
############# HOW TO USE ###############

global.isFile     = (val) -> !!val && typeof val == 'object' && val.constructor == File
global.isObject   = (val) -> !!val && typeof val == 'object' && val.constructor == Object
global.isArray    = (val) -> !!val && typeof val == 'object' && val.constructor == Array
global.isNumber   = (val) -> typeof val == 'number' && isFinite(val)
global.isString   = (val) -> typeof val == 'string' || val instanceof String
global.isFunction = (val) -> typeof val == 'function'
global.isNull     = (val) -> [undefined, null].includes(val)
global.isBlank    = (val) ->
    arrayEmpty  = isArray(val) && val.empty()
    objectEmpty = isObject(val) && Object.empty(val)
    isNull(val) || [''].includes(val) || arrayEmpty || objectEmpty
global.isPresent  = (val) -> !isBlank(val)


# matematica
global.multiplicar = (numbers...) ->
  for number in numbers.compact()
    number = dinheiro_bd(number)
    calculated =  if calculated?
                    calculated * number
                  else
                    number
  parseFloat (calculated).toFixed(2), 10 if calculated?
global.dividir = (numbers...) ->
  for number in numbers.compact()
    number = dinheiro_bd(number)
    calculated =  if calculated?
                    calculated / number
                  else
                    number
  parseFloat (calculated).toFixed(2), 10 if calculated?
global.somar = (numbers...) ->
 for number in numbers.compact()
   number = dinheiro_bd(number)
   calculated =  if calculated?
                   calculated + number
                 else
                   number
 parseFloat (calculated).toFixed(2), 10 if calculated?
global.subtrair = (numbers...) ->
  for number in numbers.compact()
    number = dinheiro_bd(number)
    calculated =  if calculated?
                    calculated - number
                  else
                    number
  parseFloat (calculated).toFixed(2), 10 if calculated?



global.convertNumToBase = (num, baseA, baseB) ->
  if !(baseA < 2 or baseB < 2 or isNaN(baseA) or isNaN(baseB) or baseA > 36 or baseB > 36)
    return parseInt(num, baseA).toString(baseB)
global.asciiToHexa = (string)->
  return null unless string
  indx = 0
  resp = []
  strg = "#{string}"

  while indx < strg.length
    resp.push strg.charCodeAt(indx).toString(16)
    indx++
  resp
global.hexaToAscii = (string)->
  return null unless string
  indx = 0
  resp = ''

  if typeof string == 'object' && string.constructor == Array
    # array de string em hexa. ex.: ['44', '69', '65', '67', '6f']
    strg = string.join('')
  else
    strg = "#{string}"

  while indx < strg.length
    resp += String.fromCharCode(parseInt(strg.substr(indx, 2), 16))
    indx += 2
  resp
