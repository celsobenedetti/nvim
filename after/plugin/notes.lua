local lib = require('lib')
local state = require('state')

vim.keymap.set('n', state.keys['<C-S-N>'], function()
  lib.notes.focus_or_create_notes_tab(function()
    lib.fzf.grep({
      cmd = {
        'rg',
        '--no-heading',
        '--line-number',
        '-g',
        '!.archives',
        -- '!' .. state.env.notes.ASSETS_DIR .. '/*',
        '-v',
        string.format('"%s"', state.env.notes.GREP_IGNORE), -- quotes are indeed needed here for complex regex
        state.env.notes.NOTES,
      },
      cwd = state.env.notes.NOTES,
    })
  end)
end, { desc = 'search all notes' })
