-- Global diff color convention (same mechanism as tufte.nvim, colorscheme-
-- agnostic): bg-only DiffAdd/DiffDelete washes, pushed into codediff.nvim's
-- own config for the char-level emphasis pair, and a bg-only extmark wash
-- for vim-fugitive's `-p`/`-i` terminal patch prompts (raw ANSI diff output
-- there has no background, only foreground). Palette picked from
-- `vim.o.background`, reapplied on every ColorScheme/background change so
-- it survives switching colorschemes.

local PALETTES = {
  dark = {
    add = '#004b00', -- line-level add background
    delete = '#3f0000', -- line-level delete background
    add_char = '#006f00', -- char-level add emphasis (more saturated)
    delete_char = '#6f0c10', -- char-level delete emphasis (more saturated)
  },
  light = {
    add = '#d0ffd0', -- line-level add background
    delete = '#ffd7d7', -- line-level delete background
    add_char = '#afffaf', -- char-level add emphasis (more saturated)
    delete_char = '#ffb6b6', -- char-level delete emphasis (more saturated)
  },
}

local function palette()
  return PALETTES[vim.o.background] or PALETTES.dark
end

local function apply()
  local p = palette()

  vim.api.nvim_set_hl(0, 'DiffAdd', { bg = p.add })
  vim.api.nvim_set_hl(0, 'DiffDelete', { bg = p.delete })

  -- Vim's stock syntax/diff.vim groups: vim-fugitive's :Gdiff/:Git diff
  -- buffers and expanded :Git status hunks use these directly.
  vim.api.nvim_set_hl(0, 'diffAdded', { bg = p.add })
  vim.api.nvim_set_hl(0, 'diffRemoved', { bg = p.delete })
  vim.api.nvim_set_hl(0, 'diffOldFile', { bg = p.delete })
  vim.api.nvim_set_hl(0, 'diffNewFile', { bg = p.add })

  -- codediff.nvim re-derives CodeDiffLine*/CodeDiffChar* from its own
  -- `highlights` config every time its setup() runs or `ColorScheme` fires,
  -- without a `default = true` guard, so it clobbers plain nvim_set_hl()
  -- calls for those groups. Push colors through its config instead, then
  -- force an immediate re-derive.
  local ok_config, cd_config = pcall(require, 'codediff.config')
  if ok_config then
    cd_config.options.highlights.line_insert = p.add
    cd_config.options.highlights.line_delete = p.delete
    cd_config.options.highlights.char_insert = p.add_char
    cd_config.options.highlights.char_delete = p.delete_char

    local ok_hl, cd_highlights = pcall(require, 'codediff.ui.highlights')
    if ok_hl then
      cd_highlights.setup()
    end
  end
end

apply()

local augroup = vim.api.nvim_create_augroup('DiffColors', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', { group = augroup, callback = apply })
vim.api.nvim_create_autocmd('OptionSet', { group = augroup, pattern = 'background', callback = apply })

-- -----------------------------------------------------------------------
-- Fugitive terminal patch prompts (`:Git add|checkout|commit|reset|restore|
-- stage|stash -p/--patch` and `-i/--interactive`) run through a real
-- :terminal, not Vim syntax highlighting, so git's own diff output there is
-- plain ANSI foreground only (no background). Recreate the DiffAdd/
-- DiffDelete wash by layering a bg-only extmark over the terminal buffer's
-- `+`/`-` lines (bg-only so the terminal's ANSI foreground for that cell is
-- preserved underneath).
-- -----------------------------------------------------------------------

local patch_ns = vim.api.nvim_create_namespace('diff_colors_fugitive_patch')

-- Neovim's terminal buffer name/b:term_title only records the resolved
-- executable (e.g. "/usr/bin/git"), not the argv fugitive passed to
-- termopen() — so "was this `-p`/`--patch`?" isn't recoverable from the
-- buffer at all. Gate on `b:git_dir` instead: FugitiveDetect() sets it on
-- every terminal fugitive spawns, and all of those render unified-diff
-- `+`/`-` lines worth washing the same way.
local function is_fugitive_term(bufnr)
  return vim.bo[bufnr].buftype == 'terminal' and vim.b[bufnr].git_dir ~= nil
end

---@param line string
---@return string?
local function classify(line)
  if line:sub(1, 4) == '+++ ' or line:sub(1, 4) == '--- ' then
    return nil
  end
  local first = line:sub(1, 1)
  if first == '+' then
    return 'DiffAdd'
  elseif first == '-' then
    return 'DiffDelete'
  end
  return nil
end

---@param bufnr integer
---@param firstline integer
---@param lastline integer -1 means end of buffer
local function highlight_range(bufnr, firstline, lastline)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  vim.api.nvim_buf_clear_namespace(bufnr, patch_ns, firstline, lastline)
  local lines = vim.api.nvim_buf_get_lines(bufnr, firstline, lastline, false)
  for i, line in ipairs(lines) do
    local hl = classify(line)
    if hl then
      local row = firstline + i - 1
      vim.api.nvim_buf_set_extmark(bufnr, patch_ns, row, 0, {
        end_row = row + 1,
        hl_group = hl,
        hl_eol = true,
        priority = 200,
      })
    end
  end
end

vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('DiffColorsFugitivePatch', { clear = true }),
  callback = function(args)
    local bufnr = args.buf
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(bufnr) or not is_fugitive_term(bufnr) then
        return
      end
      highlight_range(bufnr, 0, -1)
      vim.api.nvim_buf_attach(bufnr, false, {
        on_lines = function(_, buf, _, firstline, _, new_lastline)
          vim.schedule(function()
            highlight_range(buf, firstline, new_lastline)
          end)
        end,
      })
    end)
  end,
})
