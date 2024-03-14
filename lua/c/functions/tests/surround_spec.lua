Keys = function(c)
  return c
end

-- import the luassert.mock module
local mock = require 'luassert.mock'

describe('surround c.functions., function()
  local M

  before_each(function()
    M = require 'c.functions.surround'
  end)

  describe('M.adds_additional_space', function()
    it('should return true for space-surrounding characters', function()
      assert.is_true(M.adds_additional_space '(')
      assert.is_true(M.adds_additional_space ')')
      assert.is_true(M.adds_additional_space '{')
      assert.is_true(M.adds_additional_space '}')
      assert.is_true(M.adds_additional_space '[')
      assert.is_true(M.adds_additional_space ']')
    end)

    it('should return false for other characters', function()
      assert.is_false(M.adds_additional_space 'a')
      assert.is_false(M.adds_additional_space 'b')
      assert.is_false(M.adds_additional_space 'c')
    end)
  end)

  describe('M.surround', function()
    local api
    local delete_space = 'lds '
    local first_surround = 'S'
    local second_surround = 'ysi'

    before_each(function()
      api = mock(vim.api, true)
    end)

    after_each(function()
      mock.revert(api)
    end)

    it('should surround normal character', function()
      local char = '"'
      M.surround(char)
      assert.stub(api.nvim_feedkeys).was_called_with(first_surround .. char, 'v', true)
    end)

    it('should call second surround on #char > 1', function()
      local char = '**'
      M.surround(char)
      assert.stub(api.nvim_feedkeys).was_called_with(second_surround .. char, 'v', true)
    end)

    it('should delete space if char adds_additional_space', function()
      M.surround '{'
      assert.stub(api.nvim_feedkeys).was_called_with(delete_space, 'v', true)
    end)
  end)
end)
