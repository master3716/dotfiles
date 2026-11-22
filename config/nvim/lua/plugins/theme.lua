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
        c.bg_float = "#121212"
        c.bg_sidebar = "#0b0b0b"
        c.bg_statusline = "#121212"
        c.bg_highlight = "#160708"
        c.bg_visual = "#300a0d"
        c.bg_search = "#8f2227"
        c.bg_popup = "#121212"

        -- Subtle, non-intrusive borders & foregrounds
        c.border = "#7a2024"
        c.border_highlight = "#992b30"
        c.fg = "#d0d0d0"
        c.fg_dark = "#888888"
        c.fg_float = "#e0e0e0"
        c.fg_gutter = "#383838"
        c.fg_sidebar = "#b0b0b0"

        -- Muted, elegant Red palette (soft crimson, brick, and wine tones)
        c.red = "#c74248"
        c.red1 = "#ba3b40"
        c.blue = "#ba3b40"       -- Functions / methods
        c.blue0 = "#20080a"
        c.blue1 = "#b8474d"
        c.blue2 = "#a8393e"
        c.blue5 = "#c2555b"
        c.blue6 = "#b8595e"
        c.blue7 = "#160708"
        c.cyan = "#ba494e"       -- Operators / Specials
        c.green = "#9e3f43"      -- Strings (warm brick/ruby)
        c.green1 = "#ba3b40"
        c.green2 = "#c74248"
        c.magenta = "#c74248"    -- Keywords / Booleans
        c.magenta2 = "#ba3b40"
        c.orange = "#b85257"     -- Numbers / Constants
        c.purple = "#a3393e"     -- Statements / Types
        c.yellow = "#ad474c"     -- Warnings / Types
        c.teal = "#ba494e"
        c.comment = "#5e5e5e"    -- Calming dark neutral grey

        -- Git
        c.git = {
          add = "#b8474d",
          change = "#ba3b40",
          delete = "#6b181c",
          ignore = "#454545",
        }
      end,
      on_highlights = function(hl, c)
        -- Gutter & Line Numbers
        hl.LineNr = { fg = "#383838" }
        hl.CursorLine = { bg = "#140708" }
        hl.CursorLineNr = { fg = "#ba3b40", bold = true }

        -- Selections & Search
        hl.Visual = { bg = "#300a0d" }
        hl.Search = { bg = "#8f2227", fg = "#ffffff" }
        hl.IncSearch = { bg = "#ba3b40", fg = "#ffffff", bold = true }

        -- Windows, Separators & Floats (subtle crimson framing)
        hl.FloatBorder = { fg = "#7a2024", bg = "NONE" }
        hl.WinSeparator = { fg = "#5c1619", bold = true }
        hl.NormalFloat = { bg = "#121212" }

        -- Popup Menus (Autocomplete)
        hl.Pmenu = { bg = "#121212", fg = "#d0d0d0" }
        hl.PmenuSel = { bg = "#731b20", fg = "#ffffff", bold = true }
        hl.PmenuBorder = { fg = "#7a2024", bg = "#121212" }

        -- Statusline
        hl.StatusLine = { bg = "#121212", fg = "#d0d0d0" }
        hl.StatusLineNC = { bg = "#0b0b0b", fg = "#505050" }

        -- Treesitter / Syntax specific softer red accents
        hl["@keyword"] = { fg = "#c74248", bold = true }
        hl["@function"] = { fg = "#ba3b40", bold = true }
        hl["@function.call"] = { fg = "#ba3b40" }
        hl["@string"] = { fg = "#9e3f43" }
        hl["@constant"] = { fg = "#b85257" }
        hl["@type"] = { fg = "#ad474c", bold = true }
        hl["@variable"] = { fg = "#d0d0d0" }
        hl["@variable.parameter"] = { fg = "#b8595e" }
        hl["@operator"] = { fg = "#a8393e" }
        hl["@comment"] = { fg = "#5e5e5e", italic = true }

        -- Diagnostics
        hl.DiagnosticError = { fg = "#c74248" }
        hl.DiagnosticWarn = { fg = "#ad474c" }
        hl.DiagnosticInfo = { fg = "#ba494e" }
        hl.DiagnosticHint = { fg = "#85262a" }

        -- Snacks & Dashboard
        hl.SnacksDashboardHeader = { fg = "#ba3b40" }
        hl.SnacksDashboardIcon = { fg = "#c74248" }
        hl.SnacksDashboardKey = { fg = "#b8474d" }
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
