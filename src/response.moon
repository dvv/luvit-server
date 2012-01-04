--
-- augment Response
--

Response = require 'response'

import compile from require 'kernel'

noop = () ->

Response.prototype.auto_server = 'U-Gotta-Luvit'

Response.prototype.send = (code, data, headers, close = true) =>
  --d('RESPONSE FOR', @req and @req.method, @req and @req.url, 'IS', code, data)
  @write_head code, headers or {}
  @write data if data
  @finish() if close

-- serve 500 error and reason
Response.prototype.fail = (reason) =>
  @send 500, reason, {
    ['Content-Type']: 'text/plain; charset=UTF-8'
    ['Content-Length']: #reason
  }

-- serve 404 error
Response.prototype.serve_not_found = () =>
  @send 404

-- serve 304 not modified
Response.prototype.serve_not_modified = (headers) =>
  @send 304, nil, headers

-- serve 416 invalid range
Response.prototype.serve_invalid_range = (size) =>
  @send 416, nil, {
    ['Content-Range']: 'bytes=*/' .. size
  }

helpers = false

-- render filename with data from `data` table
render = (filename, data = {}, options = {}, callback) ->
  compile filename, (err, template) ->
    if err
      callback err
    else
      setmetatable data, __index: helpers
      template data, callback
    return
  return

helpers = {
  IF: (condition, block, callback) ->
    if condition
      block getfenv(2), callback
    else
      callback nil, ''
    return
  EACH: (array, block, callback) ->
    parts = {}
    size = #array
    done = false
    check = (err) ->
      return if done
      if #parts == size
        done = true
        callback err, join parts, ''
    -- TODO: pairs?
    for k, v in ipairs array
      block v, (err, result) ->
        return check err if err
        parts[k] = result
        check()
    check()
  INC: (name, callback) ->
    render __dirname .. '/../example/' .. name, getfenv(2), nil, callback
  ESC: (value, callback) ->
    if callback
      callback nil, value\escape()
    else
      return value\escape()
}

-- render filename with data from `data` table
-- and serve it with status 200 as text/html
Response.prototype.render = (filename, data = {}, options = {}) =>
  render filename, data, options, (err, html) ->
    if err
      @fail err.message or err
    else
      @send 200, html, {
        ['Content-Type']: 'text/html; charset=UTF-8'
        ['Content-Length']: #html
      }
    return
  return
