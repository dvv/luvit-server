local Server = require('../')

--[[
 *
 * Application
 *
]]--

local function authenticate(session, credentials, cb)
  -- N.B. this is simple "toggle" logic.
  -- in real world you should check credentials passed in `credentials`
  -- to decide whether to let user in.
  -- just assign `nil` to session in case of error.
  -- session already set? drop session
  if session then
    session = nil
  -- no session so far? get new session
  else
    session = {
      uid = tostring(require('math').random()):sub(3),
    }
  end
  -- set the session
  cb(session)
end

local function authorize(session, cb)
  -- N.B. this is a simple wrapper for static context
  -- in real world you should vary capabilities depending on the
  -- current user defined in `session`
  if session and session.uid then
    cb({
      uid = session.uid,
      -- GET /foo?bar=baz ==> this.foo.query('bar=baz')
      foo = {
        query = function(query, cb)
          cb(nil, {['you are'] = 'an authorized user!'})
        end
      },
      bar = {
        baz = {
          add = function(data, cb)
            cb({['nope'] = 'nomatter you are an authorized user ;)'})
          end
        }
      },
      context = {
        query = function(query, cb)
          cb(nil, session or {})
        end
      },
      array = {
        {a = 'a'},
        {b = 'b'},
        {c = 'c'},
        {d = 'd'},
      }
    })
  else
    cb({
      -- GET /foo?bar=baz ==> this.foo.query('bar=baz')
      foo = {
        query = function(query, cb)
          cb(nil, {['you are'] = 'a guest!'})
        end
      },
      context = {
        query = function(query, cb)
          cb(nil, session or {})
        end
      },
    })
  end
end

local function layers() return {

  -- report health status to load balancer
  Server.use('health')(),

  -- test serving requested amount of octets
  function(req, res, nxt)
    local n = tonumber(req.url:sub(2), 10)
    if not n then nxt() return end
    local s = ('x'):rep(n)
    res:send(200, s, {
      ['Content-Type'] = 'text/plain',
      ['Content-Length'] = #s,
    })
  end,

  -- serve static files
  Server.use('static')('/public/', __dirname .. '/public/', {
    -- should the `file` contents be cached?
    --is_cacheable = function(file) return file.size <= 65536 end,
    is_cacheable = function(file) return true end,
  }),

  -- handle session
  Server.use('session')({
    secret = 'change-me-in-production',
    -- 15 minute timeout
    ttl = 15 * 60 * 1000,
    -- called to get current user capabilities
    authorize = authorize,
  }),

  -- parse request body
  Server.use('body')(),

  function (req, res, nxt)
    p('BODY', req.method, req.url, req.body)
    nxt()
  end,

  -- process custom routes
  Server.use('route')({
    { 'GET /foo', function(self, nxt)
      self:send(200, 'FOOO', {})
    end },
    -- serve chrome page
    { 'GET /$', function(self, nxt)
      self:render(__dirname .. '/index.html', self.req.context)
    end },
  }),

  -- handle authentication
  Server.use('auth')('/rpc/auth', {
    -- called to get current user capabilities
    authenticate = authenticate,
  }),

  function (req, res, nxt)
    --p('CTX', req.body)
    nxt()
  end,

  -- RPC & REST
  --Server.use('rest')('/rpc/'),

  -- GET
  function (req, res, nxt)
--d(req)
    local data = req.session and req.session.uid or 'Мир'
    local s = ('Привет, ' .. data) --:rep(100)
    res:write_head(200, {
      ['Content-Type'] = 'text/plain',
      ['Content-Length'] = s:len()
    })
    res:finish(s)
  end,

}end

Server.run(layers(), 65401)
print('Server listening at http://localhost:65401/')
--Stack.create_server(stack(), 65402)
--Stack.create_server(stack(), 65403)
--Stack.create_server(stack(), 65404)
