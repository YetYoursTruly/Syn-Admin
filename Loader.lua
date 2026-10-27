-- Syn-Admin Bootstrap
-- Usage:
-- loadstring(game:HttpGet(
--     "https://raw.githubusercontent.com/YetYoursTruly/Syn-Admin/main/Loader.lua"
-- ))({ Debug = true })

local OWNER = "YetYoursTruly"
local REPO = "Syn-Admin"
local BRANCH = "main"

local HttpService = game:GetService("HttpService")

local ROOT = ("https://api.github.com/repos/%s/%s/git/trees/%s?recursive=1")
    :format(OWNER, REPO, BRANCH)

local RAW_ROOT = ("https://raw.githubusercontent.com/%s/%s/%s/")
    :format(OWNER, REPO, BRANCH)

local function httpGet(url)
    assert(type(url) == "string" and url ~= "", "URL is required")

    local ok, result = pcall(function()
        if type(game.HttpGet) == "function" then
            return game:HttpGet(url)
        elseif type(game.HttpGetAsync) == "function" then
            return game:HttpGetAsync(url)
        end

        error("Executor does not expose game:HttpGet")
    end)

    if not ok then
        error("HTTP request failed: " .. tostring(result), 2)
    end

    assert(
        type(result) == "string" and result ~= "",
        "HTTP request returned empty or invalid content"
    )

    return result
end

local function encodePath(path)
    local parts = {}

    for part in path:gmatch("[^/]+") do
        table.insert(parts, HttpService:UrlEncode(part))
    end

    return table.concat(parts, "/")
end

local function getSource(path)
    return httpGet(RAW_ROOT .. encodePath(path))
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

local function listPluginEntries(tree)
    local entries = {}
    local icons = {}

    for _, item in ipairs(tree.tree or {}) do
        if item.type == "blob" then
            local folder = item.path:match("^(Scripts/.+)/Loader%.lua$")
            if folder then
                entries[folder] = {
                    Folder = folder,
                    LoaderPath = item.path,
                }
            end

            local iconFolder = item.path:match("^(Scripts/.+)/icon%.png$")
            if iconFolder then
                icons[iconFolder] = item.path
            end
        end
    end

    local result = {}

    for folder, entry in pairs(entries) do
        entry.IconPath = icons[folder]
        table.insert(result, entry)
    end

    table.sort(result, function(a, b)
        return a.Folder < b.Folder
    end)

    return result
end

local function customAsset(path)
    local assetFunction = getcustomasset or getsynasset

    if type(assetFunction) ~= "function"
        or type(isfolder) ~= "function"
        or type(makefolder) ~= "function"
        or type(isfile) ~= "function"
        or type(writefile) ~= "function" then
        return nil
    end

    local folder = "Syn-Admin/ScriptIcons"

    pcall(function()
        if not isfolder("Syn-Admin") then
            makefolder("Syn-Admin")
        end

        if not isfolder(folder) then
            makefolder(folder)
        end
    end)

    local filename = folder .. "/" .. path:gsub("[^%w_%-%.]", "_")

    if not isfile(filename) then
        local ok, bytes = pcall(getSource, path)

        if not ok then
            warn("[Syn-Admin] Icon download failed: " .. tostring(bytes))
            return nil
        end

        local wrote, writeError = pcall(writefile, filename, bytes)

        if not wrote then
            warn("[Syn-Admin] Icon write failed: " .. tostring(writeError))
            return nil
        end
    end

    local ok, uri = pcall(assetFunction, filename)
    return ok and uri or nil
end

local function compile(path, source)
    assert(type(source) == "string" and source ~= "",
        "Source for " .. tostring(path) .. " is empty")

    assert(type(loadstring) == "function",
        "This executor does not support loadstring")

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
        return nil, result
    end

    return result
end

local function createLogger()
    local history = {}
    local context = {
        Debug = true,
        LogHistory = history,
    }

    context.Log = function(message, level)
        local entry = {
            Message = tostring(message),
            Level = tostring(level or "INFO"):upper(),
        }

        table.insert(history, entry)

        if #history > 250 then
            table.remove(history, 1)
        end

        warn("[Syn-Admin][" .. entry.Level .. "] " .. entry.Message)
    end

    return context
