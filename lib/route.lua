return function(routes)
  if routes == nil then
    routes = { }
  end
  return function(req, res, continue)
    local str = req.method .. ' ' .. req.uri.pathname
    local _list_0 = routes
    for _index_0 = 1, #_list_0 do
      local pair = _list_0[_index_0]
      local params = {
        str:match(pair[1])
      }
      if params[1] then
        pair[2](res, continue, unpack(params))
        return 
      end
    end
    continue()
    return 
  end
end
