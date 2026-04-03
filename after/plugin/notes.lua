local lib = {
  notes = require('lib.notes'),
  grep = require('lib.grep'),
}

vim.keymap.set('n', vim.g.key.ghostty['<C-S-N>'], function()
  lib.notes.focus_or_create_notes_tab(function()
    lib.grep.pick({
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
