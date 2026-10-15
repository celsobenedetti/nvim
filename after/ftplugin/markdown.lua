if not lib.buffers.is_file() then
  return
end

vim.opt_local.number = false

local function fold_frontmatter()
  local has_frontmatter = vim.api.nvim_buf_get_lines(0, 0, -1, false)[1]:match('^---$')
  if not has_frontmatter then
    return
  end

  vim.wo.foldmethod = 'manual'

  local lines = vim.api.nvim_buf_get_lines(0, 1, -1, false)
  local end_of_frontmatter = 1

  for i, line in ipairs(lines) do
    if line:match('^---$') then
      end_of_frontmatter = i + 1
      break
    end
  end

  vim.schedule(function()
    vim.api.nvim_command('1,' .. end_of_frontmatter .. ' fold')
  end)
end

local function setup_folding()
  vim.schedule(function()
    vim.wo.foldmethod = 'expr'
    vim.wo.foldlevel = 2
    vim.wo.foldenable = true

    function _G.__md_foldexpr()
      local lnum = vim.v.lnum
      local s, e = vim.b._fm_start, vim.b._fm_end
      if s and e then
        if lnum == s then
          return '>2'
        elseif lnum == e then
          return '<2'
        elseif lnum > s and lnum < e then
          return '2'
        end
      end
      return vim.treesitter.foldexpr()
    end

    vim.wo.foldexpr = 'v:lua.__md_foldexpr()'
    vim.schedule(fold_frontmatter)
  end)
end

-- create custom highlight groups for markdown
-- namespace is per-window; toggle via BufEnter/WinEnter so non-markdown windows never see it
local function setup_markdown_hl()
  -- TODO: remove this
  if true then
    return
  end

  local ns = vim.api.nvim_create_namespace('ft_markdown_local_hl')
  vim.cmd('syntax match MarkdownTag /#[a-zA-Z0-9_-]\\+/')
  vim.api.nvim_set_hl(ns, 'MarkdownTag', { link = 'BlinkCmpScrollBarThumb' })

  local group = vim.api.nvim_create_augroup('markdown_local_hl', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
    pattern = '*',
    group = group,
    callback = function()
      if vim.bo.filetype == 'markdown' then
        vim.api.nvim_win_set_hl_ns(0, ns)
      else
        vim.api.nvim_win_set_hl_ns(0, 0)
      end
    end,
  })
  vim.api.nvim_win_set_hl_ns(0, ns)
end

-- <CR> follows [[wikilinks]] here through obsidian.nvim's own buffer-local
-- "Obsidian Smart Action" map, set on BufEnter for every note inside a vault.

local function change_heading_level(delta)
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local line = lines[lnum]
  local heading_chars = line:match('^(#+)%s')
  if not heading_chars then
    return
  end
  local heading_level = #heading_chars

  if delta < 0 and heading_level == 1 then
    return
  end

  local end_line = #lines
  for l = lnum + 1, end_line do
    local lvl_match = lines[l]:match('^(#+)%s')
    if lvl_match and #lvl_match <= heading_level then
      end_line = l - 1
      break
    end
  end

  vim.api.nvim_buf_call(0, function()
    for l = lnum, end_line do
      local lvl_match = lines[l]:match('^(#+)%s')
      if lvl_match then
        local lvl = #lvl_match
        local new_level = lvl + delta
        local prefix = string.rep('#', new_level)
        vim.api.nvim_buf_set_lines(0, l - 1, l, false, { prefix .. lines[l]:sub(lvl + 1) })
      end
    end
  end)
end

vim.keymap.set('n', '>s', function()
  change_heading_level(1)
end, { buffer = true, desc = 'increase heading level' })
vim.keymap.set('n', '<s', function()
  change_heading_level(-1)
end, { buffer = true, desc = 'decrease heading level' })

local function add_reference()
  local url = vim.trim(vim.fn.getreg('+'))
  if not url:match('^https?://[%-%w+&@#/%%?=~_|!:,.;]*[%-%w+&@#/%%=~_|]$') then
    Snacks.notify.warn('Clipboard does not contain a URL', { title = 'Reference' })
    return
  end

  vim.ui.input({ prompt = 'Reference title: ' }, function(title)
    if not title or title == '' then
      return
    end

    local entry = string.format('- "[%s](%s)"', title, url)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    if not (lines[1] and lines[1]:match('^---%s*$')) then
      local new_lines = { '---', 'references:', entry, '---' }
      if lines[1] and lines[1] ~= '' then
        table.insert(new_lines, '')
      end
      vim.api.nvim_buf_set_lines(0, 0, 0, false, new_lines)
      return
    end

    local fm_end
    for i = 2, #lines do
      if lines[i]:match('^---%s*$') then
        fm_end = i
        break
      end
    end

    if not fm_end then
      Snacks.notify.warn('Frontmatter has no closing "---"', { title = 'Reference' })
      return
    end

    local ref_line
    for i = 2, fm_end - 1 do
      if lines[i]:match('^references:%s*$') then
        ref_line = i
        break
      end
    end

    if not ref_line then
      vim.api.nvim_buf_set_lines(0, fm_end - 1, fm_end - 1, false, { 'references:', entry })
      return
    end

    local insert_at = ref_line
    for i = ref_line + 1, fm_end - 1 do
      if lines[i]:match('^%s*%-') then
        insert_at = i
      else
        break
      end
    end
    vim.api.nvim_buf_set_lines(0, insert_at, insert_at, false, { entry })
  end)
end

vim.api.nvim_buf_create_user_command(
  0,
  'Reference',
  add_reference,
  { desc = 'add clipboard URL as a reference in frontmatter' }
)

vim.opt.wrap = true -- disable wrap
vim.schedule(setup_folding)
vim.schedule(setup_markdown_hl)

--- "Reading mode": keep markup hidden on the cursor line too.
---
--- Two layers re-show markup under the cursor and `anti_conceal` drives both:
--- the plugin skips its own decorations (bullets, heading icons) on the cursor
--- line, and while anti conceal is on its `win_options` preset pins
--- `concealcursor` to `''` (`lib/presets.lua`), which is what reveals the
--- `**` / backtick markers there. Disabling anti conceal flips `concealcursor`
--- to `'nvic'`, so nothing unfolds under the cursor.
---
--- The plugin exposes no public toggle for the flag, so rebuild the config:
--- `setup()` merges it into the user opts and drops the per-buffer config
--- cache, `enable()` re-renders every attached buffer with the new window
--- options. The `marks.add` patch below survives, it wraps the module once.
local base_opts = {}
local reading_mode = false
local function toggle_reading_mode()
  reading_mode = not reading_mode
  local render_markdown = require('render-markdown')
  render_markdown.setup(vim.tbl_deep_extend('force', base_opts, {
    anti_conceal = { enabled = not reading_mode },
  }))
  render_markdown.enable()
  vim.notify('markdown reading mode: ' .. (reading_mode and 'on' or 'off'))
end

vim.keymap.set('n', '<leader>rm', toggle_reading_mode, { desc = 'markdown: toggle reading mode' })
