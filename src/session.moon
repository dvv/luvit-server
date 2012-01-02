--
-- Provide req.session and user capabilities (req.context)
--

import sub, match, format from require 'string'
import date, time from require 'os'
import encrypt, uncrypt, sign from require 'crypto'
import encode, decode from require 'json'

expires_in = (ttl) -> date '%c', time() + ttl

serialize = (secret, obj) ->
  str = encode obj
  str_enc = encrypt secret, str
  timestamp = time()
  hmac_sig = sign secret, timestamp .. str_enc
  --p('ENC', hmac_sig, timestamp, str_enc)
  result = hmac_sig .. timestamp .. str_enc
  result

deserialize = (secret, ttl, str) ->
  hmac_signature = sub str, 1, 40
  timestamp = tonumber sub(str, 41, 50), 10
  data = sub str, 51
  p(DEC, hmac_signature, timestamp, data)
  hmac_sig = sign secret, timestamp .. data
  return nil if hmac_signature != hmac_sig or timestamp + ttl <= time()
  data = uncrypt secret, data
  decode data

read_session = (key, secret, ttl, req) ->
  cookie = type(req) == 'string' and req or req.headers.cookie
  --d(cookie)
  if cookie
    cookie = match cookie, '%s*;*%s*' .. key .. '=(%w*)'
    if cookie and cookie != ''
      --d('raw read', cookie)
      return deserialize secret, ttl, cookie
  nil

-- tests
if false
  secret = 'foo-bar-baz$'
  obj = {a: {foo: 123, bar: "456"}, b: {1,2,nil,3}, c: false, d: 0}
  ser = serialize secret, obj
  p(ser)
  deser = deserialize secret, 1, ser
  -- N.B. nils are killed
  p(deser, deser == obj)

--
-- we keep sessions safely in encrypted and signed cookies.
-- inspired by caolan/cookie-sessions
--
return (options = {}) ->

  -- defaults
  key = options.key or 'sid'
  ttl = options.ttl or 15 * 24 * 60 * 60 * 1000
  secret = options.secret
  context = options.context or {}

  -- handler
  return (req, res, continue) ->

    -- read session data from request and store it in req.session
    req.session = read_session key, secret, ttl, req

    -- proxy write_head to add cookie to response
    -- TODO: res.req = req ; then it's possible to avoid making this
    -- closure for each request
    _write_head = res.write_head
    res.write_head = (self, status, headers) ->
      cookie = nil
      if not req.session
        if req.headers.cookie
          cookie = format '%s=; expires=; httponly; path=/', key, expires_in(0)
      else
        cookie = format '%s=%s; expires=; httponly; path=/', key, serialize(secret, req.session), expires_in(ttl)
      -- Set-Cookie
      -- FIXME: support multiple Set-Cookie:
      if cookie
        headers = {} if not headers
        headers['Set-Cookie'] = cookie
      -- call original method
      --d('response with cookie', headers)
      _write_head self, status, headers

    -- always create a session if options.default_session specified
    if options.default_session and not req.session
      req.session = options.default_session

    -- use authorization callback if specified
    if options.authorize
      -- given current session, return context
      options.authorize req.session, (context) ->
        req.context = context or {}
        continue()
    -- assign static context
    else
      -- default is guest context
      req.context = context.guest or {}
      -- user authenticated?
      if req.session and req.session.uid
        -- provide user context
        req.context = context.user or req.context
      -- FIXME: admin context somehow?
      continue()
