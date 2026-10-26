local ScriptManager = {}
ScriptManager.__index = ScriptManager

function ScriptManager.new(options)
    options = options or {}
    return setmetatable({
        Scripts = {},
        ScriptOrder = {},
        PageManager = options.PageManager,
        Fetch = options.Fetch,
        ResolveIcon = options.ResolveIcon,
        DefaultIcon = options.DefaultIcon,
        Services = options.Services or {},
    }, ScriptManager)
end

function ScriptManager:Add(script)
    assert(type(script) == "table", "Script entry must be a table")
    assert(type(script.Id) == "string" and script.Id ~= "", "Script Id is required")
    assert(type(script.Name) == "string" and script.Name ~= "", "Script Name is required")
    assert(type(script.LoaderPath) == "string" and script.LoaderPath ~= "", "Script LoaderPath is required")
    assert(not self.Scripts[script.Id], "A script with id '" .. script.Id .. "' is already registered")
    script.Description = tostring(script.Description or "Plugin script")
    script.Author = tostring(script.Author or "Unknown")
    script.Version = tostring(script.Version or "1.0.0")
    script.Game = tostring(script.Game or "Universal")
    script.Category = tostring(script.Category or "General")
    script.Icon = self.DefaultIcon
    if self.ResolveIcon and script.IconPath then
        local ok, icon = pcall(self.ResolveIcon, script.IconPath)
        if ok and icon then script.Icon = icon end
    end
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

function ScriptManager:_pluginFor(script)
    local manager = self.PageManager
    local plugin = { Name = script.Name, Script = script }

    function plugin:AddPage(name, build, options)
        assert(manager, "PageManager is unavailable")
        return manager:AddPage(name, build, options)
    end

    function plugin:OpenPage(name, duration)
        assert(manager, "PageManager is unavailable")
        return manager:Open(name, duration)
    end

    function plugin:GetPages()
        assert(manager, "PageManager is unavailable")
        return manager:GetPages()
    end

    for key, value in pairs(self.Services) do plugin[key] = value end
    plugin.Plugin = plugin
    return plugin
end

function ScriptManager:Run(id)
    local script = self.Scripts[id]
    if not script then return false, "Script not found: " .. tostring(id) end
    if type(self.Fetch) ~= "function" then return false, "Script source fetching is unavailable" end
    if type(loadstring) ~= "function" then return false, "This executor does not support loadstring" end

    local ok, source = pcall(self.Fetch, script.LoaderPath)
    if not ok then return false, "Could not download Loader.lua: " .. tostring(source) end
    if type(source) ~= "string" or source:match("^%s*$") then
        return false, "Loader.lua is empty"
    end
    local chunk, compileError = loadstring(source, "@Syn-Admin/" .. script.LoaderPath)
    if not chunk then return false, "Could not compile Loader.lua: " .. tostring(compileError) end

    local plugin = self:_pluginFor(script)
    local loaded, result = pcall(function()
        local module = chunk(plugin)
        if type(module) == "function" then
            return module(plugin)
        elseif type(module) == "table" and type(module.Start) == "function" then
            return module.Start(plugin)
        end
        return module
    end)
    if not loaded then
        warn("[Syn-Admin] Plugin failed (" .. script.Name .. "): " .. tostring(result))
        return false, tostring(result)
    end
    return true, result
end

return ScriptManager


