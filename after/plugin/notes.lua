local lib = {
  notes = require('lib.notes'),
  fzf = require('lib.fzf'),
}

vim.keymap.set('n', vim.g.keys['<C-S-N>'], function()
  lib.notes.focus_or_create_notes_tab(function()
    lib.fzf.grep({
      cmd = {
        'rg',
        '--no-heading',
        '--line-number',
        '-g',
        '!.archives',
        -- '!' .. vim.g.env.notes.ASSETS_DIR .. '/*',
        '-v',
        string.format('"%s"', vim.g.env.notes.GREP_IGNORE), -- quotes are indeed needed here for complex regex
        vim.g.env.notes.NOTES,
      },
      cwd = vim.g.env.notes.NOTES,
    })
  end)
end, { desc = 'search all notes' })
