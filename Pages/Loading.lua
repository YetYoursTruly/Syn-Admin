return function(PageManager)
    PageManager:AddPage("Loading", function(page)
        local TweenService = game:GetService("TweenService")
        local RunService = game:GetService("RunService")
        local UserInputService = game:GetService("UserInputService")

        local background = Instance.new("Frame")
        background.Name = "WaterBackground"
        background.Size = UDim2.fromScale(1, 1)
        background.BackgroundColor3 = Color3.fromRGB(2, 3, 6)
        background.BorderSizePixel = 0
        background.ClipsDescendants = true
        background.Parent = page

        local rows = {}
        local ramp = " .:-=+*#%@"
        local textSize = 10
        local charWidth, charHeight = 7, 12
        local columns, rowCount = 0, 0

        local function buildWater()
            for _, row in ipairs(rows) do row:Destroy() end
            table.clear(rows)

            local width = background.AbsoluteSize.X
            local height = background.AbsoluteSize.Y
            if width <= 0 or height <= 0 then return end
            columns = math.ceil(width / charWidth) + 1
            rowCount = math.ceil(height / charHeight) + 1
            for index = 1, rowCount do
                local row = Instance.new("TextLabel")
                row.Name = "WaterRow" .. index
                row.Position = UDim2.fromOffset(0, (index - 1) * charHeight)
                row.Size = UDim2.new(1, 0, 0, charHeight)
                row.BackgroundTransparency = 1
                row.Font = Enum.Font.Code
                row.TextSize = textSize
                row.TextColor3 = Color3.fromRGB(210, 220, 235)
                row.TextTransparency = 0.68
                row.TextXAlignment = Enum.TextXAlignment.Left
                row.TextYAlignment = Enum.TextYAlignment.Top
                row.TextWrapped = false
                row.ZIndex = 1
                row.Parent = background
                rows[index] = row
            end
        end

        local panel = Instance.new("CanvasGroup")
        panel.Name = "LoadingPanel"
        panel.AnchorPoint = Vector2.new(0.5, 0.5)
        panel.Position = UDim2.new(0.5, 0, 0.5, 16)
        panel.Size = UDim2.new(1, -44, 0, 188)
        panel.BackgroundColor3 = Color3.fromRGB(4, 5, 8)
        panel.BackgroundTransparency = 0.12
        panel.BorderSizePixel = 0
        panel.GroupTransparency = 1
        panel.ZIndex = 3
        panel.Parent = background
        Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Transparency = 0.78
        stroke.Thickness = 1
        stroke.Parent = panel
        local scale = Instance.new("UIScale")
        scale.Scale = 0.94
        scale.Parent = panel

        local logo = Instance.new("Frame")
        logo.Name = "Logo"
        logo.AnchorPoint = Vector2.new(0.5, 0.5)
        logo.Position = UDim2.new(0.5, 0, 0, 38)
        logo.Size = UDim2.fromOffset(34, 34)
        logo.BackgroundTransparency = 1
        logo.ZIndex = 4
        logo.Parent = panel
        local diamond = Instance.new("Frame")
        diamond.Name = "Diamond"
        diamond.AnchorPoint = Vector2.new(0.5, 0.5)
        diamond.Position = UDim2.fromScale(0.5, 0.5)
        diamond.Size = UDim2.fromOffset(21, 21)
        diamond.Rotation = 45
        diamond.BackgroundTransparency = 1
        diamond.ZIndex = 4
        diamond.Parent = logo
        Instance.new("UICorner", diamond).CornerRadius = UDim.new(0, 4)
        local diamondStroke = Instance.new("UIStroke")
        diamondStroke.Color = Color3.fromRGB(255, 255, 255)
        diamondStroke.Thickness = 1.5
        diamondStroke.Transparency = 0.12
        diamondStroke.Parent = diamond

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Position = UDim2.new(0, 0, 0, 66)
        title.Size = UDim2.new(1, 0, 0, 30)
        title.BackgroundTransparency = 1
        title.Text = "Syn-Admin"
        title.TextColor3 = Color3.fromRGB(250, 250, 252)
        title.TextSize = 22
        title.Font = Enum.Font.GothamBold
        title.ZIndex = 4
        title.Parent = panel

        local subtitle = Instance.new("TextLabel")
        subtitle.Name = "Status"
        subtitle.Position = UDim2.new(0, 12, 0, 98)
        subtitle.Size = UDim2.new(1, -24, 0, 22)
        subtitle.BackgroundTransparency = 1
        subtitle.Text = "Ready to use"
        subtitle.TextColor3 = Color3.fromRGB(153, 161, 176)
        subtitle.TextSize = 12
        subtitle.Font = Enum.Font.Gotham
        subtitle.ZIndex = 4
        subtitle.Parent = panel

        local bar = Instance.new("Frame")
        bar.Name = "ProgressTrack"
        bar.AnchorPoint = Vector2.new(0.5, 0)
        bar.Position = UDim2.new(0.5, 0, 0, 140)
        bar.Size = UDim2.new(1, -72, 0, 3)
        bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        bar.BackgroundTransparency = 0.88
        bar.BorderSizePixel = 0
        bar.ClipsDescendants = true
        bar.ZIndex = 4
        bar.Parent = panel
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
        local fill = Instance.new("Frame")
        fill.Name = "IndeterminateFill"
        fill.Size = UDim2.new(0.28, 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        fill.BorderSizePixel = 0
        fill.ZIndex = 5
        fill.Parent = bar
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local connections = {}
        local elapsed, renderElapsed, spinnerElapsed = 0, 0, 0
        local pointer, splash = Vector2.new(-1000, -1000), nil
        local splashTime = 0
        table.insert(connections, UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                local mouse = UserInputService:GetMouseLocation()
                pointer = mouse - background.AbsolutePosition
            elseif input.UserInputType == Enum.UserInputType.Touch then
                pointer = Vector2.new(input.Position.X, input.Position.Y) - background.AbsolutePosition
            end
        end))
        table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mouse = UserInputService:GetMouseLocation()
                splash = mouse - background.AbsolutePosition
                splashTime = elapsed
            elseif input.UserInputType == Enum.UserInputType.Touch then
                splash = Vector2.new(input.Position.X, input.Position.Y) - background.AbsolutePosition
                splashTime = elapsed
            end
        end))

        buildWater()
        table.insert(connections, background:GetPropertyChangedSignal("AbsoluteSize"):Connect(buildWater))
        table.insert(connections, RunService.RenderStepped:Connect(function(dt)
            if not background.Parent then return end
            elapsed += dt
            renderElapsed += dt
            spinnerElapsed += dt
            diamond.Rotation = 45 + spinnerElapsed * 90
            fill.Position = UDim2.new(((elapsed * 0.55) % 1.35) - 0.28, 0, 0, 0)
            if renderElapsed < 1 / 12 then return end
            renderElapsed = 0

            local width = background.AbsoluteSize.X
            for r, row in ipairs(rows) do
                local y = (r - 0.5) * charHeight
                local chars = table.create(columns)
                for c = 1, columns do
                    local x = (c - 0.5) * charWidth
                    local wave = math.sin(x * 0.035 + elapsed * 1.25) * 0.5
                        + math.sin(y * 0.055 - elapsed * 0.9) * 0.3
                    local dx, dy = x - pointer.X, y - pointer.Y
                    local distance = math.sqrt(dx * dx + dy * dy)
                    if distance < 70 then
                        wave += math.sin(distance * 0.12 - elapsed * 5) * (1 - distance / 70) * 0.7
                    end
                    if splash then
                        local sx, sy = x - splash.X, y - splash.Y
                        local sd = math.sqrt(sx * sx + sy * sy)
                        if sd < 100 then wave += math.sin(sd * 0.12 - elapsed * 7) * (1 - sd / 100) end
                    end
                    local value = math.clamp(math.floor((wave + 1.15) / 2.3 * #ramp) + 1, 1, #ramp)
                    chars[c] = ramp:sub(value, value)
                end
                row.Text = table.concat(chars)
            end
            if splash and elapsed - splashTime > 0.7 then splash = nil end
        end))

        local entrance = TweenInfo.new(0.62, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        TweenService:Create(panel, entrance, {
            Position = UDim2.new(0.5, 0, 0.5, 0),
            GroupTransparency = 0,
        }):Play()
        TweenService:Create(scale, entrance, { Scale = 1 }):Play()

        page.Destroying:Connect(function()
            for _, connection in ipairs(connections) do connection:Disconnect() end
        end)
    end, { Icon = "⌂" })
end

