return function(url)
  if url == nil then
    url = '/ws/'
  end
  return function(req, res, continue)
    if req.url:find(url) == 1 then
      return res:fail('Not Yet Implemented')
    else
      return continue()
    end
  end
end
