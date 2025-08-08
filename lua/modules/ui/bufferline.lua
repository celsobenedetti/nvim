---@param n number index of buffer in bufferline
local function go_to_buffer(n)
  return function()
    require('bufferline').go_to(n)
  end
end

return {
  'akinsho/bufferline.nvim',
  keys = {
    { '<leader>1', go_to_buffer(1), desc = 'bufferline: go to buffer 1' },
    { '<leader>2', go_to_buffer(2), desc = 'bufferline: go to buffer 2' },
    { '<leader>3', go_to_buffer(3), desc = 'bufferline: go to buffer 3' },
    { '<leader>4', go_to_buffer(4), desc = 'bufferline: go to buffer 4' },
    { '<leader>5', go_to_buffer(5), desc = 'bufferline: go to buffer 5' },
    { '<leader>6', go_to_buffer(6), desc = 'bufferline: go to buffer 6' },
    { '<leader>7', go_to_buffer(7), desc = 'bufferline: go to buffer 7' },
    { '<leader>8', go_to_buffer(8), desc = 'bufferline: go to buffer 8' },
    { '<leader>9', go_to_buffer(9), desc = 'bufferline: go to buffer 9' },
    { '<leader>0', go_to_buffer(1), desc = 'bufferline: go to first buffer' },
    { '<leader>)', go_to_buffer(-1), desc = 'bufferline: go to last buffer' },
  },
}
