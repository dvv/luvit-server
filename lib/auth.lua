local HTTP = require('http')
local body_parser = require('./body')()
local wget
wget = function(host, path, data, callback)
  local params = {
    host = host,
    port = 80,
    path = data and path .. '?' .. data or path
  }
  p(params)
  return HTTP.request(params, function(res)
    body_parser(res, nil, function()
      return callback(nil, res.body)
    end)
    return res:on('end', function()
      return res:close()
    end)
  end)
end
return function(url, options)
  if url == nil then
    url = '/rpc/auth'
  end
  if options == nil then
    options = { }
  end
  return function(req, res, continue)
    if req.url == url then
      if req.body.token and req.method == 'POST' then
        local provider = req.headers.referer or req.headers.referrer
        if provider and provider:find('http://loginza.ru/api/redirect?') == 1 then
          wget('213.180.204.205', '/api/authinfo', 'token=' .. req.body.token, function(err, data)
            p('GOT', err, data)
            return options.authenticate(req.session, data, function(session)
              req.session = session
              return res:send(302, nil, {
                ['Location'] = '/'
              })
            end)
          end)
        end
      else
        options.authenticate(req.session, req.body, function(session)
          req.session = session
          return res:send(302, nil, {
            ['Location'] = req.headers.referer or req.headers.referrer or '/'
          })
        end)
      end
    else
      continue()
    end
    return 
  end
end
