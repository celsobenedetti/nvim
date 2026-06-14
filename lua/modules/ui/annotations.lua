return {
  'celsobenedetti/annotations.nvim',
  config = true,
  keys = {
    { 'H', ':<c-u>AnnotationsAdd<CR>', mode = 'x' },
  },

  cmd = {
    'AnnotationsAdd',
    'AnnotationsToggle',
    'AnnotationsClear',
    'AnnotationsQuickfix',
    'AnnotationsSidebar',
  },
}
