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
        keywords = { bold = true },
      },
      on_colors = function(c)
        -- Pure black base
        c.bg = "#0b0b0b"
        c.bg_dark = "#0b0b0b"
        c.bg_float = "#111111"
        c.bg_sidebar = "#0b0b0b"
        c.bg_statusline = "#111111"
        c.bg_highlight = "#1c0608"
        c.bg_visual = "#420a0e"
        c.bg_search = "#d71921"
        c.bg_popup = "#111111"

        -- Borders & Foregrounds
        c.border = "#d71921"
        c.border_highlight = "#ff3b30"
        c.fg = "#ededed"
        c.fg_dark = "#999999"
        c.fg_float = "#ffffff"
        c.fg_gutter = "#3a3a3a"
        c.fg_sidebar = "#cccccc"

        -- Pure Black & Red Syntax Mapping
        c.red = "#ff3b30"
        c.red1 = "#d71921"
        c.blue = "#d71921"       -- Functions / methods
        c.blue0 = "#260608"
        c.blue1 = "#ff4d4d"
        c.blue2 = "#e5323c"
        c.blue5 = "#ff6b6b"
        c.blue6 = "#ff8585"
        c.blue7 = "#1c0608"
        c.cyan = "#ff4d4d"       -- Operators / Specials
        c.green = "#c41e24"      -- Strings
        c.green1 = "#d71921"
        c.green2 = "#ff3b30"
        c.magenta = "#ff3b30"    -- Keywords / Booleans
        c.magenta2 = "#d71921"
        c.orange = "#ff5555"     -- Numbers / Constants
        c.purple = "#b01319"     -- Statements / Types
        c.yellow = "#ff6666"     -- Warnings / Types
        c.teal = "#ff4d4d"
        c.comment = "#5a5a5a"    -- Sleek dark grey comments

        -- Git
        c.git = {
          add = "#ff4d4d",
          change = "#d71921",
          delete = "#800b0f",
          ignore = "#4a4a4a",
        }
      end,
      on_highlights = function(hl, c)
        -- Gutter & Line Numbers
        hl.LineNr = { fg = "#3a3a3a" }
        hl.CursorLine = { bg = "#180506" }
        hl.CursorLineNr = { fg = "#d71921", bold = true }

        -- Selections & Search
        hl.Visual = { bg = "#420a0e" }
        hl.Search = { bg = "#d71921", fg = "#ffffff", bold = true }
        hl.IncSearch = { bg = "#ff3b30", fg = "#000000", bold = true }

        -- Windows, Separators & Floats
        hl.FloatBorder = { fg = "#d71921", bg = "NONE" }
        hl.WinSeparator = { fg = "#d71921", bold = true }
        hl.NormalFloat = { bg = "#111111" }

        -- Popup Menus (Autocomplete)
        hl.Pmenu = { bg = "#111111", fg = "#ededed" }
        hl.PmenuSel = { bg = "#d71921", fg = "#ffffff", bold = true }
        hl.PmenuBorder = { fg = "#d71921", bg = "#111111" }

        -- Statusline
        hl.StatusLine = { bg = "#111111", fg = "#ededed" }
        hl.StatusLineNC = { bg = "#0b0b0b", fg = "#5a5a5a" }

        -- Treesitter / Syntax specific black & red accents
        hl["@keyword"] = { fg = "#ff3b30", bold = true }
        hl["@function"] = { fg = "#d71921", bold = true }
        hl["@function.call"] = { fg = "#d71921" }
        hl["@string"] = { fg = "#e55056" }
        hl["@constant"] = { fg = "#ff6666" }
        hl["@type"] = { fg = "#ff4d4d", bold = true }
        hl["@variable"] = { fg = "#ededed" }
        hl["@variable.parameter"] = { fg = "#ff8585" }
        hl["@operator"] = { fg = "#ff3b30" }
        hl["@comment"] = { fg = "#5a5a5a", italic = true }

        -- Diagnostics
        hl.DiagnosticError = { fg = "#ff3b30" }
        hl.DiagnosticWarn = { fg = "#ff6666" }
        hl.DiagnosticInfo = { fg = "#ff4d4d" }
        hl.DiagnosticHint = { fg = "#b01319" }

        -- Snacks & Dashboard
        hl.SnacksDashboardHeader = { fg = "#d71921" }
        hl.SnacksDashboardIcon = { fg = "#ff3b30" }
        hl.SnacksDashboardKey = { fg = "#ff4d4d" }
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
