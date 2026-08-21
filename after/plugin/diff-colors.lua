-- Consolidated diff color palette, colorscheme-agnostic, delta north star.
--
-- Line/char values are delta 0.19.2's actual default theme, extracted from
-- its ANSI output (not approximated), so every diff surface in this editor
-- matches what `git diff | delta` shows:
--
--   delta concept             dark      light      usage here
--   plus-style           #002800   #D0FFD0   whole added line
--   minus-style          #3F0001   #FFE0E0   whole removed line
--   plus-emph-style      #006000   #A0EFA0   changed chars in added line
--   minus-emph-style     #901011   #FFC0C0   changed chars in removed line
--   line-numbers-style   #444444   #444444   fg of line numbers / metadata
--
-- "change" (a line modified in place) has no delta equivalent — git diff is
-- only +/- and delta renders old/new pairs (red minus line + green plus
-- line). In gid's inline view that pairing comes from show_deleted (red
-- virt line) + the modified line itself, so the gitsigns *change* word-diff
-- regions use delta's plus-emph GREEN rather than yellow. The vim diff-mode
-- "change" groups (DiffChange/DiffText/Changed/ChangedText, and the
-- GitSignsChangeLn line wash) keep the classic Vim yellow so "modified"
-- stays distinguishable from "added" in vimdiff/:Gitsigns diffthis.
--
-- Delta-style mapping to editor groups:
--   plus-style     -> DiffAdd, diffAdded, diffNewFile, Added, GitSigns*Ln
--                     (linehl), GitSigns* sign glyphs, GitSignsAddPreview,
--                     fugitive terminal `+` lines
--   minus-style    -> DiffDelete, diffRemoved, diffOldFile, Removed,
--                     GitSignsDeleteVirtLn, GitSignsDeletePreview,
--                     fugitive terminal `-` lines
--   change         -> DiffChange, diffChanged, Changed (vim diff mode only)
--   plus-emph      -> GitSignsAddInline, GitSignsAddLnInline,
--                     GitSignsChangeInline, GitSignsChangeLnInline (delta
--                     pairs green change-emph with the red deleted line),
--                     codediff char_insert
--   change-emph    -> DiffText, ChangedText (vimdiff/:Gitsigns diffthis
--                     intra-line change)
--   minus-emph     -> GitSignsDeleteInline, GitSignsDeleteLnInline,
--                     GitSignsDeleteVirtLnInLine, codediff char_delete
--   line-numbers   -> GitSignsVirtLnum, diffIndexLine

local PALETTES = {
  dark = {
    add = '#002800', -- delta plus-style
    delete = '#3F0001', -- delta minus-style
    change = '#403800', -- vim DiffChange wash (gitsigns change linehl)
    add_char = '#006000', -- delta plus-emph-style
    delete_char = '#901011', -- delta minus-emph-style
    change_char = '#8C7A00', -- vim diff-mode intra-line change (DiffText)
    lnum_fg = '#444444', -- delta line-numbers-style
  },
  light = {
    add = '#D0FFD0', -- delta plus-style
    delete = '#FFE0E0', -- delta minus-style
    change = '#FFF0B8', -- vim DiffChange wash (gitsigns change linehl)
    add_char = '#A0EFA0', -- delta plus-emph-style
    delete_char = '#FFC0C0', -- delta minus-emph-style
    change_char = '#FFE08A', -- vim diff-mode intra-line change (DiffText)
    lnum_fg = '#444444', -- delta line-numbers-style
  },
}

local function palette()
  return PALETTES[vim.o.background] or PALETTES.dark
end

