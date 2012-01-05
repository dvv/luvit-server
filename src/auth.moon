--
-- Handle signin/signout
--

HTTP = require 'http'
body_parser = require('./body')()

[[--
--
-- get remote data
--
wget = (host, path, data, callback) ->
  params = {
    host: host
    port: 80
    path: data and path .. '?' .. data or path
  }
  --p(params)
  HTTP.request params, (res) ->
    body_parser res, nil, () ->
      callback nil, res.body
    res\on 'end', () ->
      res\close()
--]]

--
-- collect profile data
--
import sha1 from require 'crypto'
collect_data = (data) ->
  return nil if not data or not data.identity
  uid = sha1 data.identity
  -- twitter
  if data.provider == 'http://twitter.com/'
    data = {
      uid: uid
      name: data.name and data.name.full_name or data.email
      email: data.email
      photo: data.photo
    }
  -- google
  elseif data.provider == 'https://www.google.com/accounts/o8/ud'
    data = {
      uid: uid
      name: data.name and data.name.full_name or data.email
      email: data.email
      photo: data.photo
    }
  -- vkontakte.ru
  elseif data.provider == 'http://vkontakte.ru/'
    data = {
      uid: uid
      name: data.name and (data.name.first_name .. ' ' .. data.name.last_name) or data.email
      email: data.email
      photo: data.photo
    }
  -- other providers
  else
    data = {
      uid: uid
      name: data.name and data.name.full_name or data.name
      email: data.email
      photo: data.photo
    }
  data

return (url = '/rpc/auth', options = {}) ->

  (req, res, continue) ->

    return continue() if req.url != url

    -- openid broker
    -- TODO: generalize and extract into own module?
    if req.body.token and req.method == 'POST'
      -- authenticate against an openid provider
      provider = req.headers.referer or req.headers.referrer
      if provider and provider\find('http://loginza.ru/api/redirect?') == 1
        params = {
          host: '213.180.204.205' -- 'loginza.ru'
          path: '/api/authinfo?token=' .. req.body.token
        }
        HTTP.request params, (wget) ->
          -- FIXME: this doesn't catch connect errors
          wget\on 'error', (err) ->
            p('ERRRRRRRR', err)
          wget\on 'end', () -> wget\close()
          body_parser wget, nil, () ->
            --p('GOT', wget.body)
            profile = collect_data wget.body
            --p('PROFILE', profile)
            -- given profile authenticated by an openid provider, request new session
            options.authenticate nil, profile, (session) ->
              -- falsy session means to remove current session
              req.session = session
              -- go back
              res\send 302, nil, {
                ['Location']: '/'
              }

    -- native signin/signout
    else
      -- given current session and request body, request new session
      options.authenticate req.session, req.body, (session) ->
        -- falsy session means to remove current session
        req.session = session
        -- go back
        res\send 302, nil, {
          ['Location']: req.headers.referer or req.headers.referrer or '/'
        }
