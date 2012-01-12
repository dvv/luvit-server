local UV = require('uv')
local format
do
  local _table_0 = require('string')
  format = _table_0.format
end
local get_type
do
  local _table_0 = require('mime')
  get_type = _table_0.get_type
end
local stat, create_read_stream
do
  local _table_0 = require('fs')
  stat = _table_0.stat
  create_read_stream = _table_0.create_read_stream
end
local date
do
  local _table_0 = require('os')
  date = _table_0.date
end
local resolve
do
  local _table_0 = require('path')
  resolve = _table_0.resolve
end
local CHUNK_SIZE = 4096
local noop
noop = function() end
local stream_file
stream_file = function(path, offset, size, progress, callback)
  UV.fs_open(path, 'r', '0666', function(err, fd)
    if err then
      return callback(err)
    end
    local readchunk
    readchunk = function()
      local chunk_size = size < CHUNK_SIZE and size or CHUNK_SIZE
      return UV.fs_read(fd, offset, chunk_size, function(err, chunk)
        if err or #chunk == 0 then
          callback(err)
          return UV.fs_close(fd, noop)
        else
          chunk_size = #chunk
          offset = offset + chunk_size
          size = size - chunk_size
          if progress then
            return progress(chunk, readchunk)
          else
            return readchunk()
          end
        end
      end)
    end
    return readchunk()
  end)
  return 
end
return function(mount, options)
  if options == nil then
    options = { }
  end
  local parse_range
  parse_range = function(range, size)
    local partial, start, stop = false
    if range then
      start, stop = range:match('bytes=(%d*)-?(%d*)')
      partial = true
    end
    start = tonumber(start) or 0
    stop = tonumber(stop) or size - 1
    return start, stop, partial
  end
  local cache = { }
  local invalidate_cache_entry
  invalidate_cache_entry = function(status, event, path)
    if cache[path] then
      cache[path].watch:close()
      cache[path] = nil
    end
    return 
  end
  local serve
  serve = function(self, file, range, cache_it)
    local headers = extend({ }, file.headers)
    local size = file.size
    local start = 0
    local stop = size - 1
    if range then
      start, stop = parse_range(range, size)
      if stop >= size then
        stop = size - 1
      end
      if stop < start then
        return self:serve_invalid_range(file.size)
      end
      headers['Content-Length'] = stop - start + 1
      headers['Content-Range'] = format('bytes=%d-%d/%d', start, stop, size)
      self:write_head(206, headers)
    else
      self:write_head(200, headers)
    end
    if file.data then
      return self:finish(range and file.data.sub(start + 1, stop - start + 1) or file.data)
    else
      if range then
        cache_it = false
      end
      local index, parts = 1, { }
      local progress
      progress = function(chunk, cb)
        if cache_it then
          parts[index] = chunk
          index = index + 1
        end
        return self:write(chunk, cb)
      end
      local eof
      eof = function(err)
        self:finish()
        if cache_it then
          file.data = join(parts, '')
        end
      end
      return stream_file(file.name, start, stop - start + 1, progress, eof)
    end
  end
  local mount_point_len = #mount + 1
  local max_age = options.max_age or 0
  return function(req, res, continue)
    if req.method ~= 'GET' or req.url:find(mount) ~= 1 then
      return continue()
    end
    local filename = resolve(options.directory, req.uri.pathname:sub(mount_point_len))
    local file = cache[filename]
    if file and file.headers['Last-Modified'] == req.headers['if-modified-since'] then
      return res:serve_not_modified(file.headers)
    end
    if file then
      return serve(res, file, req.headers.range, false)
    else
      return stat(filename, function(err, stat)
        if err then
          res:serve_not_found()
          return 
        end
        file = {
          name = filename,
          size = stat.size,
          mtime = stat.mtime,
          headers = {
            ['Content-Type'] = get_type(filename),
            ['Content-Length'] = stat.size,
            ['Cache-Control'] = 'public, max-age=' .. (max_age / 1000),
            ['Last-Modified'] = date('%c', stat.mtime),
            ['Etag'] = stat.size .. '-' .. stat.mtime
          }
        }
        cache[filename] = file
        file.watch = UV.new_fs_watcher(filename)
        file.watch:set_handler('change', invalidate_cache_entry)
        local cache_it = options.is_cacheable and options.is_cacheable(file)
        return serve(res, file, req.headers.range, cache_it)
      end)
    end
  end
end
