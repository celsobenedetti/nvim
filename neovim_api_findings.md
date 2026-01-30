Neovim API Findings - Markdown-local highlights

- nvim_set_hl(ns_id, name, val): Defines a highlight in a namespace. With ns_id=0 it is global. Using a custom namespace allows window-local overrides when that namespace is active. See :h nvim_set_hl
- nvim_win_set_hl_ns(win, ns_id): Sets the highlight namespace for a window. All drawing in that window uses highlights from ns_id, falling back to 0. This enables window-local highlight customizations. See :h nvim_win_set_hl_ns
- nvim_set_hl_ns(ns_id): Sets the highlight namespace for the current window (older API). See :h nvim_set_hl_ns
- :syntax match: Adds a syntax match for the buffer/filetype. The highlight group used will be resolved using the window's active highlight namespace. See :h :syn-match

Approach used in c4efde7100042142f0880fdab6871832754cef09:
1) Define highlights in a dedicated namespace (not 0) in ftplugin/markdown.lua
2) Activate that namespace per-window when a markdown buffer is displayed (BufWinEnter) and reset on BufWinLeave
3) This ensures the custom highlights only affect markdown windows and do not leak to other filetypes
