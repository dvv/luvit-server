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
    session = credentials or {
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
      name = session.name,
      photo = session.photo,
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


local options = {

  -- serve static files
  static = {
    dir = __dirname .. '/public/',
    is_cacheable = function(file) return file.size <= 65536 end,
  },

  -- handle session
  session = {
    secret = 'change-me-in-production',
    -- 15 minute timeout
    ttl = 15 * 60 * 1000,
    -- called to get current user capabilities
    authorize = authorize,
    -- called to authenticate credentials
    authenticate = authenticate,
  },

  -- process custom routes
  routes = {
    { 'GET /foo', function(self, nxt)
      self:send(200, 'FOOO', {})
    end },
    -- serve chrome page
    { 'GET /$', function(self, nxt)
      local context = self.req.context
      self:render(__dirname .. '/index.html', context)
    end },
  },

}

Server.standard(65401, '0.0.0.0', options)
print('Server listening at http://localhost:65401/')
