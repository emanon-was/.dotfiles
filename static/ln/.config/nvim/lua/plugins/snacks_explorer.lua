return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = { hidden = true, ignored = true },
        projects = {
          win = {
            input = {
              keys = {
                ["<C-g>"] = { "cancel", mode = { "n", "i" } },
              },
            },
          },
        },
      },
      win = {
        input = {
          keys = {
            ["<C-g>"] = { "cancel", mode = { "n", "i" } },
          },
        },
        list = {
          keys = {
            ["<C-g>"] = "cancel",
          },
        },
      },
    },
  },
}
