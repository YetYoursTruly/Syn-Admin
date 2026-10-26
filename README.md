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


## Built-in scripts and Script Hub

Add a Lua module anywhere under `Scripts/`. Each module must return a descriptor
with this structure; the Script Hub lists it and runs `Load(context)` when the
user presses its Load button:

```lua
return {
    Id = "Example/Hello", -- unique; defaults to the path under Scripts/
    Name = "Hello",
    Description = "A short description shown in Script Hub.",
    Author = "Your name",
    Version = "1.0.0",
    Game = "Universal", -- label only, for example a game name
    Category = "Utility",
    Load = function(context)
        -- context includes PageManager, Game, Players, Workspace, HttpService,
        -- and context.Script (this descriptor).
        print("Hello from " .. context.Script.Name)
    end,
}
```

The loader fetches descriptors from this repository's `Scripts/` folder at
startup. Script code only runs after the user selects Load in Script Hub.
