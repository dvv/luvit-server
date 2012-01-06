--
-- standard HTTP server middleware layers
--

require './util'

require './request'
require './response'

Http = require 'http'
Stack = require 'stack'
Path = require 'path'

parse_url = require('url').parse
parse_query = require('querystring').parse

Stack.errorHandler = (req, res, err) ->
  if err
    reason = err
    print '\n' .. reason .. '\n'
    res\fail reason
  else
    res\send 404

--
-- require a plugin by name
--
use = (plugin_name) ->
  require Path.join __dirname, plugin_name

--
-- create listening server with specified middleware layers
--
run = (layers, port, host) ->
  handler = Stack.stack unpack(layers)
  server = Http.create_server host or '127.0.0.1', port or 80, (req, res) ->
    -- bootstrap response
    res.req = req
    if not req.uri
      req.uri = parse_url req.url
      req.uri.query = parse_query req.uri.query
    -- handle request
    handler req, res
    return
  server

--
-- create standard listening server with default middleware
--
standard = (port, host, options) ->
  extend options, {
  }
  layers = {
    -- report health status to load balancer
    use('health')()
    -- serve static files
    use('static')('/public/', options.static)
    -- handle session
    use('session')(options.session)
    -- parse request body
    use('body')()
    -- process custom routes
    use('route')(options.routes)
    -- handle authentication
    use('auth')('/rpc/auth', options.session)
    -- RPC & REST
    use('rest')('/rpc/')
  }
  -- run server
  run layers, port, host

-- export module
return {
  use: use
  run: run
  standard: standard
}
