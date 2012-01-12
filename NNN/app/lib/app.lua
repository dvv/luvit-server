--
-- Application
--

local Utils = require('utils')
local Path = require('path')
local Table = require('table')
local Emitter = require('emitter')
local HTTP = require('http')
local Stack = require('stack')
local Log = require('./log')

--
-- augment standard things
--
require('./request')
require('./response')
--
require('./render')

local Application = { }

-- Application is EventEmitter
Utils.inherits(Application, Emitter)

--
-- create new application
--

function Application.new(options)
  self = Application.new_obj()
  self.options = { }
  -- middleware stack layers
  self.stack = { }
  -- custom routes
  self.routes = { }
  -- set initial options
  self:set(options)
  return self
end

--
-- set application options
--

function Application.prototype:set(option, value)
  -- option can be table
  if type(option) == 'table' then
    -- set a bunch of options
    for k, v in pairs(options or { }) do
      self:set(k, v)
    end
    return self
  end
  -- report the change and validate option
  if self.options[option] ~= value then
    -- FIXME: do handlers return values?
    if self:emit('change', option, value, self.options[option]) == false then
      error('Cannot set option "' .. option .. '"')
    end
    self.options[option] = value
    Log.debug('SET OPTION', option, value)
  end
  return self
end

--
-- add middleware layer
--

function Application.prototype:use(handler, ...)
  local layer
  if type(handler) == 'string' then
    local plugin = require(Path.join(__dirname, 'stack', handler))
    layer = plugin(...)
  else
    layer = handler
  end
  Table.insert(self.stack, layer)
  return self
end

--
-- mount a handler onto an exact path
--

function Application.prototype:mount(path, handler, ...)
  local layer
  if type(handler) == 'string' then
    local plugin = require(Path.join(__dirname, 'stack', handler))
    layer = plugin(...)
  else
    layer = handler
  end
  local plen = #path
  Table.insert(self.stack, function (req, res, nxt)
    if req.uri.pathname:sub(1, plen) == path then
      -- FIXME: this eats pathname forever
      -- if in layer we call nxt(), that handler receives cut pathname
      req.uri.pathname = req.uri.pathname:sub(plen + 1)
      layer(req, res, nxt)
    else
      nxt()
    end
  end)
  return self
end

--
-- router helpers
--

function Application.prototype:GET(url_regexp, handler)
  return self:route('GET ' .. url_regexp, handler)
end
function Application.prototype:POST(url_regexp, handler)
  return self:route('POST ' .. url_regexp, handler)
end
function Application.prototype:PUT(url_regexp, handler)
  return self:route('PUT ' .. url_regexp, handler)
end
function Application.prototype:DELETE(url_regexp, handler)
  return self:route('DELETE ' .. url_regexp, handler)
end

--
-- mount a route handler onto a path and verb
--

function Application.prototype:route(rule, handler, ...)
  Table.insert(self.routes, { rule, handler })
  return self
end

--
-- start HTTP server at `host`:`port`
--

function Application.prototype:run(port, host)
  if not port then port = 80 end
  if not host then host = '127.0.0.1' end
  --
  local parse_url = require('url').parse
  local parse_query = require('querystring').parse
  -- copy stack
  local stack = { }
  for _, layer in ipairs(self.stack) do Table.insert(stack, layer) end
  -- append standard router
  Table.insert(stack, function (req, res, nxt)
    local str = req.method .. ' ' .. req.uri.pathname
    for _, pair in ipairs(self.routes) do
      local params = { str:match(pair[1]) }
      if params[1] then
        pair[2](res, nxt, unpack(params))
        return
      end
    end
    nxt()
  end)
  -- compose request handler
  local handler = Stack.stack(unpack(stack))
  -- start HTTP server
  self.server = HTTP.create_server(host, port, function (req, res)
    -- bootstrap response
    res.req = req
    res.app = self
    -- preparse request
    req.uri = parse_url(req.url, true)
    req.uri.query = parse_query(req.uri.query)
    --Log.debug('REQ', req)
    handler(req, res)
  end)
  Log.info('Server listening at http://%s:%d/. Press CTRL+C to stop...', host, port)
  return self
end

-- module
return Application
