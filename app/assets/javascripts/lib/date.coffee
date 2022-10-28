Date::format = (format='Y-MM-DD') ->
  moment(@).format(format)

Date::toDate = -> @

Date::setEndOfDay = ->
  @setHours(23)
  @setMinutes(59)
  @setSeconds(59)
  @

Date::beginningOfMonth = ->
  @setDate(1)
  @

Date::addMilliseconds = (value) ->
  @setMilliseconds @getMilliseconds() + value
  this

Date::addSeconds = (value) ->
  @addMilliseconds value * 1000

Date::addMinutes = (value) ->
  @addMilliseconds value * 60000

Date::addHours = (value) ->
  @addMilliseconds value * 3600000

Date::addDays = (value) ->
  @addMilliseconds value * 86400000

Date::addWeeks = (value) ->
  @addMilliseconds value * 604800000

Date::addMonths = (value) ->
  n = @getDate()
  @setDate 1
  @setMonth @getMonth() + value
  @setDate Math.min(n, @getDaysInMonth())
  this

Date::addYears = (value) ->
  @addMonths value * 12

Date::getDaysInMonth = ->
  Date.getDaysInMonth @getFullYear(), @getMonth()

Date.getDaysInMonth = (year, month) ->
  [31, (if anoBissexto(year) then 29 else 28), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month]
