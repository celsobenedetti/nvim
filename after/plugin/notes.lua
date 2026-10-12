vim.keymap.set('n', config.keys['<C-S-N>'], function()
  lib.notes.focus_or_create_notes_tab(function()
    lib.fzf.grep({
      cmd = {
        'rg',
        '--no-heading',
        '--line-number',
        '-g',
        '!.archives',
        '-v',
        string.format('"%s"', config.env.GREP_IGNORE), -- quotes are indeed needed here for complex regex
        config.dirs.notes,
      },
      cwd = config.dirs.notes,
    })
  end)
end, { desc = 'search all notes' })