end

local function Debug(manager, files)
    _G.SynAdminDebug = true

    local context = createLogger()
    context.PageManager = manager
    context.Files = files

    context.Log("Debug mode enabled")

    -- Load the terminal first, before other debug modules.
    local terminalPath = "Debug/Terminal.lua"
    local terminalFound = false

    for _, path in ipairs(files) do
        if path == terminalPath then
            terminalFound = true
            break
        end
    end

    if terminalFound then
        local sourceOk, source = pcall(getSource, terminalPath)

        if sourceOk then
            local moduleOk, module = pcall(function()
                return compile(terminalPath, source)()
            end)

            if moduleOk then
                local startOk, startError = pcall(function()
                    if type(module) == "function" then
                        module(context)
                    elseif type(module) == "table"
                        and type(module.Start) == "function" then
                        module.Start(context)
                    else
                        error("Terminal module must return a function or Start table")
                    end
                end)

                if not startOk then
                    context.Log("Terminal startup failed: " .. tostring(startError), "ERROR")
                end
            else
                context.Log("Terminal compilation failed: " .. tostring(module), "ERROR")
            end
        else
            context.Log("Terminal download failed: " .. tostring(source), "ERROR")
        end
    else
        context.Log("Debug/Terminal.lua was not found in the repository", "WARN")
    end

    -- Continue even if an individual debug module fails.
    for _, path in ipairs(files) do
        if path ~= terminalPath then
            local sourceOk, source = pcall(getSource, path)

            if not sourceOk then
                context.Log(
                    "Download failed for " .. path .. ": " .. tostring(source),
                    "ERROR"
                )
                continue
            end

            local moduleOk, module = pcall(function()
                return compile(path, source)()
            end)

            if not moduleOk then
                context.Log(
                    "Compilation failed for " .. path .. ": " .. tostring(module),
                    "ERROR"
                )
                continue
            end

            local startOk, startError = pcall(function()
                if type(module) == "function" then
                    module(context)
                elseif type(module) == "table"
                    and type(module.Start) == "function" then
                    module.Start(context)
                end
            end)

            if not startOk then
                context.Log(
                    "Module startup failed for " .. path .. ": " .. tostring(startError),
                    "ERROR"
                )
            end
        end
    end

    return context
end

local initialOptions = ...

