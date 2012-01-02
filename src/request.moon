--
-- augment Request
--

Request = require 'request'

import match, gmatch from require 'string'

--
-- parse request cookies
--
Request.prototype.parse_cookies = () =>
  @cookies = {}
  if @headers.cookie
    for cookie in gmatch(@headers.cookie, '[^;]+')
      name, value = match cookie, '%s*([^=%s]-)%s*=%s*([^%s]*)'
      @cookies[name] = value if name and value
  return
