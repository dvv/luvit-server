local sub
do
  local _table_0 = require('string')
  sub = _table_0.sub
end
local Http = require('http')
local Stack = require('stack')
Stack.errorHandler = function(req, res, err)
  if err then
    local reason = err
    print('\n' .. reason .. '\n')
    return res:fail(reason)
  else
    return res:send(404)
  end
end
Stack.mount = function(mountpoint, ...)
  local stack = Stack.compose(...)
  local nmpoint = #mountpoint
  return function(req, res, continue)
    local url = req.url
    local uri = req.uri
    if sub(url, 1, nmpoint) ~= mountpoint then
      continue()
      return 
    end
    if not req.real_url then
      req.real_url = url
    end
    req.url = sub(url, nmpoint + 1)
    if req.uri then
      req.uri = Url.parse(req.url)
    end
    return stack(req, res, function(err)
      req.url = url
      req.uri = uri
      return continue(err)
    end)
  end
end
local Path = require('path')
require('./util')
require('./request')
require('./response')
local use
use = function(plugin_name)
  return require(Path.join(__dirname, plugin_name))
end
local run
run = function(layers, port, host)
  local handler = Stack.stack(unpack(layers))
  local server = Http.create_server(host or '127.0.0.1', port or 80, handler)
  return server
end
return {
  use = use,
  run = run
}
