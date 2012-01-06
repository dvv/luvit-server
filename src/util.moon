-----------------------------------------------------------
--
-- Debug
--
-----------------------------------------------------------

if process.env.DEBUG == '1'
  _G.d = (...) -> debug('DEBUG', ...)
else
  _G.d = () ->

-----------------------------------------------------------
--
-- string helpers
--
-----------------------------------------------------------

String = require 'string'

import sub, find, match, gsub, gmatch, byte, char, format from String

-- aliases
String.replace = gsub

-- strip whitespaces
trim = (str, what = '%s+') ->
  str = gsub str, '^' .. what, ''
  str = gsub str, what .. '$', ''
  str
String.trim = trim

-- interpolation
String.interpolate = (data) =>
  return self if not data
  if type(data) == 'table'
    return format(self, unpack(b)) if data[1]
    return gsub self, '(#%b{})', (w) ->
      var = trim sub w, 3, -2
      n, def = match var, '([^|]-)|(.*)'
      var = n if n
      -- TODO: dot notation
      s = type(data[var]) == 'function' and data[var]() or data[var] or def or w
      --s = String.escape s
      s
  else
    format self, data

--
-- string to hexadecimal
--
String.tohex = (str) ->
  (gsub str, '(.)', (c) -> format('%02x', byte(c)))

--
-- hexadecimal to string
--
String.fromhex = (str) ->
  (gsub str, '(%x%x)', (h) ->
    n = tonumber h, 16
    if n != 0 then format('%c', n) else '\000')

--
-- base64 encoding
-- Thanks: http://lua-users.org/wiki/BaseSixtyFour
--

-- character table string
base64_table = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

