#!/usr/bin/env luvit

local Log = require('../lib/log')

-- create application
local app = require('../').new()

local function authorize(session, callback)
  -- user authenticated
  if session and session.uid then
    callback({
      uid = session.uid,
      foo = {
        -- GET /foo?a=b --> foo.query('a=b', ...) --> 200 { "you are": "an authorized user!" }
        query = function (query, cb)
          cb(nil, { ['you are'] = 'an authorized user!' })
        end,
        -- DELETE /foo/1 --> foo.remove('1', ...) --> 204
        remove = function (query, cb)
          cb(nil)
        end
      }
    })
  -- guest
  else
    callback({
      foo = {
        query = function (query, cb)
          cb(nil, { ['you are'] = 'a guest!' })
        end
      }
    })
  end
end

-- tune options
app:set('render', {
  prefix = __dirname .. '/views',
  suffix = '.html',
})

app:mount('/static/', 'static', {
  directory = __dirname .. '/static'
})

app:set('render', {
  prefix = __dirname .. '/views',
  suffix = '.html',
})

app:mount('/echo', require('sockjs')({
  root = 'WS',
  onopen = function (conn)
    p('OPEN', conn)
  end,
  onclose = function (conn)
    p('CLOSE', conn)
  end,
  onerror = function (conn, error)
    p('ERROR', conn, error)
  end,
  onmessage = function (conn, message)
    p('<<<', message)
    -- repeater
    conn:send(message)
    p('>>>', message)
    -- close if 'quit' is got
    if message == 'quit' then
      conn:close(1002, 'Forced closure')
    end
  end,
}))

-- handle cookie session and request context
app:use('session', {
  secret = 'topsecret',
  authorize = authorize,
})

-- serve chrome page
app:GET('/$', function (self, nxt)
  self:render('index', {foo = 'bar'})
end)

-- custom route
app:GET('/foo$', function (self, nxt)
  self:send(200, 'FOO')
end)

-- custom route
app:GET('/bar$', function (self, nxt)
  self:send(200, 'BAR')
end)

app:mount('/engine.io', require('websocket')({
  engine = true,
  onopen = function (conn)
    p('OPEN', conn)
  end,
  onclose = function (conn)
    p('CLOSE', conn)
  end,
  onerror = function (conn, error)
    p('ERROR', conn, error)
  end,
  onmessage = function (conn, message)
    p('<<<', message)
    -- repeater
    conn:send(message)
    p('>>>', message)
    -- close if 'quit' is got
    if message == 'quit' then
      conn:close(1002, 'Forced closure')
    end
  end,
}))

-- run server
app:run(8081, '0.0.0.0')
