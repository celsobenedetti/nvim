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
      local osc = key and colors[key] and hex_to_osc(colors[key])
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
