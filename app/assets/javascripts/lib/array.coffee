# -------------------------
# array.js
Array::max = ->  Math.max.apply null, @
Array::min = ->  Math.min.apply null, @
Array::first = -> @[0]
Array::last = -> @slice(-1)[0]
Array::clone = -> @slice(0)

Array::intersection = (array) ->
  resp = @.filter (n) ->
    array.indexOf(n) != -1
  resp.unique()

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

Array::contains = (e) ->
  e in @

Array::include = (e) ->
  @.inArray(e)

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

Array::indexOfById = (id)->
  for el, idx in @
    return idx if el.id == id
  return -1

Array::getById = (id)->
  if id instanceof Array
    id.map (_id)=> @getById(_id)
  else
    @[@indexOfById(id)]

Array::move = (from, to)->
  @splice(to, 0, @splice(from, 1)[0])

Array::remove = (el)->
  idx = @indexOf(el)
  @splice idx, 1 if idx > -1

Array::removeAll = (el)->
  @remove el while el in @

Array::removeById = (id)->
  @removeByField('id', id)

Array::getByField = (field, value)->
  idx = @getIndexByField(field, value)
  @[idx]

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

Array::addOrExtend = (obj)->
  idx = if obj.id? then @indexOfById(obj.id) else @indexOf(obj)
  if idx is -1
    @push obj
  else
    Object.assign @[idx], obj
    # @splice(idx, 1, obj)
    # Vue.set(@, idx, obj)

Array::somar = (field)->
  _arr = if field then @.map((e)-> e[field]) else @

  _arr.reduce (mem,el)->
    +mem + +el

Array::chunk = (size=2)->
  @slice(i, i+size) for e, i in @ by size

Array::diffById = (arr)->
  result = @.map (item)->
    item if arr.indexOfById(item.id) < 0
  result.removeAll undefined
  result

Array::compact = ->
  @filter (e)-> !!e || e == 0

Array::unique = (field)->
  added = []

  @filter (item)->
    v = if field? then item[field] else item
    added.push(v) unless v in added

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

Array::reject = (fn)->
  (el for el in @ when !fn(el))

Array::flatten = ()->
  self = @.clone()
  while self.length != b?.length
    b    = self
    self = [].concat self...
  self

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

# unless @Array::forEach
#   @Array::forEach = (e) ->
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
