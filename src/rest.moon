--
-- ReST resource routing
--

import sub from require 'string'
import urldecode from require 'querystring'
JSON = require 'json'

return (mount = '/rpc/', options = {}) ->

  -- mount should end with '/'
  mount = mount .. '/' if sub(mount, #mount) != '/'
  mlen = #mount

  -- whether PUT /Foo/_new means POST /Foo
  -- useful to free POST verb for pure PRC calls
  brand_new_id = options.put_new and options.put_new or {}

  -- handler
  return (req, res, continue) ->

    -- none of our business unless url starts with `mount`
    path = req.uri.pathname
    return continue() if sub(path, 1, mlen) != mount

    -- split pathname into resource name and id
    -- TODO: support deeper resources
    resource = nil
    id = nil
    path\sub(mlen + 1)\gsub '[^/]+', (part) ->
      if not resource
        resource = urldecode part
      elseif not id
        id = urldecode part
      --p('parts', resource, id)

    --
    -- determine handler method and its parameters
    --

    -- N.B. support X-HTTP-Method-Override: to ease ReST for dumb clients
    verb = req.headers['X-HTTP-Method-Override'] or req.method
    method = nil
    params = nil

    -- query
    if verb == 'GET'

      method = 'get'
      -- get by ID
      if id and id != brand_new_id
        params = {id}
      -- query
      else
        method = 'query'
        -- bulk get via POST X-HTTP-Method-Override: GET
        if req.body[1]
          params = {req.body}
        -- query by RQL
        else
          params = {req.uri.search}

    -- create new / update resource
    elseif verb == 'PUT'

      method = 'update'
      if id
        -- add new
        if id == brand_new_id
          method = 'add'
          params = {req.body}
        -- update by ID
        else
          params = {id, req.body}
      else
        -- bulk update via POST X-HTTP-Method-Override: PUT
        if req.body[1] and req.body[1][1]
          params = {req.body[1], req.body[2]}
        -- update by RQL
        else
          params = {req.uri.search, req.body}

    -- remove resource
    elseif verb == 'DELETE'

      method = 'remove'
      if id and id != brand_new_id
        params = {id}
      else
        -- bulk remove via POST X-HTTP-Method-Override: DELETE
        if req.body[1]
          params = {req.body}
        -- remove by RQL
        else
          params = {req.uri.search}

    -- arbitrary RPC to resource
    elseif verb == 'POST'

      -- if creation is via PUT, POST is solely for RPC
      -- if `req.body` has truthy `jsonrpc` key -- try RPC
      if options.put_new or req.body.jsonrpc
        -- RPC
        method = req.body.method
        params = req.body.params
      -- else POST is solely for creation
      else
        -- add
        method = 'add'
        params = {req.body}

    -- unsupported verb
    --else
      -- NYI

    --p('PARSED', resource, method, params)

    -- called after handler finishes
    respond = (err, result) ->
      --p('RPC!', err, result, options, req.body)
      response = nil
      -- JSON-RPC response
      if options.jsonrpc or req.body.jsonrpc
        response = {}
        if err
          response.error = err
        elseif result == nil
          response.result = true
        else
          response.result = result
        res\write_head 200, {
          ['Content-Type']: 'application/json'
        }
      -- plain response
      else
        if err
          res\write_head(type(err) == 'number' and err or 406, {})
        elseif result == nil
          res\serve_not_found()
        else
          response = result
          res\write_head 200, {
            ['Content-Type']: 'application/json'
          }
      --p('RPC!!', response)
      res\write JSON.stringify(response) if response
      res\finish()

    --
    -- find the handler
    --

    -- bail out unless resource is found
    context = req.context or options.context or {}
    resource = context[resource]
    return respond 404 if not resource
    -- bail out unless resource method is supported
    return respond 405 if not resource[method]

    --
    -- call the handler. signature is fn(params..., nxt), or fn(context, params..., nxt)
    --

    if options.pass_context
      unshift params, context
    push params, respond
    --p('RPC?', params)
    resource[method] unpack params
