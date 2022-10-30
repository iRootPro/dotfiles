-- import comment plugin safely
local setup, neorg = pcall(require, "neorg")
if not setup then
	return
end

-- enable neorg
neorg.setup({
	load = {
		["core.defaults"] = {},
		["core.norg.completion"] = {
			config = {
				engine = "nvim-cmp",
			},
		},
		["core.presenter"] = {
			config = {
				zen_mode = "zen-mode",
			},
		},
		["core.norg.concealer"] = {
			config = {
				icon_preset = "varied",
				markup_preset = "safe",
				conceal = "true",
			},
		},
		["core.norg.dirman"] = {
			config = {
				workspaces = {
					work = "~/Documents/ORG/work",
					home = "~/Documents/ORG/home",
				},
			},
		},
	},
})
