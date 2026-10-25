return function(PageManager)
    PageManager:AddPage("Loading", function(page)
        local title = Instance.new("TextLabel")
        title.Name = "Heading"
        title.BackgroundTransparency = 1
        title.Position = UDim2.new(0, 28, 0, 24)
        title.Size = UDim2.new(1, -56, 0, 38)
        title.Font = Enum.Font.GothamBold
        title.Text = "Syn-Admin is ready"
        title.TextColor3 = Color3.fromRGB(235, 239, 248)
        title.TextSize = 24
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = page

        local description = Instance.new("TextLabel")
        description.Name = "Description"
        description.BackgroundTransparency = 1
        description.Position = UDim2.new(0, 28, 0, 70)
        description.Size = UDim2.new(1, -56, 0, 54)
        description.Font = Enum.Font.Gotham
        description.Text = "Pages are registered in PageManager. Add each window as a module in the Pages folder."
        description.TextColor3 = Color3.fromRGB(146, 155, 174)
        description.TextSize = 15
        description.TextWrapped = true
        description.TextXAlignment = Enum.TextXAlignment.Left
        description.TextYAlignment = Enum.TextYAlignment.Top
        description.Parent = page
    end, { Icon = "⌂" })
end
