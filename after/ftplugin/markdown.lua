local function fold_frontmatter()
  vim.schedule(function()
    local has_frontmatter = vim.api.nvim_buf_get_lines(0, 0, -1, false)[1]:match('^---')
    if not has_frontmatter then
      return
    end

    vim.opt.foldmethod = 'manual'

    local lines = vim.api.nvim_buf_get_lines(0, 1, -1, false)
    local end_of_frontmatter = 1

    for i, line in ipairs(lines) do
      if line:match('^---') then
        end_of_frontmatter = i + 1
        break
      end
    end

    vim.api.nvim_command('1,' .. end_of_frontmatter .. 'fold')
  end)
end

vim.schedule(fold_frontmatter)

--- Text formatting
-- Normal mode
vim.keymap.set('n', '<C-b>', '<Plug>(MarkdownPlusBold)', { buffer = true })
vim.keymap.set('n', '<C-i>', '<Plug>(MarkdownPlusItalic)', { buffer = true })
-- vim.keymap.set('n', '<C-s>', '<Plug>(MarkdownPlusStrikethrough)') -- conflicts with sav, { buffer = true }e
-- vim.keymap.set('n', '<C-k>', '<Plug>(MarkdownPlusCode)') -- C-k is window movemen, { buffer = true }t
vim.keymap.set('n', '<C-x>', '<Plug>(MarkdownPlusClearFormatting)', { buffer = true })

-- Visual mode
vim.keymap.set('x', '<C-b>', '<Plug>(MarkdownPlusBold)', { buffer = true })
vim.keymap.set('x', '<C-i>', '<Plug>(MarkdownPlusItalic)', { buffer = true })
vim.keymap.set('x', '<C-s>', '<Plug>(MarkdownPlusStrikethrough)', { buffer = true })
vim.keymap.set('x', '<C-k>', '<Plug>(MarkdownPlusCode)', { buffer = true })
vim.keymap.set('x', '<leader>mw', '<Plug>(MarkdownPlusCodeBlock)', { buffer = true })
vim.keymap.set('x', '<C-x>', '<Plug>(MarkdownPlusClearFormatting)', { buffer = true })

--- Headers & TOC
vim.keymap.set('n', 'gn', '<Plug>(MarkdownPlusNextHeader)', { buffer = true })
vim.keymap.set('n', 'gp', '<Plug>(MarkdownPlusPrevHeader)', { buffer = true })
vim.keymap.set('n', '<leader>h+', '<Plug>(MarkdownPlusPromoteHeader)', { buffer = true })
vim.keymap.set('n', '<leader>h-', '<Plug>(MarkdownPlusDemoteHeader)', { buffer = true })
vim.keymap.set('n', '<leader>ht', '<Plug>(MarkdownPlusGenerateTOC)', { buffer = true })
vim.keymap.set('n', '<leader>hu', '<Plug>(MarkdownPlusUpdateTOC)', { buffer = true })
vim.keymap.set('n', '<leader>hT', '<Plug>(MarkdownPlusOpenTocWindow)', { buffer = true })
-- vim.keymap.set('n', '<CR>', '<Plug>(MarkdownPlusFollowLink)') -- Follow TOC link -- interfeers with general <CR> behavio, { buffer = true }r

--- Header levels (H1-H6)
for i = 1, 6 do
  vim.keymap.set('n', '<leader>' .. i, '<Plug>(MarkdownPlusHeader' .. i .. ')', { buffer = true })
end

--- Links
-- vim.keymap.set('n', '<leader>li', '<Plug>(MarkdownPlusInsertLink)', { buffer = true })
vim.keymap.set('v', '<leader>li', '<Plug>(MarkdownPlusSelectionToLink)', { buffer = true })
vim.keymap.set('n', '<leader>le', '<Plug>(MarkdownPlusEditLink)', { buffer = true })
vim.keymap.set('n', '<leader>lr', '<Plug>(MarkdownPlusConvertToReference)', { buffer = true })
vim.keymap.set('n', '<leader>ln', '<Plug>(MarkdownPlusConvertToInline)', { buffer = true })
vim.keymap.set('n', '<leader><C-k>', '<Plug>(MarkdownPlusAutoLinkURL)', { buffer = true })

--- Images
vim.keymap.set('n', '<leader>mL', '<Plug>(MarkdownPlusInsertImage)', { buffer = true })
vim.keymap.set('v', '<leader>mL', '<Plug>(MarkdownPlusSelectionToImage)', { buffer = true })
vim.keymap.set('n', '<leader>mE', '<Plug>(MarkdownPlusEditImage)', { buffer = true })
vim.keymap.set('n', '<leader>mA', '<Plug>(MarkdownPlusToggleImageLink)', { buffer = true })

