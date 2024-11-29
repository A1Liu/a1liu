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

return Exports
