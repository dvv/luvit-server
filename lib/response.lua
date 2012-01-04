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
Response.prototype.render = function(self, filename, data, options)
  if data == nil then
    data = { }
  end
  if options == nil then
    options = { }
  end
  render(filename, data, function(err, html)
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
