# Compare buffers
buff_eq = (a, b) -> a.toString('base64') is b.toString('base64')

# Execute `fn` in the context of `ctx`
using = (ctx, fn) -> fn.call ctx

# Copy properties
extend = (dest, src) ->
  dest[k] = v for k, v of src
  dest

# Set default properties
defaults = (dest, src) ->
  dest[k] ?= v for k, v of src
  dest

# Return only the given `keys` from `obj`
pick = (obj, keys...) ->
  keys = keys[0] if keys.length is 1 and Array.isArray keys[0]
  ret = {}
  ret[k] = obj[k] for k in keys when obj[k]?
  ret

# Is Object?
isObject = (o) -> o is Object o

# Turn all (nested) buffers to base64 strings
stringify_buffs = (x) ->
  if Buffer.isBuffer x then x.toString('base64')
  else if Array.isArray x then x.map(stringify_buffs)
  else if isObject x
    ret = {}
    ret[k] = stringify_buffs v for own k, v of x
    ret
  else x

# Throttle function execution
throttle = (ms, fn) ->
  timer = last = 0
  (args...) ->
    if (passed=Date.now()-last) < ms
      timer ||= setTimeout ->
        timer = 0
        last = Date.now()
        fn.call this, args
      , ms-passed
    else if not timer
      last = Date.now()
      fn.call this, args

module.exports = { buff_eq, using, extend, defaults, pick, stringify_buffs, throttle }
