--
-- Handle signin/signout
--

Curl = require 'curl'
import sha1 from require 'crypto'

-- openid brokers
openid_brokers =
  -- loginza -- a set of openid providers popular in Russian Federation
  ['http://loginza.ru/api/redirect?']:
    --
    get_url: (token) -> 'http://loginza.ru/api/authinfo?token=' .. token
    --
    collect_data: (data) ->
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

  openid = options.openid
  if openid == true
    openid = openid_brokers

  (req, res, continue) ->

    return continue() if req.url != url

    -- openid broker
    -- TODO: generalize and extract into own module?
    if openid and req.body.token and req.method == 'POST'
      -- authenticate against an openid provider
      referrer = req.headers.referer or req.headers.referrer
      for provider_url, provider in pairs openid
        -- provider matched?
        if referrer\find(provider_url) == 1
          -- issue authentication request
          params = {
            url: provider.get_url req.body.token
          }
          Curl.get params, (err, data) ->
            --p('GOT', data)
            profile = nil
            if data
              -- collect profile data from openid provider response
              profile = provider.collect_data data
              --p('PROFILE', profile)
            -- given profile authenticated by an openid provider, request new session
            options.authenticate nil, profile, (session) ->
              -- falsy session means to remove current session
              req.session = session
              -- go back
              res\send 302, nil, {
                ['Location']: '/'
              }
          break
      return

    -- native signin/signout
    -- given current session and request body, request new session
    options.authenticate req.session, req.body, (session) ->
      -- falsy session means to remove current session
      req.session = session
      -- go back
      res\send 302, nil, {
        ['Location']: req.headers.referer or req.headers.referrer or '/'
      }
