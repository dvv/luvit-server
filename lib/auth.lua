local HTTP = require('http')
local body_parser = require('./body')()
local _ = [[--
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
local sha1
do
  local _table_0 = require('crypto')
  sha1 = _table_0.sha1
end
local collect_data
collect_data = function(data)
  if not data or not data.identity then
    return nil
  end
  local uid = sha1(data.identity)
  if data.provider == 'http://twitter.com/' then
    data = {
      uid = uid,
      name = data.name and data.name.full_name or data.email,
      email = data.email,
      photo = data.photo
    }
  elseif data.provider == 'https://www.google.com/accounts/o8/ud' then
    data = {
      uid = uid,
      name = data.name and data.name.full_name or data.email,
      email = data.email,
      photo = data.photo
    }
  elseif data.provider == 'http://vkontakte.ru/' then
    data = {
      uid = uid,
      name = data.name and (data.name.first_name .. ' ' .. data.name.last_name) or data.email,
      email = data.email,
      photo = data.photo
    }
  else
    data = {
      uid = uid,
      name = data.name and data.name.full_name or data.name,
      email = data.email,
      photo = data.photo
    }
  end
  return data
end
return function(url, options)
  if url == nil then
    url = '/rpc/auth'
  end
  if options == nil then
    options = { }
  end
  return function(req, res, continue)
    if req.url ~= url then
      return continue()
    end
    if req.body.token and req.method == 'POST' then
      local provider = req.headers.referer or req.headers.referrer
      if provider and provider:find('http://loginza.ru/api/redirect?') == 1 then
        local params = {
          host = '213.180.204.205',
          path = '/api/authinfo?token=' .. req.body.token
        }
        return HTTP.request(params, function(wget)
          wget:on('error', function(err)
            return p('ERRRRRRRR', err)
          end)
          wget:on('end', function()
            return wget:close()
          end)
          return body_parser(wget, nil, function()
            local profile = collect_data(wget.body)
            return options.authenticate(nil, profile, function(session)
              req.session = session
              return res:send(302, nil, {
                ['Location'] = '/'
              })
            end)
          end)
        end)
      end
    else
      return options.authenticate(req.session, req.body, function(session)
        req.session = session
        return res:send(302, nil, {
          ['Location'] = req.headers.referer or req.headers.referrer or '/'
        })
      end)
    end
  end
end
