vim.g.mapleader = " "

-- Load after Neovim's initial plugin scan but before the first file is read.
vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile", "StdinReadPre", "BufEnter", "VimEnter" }, {
  once = true,
  callback = function()
    require("nvix").setup()
  end,
})
