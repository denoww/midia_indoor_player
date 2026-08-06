# -------------------------
# array.js


Array::toArraySqlQuery = ->
  # [1, '2'].toArraySqlQuery()
  # retorna "(1, '2')"
  array = @.toOnlyArraySqlQuery()
  if array.length
    "(#{array.join(", ")})"
  else
    "('0')"

Array::toOnlyArraySqlQuery = ->
  # [1, '2'].toOnlyArraySqlQuery()
  # retorna ['1', "'2'"]
  array = []
  @.map (a) ->
    if isNumber(a)
      array.push "#{a}"
    else
      array.push "'#{a}'" #if a.is_a? String
  array.unique()

Array::max = ->  Math.max.apply null, @
Array::min = ->  Math.min.apply null, @
Array::first = -> @[0]
Array::last = -> @slice(-1)[0]
Array::clone = -> @slice(0)

Array::equals = (array) ->
  # [2, 1].equals([1, 2]) // true
  list = (array || []).slice(0).sort() # para não modificar o array
  @length == list.length and @sort().every(
    (el, i) ->
      item = list[i]
      if isObject(el)
        Object.equals(el, item)
      else if isArray(el)
        el.equals(item)
      else
        el == item
  )

Array::groupBy = (key) ->
  @.reduce (obj, item) ->
    (obj[item[key]] = obj[item[key]] || []).push item
    obj
  , {}

Array::intersection = (array) ->
  resp = @.filter (n) ->
    array.indexOf(n) != -1
  resp.unique()


Array::subtract = (array)->
  @.filter (i)-> array.indexOf(i) < 0

Array::toggle = (value) ->
  array = @
  index = array.indexOf(value)
  if index == -1
    array.push value
  else
    array.splice index, 1
  return

Array::inArray = (e) ->
  e in @

Array::mapObj = (field) ->
  @.map (e)-> e[field]

Array::contains = (e) ->
  e in @

Array::include = (e) ->
  @.inArray(e)

Array::includes = Array::include
Array::isIncluded = Array::include

Array::one = ()->
  @.length == 1

Array::any = ()->
  @.length > 0

Array::many = ()->
  @.length > 1

Array::empty = ()->
  !@.any()

Array::index = (value, field)->
  @transform(field).indexOf(value)

Array::transform = (field, clone = false)->
  if field?
    @map((e)-> e[field])
  else if clone
    @clone()
  else
    @

Array::sortByField = (field, type='asc') ->
  @slice(0).sort (a, b) ->
    switch type
      when 'asc'
        if a[field] > b[field] then 1 else if a[field] < b[field] then -1 else 0
      when 'desc'
        if a[field] > b[field] then -1 else if a[field] < b[field] then 1 else 0


Array::indexOfById = (id, opt={})->
  key = opt.key || 'id'
  for el, idx in @
    return idx if el[key] == id
  return -1

Array::getById = (arg)->
  if arg instanceof Array
    arg.map (_id)=> @getById(_id)
  else
    _id = arg?.id || arg
    @[@indexOfById(_id)]

Array::findById = Array::getById

Array::move = (from, to)->
  @splice(to, 0, @splice(from, 1)[0])

Array::remove = (el)->
  idx = @indexOf(el)
  @splice idx, 1 if idx > -1

Array::removeByIndex = (idx)->
  @splice idx, 1 if idx > -1

Array::removeAll = (el)->
  @remove el while el in @

Array::removeById = (rec)->
  id = rec?.id || rec
  @removeByField('id', id)

Array::getByField = (field, value)->
  idx = @getIndexByField(field, value)
  @[idx]
Array::findByKey   = Array::getByField
Array::findByField = Array::getByField

Array::getIndexByField = (field, value)->
  field = 'id' if field == undefined
  idx = null
  for el,i in @
   idx = i if el[field] == value
  return idx

Array::removeByField = (field, value)->
  field = 'id' if field == undefined

  idx = []
  for el,i in @
   idx.push i if el[field] == value

  while idx.length > 0
    (@splice idx.pop(), 1)[0]

Array::extractFrom = (deepObject)->
  _carry = deepObject

  for _attr in @
    _carry = _carry?[_attr]

  _carry

Array::addOrExtend = (obj, opts={})->
  # idx = if obj.id? then @indexOfById(obj.id) else @indexOf(obj)
  key = opts.key || 'id'
  idx = if obj[key]? then @indexOfById(obj[key], key: key) else @indexOf(obj)
  if idx is -1
    return @unshift obj if opts.unshift
    @push obj
  else
    Object.assign @[idx], obj

Array::pushOrExtend = (obj)->
  @addOrExtend(obj)

Array::unshiftOrExtend = (obj)->
  @addOrExtend(obj, {unshift: true})

Array::somar = (field)->
  _arr = if field then @.map((e)-> e[field]) else @

  _arr.reduce (mem,el)->
    +mem + +el

