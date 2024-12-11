return {
  "epwalsh/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = "markdown",
  keys = {
    { "<leader>ot", "<cmd>ObsidianToday<cr>", desc = "Obsidian Today" },
    { "<leader>oy", "<cmd>ObsidianYesterday<cr>", desc = "Obsidian Yesterday" },
    { "<leader>on", "<cmd>ObsidianNew<cr>", desc = "Obsidian New" },
  },
  dependencies = {
    -- Required.
    "nvim-lua/plenary.nvim",

    -- see below for full list of optional dependencies 👇
  },
  opts = {
    workspaces = {
      {
        name = "Notes",
        path = "~/Documents/iroot-vault/",
      },
    },
    templates = {
      subdir = "templates",
      date_format = "%Y-%m-%d-%a",
      time_format = "%H:%M",
    },

    daily_notes = {
      -- Optional, if you keep daily notes in a separate directory.
      folder = "daily",
      -- Optional, if you want to change the date format for the ID of daily notes.
      date_format = "%Y-%m-%d",
      -- Optional, if you want to change the date format of the default alias of daily notes.
      alias_format = "%B %-d, %Y",
      -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
      template = "daily.md",
    },
  },
}

-- return {
-- "epwalsh/obsidian.nvim",
-- lazy = false,
-- version = "*",
-- ft = "markdown",
-- keys = {
--   { "<leader>ot", "<cmd>ObsidianToday<cr>", desc = "Obsidian Today" },
--   { "<leader>oy", "<cmd>ObsidianYesterday<cr>", desc = "Obsidian Yesterday" },
--   { "<leader>on", "<cmd>ObsidianNew<cr>", desc = "Obsidian New" },
-- },
-- opts = {
--   workspaces = {
--     {
--       name = "Notes",
--       path = "~/Documents/iroot-vault/",
--     },
--   },
--
--   note_id_func = function(title)
--     -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
--     local suffix = ""
--     if title ~= nil then
--       -- If title is given, transform it into valid file name.
--       suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
--     else
--       -- If title is nil, just add 4 random uppercase letters to the suffix.
--       for _ = 1, 4 do
--         suffix = suffix .. string.char(math.random(65, 90))
--       end
--     end
--     return tostring(os.time()) .. "-" .. suffix
--   end,
--
--   daily_notes = {
--     -- Optional, if you keep daily notes in a separate directory.
--     folder = "daily",
--     -- Optional, if you want to change the date format for the ID of daily notes.
--     date_format = "%Y-%m-%d",
--     -- Optional, if you want to change the date format of the default alias of daily notes.
--     alias_format = "%B %-d, %Y",
--     -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
--     template = "daily.md",
--   },
--   completion = {
--     -- Set to false to disable completion.
--     nvim_cmp = true,
--
--     -- Trigger completion at 2 chars.
--     min_chars = 2,
--
--     -- Where to put new notes created from completion. Valid options are
--     --  * "current_dir" - put new notes in same directory as the current buffer.
--     --  * "notes_subdir" - put new notes in the default notes subdirectory.
--     new_notes_location = "current_dir",
--
--     -- Control how wiki links are completed with these (mutually exclusive) options:
--     --
--     -- 1. Whether to add the note ID during completion.
--     -- E.g. "[[Foo" completes to "[[foo|Foo]]" assuming "foo" is the ID of the note.
--     -- Mutually exclusive with 'prepend_note_path' and 'use_path_only'.
--     prepend_note_id = true,
--     -- 2. Whether to add the note path during completion.
--     -- E.g. "[[Foo" completes to "[[notes/foo|Foo]]" assuming "notes/foo.md" is the path of the note.
--     -- Mutually exclusive with 'prepend_note_id' and 'use_path_only'.
--     prepend_note_path = false,
--     -- 3. Whether to only use paths during completion.
--     -- E.g. "[[Foo" completes to "[[notes/foo]]" assuming "notes/foo.md" is the path of the note.
--     -- Mutually exclusive with 'prepend_note_id' and 'prepend_note_path'.
--     use_path_only = false,
--   },
--   templates = {
--     subdir = "templates",
--     date_format = "%Y-%m-%d-%a",
--     time_format = "%H:%M",
--   },
--
--   ui = {
--     conceallevel = 1,
--     enable = true, -- set to false to disable all additional syntax features
--     update_debounce = 200, -- update delay after a text change (in milliseconds)
--     -- Define how various check-boxes are displayed
--     checkboxes = {
--       -- NOTE: the 'char' value has to be a single character, and the highlight groups are defined below.
--       [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
--       ["x"] = { char = "", hl_group = "ObsidianDone" },
--       [">"] = { char = "", hl_group = "ObsidianRightArrow" },
--       ["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
--       -- Replace the above with this if you don't have a patched font:
--       -- [" "] = { char = "☐", hl_group = "ObsidianTodo" },
--       -- ["x"] = { char = "✔", hl_group = "ObsidianDone" },
--
--       -- You can also add more custom ones...
--     },
--     external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
--     -- Replace the above with this if you don't have a patched font:
--     -- external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
--     reference_text = { hl_group = "ObsidianRefText" },
--     highlight_text = { hl_group = "ObsidianHighlightText" },
--     tags = { hl_group = "ObsidianTag" },
--     hl_groups = {
--       -- The options are passed directly to `vim.api.nvim_set_hl()`. See `:help nvim_set_hl`.
--       ObsidianTodo = { bold = true, fg = "#f78c6c" },
--       ObsidianDone = { bold = true, fg = "#89ddff" },
--       ObsidianRightArrow = { bold = true, fg = "#f78c6c" },
--       ObsidianTilde = { bold = true, fg = "#ff5370" },
--       ObsidianRefText = { underline = true, fg = "#c792ea" },
--       ObsidianExtLinkIcon = { fg = "#c792ea" },
--       ObsidianTag = { italic = true, fg = "#89ddff" },
--       ObsidianHighlightText = { bg = "#75662e" },
--     },
--   },
--   mappings = {
--     -- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
--     ["gf"] = {
--       action = function()
--         return require("obsidian").util.gf_passthrough()
--       end,
--       opts = { noremap = false, expr = true, buffer = true },
--     },
--     -- Toggle check-boxes.
--     ["<leader>ch"] = {
--       action = function()
--         return require("obsidian").util.toggle_checkbox()
--       end,
--       opts = { buffer = true },
--     },
--   },
-- },
-- }
