local opts = {autosave = {autocmds = {}, enable = false}, autoswitch = {enable = true, exclude_ft = {}}, sessions_info = (vim.fn.stdpath("data") .. "/sessions-info.json"), session_path = (vim.fn.stdpath("data") .. "/sessions"), autoload = false}
local sessions_info = nil
local function read_sessions_info()
  return vim.fn.json_decode(vim.fn.readfile(opts.sessions_info))
end
local cur_session = nil
local function opened_session()
  return cur_session
end
local function read_opts()
  return opts
end
local function update_sessions_info()
  local session_info_2a = {}
  for k, _ in vim.fs.dir(opts.session_path) do
    local curdir = nil
    local buffers = {}
    local focused = nil
    for line in io.lines((opts.session_path .. k)) do
      do
        local _1_ = string.match(line, "^cd%s+(.*)$")
        if (nil ~= _1_) then
          local x = _1_
          curdir = x
        else
        end
      end
      do
        local _3_ = string.match(line, "^edit%s+(.*)$")
        if (nil ~= _3_) then
          local x = _3_
          focused = x
        else
        end
      end
      local _5_ = string.match(line, "^badd%s+%+%d+%s+(.*)$")
      if (nil ~= _5_) then
        local x = _5_
        table.insert(buffers, x)
      else
      end
    end
    session_info_2a[k] = {curdir = curdir, buffers = buffers, focused = focused}
  end
  sessions_info = session_info_2a
  local file = io.open(opts.sessions_info, "w+")
  local function close_handlers_10_auto(ok_11_auto, ...)
    file:close()
    if ok_11_auto then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _8_()
    return file:write(vim.fn.json_encode(session_info_2a))
  end
  return close_handlers_10_auto(_G.xpcall(_8_, (package.loaded.fennel or debug).traceback))
end
local function setup(user_opts)
  opts = vim.tbl_deep_extend("force", opts, (user_opts or {}))
  if (nil == string.find(opts.session_path, "/$")) then
    opts["session_path"] = (opts.session_path .. "/")
  else
  end
  if ("" == vim.fn.finddir(opts.session_path)) then
    local function _10_(_241)
      local _11_ = _241
      if (_11_ == "Yes") then
        vim.fn.mkdir(opts.session_path, "p")
        return update_sessions_info()
      elseif (_11_ == "No") then
        return error(("Session path: '" .. opts.session_path .. "' not found"))
      else
        return nil
      end
    end
    vim.ui.select({"Yes", "No"}, {prompt = ("Error: Session path '" .. opts.session_path .. "' not found. Create?")}, _10_)
  else
  end
  if opts.autosave.enable then
    local function _14_()
      if cur_session then
        vim.cmd.mksession({args = {cur_session}, bang = true})
        return update_sessions_info()
      else
        return nil
      end
    end
    vim.api.nvim_create_autocmd(vim.tbl_flatten({"VimLeave", opts.autosave.autocmds}), {group = vim.api.nvim_create_augroup("SessionAutosave", {}), desc = "Save session on exit and through specified autocmds in setup", callback = _14_})
  else
  end
  if (opts.autoload.enable and (nil ~= sessions_info) and (0 == vim.fn.argc())) then
    local to_load
    do
      local tbl_17_auto = {}
      local i_18_auto = #tbl_17_auto
      for k, v in pairs(sessions_info) do
        local val_19_auto
        if (vim.fn.getcwd() == vim.fn.expand(v.curdir)) then
          val_19_auto = (opts.session_path .. k)
        else
          val_19_auto = nil
        end
        if (nil ~= val_19_auto) then
          i_18_auto = (i_18_auto + 1)
          do end (tbl_17_auto)[i_18_auto] = val_19_auto
        else
        end
      end
      to_load = tbl_17_auto
    end
    local _19_ = to_load
    if ((_G.type(_19_) == "table") and (nil ~= (_19_)[1])) then
      local s = (_19_)[1]
      cur_session = s
      vim.cmd.source(s)
    else
    end
  else
  end
  update_sessions_info()
  sessions_info = vim.fn.json_decode(vim.fn.readfile(opts.sessions_info))
  return nil
end
local function list()
  local tbl_17_auto = {}
  local i_18_auto = #tbl_17_auto
  for k, _ in vim.fs.dir(opts.session_path) do
    local val_19_auto = k
    if (nil ~= val_19_auto) then
      i_18_auto = (i_18_auto + 1)
      do end (tbl_17_auto)[i_18_auto] = val_19_auto
    else
    end
  end
  return tbl_17_auto
