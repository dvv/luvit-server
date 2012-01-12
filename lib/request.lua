local Request = require('request')
local match, gmatch
do
  local _table_0 = require('string')
  match = _table_0.match
  gmatch = _table_0.gmatch
end
Request.prototype.parse_cookies = function(self)
  self.cookies = { }
  if self.headers.cookie then
    for cookie in gmatch(self.headers.cookie, '[^;]+') do
      local name, value = match(cookie, '%s*([^=%s]-)%s*=%s*([^%s]*)')
      if name and value then
        self.cookies[name] = value
      end
    end
  end
  return 
end
