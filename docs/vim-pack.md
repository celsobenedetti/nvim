# Replacing lazy.nvim with native vim.pack

Research for curriculum task: _"replace lazy.nvim for native vim.pack"_.

Environment verified: NVIM v0.12.1-dev (`vim.pack` is shipped; still marked
experimental but stable for daily use, `:h vim.pack`).

## What vim.pack provides natively

- Plugin manager: install / update / delete. Plugins live in
  `site/pack/core/opt/` under the data standard path (never auto-loaded at
  startup — `opt` packages are on-demand by definition).
- Lockfile: `nvim-pack-lock.json` in the config dir; track it in VCS to sync
  across machines at pinned revisions.
- `vim.pack.add(specs, { ... })` — register + install + load.
- `vim.pack.update()`, `vim.pack.del()`, `vim.pack.get()` — management.
- `PackChangedPre` / `PackChanged` autocmds — plugin hooks (build steps, etc.).

It does NOT provide lazy-loading _triggers_ (ft / cmd / keys / event). Those
must be built with native primitives.

## How loading works (empirically verified)

Startup order (`starting.txt`): init.lua → step 10 `v:vim_did_init = 1` → step
11 `:runtime! plugin/**/*.{vim,lua}` (load-plugins) → step 18 `VimEnter` (+cmd
commands run just before VimEnter autocmds).

`vim.pack.add()` calls `:packadd` internally. The `load` option:

| Call site                          | `load` default | Effect                                                       |
| ---------------------------------- | -------------- | ------------------------------------------------------------ |
| during init.lua                    | `false`        | `:packadd!` → dir added to rtp, then step 11 sources plugin/ |
| after init (`v:vim_did_init == 1`) | `true`         | `:packadd` → dir added to rtp + plugin/ sourced immediately  |

Key consequence, tested: **`vim.pack.add()` called during init.lua sources the
plugin's `plugin/` files at the load-plugins step regardless of `load`.** So
plain `add()` during init is _eager_, not lazy.

### The lazy-loading primitive

Register a plugin during init but never touch rtp, then `packadd` it on demand:

```lua
-- in init.lua: install + track the plugin, load nothing.
vim.pack.add({ { src = 'github.com/stevearc/aerial.nvim' } }, { load = function() end })

-- on trigger: load its plugin/ + ftdetect/ files.
vim.cmd.packadd('aerial.nvim')
```

With `load = function() end` the plugin is installed (git clone if missing) and
recorded in the lockfile, but its directory is never added to `'runtimepath'`,
so step 11 never sees it. Verified: nothing from the plugin runs at startup;
first `packadd` loads it exactly once.

## Trigger primitives (replace lazy.nvim's ft / cmd / keys / event)

### `cmd` — lazy load on a plugin command (the "AerialToggle" question)

lazy.nvim creates stub commands that load the plugin on first use. Native
equivalent: define the stub yourself; on first invocation delete the stub,
`packadd`, then re-execute the real command.

```lua
vim.api.nvim_create_user_command('AerialToggle', function()
  vim.api.nvim_del_user_command('AerialToggle') -- let the plugin define it
  vim.cmd.packadd('aerial.nvim')
  vim.cmd('AerialToggle') -- the now-real command
end, {})
```

Verified: plugin loads and the real command runs on the first call; warm calls
work too. Caveats: completion/nargs are lost on the stub; prefer the plugin's
Lua entry point over the command when it has one (see `keys` below). A small
helper can generate these stubs from a list of `{ command, plugin }` pairs.

### `keys` — lazy load on a keymap

```lua
vim.keymap.set('n', '<leader>out', function()
  vim.cmd.packadd('aerial.nvim')
  require('aerial').toggle()
end, { desc = 'Toggle Outline' })
```

For command-only plugins keep the `:cmd` form inside the callback:
`vim.keymap.set('n', '<leader>out', ':AerialToggle<CR>')` — but then the packadd
never fires; use the stub command pattern for those.

### `ft` — lazy load on filetype

```lua
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'csv', 'sql', 'mysql', 'plsql' },
  callback = function() vim.cmd.packadd('csvview.nvim') end,
})
```

Covers plugins like csvview, dadbod-completion, SchemaStore.

### `event` — lazy load on any event

- `VeryLazy` → `VimEnter` autocmd.
- `InsertEnter` → `InsertEnter` autocmd (supermaven, autopairs).
- `BufReadPre/BufNewFile <pattern>` → autocmd with that pattern (obsidian).
- `CmdlineEnter` → `CmdlineEnter` autocmd (blink cmdline).

### cwd condition

```lua
vim.api.nvim_create_autocmd('DirChanged', {
  callback = function()
    if lib.cwd.matches({ 'work' }) then vim.cmd.packadd('obsidian.nvim') end
  end,
})
```

## What replaces each lazy.nvim feature

| lazy.nvim feature                  | native equivalent                                                                           |
| ---------------------------------- | ------------------------------------------------------------------------------------------- |
| `spec` / `import`                  | plain Lua modules in `lua/plugins/`, `require`d from init.lua                               |
| install / update / lockfile        | `vim.pack` + `nvim-pack-lock.json`                                                          |
| `lazy = false` (eager)             | plain `vim.pack.add(...)` during init                                                       |
| `lazy = true` (deferred)           | `vim.pack.add(..., { load = function() end })` + trigger                                    |
| `cmd = { 'X' }`                    | stub user command → `packadd` → re-execute                                                  |
| `keys = { ... }`                   | keymap callback → `packadd` + Lua call                                                      |
| `ft = { ... }`                     | `FileType` autocmd → `packadd`                                                              |
| `event = { ... }`                  | autocmd on that event → `packadd`                                                           |
| `opts` / `config`                  | run setup in the trigger callback after `packadd` (or in `after/plugin/` for eager plugins) |
| `dependencies`                     | `packadd` deps before the plugin; order matters, no graph                                   |
| `enabled` conditions               | Lua `if` guard around the spec/trigger registration                                         |
| `build` hooks                      | `PackChanged` autocmd                                                                       |
| `checker` (update checker)         | manual `vim.pack.update()`; no periodic checker                                             |
| `performance.rtp.disabled_plugins` | keep `pack/*/opt`, or skip the bundled ones with `--cmd` / keep only what's used            |

## Caveats

- A lazy plugin whose `load` is a no-op is **not** require-able until `packadd`
  (its `lua/` dir isn't in rtp). Register the trigger first.
- Don't rely on `+cmd`/`-c` startup commands that trigger a lazy plugin: they
  run before `VimEnter`, so a plugin installed only at startup isn't ready. In
  practice interactive triggers fire after startup — non-issue for keymaps/ft.
- `:packadd` sources `plugin/` + runs `ftdetect/`. Ftdetect for an already-set
  filetype may re-run; harmless for most plugins.
- Per-plugin config must be invoked explicitly (no `opts` magic).
- `vim.pack` manages everything in `site/pack/core/opt`; it assumes that
  directory is exclusively its own.

