return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            win = {
              list = {
                keys = {
                  ["n"] = { "explorer_add", desc = "Add File or Directory" },
                  ["<c-t>"] = {
                    function(picker, item)
                      local dir = item and Snacks.picker.util.dir(item) or vim.fn.getcwd()
                      vim.cmd("ToggleTerm dir=" .. vim.fn.fnameescape(dir))
                    end,
                    desc = "Toggle Terminal (Float)",
                  },
                },
              },
              input = {
                keys = {
                  ["<c-t>"] = {
                    function(picker, item)
                      local dir = item and Snacks.picker.util.dir(item) or vim.fn.getcwd()
                      vim.cmd("ToggleTerm dir=" .. vim.fn.fnameescape(dir))
                    end,
                    desc = "Toggle Terminal (Float)",
                    mode = { "n", "i" },
                  },
                },
              },
            },
          },
        },
      },
    },
  },
}
