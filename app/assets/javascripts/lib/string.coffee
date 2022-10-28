String::removerAcentos = ->
  result = @
  for k, v of charToAccentedCharClassMap
    result = result.replace(new RegExp(v, "g"), k)
  result

String::ljust = (width, padding) ->
  padding = padding or ' '
  padding = padding.substr(0, 1)
  if @length < width
    resp = @ + padding.repeat(width - (@length))
  else
    resp = @
  resp.toString()

String::rjust = (width, padding) ->
  padding = padding or ' '
  padding = padding.substr(0, 1)
  if @length < width
    resp = padding.repeat(width - (@length)) + @
  else
    resp = @
  resp.toString()

String::toI = ->
  parseInt @replace(",", "."), 10

String::toPascalCase = ->
  arr = this.split(/\s|_/)
  i = 0
  l = arr.length

  while i < l
    arr[i] = arr[i].substr(0, 1).toUpperCase() + (if arr[i].length > 1 then arr[i].substr(1).toLowerCase() else "")
    i++
  arr.join ''

String::removeSpecialCharacters = ->
  @.replace(/[^\w\s]/gi, '')

charToAccentedCharClassMap =
  A: "[AÁÀÃÂÄǍȀĀȦ]"
  a: "[aáàãâäǎȁāȧ]"

  E: "[EÉÈẼÊËĚȄĒĖ]"
  e: "[eéèẽêëěȅēė]"

  I: "[IÍÌĨÎÏǏȈĪİ]"
  i: "[iíìĩîïǐȉīi̇]"

  O: "[OÓÒÕÔÖǑȌŌȮ]"
  o: "[oóòõôöǒȍōȯ]"

  U: "[UÚÙŨÛÜǓȔŪ]"
  u: "[uúùũûüǔȕū]"

  C: "[CÇ]"
  c: "[cç]"
