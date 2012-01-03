--
-- Simple regexp based router
--

--
-- `routes` are table of tables describing handlers
-- { 1={ <regexp>, <handler> }, 2={ <regexp>, <handler>, ... } }
-- <regexp> is textual concatenation of request method, space and matching url pattern
-- such complicated structure is used to workaround Lua having no ordered dictionaries
--

return (routes = {}) ->

  return (req, res, continue) ->

    -- glue method and path for matching
    str = req.method .. ' ' .. req.uri.pathname
    for pair in *routes
      params = { str\match pair[1] }
      if params[1]
        pair[2] res, continue, unpack params
        return

    -- no route matched. continue
    continue()
    return
