-- Integration test (real nvim, headless): the resize anchor in
-- after/plugin/pi.lua holds a pi terminal window's viewport in place across
-- pi's resize redraw, which clears the terminal's scrollback and reprints the
-- whole transcript. See docs/pi-resize.md.
--
-- pi is stood in for by a script named `pi` (state.pi.is_running keys off the
-- job command's basename) reproducing the one behaviour under test: on
-- SIGWINCH, emit `\e[2J\e[H\e[3J` and reprint. Its lines are long enough to
-- rewrap at the narrower width, as pi's transcript does.
--
-- Run via `make test-integration`.

local script = debug.getinfo(1, 'S').source:sub(2)

-- `nvim -l` never enters normal mode's main loop, and that is where nvim both
-- raises WinResized (may_trigger_win_scrolled_resized in normal.c) and redraws
-- — the only path that pushes a window's new size to the pty
-- (terminal_check_size in drawscreen.c). Neither happens here, so re-exec under
-- plain --headless, which runs that loop, and hand its exit code to the Makefile.
if not vim.env.PI_RESIZE_TEST_CHILD then
  local child = vim
    .system({
      'nvim',
      '--headless',
      '-u',
      'NONE',
      '-c',
      'luafile ' .. script,
    }, { text = true, env = { PI_RESIZE_TEST_CHILD = '1' }, timeout = 30000 })
    :wait()
  io.write(child.stdout or '', child.stderr or '')
  os.exit(child.code)
end

-- Repo root on rtp so `require('lib.*')` resolves (Makefile runs us from there).
local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd)

-- Globals the plugin files expect from the live config.
_G.state = {}
_G.lib = { term = require('lib.term') }

vim.cmd('luafile ' .. cwd .. '/after/plugin/pi.lua')

local LINES = 200

local fake_pi_dir = vim.fn.tempname()
vim.fn.mkdir(fake_pi_dir, 'p')
local fake_pi = fake_pi_dir .. '/pi'
vim.fn.writefile({
  '#!/usr/bin/env bash',
  ('paint() { for i in $(seq 1 %d); do printf "line %%s %%s\\n" "$i" "$(printf "=%%.0s" {1..60})"; done; }'):format(
    LINES
  ),
  -- What pi's fullRender(true) emits on a width or height change: clear
  -- screen, home, clear scrollback — then the whole transcript again.
  [[trap 'printf "\033[2J\033[H\033[3J"; paint' WINCH]],
  'paint',
  -- A stand-in for a reply streaming in -- output that is not a resize redraw
  -- -- on demand. Polled rather than signalled: a trap cannot run while the
  -- WINCH handler above is still painting.
  ('while :; do if [ -f %s/stream ]; then rm -f %s/stream; for i in $(seq 1 60); do echo "stream $i"; done; fi; sleep 0.1; done'):format(
    fake_pi_dir,
    fake_pi_dir
  ),
}, fake_pi)
vim.fn.setfperm(fake_pi, 'rwxr-xr-x')
vim.env.PATH = fake_pi_dir .. ':' .. vim.env.PATH

