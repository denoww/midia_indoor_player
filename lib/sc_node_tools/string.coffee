# -------------------------
# string.js
String::removeLeadingZeros = ->
  @replace(/^0+/, '')

String::toI = ->
  parseInt @replace(",", "."), 10

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

String::removerAcentos = -> _deaccent(@)

String::camelCaseToHyphen = ->
  this.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase();

String::toPascalCase = ->
  arr = this.split(/\s|_/)
  i = 0
  l = arr.length

  while i < l
    arr[i] = arr[i].substr(0, 1).toUpperCase() + ((if arr[i].length > 1 then arr[i].substr(1).toLowerCase() else ""))
    i++
  arr.join ""

String::removeSpecialCharacters = ->
  @.replace(/[^\w\s]/gi, '')

String::extractFrom = (deepObject)->
  @split('.').extractFrom(deepObject)

String::onlyNumbers = ->
  @replace /[^0-9]/g, ""

# check if the contentType is image "image/png".isImage() => true; "application/pdf".isImage() => false
String::contentTypeIsImage = ->
  !!@match(/image\//)

String::nl2br = ->
  @.replace(/\n/g,"<br>");

_deaccent = (accentedString) ->
  return accentedString unless accentedString
  result = accentedString
  for key, value of charToAccentedCharClassMap
    result = result?.replace(new RegExp(value, "g"), key)
  result

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
