-- import comment plugin safely
local setup, zenmode = pcall(require, "zen-mode")
if not setup then
	return
end

-- enable zen-mode
zenmode.setup()
