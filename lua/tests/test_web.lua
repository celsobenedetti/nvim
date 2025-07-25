local web = require("lib.web")

describe("web.get_search_url_from_query", function()
  it("returns GitHub repo URL for owner/repo query", function()
    assert.equals(web.get_search_url_from_query("owner/repo"), "https://github.com/owner/repo")
  end)

  it("returns lazyvim.org for 'lazyvim' prefix", function()
    assert.equals(web.get_search_url_from_query("lazyvim"), "https://lazyvim.org")
    assert.equals(web.get_search_url_from_query("LaZyVim"), "https://lazyvim.org")
  end)

  it("returns monkeytype.com for 'mt'", function()
    assert.equals(web.get_search_url_from_query("mt"), "https://monkeytype.com")
    assert.equals(web.get_search_url_from_query(" MT "), "https://monkeytype.com")
  end)

  it("handles YouTube prefix", function()
    assert.equals(
      web.get_search_url_from_query("y piano tutorials"),
      "https://www.youtube.com/results?search_query=piano+tutorials"
    )
  end)

  it("handles GitHub prefix for search", function()
    assert.equals(web.get_search_url_from_query("gh neovim"), "https://github.com/search?q=neovim&type=repositories")
  end)

  it("handles GitHub prefix for owner/repo direct", function()
    assert.equals(web.get_search_url_from_query("gh nvim-lua/plenary.nvim"), "https://github.com/nvim-lua/plenary.nvim")
  end)

  it("returns empty string for unknown no-match input", function()
    assert.equals(web.get_search_url_from_query("unknownprefix search"), "")
  end)

  it("trims input before matching", function()
    assert.equals(web.get_search_url_from_query("  g hello "), "https://www.google.com/search?q=hello")
  end)
end)
