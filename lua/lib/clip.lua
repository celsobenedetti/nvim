return {
  clip = function()
    local file = vim.fn.expand '%:p'

    -- wayland
    vim.cmd('!wl-copy ' .. file)

    --  works on x11
    -- vim.cmd("!echo -n '" .. file .. "' | xclip -selection clipboard")
  end,
}
