(var opts {:autosave {:enable false :autocmds []}
           :autoload false
           :autoswitch {:enable true :exclude_ft []}
           :sessions_info (.. (vim.fn.stdpath :data) :/sessions-info.json)
           :session_path (.. (vim.fn.stdpath :data) :/sessions)
           :exclude_name []
           :post_load_hook (fn [])})

(var sessions-info nil)

(fn read_sessions_info []
  (vim.fn.json_decode (vim.fn.readfile opts.sessions_info)))

(var cur-session nil)
(fn opened_session []
  cur-session)

(fn read_opts []
  opts)

(fn remove-excluded-fts []
  (when (not (vim.tbl_isempty opts.exclude_name))
    (local lines (icollect [line (io.lines cur-session)]
                   (do
                     (var found false)
                     (each [_ v (ipairs opts.exclude_name)]
                       (when (string.find line v)
                         (set found true)))
                     (if found nil line))))
    (with-open [file (io.open cur-session :w+)]
      (each [_ line (ipairs lines)]
        (file:write (.. line "\n"))))))

(fn update_sessions_info []
  (var session-info* [])
  (each [k _ (vim.fs.dir opts.session_path)]
    (var curdir nil)
    (var buffers [])
    (var focused nil)
    (each [line (io.lines (.. opts.session_path k))]
      (match (string.match line "^cd%s+(.*)$")
        x (set curdir x))
      (match (string.match line "^edit%s+(.*)$")
        x (set focused x))
      (match (string.match line "^badd%s+%+%d+%s+(.*)$")
        x (table.insert buffers x)))
    (tset session-info* k {: curdir : buffers : focused}))
  (set sessions-info session-info*)
  (with-open [file (io.open opts.sessions_info :w+)]
    (file:write (vim.fn.json_encode session-info*))))

(fn setup [user-opts]
  (set opts (vim.tbl_deep_extend :force opts (or user-opts [])))
  (when (= nil (string.find (. opts :session_path) "/$"))
    (tset opts :session_path (.. (. opts :session_path) "/")))
  (when (= "" (vim.fn.finddir (. opts :session_path)))
    (vim.ui.select [:Yes :No]
                   {:prompt (.. "Error: Session path '" opts.session_path
                                "' not found. Create?")}
                   #(match $1
                      :Yes (do
                             (vim.fn.mkdir opts.session_path :p)
                             (update_sessions_info))
                      :No (error (.. "Session path: '" (. opts :session_path)
                                     "' not found")))))
  (when opts.autosave.enable
    (vim.api.nvim_create_autocmd (vim.tbl_flatten [:VimLeave
                                                   opts.autosave.autocmds])
                                 {:group (vim.api.nvim_create_augroup :SessionAutosave
                                                                      [])
                                  :desc "Save session on exit and through specified autocmds in setup"
                                  :callback #(when cur-session
                                               (vim.cmd.mksession {:args [cur-session]
                                                                   :bang true})
                                               (remove-excluded-fts)
                                               (update_sessions_info))}))
  (update_sessions_info)
  (when (and opts.autoload.enable (not= nil sessions-info) (= 0 (vim.fn.argc)))
    (local to-load (icollect [k v (pairs sessions-info)]
                     (if (= (vim.fn.getcwd) (vim.fn.expand v.curdir))
                         (.. opts.session_path k)
                         nil)))
    (match to-load
      [s] (do
            (set cur-session s)
            (vim.cmd.source s)
            (opts.post_load_hook))))
  (set sessions-info (vim.fn.json_decode (vim.fn.readfile opts.sessions_info))))

(fn list []
  (icollect [k _ (vim.fs.dir opts.session_path)]
    k))

