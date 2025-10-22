-- Lazy.nvim plugin spec for snacks-lf.nvim
-- Usage: require("snacks-lf.lazy")

return {
  "jackielii/snacks-lf.nvim",
  dependencies = {
    "folke/snacks.nvim",
  },
  keys = {
    {
      "<leader>l",
      function()
        require("snacks-lf").toggle()
      end,
      desc = "Lf file manager",
      mode = { "n" },
    },
  },
  opts = {},
}
