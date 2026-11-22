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
        comments = { italic = true },
        keywords = { italic = false, bold = true },
        functions = { bold = true },
      },
      on_colors = function(c)
        -- Matte black base to match the terminal seamlessly
        c.bg = "#0b0b0b"
        c.bg_dark = "#0b0b0b"
        c.bg_float = "#121212"
        c.bg_sidebar = "#0b0b0b"
        c.bg_statusline = "#121212"
        c.bg_highlight = "#1c1c1c"
        c.bg_visual = "#331518"
        c.bg_search = "#d71921"
        c.bg_popup = "#121212"

        -- System Red UI Accents (Nothing OS theme)
        c.border = "#d71921"
        c.border_highlight = "#ff4d4d"
        c.fg_gutter = "#3a3a3a"
        c.red1 = "#d71921"
      end,
      on_highlights = function(hl, c)
        -- System Red accents for UI framing & indicators
        hl.CursorLine = { bg = "#141414" }
        hl.CursorLineNr = { fg = "#d71921", bold = true }
        hl.LineNr = { fg = "#3a3a3a" }
        hl.FloatBorder = { fg = "#d71921", bg = "NONE" }
        hl.WinSeparator = { fg = "#381012", bold = true }
        hl.Search = { bg = "#d71921", fg = "#ffffff", bold = true }
        hl.IncSearch = { bg = "#ff4d4d", fg = "#000000", bold = true }
        hl.PmenuSel = { bg = "#d71921", fg = "#ffffff", bold = true }
        hl.Visual = { bg = "#331518" }

        -- Balanced, readable syntax colors fitting a dark aesthetic
        hl.SnacksDashboardHeader = { fg = "#d71921" }
        hl.SnacksDashboardIcon = { fg = "#d71921" }
        hl.SnacksDashboardKey = { fg = "#e0af68" }
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