local function apply()
  local p = palette()

  -- --------------------------------------------------------------------
  -- 1. Core diff groups (vimdiff, :Gitsigns diffthis, diff-mode).
  -- --------------------------------------------------------------------
  vim.api.nvim_set_hl(0, 'DiffAdd', { bg = p.add })
  vim.api.nvim_set_hl(0, 'DiffDelete', { bg = p.delete })
  vim.api.nvim_set_hl(0, 'DiffChange', { bg = p.change })
  -- Changed chars inside a changed line (delta emph mapping).
  vim.api.nvim_set_hl(0, 'DiffText', { bg = p.change_char })

  -- nvim 0.10+ builtin groups: DiffAdd/DiffChange/DiffDelete/DiffText are
  -- linked to these by default, and gitsigns' sign groups derive from them
  -- (highlight.lua fallback chain includes 'Added'/'Removed'/'Changed' for
  -- nvim >= 0.10). Delta renders the +/- markers with the line's wash, so
  -- bg-only here puts the sign glyphs in the palette too.
  vim.api.nvim_set_hl(0, 'Added', { bg = p.add })
  vim.api.nvim_set_hl(0, 'Removed', { bg = p.delete })
  vim.api.nvim_set_hl(0, 'Changed', { bg = p.change })
  vim.api.nvim_set_hl(0, 'ChangedText', { bg = p.change_char })

  -- --------------------------------------------------------------------
  -- 2. Diff syntax groups (fugitive :Gdiff / :Git diff buffers).
  -- --------------------------------------------------------------------
  vim.api.nvim_set_hl(0, 'diffAdded', { bg = p.add })
  vim.api.nvim_set_hl(0, 'diffRemoved', { bg = p.delete })
  vim.api.nvim_set_hl(0, 'diffChanged', { bg = p.change })
  vim.api.nvim_set_hl(0, 'diffOldFile', { bg = p.delete })
  vim.api.nvim_set_hl(0, 'diffNewFile', { bg = p.add })
  -- Metadata (`index abc..def`) dimmed like delta's non-diff lines.
  vim.api.nvim_set_hl(0, 'diffIndexLine', { fg = p.lnum_fg })

  -- --------------------------------------------------------------------
  -- 3. Gitsigns inline diffs.
  -- --------------------------------------------------------------------
  -- Line-level (`linehl`): GitSigns*Ln, *Nr, *Cul and the sign-column
  -- groups derive from DiffAdd/DiffChange/DiffDelete via gitsigns' fallback
  -- chain (highlight.lua), so they pick up the washes in section 1
  -- automatically. GitSignsStaged* derive the same backgrounds (fg_factor
  -- only blends fg, which is nil for bg-only groups), matching delta's
  -- indifference to staged/unstaged — no explicit setup needed here.

  -- Char-level (`word_diff`): gitsigns' fallback for every *Inline group is
  -- TermCursor, so without these they render as a block cursor. Map them to
  -- delta's emph styles instead:
  --   GitSigns*Inline    -> word diff in previews (preview_hunk /
  --                          preview_hunk_inline added lines)
  --   GitSigns*LnInline  -> word diff in the buffer (`word_diff`)
  --
  -- `change` regions (modified-in-place words) use the plus-emph GREEN, not
  -- yellow: delta has no yellow, and in gid the red deleted virt line above
  -- the modified line already conveys "old", so the changed chars should
  -- read as "new" (green). Yellow-on-yellow (change_char on the GitSigns
  -- ChangeLn wash) was effectively invisible.
  vim.api.nvim_set_hl(0, 'GitSignsAddInline', { bg = p.add_char })
  vim.api.nvim_set_hl(0, 'GitSignsChangeInline', { bg = p.add_char })
  vim.api.nvim_set_hl(0, 'GitSignsDeleteInline', { bg = p.delete_char })
  vim.api.nvim_set_hl(0, 'GitSignsAddLnInline', { bg = p.add_char })
  vim.api.nvim_set_hl(0, 'GitSignsChangeLnInline', { bg = p.add_char })
  vim.api.nvim_set_hl(0, 'GitSignsDeleteLnInline', { bg = p.delete_char })

  -- Removed lines as virtual lines (preview_hunk_inline / show_deleted):
  -- whole line = minus-style wash, changed chars inside it = minus-emph,
  -- and the fake line numbers get delta's gray instead of inheriting the
  -- red wash via the GitSignsDeleteVirtLn fallback.
  vim.api.nvim_set_hl(0, 'GitSignsDeleteVirtLn', { bg = p.delete })
  vim.api.nvim_set_hl(0, 'GitSignsDeleteVirtLnInLine', { bg = p.delete_char })
  vim.api.nvim_set_hl(0, 'GitSignsVirtLnum', { fg = p.lnum_fg })

  -- Hunk preview popups (preview_hunk): added/removed line washes.
  vim.api.nvim_set_hl(0, 'GitSignsAddPreview', { bg = p.add })
  vim.api.nvim_set_hl(0, 'GitSignsDeletePreview', { bg = p.delete })
  -- GitSignsNoEOLPreview / GitSignsCurrentLineBlame are not diff colors;
  -- left to the colorscheme.
  --
  -- NOTE: the word_diff config docs mention GitSignsAddVirtLnInline /
  -- GitSignsChangeVirtLnInline for word diff in virtual lines, but those
  -- groups are not defined upstream (commented out in highlight.lua);
  -- removed virt lines only ever use GitSignsDeleteVirtLnInLine.

  -- --------------------------------------------------------------------
  -- 4. codediff.nvim: re-derives CodeDiffLine*/CodeDiffChar* from its own
  -- `highlights` config on setup()/ColorScheme without a `default` guard,
  -- so it clobbers plain nvim_set_hl() calls for those groups. Push colors
  -- through its config instead, then force an immediate re-derive.
  -- --------------------------------------------------------------------
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
-- preserved underneath). DiffAdd/DiffDelete carry the palette from section 1.
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
