-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set({ "n", "i", "x", "s", "o", "c" }, "<C-g>", "<Esc>", { remap = true, desc = "Cancel" })
vim.keymap.set("t", "<C-g>", "<C-\\><C-n>", { desc = "Leave Terminal Mode" })
