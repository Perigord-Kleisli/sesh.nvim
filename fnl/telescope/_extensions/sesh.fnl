(let [telescope (require :telescope)
      pickers (require :telescope.pickers)
      finders (require :telescope.finders)
      actions (require :telescope.actions)
      previewers (require :telescope.previewers)
      action-state (require :telescope.actions.state)
      themes (require :telescope.themes)
      sesh (require :sesh)
      {: delete : load : read_opts : update_sessions_info} sesh
      {:values conf} (require :telescope.config)]
  (fn sesh-telescope [opts]
    (update_sessions_info)
    (local opts (vim.tbl_extend :keep (or opts []) (themes.get_dropdown)))
    (local sessions-info
           (vim.fn.json_decode (vim.fn.readfile (. (read_opts) :sessions_info))))

    (fn attach_mappings [prompt-buf# map]
      (map :n :x (fn []
                   (local [selection] (action-state.get_selected_entry))
                   (actions.close prompt-buf#)
                   (delete selection)))
      (map :i :<A-x> (fn []
                       (local [selection] (action-state.get_selected_entry))
                       (actions.close prompt-buf#)
                       (delete selection)))
      (actions.select_default:replace (fn []
                                        (local [selection]
                                               (action-state.get_selected_entry))
                                        (actions.close prompt-buf#)
                                        (load selection))))

    (fn define_preview [self entry _status]
      (local session (. sessions-info entry.value))
      (lambda indent [x]
        (.. (string.rep " " vim.o.shiftwidth) x))
      (var display [])
      (match session.curdir
        x (table.insert display ["Working Directory:" (indent x) ""]))
      (match session.focused
        x (table.insert display ["Focused Buffer:" (indent x) ""]))
      (match session.buffers
        (where x (<= 1 (length x)))
        (table.insert display ["Open Buffers:" (vim.tbl_map indent x)]))
      (vim.api.nvim_buf_set_option self.state.bufnr :filetype :yaml)
      (vim.api.nvim_buf_set_lines self.state.bufnr 0 -1 false
                                  (vim.tbl_flatten display))
      (set self.state.last_set_bufnr self.state.bufnr))

    (local picker (pickers.new opts
                               {:prompt_title :Sessions
                                :finder (finders.new_table (sesh.list))
                                :sorter (conf.generic_sorter opts)
                                :previewer (previewers.new_buffer_previewer {:title "Session Info"
                                                                             : define_preview})
                                : attach_mappings}))
    (picker:find))

  (telescope.register_extension {:exports {:sesh sesh-telescope}}))
