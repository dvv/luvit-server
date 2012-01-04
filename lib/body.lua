return function(options)
  if options == nil then
    options = { }
  end
  local decode
  do
    local _table_0 = require('json')
    decode = _table_0.decode
  end
  return function(req, res, continue)
    local body = { }
    local length = 0
    req:on('data', function(chunk, len)
      length = length + 1
      body[length] = chunk
    end)
    return req:on('end', function()
      body = join(body)
      local char = body:sub(1, 1)
      if char == '[' or char == '{' then
        local status, result = pcall(function()
          return decode(body)
        end)
        if status then
          body = result
        end
      else
        local vars = body:parse_query()
        if #keys(vars) > 0 then
          body = vars
        end
      end
      req.body = body
      return continue()
    end)
  end
end
