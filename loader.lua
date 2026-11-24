-- AeroV4 Lite: pinned upstream UI, module allowlist for BedWars.
-- This repository does not contain or redistribute the upstream UI or module sources.
-- Upstream: https://github.com/wrealaero/aerov4

repeat task.wait() until game:IsLoaded()
-- Wait 10 seconds after the game has finished loading before initializing Aero.
task.wait(10)

-- Verify executor identity before downloading, running modules, or modifying any files.
-- Only exact name prefixes are allowed; names are case-insensitive.
local function executorFamily(name)
    if type(name) ~= 'string' then return nil end
    local normal = name:lower():match('^%s*(.-)%s*$')
    if normal == 'potassium' or normal:match('^potassium[%s%p]') then return 'Potassium' end
    if normal == 'real' or normal:match('^real[%s%p]') then return 'Real' end
    if normal == 'volt' or normal:match('^volt[%s%p]') then return 'Volt' end
    return nil
end

local detectedName = 'Unknown'
local executorKind
if type(identifyexecutor) == 'function' then
    local ok, name = pcall(identifyexecutor)
    if ok and type(name) == 'string' then
        detectedName = name
        executorKind = executorFamily(name)
    end
end
-- Fall back to getexecutorname() if the first identification is unavailable or unrecognized.
if not executorKind and type(getexecutorname) == 'function' then
    local ok, name = pcall(getexecutorname)
    if ok and type(name) == 'string' then
        detectedName = name
        executorKind = executorFamily(name)
    end
end

local function rejectAndUninject(message)
    -- Unload any previously running copy; this invocation has not injected yet.
    if type(shared) == 'table' and type(shared.vape) == 'table'
        and type(shared.vape.Uninject) == 'function' then
        pcall(function() shared.vape:Uninject() end)
    end
    -- Independent top-right error: survives AeroV4 Uninject.
    local ok, err = pcall(function()
        local parent
        -- PlayerGui is preferred for a visible client-side top-right error.
        local player = game:GetService('Players').LocalPlayer
        parent = player and player:FindFirstChildOfClass('PlayerGui')
        if not parent and type(gethui) == 'function' then
            local good, gui = pcall(gethui)
            if good and typeof(gui) == 'Instance' and not gui:IsA('ScreenGui') then
                parent = gui
            end
        end
        if not parent then parent = game:GetService('CoreGui') end

        local existing = parent:FindFirstChild('AeroV4LiteExecutorError')
        if existing then existing:Destroy() end
        local screen = Instance.new('ScreenGui')
        screen.Name = 'AeroV4LiteExecutorError'
        screen.IgnoreGuiInset = true
        screen.ResetOnSpawn = false
        screen.DisplayOrder = 999999
        screen.ZIndexBehavior = Enum.ZIndexBehavior.Global
        screen.Parent = parent

        local frame = Instance.new('Frame')
        frame.AnchorPoint = Vector2.new(1, 0)
        frame.Position = UDim2.new(1, -16, 0, 20)
        frame.Size = UDim2.fromOffset(350, 84)
        frame.BackgroundColor3 = Color3.fromRGB(37, 30, 32)
        frame.BorderSizePixel = 0
        frame.Parent = screen
        local corner = Instance.new('UICorner')
        corner.CornerRadius = UDim.new(0, 9)
        corner.Parent = frame
        local stripe = Instance.new('Frame')
        stripe.Size = UDim2.fromOffset(4, 84)
        stripe.BackgroundColor3 = Color3.fromRGB(236, 79, 92)
        stripe.BorderSizePixel = 0
        stripe.Parent = frame
        local title = Instance.new('TextLabel')
        title.BackgroundTransparency = 1
        title.Position = UDim2.fromOffset(15, 7)
        title.Size = UDim2.new(1, -26, 0, 25)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 15
        title.TextColor3 = Color3.fromRGB(255, 115, 125)
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = 'AeroV4 Lite - Unsupported executor'
        title.Parent = frame
        local detail = Instance.new('TextLabel')
        detail.BackgroundTransparency = 1
        detail.Position = UDim2.fromOffset(15, 32)
        detail.Size = UDim2.new(1, -26, 0, 43)
        detail.Font = Enum.Font.Gotham
        detail.TextSize = 12
        detail.TextWrapped = true
        detail.TextXAlignment = Enum.TextXAlignment.Left
        detail.TextYAlignment = Enum.TextYAlignment.Top
        detail.TextColor3 = Color3.fromRGB(232, 225, 225)
        detail.Text = message
        detail.Parent = frame
        task.delay(18, function()
            if screen and screen.Parent then screen:Destroy() end
        end)
    end)
    if not ok then
        warn('[AeroV4 Lite] Could not display top-right error: ' .. tostring(err))
        pcall(function()
            game:GetService('StarterGui'):SetCore('SendNotification', {
                Title = 'AeroV4 Lite: Unsupported executor',
                Text = message,
                Duration = 15
            })
        end)
    end
    warn('[AeroV4 Lite] Load aborted and existing instance uninject attempted: ' .. message)
end

if not executorKind then
    rejectAndUninject('Only Potassium, Real, and Volt are supported. Detected: ' .. detectedName .. '. Nothing was loaded.')
    return nil
end

print('[AeroV4 Lite] Selected executor: ' .. executorKind)


-- The module set below is specific to Roblox BedWars.
local BEDWARS_GAME_ID = 2619619496
if game.GameId ~= BEDWARS_GAME_ID then
    error('[AeroV4 Lite] This build only supports Roblox BedWars (GameId 2619619496).')
end

-- Pinning this known upstream snapshot prevents unexpected upstream changes.
local UPSTREAM_COMMIT = 'b723802d331778a362bfbd475fc2fb6f831c3fc1'
local UPSTREAM_BASE = 'https://raw.githubusercontent.com/wrealaero/aerov4/' .. UPSTREAM_COMMIT .. '/'
local DEFAULT_SELF_URL = 'https://raw.githubusercontent.com/elianxyzz-projects/elianware/main/loader.lua'
local env = getgenv()
local SELF_URL = env.AeroV4LiteURL or DEFAULT_SELF_URL

-- Verify essential executor capabilities before modifying cached files.
for _, fnName in ipairs({
    'getgenv', 'loadstring', 'readfile', 'writefile',
    'isfile', 'isfolder', 'makefolder', 'listfiles'
}) do
    if type(env[fnName]) ~= 'function' and type(_G[fnName]) ~= 'function' then
        error('[AeroV4 Lite] Your executor is missing ' .. fnName .. '. Cannot safely load.')
    end