(fn create []
  (when (= "" (vim.fn.finddir (. opts :session_path)))
    (error (.. "Session path: '" (. opts :session_path) "' not found")))
  (vim.ui.input {:prompt "Session Name:"
                 :default (vim.fs.basename (vim.fn.getcwd))}
                #(when (not= nil $1)
                   (let [session (.. opts.session_path $1)]
                     (if (= nil
                            (next (vim.fs.find $1 {:path opts.session_path})))
                         (do
                           (vim.cmd.mksession {:args [session]})
                           (vim.notify (.. "Made session: " session))
                           (remove-excluded-fts)
                           (update_sessions_info)
                           (set cur-session session))
                         (vim.ui.select [:Yes :No]
                                        {:prompt (.. "Session '" $1
                                                     "' already exists but isnt loaded, overwrite?")}
                                        #(match $1
                                           :Yes (do
                                                  (vim.cmd.mksession {:args [session]
                                                                      :bang true})
                                                  (vim.notify (.. "Saved session: "
                                                                  session))
                                                  (set cur-session session)
                                                  (remove-excluded-fts)
                                                  (update_sessions_info)))))))))

(fn save []
  (if (= nil cur-session)
      (create)
      (vim.ui.select [:Yes :No]
                     {:prompt (.. "Overwrite session '"
                                  (vim.fs.basename cur-session) "'?")}
                     #(match $1
                        :Yes (do
                               (vim.cmd.mksession {:args [cur-session]
                                                   :bang true})
                               (vim.notify (.. "Saved session: " cur-session))
                               (remove-excluded-fts)
                               (update_sessions_info))))))

(lambda switch [selection]
  (when (and opts.autosave (not= nil cur-session))
    (vim.cmd.mksession {:args [cur-session] :bang true})
    (remove-excluded-fts)
    (update_sessions_info))
  (local buffers (icollect [_ buf (ipairs (vim.api.nvim_list_bufs))]
                   (if (and (vim.api.nvim_buf_is_valid buf)
                            (vim.api.nvim_buf_get_option buf :buflisted)
                            (vim.api.nvim_buf_get_option buf :modifiable)
                            (not (vim.tbl_contains opts.autoswitch.exclude_ft
                                                   (vim.api.nvim_buf_get_option buf
                                                                                :filetype))))
                       buf)))
  (var has-modified false)
  (each [_ v (ipairs buffers)]
    (when (vim.api.nvim_buf_get_option v :modified)
      (set has-modified true)))
  (if has-modified
      (vim.ui.select ["Yes (save buffers and switch)"
                      "Yes (continue without saving)"
                      :No]
                     {:prompt "Modified buffers found, continue?"}
                     (fn [x]
                       (var go-on true)
                       (match x
                         "Yes (save buffers and switch)" (vim.cmd :wall!)
                         "Yes (continue without saving)" nil
                         _ (set go-on false))
                       (when go-on
                         (each [_ v (ipairs buffers)]
                           (vim.api.nvim_buf_delete v {:force true}))
                         (vim.cmd.source (.. opts.session_path selection))
                         (set cur-session (.. opts.session_path selection)))))
      (do
        (each [_ v (ipairs buffers)]
          (vim.api.nvim_buf_delete v {:force true}))
        (vim.cmd.source (.. opts.session_path selection))
        (set cur-session (.. opts.session_path selection)))))

(fn load [selection]
  (if (= nil selection)
      (vim.ui.select (list) {:prompt "Load session: "} #(if $1 (load $1) nil))
      (= (.. opts.session_path selection) cur-session)
      (vim.notify "Already in the loaded session" :warn)
      (let [session (.. opts.session_path selection)]
        (if opts.autoswitch
            (switch selection)
            (vim.cmd.source session))
        (set cur-session session)
        (opts.post_load_hook))))

(fn delete [selection]
  (if (= nil selection)
      (vim.ui.select (list) {:prompt "Delete session: "}
                     #(if $1 (delete $1) nil))
      (= nil (next (vim.fs.find selection {:path opts.session_path})))
      (error (.. "Session '" (selection) "' does not exist"))
      (let [session (.. opts.session_path selection)]
        (vim.ui.select ["Yes (this cannot be undone)" :No]
                       {:prompt (.. "Delete session '" session "'?")}
                       #(match $1
                          :No nil
                          _ (do
                              (when (= session cur-session)
                                (set cur-session nil))
                              (os.remove session)
                              (update_sessions_info)
                              (vim.notify (.. "Deleted session: " session))))))))

{: save
 : setup
 : load
 : list
 : delete
 : opened_session
 : read_sessions_info
 : switch
 : read_opts
 : update_sessions_info}
