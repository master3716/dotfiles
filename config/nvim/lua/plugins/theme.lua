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
        -- Pure matte black base matching the terminal canvas seamlessly
        c.bg = "#0b0b0b"
        c.bg_dark = "#0b0b0b"
        c.bg_float = "#121212"
        c.bg_sidebar = "#0b0b0b"
        c.bg_statusline = "#121212"
        c.bg_highlight = "#1a1b26"
        c.bg_visual = "#283457"
        c.bg_search = "#3d59a1"
        c.bg_popup = "#16161e"
        c.fg_gutter = "#3b4261"
      end,
      on_highlights = function(hl, c)
        -- Clean, non-distracting cursor matching text foreground
        hl.Cursor = { fg = "#0b0b0b", bg = "#c0caf5" }
        hl.TermCursor = { fg = "#0b0b0b", bg = "#c0caf5" }

        -- Subtle, comfortable line & gutter indicators
        hl.CursorLine = { bg = "#141414" }
        hl.CursorLineNr = { fg = "#737aa2", bold = true }
        hl.LineNr = { fg = "#3b4261" }

        -- Sleek, calm window borders (no harsh red framing)
        hl.FloatBorder = { fg = "#3b4261", bg = "NONE" }
        hl.WinSeparator = { fg = "#24283b", bold = true }
        hl.NormalFloat = { bg = "#121212" }

        -- Smooth selections & autocomplete
        hl.Pmenu = { bg = "#121212", fg = "#c0caf5" }
        hl.PmenuSel = { bg = "#283457", fg = "#ffffff", bold = true }
        hl.PmenuBorder = { fg = "#3b4261", bg = "#121212" }
        hl.Search = { bg = "#3d59a1", fg = "#ffffff" }
        hl.IncSearch = { bg = "#ff9e64", fg = "#000000", bold = true }
        hl.Visual = { bg = "#283457" }

        -- Dashboard accents
        hl.SnacksDashboardHeader = { fg = "#7aa2f7" }
        hl.SnacksDashboardIcon = { fg = "#7aa2f7" }
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