end

print('[AeroV4 Lite] Starting original AeroV4 UI on ' .. executorKind)

if SELF_URL ~= nil and (type(SELF_URL) ~= 'string'
    or not SELF_URL:match('^https://raw%.githubusercontent%.com/.+/loader%.lua$')) then
    error('[AeroV4 Lite] AeroV4LiteURL must be a raw.githubusercontent.com URL ending with /loader.lua')
end

local function replaceOnce(haystack, needle, replacement, label)
    local startPos, endPos = haystack:find(needle, 1, true)
    if not startPos then
        error('[AeroV4 Lite] Upstream main.lua is incompatible (missing ' .. label .. '). No code executed.')
    end
    return haystack:sub(1, startPos - 1) .. replacement .. haystack:sub(endPos + 1)
end

local function getUpstream(path)
    local success, content = pcall(function()
        return game:HttpGet(UPSTREAM_BASE .. path, true)
    end)
    if not success or type(content) ~= 'string' or content == '' or content == '404: Not Found' then
        error('[AeroV4 Lite] Could not retrieve pinned upstream file ' .. path .. ': ' .. tostring(content))
    end
    return content
end

local function ensureFolder(path)
    if not isfolder(path) then makefolder(path) end
end

for _, folder in ipairs({
    'aerov4', 'aerov4/profiles', 'aerov4/assets',
    'aerov4/libraries', 'aerov4/guis', 'aerov4/games'
}) do
    ensureFolder(folder)
end

writefile('aerov4/profiles/commit.txt', UPSTREAM_COMMIT)
writefile('aerov4/profiles/latest.txt', UPSTREAM_COMMIT)
writefile('aerov4/profiles/gui.txt', 'new')