-- The body runs as a coroutine so `pause` can hand control back to the main
-- loop: a straight-line script (or vim.wait) keeps nvim out of normal mode,
-- where the resize is noticed and the screen redrawn.
local step
local body = coroutine.create(function()
  ---@param ms integer
  local function pause(ms)
    vim.defer_fn(step, ms)
    coroutine.yield()
  end

  ---@param predicate fun(): boolean
  ---@param message fun(): string | string
  local function wait_for(predicate, message)
    local deadline = vim.uv.now() + 5000
    while not predicate() do
      if vim.uv.now() > deadline then
        error(type(message) == 'function' and message() or message, 0)
      end
      pause(20)
    end
  end

  vim.o.scrollback = 10000
  vim.cmd.term('pi')
  local buf = vim.api.nvim_get_current_buf()
  assert(state.pi.is_running(buf), 'state.pi.is_running did not recognise the pi terminal')
  wait_for(function()
    return vim.api.nvim_buf_line_count(buf) > LINES
  end, 'fake pi never painted its transcript')

  -- A scratch window so the pi windows can be resized without resizing the UI,
  -- and a second pi window so the restore is exercised on an unfocused one too.
  -- Both pi windows stay in normal mode: that is where the bug bites (nvim pins
  -- a focused terminal-mode window to pi's own cursor, so it keeps its place).
  vim.cmd.vnew()
  local scratch = vim.api.nvim_get_current_win()
  vim.cmd('wincmd p')
  vim.cmd.vsplit()
  local pi_win2 = vim.api.nvim_get_current_win()
  vim.cmd('wincmd p')
  local pi_win = vim.api.nvim_get_current_win()
  assert(
    vim.api.nvim_win_get_buf(pi_win) == buf and vim.api.nvim_win_get_buf(pi_win2) == buf,
    'pi windows lost the pi buffer'
  )
  assert(vim.api.nvim_win_get_buf(scratch) ~= buf, 'the scratch window unexpectedly shows the pi buffer')

  -- Park both cursors where a reader sits: a few lines above the end in the
  -- focused window (pi's input box), well up the transcript in the other.
  local count = vim.api.nvim_buf_line_count(buf)
  vim.api.nvim_win_set_cursor(pi_win, { count - 3, 0 })
  vim.api.nvim_win_set_cursor(pi_win2, { count - 120, 0 })

  -- Record every frame nvim actually draws for the pi windows from here on.
  -- on_win reports the toprow the window was drawn with, which is the only way
  -- to tell a viewport that was merely restored late from one that never moved.
  local frames = { [pi_win] = {}, [pi_win2] = {} }
  vim.api.nvim_set_decoration_provider(vim.api.nvim_create_namespace('pi_resize_test'), {
    on_win = function(_, winid, bufnr, toprow)
      if frames[winid] and bufnr == buf then
        table.insert(frames[winid], { toprow = toprow, count = vim.api.nvim_buf_line_count(buf) })
      end
    end,
  })

  vim.cmd('vertical resize ' .. math.floor(vim.api.nvim_win_get_width(pi_win) / 2))

  -- Wait out pi's redraw: the reprint at half the width rewraps every line, so
  -- the buffer grows well past where it started.
  wait_for(function()
    return vim.api.nvim_buf_line_count(buf) > count
  end, 'fake pi never reprinted its transcript at the new width')
  -- Let the reprint run to the end, so the frames judged below cover all of it
  -- and not just its first instalment.
  local settled = 0
  local last = 0
  while settled < 3 do
    local now = vim.api.nvim_buf_line_count(buf)
    settled = now == last and settled + 1 or 0
    last = now
    pause(100)
  end
  assert(#frames[pi_win] > 0 and #frames[pi_win2] > 0, 'nvim never redrew the pi windows; no frames to judge')

  local function offset(win)
    return vim.api.nvim_buf_line_count(buf) - vim.api.nvim_win_get_cursor(win)[1]
  end

  wait_for(function()
    return offset(pi_win) == 3 and offset(pi_win2) == 120
  end, function()
    return ('cursors not restored: focused %d lines from end (want 3), other %d (want 120)'):format(
      offset(pi_win),
      offset(pi_win2)
    )
  end)
  io.stdout:write('PASS: both pi windows kept their distance from the end of the transcript\n')

  -- No flicker: the viewport must never have been *drawn* at the top of the
  -- buffer. A frame with toprow 0 is only damning once the buffer is tall
  -- enough to have shown the anchored position instead — while the wipe has it
  -- collapsed to the window height, the top is the only thing nvim can draw.
  for win, want in pairs({ [pi_win] = 3, [pi_win2] = 120 }) do
    local height = vim.api.nvim_win_get_height(win)
    local stranded = 0
    for _, frame in ipairs(frames[win]) do
      if frame.toprow == 0 and frame.count > height + want then
        stranded = stranded + 1
      end
    end
    assert(
      stranded == 0,
      ('%d of %d frames were drawn at the top of the buffer (window height %d, anchor %d from the end)'):format(
        stranded,
        #frames[win],
        height,
        want
      )
    )
  end
  io.stdout:write(
    ('PASS: no frame drawn at the top (%d and %d frames judged)\n'):format(#frames[pi_win], #frames[pi_win2])
  )

  -- A window that did not change size must not be anchored. `WinResized` fires
  -- for any layout change in the tab page, and a pi window that kept its size
  -- gives pi nothing to redraw -- so the hold would sit unanswered, then drag
  -- that window to the recorded offset on whatever output turned up next.
  --
  -- A float is the only resize that is genuinely isolated: nvim redistributes
  -- space between siblings, so resizing any normal window resizes the pi ones
  -- too (`nvim_win_set_height` in a column layout reports every window in
  -- `v:event.windows`). Resizing a float reports only the float.
  pause(600) -- let the hold above lapse; a resize mid-hold is deliberately ignored
  local settled_count = vim.api.nvim_buf_line_count(buf)
  vim.api.nvim_win_set_cursor(pi_win, { settled_count - 40, 0 })
  local untouched = vim.api.nvim_win_get_cursor(pi_win)[1]
  local pi_size = { vim.api.nvim_win_get_width(pi_win), vim.api.nvim_win_get_height(pi_win) }

  local float = vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), false, {
    relative = 'editor',
    row = 1,
    col = 1,
    width = 20,
    height = 5,
  })
  pause(200)
  vim.api.nvim_win_set_config(float, { relative = 'editor', row = 1, col = 1, width = 40, height = 10 })

  -- ...and make pi write *something* straight after, inside the window a hold
  -- would have been live for. With no output there is nothing for a stray hold
  -- to drag the cursor to, and the assertion below would pass either way.
  vim.fn.writefile({ '' }, fake_pi_dir .. '/stream')
  wait_for(function()
    return vim.api.nvim_buf_line_count(buf) > settled_count
  end, 'fake pi never emitted the streaming output')
  pause(1200)

  assert(
    vim.api.nvim_win_get_width(pi_win) == pi_size[1] and vim.api.nvim_win_get_height(pi_win) == pi_size[2],
    'the pi window changed size, so this does not test an unrelated resize'
  )
  assert(
    vim.api.nvim_win_get_cursor(pi_win)[1] == untouched,
    ('an unrelated resize moved the pi cursor from %d to %d'):format(untouched, vim.api.nvim_win_get_cursor(pi_win)[1])
  )
  io.stdout:write('PASS: a resize that spared the pi window left its cursor alone\n')
end)

function step()
  local ok, err = coroutine.resume(body)
  if not ok then
    io.stderr:write('FAIL: ', tostring(err), '\n')
    vim.cmd('cquit 1')
  elseif coroutine.status(body) == 'dead' then
    vim.cmd('qa!')
  end
end

step()
-- Nothing types into this nvim, so a body that stops resuming would idle in the
-- main loop forever.
vim.defer_fn(function()
  io.stderr:write('FAIL: test body never finished\n')
  vim.cmd('cquit 1')
end, 25000)
