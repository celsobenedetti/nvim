return {
  {
    'rmagatti/auto-session',
    lazy = false,
    ---enables autocomplete for opts
    ---@module "auto-session"
    ---@type AutoSession.Config
    opts = {
      enabled = true, -- Enables/disables auto creating, saving and restoring
      auto_save = true, -- Enables/disables auto saving session on exit
      auto_restore = false, -- Enables/disables auto restoring session on start
      auto_create = true, -- Enables/disables auto creating new session files. Can be a function that returns true if a new session file should be allowed
      auto_restore_last_session = false, -- On startup, loads the last saved session if session for cwd does not exist
      cwd_change_handling = false, -- Automatically save/restore sessions when changing directories
      single_session_mode = false, -- Enable single session mode to keep all work in one session regardless of cwd changes. When enabled, prevents creation of separate sessions for different directories and maintains one unified session. Does not work with cwd_change_handling
    },
  },
}
