---@module "tests.primitives"
---
---
local strings = require("lib.strings")
print("test: lib.strings")

describe("strings.trim", function()
  local cases = {
    { input = "  hello  ", expected = "hello", desc = "removes leading and trailing spaces" },
    { input = "\t world\n", expected = "world", desc = "removes leading and trailing whitespace characters" },
    { input = "    ", expected = "", desc = "returns empty string if input is only whitespace" },
    { input = "abc", expected = "abc", desc = "leaves string unchanged if no leading or trailing whitespace" },
    { input = "  a b  c  ", expected = "a b  c", desc = "retains internal spaces" },
    { input = "", expected = "", desc = "handles empty string input" },
  }
  for _, tcase in ipairs(cases) do
    it(tcase.desc, function()
      assert.equals(tcase.expected, strings.trim(tcase.input))
    end)
  end
end)

describe("strings.slugify", function()
  local cases = {
    {
      input = "Hello World",
      expected = "hello-world",
      desc = "lowercases and replaces spaces and non-alphanumerics with hyphens",
    },
    { input = "ABC 123!", expected = "abc-123", desc = "removes non-alphanumerics" },
    { input = "A    b", expected = "a-b", desc = "collapses multiple spaces to single hyphen" },
    { input = " **foo bar**! ", expected = "foo-bar", desc = "removes leading and trailing hyphens" },
    { input = "---baz---", expected = "baz", desc = "removes leading and trailing hyphens from dashes" },
    { input = "foo-bar.baz", expected = "foo-bar.baz", desc = "preserves hyphens and periods" },
    { input = "abc✨", expected = "abc", desc = "removes invalid utf-8 chars" },
    { input = "", expected = "", desc = "returns empty string on empty input" },
  }
  for _, tcase in ipairs(cases) do
    it(tcase.desc, function()
      assert.equals(tcase.expected, strings.slugify(tcase.input))
    end)
  end
end)

describe("strings.urlencode", function()
  local cases = {
    {
      input = "hello world!",
      expected = "hello+world%21",
      desc = "encodes unsafe ascii chars and replaces spaces with plus",
    },
    { input = "a\nb", expected = "a+b", desc = "replaces newline with plus" },
    { input = nil, expected = "", desc = "returns empty string for nil input" },
    { input = "a-b_c.1~", expected = "a-b_c.1~", desc = "keeps safe url chars unencoded" },
    { input = "✨", expected = "%E2%9C%A8", desc = "encodes utf-8 bytes" },
    { input = tostring(1234), expected = "1234", desc = "number input treated as string" },
    { input = "foo bar", expected = "foo+bar", desc = "replaces space with plus" },
  }
  for _, tcase in ipairs(cases) do
    it(tcase.desc, function()
      assert.equals(tcase.expected, strings.urlencode(tcase.input))
    end)
  end
end)
