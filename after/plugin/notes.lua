vim.keymap.set('n', config.keys['<C-S-N>'], function()
  lib.notes.focus_or_create_notes_tab(function()
    lib.fzf.grep({
      cmd = {
        'rg',
        '--no-heading',
        '--line-number',
        '-g',
        '!.archives',
        -- '!' .. config.env.notes.ASSETS_DIR .. '/*',
        '-v',
        string.format('"%s"', config.env.GREP_IGNORE), -- quotes are indeed needed here for complex regex
        config.dirs.notes,
      },
      cwd = config.dirs.notes,
    })
  end)
end, { desc = 'search all notes' })

vim.api.nvim_create_autocmd('VimEnter', {
  desc = 'notes: VimEnter setup callback for notes dir',
  callback = function()
    if lib.cwd.matches({ 'notes' }) then
      local initial_buf = vim.api.nvim_get_current_buf()
      lib.notes.focus_or_create_notes_tab(function()
        vim.cmd.tabclose(1)
        vim.api.nvim_set_current_buf(initial_buf)
      end)
    end
  end,
})
