#!/usr/bin/env luvit

local HTTP = require('http')
local body_parser = require('./lib/body')()
local wget
wget = function(host, path, data, callback)
  local params = {
    host = host,
    port = 80,
    path = data and path .. '?' .. data or path
  }
  p(params)
  HTTP.request(params, function(res)
    p(res)
    body_parser(res, nil, function()
      callback(nil, res.body)
    end)
    res:on('end', function()
      res:close()
    end)
  end)
end
wget('213.180.204.2051', '/api/authinfo', 'token=a88e7cec94343bae63624b569ab09da5', function(err, data)
  p(err, data)
end)