end
local function create()
  if ("" == vim.fn.finddir(opts.session_path)) then
    error(("Session path: '" .. opts.session_path .. "' not found"))
  else
  end
  local function _24_(_241)
    if (nil ~= _241) then
      local session = (opts.session_path .. _241)
      if (nil == next(vim.fs.find(_241, {path = opts.session_path}))) then
        vim.cmd.mksession({args = {session}})
        vim.notify(("Made session: " .. session))
        update_sessions_info()
        cur_session = session
        return nil
      else
        return vim.notify(("Session '" .. _241 .. "' already exists"), "warn")
      end
    else
      return nil
    end
  end
  return vim.ui.input({prompt = "Session Name:", default = vim.fs.basename(vim.fn.getcwd())}, _24_)
end
local function save()
  if (nil == cur_session) then
    return create()
  else
    local function _27_(_241)
      local _28_ = _241
      if (_28_ == "Yes") then
        vim.cmd.mksession({args = {cur_session}, bang = true})
        vim.notify(("Saved session: " .. cur_session))
        return update_sessions_info()
      else
        return nil
      end
    end
    return vim.ui.select({"Yes", "No"}, {prompt = ("Overwrite session '" .. vim.fs.basename(cur_session) .. "'?")}, _27_)
  end
end
local function switch(selection)
  _G.assert((nil ~= selection), "Missing argument selection on fnl/sesh/init.fnl:107")
  if (opts.autosave and (nil ~= cur_session)) then
    vim.cmd.mksession({args = {cur_session}, bang = true})
    update_sessions_info()
  else
  end
  local buffers
  do
    local tbl_17_auto = {}
    local i_18_auto = #tbl_17_auto
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local val_19_auto
      if (vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_option(buf, "buflisted") and vim.api.nvim_buf_get_option(buf, "modifiable") and not vim.tbl_contains(opts.autoswitch.exclude_ft, vim.api.nvim_buf_get_option(buf, "filetype"))) then
        val_19_auto = buf
      else
        val_19_auto = nil
      end
      if (nil ~= val_19_auto) then
        i_18_auto = (i_18_auto + 1)
        do end (tbl_17_auto)[i_18_auto] = val_19_auto
      else
      end
    end
    buffers = tbl_17_auto
  end
  local has_modified = false
  for _, v in ipairs(buffers) do
    if vim.api.nvim_buf_get_option(v, "modified") then
      has_modified = true
    else
    end
  end
  if has_modified then
    local function _35_(x)
      local go_on = true
      do
        local _36_ = x
        if (_36_ == "Yes (save buffers and switch)") then
          vim.cmd("wall!")
        elseif (_36_ == "Yes (continue without saving)") then
        elseif true then
          local _ = _36_
          go_on = false
        else
        end
      end
      if go_on then
        for _, v in ipairs(buffers) do
          vim.api.nvim_buf_delete(v, {force = true})
        end
        vim.cmd.source((opts.session_path .. selection))
        cur_session = (opts.session_path .. selection)
        return nil
      else
        return nil
      end
    end
    return vim.ui.select({"Yes (save buffers and switch)", "Yes (continue without saving)", "No"}, {prompt = "Modified buffers found, continue?"}, _35_)
  else
    for _, v in ipairs(buffers) do
      vim.api.nvim_buf_delete(v, {force = true})
    end
    vim.cmd.source((opts.session_path .. selection))
    cur_session = (opts.session_path .. selection)
    return nil
  end
end
local function load(selection)
  if (nil == selection) then
    local function _40_(_241)
      if _241 then
        return load(_241)
      else
        return nil
      end
    end
    return vim.ui.select(list(), {prompt = "Load session: "}, _40_)
  elseif ((opts.session_path .. selection) == cur_session) then
    return vim.notify("Already in the loaded session", "warn")
  else
    local session = (opts.session_path .. selection)
    if opts.autoswitch then
      switch(selection)
    else
      vim.cmd.source(session)
    end
    cur_session = session
    return nil
  end
end
local function delete(selection)
  if (nil == selection) then
    local function _44_(_241)
      if _241 then
        return delete(_241)
      else
        return nil
      end
    end
    return vim.ui.select(list(), {prompt = "Delete session: "}, _44_)
  elseif (nil == next(vim.fs.find(selection, {path = opts.session_path}))) then
    return error(("Session '" .. selection() .. "' does not exist"))
  else
    local session = (opts.session_path .. selection)
    local function _46_(_241)
      local _47_ = _241
      if (_47_ == "No") then
        return nil
      elseif true then
        local _ = _47_
        if (session == cur_session) then
          cur_session = nil
        else
        end
        os.remove(session)
        update_sessions_info()
        return vim.notify(("Deleted session: " .. session))
      else
        return nil
      end
    end
    return vim.ui.select({"Yes (this cannot be undone)", "No"}, {prompt = ("Delete session '" .. session .. "'?")}, _46_)
  end
end
return {save = save, setup = setup, load = load, list = list, delete = delete, opened_session = opened_session, read_sessions_info = read_sessions_info, switch = switch, read_opts = read_opts, update_sessions_info = update_sessions_info}
