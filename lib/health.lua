return function(url)
  if url == nil then
    url = '/haproxy?monitor'
  end
  return function(req, res, continue)
    if req.url == url then
      res:send(200, nil, { })
    else
      continue()
    end
    return 
  end
end
