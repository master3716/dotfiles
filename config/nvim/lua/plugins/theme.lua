return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night",
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
      on_colors = function(colors)
        colors.bg = "#0b0b0b"
        colors.bg_dark = "#0b0b0b"
        colors.bg_float = "#141414"
        colors.bg_sidebar = "#0b0b0b"
        colors.bg_statusline = "#141414"
        colors.bg_highlight = "#1c1c1c"
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
