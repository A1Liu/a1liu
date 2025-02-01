local Exports = {}

table.unpack = table.unpack or unpack

local import_chain = {}
function Exports.import(name)
  table.insert(import_chain, name)

  local function import() return require(name) end
  local _, imported_module = xpcall(import, function(error)
    vim.print("Failed to import file: " .. name)
    local chain = ""
    for _, v in pairs(import_chain) do
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

function Exports.table_array_concat(t1, t2)
  t1 = t1 or {}
  t2 = t2 or {}

  local output = Exports.table_copy(t1)
  for _, v in pairs(t2) do
    table.insert(output, v)
  end
  return output
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
