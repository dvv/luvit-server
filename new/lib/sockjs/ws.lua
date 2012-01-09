--
-- WebSocket server
--

return function (options)

  -- defaults
  if options == nil then options = { } end

  -- handler
  return function(req, res, nxt)
    res:fail('Not Yet Implemented')
  end

end
