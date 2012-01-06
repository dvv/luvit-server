--
-- WebSocket server
--

return (url = '/ws/') ->

  (req, res, continue) ->

    if req.url\find(url) == 1
      res\fail 'Not Yet Implemented'

    else
      continue()