local function startSynAdmin(options)
    if options == true then
        options = { Debug = true }
    else
        options = type(options) == "table" and options or {}
    end

    _G.SynAdminDebug = false

    local function logStartupError(message)
        warn("[Syn-Admin][STARTUP ERROR] " .. tostring(message))
    end

    -- Fetch and validate the repository tree.
    local requestOk, treeSource = pcall(httpGet, ROOT)

    if not requestOk then
        logStartupError("Could not fetch repository tree: " .. tostring(treeSource))
        return nil
    end

    local decodeOk, tree = pcall(function()
        return HttpService:JSONDecode(treeSource)
    end)

    if not decodeOk or type(tree) ~= "table" or type(tree.tree) ~= "table" then
        logStartupError("GitHub returned an invalid repository tree")
        return nil
    end

    -- Load PageManager.
    local managerSourceOk, managerSource = pcall(getSource, "PageManager.lua")

    if not managerSourceOk then
        logStartupError("Could not download PageManager.lua: " .. tostring(managerSource))
        return nil
    end

    local managerModule, managerError = runModule("PageManager.lua", managerSource)

    if type(managerModule) ~= "table" or type(managerModule.new) ~= "function" then
        logStartupError("PageManager.lua is invalid: " .. tostring(managerError))
        return nil
    end

    local managerOk, manager = pcall(function()
        return managerModule.new({
            Parent = options.Parent,
            Title = options.Title or "Syn-Admin",
            TweenDuration = options.TweenDuration,
        })
    end)

    if not managerOk or not manager then
        logStartupError("Could not create PageManager: " .. tostring(manager))
        return nil
    end

    manager.ResolveAsset = customAsset

    -- Load ScriptManager.
    local scriptSourceOk, scriptSource = pcall(getSource, "ScriptManager.lua")

    if not scriptSourceOk then
        logStartupError("Could not download ScriptManager.lua: " .. tostring(scriptSource))
        pcall(function() manager:Destroy() end)
        return nil
    end

    local scriptManagerModule, scriptManagerError =
        runModule("ScriptManager.lua", scriptSource)

    if type(scriptManagerModule) ~= "table"
        or type(scriptManagerModule.new) ~= "function" then
        logStartupError("ScriptManager.lua is invalid: " .. tostring(scriptManagerError))
        pcall(function() manager:Destroy() end)
        return nil
    end

    local defaultIcon = customAsset("Assets/Images/x.png") or ""

    local scriptManagerOk, scriptManager = pcall(function()
        return scriptManagerModule.new({
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
    end)

    if not scriptManagerOk or not scriptManager then
        logStartupError("Could not create ScriptManager: " .. tostring(scriptManager))
        pcall(function() manager:Destroy() end)
        return nil
    end

    -- Register plugin entries independently.
    for _, entry in ipairs(listPluginEntries(tree)) do
        local name = entry.Folder:match("([^/]+)$")

        local ok, err = pcall(function()
            scriptManager:Add({
                Id = entry.Folder,
                Name = name,
                Description = "Plugin from " .. entry.Folder,
                LoaderPath = entry.LoaderPath,
                IconPath = entry.IconPath,
            })
        end)

        if not ok then
            warn("[Syn-Admin] Invalid plugin entry "
                .. tostring(entry.LoaderPath) .. ": " .. tostring(err))
        end
    end

    -- Load pages independently; a broken page should not block the others.
    local pageFiles = listLuaFiles(tree, "Pages")

    if #pageFiles == 0 then
        logStartupError("No Lua page modules were found in Pages/")
        pcall(function() manager:Destroy() end)
        return nil
    end

    for _, path in ipairs(pageFiles) do
        local sourceOk, source = pcall(getSource, path)

        if not sourceOk then
            warn("[Syn-Admin] Page download failed (" .. path .. "): " .. tostring(source))
            continue
        end

        local module = runModule(path, source)

        if type(module) == "function" then
            local ok, err = pcall(module, manager, scriptManager)

            if not ok then
                warn("[Syn-Admin] Page failed (" .. path .. "): " .. tostring(err))
            end
        elseif type(module) == "table" and type(module.Build) == "function" then
            local ok, err = pcall(function()
                manager:AddPage(
                    module.Name or path:match("([^/]+)%.lua$"),
                    module.Build,
                    module
                )
            end)

            if not ok then
                warn("[Syn-Admin] Page failed (" .. path .. "): " .. tostring(err))
            end
        else
            warn("[Syn-Admin] Invalid page module: " .. path)
        end
    end

    -- Start debug mode before showing the loading page.
    if options.Debug == true then
        local debugFiles = listLuaFiles(tree, "Debug")
        Debug(manager, debugFiles)
    end

    local startPage = options.StartPage or "Loading"
    local opened = false

    local openOk, openResult = pcall(function()
        return manager:Open(startPage)
    end)

    if openOk and openResult then
        opened = true
    else
        warn("[Syn-Admin] Could not open start page "
            .. tostring(startPage) .. ": " .. tostring(openResult))
    end

    if not opened then
        local pages = manager:GetPages()

        for _, pageName in ipairs(pages) do
            local ok, result = pcall(function()
                return manager:Open(pageName)
            end)

            if ok and result then
                opened = true
                warn("[Syn-Admin] Opened fallback page: " .. pageName)
                break
            end
        end
    end

    if not opened then
        logStartupError("No registered page could be opened")
    end

    return manager
end

if initialOptions == nil then
    return startSynAdmin({})
end

return startSynAdmin(initialOptions)
