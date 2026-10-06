# Stray insert mode when leaving a terminal window

Findings from fixing: `:tabnew` from a `:terminal` window dropped the new,
empty buffer into insert mode. Same for `:Git log -n 1` — fugitive's output
buffer opened in insert mode, but only when the command was run from a
terminal window.

## The autocmds

`after/plugin/terminal.lua` auto-enters insert mode on terminal enter:

```lua
vim.api.nvim_create_autocmd('BufWinEnter', { pattern = 'term://*', callback = lib.term.startinsert })
vim.api.nvim_create_autocmd('WinEnter',    { pattern = 'term://*', callback = lib.term.startinsert })
```

The `term://*` pattern is doing the "is this a terminal?" test. That test is
wrong twice over.

## Why it misfires

**`WinEnter` fires before the new window gets its buffer.** Opening a window
from a terminal window (`:tabnew`, `:split`, the split fugitive opens for a
pager command like `:Git log`) fires `WinEnter` for the *new* window while the
*terminal* is still the current buffer. Logged at the autocmd:

```
MATCH WinEnter ev.buf=1 ev.file=term://~/projects/nvim//46166:/usr/bin/bash
               CURBUF=1 curname=term://~/projects/nvim//46166:/usr/bin/bash curbt=terminal
```

So the pattern matches, and the callback runs.

**`:startinsert` does not take effect until nvim returns to the main loop**
(`:h :startinsert` — it applies "when the command finishes"). By then the
window shows the new buffer, and insert mode lands there:

```
INSERTENTER buf=7 bt= name=
```

Nothing about the buffer insert mode actually reached was ever checked: the
pattern tested the buffer being *left*, and the check ran at a moment that
said nothing about where the cursor would end up.

## The fix

`lib.term.startinsert` defers its own decision with `vim.schedule`, then
re-reads the window and buffer — including an explicit
`buftype == 'terminal'` check — at the point insert mode would apply:

```lua
vim.schedule(function()
  ...
  if not is_term(buffer) then
    return
  end
  vim.cmd('startinsert')
end)
```

Entering an existing terminal window is unaffected: there `WinEnter` fires
with the terminal already current, so the deferred re-check still sees it.

Because the deferral now lives inside `startinsert`, the `TermOpen` handler no
longer needs its own `vim.schedule(lib.term.startinsert)` wrapper.

## Related gotcha

`BufWinEnter term://*` never matches when a terminal is *created*: `:terminal`
displays the buffer first and renames it to `term://…` afterwards, so the
pattern sees the old (empty) name. That is why the `TermOpen` autocmd exists
at all. `BufWinEnter` only matches when an already-named terminal buffer is
re-displayed in a window (`:b <termbuf>`).

## Reproducing

Insert mode is entered asynchronously, and headless nvim never fires it, so
assert from a real UI under tmux with an `InsertEnter` autocmd writing to a
log file — `mode()` sampled from a `-c` chain is always stale.
