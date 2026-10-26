return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          flags = {
            debounce_text_changes = 300,
          },
        },

        ruff = {
          flags = {
            debounce_text_changes = 300,
          },
        },
      },
    },
  },
}
