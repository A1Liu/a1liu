if vim.g.neovide then
  require("compat/neovide")
end

xpcall(
  function() require("compat/this") end,
  function(error) end
)

