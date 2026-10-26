local ScriptManager = {}
ScriptManager.__index = ScriptManager

local function validDescriptor(script, path)
    assert(type(script) == "table", path .. " must return a script descriptor table")
    assert(type(script.Name) == "string" and script.Name ~= "", path .. " is missing Name")
    assert(type(script.Description) == "string", path .. " is missing Description")
    assert(type(script.Load) == "function", path .. " is missing Load(context)")
    script.Version = tostring(script.Version or "1.0.0")
    script.Author = tostring(script.Author or "Unknown")
    script.Category = tostring(script.Category or "General")
    script.Game = tostring(script.Game or "Universal")
    script.Id = tostring(script.Id or path:gsub("^Scripts/", ""):gsub("%.lua$", ""))
    script.Source = path
    return script
end

function ScriptManager.new(options)
    options = options or {}
    return setmetatable({ Scripts = {}, ScriptOrder = {}, Context = options.Context or {} }, ScriptManager)
end

function ScriptManager:Add(script, path)
    script = validDescriptor(script, path or "Script")
    assert(not self.Scripts[script.Id], "A script with id '" .. script.Id .. "' is already registered")
    self.Scripts[script.Id] = script
    table.insert(self.ScriptOrder, script.Id)
    return script
end

function ScriptManager:Get(id)
    return self.Scripts[id]
end

function ScriptManager:GetAll()
    local scripts = {}
    for _, id in ipairs(self.ScriptOrder) do table.insert(scripts, self.Scripts[id]) end
    return scripts
end

function ScriptManager:Run(id, extraContext)
    local script = self.Scripts[id]
    if not script then return false, "Script not found: " .. tostring(id) end
    local context = {}
    for key, value in pairs(self.Context) do context[key] = value end
    for key, value in pairs(extraContext or {}) do context[key] = value end
    context.Script = script
    local ok, result = pcall(script.Load, context)
    if not ok then
        warn("[Syn-Admin] Script failed (" .. script.Name .. "): " .. tostring(result))
        return false, tostring(result)
    end
    return true, result
end

return ScriptManager
