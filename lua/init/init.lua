vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

require('vim._core.ui2').enable()

require('init.globals')
require('init.lazy')
require('init.colors')
require('init.options')
require('init.sensible')
