-- AeroV4 Lite: pinned upstream UI, 10-module allowlist for BedWars.
-- This repository does not contain or redistribute the upstream UI or module sources.
-- Upstream: https://github.com/wrealaero/aerov4

repeat task.wait() until game:IsLoaded()

-- Verify executor identity before downloading, running modules, or modifying any files.
-- Only exact name prefixes are allowed; names are case-insensitive.
local function executorFamily(name)
    if type(name) ~= 'string' then return nil end
    local normal = name:lower():match('^%s*(.-)%s*$')
    if normal == 'potassium' or normal:match('^potassium[%s%p]') then return 'Potassium' end
    if normal == 'real' or normal:match('^real[%s%p]') then return 'Real' end
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
-- Real also documents getexecutorname(); use it only as a fallback.
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
    rejectAndUninject('Only Potassium and Real are supported. Detected: ' .. detectedName .. '. Nothing was loaded.')
    return nil
end

-- Both executor API references document these operations, but not every build implements them.
local function selectedHitFixAPIs()
    if type(debug) ~= 'table' then return false end
    if executorKind == 'Potassium' then
        return type(debug.getconstant) == 'function'
            and type(debug.setconstant) == 'function'
            and type(debug.getupvalue) == 'function'
            and type(debug.setupvalue) == 'function'
    end
    return type(getconstant or debug.getconstant) == 'function'
        and type(setconstant or debug.setconstant) == 'function'
        and type(getupvalue or debug.getupvalue) == 'function'
        and type(setupvalue or debug.setupvalue) == 'function'