local filterCode = [==[
    -- Filter after BedWars module registration, before enabling saved modules.
    do
        local keep = {
            AimAssist = true,
            SilentAim = true,
            Reach = true,
            HitFix = true,
            KitESP = true,
            KitRender = true,
            NameTags = true,
            HitBoxes = true,
            ESP = true,
            BedPlates = true,
            FPSBoost = true,
            AutoTool = true,
            Freecam = true,
            FOV = true,
            CombatPing = true,
            HitDelayGraph = true,
            FrameTimeGraph = true,
            DamageTakenGraph = true,
            MovementSpeedGraph = true
        }
        local keepCategories = {
            Main = true,
            Friends = true,
            Targets = true,
            Profiles = true,
            Favorites = true,
            Combat = true,
            Blatant = true,
            Render = true,
            Utility = true,
            World = true,
            Kits = true,
            Minigames = true,
            Legit = true,
            ['Experimental (Ban)'] = true,
            Debug = true
        }
        local function pruneModules(tab)
            if type(tab) ~= 'table' then return end
            local unwanted = {}
            for moduleName in pairs(tab) do
                if not keep[moduleName] then
                    unwanted[#unwanted + 1] = moduleName
                end
            end
            for _, moduleName in ipairs(unwanted) do
                local module = tab[moduleName]
                if module and module.Enabled then
                    pcall(function() module:Toggle() end)
                end
                local ok, err = pcall(function() vape:Remove(moduleName) end)
                if not ok then
                    warn('[AeroV4 Lite] Could not remove ' .. moduleName .. ': ' .. tostring(err))
                end
            end
        end

        pruneModules(vape.Modules)
        if vape.Legit then pruneModules(vape.Legit.Modules) end

        -- Disable registration-time defaults before the original profile loader runs.
        -- Fresh profiles therefore start OFF; existing profiles then restore
        -- their saved Enabled values, along with all options and keybinds.
        local function stopEnabledModules(modules)
            if type(modules) ~= 'table' then return end
            for _, module in pairs(modules) do
                if module.Enabled and type(module.Toggle) == 'function' then
                    local ok, err = pcall(function() module:Toggle() end)
                    if not ok then
                        warn('[AeroV4 Lite] Could not disable active module: ' .. tostring(err))
                    end
                end
            end
        end
        stopEnabledModules(vape.Modules)
        if vape.Legit then stopEnabledModules(vape.Legit.Modules) end

        -- Keep internal categories for friend/target settings and other dependencies.
        if type(vape.Categories) == 'table' then
            for categoryName, category in pairs(vape.Categories) do
                if type(category) == 'table' and category.Type == 'Category'
                    and not keepCategories[categoryName] then
                    if category.Object then category.Object.Visible = false end
                    if category.Button and category.Button.Object then
                        category.Button.Object.Visible = false
                    end
                end
            end
        end


        -- Compact warnings shown only in the LSHIFT/click GUI.
        -- These are user-defined thresholds, not reliable ban predictions.
        do
            local gui = vape.gui
            local scaled = gui and gui:FindFirstChild('ScaledGui')
            local click = scaled and scaled:FindFirstChild('ClickGui')
            if click then
                local warnings = Instance.new('Frame')
                warnings.Name = 'ElianBlatancyWarnings'
                warnings.BackgroundTransparency = 1
                warnings.AnchorPoint = Vector2.new(1, 0)
                warnings.Position = UDim2.new(1, -12, 0, 12)
                warnings.Size = UDim2.fromOffset(242, 112)
                warnings.ZIndex = 100
                warnings.Parent = click

                local layout = Instance.new('UIListLayout')
                layout.SortOrder = Enum.SortOrder.LayoutOrder
                layout.Padding = UDim.new(0, 5)
                layout.Parent = warnings

                local function createWarning(order, message)
                    local box = Instance.new('Frame')
                    box.Name = 'Warning' .. order
                    box.LayoutOrder = order
                    box.Size = UDim2.new(1, 0, 0, 46)
                    box.BackgroundColor3 = Color3.fromRGB(117, 23, 30)
                    box.BorderSizePixel = 0
                    box.Visible = false
                    box.ZIndex = 101
                    box.Parent = warnings
                    local corner = Instance.new('UICorner')
                    corner.CornerRadius = UDim.new(0, 6)
                    corner.Parent = box
                    local stroke = Instance.new('UIStroke')
                    stroke.Color = Color3.fromRGB(235, 75, 84)
                    stroke.Thickness = 1
                    stroke.Parent = box
                    local label = Instance.new('TextLabel')
                    label.BackgroundTransparency = 1
                    label.Position = UDim2.fromOffset(9, 4)
                    label.Size = UDim2.new(1, -37, 1, -8)
                    label.Font = Enum.Font.GothamMedium
                    label.TextSize = 12
                    label.TextWrapped = true
                    label.TextXAlignment = Enum.TextXAlignment.Left
                    label.TextYAlignment = Enum.TextYAlignment.Center
                    label.TextColor3 = Color3.fromRGB(255, 243, 243)
                    label.Text = message
                    label.ZIndex = 102
                    label.Parent = box
                    local close = Instance.new('TextButton')
                    close.Name = 'Dismiss'
                    close.BackgroundTransparency = 1
                    close.AnchorPoint = Vector2.new(1, 0)
                    close.Position = UDim2.new(1, -5, 0, 4)
                    close.Size = UDim2.fromOffset(22, 22)
                    close.Font = Enum.Font.GothamBold
                    close.TextSize = 16
                    close.TextColor3 = Color3.fromRGB(255, 220, 220)
                    close.Text = 'X'
                    close.ZIndex = 103
                    close.Parent = box
                    return box, close
                end

                local banBox, banClose = createWarning(1, 'you can get banned for this')
                local clipBox, clipClose = createWarning(2, 'if you clip this, you will get banned')
                local dismissed = {ban = false, clip = false}
                local priorSignature

                banClose.MouseButton1Click:Connect(function()
                    dismissed.ban = true
                    banBox.Visible = false
                end)
                clipClose.MouseButton1Click:Connect(function()
                    dismissed.clip = true
                    clipBox.Visible = false
                end)

                local function normalize(value)
                    return tostring(value or ''):lower():gsub('[^%w]', '')
                end
                local function getModule(name)
                    local target = normalize(name)
                    for _, modules in ipairs({vape.Modules or {}, (vape.Legit and vape.Legit.Modules) or {}}) do
                        for key, module in pairs(modules) do
                            if normalize(key) == target then return module end
                        end
                    end
                end
                local function findOption(module, ...)
                    if type(module) ~= 'table' then return nil end
                    local keys = {...}
                    for _, key in ipairs(keys) do
                        for name, option in pairs(module.Options or {}) do
                            if normalize(name) == normalize(key) then return option end
                        end
                    end
                    return nil
                end
                local function numberOption(module, ...)
                    local option = findOption(module, ...)
                    if not option then return nil end
                    return tonumber(option.Value or option.CurrentValue)
                end
                local function selectedOption(module, ...)
                    local option = findOption(module, ...)
                    if not option then return nil end
                    return tostring(option.Value or option.Selected or option.Mode or '')
                end
                local function readPing()
                    local player = game:GetService('Players').LocalPlayer
                    if not player then return nil end
                    local ok, seconds = pcall(function() return player:GetNetworkPing() end)
                    if ok and type(seconds) == 'number' then
                        return seconds * 2000 -- round-trip latency, ms
                    end
                    return nil
                end

                local function check()
                    local reach = getModule('Reach')
                    local hitboxes = getModule('HitBoxes')
                    local silent = getModule('SilentAim')
                    local air = getModule('AirReach') or reach
                    local r = reach and reach.Enabled and numberOption(reach, 'Attack', 'Reach', 'Distance')
                    local h = hitboxes and hitboxes.Enabled and numberOption(hitboxes, 'Expand', 'Size', 'Hitbox', 'HitBoxes')
                    local ping = readPing()
                    local airPct = air and air.Enabled and numberOption(air, 'Air Hits Percentage', 'AirHitsPercentage', 'Air Hits', 'AirHits', 'Percentage')
                    local fov = silent and silent.Enabled and numberOption(silent, 'FOV')
                    local mode = selectedOption(silent, 'Mode', 'Target Mode', 'Targeting Mode') or ''
                    local distanceMode = normalize(mode):find('distance', 1, true) ~= nil

                    local ban = (h ~= nil and h > 25 and r ~= nil and r > 13.5 and ping ~= nil and ping < 120)
                        or (r ~= nil and r > 15)
                        or (airPct ~= nil and airPct > 85)
                        or (fov ~= nil and (fov > 85 or (fov > 40 and not distanceMode)))

                    local render = false
                    local renderNames = {
                        ESP = true, KitESP = true, KitRender = true, NameTags = true,
                        BedPlates = true
                    }
                    for _, modules in ipairs({vape.Modules or {}, (vape.Legit and vape.Legit.Modules) or {}}) do
                        for name, module in pairs(modules) do
                            if type(module) == 'table' and module.Enabled then
                                local category = module.Category
                                local categoryName = type(category) == 'table' and category.Name or category
                                if renderNames[name] or categoryName == 'Render' then
                                    render = true
                                    break
                                end
                            end
                        end
                        if render then break end
                    end
                    return ban, render, table.concat({
                        tostring(reach and reach.Enabled), tostring(r), tostring(hitboxes and hitboxes.Enabled),
                        tostring(h), tostring(ping ~= nil and ping < 130), tostring(ping ~= nil and ping > 200), tostring(airPct),
                        tostring(silent and silent.Enabled), tostring(fov), mode, tostring(render)
                    }, '|')
                end

                task.spawn(function()
                    while click.Parent and gui.Parent do
                        local ok, ban, clip, signature = pcall(check)
                        if ok then
                            if signature ~= priorSignature then
                                priorSignature = signature
                                dismissed.ban = false
                                dismissed.clip = false
                            end
                            banBox.Visible = ban and not dismissed.ban
                            clipBox.Visible = clip and not dismissed.clip
                        end
                        task.wait(0.25)
                    end
                end)
            else
                warn('[AeroV4 Lite] Warning UI unavailable: ClickGui not found')
            end
        end

        -- Previous full-client profiles must not reveal hidden categories.
        local experimentalFirstLoad = true
        local upstreamLoad = vape.Load
        if type(upstreamLoad) == 'function' then
            function vape:Load(...)
                local result = table.pack(upstreamLoad(self, ...))
                for categoryName, category in pairs(self.Categories or {}) do
                    if not keepCategories[categoryName]
                        and type(category) == 'table'
                        and category.Type == 'Category' then
                        if category.Object then category.Object.Visible = false end
                        if category.Button and category.Button.Object then
                            category.Button.Object.Visible = false
                        end
                    end
                end
                local experimental = self.Categories and self.Categories['Experimental (Ban)']
                if experimental and experimental.Button then
                    if experimental.Button.Object then experimental.Button.Object.Visible = true end
                    if experimentalFirstLoad then
                        experimentalFirstLoad = false
                        if not experimental.Button.Enabled then experimental.Button:Toggle() end
                        if not experimental.Expanded and experimental.Expand then experimental:Expand() end
                    end
                end
                return table.unpack(result, 1, result.n)
            end
        end
        if game.PlaceId == 6872274481 then
            for moduleName in pairs(keep) do
                if not ((vape.Modules and vape.Modules[moduleName])
                    or (vape.Legit and vape.Legit.Modules and vape.Legit.Modules[moduleName])) then
                    warn('[AeroV4 Lite] Missing upstream module: ' .. moduleName)
                end
            end
        end
    end
]==]

local originalMain = getUpstream('main.lua')
local needle = '\tfinishLoading()\nelse\n\tvape.Init = finishLoading'
local newMain = replaceOnce(
    originalMain,
    needle,
    filterCode .. '\n\tfinishLoading()\nelse\n\tvape.Init = finishLoading',
    'load-before-finish insertion point'
)

-- Ensure teleport reloads return to this Lite build instead of full upstream.
if SELF_URL then
    local oldLoader = 'local LOADER_URL = "https://raw.githubusercontent.com/wrealaero/aerov4/main/downloader.lua"'
    newMain = replaceOnce(newMain, oldLoader,
        'local LOADER_URL = ' .. string.format('%q', SELF_URL),
        'teleport loader URL')
    local marker = '\n\t\tif identifyexecutor and ({identifyexecutor()})[1] == \'Potassium\' then'
    local queuePrefix = 'getgenv().AeroV4LiteURL = ' .. string.format('%q', SELF_URL) .. '\n'
    newMain = replaceOnce(newMain, marker,
        '\n\t\tteleportScript = ' .. string.format('%q', queuePrefix) .. ' .. teleportScript' .. marker,
        'teleport queue context')
else
    newMain = replaceOnce(newMain,
        'local function buildTeleportScript()\n',
        'local function buildTeleportScript()\n\t\treturn nil -- Disable full-client reloader.\n',
        'teleport hook')
end

-- Fetch the original GUI, universal modules and selected BedWars game code.
writefile('aerov4/main.lua', newMain)
-- Use the original GUI profile loader without changing its saved Enabled states.
-- No saved profile -> modules stay disabled; saved profile -> prior enabled
-- module choices and all settings are restored automatically.
-- Load the supplied Elian banner as a local custom asset.
local imageURL = 'https://raw.githubusercontent.com/elianxyzz-projects/aeroclone/main/assets/elian.png'
local imageOK, imageBytes = pcall(function() return game:HttpGet(imageURL, true) end)
if imageOK and type(imageBytes) == 'string' and #imageBytes > 1000 then
    writefile('aerov4/assets/new/elian.png', imageBytes)
else
    warn('[AeroV4 Lite] Could not download custom Elian banner')
end

local customGUI = getUpstream('guis/new.lua')
-- Apply the Elian blue gradient to every category window and module row,
-- including the different pop-out menu windows constructed by the upstream GUI.
local blueMenuHelper = [==[
local function aeroLiteBlueGradient(object, subtle)
    if not object or object:FindFirstChild('AeroLiteBlueGradient') then return end
    local gradient = Instance.new('UIGradient')
    gradient.Name = 'AeroLiteBlueGradient'
    gradient.Rotation = 90
    gradient.Color = subtle and ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 52, 139)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(9, 78, 169)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(9, 112, 190))
    }) or ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 34, 132)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 109, 232)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(21, 195, 241))
    })
    gradient.Parent = object
