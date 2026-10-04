# hunk diff viewer in a Neovim tabpage

[hunk](https://www.hunk.dev/docs/) is a terminal diff viewer. `<leader>gh`
(`after/plugin/hunk.lua`) runs `hunk diff` as a terminal job in its own
tabpage, the lazygit tab pattern (`after/plugin/lazygit.lua`), and wires hunk's
"edit this file" command back into the Neovim that started it: the file opens
in the **first tabpage**, where the code is, instead of nesting an editor
inside hunk's terminal.

## Which hunk key opens the file

`e` — `hunk.review.editSelectedFile`, "open the selected file in your editor".
It uses the line cursor, so it carries the location, not only the file.

**`gf` is not bindable inside hunk.** Its `[keybindings]` table takes single
chords (`modifier+base`), and a multi-character base must be a known named key
(`tab`, `pageup`, …) — `parseKeyChord` in
`packages/hunk/src/extension-api/keys.ts` rejects `"gf"` as `Unknown key`.
There are no two-key sequences. Another single chord is one line in
`~/.config/hunk/config.toml`, keys listed there replace the defaults:

```toml
[keybindings]
"hunk.review.editSelectedFile" = ["e", "f"]
```

## Why the $EDITOR shim is named `nvim`

hunk has no editor config key: `openSelectedFileInEditor`
(`packages/hunk/src/ui/lib/openInEditor.ts`) reads `$EDITOR`, splits it
respecting quotes, and spawns it directly. The line number only comes along
for vi-style editors — `buildEditorCommand` matches `basename($EDITOR)` against
`vim`/`nvim`/`vi` and then appends `+{line} {absolute path}`; anything else
gets the bare path. So `scripts/hunk-editor/nvim` carries that name to be
handed the location, and is referenced by absolute path (keep its directory
off `$PATH`, or its own `nvim` calls would recurse into the shim).

The shim talks to the parent Neovim over `$NVIM`, the server address Neovim
exports into every job it spawns (`:h $NVIM`):

```sh
nvim --server "$NVIM" --remote-expr "v:lua.require'lib.hunk'.open('{path}', {line})"
```

`lib.hunk.open` switches to the first tabpage, `:edit`s the file and moves the
cursor. `--remote-expr` prints its result, hence the `''` return. Single
quotes in the path are doubled by the shim (the Vimscript string escape).

hunk suspends its renderer around any vi-style editor and resumes when the
child exits, which here is as soon as the RPC returns.

## Testing

Real hunk, real keystrokes, headless — hunk renders fine without a UI client:

```sh
cd /tmp/hunkrepo   # a git repo with an unstaged change
nvim --headless -u NONE --cmd "set rtp^=/home/celso/projects/nvim" \
  -c "lua vim.g.mapleader = ','; _G.lib = require('lib'); _G.state = require('state')" \
  -c "luafile /home/celso/projects/nvim/after/plugin/hunk.lua" \
  -c "normal ,gh" -c "sleep 6" \
  -c "lua vim.api.nvim_chan_send(vim.bo[vim.fn.bufnr('term://*')].channel, 'jjjje')" \
  -c "sleep 4" \
  -c "lua print(vim.fn.tabpagenr(), vim.api.nvim_buf_get_name(0), vim.fn.line('.'))" \
  -c "qa!"
```

Sending `q` instead asserts the other half: hunk exits, `on_exit` closes the
tab and wipes the dead terminal buffer.
