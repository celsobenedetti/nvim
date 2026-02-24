local function fold_frontmatter()
  vim.schedule(function()
    local has_frontmatter = vim.api.nvim_buf_get_lines(0, 0, -1, false)[1]:match('^---')
    if not has_frontmatter then
      return
    end

    local lines = vim.api.nvim_buf_get_lines(0, 1, -1, false)
    local end_of_frontmatter = 1

    for i, line in ipairs(lines) do
      if line:match('^---') then
        end_of_frontmatter = i + 1
        break
      end
    end

    vim.opt.foldmethod = 'manual'
    vim.api.nvim_command('1,' .. end_of_frontmatter .. 'fold')
  end)
end

-- create custom highlight group for markdown #tags
-- namespace code to ensure higlights only apply to markdown windows, even after markdown ftplugin is loaded
local function highlight_tags()
  local ns = vim.api.nvim_create_namespace('ft_markdown_local_hl')
  vim.cmd('syntax match MarkdownTag /#[a-zA-Z0-9_-]\\+/')
  vim.api.nvim_set_hl(ns, 'MarkdownTag', { link = 'BlinkCmpScrollBarThumb' })

  -- apply highlight namespace only for markdown windows
  local bufnr = vim.api.nvim_get_current_buf()
  local group = vim.api.nvim_create_augroup('markdown_local_hl_' .. bufnr, { clear = true })

  local function apply_ns()
    local ok = pcall(vim.api.nvim_win_set_hl_ns, 0, ns)
    if not ok and vim.api.nvim_set_hl_ns then
      pcall(vim.api.nvim_set_hl_ns, ns)
    end
  end

  local function reset_ns()
    local ok = pcall(vim.api.nvim_win_set_hl_ns, 0, 0)
    if not ok and vim.api.nvim_set_hl_ns then
      pcall(vim.api.nvim_set_hl_ns, 0)
    end
  end

  vim.api.nvim_create_autocmd('BufWinEnter', {
    buffer = bufnr,
    group = group,
    callback = apply_ns,
  })

  vim.api.nvim_create_autocmd('BufWinLeave', {
    buffer = bufnr,
    group = group,
    callback = reset_ns,
  })
  -- set for the current window now
  apply_ns()
end

