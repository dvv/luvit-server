local Response = require('response')
local compile
do
  local _table_0 = require('kernel')
  compile = _table_0.compile
end
local noop
noop = function() end
Response.prototype.auto_server = 'U-Gotta-Luvit'
Response.prototype.send = function(self, code, data, headers, close)
  if close == nil then
    close = true
  end
  self:write_head(code, headers or { })
  if data then
    self:write(data)
  end
  if close then
    return self:finish()
  end
end
Response.prototype.fail = function(self, reason)
  return self:send(500, reason, {
    ['Content-Type'] = 'text/plain; charset=UTF-8',
    ['Content-Length'] = #reason
  })
end
Response.prototype.serve_not_found = function(self)
  return self:send(404)
end
Response.prototype.serve_not_modified = function(self, headers)
  return self:send(304, nil, headers)
end
Response.prototype.serve_invalid_range = function(self, size)
  return self:send(416, nil, {
    ['Content-Range'] = 'bytes=*/' .. size
  })
end
local helpers = false
local render
render = function(filename, data, options, callback)
  if data == nil then
    data = { }
  end
  if options == nil then
    options = { }
  end
  compile(filename, function(err, template)
    if err then
      callback(err)
    else
      setmetatable(data, {
        __index = helpers
      })
      template(data, callback)
    end
    return 
  end)
  return 
end
helpers = {
  IF = function(condition, block, callback)
    if condition then
      block(getfenv(2), callback)
    else
      callback(nil, '')
    end
    return 
  end,
  EACH = function(array, block, callback)
    local parts = { }
    local size = #array
    local done = false
    local check
    check = function(err)
      if done then
        return 
      end
      if #parts == size then
        done = true
        return callback(err, join(parts, ''))
      end
    end
    for k, v in ipairs(array) do
      block(v, function(err, result)
        if err then
          return check(err)
        end
        parts[k] = result
        return check()
      end)
    end
    return check()
  end,
  INC = function(name, callback)
    return render(__dirname .. '/../example/' .. name, getfenv(2), nil, callback)
  end,
  ESC = function(value, callback)
    if callback then
      return callback(nil, value:escape())
    else
      return value:escape()
    end
  end
}
Response.prototype.render = function(self, filename, data, options)
  if data == nil then
    data = { }
  end
  if options == nil then
    options = { }
  end
  render(filename, data, options, function(err, html)
    if err then
      self:fail(err.message or err)
    else
      self:send(200, html, {
        ['Content-Type'] = 'text/html; charset=UTF-8',
        ['Content-Length'] = #html
      })
    end
    return 
  end)
  return 
end
