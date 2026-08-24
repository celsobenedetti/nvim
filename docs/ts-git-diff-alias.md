# Treating fugitive's `filetype=git` buffers as diff (treesitter alias)

Fugitive hardcodes `setlocal filetype=git` on its patch buffers
(`:Git log -p`, `:Git show`, `:Git diff`) with no configuration option, so
we cannot ask it to use `filetype=diff`. Re-typing those buffers to `diff`
from our side would also break things: fugitive's own `<CR>`/`gx` jump
machinery checks `&filetype ==# 'git'` (autoload/fugitive.vim), and
`syntax/git.vim` highlights the commit metadata around the embedded diffs.

Instead we register a **treesitter language alias**:

```lua
vim.treesitter.language.register('diff', 'git')  -- after/plugin/autocmds.lua
```

and add `'git'` to `config.treesitter.highlight` so `vim.treesitter.start()`
runs on git buffers.

## What this buys

- The treesitter highlighter parses these buffers with the `diff` grammar
  (`queries/diff/highlights.scm`), on top of regex `syntax/git.vim`.
- Treesitter folding works: the fold machinery (`vim.treesitter.foldexpr`,
  wired globally in lua/plugins/treesitter.lua) resolves its parser from the
  *filetype*, and the alias makes that resolution return the `diff` parser —
  so `queries/diff/folds.scm` folds each file's block and hunks inside
  `:Git log -p` output.
- `&filetype` stays `git`, keeping fugitive navigation,
  `after/ftplugin/git.lua` word-level emphasis (`docs/diff-emph.md`), and
  the git-tab naming autocmds untouched.

## Notes

- The alias only affects filetype→parser resolution; regex syntax still
  loads normally. Where both paint, treesitter extmarks (priority 100) win.
- Non-patch `ft=git` buffers (e.g. `:Git log --name-only`) parse to mostly
  ERROR nodes — harmless, just no captures.
- Requires the `diff` parser (already in `config.treesitter.ensure_installed`).

## Testing

`make test-integration` includes `tests/integration/test_ts_git_alias.lua`:
registers the alias headlessly, builds a fugitive-shaped patch buffer, and
asserts (1) the highlighter attaches a `diff` parser and (2)
`foldclosedend()` on the `diff --git` header spans through the hunk.
