-- TODO: probably remove compile.nvim, as cool as it is
if true then
  return {}
end
-- plugin which emulates the features of Emacs' Compilation Mode.
-- It allows you to run commands which are output into a special buffer,
-- and then rerun that command over and over again as much as you need.
-- https://www.gnu.org/software/emacs/manual/html_node/emacs/Compilation-Mode.html
return {
  'ej-shafran/compile-mode.nvim',
  version = '^5.0.0',
  event = 'CmdlineEnter',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { 'm00qek/baleia.nvim', tag = 'v1.3.0' }, -- if you want to enable coloring of ANSI escape codes in compilation output
  },
  config = function()
    vim.g.compile_mode = {
      input_word_completion = true, -- blink.nvim tab completion in command mode:
      baleia_setup = true, --  ANSI escape code support, add:
      bang_expansion = true, --  replace special characters (e.g. `%`) in the command (and behave more like `:!`), add:
    }

    -- replace "!" with "Compile" in command mode
    -- :help abbreviation
    vim.cmd('cnoreabbrev ! Compile')
  end,

  keys = {
    {
      '♦', -- "C--;"
      function()
        local bufnr = vim.api.nvim_get_current_buf()
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if bufname:find('oil://') then
          vim.g.compilation_directory = bufname:gsub('oil://', '')
        end
        vim.api.nvim_feedkeys(':Compile ', 'i', false)
      end,
      { desc = 'cmd: compile command runner' },
    },
  },
}
