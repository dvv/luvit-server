local Response = require('response')

Response.prototype.auto_server = 'U-Gotta-Luvit'

function Response.prototype:send(code, data, headers, close)
  p('REQ', self.req.url, code)
  if close == nil then close = true end
  self:write_head(code, headers or { })
  if data then
    self:write(data)
  end
  if close then
    self:finish()
  end
end

function Response.prototype:fail(reason)
  self:send(500, reason, {
    ['Content-Type'] = 'text/plain; charset=UTF-8',
    ['Content-Length'] = #reason
  })
end

function Response.prototype:serve_not_found()
  self:send(404)
end

function Response.prototype:serve_not_modified(headers)
  self:send(304, nil, headers)
end

function Response.prototype:serve_invalid_range(size)
  self:send(416, nil, {
    ['Content-Range'] = 'bytes=*/' .. size
  })
end
