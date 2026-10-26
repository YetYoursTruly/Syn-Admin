local function label(parent, name, text, position, size, textSize, color)
    local object = Instance.new("TextLabel")
    object.Name = name
    object.BackgroundTransparency = 1
    object.Position = position
    object.Size = size
    object.Font = Enum.Font.Gotham
    object.Text = text
    object.TextColor3 = color
    object.TextSize = textSize
    object.TextXAlignment = Enum.TextXAlignment.Left
    object.TextWrapped = true
    object.Parent = parent
    return object
end

return function(PageManager, ScriptManager)
    PageManager:AddPage("Script Hub", function(page)
        local heading = label(page, "Heading", "Script Hub", UDim2.new(0, 20, 0, 16), UDim2.new(1, -40, 0, 28), 20, Color3.fromRGB(245, 246, 248))
        heading.Font = Enum.Font.GothamBold
        label(page, "Description", "Choose a plugin to load.", UDim2.new(0, 20, 0, 45), UDim2.new(1, -40, 0, 24), 12, Color3.fromRGB(145, 147, 153))
        local status = label(page, "Status", "Ready", UDim2.new(0, 20, 1, -31), UDim2.new(1, -40, 0, 20), 11, Color3.fromRGB(145, 147, 153))

        local list = Instance.new("ScrollingFrame")
        list.Name = "Scripts"
        list.Position = UDim2.new(0, 20, 0, 78)
        list.Size = UDim2.new(1, -40, 1, -116)
        list.BackgroundTransparency = 1
        list.BorderSizePixel = 0
        list.ScrollBarThickness = 3
        list.CanvasSize = UDim2.new()
        list.AutomaticCanvasSize = Enum.AutomaticSize.Y
        list.Parent = page
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = list

        local scripts = ScriptManager:GetAll()
        for index, script in ipairs(scripts) do
            local card = Instance.new("Frame")
            card.Name = script.Id:gsub("[^%w_%-]", "_")
            card.LayoutOrder = index
            card.Size = UDim2.new(1, -6, 0, 76)
            card.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
            card.BorderSizePixel = 0
            card.Parent = list
            Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

            local icon = Instance.new("ImageLabel")
            icon.Name = "Icon"
            icon.Position = UDim2.new(0, 10, 0.5, -21)
            icon.Size = UDim2.fromOffset(42, 42)
            icon.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            icon.BorderSizePixel = 0
            icon.Image = script.Icon or ScriptManager.DefaultIcon or ""
            icon.ScaleType = Enum.ScaleType.Crop
            icon.Parent = card
            Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 7)

            local title = label(card, "Name", script.Name, UDim2.new(0, 61, 0, 8), UDim2.new(1, -154, 0, 20), 13, Color3.fromRGB(245, 246, 248))
            title.Font = Enum.Font.GothamSemibold
            label(card, "Details", script.Description .. "  ·  " .. script.Game .. "  ·  v" .. script.Version,
                UDim2.new(0, 61, 0, 31), UDim2.new(1, -154, 0, 34), 10, Color3.fromRGB(145, 147, 153))

            local run = Instance.new("TextButton")
            run.Name = "Load"
            run.AnchorPoint = Vector2.new(1, 0.5)
            run.Position = UDim2.new(1, -9, 0.5, 0)
            run.Size = UDim2.fromOffset(74, 32)
            run.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            run.BorderSizePixel = 0
            run.AutoButtonColor = true
            run.Font = Enum.Font.GothamSemibold
            run.Text = "Load"
            run.TextColor3 = Color3.fromRGB(20, 20, 20)
            run.TextSize = 12
            run.Parent = card
            Instance.new("UICorner", run).CornerRadius = UDim.new(0, 7)

            run.Activated:Connect(function()
                run.Active = false
                status.Text = "Loading " .. script.Name .. "..."
                status.TextColor3 = Color3.fromRGB(235, 190, 90)
                task.spawn(function()
                    local finished, succeeded, result = false, false, nil
                    task.spawn(function()
                        succeeded, result = ScriptManager:Run(script.Id)
                        finished = true
                    end)
                    local frames = { "Loading", "Loading.", "Loading..", "Loading..." }
                    local frame = 1
                    while not finished and run.Parent do
                        run.Text = frames[frame]
                        frame = frame % #frames + 1
                        task.wait(0.25)
                    end
                    if not run.Parent then return end
                    run.Active = true
                    run.Text = succeeded and "Loaded" or "Retry"
                    status.Text = succeeded and (script.Name .. " loaded") or ("Failed: " .. tostring(result))
                    status.TextColor3 = succeeded and Color3.fromRGB(120, 210, 145) or Color3.fromRGB(235, 110, 110)
                    task.wait(1.5)
                    if run.Parent then run.Text = "Load" end
                end)
            end)
        end
        if #scripts == 0 then
            label(list, "Empty", "No plugin folders found. Add a folder with Loader.lua under Scripts/.", UDim2.new(), UDim2.new(1, -8, 0, 44), 12, Color3.fromRGB(145, 147, 153))
        end
    end, { Icon = "⇧" })
end
