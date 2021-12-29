local api = vim.api
local luv = vim.loop
local distant_fn = require('distant.fn')

local M = {}

local function to_tree_filetype(filetype)
  if filetype == 'dir' then
    return 'directory'
  elseif filetype == 'symlink' then
    return 'link'
  else
    return filetype
  end
end

-- return: filename, filetype (directory, file, link)
M.scandir = function(cwd, is_remote)
  if is_remote then
    local err, res = distant_fn.read_dir({
      path = cwd, depth = 1
    })
    -- To keep the index
    local function list_iter(t)
      local i = 0
      local n = table.getn(t)
      return function()
        i = i + 1
        if i <= n then return t[i] end
      end
    end
    if not err then
      return list_iter(res['entries'])
    else
      return
    end
  else
    return luv.fs_scandir(cwd)
  end
end

M.scandir_next = function(handler, is_remote)
  if is_remote then
    local item = handler()
    if item ~= nil then
      return item.path, to_tree_filetype(item.file_type)
    else
      return nil, nil
    end
  else
    return luv.fs_scandir_next(handler)
  end
end

M.access = function(absolute_path, acc, is_remote)
  if is_remote then
    if acc == 'R' then
      local err, mdata = distant_fn.metadata({path = absolute_path})
      if not err then
        return mdata['file_type'] == 'dir'
      else
        return
      end
    elseif acc == 'X' then
      return false
    else
      return false
    end
  else
    return luv.fs_access(absolute_path, acc)
  end
end

M.stat = function(absolute_path, is_remote)
  if is_remote then
    local err, mdata = distant_fn.metadata({path = absolute_path})
    return mdata
  else
    return luv.fs_stat(absolute_path)
  end
end

M.realpath = function(absolute_path, is_remote)
  if is_remote then
    local err, mdata = distant_fn.metadata({
      path = absolute_path, canonicalize = true
    })
    return mdata['canonicalized_path']
  else
    return luv.fs_realpath(absolute_path)
  end
end


M.get_last_modified_time = function(stat, is_remote)
  if is_remote then
    return stat.modified
  else
    return stat.mtime.sec
  end
end

M.get_type = function(stat, is_remote)
  if is_remote then
    return to_tree_filetype(stat.file_type)
  else
    return stat.type
  end
end

return M
