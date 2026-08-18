# Overseer statusline indicator — design

Date: 2026-08-18

## Goal

Show an indicator in the right section of the statusline when any
overseer.nvim task is actively running (status `RUNNING` or `PENDING`).

## Approach

Detect active tasks via overseer's `list_tasks({ status = { 'RUNNING', 'PENDING' } })`,
wrapped in a reusable `lib.overseer.get_active_tasks()` helper. Cache the count
in `state` (global, not per-buffer) via the `User OverseerListUpdate` autocmd
overseer fires on every task add / remove / status change
(`task_list.dispatch()`). The segment renders live from the cached count,
following the existing `_macro` pattern.

overseer is lazy-loaded (via `cmd`), so the autocmd only ever fires while
overseer is loaded. No polling, no eager `require`. `lib.overseer` is defined
when the lazy plugin spec loads at startup (before any task event can fire).

## Data flow

1. `OverseerRun` loads overseer, creates a task (status `RUNNING`) →
   `dispatch()` fires `User OverseerListUpdate`.
2. Autocmd counts tasks with status `RUNNING`/`PENDING`, stores in
   `state.overseer_task_count`.
3. `MyStatusLine()` renders it as the rightmost right-section segment
   (after `branch`).
4. Task finishes → status change → `dispatch()` fires → count becomes 0 →
   indicator disappears.

## Changes

### `lua/plugins/secondary/overseer.lua`

Add to `lib.overseer`:

```lua
--- Tasks queued or currently running
---@return overseer.Task[]
get_active_tasks = function()
  if not package.loaded['overseer'] then
    return {}
  end
  return require('overseer').list_tasks({ status = { 'RUNNING', 'PENDING' } })
end,
```

### `lua/config.lua`

Add `icons.overseer` (play glyph).

### `lua/state.lua`

```lua
---@field overseer_task_count number?
overseer_task_count = nil,
```

### `after/plugin/statusline.lua`

Module segment:

```lua
_overseer_tasks = function()
  local count = state.overseer_task_count
  if not count or count == 0 then
    return ''
  end
  return hl(config.hl.text.highlight, config.icons.overseer .. count)
end,
```

Autocmd in `setup_caching_and_updating()`:

```lua
vim.api.nvim_create_autocmd('User', {
  pattern = 'OverseerListUpdate',
  callback = function()
    state.overseer_task_count = #lib.overseer.get_active_tasks()
  end,
})
```

Placement: last segment of the right section in `MyStatusLine()`, after
`branch` (rightmost). Highlight: `config.hl.text.highlight` (Title),
consistent with branch / lsp icons.

## Testing

Mirror existing test replicas in `tests/statusline/`:

- `test_modules.lua`: `_overseer_tasks` cases — count nil, 0, and 3.
- `test_integration.lua`: indicator appears after `branch` on the right,
  no trailing separator, empty when no tasks.

Run with `make test`.