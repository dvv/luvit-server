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

Stack.errorHandler = (req, res, err) ->
  if err
    reason = err
    print '\n' .. reason .. '\n'
    res\fail reason
  else
    res\send 404

use = (plugin_name) ->
  require Path.join __dirname, plugin_name

run = (layers, port, host) ->
  handler = Stack.stack unpack(layers)
  server = Http.create_server host or '127.0.0.1', port or 80, (req, res) ->
    -- bootstrap response
    res.req = req
    if not req.uri
      req.uri = parse_url req.url
      req.uri.query = req.uri.query\parse_query()
    -- handle request
    handler req, res
    return
  server

-- export module
return {
  use: use
  run: run
}
