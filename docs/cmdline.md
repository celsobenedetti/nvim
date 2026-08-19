# Hijacking `<Tab>` on the cmdline (fzf-tab)

Findings from implementing `lib.cmdline.fzf_tab`: `<Tab>` on the command line
launches an fzf-lua file/dir picker when the line ends in `**`, and runs
`:e <selected>` on confirm. Fallback (no `**`) keeps the native cmdline
completion.

## How it works

- `vim.keymap.set('c', '<Tab>', handler)` — plain (non-`expr`) cmdline
  mappings **can** call `vim.fn.getcmdline()` / `getcmdtype()` / `getcmdpos()`.
  The docs (`:h getcmdline()`) only mention `c_CTRL-\_e`, `c_CTRL-R_=` and
  expression mappings, but a Lua callback works too. `getcmdline()` returns the
  line **without** the leading `:`; `getcmdtype()` returns `:` for Ex commands.
- To **cancel** the pending cmdline from the callback:
  `vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-c>', ...), 'ni', false)`.
  A floating window (fzf-lua) cannot open while the cmdline is active, so the
  picker is launched inside `vim.schedule(...)` — verified that the cancel is
  processed *before* the scheduled callback runs, leaving us in normal mode.
- **Fallback to native completion without recursion**: `<C-n>`/`<C-p>` are not
  usable (they're history/remapped here), and feeding `<Tab>` again would
  re-trigger this very mapping. The canonical trick is `'wildcharm'`
  (`:h 'wildcharm'`, default 0): a key that behaves *exactly* like
  `'wildchar'` (<Tab>) but only fires from mappings/feedkeys, never when typed
  literally. Set `vim.opt.wildcharm = 26` (0x1A, `<C-z>`) and feed `<C-z>` for
  the default completion.
- feedkeys flags: `'n'` = no remap (so the fed `<C-z>` isn't re-mapped), `'i'`
  = insert at the *front* of typeahead so the fed key executes before any
  queued keys (without `'i'` it lands *after* queued typeahead, e.g. a pending
  `<CR>`, and the completion never happens).

## fzf-lua specifics

- `opts.cmd` is used verbatim (`providers/files.lua` `get_files_cmd`); `cwd`
  is passed to the spawned fzf process (`core.fzf_exec`), so entries come back
  relative to it. Resolve to absolute with `fzf-lua.path.entry_to_file` +
  `path.join({ opts.cwd or opts._cwd or vim.uv.cwd(), rel })` —
  `lib.fzf.selected_path`.
- `winopts.title` renders as a **border label** (`win.lua`
  `update_fzf_border_label`) — with `border = 'none'` (the `:e` profile) it
  never shows. Use the fzf `prompt` to indicate the search root instead.
- Opening a *directory* selection needs `vim.cmd.e(path)` (not fzf-lua's
  default `bufadd`-based actions) so the netrw/oil hijack runs; escape with
  `vim.fn.fnameescape` for spaces.
