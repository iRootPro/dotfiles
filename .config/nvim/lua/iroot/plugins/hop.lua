-- import comment plugin safely
local setup, hop = pcall(require, "hop")
if not setup then
	return
end

-- enable hop
hop.setup()
