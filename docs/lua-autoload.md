# How Neovim auto-loads Lua config files

Plain facts from the help docs (`starting.txt`, `options.txt` `'runtimepath'`,
`repeat.txt` `:runtime`, `lua.txt` `lua-module-load`, `filetype.txt`,
`lsp.txt`). Focus: which Lua files run without being explicitly `require`d.

## 1. The config file itself: `init.lua`

At startup Neovim reads exactly one config file,
`$XDG_CONFIG_HOME/nvim/init.lua` (or `init.vim` — never both). It is the only
Lua file that is _unconditionally_ executed. Everything else in `lua/` only runs
if `init.lua` (or a plugin) explicitly loads it.

## 2. `plugin/` — auto-sourced at startup

After the config file, startup runs:

```
:runtime! plugin/**/*.{vim,lua}
```

(`starting.txt` step 11). Every directory in `'runtimepath'` is searched for a
`plugin/` subdirectory; all `*.vim` and `*.lua` files inside are sourced, also
in subdirectories, alphabetically per directory, `*.vim` first then `*.lua`.

## 3. `after/` — same files, sourced last

The `after/` subdirectory of each `'runtimepath'` entry is searched _second_, in
reverse runtimepath order, after packages are loaded:

```
plugin/**/*.{vim,lua}   (in after/ dirs)
```

So `after/plugin/*.lua` is auto-sourced by the exact same mechanism as
`plugin/*.lua`, but later, so its settings win over the config's own `plugin/`
files and over installed plugins. This is the `after-directory` feature
(`options.txt`): user preferences live at the end of `'runtimepath'`.

Note: there is no special `lua/after/` magic. The auto-sourced "after" files
live at the _root_ of the runtime dir, e.g. `after/plugin/foo.lua`, not
`lua/after/plugin/foo.lua`. A file under `lua/` is a module; it is never
auto-sourced.

## 4. `lua/` — never auto-loaded, only via `require()`

`'runtimepath'` entries list `lua/` as a runtime directory (`options.txt`), but
the only way its files execute is `require('foo.bar')`. `require()` maps dots to
path separators and searches, in runtimepath order:

```
lua/foo/bar.lua
lua/foo/bar/init.lua
lua/foo/bar.so / .dll
```

first match wins; result cached after the first call (`lua.txt`
`lua-module-load`). Nothing in `lua/` runs by itself. `init.lua` is a convention
— `require('init')` finds `lua/init.lua` or `lua/init/init.lua`.

## 5. `ftplugin/` and `after/ftplugin/` — sourced per filetype

Step 6 of startup sources `ftplugin.vim`, which registers a `FileType` autocmd.
When a buffer's filetype is set, it runs:

```
:runtime! ftplugin/{name}.{vim,lua} ftplugin/{name}_*.{vim,lua} ftplugin/{name}/*.{vim,lua}
```

Because `after/` is at the end of `'runtimepath'`, `after/ftplugin/{name}.lua`
is sourced after any plugin's `ftplugin/{name}.lua` and can override it
(`filetype.txt`). So `after/ftplugin/python.lua` runs automatically whenever a
`.py` buffer is opened.

## 6. `lsp/` and `after/lsp/` — loaded per LSP config

`'runtimepath'` also lists `lsp/` (`options.txt`). Config files are not sourced
eagerly; they are read when `vim.lsp.enable('foo')` starts a client. All
`lsp/foo.lua` files in runtimepath are merged, then `after/lsp/foo.lua` files
override them (`lsp.txt` "How configs are merged"). So `after/lsp/eslint.lua` is
auto-consumed only when the `eslint` LSP is enabled.

## 7. `autoload/` — Vimscript only, loaded on first `#` call

`autoload/` is a Vimscript lazy-loading feature (`options.txt`, `userfunc.txt`
`autoload`). No file in `autoload/` runs at startup. Instead, calling a
function that is not yet defined and whose name contains `#` triggers a load:

```
:call foo#bar()
```

searches every `autoload/foo.vim` in `'runtimepath'`, in runtimepath order,
first match wins, and sources it. Every `#` in the name acts as a path
separator, so `:call foo#bar#baz()` loads `autoload/foo/bar.vim`. The file
must define a function whose name matches the call exactly (`E746` if the
`#`-prefix of the function and the file name disagree).

Only `.vim` files are autoloaded — an `autoload/foo.lua` is never picked up
by this mechanism. The Lua equivalent is `lua/` + `require()` (`lua-guide.txt`
`lua-guide-modules`); from Lua you can still trigger a Vimscript autoload with
`vim.fn['foo#bar']()` (`lua.txt` `vim.fn`).

Reading an undefined autoload variable also loads the script:

```
:let x = foo#bar#lvar
```

Assigning to such a variable does _not_ trigger a load — that is how you pass
settings to an autoload script before its functions are used.

Caveats (`userfunc.txt`):

- A script is loaded at most once per session (tracked in a loaded-script
  list). If it is missing, or exists but does not define the called function
  (`E117`), it is not attempted again — even after you fix the file. Restart
  Nvim or `:source` the file manually.
- Avoid calling autoload functions from the toplevel of another autoload
  script: the target may not be defined yet, so autoload is meant for
  on-demand calls, not startup code.
- The search also covers `'packpath'` (under `start/` and `opt/`, `pack.txt`),
  so package autoload functions can be called from your config before the
  package is on `'runtimepath'`.

## Summary table

| Directory                     | When it runs                                |
| ----------------------------- | ------------------------------------------- |
| `init.lua`                    | Always, at startup                          |
| `plugin/**/*.{vim,lua}`       | Startup step 11                             |
| `after/plugin/**/*.{vim,lua}` | Startup step 11, after packages, overriding |
| `lua/**`                      | Only via `require()`                        |
| `after/ftplugin/*.lua`        | On `FileType` autocmd, after base ftplugins |
| `after/lsp/*.lua`             | When that LSP is enabled                    |
| `autoload/*.vim`              | On first call of a `#` function             |

## What this means for this config

- `init.lua` is the single entry point; it `require('init')` and sets up
  lazy.nvim.
- `lua/init/*.lua` and `lua/plugins/*.lua` run because they are explicitly
  `require`d: `require('init')` from `init.lua`, and lazy.nvim's
  `{ import = 'plugins' }` / `{ import = 'plugins.secondary' }` load
  `lua/plugins/*.lua` / `lua/plugins/secondary/*.lua`.
- `after/plugin/*.lua` is auto-sourced by Neovim itself (mechanism in §3); it is
  not a lazy.nvim feature.
- `after/ftplugin/*.lua` runs on filetype detection (§5).
- `after/lsp/*.lua` runs when the matching LSP is enabled (§6).
- No `autoload/` in this config: it is a Vimscript-only mechanism (§7), and its
  Lua counterpart — `lua/` + `require()` — is exactly what lazy.nvim's imports
  and the deferred `require()`s already do.
- `lua/lib/*.lua` never runs on its own; it is only executed when some
  `require('lib.x')` happens.