end
if not selectedHitFixAPIs() then
    rejectAndUninject(executorKind .. ' lacks required HitFix debug APIs. Nothing was loaded.')
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
local DEFAULT_SELF_URL = 'https://raw.githubusercontent.com/elianxyzz-projects/aeroclone/main/loader.lua'
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
            ProjectileAimbot = true,
            KitESP = true,
            KitRender = true,
            NameTags = true,
            HitBoxes = true,
            ESP = true,
            BedPlates = true,
            HitFix = true,
            FPSBoost = true
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
            Legit = true
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

        -- Keep every module OFF before saved profile options are loaded.
        -- The user must explicitly enable a module through the UI.
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
        vape.ManualEnableOnly = true

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

        -- Previous full-client profiles must not reveal hidden categories.
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
-- Do not auto-enable modules from previously saved configs (including profile changes).
-- Preserve all original GUI, option loading, keybinds, colors and manual toggles.
local originalGui = getUpstream('guis/new.lua')
local function preventProfileAutoEnable(source, originalCondition, patchedCondition, label)
    local first = source:find(originalCondition, 1, true)
    if not first or source:find(originalCondition, first + #originalCondition, true) then
        error('[AeroV4 Lite] Unrecognized upstream GUI profile toggle: ' .. label)
    end
    return source:sub(1, first - 1) .. patchedCondition .. source:sub(first + #originalCondition)
end
originalGui = preventProfileAutoEnable(
    originalGui,
    'if v.Enabled ~= object.Enabled then',
    'if not self.ManualEnableOnly and v.Enabled ~= object.Enabled then',
    'normal modules'
)
originalGui = preventProfileAutoEnable(
    originalGui,
    'if object.Enabled ~= (v.Enabled or false) then',
    'if not self.ManualEnableOnly and object.Enabled ~= (v.Enabled or false) then',
    'legit modules'
)
writefile('aerov4/guis/new.lua', originalGui)
writefile('aerov4/games/universal.lua', getUpstream('games/universal.lua'))


-- Match the single original HitFix registration block from the pinned BedWars version.
-- Select one API implementation at load-time (never run both).
local function patchHitFix(bedwarsSource)
    bedwarsSource = bedwarsSource:gsub('\r\n', '\n')
    local oldStart = 'run(function()\n\tlocal Hitfix '
    local oldNext = '\nrun(function()\n\tlocal Interface'
    local first = bedwarsSource:find(oldStart, 1, true)
    local following = first and bedwarsSource:find(oldNext, first, true)
    if not first or not following then
        error('[AeroV4 Lite] HitFix upstream registration changed; refusing to run unverified patch.')
    end
    local originalBlock = bedwarsSource:sub(first, following - 1)
    if not originalBlock:find("Name = 'HitFix'", 1, true)
        or not originalBlock:find('debug.getconstant', 1, true)
        or not originalBlock:find('debug.setupvalue', 1, true) then
        error('[AeroV4 Lite] Unexpected HitFix block. Refusing to load.')
    end

    local apiGetConstant, apiSetConstant, apiGetUpvalue, apiSetUpvalue
    if executorKind == 'Potassium' then
        apiGetConstant, apiSetConstant = 'debug.getconstant', 'debug.setconstant'
        apiGetUpvalue, apiSetUpvalue = 'debug.getupvalue', 'debug.setupvalue'
    elseif executorKind == 'Real' then
        apiGetConstant, apiSetConstant = '(getconstant or debug.getconstant)', '(setconstant or debug.setconstant)'
        apiGetUpvalue, apiSetUpvalue = '(getupvalue or debug.getupvalue)', '(setupvalue or debug.setupvalue)'
    else
        error('[AeroV4 Lite] Invalid HitFix executor adapter')
    end

    local code = [==[
run(function()
    local getConstant = __GET_CONSTANT__
    local setConstant = __SET_CONSTANT__
    local getUpvalue = __GET_UPVALUE__
    local setUpvalue = __SET_UPVALUE__
    local saved = setmetatable({}, {__mode = 'k'})
    local HitFix

    local function findState(func)
        local state = saved[func]
        if state then return state end
        local index, originalConstant
        for i = 1, 80 do
            local ok, value = pcall(getConstant, func, i)
            if not ok then break end
            if value == 'Raycast' or value == 'raycast' then
                index, originalConstant = i, value
                break
            end
        end
        if not index then
            warn('[AeroV4 Lite HitFix] Raycast constant not found: module unchanged')
            return nil
        end
        local ok, originalUpvalue = pcall(getUpvalue, func, 4)
        if not ok then
            warn('[AeroV4 Lite HitFix] Upvalue 4 not readable: module unchanged')
            return nil
        end
        state = {
            index = index,
            originalConstant = originalConstant,
            originalUpvalue = originalUpvalue
        }
        saved[func] = state
        return state
    end

    HitFix = vape.Categories.Legit:CreateModule({
        Name = 'HitFix',
        Function = function(enabled)
            local controller = bedwars.SwordController
            local func = controller and controller.swingSwordAtMouse
            if type(func) ~= 'function' then
                warn('[AeroV4 Lite HitFix] Sword swing function unavailable')
                return
            end
            local state = findState(func)
            if not state then return end

            local nextConstant = enabled and 'raycast' or state.originalConstant
            local nextUpvalue = enabled and bedwars.QueryUtil or state.originalUpvalue
            local constantOK, constantError = pcall(setConstant, func, state.index, nextConstant)
            local upvalueOK, upvalueError = pcall(setUpvalue, func, 4, nextUpvalue)

            if not constantOK or not upvalueOK then
                warn('[AeroV4 Lite HitFix] Failed to apply ' .. tostring(enabled)
                    .. ': ' .. tostring(constantError or upvalueError))
                -- Avoid leaving only half the modification applied.
                pcall(setConstant, func, state.index, state.originalConstant)
                pcall(setUpvalue, func, 4, state.originalUpvalue)
            end
        end
    })
end)
]==]
    local substitutions = {
        ['__GET_CONSTANT__'] = apiGetConstant,
        ['__SET_CONSTANT__'] = apiSetConstant,
        ['__GET_UPVALUE__'] = apiGetUpvalue,
        ['__SET_UPVALUE__'] = apiSetUpvalue
    }
    for marker, value in pairs(substitutions) do
        code = code:gsub(marker, function() return value end)
    end
    if code:find('__GET_') or code:find('__SET_') then
        error('[AeroV4 Lite] Incomplete HitFix adaptation')
    end
    return bedwarsSource:sub(1, first - 1) .. code .. bedwarsSource:sub(following + 1)
end

local gameFileId = (game.PlaceId == 6872265039) and 6872265039 or 6872274481
local bedwarsSource = getUpstream('games/' .. tostring(gameFileId) .. '.lua')
if gameFileId == 6872274481 then
    bedwarsSource = patchHitFix(bedwarsSource)
end
writefile('aerov4/games/' .. tostring(gameFileId) .. '.lua', bedwarsSource)

local originalDownloader = getUpstream('downloader.lua')
local runDownloader, compileError = loadstring(originalDownloader, 'aerov4-lite-downloader')
if not runDownloader then
    error('[AeroV4 Lite] Original downloader could not be compiled: ' .. tostring(compileError))
end
return runDownloader()
