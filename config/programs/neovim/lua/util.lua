local Exports = {}

table.unpack = table.unpack or unpack

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

-- True insanity. Every line of this function was a pain in the ass,
-- because the docs are all over the place.
function Exports.curry(f, ...)
  local outer_args = {...}
  return function(...)
    local inner_args = {...}
    local data = vim.tbl_extend("keep", outer_args, inner_args)
    return f(table.unpack(data))
  end
end

return Exports
