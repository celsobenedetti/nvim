local web = require("lib.web")

describe("web.get_search_url_from_query", function()
  local cases = {
    { desc = "GitHub repo shortcut (owner/repo)", input = "owner/repo", expected = "https://github.com/owner/repo" },
    { desc = "lazyvim (case insensitive)", input = "lazyvim", expected = "https://lazyvim.org" },
    { desc = "lazyvim (mixed case)", input = "LaZyVim", expected = "https://lazyvim.org" },
    { desc = "monkeytype prefix", input = "mt", expected = "https://monkeytype.com" },
    { desc = "monkeytype prefix with spaces", input = " MT ", expected = "https://monkeytype.com" },
    {
      desc = "YouTube search prefix",
      input = "y piano tutorials",
      expected = "https://www.youtube.com/results?search_query=piano+tutorials",
    },
    {
      desc = "GitHub search prefix",
      input = "gh neovim",
      expected = "https://github.com/search?q=neovim&type=repositories",
    },
    {
      desc = "GitHub direct repo access",
      input = "gh nvim-lua/plenary.nvim",
      expected = "https://github.com/nvim-lua/plenary.nvim",
    },
    { desc = "unknown prefix returns empty string", input = "unknownprefix search", expected = "" },
    {
      desc = "Google search fallback and trimming",
      input = "  g hello ",
      expected = "https://www.google.com/search?q=hello",
    },
    {
      desc = "Should not mistake g{url} for google",
      input = "gitlab.com",
      expected = "https://gitlab.com",
    },
    {
      desc = "should match git repo",
      input = "robitx/gp.nvim",
      expected = "https://github.com/robitx/gp.nvim",
    },
  }

  for _, case in ipairs(cases) do
    it(case.desc, function()
      assert.equals(web.get_search_url_from_query(case.input), case.expected)
    end)
  end
end)

describe("does_string_match_url_without_protocol", function()
  local cases = {
    { "opencode.ai", true },
    { "google.ai", true },
    { "lazyvim.org", true },
    { "foo.bar.baz.com", true },
    { "1-2-3.example.net", true },
    { "http://google.com", false },
    { "https://opencode.ai", false },
    { "ftp://ftpserver.com", false },
    { "google.1a", false },
    { "google.", false },
    { ".ai", false },
    { "8.8.8.8", false },
    { "localhost", false },
    { "-badhost.com", false },
    { "test_domain.ai", false },
  }

  for _, c in ipairs(cases) do
    it(("matches %q → %s"):format(c[1], tostring(c[2])), function()
      assert.equals(web.does_string_match_url_without_protocol(c[1]), c[2])
    end)
  end
end)