end
]==]
local helperAnchor = 'local color = {}'
customGUI = replaceOnce(customGUI, helperAnchor, blueMenuHelper .. '\n' .. helperAnchor, 'blue-gradient helper')
local windowToken = 'window.Parent = clickgui'
local windowCount
customGUI, windowCount = customGUI:gsub(windowToken, windowToken .. '\n\t\taeroLiteBlueGradient(window, false)')
if windowCount < 3 then
    error('[AeroV4 Lite] Expected category/menu windows were not found for blue gradient')
end
customGUI = replaceOnce(customGUI,
    'modulebutton.Parent = children',
    'modulebutton.Parent = children\n\t\taeroLiteBlueGradient(modulebutton, true)',
    'module row gradient')

-- Replace only the main GUI branding and its Settings pane styling.
local oldLogo = "logo.Image = getcustomasset('aerov4/assets/new/guivape.png')"
local newLogo = "logo.Image = getcustomasset('aerov4/assets/new/elian.png')"
customGUI = replaceOnce(customGUI, oldLogo, newLogo, 'main GUI logo')
customGUI = replaceOnce(customGUI,
    "logov4.Parent = logo",
    "logov4.Visible = false\n\tlogov4.Parent = logo",
    'legacy V4 logo overlay')
customGUI = replaceOnce(customGUI,
    "logo.Size = UDim2.fromOffset(62, 18)",
    "logo.Size = UDim2.fromOffset(49, 30)",
    'main GUI logo dimensions')
customGUI = replaceOnce(customGUI,
    "logo.Position = UDim2.fromOffset(11, 10)",
    "logo.Position = UDim2.fromOffset(10, 3)",
    'main GUI logo position')
customGUI = replaceOnce(customGUI,
    "logo.ImageColor3 = select(3, uipallet.Main:ToHSV()) > 0.5 and uipallet.Text or Color3.new(1, 1, 1)",
    "logo.ImageColor3 = Color3.new(1, 1, 1)\n\tlogo.ScaleType = Enum.ScaleType.Fit",
    'main GUI image color')
customGUI = replaceOnce(customGUI,
    "settingspane.Parent = window",
    [[settingspane.Parent = window
    settingspane.BackgroundColor3 = Color3.fromRGB(5, 38, 112)
    local blueGradient = Instance.new('UIGradient')
    blueGradient.Rotation = 90
    blueGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 34, 132)),
        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(0, 109, 232)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(21, 195, 241))
    })
    blueGradient.Parent = settingspane]],
    'Settings background')
customGUI = replaceOnce(customGUI,
    "settingschildren.BackgroundColor3 = uipallet.Main",
    "settingschildren.BackgroundColor3 = Color3.fromRGB(5, 57, 144)\n\tlocal childrenGradient = Instance.new('UIGradient')\n\tchildrenGradient.Rotation = 90\n\tchildrenGradient.Color = ColorSequence.new(Color3.fromRGB(6, 69, 178), Color3.fromRGB(2, 150, 216))\n\tchildrenGradient.Parent = settingschildren",
    'Settings content background')
