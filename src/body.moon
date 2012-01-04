--
-- Parse request body into `req.body` table
--

return (options = {}) ->

  import decode from require 'json'

  (req, res, continue) ->

    -- collect body
    body = {}
    length = 0
    req\on 'data', (chunk, len) ->
      length = length + 1
      body[length] = chunk

    -- parse body
    req\on 'end', () ->
      body = join body
      -- first octet is [ or { ?
      char = body\sub 1, 1
      if char == '[' or char == '{'
        -- body seems JSON, try to decode
        status, result = pcall () -> decode body
        -- decoded ok?
        if status
          -- set body to decoded table
          body = result
      -- either urlencoded or plain string
      else
        -- parse urlencoded
        vars = body\parse_query()
        -- parsed table is not empty?
        if #keys(vars) > 0
          -- set body to parsed table
          body = vars
      --
      req.body = body

      -- go on
      continue()
