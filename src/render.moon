--
-- rich interpolation
--

Renderer = require 'kernel'

import resolve from require 'path'

-- TODO: get rid of globality
_defs = {}

-- root of partials
Renderer.root = ''

-- setup renderer helpers
extend Renderer.helpers, {

  X: (x, name, filename, offset) ->
    if type(x) == 'function'
      return '{{' .. name .. ':FUNCTION}}'
    if type(x) == 'table'
      return '{{' .. name .. ':TABLE}}'
    if x == nil
      return '{{' .. name .. ':NIL}}'
    return x

  PARTIAL: (name, locals, callback) ->
    if not callback
      callback = locals
      locals = {}
    Renderer.compile resolve(Renderer.root, name), (err, template) ->
      if err
        callback nil, '{{' .. (err.message or err) .. '}}'
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

-- module
return {
  render: Renderer.helpers.PARTIAL
  set_root: (path) -> Renderer.root = path
}
