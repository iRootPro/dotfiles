-- import comment plugin safely
local setup, toggleterm = pcall(require, "toggleterm")
if not setup then
	return
end

-- enable hop
toggleterm.setup({
	size = 10,
	shading_factor = 2,
	direction = "float",
	float_opts = {
		border = "curved",
		highlights = {
			border = "Normal",
			background = "Normal",
		},
	},
})
