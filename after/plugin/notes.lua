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
        string.format('"%s"', config.env.notes.GREP_IGNORE), -- quotes are indeed needed here for complex regex
        config.env.notes.NOTES,
      },
      cwd = config.env.notes.NOTES,
    })
  end)
end, { desc = 'search all notes' })
