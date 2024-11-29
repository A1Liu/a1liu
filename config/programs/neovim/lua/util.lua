local Exports = {}

function Exports.import(name)
  function import()
    return require(name)
  end

  return xpcall(import, function()
    print("Failed to import file: " .. name)
  end)
end

return Exports
