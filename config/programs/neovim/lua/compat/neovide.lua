vim.g.neovide_cursor_animation_length = 0.05
vim.g.neovide_cursor_trail_size = 0.3
vim.g.neovide_cursor_animate_command_line = false

vim.keymap.set('v', '<D-c>', '"+y')    -- Copy
vim.keymap.set('n', '<D-v>', '"+P')    -- Paste normal mode
vim.keymap.set('v', '<D-v>', '"+P')    -- Paste visual mode
vim.keymap.set('c', '<D-v>', '<C-R>+') -- Paste command mode
vim.keymap.set('i', '<D-v>', '<C-R>+') -- Paste insert mode

-- Paste terminal mode; `<C-\><C-N>` puts you in normal mode
vim.keymap.set('t', '<D-v>', '<C-\\><C-N>"+Pi', {
  noremap = true,
})

vim.keymap.set('n', '<D-w>', '":q<CR>', {
  noremap = true,
})
