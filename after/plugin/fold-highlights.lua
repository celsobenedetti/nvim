-- Consolidated fold backgrounds: every closed fold line gets a single
-- background, whatever syntax, treesitter or plugin extmarks put there.
-- See lua/lib/fold_hl.lua for the precedence measurements behind it.
--
-- Opt a window out of the fold surface color with 'winhighlight' (e.g.
-- `Folded:DiffFolded`, see after/ftplugin/git.lua); opt a buffer out entirely
-- with `vim.b.fold_hl_disable = true`.
require('lib.fold_hl').setup()
