--
-- standard HTTP server middleware layers
--

import sub from require 'string'

Http = require 'http'

Stack = require 'stack'

Stack.errorHandler = (req, res, err) ->
  if err
    reason = err
    print '\n' .. reason .. '\n'
    res\fail reason
  else
    res\send 404

Stack.mount = (mountpoint, ...) ->
  stack = Stack.compose ...
  nmpoint = #mountpoint
  return (req, res, continue) ->
    url = req.url
    uri = req.uri
    if sub(url, 1, nmpoint) != mountpoint
      continue()
      return
    -- modify the url
    if not req.real_url
      req.real_url = url
    req.url = sub url, nmpoint + 1
    if req.uri
      req.uri = Url.parse req.url
    stack req, res, (err) ->
      req.url = url
      req.uri = uri
      continue err

Path = require 'path'

require './util'
require './request'
require './response'

use = (plugin_name) ->
  require Path.join __dirname, plugin_name

run = (layers, port, host) ->
  handler = Stack.stack unpack(layers)
  server = Http.create_server host or '127.0.0.1', port or 80, handler
  server

-- export module
return {
  use: use
  run: run
}
