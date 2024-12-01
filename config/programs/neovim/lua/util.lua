local Exports = {}

function Exports.import(name)
  function import()
    return require(name)
  end

  return xpcall(import, function(error)
    print("Failed to import file: " .. name)
    print("  Error: " .. error)
  end)
end

function Exports.table_copy(t)
  local u = { }
  for k, v in pairs(t) do u[k] = v end
  return setmetatable(u, getmetatable(t))
end

return Exports
