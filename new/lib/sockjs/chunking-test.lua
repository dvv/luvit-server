local OS = require('os')
local date, time = OS.date, OS.time

local delay = require('timer').set_timeout

return {

  POST = function (self, options)
    self:handle_xhr_cors()
    self:set_code(200)
    self:set_header('Content-Type', 'application/javascript; charset=UTF-8')
    local delays = {
      1,
      5,
      25,
      125,
      625,
      3125
    }
    local function send(k)
      if k == 2 then
        self:write((rep(' ', 2048)) .. 'h\n')
      else
        self:write('h\n')
      end
      if k == 7 then
        --p('CHUNKINGDONE')
        if not self.closed then
          self:finish()
        end
      else
        set_timeout(delays[k], send, k + 1)
      end
    end
    send(1)
  end,

  OPTIONS = function (self, options)
    self:handle_xhr_cors()
    self:handle_balancer_cookie()
    self:send(204, nil, {
      ['Allow'] = 'OPTIONS, POST',
      ['Cache-Control'] = 'public, max-age=' .. options.cache_age,
      ['Expires'] = date('%c', time() + options.cache_age),
      ['Access-Control-Max-Age'] = tostring(options.cache_age)
    })
  end

}
