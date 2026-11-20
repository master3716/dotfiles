return {
  {
    "akinsho/toggleterm.nvim",
    opts = {
      direction = "float",
      float_opts = {
        border = "rounded",
        winblend = 0,
        width = function()
          return math.floor(vim.o.columns * 0.8)
        end,
        height = function()
          return math.floor(vim.o.lines * 0.8)
        end,
      },
      open_mapping = [[<c-t>]],
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      terminal = {
        win = {
          position = "float",
          border = "rounded",
          width = 0.8,
          height = 0.8,
          keys = {
            term_c_t = { "<c-t>", "hide", desc = "Hide Terminal", mode = "t" },
          },
        },
      },
    },
  },
}
