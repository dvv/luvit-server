--
-- Parse request body into `req.body` table
--

return (options = {}) ->

  import parse_request from require 'curl'

  (req, res, continue) ->

    parse_request req, (err, data) ->
      req.body = data
      continue()
