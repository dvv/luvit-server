local Response = require('response')

function Response.prototype:handle_xhr_cors()
  local origin = self.req.headers['origin'] or '*'
  self:set_header('Access-Control-Allow-Origin', origin)
  local headers = self.req.headers['access-control-request-headers']
  if headers then
    self:set_header('Access-Control-Allow-Headers', headers)
  end
  self:set_header('Access-Control-Allow-Credentials', 'true')
end

function Response.prototype:handle_balancer_cookie()
  if not self.req.cookies then
    self.req:parse_cookies()
  end
  local jsid = self.req.cookies['JSESSIONID'] or 'dummy'
  self:set_header('Set-Cookie', 'JSESSIONID=' .. jsid .. '; path=/')
end

local delay = require('timer').set_timeout

function Response.prototype:write_frame(payload, continue)
  if self.max_size then
    self.curr_size = self.curr_size + #payload
  end
  self:write(payload, function(err)
    if self.max_size and self.curr_size >= self.max_size then
      self:finish(function()
        if continue then continue(err) ; return end
      end)
    else
      if continue then
        continue()
      end
    end
  end)
end

function Response.prototype:do_reasoned_close(status, reason)
  if self.session then
    self.session:unbind()
  end
  self:finish()
end

return Response
