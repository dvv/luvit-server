return function(options)
  if options == nil then
    options = { }
  end
  return function(req, res, continue)
    req.body = { }
    continue()
    return 
  end
end
