local sub
do
  local _table_0 = require('string')
  sub = _table_0.sub
end
local urldecode
do
  local _table_0 = require('querystring')
  urldecode = _table_0.urldecode
end
local JSON = require('json')
return function(mount, options)
  if mount == nil then
    mount = '/rpc/'
  end
  if options == nil then
    options = { }
  end
  if sub(mount, #mount) ~= '/' then
    mount = mount .. '/'
  end
  local mlen = #mount
  local brand_new_id = options.put_new and options.put_new or { }
  return function(req, res, continue)
    local path = req.uri.pathname
    if sub(path, 1, mlen) ~= mount then
      return continue()
    end
    local resource = nil
    local id = nil
    path:sub(mlen + 1):gsub('[^/]+', function(part)
      if not resource then
        resource = urldecode(part)
      elseif not id then
        id = urldecode(part)
      end
    end)
    local verb = req.headers['X-HTTP-Method-Override'] or req.method
    local method = nil
    local params = nil
    if verb == 'GET' then
      method = 'get'
      if id and id ~= brand_new_id then
        params = {
          id
        }
      else
        method = 'query'
        if req.body[1] then
          params = {
            req.body
          }
        else
          params = {
            req.uri.search
          }
        end
      end
    elseif verb == 'PUT' then
      method = 'update'
      if id then
        if id == brand_new_id then
          method = 'add'
          params = {
            req.body
          }
        else
          params = {
            id,
            req.body
          }
        end
      else
        if req.body[1] and req.body[1][1] then
          params = {
            req.body[1],
            req.body[2]
          }
        else
          params = {
            req.uri.search,
            req.body
          }
        end
      end
    elseif verb == 'DELETE' then
      method = 'remove'
      if id and id ~= brand_new_id then
        params = {
          id
        }
      else
        if req.body[1] then
          params = {
            req.body
          }
        else
          params = {
            req.uri.search
          }
        end
      end
    elseif verb == 'POST' then
      if options.put_new or req.body.jsonrpc then
        method = req.body.method
        params = req.body.params
      else
        method = 'add'
        params = {
          req.body
        }
      end
    end
    local respond
    respond = function(err, result)
      local response = nil
      if options.jsonrpc or req.body.jsonrpc then
        response = { }
        if err then
          response.error = err
        elseif result == nil then
          response.result = true
        else
          response.result = result
        end
        res:write_head(200, {
          ['Content-Type'] = 'application/json'
        })
      else
        if err then
          res:write_head(type(err) == 'number' and err or 406, { })
        elseif result == nil then
          res:serve_not_found()
        else
          response = result
          res:write_head(200, {
            ['Content-Type'] = 'application/json'
          })
        end
      end
      if response then
        res:write(JSON.stringify(response))
      end
      return res:finish()
    end
    local context = req.context or options.context or { }
    resource = context[resource]
    if not resource then
      return respond(404)
    end
    if not resource[method] then
      return respond(405)
    end
    if options.pass_context then
      unshift(params, context)
    end
    push(params, respond)
    return resource[method](unpack(params))
  end
end
