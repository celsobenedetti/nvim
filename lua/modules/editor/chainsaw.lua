return {
  {
    "chrisgrieser/nvim-chainsaw",
    lazy = true,
    keys = {
      {
        "<leader>l",
        function()
          require("chainsaw").variableLog()
        end,
        desc = "Chainsaw: insert variable log",
      },
      {
        "<leader>cL",
        function()
          require("chainsaw").removeLogs()
        end,
        desc = "Chainsaw: clear Logs",
        mode = { "n", "v" },
      },
    },
    config = function()
      require("chainsaw").setup({
        -- The marker should be a unique string, since signs and highlights are based
        -- on it. Furthermore, `.removeLogs()` will remove any line with it. Thus,
        -- unique emojis or strings (e.g., "[Chainsaw]") are recommended.
        marker = "🔎",

        -- Appearance of lines with the marker
        visuals = {
          icon = "", -- as opposed to the marker only used in nvim, thus nerdfont glyphs are okay
          signHlgroup = "DiagnosticSignInfo",
          signPriority = 50,
          lineHlgroup = false,

          nvimSatelliteIntegration = {
            enabled = true,
            hlgroup = "DiagnosticSignInfo",
            icon = "▪",
            leftOfScrollbar = false,
            priority = 40, -- compared to other handlers (diagnostics are 50)
          },
        },

        -- Auto-install a pre-commit hook that prevents commits containing the marker
        -- string. Will not be installed if there is already another pre-commit-hook.
        preCommitHook = {
          enabled = false,
          notifyOnInstall = true,
          hookPath = ".chainsaw", -- relative to git root

          -- Will insert the marker as `%s`. (Pre-commit hooks requires a shebang
          -- and exit non-zero when marker is found to block the commit.)
          hookContent = [[#!/bin/sh
			if git grep --fixed-strings --line-number "%s" .; then
				echo
				echo "nvim-chainsaw marker found. Aborting commit."
				exit 1
			fi
		]],

          -- Relevant if you track your nvim-config via git and use a custom marker,
          -- as your config will then always include the marker and falsely trigger
          -- the pre-commit hook.
          notInNvimConfigDir = true,

          -- List of git roots where the hook should not be installed. Supports
          -- globs and `~`. Must match the full directory.
          dontInstallInDirs = {
            -- "~/special-project"
            -- "~/repos/**",
          },
        },

        -- configuration for specific logtypes
        logTypes = {
          emojiLog = {
            emojis = { "🔵", "🟩", "⭐", "⭕", "💜", "🔲" },
          },
        },

        -----------------------------------------------------------------------------
        -- see https://github.com/chrisgrieser/nvim-chainsaw/blob/main/lua/chainsaw/config/log-statements-data.lua
        logStatements = require("chainsaw.config.log-statements-data").logStatements,
        supersets = require("chainsaw.config.log-statements-data").supersets,
      })
    end, -- required even if left empty
  },
}
