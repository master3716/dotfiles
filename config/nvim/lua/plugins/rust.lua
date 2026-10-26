return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        rust_analyzer = {
          flags = {
            debounce_text_changes = 300,
          },

          settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = false,
              },

              check = {
                command = "check",
              },

              checkOnSave = true,

              procMacro = {
                enable = true,
              },
            },
          },
        },
      },
    },
  },
}
