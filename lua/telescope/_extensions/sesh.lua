local telescope = require("telescope")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local previewers = require("telescope.previewers")
local action_state = require("telescope.actions.state")
local themes = require("telescope.themes")
local sesh = require("sesh")
local _let_1_ = sesh
local delete = _let_1_["delete"]
local load = _let_1_["load"]
local sessions_info = sesh.read_sessions_info()
local _let_2_ = require("telescope.config")
local conf = _let_2_["values"]
local function sesh_telescope(opts)
  local opts0 = vim.tbl_extend("keep", (opts or {}), themes.get_dropdown())
  local function attach_mappings(prompt_buf_23, map)
    local function _3_()
      local _local_4_ = action_state.get_selected_entry()
      local selection = _local_4_[1]
      actions.close(prompt_buf_23)
      return delete(selection)
    end
    map("n", "d", _3_)
    local function _5_()
      local _local_6_ = action_state.get_selected_entry()
      local selection = _local_6_[1]
      actions.close(prompt_buf_23)
      return delete(selection)
    end
    map("i", "<A-x>", _5_)
    local function _7_()
      local _local_8_ = action_state.get_selected_entry()
      local selection = _local_8_[1]
      actions.close(prompt_buf_23)
      return load(selection)
    end
    return (actions.select_default):replace(_7_)
  end
  local function define_preview(self, entry, _status)
    local _local_9_ = sessions_info[entry.value]
    local buffers = _local_9_["buffers"]
    local curdir = _local_9_["curdir"]
    local focused = _local_9_["focused"]
    local function indent(x)
      return (string.rep(" ", vim.o.shiftwidth) .. (x or ""))
    end
    local display = {"Working Directory:", indent(curdir), "", "Focused Buffer:", indent(focused), "", "Open Buffers: "}
    for _, v in ipairs(buffers) do
      table.insert(display, indent(v))
    end
    vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "yaml")
    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, display)
    self.state.last_set_bufnr = self.state.bufnr
    return nil
  end
  local picker = pickers.new(opts0, {prompt_title = "Sessions", finder = finders.new_table(sesh.list()), sorter = conf.generic_sorter(opts0), previewer = previewers.new_buffer_previewer({title = "Session Info", define_preview = define_preview}), attach_mappings = attach_mappings})
  return picker:find()
end
return telescope.register_extension({exports = {sesh = sesh_telescope}})