String.base64 = (data) ->
  ((gsub(data, '.', (x) ->
    r, b = '', byte(x)
    for i = 8, 1, -1
      r = r .. (b%2^i - b%2^(i - 1) > 0 and '1' or '0')
    r) .. '0000')\gsub('%d%d%d?%d?%d?%d?', (x) ->
    return '' if #x < 6
    c = 0
    for i = 1, 6
      c = c + (sub(x, i, i) == '1' and 2^(6 - i) or 0)
    sub(base64_table, c + 1, c + 1)) .. ({'', '==', '='})[#data % 3 + 1])

String.escape = (str) ->
  -- TODO: escape HTML entities
  --return self:gsub('&%w+;', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'):gsub('"', '&quot;')
  -- TODO: escape &
  gsub(str, '<', '&lt;')\gsub('>', '&gt;')\gsub('"', '&quot;')

String.unescape = (str) ->
  -- TODO: unescape HTML entities
  str

String.split = (str, sep = '%s+', nmax) ->
  r = {}
  return r if #str <= 0
  plain = false
  nmax = nmax or -1
  nf = 1
  ns = 1
  nfr, nl = find str, sep, ns, plain
  while nfr and nmax != 0
    r[nf] = sub str, ns, nfr - 1
    nf = nf + 1
    ns = nl + 1
    nmax = nmax - 1
    nfr, nl = find str, sep, ns, plain
  r[nf] = sub str, ns
  r

--
-- augment string prototype
--

-- nil .. 'foo' == 'nilfoo'
--getmetatable('').__concat = (a, b) -> tostring(a) .. tostring(b)
-- 'foo #{bar}' % {bar = 'baz'} == 'foo baz'
--getmetatable('').__mod = String.interpolate
-- 'foo bar  baz' / ' ' == {'foo', 'bar', ' baz'}
--getmetatable('').__div = String.split
-- '!!   foo bar  baz   !!!' - '!+' == '   foo bar  baz   '
getmetatable('').__sub = String.trim

-----------------------------------------------------------
--
-- collection of various helpers. when critical mass will accumulated
-- they should go to some lib file
--
-----------------------------------------------------------

T = require 'table'

-- shallow copy
_G.copy = (obj) ->
  return obj if type(obj) != 'table'
  x = {}
  setmetatable x, __index: obj
  x

-- deep copy of a table
-- FIXME: that's a blind copy-paste, needs testing
_G.clone = (obj) ->
  copied = {}
  new = {}
  copied[obj] = new
  for k, v in pairs(obj)
    if type(v) != 'table'
      new[k] = v
    elseif copied[v]
      new[k] = copied[v]
    else
      copied[v] = clone v, copied
      new[k] = setmetatable copied[v], getmetatable v
  setmetatable new, getmetatable u
  new

_G.extend = (obj, with_obj) ->
  for k, v in pairs(with_obj)
    obj[k] = v
  obj

_G.extend_unless = (obj, with_obj) ->
  for k, v in pairs(with_obj)
    obj[k] = v if obj[k] == nil
  obj

_G.push = (t, x) ->
  T.insert t, x

_G.unshift = (t, x) ->
  T.insert t, 1, x

_G.pop = (t) ->
  T.remove t

_G.shift = (t) ->
  T.remove t, 1

_G.slice = (t, start = 0, stop = #t) ->
  start = start + #t if start < 0
  stop = stop + #t if stop < 0
  if type(t) == 'string'
    return sub(t, start + 1, stop)
  -- table
  r = {}
  n = 0
  i = 0
  for i = start + 1, stop
    n = n + 1
    r[n] = t[i]
  r

_G.sort = (t, f) ->
  T.sort t, f

_G.join = (t, s) ->
  T.concat t, s

_G.has = (t, s) ->
  rawget(t, s)

_G.keys = (t) ->
  r = {}
  n = 0
  for k, v in pairs(t)
    n = n + 1
    r[n] = k
  r

_G.values = (t) ->
  r = {}
  n = 0
  for k, v in pairs(t)
    n = n + 1
    r[n] = v
  r

_G.map = (t, f) ->
  r = {}
  for k, v in pairs(t)
    r[k] = f v, k, t
  r

_G.filter = (t, f) ->
  r = {}
  for k, v in pairs(t)
    r[k] = v if f v, k, t
  r

_G.each = (t, f) ->
  for k, v in pairs(t)
    f v, k, t

_G.curry = (f, g) ->
  (...) -> f g unpack arg

_G.bind111 = (f, ...) ->
  (...) -> f g unpack arg

_G.indexOf = (t, x) ->
  if type(t) == 'string'
    return find t, x, true
  for k, v in pairs(t)
    return k if v == x
  nil

-----------------------------------------------------------
--
-- rich interpolation
--
-----------------------------------------------------------
Kernel = require 'kernel'

_defs = {}

extend Kernel.helpers, {

  X: (x, name, filename, offset) ->
    if type(x) == 'function'
      return '{{FUNCTION}}'
    if type(x) == 'table'
      return '{{TABLE}}'
    if x == nil
      return '{{' .. name .. ':NIL}}'
    return x

  PARTIAL: (name, locals, callback) ->
    if not callback
      callback = locals
      locals = {}
    Kernel.compile name, (err, template) ->
      if err
        callback err
      else
        template locals, callback

  IF: (condition, block, callback) ->
    if condition
      block {}, callback
    else
      callback nil, ''

  LOOP: (array, block, callback) ->
    left = 1
    parts = {}
    done = false
    for i, value in ipairs array
      left = left + 1
      --value.index = i
      block value, (err, result) ->
        return if done
        if err
          done = true
          return callback err
        parts[i] = result
        left = left - 1
        if left == 0
          done = true
          callback nil, join parts
    left = left - 1
    if left == 0 and not done
      done = true
      callback nil, join parts

  ESC: (value, callback) ->
    if callback
      callback nil, value\escape()
    else
      return value\escape()

  DEF: (name, block, callback) ->
    _defs[name] = block
    callback nil, ''

  USE: (name, locals, callback) ->
    if not callback
      callback = locals
      locals = {}
    _defs[name] locals, callback

}

_G.render = Kernel.helpers.PARTIAL
