--
-- keep sessions safely in encrypted and signed cookies.
-- inspired by caolan/cookie-sessions
--

--
-- Parse cookie-based session from Cookie: header
-- into `req.session`.
-- If session is authenticated, fill `req.context` with user capabilities
--

local String = require('string')
local sub, match, format = String.sub, String.match, String.format

local OS = require('os')
local date, time = OS.date, OS.time

local Crypto = require('crypto')
local encrypt, uncrypt, sign = Crypto.encrypt, Crypto.uncrypt, Crypto.sign

local JSON = require('json')

local function expires_in(ttl)
  return date('%c', time() + ttl)
end

local function serialize(secret, obj)
  local str = JSON.stringify(obj)
  local str_enc = encrypt(secret, str)
  local timestamp = time()
  local hmac_sig = sign(secret, timestamp .. str_enc)
  local result = hmac_sig .. timestamp .. str_enc
  return result
end

local function deserialize(secret, ttl, str)
  local hmac_signature = sub(str, 1, 40)
  local timestamp = tonumber(sub(str, 41, 50), 10)
  local data = sub(str, 51)
  local hmac_sig = sign(secret, timestamp .. data)
  if hmac_signature ~= hmac_sig or timestamp + ttl <= time() then
    return nil
  end
  data = uncrypt(secret, data)
  data = JSON.parse(data)
  if data == JSON.null then data = nil end
  return data
end

local function read_session(key, secret, ttl, req)
  local cookie = type(req) == 'string' and req or req.headers.cookie
  if cookie then
    cookie = match(cookie, '%s*;*%s*' .. key .. '=(%w*)')
    if cookie and cookie ~= '' then
      return deserialize(secret, ttl, cookie)
    end
  end
end

return function (options)

  -- defaults
  if options == nil then options = { } end
  local key = options.key or 'sid'
  local ttl = options.ttl or 15 * 24 * 60 * 60 * 1000
  local secret = options.secret
  local context = options.context or { }

  --
  -- handler
  --
  return function (req, res, nxt)

    -- read session data from request and store it in req.session
    req.session = read_session(key, secret, ttl, req)

    -- patch response to support writing cookies
    -- TODO: is there a lighter method?
    local _write_head = res.write_head
    res.write_head = function (self, code, headers, callback)
      local cookie = nil
      if not req.session then
        if req.headers.cookie then
          cookie = format('%s=;expires=%s;httponly;path=/', key, expires_in(0))
        end
      else
        cookie = format('%s=%s;expires=%s;httponly;path=/', key, serialize(secret, req.session), expires_in(ttl))
      end
      -- Set-Cookie
      if cookie then
        self:add_header('Set-Cookie', cookie)
      end
      _write_head(self, code, headers, callback)
    end

    -- always create a session if options.default_session specified
    if options.default_session and not req.session then
      req.session = options.default_session
    end

    -- use authorization callback if specified
    if options.authorize then
      -- given current session, setup request context
      options.authorize(req.session, function (context)
        req.context = context or { }
        nxt()
      end)
    -- assign static request context
    else
      -- default is guest request context
      req.context = context.guest or { }
      -- user authenticated?
      if req.session and req.session.uid and context.user then
        -- provide user request context
        req.context = context.user
      end
      nxt()
    end

  end

end
