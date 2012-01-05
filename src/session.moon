--
-- Provide req.session and user capabilities (req.context)
--

import sub, match, format from require 'string'
import date, time from require 'os'
import encrypt, uncrypt, sign from require 'crypto'
import encode, decode, null from require 'json'

expires_in = (ttl) -> date '%c', time() + ttl

serialize = (secret, obj) ->
  str = encode obj
  str_enc = encrypt secret, str
  timestamp = time()
  hmac_sig = sign secret, timestamp .. str_enc
  result = hmac_sig .. timestamp .. str_enc
  result

deserialize = (secret, ttl, str) ->
  hmac_signature = sub str, 1, 40
  timestamp = tonumber sub(str, 41, 50), 10
  data = sub str, 51
  hmac_sig = sign secret, timestamp .. data
  return nil if hmac_signature != hmac_sig or timestamp + ttl <= time()
  data = uncrypt secret, data
  data = decode data
  data = nil if data == null
  data

read_session = (key, secret, ttl, req) ->
  cookie = type(req) == 'string' and req or req.headers.cookie
  if cookie
    cookie = match cookie, '%s*;*%s*' .. key .. '=(%w*)'
    if cookie and cookie != ''
      return deserialize secret, ttl, cookie
  nil

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

    -- patch response to support writing cookies
    -- TODO: is there a lighter method?
    _write_head = res.write_head
    res.write_head = (self, code, headers, callback) ->
      cookie = nil
      if not req.session
        if req.headers.cookie
          cookie = format '%s=;expires=%s;httponly;path=/', key, expires_in(0)
      else
        cookie = format '%s=%s;expires=%s;httponly;path=/', key, serialize(secret, req.session), expires_in(ttl)
      -- Set-Cookie
      if cookie
        self\add_header 'Set-Cookie', cookie
      _write_head self, code, headers, callback

    -- always create a session if options.default_session specified
    if options.default_session and not req.session
      req.session = options.default_session

    -- use authorization callback if specified
    if options.authorize
      -- given current session, setup request context
      options.authorize req.session, (context) ->
        req.context = context or {}
        continue()
    -- assign static request context
    else
      -- default is guest request context
      req.context = context.guest or {}
      -- user authenticated?
      if req.session and req.session.uid and context.user
        -- provide user request context
        req.context = context.user
      continue()
