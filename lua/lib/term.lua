local function is_term(buffer)
  if not buffer then
    buffer = vim.api.nvim_get_current_buf()
  end
  return vim.bo[buffer].buftype == 'terminal'
end

---@class LibTerm
local M = {
  is_term = is_term,

  is_toggle_term = function(buffer)
    if not buffer then
      buffer = vim.api.nvim_get_current_buf()
    end
    return is_term(buffer) and buffer == state.toggle_term_bufnr
  end,

  is_claude = function(buffer)
    if not buffer then
      buffer = vim.api.nvim_get_current_buf()
    end
    return is_term(buffer) and buffer == state.claude_bufnr
  end,
  is_opencode = function(buffer)
    if not buffer then
      buffer = vim.api.nvim_get_current_buf()
    end
    return is_term(buffer) and buffer == state.opencode_bufnr
  end,

  -- Returns true if buffer is terminal, and has no running command
  -- https://github.com/neovim/neovim/issues/31313
  -- https://github.com/ilan-schemoul/nvim-config/commit/4e27ebabe9d4e819007c770800bac4d5903b8a8d
  terminal_is_available = function(buffer)
    if not buffer then
      buffer = vim.api.nvim_get_current_buf()
    end

    if not vim.api.nvim_buf_is_valid(buffer) then
      return true
    end
    if not is_term(buffer) then
      Snacks.notify.warn('Buffer is not terminal')
      return true
    end
    local channel = vim.bo[buffer].channel
    local child_process = vim.api.nvim_get_proc_children(vim.fn.jobpid(channel))
    return vim.tbl_count(child_process) == 0
  end,

  startinsert = function()
    if not state.insert_when_entering_terminal then
      return
    end
    local win = vim.api.nvim_get_current_win()
    local is_floating = vim.api.nvim_win_get_config(win).relative ~= ''
    if is_floating then
      return
    end
    vim.cmd('startinsert')
  end,
}

return M
