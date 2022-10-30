-- import comment plugin safely
local setup, golang = pcall(require, "go")
if not setup then
	return
end

-- enable golang
golang.setup()
