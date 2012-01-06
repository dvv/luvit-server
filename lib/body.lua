return function(options)
  if options == nil then
    options = { }
  end
  local parse_request
  do
    local _table_0 = require('curl')
    parse_request = _table_0.parse_request
  end
  return function(req, res, continue)
    return parse_request(req, function(err, data)
      req.body = data
      return continue()
    end)
  end
end