--- List  Management
-- Insert mode
vim.keymap.set('i', '<C-CR>', '<Plug>(MarkdownPlusListEnter)', { buffer = true })
vim.keymap.set('i', '<A-CR>', '<Plug>(MarkdownPlusListShiftEnter)', { buffer = true })
-- vim.keymap.set('i', '<C-]>', '<Plug>(MarkdownPlusListIndent)') -- conflicts with supermave, { buffer = true }n
vim.keymap.set('i', '<C-[>', '<Plug>(MarkdownPlusListOutdent)', { buffer = true })
vim.keymap.set('i', '<C-h>', '<Plug>(MarkdownPlusListBackspace)', { buffer = true })
-- vim.keymap.set('i', '<C-t>', '<Plug>(MarkdownPlusToggleCheckbox)') interfeer's with native C-, { buffer = true }t

-- Normal mode
-- vim.keymap.set('n', '<leader>lr', '<Plug>(MarkdownPlusRenumberLists)', { buffer = true })
-- vim.keymap.set('n', '<leader>ld', '<Plug>(MarkdownPlusDebugLists)', { buffer = true })
-- vim.keymap.set('n', 'o', '<Plug>(MarkdownPlusNewListItemBelow)') -- the fuk is thi, { buffer = true }s
-- vim.keymap.set('n', 'O', '<Plug>(MarkdownPlusNewListItemAbove)', { buffer = true })
vim.keymap.set('n', '<leader>mx', '<Plug>(MarkdownPlusToggleCheckbox)', { buffer = true })

-- Visual mode
vim.keymap.set('x', '<leader>mx', '<Plug>(MarkdownPlusToggleCheckbox)', { buffer = true })

--- Quotes
-- Normal mode
vim.keymap.set('n', '<C-q>', '<Plug>(MarkdownPlusToggleQuote)', { buffer = true })
-- Visual mode
vim.keymap.set('x', '<C-q>', '<Plug>(MarkdownPlusToggleQuote)', { buffer = true })

--- Callouts
-- Normal mode - Insert callout
vim.keymap.set('n', '<leader>mc', '<Plug>(MarkdownPlusInsertCallout)', { buffer = true })
-- Visual mode - Wrap selection in callout
vim.keymap.set('x', '<leader>mc', '<Plug>(MarkdownPlusInsertCallout)', { buffer = true })
-- Toggle callout type (cycle through types)
vim.keymap.set('n', '<leader>mC', '<Plug>(MarkdownPlusToggleCalloutType)', { buffer = true })
-- Convert blockquote to callout
vim.keymap.set('n', '<leader>m>c', '<Plug>(MarkdownPlusConvertToCallout)', { buffer = true })
-- Convert callout to blockquote
vim.keymap.set('n', '<leader>m>b', '<Plug>(MarkdownPlusConvertToBlockquote)', { buffer = true })

--- Footnotes
vim.keymap.set('n', '<leader>fi', '<Plug>(MarkdownPlusFootnoteInsert)', { buffer = true })
vim.keymap.set('n', '<leader>fe', '<Plug>(MarkdownPlusFootnoteEdit)', { buffer = true })
vim.keymap.set('n', '<leader>fd', '<Plug>(MarkdownPlusFootnoteDelete)', { buffer = true })
vim.keymap.set('n', '<leader>fg', '<Plug>(MarkdownPlusFootnoteGotoDefinition)', { buffer = true })
vim.keymap.set('n', '<leader>fr', '<Plug>(MarkdownPlusFootnoteGotoReference)', { buffer = true })
vim.keymap.set('n', '<leader>fn', '<Plug>(MarkdownPlusFootnoteNext)', { buffer = true })
vim.keymap.set('n', '<leader>fp', '<Plug>(MarkdownPlusFootnotePrev)', { buffer = true })
vim.keymap.set('n', '<leader>fl', '<Plug>(MarkdownPlusFootnoteList)', { buffer = true })

--- Tables
-- Table operations with different prefix
vim.keymap.set('n', '<leader>Tc', '<Plug>(markdown-plus-table-create)', { buffer = true })
vim.keymap.set('n', '<leader>Tf', '<Plug>(markdown-plus-table-format)', { buffer = true })
vim.keymap.set('n', '<leader>Tn', '<Plug>(markdown-plus-table-normalize)', { buffer = true })

-- Row operations
vim.keymap.set('n', '<leader>Tir', '<Plug>(markdown-plus-table-insert-row-below)', { buffer = true })
vim.keymap.set('n', '<leader>TiR', '<Plug>(markdown-plus-table-insert-row-above)', { buffer = true })
vim.keymap.set('n', '<leader>Tdr', '<Plug>(markdown-plus-table-delete-row)', { buffer = true })
vim.keymap.set('n', '<leader>Tyr', '<Plug>(markdown-plus-table-duplicate-row)', { buffer = true })

-- Column operations
vim.keymap.set('n', '<leader>Tic', '<Plug>(markdown-plus-table-insert-column-right)', { buffer = true })
vim.keymap.set('n', '<leader>TiC', '<Plug>(markdown-plus-table-insert-column-left)', { buffer = true })
vim.keymap.set('n', '<leader>Tdc', '<Plug>(markdown-plus-table-delete-column)', { buffer = true })
vim.keymap.set('n', '<leader>Tyc', '<Plug>(markdown-plus-table-duplicate-column)', { buffer = true })
