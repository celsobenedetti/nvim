-- Makes any :terminal buffer answer OSC 10/11 (foreground/background) and OSC 4
-- (16-color ANSI palette) queries with the current Omarchy theme's colors.
--
-- Neovim's embedded terminal never answers OSC 4 at all, and hardcodes a
-- white-on-black reply for OSC 10/11 that ignores 'Normal' and
-- g:terminal_color_N (confirmed against Neovim's source: nothing ever calls
-- libvterm's default-color setter). TermRequest still fires for these
-- queries though, and the querying program folds every reply it receives for
-- a given code and keeps the last one (verified against hunk's own OSC reply
-- parser, core/theme/detection.ts), so answering here after Neovim's own
-- (ignored) reply works cleanly.
local OMARCHY_COLORS_PATH = vim.fn.expand('~/.local/state/omarchy/current/theme/colors.toml')

-- hunk derives its diff add/remove colors from the ANSI red/green it reads
-- here (core/theme/detection.ts), not from literal addedBg/removedBg fields,
-- so the only way to make its diff washes match lua/diff-colors.lua is to
-- feed it diff-colors.lua's own red/green instead of the theme's actual ANSI
-- red/green (tufte's in particular is near-neutral -- 'vermillion is the
-- only saturated color' -- so hunk has nothing to derive a visible green
-- diff wash from otherwise). Values are diff-colors.lua's add_char/delete_char
-- (its 'emphasis' tier, the most saturated green/red it defines).
--
-- Its own emphasis-tier colors (add_char/delete_char) are themselves a pale
-- wash meant to sit directly on a near-white background, so feeding them
-- here just gets diluted a second time by hunk's blend -- on a light, pale
-- background that reads as barely-there. A properly saturated red/green
-- survives that dilution and still reads as a real diff color; the muddier
-- dark-mode add_char/delete_char don't need that push since blending
-- towards a dark background doesn't wash them out the same way.
local DIFF_ANSI_OVERRIDE = {
  dark = { red = '#a01818', green = '#008000' },
  light = { red = '#e00000', green = '#009d00' },
}

-- ANSI 'bright black' (index 8) is what hunk's 'terminal' theme maps code
-- comments to. Omarchy's own `muted` is meant as a pale, near-background UI
-- tint on light themes (ghostty's own convention -- see ghostty.conf.tpl),
-- not a readable dim-text color, so comments inherit that paleness. A dark
-- theme's `muted` is already a legible mid-gray and needs no help.
-- diff-colors.lua's line-numbers-style (#444444, 'both' modes) is exactly
-- the dim-but-readable gray this needs.
local LIGHT_MODE_MUTED_OVERRIDE = '#444444'

local PALETTE_KEYS = {
  [0] = 'background',
  [1] = 'red',
  [2] = 'green',
  [3] = 'yellow',
  [4] = 'blue',
  [5] = 'magenta',
  [6] = 'cyan',
  [7] = 'foreground',
  [8] = 'muted',
  [9] = 'bright_red',
  [10] = 'bright_green',
  [11] = 'bright_yellow',
  [12] = 'bright_blue',
  [13] = 'bright_magenta',
  [14] = 'bright_cyan',
  [15] = 'bright_foreground',
}

local function read_omarchy_colors()
  local colors = {}
  for line in io.lines(OMARCHY_COLORS_PATH) do
    local key, value = line:match('^(%a[%w_]*)%s*=%s*"([^"]*)"')
    if key then
      colors[key] = value
    end
  end
  return colors
end

local function hex_to_osc(hex)
  local r, g, b = hex:match('^#(%x%x)(%x%x)(%x%x)$')
  if not r then
    return nil
  end
  return ('rgb:%s%s/%s%s/%s%s'):format(r, r, g, g, b, b)
end

local function respond(buf, code, value)
  vim.api.nvim_chan_send(vim.bo[buf].channel, ('\27]%s;%s\27\\'):format(code, value))
end

vim.api.nvim_create_autocmd('TermRequest', {
  desc = 'omarchy: answer terminal color queries with the current theme',
  callback = function(ev)
    if vim.fn.filereadable(OMARCHY_COLORS_PATH) == 0 then
      return
    end

    local seq = ev.data.sequence
    local idx = seq:match('^\27%]4;(%d+);%?')
    if idx then
      local ok, colors = pcall(read_omarchy_colors)
      local key = ok and PALETTE_KEYS[tonumber(idx)]
      local override = ok and DIFF_ANSI_OVERRIDE[colors.mode] and DIFF_ANSI_OVERRIDE[colors.mode][key]
      if not override and ok and key == 'muted' and colors.mode == 'light' then
        override = LIGHT_MODE_MUTED_OVERRIDE
      end
      local hex = override or (key and colors[key])
      local osc = hex and hex_to_osc(hex)
      if osc then
        respond(ev.buf, '4;' .. idx, osc)
      end
      return
    end

    local key
    if seq:match('^\27%]10;%?') then
      key = 'foreground'
    elseif seq:match('^\27%]11;%?') then
      key = 'background'
    else
      return
    end

    local ok, colors = pcall(read_omarchy_colors)
    local osc = ok and colors[key] and hex_to_osc(colors[key])
    if osc then
      respond(ev.buf, key == 'foreground' and 10 or 11, osc)
    end
  end,
})
