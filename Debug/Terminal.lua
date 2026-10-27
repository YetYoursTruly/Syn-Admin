return function(context)
    context = type(context) == "table" and context or {}

    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")

    local function log(message, level)
        if type(context.Log) == "function" then
            pcall(context.Log, message, level or "INFO")
        else
            warn("[Syn-Admin][" .. tostring(level or "INFO") .. "] " .. tostring(message))
        end
    end

    local parent

    if type(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok then
            parent = result
        end
    end

    if not parent then
        local ok, result = pcall(function()
            return game:GetService("CoreGui")
        end)

        if ok then
            parent = result
        end
    end

    if not parent then
        local player = Players.LocalPlayer

        if player then
            local ok, result = pcall(function()
                return player:WaitForChild("PlayerGui", 5)
            end)

            if ok then
                parent = result
            end
        end
    end

    if not parent then
        log("Terminal could not find a GUI parent", "ERROR")
        return
    end

    local success, err = pcall(function()
        local old = parent:FindFirstChild("SynAdminDebugTerminal")
        if old then
            old:Destroy()
        end

        local gui = Instance.new("ScreenGui")
        gui.Name = "SynAdminDebugTerminal"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 20000
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Parent = parent

        local window = Instance.new("Frame")
        window.Name = "Terminal"
        window.AnchorPoint = Vector2.new(0.5, 0.5)
        window.Position = UDim2.fromScale(0.5, 0.5)
        window.Size = UDim2.new(0.72, 0, 0.62, 0)
        window.BackgroundColor3 = Color3.fromRGB(7, 8, 10)
        window.BorderSizePixel = 0
        window.Parent = gui

        Instance.new("UICorner", window).CornerRadius = UDim.new(0, 10)

        local constraint = Instance.new("UISizeConstraint")
        constraint.MinSize = Vector2.new(340, 240)
        constraint.MaxSize = Vector2.new(760, 520)
        constraint.Parent = window

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Transparency = 0.78
        stroke.Thickness = 1
        stroke.Parent = window

        local header = Instance.new("TextButton")
        header.Name = "Header"
        header.Size = UDim2.new(1, 0, 0, 34)
        header.BackgroundColor3 = Color3.fromRGB(15, 16, 19)
        header.BorderSizePixel = 0
        header.AutoButtonColor = false
        header.Text = "  SYN-ADMIN / DEBUG TERMINAL"
        header.TextColor3 = Color3.fromRGB(225, 229, 237)
        header.TextSize = 12
        header.Font = Enum.Font.Code
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.Parent = window

        Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

        local close = Instance.new("TextButton")
        close.Name = "Close"
        close.AnchorPoint = Vector2.new(1, 0.5)
        close.Position = UDim2.new(1, -7, 0.5, 0)
        close.Size = UDim2.fromOffset(24, 22)
        close.BackgroundColor3 = Color3.fromRGB(35, 36, 40)
        close.BorderSizePixel = 0
        close.Text = "×"
        close.TextColor3 = Color3.fromRGB(235, 235, 235)
        close.TextSize = 18
        close.Font = Enum.Font.Gotham
        close.Parent = header

        Instance.new("UICorner", close).CornerRadius = UDim.new(0, 5)

        local output = Instance.new("ScrollingFrame")
        output.Name = "Output"
        output.Position = UDim2.new(0, 10, 0, 43)
        output.Size = UDim2.new(1, -20, 1, -91)
        output.BackgroundTransparency = 1
        output.BorderSizePixel = 0
        output.ScrollBarThickness = 4
        output.AutomaticCanvasSize = Enum.AutomaticSize.Y
        output.ScrollingDirection = Enum.ScrollingDirection.Y
        output.CanvasSize = UDim2.new()
        output.Parent = window

        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 3)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Parent = output

        local input = Instance.new("TextBox")
        input.Name = "CustomLogInput"
        input.Position = UDim2.new(0, 10, 1, -38)
        input.Size = UDim2.new(1, -20, 0, 27)
        input.BackgroundColor3 = Color3.fromRGB(18, 19, 23)
        input.BorderSizePixel = 0
        input.ClearTextOnFocus = false
        input.PlaceholderText = "Type a log message and press Enter"
        input.PlaceholderColor3 = Color3.fromRGB(115, 120, 130)
        input.Text = ""
        input.TextColor3 = Color3.fromRGB(240, 242, 245)
        input.TextSize = 12
        input.Font = Enum.Font.Code
        input.TextXAlignment = Enum.TextXAlignment.Left
        input.Parent = window

        Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)

        local inputPadding = Instance.new("UIPadding")
        inputPadding.PaddingLeft = UDim.new(0, 8)
        inputPadding.PaddingRight = UDim.new(0, 8)
        inputPadding.Parent = input

        local rows = {}
        local connections = {}
        local destroyed = false

        local function append(level, message)
            if destroyed or not output.Parent then
                return
            end

            level = tostring(level or "INFO"):upper()
            message = tostring(message)

            local row = Instance.new("TextLabel")
            row.Name = "LogEntry"
            row.Size = UDim2.new(1, -4, 0, 18)
            row.AutomaticSize = Enum.AutomaticSize.Y
            row.BackgroundTransparency = 1
            row.TextWrapped = true
            row.TextXAlignment = Enum.TextXAlignment.Left
            row.TextYAlignment = Enum.TextYAlignment.Top
            row.Font = Enum.Font.Code
            row.TextSize = 12
            row.LayoutOrder = #rows + 1

            if level == "ERROR" then
                row.TextColor3 = Color3.fromRGB(255, 120, 120)
            elseif level == "WARN" then
                row.TextColor3 = Color3.fromRGB(255, 205, 120)
            elseif level == "CUSTOM" or level == "INPUT" then
                row.TextColor3 = Color3.fromRGB(150, 205, 255)
            else
                row.TextColor3 = Color3.fromRGB(205, 213, 225)
            end

            row.Text = string.format("[%s] %s", level, message)
            row.Parent = output

            table.insert(rows, row)

            while #rows > 250 do
                local first = table.remove(rows, 1)
                if first then
                    first:Destroy()
                end
            end

            task.defer(function()
                if output.Parent then
                    output.CanvasPosition = Vector2.new(
                        0,
                        math.max(0, output.AbsoluteCanvasSize.Y)
                    )
                end
            end)
        end

        -- Keep the logger installed by Loader.lua and forward to it.
        local previousLog = context.Log

        context.Terminal = {
            Log = append,
            Gui = gui,
        }

        context.Log = function(message, level)
            append(level or "INFO", message)

            if type(previousLog) == "function" then
                pcall(previousLog, message, level or "INFO")
            end
        end

        _G.SynAdminLog = context.Log

        -- Show logs recorded before the terminal finished starting.
        for _, entry in ipairs(context.LogHistory or {}) do
            append(entry.Level, entry.Message)
        end

        append("INFO", "Terminal ready.")

        table.insert(connections, close.Activated:Connect(function()
            gui.Enabled = false
        end))

        table.insert(connections, input.FocusLost:Connect(function(enterPressed)
            if not enterPressed then
                return
            end

            local message = input.Text
            input.Text = ""

            if message ~= "" then
                context.Log(message, "CUSTOM")
            end
        end))

        -- Dragging.
        local dragging = false
        local dragStart
        local startPosition

        table.insert(connections, header.InputBegan:Connect(function(event)
            if event.UserInputType == Enum.UserInputType.MouseButton1
                or event.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = event.Position
                startPosition = window.Position
            end
        end))

        table.insert(connections, UserInputService.InputChanged:Connect(function(event)
            if not dragging then
                return
            end

            if event.UserInputType ~= Enum.UserInputType.MouseMovement
                and event.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            local delta = event.Position - dragStart

            window.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end))

        table.insert(connections, UserInputService.InputEnded:Connect(function(event)
            if event.UserInputType == Enum.UserInputType.MouseButton1
                or event.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))

        table.insert(connections, gui.Destroying:Connect(function()
            destroyed = true

            for _, connection in ipairs(connections) do
                pcall(function()
                    connection:Disconnect()
                end)
            end

            if _G.SynAdminLog == context.Log then
                _G.SynAdminLog = nil
            end
        end))
    end)

    if not success then
        log("Terminal creation failed: " .. tostring(err), "ERROR")
    end
end
