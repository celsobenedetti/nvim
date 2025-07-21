local builtin = require("telescope.builtin")

--- Search org files in notes folder
return function()
  builtin.find_files({
    prompt_title = "< Org files >",
    search_file = "*.org",
    search_dirs = {
      C.notes.NOTES,
    },
    cwd = C.notes.NOTES,
    hidden = true,
  })
end
