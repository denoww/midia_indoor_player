unless Object.keys
  # console.warn ("Esse navegador não implementou a função Object.keys(myObj). Podem ocasionar Bugs. Discuta com a equipe qual ação deve ser tomada.")
  Object.keys = (obj)->
    prop for prop of obj when obj.hasOwnProperty prop

unless Object.values
  # Como usar:
  # Object.values({a: 1, b: "2"}) # retorna [1, "2"]
  Object.values = (obj) ->
    Object.keys(obj).map (key) ->
      obj[key]
# else
#   console.warn ("Esse navegador implementou a função Object.values(myObj), e está sobrescrevendo a que foi implementada manualmente nesse sistema. Podem ocasionar Bugs. Discuta com a equipe qual ação deve ser tomada.")

unless Object.slice
  # Como usar
  # Ex: 1
  # Object.slice({a:1, b: 2, c: 3, d: 4}, 'a', 'd') # return {a:1, d:4}
  # Ex 2:
  # keys = ['a', 'd']
  # Object.slice({a:1, b: 2, c: 3, d: 4}, keys...) # return {a:1, d:4}
  Object.slice = (obj, props...) ->
    ret = {}
    i = 0
    for prop in props
      prop = props[i]
      if obj.hasOwnProperty(prop)
        ret[prop] = obj[prop]
      i += 1
    ret

unless Object.reject
  # Como usar
  # Ex: 1
  # Object.reject({a:1, b: 2, c: 3, d: 4}, 'a', 'd') # return {b:2, c:3}
  # Ex 2:
  # keys = ['a', 'd']
  # Object.reject({a:1, b: 2, c: 3, d: 4}, keys...) # return {b:2, c:3}
  Object.reject = (obj, keys...) ->
    res = {}
    res[k] = v for k, v of obj when !(k in keys)
    res

unless Object.blank
  # console.warn ("Esse navegador não implementou a função Object.blank(myObj). Podem ocasionar Bugs. Discuta com a equipe qual ação deve ser tomada.")
  Object.blank = (val)->
    return false if ['number', 'boolean', 'function'].include typeof(val)
    return true unless val?
    return val.empty() if ['string'].include typeof(val)
    Object.empty(val)

unless Object.empty
  # console.warn ("Esse navegador não implementou a função Object.empty(myObj). Podem ocasionar Bugs. Discuta com a equipe qual ação deve ser tomada.")
  Object.empty = (obj)->
    Object.keys(obj).empty()

unless Object.any
  # console.warn ("Esse navegador não implementou a função Object.any(myObj). Podem ocasionar Bugs. Discuta com a equipe qual ação deve ser tomada.")
  Object.any = (obj)->
    Object.keys(obj).any()

unless Object.many
  # console.warn ("Esse navegador não implementou a função Object.many(myObj). Podem ocasionar Bugs. Discuta com a equipe qual ação deve ser tomada.")
  Object.many = (obj)->
    Object.keys(obj).many()

unless Object.delete
  Object.delete = (obj, key)->
    delete obj[key]
    obj

unless Object.equals
  # console.warn ("Esse navegador não implementou a função Object.equals(obj1, obj2). Podem ocasionar Bugs. Discuta com a equipe qual ação deve ser tomada.")
  Object.equals = (obj1, obj2)->
    return true if obj1 == obj2
    # if both obj1 and obj2 are null or undefined and exactly the same

    return false if ( ! ( obj1 instanceof Object ) || ! ( obj2 instanceof Object ) )
    # if they are not strictly equal, they both need to be Objects

    return false if obj1.constructor != obj2.constructor
    # they must have the exact same prototype chain, the closest we can do is
    # test there constructor.

    for obj of obj1
      continue if ( ! obj1.hasOwnProperty( obj ) )
      # other properties were tested using obj1.constructor == obj2.constructor

      return false if ( ! obj2.hasOwnProperty( obj ) )
      # allows to compare obj1[ obj ] and obj2[ obj ] when set to undefined

      continue if obj1[ obj ] == obj2[ obj ]
      # if they have the same strict value or identity then they are equal

      return false if typeof( obj1[ obj ] ) != "object"
      # Numbers, Strings, Functions, Booleans must be strictly equal

      return false if ( ! Object.equals( obj1[ obj ], obj2[ obj ] ) )
      # Objects and Arrays must be tested recursively

    for obj of obj2
      return false if ( obj2.hasOwnProperty( obj ) && ! obj1.hasOwnProperty( obj ) )
      # allows obj1[ obj ] to be set to undefined

    true
