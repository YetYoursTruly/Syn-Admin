return function(PageManager)
    PageManager:AddPage("Loading", function(page)
        local TweenService = game:GetService("TweenService")
        local RunService = game:GetService("RunService")
        local UserInputService = game:GetService("UserInputService")

        -- The splash sits above the window and fills the actual screen.
        local overlayGui = Instance.new("ScreenGui")
        overlayGui.Name = "SynAdminLoadingOverlay"
        overlayGui.IgnoreGuiInset = true
        overlayGui.ResetOnSpawn = false
        overlayGui.DisplayOrder = PageManager.Gui.DisplayOrder + 1
        overlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        overlayGui.Enabled = false
        overlayGui.Parent = PageManager.Gui.Parent

        local overlay = Instance.new("CanvasGroup")
        overlay.Name = "FullscreenFade"
        overlay.Size = UDim2.fromScale(1, 1)
        overlay.BackgroundTransparency = 1
        overlay.GroupTransparency = 1
        overlay.Parent = overlayGui

        local background = Instance.new("Frame")
        background.Name = "WaterBackground"
        background.Size = UDim2.fromScale(1, 1)
        background.BackgroundColor3 = Color3.fromRGB(2, 3, 6)
        background.BorderSizePixel = 0
        background.ClipsDescendants = true
        background.Parent = overlay

        local rows = {}
        local ramp = " .:-=+*#%@"
        local textSize = 14
        local charWidth, charHeight = 8, 14
        local columns = 0

        local function buildWater()
            for _, row in ipairs(rows) do row:Destroy() end
            table.clear(rows)

            local size = background.AbsoluteSize
            if size.X <= 0 or size.Y <= 0 then return end
            columns = math.ceil(size.X / charWidth) + 1
            local rowCount = math.ceil(size.Y / charHeight) + 1
            for index = 1, rowCount do
                local row = Instance.new("TextLabel")
                row.Name = "WaterRow" .. index
                row.Position = UDim2.fromOffset(0, (index - 1) * charHeight)
                row.Size = UDim2.new(1, 0, 0, charHeight)
                row.BackgroundTransparency = 1
                row.Font = Enum.Font.Code
                row.TextSize = textSize
                row.TextColor3 = Color3.fromRGB(220, 228, 240)
                row.TextTransparency = 0.58
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
        panel.Position = UDim2.new(0.5, 0, 0.5, 18)
        panel.Size = UDim2.new(1, -36, 0, 204)
        panel.BackgroundColor3 = Color3.fromRGB(4, 5, 8)
        panel.BackgroundTransparency = 0.1
        panel.BorderSizePixel = 0
        panel.GroupTransparency = 1
        panel.ZIndex = 3
        panel.Parent = background
        local sizeConstraint = Instance.new("UISizeConstraint")
        sizeConstraint.MinSize = Vector2.new(260, 204)
        sizeConstraint.MaxSize = Vector2.new(400, 204)
        sizeConstraint.Parent = panel
        Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Transparency = 0.78
        stroke.Thickness = 1
        stroke.Parent = panel
        local scale = Instance.new("UIScale")
        scale.Scale = 0.94
        scale.Parent = panel

        local logo = Instance.new("ImageLabel")
        logo.Name = "Logo"
        logo.AnchorPoint = Vector2.new(0.5, 0.5)
        logo.Position = UDim2.new(0.5, 0, 0, 42)
        logo.Size = UDim2.fromOffset(54, 54)
        logo.BackgroundTransparency = 1
        logo.ScaleType = Enum.ScaleType.Fit
        logo.ZIndex = 4
        logo.Parent = panel
        local resolveAsset = PageManager.ResolveAsset
        if type(resolveAsset) == "function" then
            local ok, image = pcall(resolveAsset, "Assets/Images/Syn-Admin Icon.png")
            if ok and image then
                logo.Image = image
            else
                local fallbackOk, fallback = pcall(resolveAsset, "Assets/Images/x.png")
                if fallbackOk and fallback then logo.Image = fallback end
            end
        end

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Position = UDim2.new(0, 0, 0, 78)
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
        subtitle.Position = UDim2.new(0, 12, 0, 112)
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
        bar.Position = UDim2.new(0.5, 0, 0, 156)
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
        local elapsed, renderElapsed = 0, 0
        local pointer = Vector2.new(-1000, -1000)
        local splash, splashTime = nil, 0
        table.insert(connections, UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                pointer = UserInputService:GetMouseLocation() - background.AbsolutePosition
            elseif input.UserInputType == Enum.UserInputType.Touch then
                pointer = Vector2.new(input.Position.X, input.Position.Y) - background.AbsolutePosition
            end
        end))
        table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                splash = UserInputService:GetMouseLocation() - background.AbsolutePosition
                splashTime = elapsed
            elseif input.UserInputType == Enum.UserInputType.Touch then
                splash = Vector2.new(input.Position.X, input.Position.Y) - background.AbsolutePosition
                splashTime = elapsed
            end
        end))

        buildWater()
        table.insert(connections, background:GetPropertyChangedSignal("AbsoluteSize"):Connect(buildWater))
        table.insert(connections, RunService.RenderStepped:Connect(function(dt)
            if not overlayGui.Enabled or not page.Visible then return end
            elapsed += dt
            renderElapsed += dt
            fill.Position = UDim2.new(((elapsed * 0.55) % 1.35) - 0.28, 0, 0, 0)
            if renderElapsed < 1 / 12 then return end
            renderElapsed = 0

            for r, row in ipairs(rows) do
                local y = (r - 0.5) * charHeight
                local chars = table.create(columns)
                for c = 1, columns do
                    local x = (c - 0.5) * charWidth
                    local wave = math.sin(x * 0.014 + y * 0.006 + elapsed * 0.5) * 0.7
                        + math.sin(y * 0.02 - x * 0.004 - elapsed * 0.38) * 0.45
                    local dx, dy = x - pointer.X, y - pointer.Y
                    local distance = math.sqrt(dx * dx + dy * dy)
                    if distance < 100 then
                        wave += math.sin(distance * 0.1 - elapsed * 4) * (1 - distance / 100) * 0.7
                    end
                    if splash then
                        local sx, sy = x - splash.X, y - splash.Y
                        local splashDistance = math.sqrt(sx * sx + sy * sy)
                        if splashDistance < 130 then
                            wave += math.sin(splashDistance * 0.1 - (elapsed - splashTime) * 7)
                                * (1 - splashDistance / 130)
                        end
                    end
                    local shade = math.clamp(math.floor((wave + 1.7) / 3.4 * #ramp) + 1, 1, #ramp)
                    chars[c] = ramp:sub(shade, shade)
                end
                row.Text = table.concat(chars)
            end
            if splash and elapsed - splashTime > 1.2 then splash = nil end
        end))

        local entrance = TweenInfo.new(0.62, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        local splashToken = 0
        local function showSplash()
            splashToken += 1
            local token = splashToken
            overlayGui.Enabled = true
            overlay.GroupTransparency = 1
            panel.Position = UDim2.new(0.5, 0, 0.5, 18)
            panel.GroupTransparency = 1
            scale.Scale = 0.94
            TweenService:Create(overlay, entrance, { GroupTransparency = 0 }):Play()
            TweenService:Create(panel, entrance, {
                Position = UDim2.new(0.5, 0, 0.5, 0),
                GroupTransparency = 0,
            }):Play()
            TweenService:Create(scale, entrance, { Scale = 1 }):Play()

            task.delay(2.2, function()
                if token ~= splashToken or not overlayGui.Parent then return end
                if not page.Visible then
                    overlayGui.Enabled = false
                    return
                end
                local fade = TweenService:Create(overlay,
                    TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { GroupTransparency = 1 })
                fade:Play()
                fade.Completed:Wait()
                if token == splashToken and overlayGui.Parent then overlayGui.Enabled = false end
            end)
        end

        table.insert(connections, page:GetPropertyChangedSignal("Visible"):Connect(function()
            if page.Visible then
                showSplash()
            else
                splashToken += 1
                overlayGui.Enabled = false
            end
        end))
        page.Destroying:Connect(function()
            splashToken += 1
            for _, connection in ipairs(connections) do connection:Disconnect() end
            if overlayGui.Parent then overlayGui:Destroy() end
        end)
    end, { Icon = "⌂" })
end
