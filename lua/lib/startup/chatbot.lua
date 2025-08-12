---@module lib.startup.chatbot
---this starts the chatbot servers with overseer
---

--- delays
local delay = {
  100,
  400,
  500,
}

vim.defer_fn(function()
  vim.cmd 'OverseerLoadBundle chatbot'
end, delay[1])

vim.defer_fn(function()
  vim.cmd 'OverseerToggle'
end, delay[2])

vim.defer_fn(function()
  vim.cmd 'wincmd k'
  vim.cmd 'wincmd q'
end, delay[3])
