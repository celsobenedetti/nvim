# MRU buffer navigation: `Bprev` / `Bnext`

Status: plan

## Goal

Buffer navigation like `bnext`/`bprev`, but by most-recently-accessed order
instead of buffer number. Visiting a buffer makes it the MRU head, so:

- on buffer 3, going to buffer 2 -> `Bprev` goes back to 3
- `Bnext` after that returns to 2

## Research: no native mechanism

- `:h :bnext` iterates strictly by buffer number.
- The jumplist (`:h jumplist`) is window-local, cursor-position-based, and
  navigated via `Ctrl-o`/`Ctrl-i`; it is not a buffer MRU.
- `:e#` / alternate file tracks only the single previous buffer.
- No `getbufinfo` ordering flag exposes access order.

## Data structure: two stacks + current pointer

A single MRU list fails because visiting makes a buffer most-recent, which
erases the forward direction. The browser-history model fixes it: `back` and
`forward` stacks plus the current buffer, where `Bprev`/`Bnext` *move* the
current buffer between stacks rather than recording a fresh visit.

```
record(b):  when b ~= current:  back.push(current); forward = []; current = b
prev():     target = back.pop(); forward.push(current); current = target; return target
next():     target = forward.pop(); back.push(current); current = target; return target
```

Trace `3 -> 2`:
```
: b 2    back=[3]       forward=[]   current=2
Bprev    back=[]        forward=[2]  current=3
Bnext    back=[3]       forward=[]   current=2
```

`current` is updated synchronously inside `prev`/`next` *before* switching the
buffer, so the following `BufEnter` is a no-op (guarded by `b ~= current`) — no
suppression flag needed.

Deleted buffers are pruned on access: when popping, invalid/unloaded buffers are
dropped until a valid one is found.

## Decisions

- Global history (whole session, all windows/tabs).
- Session-only (not persisted to shada).
- Prune on access.
- Commands `:Bprev` / `:Bnext` backed by `lib.browser_history` (pure, testable).

## Files

- `lua/lib/browser_history.lua` — pure two-stack state machine (`record`, `prev`, `next`, `reset`).
- `after/plugin/browser-history.lua` — `BufEnter` autocmd + `:Bprev`/`:Bnext` commands.
- `tests/lib/test_browser_history.lua` — luajit unit tests.

## Test plan

Run: `luajit tests/lib/test_browser_history.lua` and `make test`.
