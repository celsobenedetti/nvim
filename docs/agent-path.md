# `<leader>op` (opencode) fails only under neovide

## Symptom

`<leader>op` closed the buffer immediately ("errors out"); `<leader>pi` worked.
Only inside neovide, not in a terminal-launched nvim.

## Root cause

`after/plugin/agents.lua` opens the agent with `vim.cmd.term(agent)`, i.e.
`$SHELL -c opencode` in nvim's own environment. If the command is not found,
bash exits at once, `TermClose` fires, and the guard at `agents.lua:32-45`
force-deletes the buffer — so the failure looks like a silent buffer close.

Neovide launched from the desktop does **not** inherit the shell rc, so its
PATH is the systemd user-manager/session PATH:

```
/usr/share/omarchy/bin : ~/.local/share/mise/shims : ~/.cargo/bin :
/usr/local/sbin : /usr/local/bin : /usr/bin : ~/.local/bin : ...
```

- `pi` / `claude` resolve because their `~/.local/share/mise/shims` entry is on
  that PATH.
- `opencode` lives only in `~/.opencode/bin`, added **only by
  `~/.zshrc` / `~/.bashrc`**. That directory is missing from the GUI PATH, so
  `opencode: command not found`.

Confirm with the running process (neovide is a child of Hyprland, which is
itself missing the entry):

```
tr '\0' '\n' < /proc/$(pgrep -x neovide)/environ | grep '^PATH='
```

## Fix

`~/.config/environment.d/custom.conf` (read by the systemd user manager at
login, so GUI sessions inherit it):

```
PATH=$HOME/.opencode/bin:$HOME/.local/bin:$PATH
```

Takes effect on the next graphical login; the running neovide/Hyprland keep
their current environment until then. To test without re-logging, launch
neovide from a shell that sourced `.zshrc`.

## See also

- `after/plugin/agents.lua` — the `TermClose` buffer-delete guard that hides
  the real "command not found" error.
