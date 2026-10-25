local PageManager = {}
PageManager.__index = PageManager

local COLORS = {
    Background = Color3.fromRGB(10, 12, 18),
    Surface = Color3.fromRGB(17, 20, 29),
    Raised = Color3.fromRGB(26, 30, 42),
    Text = Color3.fromRGB(235, 239, 248),
    Muted = Color3.fromRGB(146, 155, 174),
    Accent = Color3.fromRGB(111, 153, 255),
}

local function create(className, props, parent)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function defaultParent()
    if type(gethui) == "function" then
        local ok, parent = pcall(gethui)
        if ok and parent then return parent end
    end

    local ok, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok and coreGui then return coreGui end

    local player = game:GetService("Players").LocalPlayer
    assert(player, "PageManager must run on a client")
    return player:WaitForChild("PlayerGui")
end

function PageManager.new(options)
    options = options or {}
    local self = setmetatable({
        Pages = {},
        PageOrder = {},
        ActivePage = nil,
        TweenDuration = math.clamp(tonumber(options.TweenDuration) or 0.22, 0.05, 1),
        _transition = 0,
    }, PageManager)

    self.TweenService = game:GetService("TweenService")
    self.Gui = create("ScreenGui", {
        Name = "SynAdminPages",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 10000,
    }, options.Parent or defaultParent())

    local window = create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0.82, 0, 0.78, 0),
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 0,
    }, self.Gui)
    self.Window = window
    create("UISizeConstraint", {
        MinSize = Vector2.new(420, 280),
        MaxSize = Vector2.new(980, 680),
    }, window)
    create("UICorner", { CornerRadius = UDim.new(0, 14) }, window)
    create("UIStroke", { Color = COLORS.Raised, Thickness = 1 }, window)

    self.Sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 176, 1, 0),
        BackgroundColor3 = COLORS.Surface,
        BorderSizePixel = 0,
    }, window)
    create("UICorner", { CornerRadius = UDim.new(0, 14) }, self.Sidebar)
    create("Frame", {
        Name = "SidebarSquareEdge",
        Position = UDim2.new(1, -14, 0, 0),
        Size = UDim2.new(0, 14, 1, 0),
        BackgroundColor3 = COLORS.Surface,
        BorderSizePixel = 0,
    }, self.Sidebar)

    create("TextLabel", {
        Name = "Title",
        Position = UDim2.new(0, 18, 0, 19),
        Size = UDim2.new(1, -34, 0, 28),
        BackgroundTransparency = 1,
        Text = options.Title or "Syn-Admin",
        TextColor3 = COLORS.Text,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, self.Sidebar)

    self.Nav = create("Frame", {
        Name = "PageNavigation",
        Position = UDim2.new(0, 10, 0, 64),
        Size = UDim2.new(1, -20, 1, -78),
        BackgroundTransparency = 1,
    }, self.Sidebar)
    create("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, self.Nav)

    self.Content = create("Frame", {
        Name = "PageContainer",
        Position = UDim2.new(0, 176, 0, 0),
        Size = UDim2.new(1, -176, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    }, window)

    return self
end

function PageManager:AddPage(name, build, options)
    assert(type(name) == "string" and name ~= "", "Page name is required")
    assert(type(build) == "function", "Page builder must be a function")
    assert(not self.Pages[name], "A page named '" .. name .. "' already exists")
    options = options or {}

    local order = #self.PageOrder + 1
    local button = create("TextButton", {
        Name = name .. "Tab",
        LayoutOrder = order,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = COLORS.Surface,
        AutoButtonColor = true,
        BorderSizePixel = 0,
        Text = (options.Icon and (tostring(options.Icon) .. "   ") or "") .. name,
        TextColor3 = COLORS.Muted,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, self.Nav)
    create("UICorner", { CornerRadius = UDim.new(0, 8) }, button)
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 8),
    }, button)

    local page = create("CanvasGroup", {
        Name = name,
        Position = UDim2.new(0.035, 0, 0, 0),
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        GroupTransparency = 1,
        Visible = false,
    }, self.Content)

    local ok, err = pcall(build, page, self)
    if not ok then
        page:Destroy()
        button:Destroy()
        error("Could not build page '" .. name .. "': " .. tostring(err), 2)
    end

    self.Pages[name] = { Frame = page, Button = button }
    table.insert(self.PageOrder, name)
    button.Activated:Connect(function()
        self:Open(name)
    end)
    return page
end

function PageManager:Open(name, duration)
    local nextPage = self.Pages[name]
    if not nextPage then return false end
    if self.ActivePage == name then return true end

    self._transition = self._transition + 1
    local transition = self._transition
    local tweenDuration = math.clamp(tonumber(duration) or self.TweenDuration, 0.05, 1)
    local tweenInfo = TweenInfo.new(tweenDuration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    for pageName, page in pairs(self.Pages) do
        page.Button.BackgroundColor3 = pageName == name and COLORS.Raised or COLORS.Surface
        page.Button.TextColor3 = pageName == name and COLORS.Text or COLORS.Muted
    end

    if self.ActivePage then
        local oldName = self.ActivePage
        local oldPage = self.Pages[oldName]
        if oldPage then
            local out = self.TweenService:Create(oldPage.Frame, tweenInfo, {
                Position = UDim2.new(-0.035, 0, 0, 0),
                GroupTransparency = 1,
            })
            out.Completed:Connect(function(playbackState)
                if playbackState == Enum.PlaybackState.Completed and self.ActivePage ~= oldName then
                    oldPage.Frame.Visible = false
                end
            end)
            out:Play()
        end
    end

    nextPage.Frame.Visible = true
    nextPage.Frame.Position = UDim2.new(0.035, 0, 0, 0)
    nextPage.Frame.GroupTransparency = 1
    self.ActivePage = name
    self.TweenService:Create(nextPage.Frame, tweenInfo, {
        Position = UDim2.new(0, 0, 0, 0),
        GroupTransparency = 0,
    }):Play()
    return true
end

function PageManager:GetPages()
    local pages = {}
    for _, name in ipairs(self.PageOrder) do
        table.insert(pages, name)
    end
    return pages
end

function PageManager:Destroy()
    self._transition = self._transition + 1
    if self.Gui then self.Gui:Destroy() end
end

return PageManager
