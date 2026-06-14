if 'vantablack' ~= require('lib.colors').omarchy_colorscheme().colorscheme then
  return {}
end

local lib = { colors = require('lib.colors') }

lib.colors.update({
  done = '#83efef',
  todo = '#ffbcb5',
})

return {}
