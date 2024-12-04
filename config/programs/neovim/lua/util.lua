local Exports = {}

local import_chain = {}
function Exports.import(name)
  table.insert(import_chain, name)

  function import() return require(name) end
  local successed, imported_module = xpcall(import, function(error)
    vim.print("Failed to import file: " .. name)
    local chain = ""
    for k, v in pairs(import_chain) do
      chain = chain .. ", " .. v
    end

    chain = string.gsub(chain, '^,%s*(.-)%s*$', '%1')

    vim.print("  Import chain: " .. chain)
    vim.print("  Error: " .. error)
  end)

  table.remove(import_chain)

  return imported_module
end

function Exports.table_copy(t)
  local u = { }
  for k, v in pairs(t) do u[k] = v end
  return setmetatable(u, getmetatable(t))
end

return Exports
