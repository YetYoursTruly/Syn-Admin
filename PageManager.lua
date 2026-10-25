local PageManager = {}
PageManager.__index = PageManager

local COLORS = {
    Background = Color3.fromRGB(4, 4, 4),
    Surface = Color3.fromRGB(8, 8, 8),
    Raised = Color3.fromRGB(22, 22, 22),
    Text = Color3.fromRGB(245, 246, 248),
    Muted = Color3.fromRGB(145, 147, 153),
    Accent = Color3.fromRGB(218, 231, 255),
    Border = Color3.fromRGB(255, 255, 255),
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

    local window = create("CanvasGroup", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 12),
        Size = UDim2.new(0.72, 0, 0.68, 0),
        BackgroundColor3 = COLORS.Background,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        ClipsDescendants = true,
    }, self.Gui)
    self.Window = window
    create("UISizeConstraint", {
        MinSize = Vector2.new(380, 280),
        MaxSize = Vector2.new(760, 520),
    }, window)
    self.WindowScale = create("UIScale", { Scale = 0.965 }, window)
    create("UICorner", { CornerRadius = UDim.new(0, 14) }, window)
    self.EdgeStroke = create("UIStroke", {
        Color = COLORS.Border,
        Thickness = 1,
        Transparency = 0.3,
    }, window)
    self.GlowStroke = create("UIStroke", {
        Color = COLORS.Accent,
        Thickness = 9,
        Transparency = 0.82,
    }, window)

    local entranceInfo = TweenInfo.new(0.48, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    self.TweenService:Create(window, entranceInfo, {
        Position = UDim2.fromScale(0.5, 0.5),
        GroupTransparency = 0,
    }):Play()
    self.TweenService:Create(self.WindowScale, entranceInfo, { Scale = 1 }):Play()

    self.GlowTween = self.TweenService:Create(self.GlowStroke,
        TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Transparency = 0.94 }
    )
    self.GlowTween:Play()

    self.Sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 156, 1, 0),
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
        Position = UDim2.new(0, 17, 0, 18),
        Size = UDim2.new(1, -32, 0, 26),
        BackgroundTransparency = 1,
        Text = options.Title or "Syn-Admin",
        TextColor3 = COLORS.Text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, self.Sidebar)

    self.Nav = create("Frame", {
        Name = "PageNavigation",
        Position = UDim2.new(0, 9, 0, 58),
        Size = UDim2.new(1, -18, 1, -70),
        BackgroundTransparency = 1,
    }, self.Sidebar)
    create("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, self.Nav)

    self.Content = create("Frame", {
        Name = "PageContainer",
        Position = UDim2.new(0, 156, 0, 0),
        Size = UDim2.new(1, -156, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    }, window)

    local closeButton = create("TextButton", {
        Name = "CloseButton",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 10),
        Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = COLORS.Raised,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "×",
        TextColor3 = COLORS.Muted,
        TextSize = 20,
        Font = Enum.Font.Gotham,
    }, window)
    create("UICorner", { CornerRadius = UDim.new(0, 8) }, closeButton)
    closeButton.Activated:Connect(function()
        self:Close()
    end)

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
        AutoButtonColor = false,
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
    button.MouseEnter:Connect(function()
        if self.ActivePage ~= name then
            self.TweenService:Create(button, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = COLORS.Raised,
                TextColor3 = COLORS.Text,
            }):Play()
        end
    end)
    button.MouseLeave:Connect(function()
        if self.ActivePage ~= name then
            self.TweenService:Create(button, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = COLORS.Surface,
                TextColor3 = COLORS.Muted,
            }):Play()
        end
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
        self.TweenService:Create(page.Button,
            TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                BackgroundColor3 = pageName == name and COLORS.Raised or COLORS.Surface,
                TextColor3 = pageName == name and COLORS.Text or COLORS.Muted,
            }
        ):Play()
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
    if self.GlowTween then self.GlowTween:Cancel() end
    if self.Gui then self.Gui:Destroy() end
end

function PageManager:Close()
    if self._closing or not self.Gui then return end
    self._closing = true
    self._transition = self._transition + 1
    if self.GlowTween then self.GlowTween:Cancel() end

    local closeTween = self.TweenService:Create(self.Window,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { GroupTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, 10) }
    )
    self.TweenService:Create(self.WindowScale,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Scale = 0.97 }
    ):Play()
    closeTween.Completed:Connect(function(playbackState)
        if playbackState == Enum.PlaybackState.Completed then
            self:Destroy()
        end
    end)
    closeTween:Play()
end

return PageManager