local function set_keymaps()
  -- keymaps
  -- https://github.com/yousefhadder/markdown-plus.nvim
  --- Text formatting
  --
  -- Normal mode
  vim.api.nvim_buf_set_keymap(0, 'n', '<C-b>', '<Plug>(MarkdownPlusBold)', { desc = 'MarkdownPlusBold' })
  -- vim.api.nvim_buf_set_keymap(0, 'n', '<C-i>', '<Plug>(MarkdownPlusItalic)', { desc = 'MarkdownPlusItalic' })
  -- vim.api.nvim_buf_set_keymap(0,'n', '<C-s>', '<Plug>(MarkdownPlusStrikethrough)') -- conflicts with sav, {  }e
  -- vim.api.nvim_buf_set_keymap(0,'n', '<C-k>', '<Plug>(MarkdownPlusCode)') -- C-k is window movement, {  }t
  -- vim.api.nvim_buf_set_keymap(
  --   0,
  --   'n',
  --   '<C-x>',
  --   '<Plug>(MarkdownPlusClearFormatting)',
  --   { desc = 'MarkdownPlusClearFormatting' }
  -- )

  -- Visual mode
  vim.api.nvim_buf_set_keymap(0, 'x', '<C-b>', '<Plug>(MarkdownPlusBold)', { desc = 'MarkdownPlusBold' })
  vim.api.nvim_buf_set_keymap(0, 'x', '<C-i>', '<Plug>(MarkdownPlusItalic)', { desc = 'MarkdownPlusItalic' })
  vim.api.nvim_buf_set_keymap(
    0,
    'x',
    '<C-s>',
    '<Plug>(MarkdownPlusStrikethrough)',
    { desc = 'MarkdownPlusStrikethrough' }
  )
  -- vim.api.nvim_buf_set_keymap(0,'x', '<C-k>', '<Plug>(MarkdownPlusCode)', {  }) -- replaced by Cusor like C-k for opencode
  vim.api.nvim_buf_set_keymap(0, 'x', '<leader>mw', '<Plug>(MarkdownPlusCodeBlock)', { desc = 'MarkdownPlusCodeBlock' })
  vim.api.nvim_buf_set_keymap(
    0,
    'x',
    '<C-x>',
    '<Plug>(MarkdownPlusClearFormatting)',
    { desc = 'MarkdownPlusClearFormatting' }
  )

  --- Headers & TOC
  vim.api.nvim_buf_set_keymap(0, 'n', 'gn', '<Plug>(MarkdownPlusNextHeader)', { desc = 'MarkdownPlusNextHeader' })
  -- vim.api.nvim_buf_set_keymap(0, 'n', 'gp', '<Plug>(MarkdownPlusPrevHeader)', { desc = 'MarkdownPlusPrevHeader' })
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>h+',
    '<Plug>(MarkdownPlusPromoteHeader)',
    { desc = 'MarkdownPlusPromoteHeader' }
  )
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>h-',
    '<Plug>(MarkdownPlusDemoteHeader)',
    { desc = 'MarkdownPlusDemoteHeader' }
  )
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>ht',
    '<Plug>(MarkdownPlusGenerateTOC)',
    { desc = 'MarkdownPlusGenerateTOC' }
  )
  vim.api.nvim_buf_set_keymap(0, 'n', '<leader>hu', '<Plug>(MarkdownPlusUpdateTOC)', { desc = 'MarkdownPlusUpdateTOC' })
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>hT',
    '<Plug>(MarkdownPlusOpenTocWindow)',
    { desc = 'MarkdownPlusOpenTocWindow' }
  )
  -- vim.api.nvim_buf_set_keymap(0,'n', '<CR>', '<Plug>(MarkdownPlusFollowLink)') -- Follow TOC link -- interfeers with general <CR> behavio, {  }r

  --- Header levels (H1-H6)
  for i = 1, 6 do
    vim.api.nvim_buf_set_keymap(
      0,
      'n',
      '<leader>' .. i,
      '<Plug>(MarkdownPlusHeader' .. i .. ')',
      { desc = "MarkdownPlusHeader' .. i .. '" }
    )
  end
  --
  -- --- Links
  -- vim.api.nvim_buf_set_keymap(0,'n', '<leader>li', '<Plug>(MarkdownPlusInsertLink)', {  })
  vim.api.nvim_buf_set_keymap(
    0,
    'v',
    '<leader>li',
    '<Plug>(MarkdownPlusSelectionToLink)',
    { desc = 'MarkdownPlusSelectionToLink' }
  )
  vim.api.nvim_buf_set_keymap(0, 'n', '<leader>le', '<Plug>(MarkdownPlusEditLink)', { desc = 'MarkdownPlusEditLink' })
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>lr',
    '<Plug>(MarkdownPlusConvertToReference)',
    { desc = 'MarkdownPlusConvertToReference' }
  )
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>ln',
    '<Plug>(MarkdownPlusConvertToInline)',
    { desc = 'MarkdownPlusConvertToInline' }
  )
  vim.api.nvim_buf_set_keymap(0, 'n', '<C-k>', '<Plug>(MarkdownPlusAutoLinkURL)', { desc = 'MarkdownPlusAutoLinkURL' })

  --- Images
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>mL',
    '<Plug>(MarkdownPlusInsertImage)',
    { desc = 'MarkdownPlusInsertImage' }
  )
  vim.api.nvim_buf_set_keymap(
    0,
    'v',
    '<leader>mL',
    '<Plug>(MarkdownPlusSelectionToImage)',
    { desc = 'MarkdownPlusSelectionToImage' }
  )
  vim.api.nvim_buf_set_keymap(0, 'n', '<leader>mE', '<Plug>(MarkdownPlusEditImage)', { desc = 'MarkdownPlusEditImage' })
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>mA',
    '<Plug>(MarkdownPlusToggleImageLink)',
    { desc = 'MarkdownPlusToggleImageLink' }
  )
  --
  -- --- List  Management
  -- Insert mode
  vim.api.nvim_buf_set_keymap(0, 'i', '<C-CR>', '<Plug>(MarkdownPlusListEnter)', { desc = 'MarkdownPlusListEnter' })
  vim.api.nvim_buf_set_keymap(
    0,
    'i',
    '<A-CR>',
    '<Plug>(MarkdownPlusListShiftEnter)',
    { desc = 'MarkdownPlusListShiftEnter' }
  )
  -- vim.api.nvim_buf_set_keymap(0,'i', '<C-]>', '<Plug>(MarkdownPlusListIndent)') -- conflicts with supermave, {  }n
  -- vim.api.nvim_buf_set_keymap(0,'i', '<C-[>', '<Plug>(MarkdownPlusListOutdent)', {  })
  vim.api.nvim_buf_set_keymap(
    0,
    'i',
    '<C-h>',
    '<Plug>(MarkdownPlusListBackspace)',
    { desc = 'MarkdownPlusListBackspace' }
  )
  -- vim.api.nvim_buf_set_keymap(0,'i', '<C-t>', '<Plug>(MarkdownPlusToggleCheckbox)') interfeer's with native C-, {  }t

  -- Normal mode
  -- vim.api.nvim_buf_set_keymap(0,'n', '<leader>lr', '<Plug>(MarkdownPlusRenumberLists)', {  })
  -- vim.api.nvim_buf_set_keymap(0,'n', '<leader>ld', '<Plug>(MarkdownPlusDebugLists)', {  })
  -- vim.api.nvim_buf_set_keymap(0,'n', 'o', '<Plug>(MarkdownPlusNewListItemBelow)') -- the fuk is thi, {  }s
  -- vim.api.nvim_buf_set_keymap(0,'n', 'O', '<Plug>(MarkdownPlusNewListItemAbove)', {  })
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>mx',
    '<Plug>(MarkdownPlusToggleCheckbox)',
    { desc = 'MarkdownPlusToggleCheckbox' }
  )

  -- Visual mode
  vim.api.nvim_buf_set_keymap(
    0,
    'x',
    '<leader>mx',
    '<Plug>(MarkdownPlusToggleCheckbox)',
    { desc = 'MarkdownPlusToggleCheckbox' }
  )

  --- Quotes
  -- Normal mode
  vim.api.nvim_buf_set_keymap(0, 'n', '<C-q>', '<Plug>(MarkdownPlusToggleQuote)', { desc = 'MarkdownPlusToggleQuote' })
  -- Visual mode
  vim.api.nvim_buf_set_keymap(0, 'x', '<C-q>', '<Plug>(MarkdownPlusToggleQuote)', { desc = 'MarkdownPlusToggleQuote' })

  --- Callouts
  -- Normal mode - Insert callout
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>mc',
    '<Plug>(MarkdownPlusInsertCallout)',
    { desc = 'MarkdownPlusInsertCallout' }
  )
  --
  -- Visual mode - Wrap selection in callout
  vim.api.nvim_buf_set_keymap(
    0,
    'x',
    '<leader>mc',
    '<Plug>(MarkdownPlusInsertCallout)',
    { desc = 'MarkdownPlusInsertCallout' }
  )
  -- Toggle callout type (cycle through types)
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>mC',
    '<Plug>(MarkdownPlusToggleCalloutType)',
    { desc = 'MarkdownPlusToggleCalloutType' }
  )
  -- Convert blockquote to callout
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>m>c',
    '<Plug>(MarkdownPlusConvertToCallout)',
    { desc = 'MarkdownPlusConvertToCallout' }
  )
  -- Convert callout to blockquote
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>m>b',
    '<Plug>(MarkdownPlusConvertToBlockquote)',
    { desc = 'MarkdownPlusConvertToBlockquote' }
  )

  --- Footnotes
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>fi',
    '<Plug>(MarkdownPlusFootnoteInsert)',
    { desc = 'MarkdownPlusFootnoteInsert' }
  )
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>fe',
    '<Plug>(MarkdownPlusFootnoteEdit)',
    { desc = 'MarkdownPlusFootnoteEdit' }
  )
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>fd',
    '<Plug>(MarkdownPlusFootnoteDelete)',
    { desc = 'MarkdownPlusFootnoteDelete' }
  )
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>fg',
    '<Plug>(MarkdownPlusFootnoteGotoDefinition)',
    { desc = 'MarkdownPlusFootnoteGotoDefinition' }
  )
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>fr',
    '<Plug>(MarkdownPlusFootnoteGotoReference)',
    { desc = 'MarkdownPlusFootnoteGotoReference' }
  )
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>fn',
    '<Plug>(MarkdownPlusFootnoteNext)',
    { desc = 'MarkdownPlusFootnoteNext' }
  )
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>fp',
    '<Plug>(MarkdownPlusFootnotePrev)',
    { desc = 'MarkdownPlusFootnotePrev' }
  )
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>fl',
    '<Plug>(MarkdownPlusFootnoteList)',
    { desc = 'MarkdownPlusFootnoteList' }
  )

  --- Tables
  -- Table operations with different prefix
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>Tc',
    '<Plug>(markdown-plus-table-create)',
    { desc = 'markdown-plus-table-create' }
  )
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>Tf',
    '<Plug>(markdown-plus-table-format)',
    { desc = 'markdown-plus-table-format' }
  )
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>Tn',
    '<Plug>(markdown-plus-table-normalize)',
    { desc = 'markdown-plus-table-normalize' }
  )

  -- Row operations
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>Tir',
    '<Plug>(markdown-plus-table-insert-row-below)',
    { desc = 'markdown-plus-table-insert-row-below' }
  )
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>TiR',
    '<Plug>(markdown-plus-table-insert-row-above)',
    { desc = 'markdown-plus-table-insert-row-above' }
  )
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>Tdr',
    '<Plug>(markdown-plus-table-delete-row)',
    { desc = 'markdown-plus-table-delete-row' }
  )
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>Tyr',
    '<Plug>(markdown-plus-table-duplicate-row)',
    { desc = 'markdown-plus-table-duplicate-row' }
  )

  -- Column operations
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>Tic',
    '<Plug>(markdown-plus-table-insert-column-right)',
    { desc = 'markdown-plus-table-insert-column-right' }
  )
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>TiC',
    '<Plug>(markdown-plus-table-insert-column-left)',
    { desc = 'markdown-plus-table-insert-column-left' }
  )
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>Tdc',
    '<Plug>(markdown-plus-table-delete-column)',
    { desc = 'markdown-plus-table-delete-column' }
  )
  vim.api.nvim_buf_set_keymap(
    0,
    'n',
    '<leader>Tyc',
    '<Plug>(markdown-plus-table-duplicate-column)',
    { desc = 'markdown-plus-table-duplicate-column' }
  )
end

--- main execution

vim.opt.wrap = true -- disable wrap

vim.schedule(fold_frontmatter)
vim.schedule(set_keymaps)
vim.schedule(highlight_tags)