-- Enforce capped sliders for typed values and restored profiles as well.
customGUI = replaceOnce(customGUI,
    "function optionapi:SetValue(value, pos, final)\n\t\t\tif tonumber(value) == math.huge or value ~= value then return end",
    "function optionapi:SetValue(value, pos, final)\n\t\t\tif tonumber(value) == math.huge or value ~= value then return end\n\t\t\tif optionsettings.AeroLiteCap then value = math.clamp(tonumber(value) or optionsettings.Min, optionsettings.Min, optionsettings.Max) end",
    'capped slider value validation')
customGUI = replaceOnce(customGUI,
    "scarcitybanner.Text = 'shitty ass aerov4 script gang gang'",
    "scarcitybanner.Text = ''",
    'bottom banner text')
customGUI = replaceOnce(customGUI,
    "mainapi.Categories.Main:CreateDivider('misc')",
    "if game.GameId == 2619619496 then\n    mainapi:CreateCategory({\n        Name = 'Experimental (Ban)',\n        Icon = getcustomasset('aerov4/assets/new/blatanticon.png'),\n        Size = UDim2.fromOffset(14, 14)\n    })\n    local experimental = mainapi.Categories['Experimental (Ban)']\n    if experimental and experimental.Object then\n        experimental.Object.Position = UDim2.fromOffset(466, 120)\n        if experimental.Button and experimental.Button.Object then\n            experimental.Button.Object.Visible = true\n        end\n    end\nend\nmainapi.Categories.Main:CreateDivider('misc')",
    'experimental category')
customGUI = replaceOnce(customGUI,
    "mainapi.Categories.Main:CreateDivider('misc')",
    "if game.GameId == 2619619496 then\n    mainapi:CreateCategory({Name = 'Debug', Icon = getcustomasset('aerov4/assets/new/blatanticon.png'), Size = UDim2.fromOffset(14, 14)})\n    local debugCategory = mainapi.Categories.Debug\n    if debugCategory and debugCategory.Object then debugCategory.Object.Position = UDim2.fromOffset(686, 120) end\nend\nmainapi.Categories.Main:CreateDivider('misc')",
    'debug category')
writefile('aerov4/guis/new.lua', customGUI)
-- Preserve the upstream AeroV4 implementations of Freecam and FOV.
-- Freecam's original registration is in World; move only that module to Legit.
local universalSource = getUpstream('games/universal.lua')
local upstreamFreecam = "Freecam = vape.Categories.World:CreateModule({"
universalSource = replaceOnce(universalSource, upstreamFreecam,
    "Freecam = vape.Categories.Legit:CreateModule({", 'original Freecam category')
writefile('aerov4/games/universal.lua', universalSource)


-- Limit only the original BedWars module sliders, preserving their other options.
local function capSlider(source, marker, cap)
    local first, last = source:find(marker, 1, true)
    if not first or source:find(marker, last + 1, true) then
        error('[AeroV4 Lite] Unexpected slider registration: ' .. marker)
    end
    local head, tail = source:sub(1, last), source:sub(last + 1)
    local changed, count = tail:gsub('^(%s*Name%s*=%s*[^,\n]+,%s*.-Min%s*=%s*%d+,%s*)Max%s*=%s*%d+,(%s*)Default%s*=%s*%d+,', function(prefix, spacing)
        return prefix .. 'Max = ' .. cap .. ',' .. spacing .. 'Default = ' .. cap .. ', AeroLiteCap = true,'
    end, 1)
    if count ~= 1 then error('[AeroV4 Lite] Slider layout changed: ' .. marker) end
    return head .. changed
end

-- Retain the existing standalone HitFix compatibility and restore logic.
local function patchHitFix(source)
    local startMarker = "run(function()\n\tlocal Hitfix "
    local endMarker = "\nrun(function()\n\tlocal Interface"
    local first = source:find(startMarker, 1, true)
    local last = first and source:find(endMarker, first, true)
    if not first or not last or not source:sub(first, last - 1):find("Name = 'HitFix'", 1, true) then
        error('[AeroV4 Lite] HitFix block changed; cannot apply HitFix compatibility patch.')
    end
    local replacement = [==[
run(function()
    local HitFix
    local active
    local getConstant = debug.getconstant or getconstant
    local setConstant = debug.setconstant or setconstant
    local getUpvalue = debug.getupvalue or getupvalue
    local setUpvalue = debug.setupvalue or setupvalue

    local function report(message, force)
        if force then warn('[AeroLite HitFix] ' .. message)
        else print('[AeroLite HitFix] ' .. message) end
    end

    local function restore()
        if not active then return true end
        local old = active
        local a = pcall(setConstant, old.func, old.index, old.constant)
        local b = pcall(setUpvalue, old.func, 4, old.value)
        if a and b then active = nil end
        return a and b
    end

    local function reconcile()
        local enabled = HitFix and HitFix.Enabled
        if not enabled then
            if not restore() then report('Could not restore original raycast.', true) end
            return
        end
        if type(getConstant) ~= 'function' or type(setConstant) ~= 'function'
            or type(getUpvalue) ~= 'function' or type(setUpvalue) ~= 'function' then
            report('Required executor APIs unavailable.', true)
            return
        end
        local controller = bedwars.SwordController
        local func = controller and controller.swingSwordAtMouse
        if type(func) ~= 'function' then return end
        local target = bedwars.QueryUtil
        local constant = 'raycast'
        if not target then report('Selected query unavailable.', true) return end
        if active and active.func ~= func and not restore() then
            report('Could not restore previous controller.', true)
            return
        end
        if not active then
            local index, original
            for n = 1, 50 do
                local ok, val = pcall(getConstant, func, n)
                if not ok then break end
                if val == 'Raycast' or val == 'raycast' then
                    index, original = n, val
                    break
                end
            end
            if not index then report('Raycast not found; controller unchanged.', true) return end
            local ok, first, second = pcall(getUpvalue, func, 4)
            local value = second ~= nil and second or first
            if not ok or (value ~= workspace and value ~= bedwars.QueryUtil) then
                report('Unexpected query object; controller unchanged.', true)
                return
            end
            active = {func = func, index = index, constant = original, value = value}
        end
        local a = pcall(setConstant, func, active.index, constant)
        local b = a and pcall(setUpvalue, func, 4, target)
        if not a or not b then
            restore()
            report('Could not apply selected mode.', true)
            return
        end
    end

    HitFix = vape.Categories.Legit:CreateModule({
        Name = 'HitFix',
        Function = function() reconcile() end,
        Tooltip = 'Original AeroV4 query behavior.'
    })

    vape:Clean(function() restore() end)
end)
]==]
    return source:sub(1, first - 1) .. replacement .. source:sub(last)
