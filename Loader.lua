-- Syn-Admin bootstrap. Run with:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/YetYoursTruly/Syn-Admin/main/Loader.lua"))({ Debug = true })
-- Debug modules are opt-in and only execute when Debug = true is passed.

local OWNER = "YetYoursTruly"
local REPO = "Syn-Admin"
local BRANCH = "main"
local HttpService = game:GetService("HttpService")
local ROOT = ("https://api.github.com/repos/%s/%s/git/trees/%s?recursive=1")
    :format(OWNER, REPO, BRANCH)
local RAW_ROOT = ("https://raw.githubusercontent.com/%s/%s/%s/")
    :format(OWNER, REPO, BRANCH)

local function httpGet(url)
    if type(game.HttpGet) == "function" then
        return game:HttpGet(url)
    end
    if type(game.HttpGetAsync) == "function" then
        return game:HttpGetAsync(url)
    end
    error("This executor does not expose game:HttpGet")
end

local function encodePath(path)
    local parts = {}
    for part in path:gmatch("[^/]+") do
        table.insert(parts, HttpService:UrlEncode(part))
    end
    return table.concat(parts, "/")
end

local function listLuaFiles(tree, folder)
    local files = {}
    for _, entry in ipairs(tree.tree or {}) do
        if entry.type == "blob"
            and entry.path:match("^" .. folder .. "/.+%.lua$") then
            table.insert(files, entry.path)
        end
    end
    table.sort(files)
    return files
end

local function getSource(path)
    return httpGet(RAW_ROOT .. encodePath(path))
end
local function listPluginEntries(tree)
    local entries, icons = {}, {}
    for _, item in ipairs(tree.tree or {}) do
        if item.type == "blob" then
            local folder = item.path:match("^(Scripts/.+)/Loader%.lua$")
            if folder then entries[folder] = { Folder = folder, LoaderPath = item.path } end
            local iconFolder = item.path:match("^(Scripts/.+)/icon%.png$")
            if iconFolder then icons[iconFolder] = item.path end
        end
    end
    local result = {}
    for folder, entry in pairs(entries) do
        entry.IconPath = icons[folder]
        table.insert(result, entry)
    end
    table.sort(result, function(a, b) return a.Folder < b.Folder end)
    return result
end

local function customAsset(path)
    local assetFunction = getcustomasset or getsynasset
    if type(assetFunction) ~= "function" or type(isfolder) ~= "function"
        or type(makefolder) ~= "function" or type(isfile) ~= "function"
        or type(writefile) ~= "function" then return nil end

    local folder = "Syn-Admin/ScriptIcons"
    pcall(function()
        if not isfolder("Syn-Admin") then makefolder("Syn-Admin") end
        if not isfolder(folder) then makefolder(folder) end
    end)
    local filename = folder .. "/" .. path:gsub("[^%w_%-%.]", "_")
    if not isfile(filename) then
        local ok, bytes = pcall(httpGet, RAW_ROOT .. encodePath(path))
        if not ok then return nil end
        local wrote = pcall(writefile, filename, bytes)
        if not wrote then return nil end
    end
    local ok, uri = pcall(assetFunction, filename)
    return ok and uri or nil
end

local function compile(path, source)
    assert(type(loadstring) == "function", "This executor does not support loadstring")
    local chunk, err = loadstring(source, "@Syn-Admin/" .. path)
    assert(chunk, "Could not compile " .. path .. ": " .. tostring(err))
    return chunk
end

local function runModule(path, source)
    local ok, result = pcall(function()
        return compile(path, source)()
    end)
    if not ok then
        warn("[Syn-Admin] Failed to load " .. path .. ": " .. tostring(result))
        return nil
    end
    return result
end

local function Debug(manager, files)
    _G.SynAdminDebug = true
    local context = {
        PageManager = manager,
        Debug = true,
        Files = files,
    }

    for _, path in ipairs(files) do
        local module = runModule(path, getSource(path))
        if type(module) == "function" then
            local ok, err = pcall(module, context)
            if not ok then warn("[Syn-Admin] Debug module failed (" .. path .. "): " .. tostring(err)) end
        elseif type(module) == "table" and type(module.Start) == "function" then
            local ok, err = pcall(module.Start, context)
            if not ok then warn("[Syn-Admin] Debug module failed (" .. path .. "): " .. tostring(err)) end
        end
    end
end

local initialOptions = ...
local function startSynAdmin(options)
    if options == true then
        options = { Debug = true }
    else
        options = type(options) == "table" and options or {}
    end
    _G.SynAdminDebug = false

    local tree = HttpService:JSONDecode(httpGet(ROOT))
    assert(type(tree.tree) == "table", "GitHub did not return a repository tree")

    local managerModule = runModule("PageManager.lua", getSource("PageManager.lua"))
    assert(type(managerModule) == "table" and type(managerModule.new) == "function",
        "PageManager.lua must return a table with a new() function")
    local manager = managerModule.new({
        Parent = options.Parent,
        Title = options.Title or "Syn-Admin",
        TweenDuration = options.TweenDuration,
    })


    local scriptManagerModule = runModule("ScriptManager.lua", getSource("ScriptManager.lua"))
    assert(type(scriptManagerModule) == "table" and type(scriptManagerModule.new) == "function",
        "ScriptManager.lua must return a table with a new() function")
    local defaultIcon = customAsset("Assets/Images/x.png") or ""
    local scriptManager = scriptManagerModule.new({
        PageManager = manager,
        Fetch = getSource,
        ResolveIcon = customAsset,
        DefaultIcon = defaultIcon,
        Services = {
            Game = game,
            Players = game:GetService("Players"),
            Workspace = game:GetService("Workspace"),
            HttpService = HttpService,
        },
    })
    for _, entry in ipairs(listPluginEntries(tree)) do
        local name = entry.Folder:match("([^/]+)$")
        local ok, err = pcall(scriptManager.Add, scriptManager, {
            Id = entry.Folder,
            Name = name,
            Description = "Plugin from " .. entry.Folder,
            LoaderPath = entry.LoaderPath,
            IconPath = entry.IconPath,
        })
        if not ok then warn("[Syn-Admin] Invalid plugin entry (" .. entry.LoaderPath .. "): " .. tostring(err)) end
    end

    local pageFiles = listLuaFiles(tree, "Pages")
    assert(#pageFiles > 0, "No Lua page modules were found in Pages/")
    for _, path in ipairs(pageFiles) do
        local module = runModule(path, getSource(path))
        if type(module) == "function" then
            local ok, err = pcall(module, manager, scriptManager)
            if not ok then warn("[Syn-Admin] Page failed (" .. path .. "): " .. tostring(err)) end
        elseif type(module) == "table" and type(module.Build) == "function" then
            local ok, err = pcall(function()
                manager:AddPage(module.Name or path:match("([^/]+)%.lua$"), module.Build, module)
            end)
            if not ok then warn("[Syn-Admin] Page failed (" .. path .. "): " .. tostring(err)) end
        else
            warn("[Syn-Admin] Page module must return a function or a page descriptor: " .. path)
        end
    end

    local startPage = options.StartPage or "Loading"
    if not manager:Open(startPage) then
        local pages = manager:GetPages()
        assert(#pages > 0, "No pages registered")
        manager:Open(pages[1])
    end

    if options.Debug == true then
        Debug(manager, listLuaFiles(tree, "Debug"))
    end

    return manager
end

-- Calling loadstring(source)() starts with default options. Options can still
-- be passed directly as loadstring(source)(options).
if initialOptions == nil then
    return startSynAdmin({})
end
return startSynAdmin(initialOptions)





