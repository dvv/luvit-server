--
-- Handle signin/signout
--

HTTP = require 'http'
body_parser = require('./body')()

wget = (host, path, data, callback) ->
  params = {
    host: host
    port: 80
    path: data and path .. '?' .. data or path
  }
  p(params)
  HTTP.request params, (res) ->
    body_parser res, nil, () ->
      callback nil, res.body
    res\on 'end', () ->
      res\close()

return (url = '/rpc/auth', options = {}) ->

  (req, res, continue) ->

    if req.url == url

      -- openid broker
      if req.body.token and req.method == 'POST'
        -- request provider
        provider = req.headers.referer or req.headers.referrer
        if provider and provider\find('http://loginza.ru/api/redirect?') == 1
          --wget 'http://loginza.ru/api/authinfo?token=' .. req.body.token, (err, data) ->
          wget '213.180.204.205', '/api/authinfo', 'token=' .. req.body.token, (err, data) ->
            p('GOT', err, data)
            -- given current session and request body, request new session
            options.authenticate req.session, data, (session) ->
              -- falsy session means to remove current session
              req.session = session
              -- go back
              res\send 302, nil, {
                ['Location']: '/'
              }

      else
        -- given current session and request body, request new session
        options.authenticate req.session, req.body, (session) ->
          -- falsy session means to remove current session
          req.session = session
          -- go back
          res\send 302, nil, {
            ['Location']: req.headers.referer or req.headers.referrer or '/'
          }

    else
      continue()

    return