end

local gameFileId = (game.PlaceId == 6872265039) and 6872265039 or 6872274481
local bedwarsSource = getUpstream('games/' .. tostring(gameFileId) .. '.lua')
if gameFileId == 6872274481 then
    bedwarsSource = bedwarsSource:gsub('\r\n', '\n')
    bedwarsSource = capSlider(bedwarsSource, 'Attack = Reach:CreateSlider({', 16)
    bedwarsSource = capSlider(bedwarsSource, 'Mine = Reach:CreateSlider({', 16)
    bedwarsSource = capSlider(bedwarsSource, 'FOV = SilentAim:CreateSlider({', 100)
    bedwarsSource = patchHitFix(bedwarsSource)
    -- Keep the original AeroV4 PhaseMine implementation unchanged; show it in Experimental.
    bedwarsSource = replaceOnce(bedwarsSource,
        'PhaseMine = vape.Categories.World:CreateModule({',
        "PhaseMine = vape.Categories['Experimental (Ban)']:CreateModule({",
        'original PhaseMine experimental category')

    -- Pause only with a wood-to-diamond axe or pickaxe equipped and a check triggered.
    -- Adjust only the PhaseMine block, not other BedWars modules.
    local phaseStart = "run(function()\n\tlocal PhaseMine\n"
    local phaseEnd = "Tooltip = 'mine OR build through players and npcs'\n\t})\nend)"
    local first = bedwarsSource:find(phaseStart, 1, true)
    local finish = first and bedwarsSource:find(phaseEnd, first, true)
    if not first or not finish then
        error('[AeroV4 Lite] PhaseMine module boundaries not found')
    end
    finish = finish + #phaseEnd - 1
    local phaseSource = bedwarsSource:sub(first, finish)
    local function phaseReplace(before, after, name)
        local start = phaseSource:find(before, 1, true)
        if not start or phaseSource:find(before, start + #before, true) then
            error('[AeroV4 Lite] Unexpected PhaseMine patch marker: ' .. name)
        end
        phaseSource = phaseSource:sub(1, start - 1) .. after .. phaseSource:sub(start + #before)
    end
    phaseReplace("local tracked = {}\n\tlocal descConnections = {}",
        [==[local tracked = {}
    local descConnections = {}
    local paused = false
    local pauseGeneration = 0
    local EntityLimitSlider
    local function maxFrontEntities()
        return EntityLimitSlider and EntityLimitSlider.Value or 3
    end
    local CURSOR_RADIUS_PIXELS = 45
    local TreeCheck, HephCheck

    local function hasMiningToolEquipped()
        -- AeroV4's BedWars inventory wrapper returns the currently held item
        -- as inventory.hand.itemType, without relying on Roblox Tool instances.
        local inventory = bedwars.getInventory and bedwars.getInventory(lplr)
        local hand = inventory and inventory.hand
        local itemType = hand and hand.itemType
        if type(itemType) ~= 'string' then return false end
        return ({
            wood_pickaxe = true, stone_pickaxe = true,
            iron_pickaxe = true, diamond_pickaxe = true,
            wood_axe = true, stone_axe = true,
            iron_axe = true, diamond_axe = true
        })[itemType:lower()] == true
    end

    local function matchesCheckedKit(model)
        local player = game:GetService('Players'):GetPlayerFromCharacter(model)
        if not player then return false end
        -- AeroV4 reads PlayingAsKits and tokenizes it for multiple active kits.
        local kits = player:GetAttribute('PlayingAsKits')
        if type(kits) ~= 'string' then return false end
        for kit in kits:lower():gmatch('[%w_]+') do
            if TreeCheck and TreeCheck.Enabled
                and (kit == 'bigman' or kit == 'eldertree' or kit == 'elder_tree') then
                return true
            end
            if HephCheck and HephCheck.Enabled
                and (kit == 'tinker' or kit == 'hephaestus') then
                return true
            end
        end
        return false
    end

    local function countFrontEntities()
        local character = lplr.Character
        local root = character and character:FindFirstChild('HumanoidRootPart')
        local camera = workspace.CurrentCamera
        if not root or not camera then return 0 end
        local counted = {}
        local count = 0
        local function checkCharacter(model)
            if not model or model == character or counted[model] or not model.Parent then return end
            counted[model] = true
            local humanoid = model:FindFirstChildOfClass('Humanoid')
            local targetRoot = model:FindFirstChild('HumanoidRootPart') or model.PrimaryPart
            if not humanoid or humanoid.Health <= 0 or not targetRoot then return end
            local point, visible = camera:WorldToViewportPoint(targetRoot.Position)
            if not visible or point.Z <= 0 then return end
            local inset = game:GetService('GuiService'):GetGuiInset()
            local cursor = game:GetService('UserInputService'):GetMouseLocation() - inset
            if (Vector2.new(point.X, point.Y) - cursor).Magnitude <= CURSOR_RADIUS_PIXELS then
                if matchesCheckedKit(model) then
                    count = maxFrontEntities() + 1
                else
                    count = count + 1
                end
            end
        end
        for _, entity in ipairs(entitylib.List) do
            checkCharacter(entity.Character)
            if count > maxFrontEntities() then return count end
        end
        for _, model in ipairs(workspace:GetChildren()) do
            if model:IsA('Model') then checkCharacter(model) end
            if count > maxFrontEntities() then return count end
        end
        return count
    end

    local function setPaused(value)
        if paused == value then return end
        paused = value
        for _, parts in pairs(tracked) do
            for part in pairs(parts) do
                if part.Parent then
                    pcall(function()
                        bedwars.QueryUtil:setQueryIgnored(part, not paused)
                    end)
                end
            end
        end
    end]==],
        'pause state and front entity detection')
    phaseReplace("local function ignorePart(part)\n\t\t\t\t\tpcall(function()",
        "local function ignorePart(part)\n                    if paused then return end\n\t\t\t\t\tpcall(function()",
        'prevent query ignores while paused')
    phaseReplace("if callback then\n\n\t\t\t\tlocal function ignorePart",
        "if callback then\n                pauseGeneration = pauseGeneration + 1\n                local generation = pauseGeneration\n                paused = false\n                setPaused(hasMiningToolEquipped() and countFrontEntities() > maxFrontEntities())\n\n\t\t\t\tlocal function ignorePart",
        'enable state setup')
    phaseReplace("setupAllCharacters()\n\t\t\t\tupdateCollision()\n",
        [==[setupAllCharacters()
                updateCollision()
                task.spawn(function()
                    while PhaseMine.Enabled and pauseGeneration == generation do
                        setPaused(hasMiningToolEquipped() and countFrontEntities() > maxFrontEntities())
                        task.wait(0.15)
                    end
                end)
]==],
        'independent pause monitor')
    phaseReplace("\t\t\telse\n\t\t\t\tfor _, conn in ipairs(connections) do",
        "\t\t\telse\n                pauseGeneration = pauseGeneration + 1\n                setPaused(false)\n\t\t\t\tfor _, conn in ipairs(connections) do",
        'stop monitor and restore on disable')
    -- Cursor-centered FOV checks use a 45-pixel radius in third person.
    -- Screen-space FOV uses WorldToViewportPoint and the mouse's viewport position.
    -- No stud-distance limit; entities and kits share the cursor FOV.
    phaseReplace("Tooltip = 'mine OR build through players and npcs'\n\t})\nend)",
        [==[Tooltip = 'mine OR build through players and npcs'
    })
    EntityLimitSlider = PhaseMine:CreateSlider({
        Name = 'Entity Limit',
        Min = 1,
        Max = 5,
        Default = 3,
        Tooltip = 'how many things infront before it doesnt phasemine'
    })
    TreeCheck = PhaseMine:CreateToggle({
        Name = 'TreeCheck',
        Default = false,
        Tooltip = 'checks if there is a big tree blocking'
    })
    HephCheck = PhaseMine:CreateToggle({
        Name = 'HephCheck',
        Default = false,
        Tooltip = 'checks if theres a fat heph blocking'
    })
end)]==],
        'PhaseMine settings slider')
    phaseReplace("Name = 'PhaseMine',", "Name = 'LegitMine',", 'display name')
    phaseReplace("    HephCheck = PhaseMine:CreateToggle({\n        Name = 'HephCheck',\n        Default = false,\n        Tooltip = 'checks if theres a fat heph blocking'\n    })", [==[    HephCheck = PhaseMine:CreateToggle({
        Name = 'HephCheck',
        Default = false,
        Tooltip = 'checks if theres a fat heph blocking'
    })
    vape.ModuleAliases = vape.ModuleAliases or {}
    vape.ModuleAliases.LegitMine = {'PhaseMine'}]==], 'search alias')
    bedwarsSource = bedwarsSource:sub(1, first - 1) .. phaseSource .. bedwarsSource:sub(finish + 1)
