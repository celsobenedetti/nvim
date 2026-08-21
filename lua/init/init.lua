vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

require('vim._core.ui2').enable()

require('init.globals')
require('init.pre')
require('init.lazy')
require('init.options')
require('init.sensible')
