local delay = tonumber(os.getenv("ZEN_DELAY")) or 100

vim.defer_fn(function()
  Snacks.zen.zen()
end, delay)