end
-- Read-only local diagnostics. No remotes, combat hooks or damage modification.
if gameFileId == 6872274481 then
    bedwarsSource = [==[
do
    local api = shared.vape
    local category = api and api.Categories.Debug
    if category then
        local player = game:GetService('Players').LocalPlayer
        local runService = game:GetService('RunService')
        local input = game:GetService('UserInputService')
        local positions = {}
        local W, H, N = 216, 122, 48
        local function register(name, title, units, slot, period, sample, eventMode, tooltip)
            local module
            module = category:CreateModule({
                Name = name,
                Tooltip = tooltip,
                Function = function(enabled)
                    if not enabled or not module.Enabled then return end
                    local pg = player:FindFirstChildOfClass('PlayerGui')
                    if not pg then return end
                    local screen = Instance.new('ScreenGui')
                    screen.Name = 'ElianDebug' .. name
                    screen.ResetOnSpawn = false
                    screen.DisplayOrder = 15
                    screen.Parent = pg
                    module:Clean(screen)
                    local frame = Instance.new('Frame')
                    frame.Size = UDim2.fromOffset(W, H)
                    frame.BackgroundColor3 = Color3.fromRGB(23, 27, 36)
                    frame.BackgroundTransparency = 0.08
                    frame.BorderSizePixel = 0
                    frame.Parent = screen
                    local round = Instance.new('UICorner')
                    round.CornerRadius = UDim.new(0, 6)
                    round.Parent = frame
                    local function place(x, y)
                        local camera = workspace.CurrentCamera
                        local view = camera and camera.ViewportSize or Vector2.new(800, 600)
                        x = math.clamp(x, 0, math.max(0, view.X - W))
                        y = math.clamp(y, 0, math.max(0, view.Y - H - 36))
                        frame.Position = UDim2.fromOffset(x, y)
                        positions[name] = Vector2.new(x, y)
                    end
                    local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800,600)
                    local saved = positions[name]
                    place(saved and saved.X or view.X - W - 12 - math.floor((slot-1)/3)*(W+8),
                          saved and saved.Y or 65 + ((slot-1)%3)*(H+8))
                    local function textLabel(parent, text, x, y, w, h, size)
                        local label = Instance.new('TextLabel')
                        label.BackgroundTransparency = 1
                        label.Position = UDim2.fromOffset(x,y)
                        label.Size = UDim2.fromOffset(w,h)
                        label.Font = Enum.Font.Gotham
                        label.TextSize = size
                        label.TextColor3 = Color3.fromRGB(225,232,245)
                        label.TextXAlignment = Enum.TextXAlignment.Left
                        label.Text = text
                        label.Parent = parent
                        return label
                    end
                    local header = textLabel(frame,title,8,0,W-16,23,12)
                    header.Active = true
                    local readout = textLabel(frame,'Waiting for data',8,79,W-16,19,11)
                    local spikeReadout = textLabel(frame,'Last spike: --',8,98,W-16,19,11)
                    spikeReadout.TextColor3 = Color3.fromRGB(245,185,91)
                    local plot = Instance.new('Frame')
                    plot.Position = UDim2.fromOffset(8,24)
                    plot.Size = UDim2.fromOffset(W-16,54)
                    plot.BackgroundColor3 = Color3.fromRGB(14,18,25)
                    plot.BorderSizePixel = 0
                    plot.ClipsDescendants = true
                    plot.Parent = frame
                    local bars, values, recent = {}, {}, {}
                    local lastValue, lastSpike, lastSpikeAt
                    local function average(now)
                        while recent[1] and now - recent[1].at > 5 do table.remove(recent,1) end
                        if #recent == 0 then return nil end
                        local sum = 0
                        for _, v in ipairs(recent) do sum = sum + v.value end
                        return sum / #recent
                    end
                    local function refresh(now)
                        local avg = average(now)
                        readout.Text = lastValue ~= nil and string.format('Now %.1f | 5s avg %s %s', lastValue, avg and string.format('%.1f',avg) or '--',units) or 'Waiting for data'
                        spikeReadout.Text = lastSpikeAt and string.format('Spike %.1f %s | %.1fs ago',lastSpike,units,now-lastSpikeAt) or 'Last spike: --'
                    end
                    for i = 1,N do
                        local bar = Instance.new('Frame')
                        bar.AnchorPoint = Vector2.new(0,1)
                        bar.BorderSizePixel = 0
                        bar.BackgroundColor3 = Color3.fromRGB(52,162,245)
                        bar.Visible = false
                        bar.Parent = plot
                        bars[i] = bar
                    end
                    local function push(value)
                        if type(value) ~= 'number' or value ~= value or value == math.huge or value < 0 then return end
                        local now = os.clock()
                        local baseline = average(now)
                        local minimum = ({CombatPing = 10, HitDelayGraph = 30, FrameTimeGraph = 2, DamageTakenGraph = 3, MovementSpeedGraph = 2})[name] or 1
                        local spike = baseline ~= nil and #recent >= 3 and value > baseline * 1.5 and value - baseline >= minimum
                        if spike then lastSpike, lastSpikeAt = value, now end
                        lastValue = value
                        recent[#recent+1] = {at = now, value = value}
                        values[#values+1] = {value = value, spike = spike}
                        if #values > N then table.remove(values,1) end
                        local max = 1
                        for _, v in ipairs(values) do max = math.max(max,v.value) end
                        local step = (W-16)/N
                        for i, bar in ipairs(bars) do
                            local v = values[i - (N-#values)]
                            bar.Visible = v ~= nil
                            if v then
                                bar.Position = UDim2.fromOffset((i-1)*step,54)
                                bar.Size = UDim2.fromOffset(math.max(1,step-1),math.max(1, v.value/max*53))
                                bar.BackgroundColor3 = v.spike and Color3.fromRGB(245,185,91) or Color3.fromRGB(52,162,245)
                            end
                        end
                        refresh(now)
                    end
                    local drag, start, from
                    module:Clean(header.InputBegan:Connect(function(obj)
                        if obj.UserInputType == Enum.UserInputType.MouseButton1 or obj.UserInputType == Enum.UserInputType.Touch then
                            drag, start, from = obj, obj.Position, frame.AbsolutePosition
                            from = Vector2.new(frame.Position.X.Offset,frame.Position.Y.Offset)
                        end
                    end))
                    module:Clean(input.InputChanged:Connect(function(obj)
                        if not drag then return end
                        if obj == drag or (drag.UserInputType == Enum.UserInputType.MouseButton1 and obj.UserInputType == Enum.UserInputType.MouseMovement) then
                            local delta = obj.Position-start
                            place(from.X+delta.X,from.Y+delta.Y)
                        end
                    end))
                    module:Clean(input.InputEnded:Connect(function(obj)
                        if obj == drag then drag = nil end
                    end))
                    local elapsed, frames, previous, previousAt, tracked, healthConn = 0,0,nil,nil,nil,nil
                    local refreshElapsed = 0
                    module:Clean(function() if healthConn then healthConn:Disconnect() end end)
                    module:Clean(runService.Heartbeat:Connect(function(dt)
                        if not module.Enabled then return end
                        refreshElapsed = refreshElapsed + dt
                        if refreshElapsed >= 0.25 then refreshElapsed = 0; refresh(os.clock()) end
                        local char = player.Character
                        local hum = char and char:FindFirstChildOfClass('Humanoid')
                        if eventMode and hum ~= tracked then
                            if healthConn then healthConn:Disconnect(); healthConn = nil end
                            tracked, previousAt = hum,nil
                            previous = hum and hum.Health
                            if hum then
                                healthConn = hum.HealthChanged:Connect(function(hp)
                                    local old = previous
                                    previous = hp
                                    if not old or hp >= old then return end
                                    local now = os.clock()
                                    if eventMode == 'interval' then
                                        if previousAt and now-previousAt <= 10 then push((now-previousAt)*1000) end
                                        previousAt = now
                                    else push(old-hp) end
                                end)
                            end
                        end
                        if eventMode then return end
                        elapsed,frames = elapsed+dt,frames+1
                        if elapsed < period then return end
                        local ok,value = pcall(sample,elapsed,frames,char,hum)
                        elapsed,frames = 0,0
                        if ok and value ~= nil then push(value) end
                    end))
                end
            })
        end
        register('CombatPing','Combat ping','ms',1,0.25,function()
            local item = game:GetService('Stats').Network.ServerStatsItem:FindFirstChild('Data Ping')
            return item and item:GetValue() or player:GetNetworkPing()*1000
        end,nil,'Live connection latency; sampled continuously, not just in combat.')
        register('HitDelayGraph','Incoming hit delay','ms',2,0,nil,'interval',
            'Intervals between local health losses, not confirmed outgoing hits. Resets interval after 10 seconds.')
        register('FrameTimeGraph','Frame time','ms',3,0.25,function(dt,frames) return dt/frames*1000 end,nil,'Average client frame duration.')
        register('DamageTakenGraph','Damage taken','HP',4,0,nil,'damage','Local health decreases, including environmental damage.')
        register('MovementSpeedGraph','Movement speed','stud/s',5,0.15,function(_,_,char)
            local root = char and char:FindFirstChild('HumanoidRootPart')
            if root then local v = root.AssemblyLinearVelocity; return Vector3.new(v.X,0,v.Z).Magnitude end
        end,nil,'Local horizontal movement speed.')
    end
end
]==] .. '\n' .. bedwarsSource
end
writefile('aerov4/games/' .. tostring(gameFileId) .. '.lua', bedwarsSource)

local originalDownloader = getUpstream('downloader.lua')
local runDownloader, compileError = loadstring(originalDownloader, 'aerov4-lite-downloader')
if not runDownloader then
    error('[AeroV4 Lite] Original downloader could not be compiled: ' .. tostring(compileError))
end
return runDownloader()