Array::chunk = (size=2)->
  @slice(i, i+size) for e, i in @ by size

Array::compact = ->
  @filter (e)-> !!e || e == 0

Array::unique = (field)->
  added = []

  @filter (item)->
    v = if field? then item[field] else item
    added.push(v) unless v in added

Array::diff = (list)->
  # [1, 2, 3].diff([1, 2])
    # retorna [3]
  result = @.map (item)-> item unless list.includes(item)
  result.removeAll undefined
  result

Array::diffByFn = (list, fn)->
  result = @.map (item)->
    item if fn(item, list)
  result.removeAll undefined
  result

Array::diffByField = (list, field)->
  # [{id: 1}, {id: 2}].diffByField([{id: 1}], 'id')
    # retorna [{id: 2}]
  @.diffByFn list, (el)->
    list.indexOfById(el[field], key: field) < 0

Array::diffById = (list)->
  # [{id: 1}, {id: 2}].diffById([{id: 1}])
    # retorna [{id: 2}]
  @.diffByField(list, 'id')

Array::clear = ->
  @length = 0
  @

Array::sum = ->
  return 0 unless @length
  @reduce (mem,el)-> +mem + +el

Array::find = (fn)->
  @.select(fn)[0]

Array::select = (fn)->
  (el for el in @ when !!fn(el))

Array::selectByField = (key, val)->
  # return @select (el) ->  if isArray(val)
  valIsArray = isArray(val)
  @select (el) ->
    valElIsArray = isArray(el[key])
    return val.intersection(el[key]).any() if valIsArray && valElIsArray
    return val.includes(el[key]) if valIsArray
    return el[key].includes(val) if valElIsArray
    el[key] == val

Array::reject = (fn)->
  (el for el in @ when !fn(el))

Array::rejectByField = (key, val)->
  valIsArray = isArray(val)
  @select (el) ->
    valElIsArray = isArray(el[key])
    return !val.intersection(el[key]).any() if valIsArray && valElIsArray
    return !val.includes(el[key]) if valIsArray
    return !el[key].includes(val) if valElIsArray
    el[key] != val

Array::flattenCompact = ->
  @.flatten().compact()

Array::flatten = ->
  @.reduce ((flat, toFlatten) ->
    flat.concat if Array.isArray(toFlatten) then toFlatten.flatten() else toFlatten
  ), []

# Porque a de cima tá mais batutinha 2.
# Array::flatten = ()->
#   self = @.clone()
#   while self.length != b?.length
#     b    = self
#     self = [].concat self...
#   self

# Porque a de cima tá mais batutinha.
# Array::flatten = e = ->
#   t = []
#   n = 0
#   r = @length

#   while n < r
#     i = Object::toString.call(this[n]).split(" ").pop().split("]").shift().toLowerCase()
#     t = t.concat((if /^(array|collection|arguments|object)$/.test(i) then e.call(this[n]) else this[n]))  if i
#     n++
#   t

Array::presence = ->
  if @.empty() then null else @

Array::toSentence = ->
  return '' if @empty()
  return @first() if @length is 1
  [@[0...-1].join(', '), @last()].join ' e '

# Aguardando confirmação de não bugs
# Array::toSentence = ->
#   e = this
#   if @length is 0
#     ""
#   else if @length is 1
#     this[0]
#   else
#     t = @length - 1
#     n = this[t]
#     e.splice t, 1
#     primeiros = e.join(", ")
#     [primeiros, n].join " e "

Array::occurrencesOf = (e) ->
  (el for el in @ when el == e).length

# Aguardando confirmação de não bugs
# Array::occurrencesOf = (e) ->
#   t = {}
#   n = 0

#   while n < @length
#     r = this[n]
#     t[r] = (if t[r] then t[r] + 1 else 1)
#     n++
#   result = t[e]
#   if result is `undefined`
#     0
#   else
#     result

# Como usar o foreach
# [12, 5, 8, 130, 44].forEach(function(element, index, array){
# });
# ou
# [12, 5, 8, 130, 44].forEach(function(element){
# ou
# [12, 5, 8, 130, 44].forEach (element) ->
unless Array::forEach
  Array::forEach = (fn) ->
    throw new TypeError unless typeof e is "function"
    fn(el, idx, @) for el, idx in @

# unless Array::forEach
#   Array::forEach = (e) ->
#     # Como usar o foreach
#     # [12, 5, 8, 130, 44].forEach(function(element, index, array){
#     # });
#     # ou
#     # [12, 5, 8, 130, 44].forEach(function(element){
#     # ou
#     # [12, 5, 8, 130, 44].forEach (element) ->


#     t = @length
#     throw new TypeError unless typeof e is "function"
#     n = arguments[1]
#     r = 0

#     while r < t
#       e.call n, this[r], r, this if r of this
#       r++

# ----------- fim array.js--------------
