local opts = {autosave = {autocmds = {}, enable = false}, autoswitch = {enable = true, exclude_ft = {}}, sessions_info = (vim.fn.stdpath("data") .. "/sessions-info.json"), session_path = (vim.fn.stdpath("data") .. "/sessions"), autoload = false}
local sessions_info = vim.fn.json_decode(vim.fn.readfile(opts.sessions_info))
local function read_sessions_info()
  return sessions_info
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
    local focused = ""
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
    vim.notify(("Session path: '" .. opts.session_path .. "' not found"), "error")
  else
  end
  update_sessions_info()
  if opts.autosave.enable then
    local function _11_()
      if cur_session then
        vim.cmd.mksession({args = {cur_session}, bang = true})
        return update_sessions_info()
      else
        return nil
      end
    end
    vim.api.nvim_create_autocmd(vim.tbl_flatten({"VimLeave", opts.autosave.autocmds}), {group = vim.api.nvim_create_augroup("SessionAutosave", {}), desc = "Save session on exit and through specified autocmds in setup", callback = _11_})
  else
  end
  if (opts.autoload.enable and (0 == vim.fn.argc())) then
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
    local _16_ = to_load
    if ((_G.type(_16_) == "table") and (nil ~= (_16_)[1])) then
      local s = (_16_)[1]
      cur_session = s
      return vim.cmd.source(s)
    else
      return nil
    end
  else
    return nil
  end
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
  local function _21_(_241)
    local session = (opts.session_path .. _241)
    if (nil == next(vim.fs.find(_241, {path = opts.session_path}))) then
      vim.cmd.mksession({args = {session}})
      vim.notify(("Made session: " .. session))
      cur_session = session
      return nil
    else
      return vim.notify(("Session '" .. _241 .. "' already exists"), "warn")
    end
  end
  return vim.ui.input({prompt = "Session Name:", default = vim.fs.basename(vim.fn.getcwd())}, _21_)
end
local function save()
  if (nil == cur_session) then
    create()
  else
    local function _23_(_241)
      local _24_ = _241
      if (_24_ == "Yes") then
        vim.cmd.mksession({args = {cur_session}, bang = true})
        return vim.notify(("Saved session: " .. cur_session))
      else
        return nil
      end
    end
    vim.ui.select({"Yes", "No"}, {prompt = ("Overwrite session '" .. vim.fs.basename(cur_session) .. "'?")}, _23_)
  end
  return update_sessions_info()
end
local function switch(selection)
  _G.assert((nil ~= selection), "Missing argument selection on fnl/sesh/init.fnl:95")
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
    local function _31_(x)
      local go_on = true
      do
        local _32_ = x
        if (_32_ == "Yes (save buffers and switch)") then
          vim.cmd("wall!")
        elseif (_32_ == "Yes (continue without saving)") then
        elseif true then
          local _ = _32_
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
    return vim.ui.select({"Yes (save buffers and switch)", "Yes (continue without saving)", "No"}, {prompt = "Modified buffers found, continue?"}, _31_)
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
    local function _36_(_241)
      if _241 then
        return load(_241)
      else
        return nil
      end
    end
    return vim.ui.select(list(), {prompt = "Load session: "}, _36_)
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
    local function _40_(_241)
      if _241 then
        return delete(_241)
      else
        return nil
      end
    end
    return vim.ui.select(list(), {prompt = "Delete session: "}, _40_)
  elseif (nil == next(vim.fs.find(selection, opts.session_path))) then
    return error(("Session '" .. selection .. "' does not exist"))
  else
    local session = (opts.session_path .. selection)
    local function _42_(_241)
      local _43_ = _241
      if (_43_ == "No") then
        return nil
      elseif true then
        local _ = _43_
        os.remove(session)
        vim.notify(("Deleted session: " .. session))
        cur_session = nil
        return nil
      else
        return nil
      end
    end
    return vim.ui.select({"Yes (this cannot be undone)", "No"}, {prompt = ("Delete session '" .. session .. "'?")}, _42_)
  end
end
return {save = save, setup = setup, load = load, list = list, delete = delete, opened_session = opened_session, switch = switch, read_opts = read_opts, read_sessions_info = read_sessions_info, update_sessions_info = update_sessions_info}
