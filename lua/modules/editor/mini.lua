return {
  -- editing
  {
    'nvim-mini/mini.ai',
    version = false,
    config = function()
      require('mini.ai').setup({})
    end,
  },

  -- ui
  { 'nvim-mini/mini.hipatterns', version = false, config = true },
  {
    'nvim-mini/mini.icons',
    version = false,
    opts = {
      file = {
        ['.eslintrc.js'] = { glyph = '󰱺', hl = 'MiniIconsYellow' },
        ['eslint.config.ts'] = { glyph = '󰱺', hl = 'MiniIconsYellow' },
        ['.node-version'] = { glyph = '', hl = 'MiniIconsGreen' },
        ['.nvmrc'] = { glyph = '', hl = 'MiniIconsGreen' },
        ['.prettierrc'] = { glyph = '', hl = 'MiniIconsPurple' },
        ['package.json'] = { glyph = '', hl = 'MiniIconsGreen' },
        ['tsconfig.json'] = { glyph = '', hl = 'MiniIconsAzure' },
        ['tsconfig.node.json'] = { glyph = '', hl = 'MiniIconsAzure' },
        ['tsconfig.app.json'] = { glyph = '', hl = 'MiniIconsAzure' },
        ['vite.config.ts'] = { glyph = '', hl = 'MiniIconsGreen' },
        ['vitest.config.ts'] = { glyph = '', hl = 'MiniIconsGreen' },
        ['pnpm-lock.yaml'] = { glyph = '', hl = 'MiniIconsYellow' },
        ['pnpm-workspace.yaml'] = { glyph = '', hl = 'MiniIconsYellow' },
      },
    },
    init = function()
      package.preload['nvim-web-devicons'] = function()
        require('mini.icons').mock_nvim_web_devicons()
        return package.loaded['nvim-web-devicons']
      end
    end,
  },
}
