local M = {}

function M.setup()
  require("nvix.editor.base").setup()
  require("nvix.editor.plugins").setup()
  require("nvix.editor.snacks").setup()
  require("nvix.editor.mappings").setup()
  require("nvix.editor.lang").setup()
end

return M
