-- import comment plugin safely
local setup, aerial = pcall(require, "aerial")
if not setup then
	return
end

-- enable aerial
aerial.setup({
	attach_mode = "global",
	backends = { "lsp", "treesitter", "markdown" },
	layout = {
		min_width = 28,
	},
	show_guides = true,
	filter_kind = false,
	guides = {
		mid_item = "├ ",
		last_item = "└ ",
		nested_top = "│ ",
		whitespace = "  ",
	},
	keymaps = {
		["[y"] = "actions.prev",
		["]y"] = "actions.next",
		["[Y"] = "actions.prev_up",
		["]Y"] = "actions.next_up",
		["{"] = false,
		["}"] = false,
		["[["] = false,
		["]]"] = false,
	},
})
