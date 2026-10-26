# Syn-Admin

## Loader

`Loader.lua` returns a startup function. It reads the repository tree, loads
`PageManager.lua`, registers every Lua page under `Pages/`, and opens the page
named by `StartPage` (or `Loading` by default).

```lua
local pageManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/YetYoursTruly/Syn-Admin/main/Loader.lua"
))({ StartPage = "Loading" })
```

Pass `true` or `{ Debug = true }` to opt into loading every Lua module under
`Debug/`:

```lua
local pageManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/YetYoursTruly/Syn-Admin/main/Loader.lua"
))({ Debug = true })
-- Short form: loadstring(game:HttpGet("https://raw.githubusercontent.com/YetYoursTruly/Syn-Admin/main/Loader.lua"))(true)

-- The older two-step form is still supported:
-- local startSynAdmin = loadstring(game:HttpGet(url))()
-- local pageManager = startSynAdmin({ Debug = true })
```

Debug modules should return a function that receives a context table. They
should only contain development diagnostics. Keep debug mode off for normal
use.

## Adding a page

Create a Lua file in `Pages/`. The file should return a registration function:

```lua
return function(PageManager)
    PageManager:AddPage("Example", function(page)
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -40, 0, 32)
        label.Position = UDim2.new(0, 20, 0, 20)
        label.Text = "Example page"
        label.Parent = page
    end, { Icon = "•" })
end
```

`PageManager:Open("Example")` switches tabs with a short fade-and-slide
tween. The duration can be set in seconds when switching tabs, or configured
when starting with `TweenDuration`.

The loader fetches source from the configured GitHub repository at runtime.
For this unauthenticated `loadstring` setup, the repository must be publicly
readable. Never put a GitHub token in `Loader.lua`.



## Script Hub plugins

Each plugin is a folder under `Scripts/` containing `Loader.lua`. An optional
`icon.png` in that same folder is shown in Script Hub. If it is missing, the
hub uses `Assets/Images/x.png`.

```text
Scripts/
  Example/
    Loader.lua
    icon.png       # optional
```

The Hub registers folders from their `Loader.lua` path. Pressing its white
**Load** button downloads and compiles that `Loader.lua` with `loadstring`.
The loader receives a plugin context as `...`; it can also return a function
that receives the same context:

```lua
local plugin = ...
plugin:AddPage("Example", function(page)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -32, 0, 32)
    label.Position = UDim2.new(0, 16, 0, 16)
    label.BackgroundTransparency = 1
    label.Text = "Example plugin page"
    label.Parent = page
end, { Icon = "•" })
```

Custom pages are exposed to plugin loaders through `plugin:AddPage`; plugin
loaders do not receive the raw PageManager. `plugin:OpenPage(name)` and
`plugin:GetPages()` are also available. Plugins receive `Game`, `Players`,
`Workspace`, `HttpService`, and `Script` in their context.
