local Renderer = require('kernel')
local resolve
do
  local _table_0 = require('path')
  resolve = _table_0.resolve
end
local _defs = { }
Renderer.root = ''
extend(Renderer.helpers, {
  X = function(x, name, filename, offset)
    if type(x) == 'function' then
      return '{{' .. name .. ':FUNCTION}}'
    end
    if type(x) == 'table' then
      return '{{' .. name .. ':TABLE}}'
    end
    if x == nil then
      return '{{' .. name .. ':NIL}}'
    end
    return x
  end,
  PARTIAL = function(name, locals, callback)
    if not callback then
      callback = locals
      locals = { }
    end
    return Renderer.compile(resolve(Renderer.root, name), function(err, template)
      if err then
        return callback(nil, '{{' .. (err.message or err) .. '}}')
      else
        return template(locals, callback)
      end
    end)
  end,
  IF = function(condition, block, callback)
    if condition then
      return block({ }, callback)
    else
      return callback(nil, '')
    end
  end,
  LOOP = function(array, block, callback)
    local left = 1
    local parts = { }
    local done = false
    for i, value in ipairs(array) do
      left = left + 1
      block(value, function(err, result)
        if done then
          return 
        end
        if err then
          done = true
          return callback(err)
        end
        parts[i] = result
        left = left - 1
        if left == 0 then
          done = true
          return callback(nil, join(parts))
        end
      end)
    end
    left = left - 1
    if left == 0 and not done then
      done = true
      return callback(nil, join(parts))
    end
  end,
  ESC = function(value, callback)
    if callback then
      return callback(nil, value:escape())
    else
      return value:escape()
    end
  end,
  DEF = function(name, block, callback)
    _defs[name] = block
    return callback(nil, '')
  end,
  USE = function(name, locals, callback)
    if not callback then
      callback = locals
      locals = { }
    end
    return _defs[name](locals, callback)
  end
})
return {
  render = Renderer.helpers.PARTIAL,
  set_root = function(path)
    Renderer.root = path
  end
}
