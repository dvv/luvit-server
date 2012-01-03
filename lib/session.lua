local sub, match, format
do
  local _table_0 = require('string')
  sub, match, format = _table_0.sub, _table_0.match, _table_0.format
end
local date, time
do
  local _table_0 = require('os')
  date, time = _table_0.date, _table_0.time
end
local encrypt, uncrypt, sign
do
  local _table_0 = require('crypto')
  encrypt, uncrypt, sign = _table_0.encrypt, _table_0.uncrypt, _table_0.sign
end
local encode, decode, null
do
  local _table_0 = require('json')
  encode, decode, null = _table_0.encode, _table_0.decode, _table_0.null
end
local expires_in
expires_in = function(ttl)
  return date('%c', time() + ttl)
end
local serialize
serialize = function(secret, obj)
  local str = encode(obj)
  local str_enc = encrypt(secret, str)
  local timestamp = time()
  local hmac_sig = sign(secret, timestamp .. str_enc)
  local result = hmac_sig .. timestamp .. str_enc
  return result
end
local deserialize
deserialize = function(secret, ttl, str)
  local hmac_signature = sub(str, 1, 40)
  local timestamp = tonumber(sub(str, 41, 50), 10)
  local data = sub(str, 51)
  local hmac_sig = sign(secret, timestamp .. data)
  if hmac_signature ~= hmac_sig or timestamp + ttl <= time() then
    return nil
  end
  data = uncrypt(secret, data)
  data = decode(data)
  if data == null then
    data = nil
  end
  return data
end
local read_session
read_session = function(key, secret, ttl, req)
  local cookie = type(req) == 'string' and req or req.headers.cookie
  if cookie then
    cookie = match(cookie, '%s*;*%s*' .. key .. '=(%w*)')
    if cookie and cookie ~= '' then
      return deserialize(secret, ttl, cookie)
    end
  end
  return nil
end
return function(options)
  if options == nil then
    options = { }
  end
  local key = options.key or 'sid'
  local ttl = options.ttl or 15 * 24 * 60 * 60 * 1000
  local secret = options.secret
  local context = options.context or { }
  return function(req, res, continue)
    req.session = read_session(key, secret, ttl, req)
    local _write_head = res.write_head
    res.write_head = function(self, code, headers, callback)
      local cookie = nil
      if not req.session then
        if req.headers.cookie then
          cookie = format('%s=;expires=%s;httponly;path=/', key, expires_in(0))
        end
      else
        cookie = format('%s=%s;expires=%s;httponly;path=/', key, serialize(secret, req.session), expires_in(ttl))
      end
      if cookie then
        self:add_header('Set-Cookie', cookie)
      end
      return _write_head(self, code, headers, callback)
    end
    if options.default_session and not req.session then
      req.session = options.default_session
    end
    if options.authorize then
      return options.authorize(req.session, function(context)
        req.context = context or { }
        return continue()
      end)
    else
      req.context = context.guest or { }
      if req.session and req.session.uid then
        req.context = context.user or req.context
      end
      return continue()
    end
  end
end
