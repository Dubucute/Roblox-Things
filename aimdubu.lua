local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Chat = game:GetService("Chat")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- ========== AIM ASSIST MODULE (MOBILE) ==========
local AimAssistController = nil
local aimAssistInstance = nil
local isAimAssistReady = false

if isMobileUser then
    local success, module = pcall(function()
        return game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("AimAssistController")
    end)
    if success and module then
        AimAssistController = require(module)
        aimAssistInstance = AimAssistController.new()
        isAimAssistReady = true
        print("Dubu Hub: AimAssistController loaded for mobile.")
    else
        warn("Dubu Hub: AimAssistController not found – falling back to basic aimlock.")
    end
end

local hasFileSupport = (isfolder ~= nil and makefolder ~= nil and listfiles ~= nil and readfile ~= nil and writefile ~= nil and delfile ~= nil)
if not hasFileSupport then
    warn("Dubu Hub: Your executor does not support file functions. Config and teleport saving will be disabled.")
end

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
if not WindUI then
    warn("Failed to load WindUI.")
    return
end

local function ensureFolder(path)
    if not hasFileSupport then return end
    if not isfolder then return end
    local parts = string.split(path, "/")
    local current = ""
    for _, part in ipairs(parts) do
        if current == "" then current = part
        else current = current .. "/" .. part end
        if not isfolder(current) then pcall(makefolder, current) end
    end
end

if hasFileSupport then
    ensureFolder("DubuHub/Streetlife")
    ensureFolder("DubuHub/Streetlife/positions")
    ensureFolder("DubuHub/Streetlife/lang")
end

-- ========== GLOBAL UTILITY FUNCTIONS ==========

local function getMyCar()
    local vehiclesFolder = workspace:FindFirstChild("Vehicles")
    if not vehiclesFolder then return nil end
    return vehiclesFolder:FindFirstChild(LocalPlayer.Name .. "'s Car")
end

local function isScooter(car)
    if not car then return false end
    local success, carType = pcall(function() return car:GetAttribute("CarType") end)
    return success and carType == "Scooter"
end

local function findSpawnScooter()
    local scootersFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Scooters")
    if not scootersFolder then scootersFolder = workspace:FindFirstChild("Scooters") end
    if not scootersFolder then return nil, nil, "Scooters folder not found" end
    local spawnerModel = scootersFolder:FindFirstChild("SpawnScooter")
    if not spawnerModel then return nil, nil, "SpawnScooter not found in Scooters folder" end
    local promptPart, prompt = nil, nil
    for _, child in ipairs(spawnerModel:GetDescendants()) do
        if child:IsA("BasePart") then
            prompt = child:FindFirstChildOfClass("ProximityPrompt")
            if prompt then promptPart = child; break end
        end
    end
    if not promptPart then
        prompt = spawnerModel:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            promptPart = spawnerModel.PrimaryPart
            if not promptPart then
                for _, child in ipairs(spawnerModel:GetDescendants()) do
                    if child:IsA("BasePart") then promptPart = child; break end
                end
            end
        end
    end
    if not promptPart or not prompt then return nil, nil, "No part with ProximityPrompt found in SpawnScooter" end
    return promptPart, prompt, nil
end

local function teleportModel(model, targetPos)
    if not model then return false end
    if model.PrimaryPart then
        model:SetPrimaryPartCFrame(CFrame.new(targetPos))
        return true
    else
        local modelCF = model:GetModelCFrame()
        local offset = targetPos - modelCF.Position
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then part.CFrame = part.CFrame + offset end
        end
        return true
    end
end

local function teleportMyCar(targetPos)
    local car = getMyCar()
    if not car then
        WindUI:Notify({ Title = "Teleport", Content = "Your car not found in workspace.Vehicles", Duration = 2 })
        return
    end
    if teleportModel(car, targetPos) then
        WindUI:Notify({ Title = "Teleport", Content = "Your car teleported", Duration = 2 })
    else
        WindUI:Notify({ Title = "Teleport", Content = "Failed to teleport car", Duration = 2 })
    end
end

local function getPlayerPosition()
    local char = workspace:FindFirstChild(LocalPlayer.Name)
    if not char or not char.PrimaryPart then return nil end
    return char.PrimaryPart.Position
end

-- ========== THEME ==========
WindUI:AddTheme({
    Name = "Rosewave",
    Accent              = Color3.fromHex("#e8547a"),
    Background          = Color3.fromHex("#0d0d12"),
    BackgroundTransparency = 0,
    Outline             = Color3.fromHex("#2a1a22"),
    Text                = Color3.fromHex("#f5e6ec"),
    Placeholder         = Color3.fromHex("#8a6475"),
    Button              = Color3.fromHex("#e8547a"),
    Icon                = Color3.fromHex("#e8547a"),
    Hover               = Color3.fromHex("#ff8fab"),
    WindowBackground    = Color3.fromHex("#0d0d12"),
    WindowShadow        = Color3.fromHex("#000000"),
    DialogBackground    = Color3.fromHex("#130d10"),
    DialogBackgroundTransparency = 0,
    DialogTitle         = Color3.fromHex("#f5e6ec"),
    DialogContent       = Color3.fromHex("#c9a8b8"),
    DialogIcon          = Color3.fromHex("#e8547a"),
    WindowTopbarButtonIcon  = Color3.fromHex("#e8547a"),
    WindowTopbarTitle   = Color3.fromHex("#f5e6ec"),
    WindowTopbarAuthor  = Color3.fromHex("#9e7a8c"),
    WindowTopbarIcon    = Color3.fromHex("#e8547a"),
    TabBackground       = Color3.fromHex("#0a0a0f"),
    TabTitle            = Color3.fromHex("#f5e6ec"),
    TabIcon             = Color3.fromHex("#e8547a"),
    ElementBackground   = Color3.fromHex("#141018"),
    ElementTitle        = Color3.fromHex("#f5e6ec"),
    ElementDesc         = Color3.fromHex("#9e7a8c"),
    ElementIcon         = Color3.fromHex("#e8547a"),
    PopupBackground     = Color3.fromHex("#0d0d12"),
    PopupBackgroundTransparency = 0,
    PopupTitle          = Color3.fromHex("#f5e6ec"),
    PopupContent        = Color3.fromHex("#c9a8b8"),
    PopupIcon           = Color3.fromHex("#e8547a"),
    Toggle              = Color3.fromHex("#e8547a"),
    ToggleBar           = Color3.fromHex("#3d2030"),
    Checkbox            = Color3.fromHex("#e8547a"),
    CheckboxIcon        = Color3.fromHex("#f5e6ec"),
    Slider              = Color3.fromHex("#e8547a"),
    SliderThumb         = Color3.fromHex("#f5e6ec"),
    SearchText          = Color3.fromHex("#000000"),
    SearchClose         = Color3.fromHex("#000000"),
    SearchPlaceholder   = Color3.fromHex("#333333"),
})
WindUI:SetTheme("Rosewave")

-- ========== LOCALIZATION ==========
local GROQ_API_KEY = "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"
local LANG_NAME_MAP = {
    ["en"]="English",["ru"]="Russian",["es"]="Spanish",["fr"]="French",["de"]="German",
    ["pt"]="Portuguese",["ja"]="Japanese",["ko"]="Korean",["zh-cn"]="Chinese (Simplified)",
    ["ar"]="Arabic",["tr"]="Turkish",["vi"]="Vietnamese",["id"]="Indonesian",
    ["tl"]="Filipino",["hil"]="Ilonggo",["ceb"]="Cebuano",["akv"]="Aklanon",
    ["Gay Lingo"]="Gay Lingo",
}
local LANG_CACHE_FOLDER = "DubuHub/Streetlife/lang"
local LOC_SPLIT = "\n\u{241E}\n"

local LOC_SOURCE = {
    ["HUB_TITLE"]="Dubu Hub",["HUB_AUTHOR"]="by Dubu",["OPEN_BUTTON"]="Open Dubu Hub",
    ["TAB_MAIN"]="Main",["TAB_MONEY_FARM"]="Money Farm",["TAB_TELEPORTS"]="Teleports",
    ["TAB_HOUSE_ROB"]="House Rob",["TAB_COMBAT"]="Combat",["TAB_ESP"]="ESP",
    ["TAB_SHOP"]="Shop",["TAB_UI"]="UI",["TAB_CAR_UTILS"]="Car Utils",
    ["TAB_CRYPTO"]="Crypto",["TAB_MISC"]="Misc",["TAB_CONFIG"]="Config",
    ["WHATS_NEW_TITLE"]="Dubu Hub v6.5 – What's New",["CLOSE"]="Close",
    ["CONFIG_TITLE"]="Configuration",["CONFIG_DESC"]="Save, load, and manage multiple configs.",
    ["CONFIG_LIST"]="Config List",["CONFIG_LIST_DESC"]="Select a config to load/save",
    ["CONFIG_NEW_NAME"]="New Config Name",["CONFIG_NEW_NAME_DESC"]="Enter name for new config",
    ["CONFIG_NEW"]="New Config",["CONFIG_NEW_DESC"]="Create a new config with the entered name",
    ["CONFIG_SAVE"]="Save Config",["CONFIG_SAVE_DESC"]="Save current settings to the selected config",
    ["CONFIG_LOAD"]="Load Config",["CONFIG_LOAD_DESC"]="Load settings from the selected config",
    ["CONFIG_DELETE"]="Delete Config",["CONFIG_DELETE_DESC"]="Delete the selected config (cannot be undone)",
    ["CONFIG_REFRESH"]="Refresh List",["CONFIG_REFRESH_DESC"]="Manually refresh the config list",
    ["CONFIG_RESET"]="Reset to Defaults",["CONFIG_RESET_DESC"]="Reset all saved settings to default values",
    ["LANGUAGE"]="Language",["LANGUAGE_DESC"]="Translate UI via Groq AI API",
    ["LANG_TRANSLATING"]="Translating UI...",["LANG_FAILED"]="Translation failed, using English",
    ["LANG_READY"]="Language updated",["SAVING_UNAVAILABLE"]="Saving Unavailable",
    ["SAVING_UNAVAILABLE_DESC"]="Your executor does not support file functions. Config saving is disabled.",
    ["LOADED_TITLE"]="Dubu Hub",["LOADED_CONTENT"]="Loaded! Press Left Alt to toggle UI.",
}

local HUB_LANGUAGES = {
    {label="English",code="en"},{label="Russian",code="ru"},{label="Spanish",code="es"},
    {label="French",code="fr"},{label="German",code="de"},{label="Portuguese",code="pt"},
    {label="Japanese",code="ja"},{label="Korean",code="ko"},{label="Chinese (Simplified)",code="zh-cn"},
    {label="Arabic",code="ar"},{label="Turkish",code="tr"},{label="Vietnamese",code="vi"},
    {label="Indonesian",code="id"},{label="Filipino",code="tl"},{label="Ilonggo",code="hil"},
    {label="Cebuano",code="ceb"},{label="Aklanon",code="akv"},{label="Gay Lingo",code="Gay Lingo"},
}

local hubLangLabels, hubLangCodeByLabel = {}, {}
for _, entry in ipairs(HUB_LANGUAGES) do
    table.insert(hubLangLabels, entry.label)
    hubLangCodeByLabel[entry.label] = entry.code
end

local localizationConfig = {
    Enabled = true, Prefix = "loc:", DefaultLanguage = "en",
    Translations = { ["en"] = LOC_SOURCE },
}
local hubLanguageLoading = false

local function groqTranslate(text, targetLang)
    if targetLang == "en" then return text end
    local langName = LANG_NAME_MAP[targetLang] or targetLang
    local ok, translated = pcall(function()
        local requestMethod = request or syn and syn.request or http_request
        if not requestMethod then return nil end
        local response = requestMethod({
            Url = "https://api.groq.com/openai/v1/chat/completions",
            Method = "POST",
            Headers = { ["Authorization"]="Bearer "..GROQ_API_KEY, ["Content-Type"]="application/json" },
            Body = HttpService:JSONEncode({
                model = "llama-3.3-70b-versatile",
                messages = {
                    { role="system", content="You are a translation API. Output ONLY the raw translation. No markdown, no quotes, no notes." },
                    { role="user", content=string.format("Target Language: %s\nText: %s", langName, text) }
                },
                temperature = 0.1
            })
        })
        if response and response.StatusCode == 200 then
            local data = HttpService:JSONDecode(response.Body)
            if data and data.choices and data.choices[1] then
                return data.choices[1].message.content:gsub("^%s*(.-)%s*$","%1")
            end
        end
        return nil
    end)
    if ok then return translated end
    return nil
end

local function loadCachedLanguage(lang)
    if not hasFileSupport then return nil end
    local file = LANG_CACHE_FOLDER.."/"..lang..".json"
    if not isfile(file) then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(file)) end)
    if ok and type(data)=="table" then return data end
    return nil
end

local function saveCachedLanguage(lang, translations)
    if not hasFileSupport then return end
    pcall(function() writefile(LANG_CACHE_FOLDER.."/"..lang..".json", HttpService:JSONEncode(translations)) end)
end

local function orderedLocKeys()
    local keys = {}
    for key in pairs(LOC_SOURCE) do table.insert(keys, key) end
    table.sort(keys)
    return keys
end

local function buildLanguageTable(lang)
    if lang == "en" then return LOC_SOURCE end
    local cached = loadCachedLanguage(lang)
    if cached then return cached end
    local noTranslate = { HUB_TITLE=true, HUB_AUTHOR=true, LOADED_TITLE=true }
    local keys = orderedLocKeys()
    local parts = {}
    for _, key in ipairs(keys) do
        if not noTranslate[key] then table.insert(parts, LOC_SOURCE[key]) end
    end
    local batchText = table.concat(parts, LOC_SPLIT)
    local translatedBatch = groqTranslate(batchText, lang)
    if not translatedBatch then return nil end
    local translatedParts = string.split(translatedBatch, LOC_SPLIT)
    local result = {}
    local partIndex = 0
    for _, key in ipairs(keys) do
        if noTranslate[key] then
            result[key] = LOC_SOURCE[key]
        else
            partIndex = partIndex + 1
            result[key] = translatedParts[partIndex] or LOC_SOURCE[key]
        end
    end
    saveCachedLanguage(lang, result)
    return result
end

local function refreshWindUILocalization()
    WindUI:Localization(localizationConfig)
end

local function setHubLanguage(lang, forceRefresh)
    if hubLanguageLoading then return end
    if lang == "en" then WindUI:SetLanguage("en"); return end
    if not forceRefresh and localizationConfig.Translations[lang] then
        WindUI:SetLanguage(lang); return
    end
    if forceRefresh and hasFileSupport then
        local file = LANG_CACHE_FOLDER.."/"..lang..".json"
        if isfile(file) then pcall(delfile, file) end
        localizationConfig.Translations[lang] = nil
    end
    hubLanguageLoading = true
    WindUI:Notify({ Title=LOC_SOURCE.LANGUAGE, Content=LOC_SOURCE.LANG_TRANSLATING, Duration=3 })
    task.spawn(function()
        local translations = buildLanguageTable(lang)
        hubLanguageLoading = false
        if not translations then
            WindUI:Notify({ Title=LOC_SOURCE.LANGUAGE, Content=LOC_SOURCE.LANG_FAILED, Duration=3 })
            WindUI:SetLanguage("en"); return
        end
        localizationConfig.Translations[lang] = translations
        refreshWindUILocalization()
        WindUI:SetLanguage(lang)
        WindUI:Notify({ Title=translations.LOADED_TITLE or LOC_SOURCE.LOADED_TITLE, Content=translations.LANG_READY or LOC_SOURCE.LANG_READY, Duration=2 })
    end)
end

refreshWindUILocalization()

-- ========== GAME NAME ==========
local function getGameName()
    local success, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
    if success and info and info.Name then return info.Name end
    return "Unknown Game"
end
local gameName = getGameName()
local VERSION = "v6.5"

-- ========== WINDOW ==========
local isMobileUser = UserInputService.TouchEnabled
local screenSize = workspace.CurrentCamera.ViewportSize
local winWidth  = isMobileUser and math.min(screenSize.X - 20, 500) or 650
local winHeight = isMobileUser and math.min(screenSize.Y - 60, 360) or 480

local Window = WindUI:CreateWindow({
    Title       = "loc:HUB_TITLE",
    Icon        = "paw-print",
    Author      = "loc:HUB_AUTHOR",
    Folder      = "DubuHub/Streetlife",
    Theme       = "Rosewave",
    Size        = UDim2.fromOffset(winWidth, winHeight),
    MinSize     = isMobileUser and Vector2.new(300,300) or Vector2.new(550,400),
    MaxSize     = isMobileUser and Vector2.new(screenSize.X, screenSize.Y) or Vector2.new(900,600),
    Transparent = true,
    Resizable   = true,
    SideBarWidth     = isMobileUser and 130 or 200,
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    },
    HideSearchBar    = false,
    ScrollBarEnabled = true,
    User = { Enabled = true, Anonymous = false, Callback = function() print("User clicked") end },
})

local tagColor = Color3.fromHex("#e8547a")
Window:Tag({ Title=gameName, Icon="gamepad-2", Color=tagColor, Radius=8 })
Window:Tag({ Title=VERSION, Color=Color3.fromHex("#3d2030"), Border=true, Radius=8 })

if not Window then warn("Failed to create WindUI window.") return end

Window:EditOpenButton({
    Title = "loc:OPEN_BUTTON", Icon = "paw-print",
    CornerRadius = UDim.new(0,16), StrokeThickness = 2,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHex("#e8547a")),
        ColorSequenceKeypoint.new(1, Color3.fromHex("#c2185b")),
    }),
    OnlyMobile = false, Enabled = true, Draggable = true,
})

-- ========== TABS ==========
local tabs = {}
tabs.about     = Window:Tab({ Title="About",              Icon="info",          Locked=false })
tabs.main      = Window:Tab({ Title="loc:TAB_MAIN",       Icon="zap",           Locked=false })
tabs.moneyFarm = Window:Tab({ Title="loc:TAB_MONEY_FARM", Icon="dollar-sign",   Locked=false })
tabs.teleports = Window:Tab({ Title="loc:TAB_TELEPORTS",  Icon="map-pin",       Locked=false })
tabs.houseRob  = Window:Tab({ Title="loc:TAB_HOUSE_ROB",  Icon="house",         Locked=false })
tabs.combat    = Window:Tab({ Title="loc:TAB_COMBAT",     Icon="sword",         Locked=false })
tabs.esp       = Window:Tab({ Title="loc:TAB_ESP",        Icon="eye",           Locked=false })
tabs.shop      = Window:Tab({ Title="loc:TAB_SHOP",       Icon="shopping-cart", Locked=false })
tabs.ui        = Window:Tab({ Title="loc:TAB_UI",         Icon="shopping-bag",  Locked=false })
tabs.carUtils  = Window:Tab({ Title="loc:TAB_CAR_UTILS",  Icon="car",           Locked=false })
tabs.crypto    = Window:Tab({ Title="loc:TAB_CRYPTO",     Icon="bitcoin",       Locked=false })
tabs.misc      = Window:Tab({ Title="loc:TAB_MISC",       Icon="settings",      Locked=false })
tabs.config    = Window:Tab({ Title="loc:TAB_CONFIG",     Icon="database",      Locked=false })

local uiRefs = {}

-- ========== ABOUT TAB ==========
local aboutSection = tabs.about:Section({ Title="About", Icon="info", Opened=true })
aboutSection:Paragraph({ Title="Dubu Hub v6.5", Desc="A powerful script hub for Streetlife Roblox." })
aboutSection:Divider()
aboutSection:Paragraph({ Title="What's New", Desc=[[
- Money Farm – Auto spawn & sell MCXRattlers for fast cash
- Car Utils Tab – Fly car with WASD or mobile auto-forward + no-clip
- Revert Spawn – Spawn special weapon variants from dropdown
- Combined House Rob – One button to unlock & teleport
- Master toggle for teleport after unlock
- Flipsy's Armory – Buy exclusive weapons
- Mask Shop – Purchase masks without money
- Seeds & Supplies – Get seeds or gardening supplies
- Copy & Paste Position – Copy coords or teleport car to pasted coordinates
- Improved aimlock keybind – now supports mouse buttons (LMB/RMB)
- Infinite Stamina now locks Boost permanently
- Performance fixes and UI improvements
- NEW: 2-column teleport layout & Rosewave theme
- UPGRADED: Aimlock with prediction, wall check, and smoothness
- UPGRADED: ESP with boxes, names, health, distance, skeleton, tracers
- UPGRADED: Car Fly with WASD and camera direction, ground speed boost
- NEW: Gun Mods – No Recoil + Fast Reload
]] })
aboutSection:Divider()
aboutSection:Paragraph({ Title="Credits", Desc="Created by Dubu\nUI Library: WindUI by Footagesus" })
aboutSection:Button({ Title="Open Website", Callback=function()
    if setclipboard then
        setclipboard("https://dubuhub.vercel.app/")
        WindUI:Notify({ Title="Copied", Content="Dubu Hub website link copied to clipboard", Duration=2 })
    end
end })

-- ========== FEATURE LOGIC ==========

-- Instant Prompts
local instantPromptsEnabled = false
local promptConnection = nil
local scanningPrompts = false
local function toggleInstantPrompts(value)
    instantPromptsEnabled = value
    if value then
        if promptConnection then return end
        if not scanningPrompts then
            scanningPrompts = true
            task.spawn(function()
                for _, prompt in ipairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then pcall(function() prompt.HoldDuration = 0 end) end
                    task.wait()
                end
                scanningPrompts = false
            end)
        end
        promptConnection = ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
            if prompt and prompt.Parent then pcall(function() prompt.HoldDuration = 0 end) end
        end)
    else
        if promptConnection then promptConnection:Disconnect(); promptConnection = nil end
    end
end

-- Infinite Stamina
local infiniteStaminaEnabled = false
local staminaConnection = nil
local function setStaminaHuge()
    local character = workspace:FindFirstChild(LocalPlayer.Name)
    if character then
        pcall(function() character:SetAttribute("Stamina", 999999); character:SetAttribute("Boost", true) end)
    end
    local staminaVal = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Stamina")
    if staminaVal and staminaVal:IsA("NumberValue") then staminaVal.Value = 100 end
end
local function toggleInfiniteStamina(value)
    infiniteStaminaEnabled = value
    if value then
        if staminaConnection then return end
        setStaminaHuge()
        staminaConnection = RunService.Heartbeat:Connect(setStaminaHuge)
    else
        if staminaConnection then staminaConnection:Disconnect(); staminaConnection = nil end
    end
end
LocalPlayer.CharacterAdded:Connect(function() if infiniteStaminaEnabled then setStaminaHuge() end end)

-- Infinite Strength
local infiniteStrengthEnabled = false
local strengthConnection = nil
local function toggleInfiniteStrength(value)
    infiniteStrengthEnabled = value
    if value then
        if strengthConnection then return end
        strengthConnection = RunService.Heartbeat:Connect(function()
            local val = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Strength")
            if val and val:IsA("NumberValue") then val.Value = 100 end
        end)
    else
        if strengthConnection then strengthConnection:Disconnect(); strengthConnection = nil end
    end
end

-- Unlock Camera
local originalCameraMaxZoom = 20
local function toggleUnlockCamera(value)
    if value then
        originalCameraMaxZoom = LocalPlayer.CameraMaxZoomDistance
        LocalPlayer.CameraMaxZoomDistance = 1000
    else
        LocalPlayer.CameraMaxZoomDistance = originalCameraMaxZoom
    end
end

-- Anti AFK
local antiAFKConnection = nil
local function toggleAntiAFK(value)
    if value then
        if antiAFKConnection then return end
        antiAFKConnection = LocalPlayer.Idled:Connect(function()
            VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end)
        WindUI:Notify({ Title="Anti AFK", Content="Enabled – You won't be kicked", Duration=2 })
    else
        if antiAFKConnection then antiAFKConnection:Disconnect(); antiAFKConnection = nil end
        WindUI:Notify({ Title="Anti AFK", Content="Disabled", Duration=2 })
    end
end

-- ATM
local atmAmount = "1000"
local function withdraw(amount)
    amount = tonumber(amount)
    if amount and amount > 0 then
        local success, err = pcall(function()
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("ATM"):FireServer("Withdraw", amount)
        end)
        if success then WindUI:Notify({ Title="ATM", Content=string.format("Withdrew $%d", amount), Duration=2 }); return true
        else WindUI:Notify({ Title="ATM", Content="Withdraw failed: "..tostring(err), Duration=3 }); return false end
    else
        WindUI:Notify({ Title="ATM", Content="Invalid amount", Duration=2 }); return false
    end
end
local function deposit(amount)
    amount = tonumber(amount)
    if amount and amount > 0 then
        local success, err = pcall(function()
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("ATM"):FireServer("Deposit", amount)
        end)
        if success then WindUI:Notify({ Title="ATM", Content=string.format("Deposited $%d", amount), Duration=2 })
        else WindUI:Notify({ Title="ATM", Content="Deposit failed: "..tostring(err), Duration=3 }) end
    else
        WindUI:Notify({ Title="ATM", Content="Invalid amount", Duration=2 })
    end
end

-- ========== AIMLOCK (UPGRADED) ==========
local aimlock = {
    enabled = false,
    active = false,
    fov = 200,
    maxRange = 1000,
    color = Color3.fromRGB(255,255,255),
    smooth = 0.4,
    prediction = 0.14,
    wallCheck = true,
    targetPart = "Head",
    whitelistedPlayers = {},
    whitelistedSet = {},
    bind = { Type="Mouse", Button=Enum.UserInputType.MouseButton2 },
    currentTarget = nil
}
local Camera = workspace.CurrentCamera

-- Configure aim assist module if available
if isAimAssistReady and aimAssistInstance then
    aimAssistInstance:addPlayerTargets(true, false)

    -- Convert pixel FOV to degrees using camera's field of view
    local function pixelToDegrees(pixels)
        local screenSize = Camera.ViewportSize
        if screenSize and screenSize.X > 0 then
            -- angle = atan( pixel_radius / (screen_width/2 * tan(cam_fov/2)) )
            local camFovRad = math.rad(Camera.FieldOfView)
            local halfScreen = screenSize.X / 2
            local angleRad = math.atan2(pixels / 2, halfScreen / math.tan(camFovRad / 2))
            return math.deg(angleRad) * 2  -- full cone angle
        end
        return math.clamp(pixels / 8, 1, 60)  -- fallback
    end

    local fovDeg = pixelToDegrees(aimlock.fov)
    aimAssistInstance:setRange(aimlock.maxRange)
    aimAssistInstance:setFieldOfView(fovDeg)
    aimAssistInstance:setSortingBehavior("FOV")
    aimAssistInstance:setIgnoreLineOfSight(not aimlock.wallCheck)
    aimAssistInstance:setType("LockOn")
    aimAssistInstance:setMethodStrength("Smooth", 0.5)

    -- Create a dummy Model (not a Part) so GetPivot / PivotTo work
    local dummyModel = Instance.new("Model")
    dummyModel.Name = "AimAssistDummy"
    local dummyPart = Instance.new("Part")
    dummyPart.Anchored = true
    dummyPart.Transparency = 1
    dummyPart.CanCollide = false
    dummyPart.Parent = dummyModel
    dummyModel.PrimaryPart = dummyPart
    dummyModel.Parent = workspace

    aimAssistInstance:setSubject(dummyModel)
    _G.AimAssistDummy = dummyModel
end

local function getBindName(bind)
    if bind.Type == "Keyboard" then return bind.Key.Name end
    if bind.Type == "Mouse" then
        if bind.Button == Enum.UserInputType.MouseButton1 then return "LMB" end
        if bind.Button == Enum.UserInputType.MouseButton2 then return "RMB" end
        return "Mouse Button"
    end
    return "Unknown"
end

local mobileAimlockGui, mobileAimlockButton = nil, nil

local FOVCircle_OK, FOVCircle = pcall(Drawing.new, "Circle")
if FOVCircle_OK and FOVCircle then
    FOVCircle.Thickness = 2; FOVCircle.NumSides = 32; FOVCircle.Visible = false
    FOVCircle.Transparency = 1; FOVCircle.Filled = false; FOVCircle.ZIndex = 999
else
    FOVCircle = nil
end

local SnapLine_OK, SnapLine = pcall(Drawing.new, "Line")
if SnapLine_OK and SnapLine then
    SnapLine.Thickness = 2; SnapLine.Visible = false; SnapLine.Transparency = 1; SnapLine.ZIndex = 999
else
    SnapLine = nil
end

local function updateAimlockVisuals()
    if FOVCircle then FOVCircle.Color = aimlock.color end
    if SnapLine then SnapLine.Color = aimlock.color end
    if FOVCircle then FOVCircle.Radius = aimlock.fov / 2 end
end
updateAimlockVisuals()

local function updateFOVCircle()
    if not FOVCircle then return end
    if isMobileUser then
        local size = Camera.ViewportSize
        if size and size.X > 0 then FOVCircle.Position = Vector2.new(size.X/2, size.Y/2) end
    else
        FOVCircle.Position = UserInputService:GetMouseLocation()
    end
end

local function updateSnapLine(targetPos)
    if not SnapLine then return end
    local fromPos = isMobileUser and Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2) or UserInputService:GetMouseLocation()
    SnapLine.From = fromPos
    local success, screenPoint = pcall(Camera.WorldToViewportPoint, Camera, targetPos)
    if success and screenPoint then SnapLine.To = Vector2.new(screenPoint.X, screenPoint.Y); SnapLine.Visible = true end
end

local function isValidTarget(player)
    return player and player ~= LocalPlayer and player.Character
        and player.Character:FindFirstChild("Head")
        and player.Character:FindFirstChild("Humanoid")
        and player.Character.Humanoid.Health > 0
        and player.Character:FindFirstChild("HumanoidRootPart")
end

local function localCharacterValid()
    return LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        and LocalPlayer.Character:FindFirstChild("Humanoid")
        and LocalPlayer.Character.Humanoid.Health > 0
end

local STICKY_FOV_MULT = 1.2

local function IsVisible(targetPart)
    if not aimlock.wallCheck then return true end
    local cam = workspace.CurrentCamera
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, cam}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local result = workspace:Raycast(cam.CFrame.Position, targetPart.Position - cam.CFrame.Position, params)
    return result == nil or result.Instance:IsDescendantOf(targetPart.Parent)
end

local function getClosestPlayer()
    if not localCharacterValid() then return nil end
    local rootPart = LocalPlayer.Character.HumanoidRootPart
    local centerPos = isMobileUser and Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2) or UserInputService:GetMouseLocation()
    local closestPlayer, shortestDistance = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isValidTarget(player) then
            if not aimlock.whitelistedSet[player.Name] then
                local part = player.Character:FindFirstChild(aimlock.targetPart) or player.Character.HumanoidRootPart
                local worldDist = (part.Position - rootPart.Position).Magnitude
                if worldDist <= aimlock.maxRange then
                    local ok, sp = pcall(Camera.WorldToViewportPoint, Camera, part.Position)
                    if ok and sp and sp.Z > 0 then
                        local distFromCenter = (Vector2.new(sp.X, sp.Y) - centerPos).Magnitude
                        if distFromCenter <= aimlock.fov/2 and IsVisible(part) and worldDist < shortestDistance then
                            shortestDistance = worldDist; closestPlayer = player
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function isStickyValid(player)
    if not isValidTarget(player) then return false end
    local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    local part = player.Character:FindFirstChild(aimlock.targetPart) or player.Character.HumanoidRootPart
    if (part.Position - rootPart.Position).Magnitude > aimlock.maxRange * STICKY_FOV_MULT then return false end
    local centerPos = isMobileUser and Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2) or UserInputService:GetMouseLocation()
    local ok, sp = pcall(Camera.WorldToViewportPoint, Camera, part.Position)
    if not ok or not sp or sp.Z <= 0 then return false end
    return (Vector2.new(sp.X, sp.Y) - centerPos).Magnitude <= (aimlock.fov/2) * STICKY_FOV_MULT and IsVisible(part)
end

local moveMouseFunc = nil
if not isMobileUser then
    if mousemoverel then
        moveMouseFunc = function(dx, dy) mousemoverel(dx, dy) end
    elseif pcall(function() return VirtualInputManager.SendMouseMoveEvent end) then
        moveMouseFunc = function(dx, dy) VirtualInputManager:SendMouseMoveEvent(dx, dy, game) end
    end
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not aimlock.enabled or isMobileUser then return end
    if aimlock.bind.Type=="Keyboard" and input.KeyCode==aimlock.bind.Key then aimlock.active=true
    elseif aimlock.bind.Type=="Mouse" and input.UserInputType==aimlock.bind.Button then aimlock.active=true end
end)
UserInputService.InputEnded:Connect(function(input, gp)
    if gp or isMobileUser then return end
    if aimlock.bind.Type=="Keyboard" and input.KeyCode==aimlock.bind.Key then
        aimlock.active=false; if SnapLine then SnapLine.Visible=false end; aimlock.currentTarget=nil
    elseif aimlock.bind.Type=="Mouse" and input.UserInputType==aimlock.bind.Button then
        aimlock.active=false; if SnapLine then SnapLine.Visible=false end; aimlock.currentTarget=nil
    end
end)

-- ========== MOBILE AIMLOCK BUTTON ==========
local mobileAimlockCreationAttempted = false

local function getPlayerGui()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then return pg end
    local ok, result = pcall(function()
        return LocalPlayer:WaitForChild("PlayerGui", 5)
    end)
    if ok and result then return result end
    for _, child in ipairs(LocalPlayer:GetChildren()) do
        if child.ClassName == "PlayerGui" then
            return child
        end
    end
    return nil
end

local function createMobileAimlockButton()
    if mobileAimlockGui and mobileAimlockGui.Parent then return true end
    if mobileAimlockGui then
        pcall(function() mobileAimlockGui:Destroy() end)
        mobileAimlockGui = nil
        mobileAimlockButton = nil
    end
    local playerGui = getPlayerGui()
    if not playerGui then
        warn("Dubu Hub: PlayerGui not found! Cannot create mobile button.")
        return false
    end
    mobileAimlockCreationAttempted = true
    mobileAimlockGui = Instance.new("ScreenGui")
    mobileAimlockGui.Name = "MobileAimlockGui"
    mobileAimlockGui.ResetOnSpawn = false
    mobileAimlockGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    mobileAimlockGui.Enabled = true
    mobileAimlockGui.IgnoreGuiInset = true
    mobileAimlockGui.DisplayOrder = 999
    mobileAimlockGui.Parent = playerGui

    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "AimlockContainer"
    buttonContainer.Size = UDim2.new(0, 130, 0, 52)
    buttonContainer.Position = UDim2.new(0.1, 0, 0.9, 0)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = mobileAimlockGui

    mobileAimlockButton = Instance.new("TextButton")
    mobileAimlockButton.Name = "AimlockButton"
    mobileAimlockButton.Size = UDim2.new(1, 0, 1, 0)
    mobileAimlockButton.Position = UDim2.new(0, 0, 0, 0)
    mobileAimlockButton.BackgroundColor3 = Color3.fromRGB(232, 84, 122)
    mobileAimlockButton.BorderSizePixel = 0
    mobileAimlockButton.Font = Enum.Font.GothamBold
    mobileAimlockButton.Text = "AIM"
    mobileAimlockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    mobileAimlockButton.TextSize = 14
    mobileAimlockButton.AutoButtonColor = false
    mobileAimlockButton.BackgroundTransparency = 0.15
    mobileAimlockButton.Parent = buttonContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = mobileAimlockButton

    local gradientOverlay = Instance.new("Frame")
    gradientOverlay.Name = "Gradient"
    gradientOverlay.Size = UDim2.new(1, -8, 1, -8)
    gradientOverlay.Position = UDim2.new(0, 4, 0, 4)
    gradientOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    gradientOverlay.BackgroundTransparency = 0.85
    gradientOverlay.BorderSizePixel = 0
    gradientOverlay.Parent = mobileAimlockButton

    local gradientCorner = Instance.new("UICorner")
    gradientCorner.CornerRadius = UDim.new(0, 10)
    gradientCorner.Parent = gradientOverlay

    local statusDot = Instance.new("Frame")
    statusDot.Name = "StatusDot"
    statusDot.Size = UDim2.new(0, 10, 0, 10)
    statusDot.Position = UDim2.new(1, -18, 0.5, -5)
    statusDot.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    statusDot.BorderSizePixel = 0
    statusDot.Parent = mobileAimlockButton

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = statusDot

    local dragHandle = Instance.new("Frame")
    dragHandle.Name = "DragHandle"
    dragHandle.Size = UDim2.new(0, 18, 1, 0)
    dragHandle.Position = UDim2.new(0, 0, 0, 0)
    dragHandle.BackgroundColor3 = Color3.fromRGB(194, 24, 91)
    dragHandle.BorderSizePixel = 0
    dragHandle.BackgroundTransparency = 0.3
    dragHandle.Parent = mobileAimlockButton

    local handleCorner = Instance.new("UICorner")
    handleCorner.CornerRadius = UDim.new(0, 14)
    handleCorner.Parent = dragHandle

    for i = 0, 2 do
        local line = Instance.new("Frame")
        line.Name = "Line" .. i
        line.Size = UDim2.new(0, 8, 0, 2)
        line.Position = UDim2.new(0, 5, 0, 14 + (i * 10))
        line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        line.BackgroundTransparency = 0.4
        line.BorderSizePixel = 0
        line.Parent = dragHandle
        local lineCorner = Instance.new("UICorner")
        lineCorner.CornerRadius = UDim.new(1, 0)
        lineCorner.Parent = line
    end

    local pulseConnection = nil
    local mobileActive, isToggling = false, false
    local dragging, dragStart, containerStartPos = false, nil, nil
    local dragOccurred = false
    local smoothTargetPosition = nil
    local aimSmoothness = 0.15

    local function updateButtonVisuals()
        if not mobileAimlockButton or not mobileAimlockButton.Parent then return end
        if mobileActive then
            mobileAimlockButton.BackgroundColor3 = Color3.fromRGB(76, 255, 140)
            mobileAimlockButton.Text = "AIM ON"
            statusDot.BackgroundColor3 = Color3.fromRGB(76, 255, 140)
            dragHandle.BackgroundColor3 = Color3.fromRGB(30, 200, 80)
            if not pulseConnection then
                pulseConnection = RunService.Heartbeat:Connect(function()
                    if not statusDot or not statusDot.Parent then
                        if pulseConnection then pulseConnection:Disconnect() pulseConnection = nil end
                        return
                    end
                    local time = tick()
                    local pulse = 0.6 + (math.sin(time * 4) * 0.15)
                    statusDot.BackgroundTransparency = pulse
                end)
            end
        else
            mobileAimlockButton.BackgroundColor3 = Color3.fromRGB(232, 84, 122)
            mobileAimlockButton.Text = "AIM"
            statusDot.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
            dragHandle.BackgroundColor3 = Color3.fromRGB(194, 24, 91)
            if pulseConnection then
                pulseConnection:Disconnect()
                pulseConnection = nil
            end
            statusDot.BackgroundTransparency = 0
        end
    end

    local function toggleMobile()
        if isToggling then return end
        isToggling = true
        mobileActive = not mobileActive
        aimlock.active = mobileActive
        updateButtonVisuals()
        if FOVCircle then FOVCircle.Visible = mobileActive end
        if not mobileActive then
            if SnapLine then SnapLine.Visible = false end
            smoothTargetPosition = nil
            aimlock.currentTarget = nil
        end
        task.wait(0.1)
        isToggling = false
    end

    local mobileAimRenderConnection = nil
    mobileAimRenderConnection = RunService.RenderStepped:Connect(function(dt)
        if not aimlock.enabled or not aimlock.active then return end

        local targetPosition = nil

        if isAimAssistReady and aimAssistInstance then
            local dummy = _G.AimAssistDummy
            if dummy and dummy.PrimaryPart then
                dummy:SetPrimaryPartCFrame(Camera.CFrame)
            end
            local targetResult = aimAssistInstance.targetSelector:selectTarget(dummy, Camera.CFrame.LookVector)
            if targetResult and targetResult.AdjustedPoint then
                targetPosition = targetResult.AdjustedPoint
            end
        else
            -- Fallback to original method
            if aimlock.currentTarget then
                if not isStickyValid(aimlock.currentTarget) then
                    aimlock.currentTarget = nil
                    smoothTargetPosition = nil
                end
            else
                aimlock.currentTarget = getClosestPlayer()
                if aimlock.currentTarget then
                    local part = aimlock.currentTarget.Character:FindFirstChild(aimlock.targetPart) or aimlock.currentTarget.Character.HumanoidRootPart
                    smoothTargetPosition = part.Position
                end
            end
            if aimlock.currentTarget and isValidTarget(aimlock.currentTarget) then
                local part = aimlock.currentTarget.Character:FindFirstChild(aimlock.targetPart) or aimlock.currentTarget.Character.HumanoidRootPart
                if smoothTargetPosition then
                    smoothTargetPosition = smoothTargetPosition:Lerp(part.Position, aimSmoothness)
                else
                    smoothTargetPosition = part.Position
                end
                targetPosition = smoothTargetPosition
            end
        end

        if targetPosition then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
            if SnapLine then
                updateSnapLine(targetPosition)
            end
        else
            if SnapLine then SnapLine.Visible = false end
            smoothTargetPosition = nil
        end
    end)

    -- Drag handling
    local function onDragBegan(inputPos)
        dragging = true
        dragOccurred = false
        dragStart = inputPos
        containerStartPos = buttonContainer.Position
        dragHandle.BackgroundTransparency = 0
    end

    local function onDragEnded()
        if dragging then
            if not dragOccurred then
                toggleMobile()
            end
            dragging = false
            dragOccurred = false
            dragStart = nil
            containerStartPos = nil
            dragHandle.BackgroundTransparency = 0.3
        end
    end

    local function onInputBegan(inputPos)
        if not dragging then
            onDragBegan(inputPos)
        end
    end

    local function onInputEnded()
        onDragEnded()
    end

    mobileAimlockButton.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            onInputBegan(input.Position)
        end
    end)

    mobileAimlockButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            onInputEnded()
        end
    end)

    buttonContainer.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Touch then
            onInputBegan(input.Position)
        end
    end)

    local moveConnection = UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.Touch then
            local currentPos = input.Position
            local delta = currentPos - dragStart
            local distance = delta.Magnitude
            if distance > 8 then
                dragOccurred = true
                local newX = containerStartPos.X.Offset + delta.X
                local newY = containerStartPos.Y.Offset + delta.Y
                local viewSize = Camera.ViewportSize
                newX = math.max(0, math.min(newX, viewSize.X - 130))
                newY = math.max(0, math.min(newY, viewSize.Y - 52))
                buttonContainer.Position = UDim2.new(0, newX, 0, newY)
            end
        end
    end)

    local touchEndFallback = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and dragging then
            onInputEnded()
        end
    end)

    mobileAimlockGui:SetAttribute("MoveConn", true)
    mobileAimlockGui:SetAttribute("TouchEndConn", true)

    updateButtonVisuals()
    print("Dubu Hub: Mobile aimlock button created!")
    return true
end

local function ensureMobileAimlockButton()
    if not isMobileUser then return false end
    if mobileAimlockGui and mobileAimlockGui.Parent then return true end
    local success, result = pcall(createMobileAimlockButton)
    if not success then
        warn("Dubu Hub: Mobile aimlock button error: " .. tostring(result))
        WindUI:Notify({ Title = "Mobile Button", Content = "Error: " .. tostring(result), Duration = 5 })
        return false
    end
    if mobileAimlockGui and mobileAimlockGui.Parent then
        WindUI:Notify({ Title = "Mobile Button", Content = "Aimlock button created! Tap to toggle.", Duration = 3 })
        return true
    end
    WindUI:Notify({ Title = "Mobile Button", Content = "Failed to create button. Try again.", Duration = 3 })
    return false
end

if isMobileUser then
    task.spawn(function()
        task.wait(2)
        if not mobileAimlockGui then
            ensureMobileAimlockButton()
        end
    end)
end

-- ========== ESP (UPGRADED) ==========
local esp = {
    enabled = false,
    boxes = false,
    names = false,
    health = false,
    distance = false,
    skeleton = false,
    tracers = false,
    fill = false,
    color = Color3.fromRGB(220,20,60),
    whitelistColor = Color3.fromRGB(0,0,255),
    maxDistance = 1000,
    objects = {}
}
local EspSettings = esp

local function removeESPForPlayer(player)
    local data = EspSettings.objects[player]
    if data then
        if data.nameBillboard then data.nameBillboard:Destroy() end
        if data.healthBillboard then data.healthBillboard:Destroy() end
        if data.highlight then data.highlight:Destroy() end
        if data.Box then pcall(function() data.Box:Remove() end) end
        if data.BoxO then pcall(function() data.BoxO:Remove() end) end
        if data.Dist then pcall(function() data.Dist:Remove() end) end
        if data.Tracer then pcall(function() data.Tracer:Remove() end) end
        if data.Bones then
            for _, l in pairs(data.Bones) do pcall(function() l:Remove() end) end
        end
        EspSettings.objects[player] = nil
    end
end

local function createESPForPlayer(player)
    if not player.Character then return end
    removeESPForPlayer(player)
    local char = player.Character
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if not head or not humanoid then return end

    local playerEsp = {}

    -- Highlight for fill effect (chams) - initially disabled
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0.7
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false
    highlight.Parent = char
    playerEsp.highlight = highlight

    -- Name BillboardGui (3D world-space)
    local nameBillboard = Instance.new("BillboardGui")
    nameBillboard.Name = "ESP_Name"
    nameBillboard.Size = UDim2.new(0, 100, 0, 20)
    nameBillboard.AlwaysOnTop = true
    nameBillboard.StudsOffset = Vector3.new(0, 2.5, 0)
    nameBillboard.Parent = head
    nameBillboard.Enabled = false
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = EspSettings.color
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = nameBillboard
    playerEsp.nameLabel = nameLabel
    playerEsp.nameBillboard = nameBillboard

    -- Health BillboardGui (3D world-space)
    local healthBillboard = Instance.new("BillboardGui")
    healthBillboard.Name = "ESP_Health"
    healthBillboard.Size = UDim2.new(0, 50, 0, 5)
    healthBillboard.AlwaysOnTop = true
    healthBillboard.StudsOffset = Vector3.new(0, 1.5, 0)
    healthBillboard.Parent = head
    healthBillboard.Enabled = false
    local hpBg = Instance.new("Frame")
    hpBg.Size = UDim2.new(1, 0, 1, 0)
    hpBg.BackgroundColor3 = Color3.new(0, 0, 0)
    hpBg.BackgroundTransparency = 0.3
    hpBg.BorderSizePixel = 0
    hpBg.Parent = healthBillboard
    local hpFill = Instance.new("Frame")
    hpFill.Name = "Fill"
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = Color3.new(0, 1, 0)
    hpFill.BorderSizePixel = 0
    hpFill.Parent = hpBg
    playerEsp.healthFill = hpFill
    playerEsp.healthBillboard = healthBillboard

    -- 2D Drawing objects for boxes, distance, tracers, skeleton
    local box = Drawing.new("Square")
    box.Filled = false; box.Thickness = 1
    local boxOutline = Drawing.new("Square")
    boxOutline.Filled = false; boxOutline.Thickness = 3; boxOutline.Color = Color3.new(0,0,0)
    local distLabel = Drawing.new("Text")
    distLabel.Center = true; distLabel.Outline = true; distLabel.Size = 12; distLabel.Font = 2
    local tracer = Drawing.new("Line")
    tracer.Thickness = 1
    local bones = {}
    for _, b in ipairs({"Head_Spine","Spine_LArm","Spine_RArm","Spine_LLeg","Spine_RLeg"}) do
        local line = Drawing.new("Line")
        line.Thickness = 1.5
        bones[b] = line
    end

    playerEsp.Box = box
    playerEsp.BoxO = boxOutline
    playerEsp.Dist = distLabel
    playerEsp.Tracer = tracer
    playerEsp.Bones = bones

    EspSettings.objects[player] = playerEsp
end

local function updateESP()
    local cam = workspace.CurrentCamera
    for player, data in pairs(EspSettings.objects) do
        if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChild("Humanoid") then
            removeESPForPlayer(player)
            continue
        end
        local char = player.Character
        local root = char.HumanoidRootPart
        local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or root
        local head = char:FindFirstChild("Head")
        local humanoid = char.Humanoid
        local dist = (cam.CFrame.Position - torso.Position).Magnitude
        local useColor = aimlock.whitelistedSet[player.Name] and EspSettings.whitelistColor or EspSettings.color

        -- Update Highlight (Fill) - only when fill toggle is on
        if data.highlight then
            data.highlight.FillColor = useColor
            data.highlight.OutlineColor = useColor
            data.highlight.Enabled = EspSettings.fill and EspSettings.enabled and dist <= EspSettings.maxDistance
        end

        -- Update BillboardGui elements (names/health) - 3D world-space
        if data.nameLabel then
            data.nameLabel.TextColor3 = useColor
            data.nameBillboard.Enabled = EspSettings.names and EspSettings.enabled and dist <= EspSettings.maxDistance
        end
        if data.healthFill then
            local hpPct = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            data.healthFill.Size = UDim2.new(hpPct, 0, 1, 0)
            data.healthFill.BackgroundColor3 = Color3.new(1 - hpPct, hpPct, 0)
            data.healthBillboard.Enabled = EspSettings.health and EspSettings.enabled and dist <= EspSettings.maxDistance
        end

        -- Hide all 2D Drawing objects initially
        if data.Box then data.Box.Visible = false end
        if data.BoxO then data.BoxO.Visible = false end
        if data.Dist then data.Dist.Visible = false end
        if data.Tracer then data.Tracer.Visible = false end
        if data.Bones then
            for _, b in pairs(data.Bones) do b.Visible = false end
        end

        -- Check if ESP is enabled and within distance
        if not EspSettings.enabled or dist > EspSettings.maxDistance then
            continue
        end

        -- Check if player is on screen (Z > 0 means in front of camera)
        local pos, onScreen = cam:WorldToViewportPoint(torso.Position)
        if not onScreen or pos.Z <= 0 then
            continue
        end

        local topPos = cam:WorldToViewportPoint(torso.Position + Vector3.new(0, 2.5, 0))
        local botPos  = cam:WorldToViewportPoint(torso.Position - Vector3.new(0, 3.0, 0))
        local h = math.abs(topPos.Y - botPos.Y)
        if h < 1 then continue end
        local w = h / 1.5

        -- Update 2D Drawing objects
        if EspSettings.boxes and data.Box and data.BoxO then
            data.Box.Size = Vector2.new(w, h)
            data.Box.Position = Vector2.new(pos.X - w/2, topPos.Y)
            data.Box.Color = useColor
            data.Box.Visible = true
            data.BoxO.Size = Vector2.new(w+2, h+2)
            data.BoxO.Position = Vector2.new(pos.X - w/2 - 1, topPos.Y - 1)
            data.BoxO.Visible = true
        end

        if EspSettings.distance and data.Dist then
            data.Dist.Text = "[" .. math.floor(dist) .. "m]"
            data.Dist.Position = Vector2.new(pos.X, botPos.Y + 2)
            data.Dist.Color = Color3.fromRGB(160,140,140)
            data.Dist.Visible = true
        end

        if EspSettings.tracers and data.Tracer then
            data.Tracer.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
            data.Tracer.To = Vector2.new(pos.X, botPos.Y)
            data.Tracer.Color = useColor
            data.Tracer.Visible = true
        end

        -- Skeleton
        if EspSettings.skeleton and data.Bones then
            local function drawBone(key, a, b)
                if a and b then
                    local s1, o1 = cam:WorldToViewportPoint(a.Position)
                    local s2, o2 = cam:WorldToViewportPoint(b.Position)
                    if o1 and o2 and s1.Z > 0 and s2.Z > 0 then
                        data.Bones[key].From = Vector2.new(s1.X, s1.Y)
                        data.Bones[key].To = Vector2.new(s2.X, s2.Y)
                        data.Bones[key].Color = useColor
                        data.Bones[key].Visible = true
                        return
                    end
                end
                data.Bones[key].Visible = false
            end
            local spine = torso
            local lArm = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
            local rArm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
            local lLeg = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")
            local rLeg = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")
            drawBone("Head_Spine", head, spine)
            drawBone("Spine_LArm", spine, lArm)
            drawBone("Spine_RArm", spine, rArm)
            drawBone("Spine_LLeg", spine, lLeg)
            drawBone("Spine_RLeg", spine, rLeg)
        end
    end
end

local function refreshESP()
    for player in pairs(EspSettings.objects) do removeESPForPlayer(player) end
    if EspSettings.enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then createESPForPlayer(player) end
        end
    end
end

local function onCharacterAdded(player)
    player.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart", 5)
        if EspSettings.enabled and player ~= LocalPlayer then createESPForPlayer(player) end
    end)
end
for _, player in ipairs(Players:GetPlayers()) do onCharacterAdded(player) end
Players.PlayerAdded:Connect(onCharacterAdded)
Players.PlayerRemoving:Connect(function(player)
    removeESPForPlayer(player)
end)

-- ========== GUN MODS ==========
local gunMods = {
    NoRecoil = false,
    FastReload = false,
    ReloadSpeed = 3.0
}
local prevCamPitch = nil
local isShooting = false

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isShooting = true
        prevCamPitch = nil
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isShooting = false
        prevCamPitch = nil
    end
end)

RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    if gunMods.NoRecoil and isShooting then
        local _, currentPitch, _ = cam.CFrame:ToEulerAnglesYXZ()
        if prevCamPitch ~= nil then
            local delta = currentPitch - prevCamPitch
            if delta < -0.0008 and mousemoverel then
                local comp = math.deg(delta * -1) * (cam.ViewportSize.Y / cam.FieldOfView) * 0.85
                mousemoverel(0, comp)
            end
        end
        prevCamPitch = currentPitch
    elseif not isShooting then
        prevCamPitch = nil
    end
end)

RunService.Heartbeat:Connect(function()
    if gunMods.FastReload then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                for _, anim in pairs(hum:GetPlayingAnimationTracks()) do
                    if string.find(string.lower(anim.Name), "reload") then
                        anim:AdjustSpeed(gunMods.ReloadSpeed)
                    end
                end
            end
        end
    end
end)

-- ========== CAR UTILS (UPGRADED) ==========
local carMods = {
    Fly = false,
    FlyKey = Enum.KeyCode.F,
    SpeedBoost = false,
    SpeedAmount = 150
}
local carFlyEnabled = false

-- Mobile fly buttons
local mobileFlyGui, upButton, downButton = nil, nil, nil
local upPressed, downPressed = false, false

local function createMobileFlyButtons()
    if mobileFlyGui then return end
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end
    mobileFlyGui = Instance.new("ScreenGui")
    mobileFlyGui.Name = "MobileCarFlyGui"
    mobileFlyGui.ResetOnSpawn = false
    mobileFlyGui.Parent = playerGui

    local function makeButton(name, position, color, text)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(0, 80, 0, 80)
        btn.Position = position
        btn.BackgroundColor3 = color
        btn.BackgroundTransparency = 0.4
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Color3.white
        btn.TextSize = 28
        btn.Font = Enum.Font.GothamBold
        btn.AutoButtonColor = false
        btn.Parent = mobileFlyGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 20)
        corner.Parent = btn

        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                if name == "Up" then upPressed = true
                elseif name == "Down" then downPressed = true end
            end
        end)
        btn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                if name == "Up" then upPressed = false
                elseif name == "Down" then downPressed = false end
            end
        end)
        return btn
    end

    upButton   = makeButton("Up",   UDim2.new(1, -90, 1, -170), Color3.fromRGB(0, 170, 255), "▲")
    downButton = makeButton("Down", UDim2.new(0, 10, 1, -170), Color3.fromRGB(255, 100, 100), "▼")
end

local function destroyMobileFlyButtons()
    if mobileFlyGui then
        mobileFlyGui:Destroy()
        mobileFlyGui = nil
        upButton = nil
        downButton = nil
    end
    upPressed = false
    downPressed = false
end

local function toggleCarFly()
    carFlyEnabled = not carFlyEnabled
    if uiRefs.CarFlyToggle then
        uiRefs.CarFlyToggle:Set(carFlyEnabled)
    end
    if carFlyEnabled then
        if isMobileUser then createMobileFlyButtons() end
        WindUI:Notify({ Title = "Car Fly", Content = "Enabled" .. (isMobileUser and " – use ▲/▼ for height" or ""), Duration = 2 })
    else
        destroyMobileFlyButtons()
        WindUI:Notify({ Title = "Car Fly", Content = "Disabled", Duration = 2 })
    end
end

-- Keybind toggles car fly
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == carMods.FlyKey then
        toggleCarFly()
    end
end)

-- Car fly loop (runs every frame)
RunService.Stepped:Connect(function(_, dt)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local seat = hum.SeatPart
    if not seat or not seat:IsA("VehicleSeat") then return end
    local cam = workspace.CurrentCamera
    local car = seat.Parent

    -- Ground speed boost
    if carMods.SpeedBoost and not carFlyEnabled then
        if seat.AssemblyLinearVelocity.Magnitude > 5 then
            seat.AssemblyLinearVelocity = seat.AssemblyLinearVelocity + (seat.CFrame.LookVector * (carMods.SpeedAmount * dt))
        end
    end

    -- Car fly
    if carFlyEnabled then
        local vel = Vector3.new(0, 0, 0)
        local spd = carMods.SpeedAmount

        if isMobileUser then
            -- Mobile: use throttle from the seat (0..1) for forward/backward
            local throttle = seat.Throttle or 0
            -- also check if the player is touching the forward/backward controls
            -- but throttle already reflects that
            if math.abs(throttle) > 0.05 then
                vel = vel + cam.CFrame.LookVector * spd * throttle
            end

            -- Up/down buttons
            if upPressed then vel = vel + Vector3.new(0, spd, 0) end
            if downPressed then vel = vel + Vector3.new(0, -spd, 0) end
        else
            -- PC: WASD
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + cam.CFrame.LookVector * spd end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - cam.CFrame.LookVector * spd end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - cam.CFrame.RightVector * spd end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + cam.CFrame.RightVector * spd end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vel = vel + Vector3.new(0, spd, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel + Vector3.new(0, -spd, 0) end
        end

        -- Apply velocity and keep car upright
        if vel.Magnitude > 0 then
            seat.AssemblyLinearVelocity = vel
            seat.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            -- Align car to camera direction (optional)
            -- car:SetPrimaryPartCFrame(CFrame.new(car.PrimaryPart.Position, cam.CFrame.Position + cam.CFrame.LookVector * 10))
        else
            -- If no input, stop the car
            seat.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
    end
end)

-- Noclip (car + player)
local carNoclipEnabled = false
local function setNoclip(state)
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = not state end
        end
    end
    local car = getMyCar()
    if car then
        for _, part in ipairs(car:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = not state end
        end
    end
end

-- Misc features
local blurEffect, blurHeartbeatConnection, cameraChangedConnection = nil, nil, nil
local lastLookVector = Camera and Camera.CFrame and Camera.CFrame.lookVector or Vector3.new(0, 0, -1)
local function createBlur()
    if blurEffect then blurEffect:Destroy() end
    blurEffect = Instance.new("BlurEffect"); blurEffect.Parent = Camera
end
local function toggleRealisticGraphics(value)
    if value then
        createBlur()
        blurHeartbeatConnection = RunService.Heartbeat:Connect(function()
            if not blurEffect or blurEffect.Parent ~= Camera then createBlur() end
            local magnitude = (Camera.CFrame.lookVector - lastLookVector).magnitude
            blurEffect.Size = math.abs(magnitude) * 20
            lastLookVector = Camera.CFrame.lookVector
        end)
        cameraChangedConnection = workspace.Changed:Connect(function(prop)
            if prop == "CurrentCamera" then
                Camera = workspace.CurrentCamera
                if blurEffect then blurEffect.Parent = Camera else createBlur() end
            end
        end)
        WindUI:Notify({ Title="Graphics", Content="Realistic mode ON", Duration=2 })
    else
        if blurHeartbeatConnection then blurHeartbeatConnection:Disconnect(); blurHeartbeatConnection=nil end
        if cameraChangedConnection then cameraChangedConnection:Disconnect(); cameraChangedConnection=nil end
        if blurEffect then blurEffect:Destroy(); blurEffect=nil end
        WindUI:Notify({ Title="Graphics", Content="Realistic mode OFF", Duration=2 })
    end
end

local function fullBright()
    Lighting.Ambient=Color3.new(1,1,1); Lighting.Brightness=2
    Lighting.ColorShift_Top=Color3.new(1,1,1); Lighting.ColorShift_Bottom=Color3.new(1,1,1)
    Lighting.OutdoorAmbient=Color3.new(1,1,1); Lighting.GlobalShadows=false
    Lighting.FogEnd=100000; Lighting.FogStart=0
    WindUI:Notify({ Title="Full Bright", Content="Enabled (no shadows)", Duration=2 })
end

local function loadInfiniteYield()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    WindUI:Notify({ Title="Infinite Yield", Content="Loaded!", Duration=2 })
end

-- ========== MAIN TAB ==========
local mainUtilities = tabs.main:Section({ Title="Utilities", Icon="zap", Opened=true })
mainUtilities:Paragraph({ Title="Utilities", Desc="General purpose toggles and actions." })
uiRefs.InstantPromptsToggle = mainUtilities:Toggle({ Title="Instant Prompts", Desc="Make all proximity prompts instant", Flag="InstantPrompts", Default=false, Callback=toggleInstantPrompts })
uiRefs.InfiniteStaminaToggle = mainUtilities:Toggle({ Title="Infinite Stamina", Desc="Prevents stamina from decreasing + boost", Flag="InfiniteStamina", Default=false, Callback=toggleInfiniteStamina })
uiRefs.InfiniteStrengthToggle = mainUtilities:Toggle({ Title="Infinite Strength", Desc="Keep Strength at 100", Flag="InfiniteStrength", Default=false, Callback=toggleInfiniteStrength })
uiRefs.UnlockCameraToggle = mainUtilities:Toggle({ Title="Unlock Camera", Desc="Set camera max zoom to 1000", Flag="UnlockCamera", Default=false, Callback=toggleUnlockCamera })
uiRefs.AntiAFKToggle = mainUtilities:Toggle({ Title="Anti AFK", Desc="Prevent being kicked for idle", Flag="AntiAFK", Default=false, Callback=toggleAntiAFK })

local mainATM = tabs.main:Section({ Title="ATM", Icon="dollar-sign", Opened=false })
mainATM:Paragraph({ Title="ATM", Desc="Withdraw or deposit cash." })
uiRefs.ATMAmount = mainATM:Input({ Title="Amount", Desc="Amount to withdraw or deposit", Value=atmAmount, Type="Input", Placeholder="Enter number...", Callback=function(input) atmAmount=input end })
mainATM:Button({ Title="Withdraw", Desc="Withdraw the entered amount", Callback=function() withdraw(atmAmount) end })
mainATM:Button({ Title="Deposit",  Desc="Deposit the entered amount",  Callback=function() deposit(atmAmount) end })
mainATM:Button({ Title="Deposit All", Desc="Deposit all wallet money", Callback=function()
    local moneyVal = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Money")
    if moneyVal and moneyVal:IsA("NumberValue") and moneyVal.Value > 0 then
        deposit(moneyVal.Value); WindUI:Notify({ Title="ATM", Content="Deposited all money", Duration=2 })
    else WindUI:Notify({ Title="ATM", Content="No money to deposit", Duration=2 }) end
end })

local mainSendMoney = tabs.main:Section({ Title="Send Money", Icon="send", Opened=false })
mainSendMoney:Paragraph({ Title="Send Money", Desc="Send cash to another player." })
local sendUsername, sendAmount = "", ""
mainSendMoney:Input({ Title="Recipient Username", Desc="Enter the player's username", Value="", Type="Input", Placeholder="e.g., Flipsy", Callback=function(input) sendUsername=input end })
mainSendMoney:Input({ Title="Amount", Desc="Enter amount to send", Value="", Type="Input", Placeholder="e.g., 10000", Callback=function(input) sendAmount=input end })
mainSendMoney:Button({ Title="Send Money", Desc="Send the specified amount", Callback=function()
    if sendUsername=="" or sendAmount=="" then WindUI:Notify({ Title="Send Money", Content="Please enter both username and amount", Duration=2 }); return end
    local targetPlayer = Players:FindFirstChild(sendUsername)
    if not targetPlayer then WindUI:Notify({ Title="Send Money", Content="Player not found", Duration=2 }); return end
    local amount = tonumber(sendAmount)
    if not amount or amount <= 0 then WindUI:Notify({ Title="Send Money", Content="Invalid amount", Duration=2 }); return end
    local ok, err = pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Phone"):FireServer("SendMoney", targetPlayer, amount)
    end)
    if ok then WindUI:Notify({ Title="Send Money", Content=string.format("Sent $%d to %s", amount, sendUsername), Duration=2 })
    else WindUI:Notify({ Title="Send Money", Content="Failed: "..tostring(err), Duration=3 }) end
end })

local mainCommands = tabs.main:Section({ Title="Commands", Icon="terminal", Opened=false })
mainCommands:Paragraph({ Title="Commands", Desc="Quick commands using ControllerRemote." })
local handToUsername = ""
mainCommands:Input({ Title="Hand To Username", Desc="Enter player username to hand item to", Value="", Type="Input", Placeholder="e.g., Flipsy", Callback=function(input) handToUsername=input end })
mainCommands:Button({ Title="Hand To", Desc="Hands your held item to the player", Callback=function()
    if handToUsername=="" then WindUI:Notify({ Title="Command", Content="Please enter a username", Duration=2 }); return end
    local ok,err = pcall(function() game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("ControllerRemote"):FireServer("/handto "..handToUsername) end)
    if ok then WindUI:Notify({ Title="Command", Content="Hand to "..handToUsername.." sent", Duration=2 })
    else WindUI:Notify({ Title="Command", Content="Failed: "..tostring(err), Duration=3 }) end
end })
local payAmount = ""
mainCommands:Input({ Title="Pay Amount", Desc="Enter amount to pay", Value="", Type="Input", Placeholder="e.g., 1000", Callback=function(input) payAmount=input end })
mainCommands:Button({ Title="Pay", Desc="Pays the specified amount", Callback=function()
    local amount = tonumber(payAmount)
    if not amount or amount<=0 then WindUI:Notify({ Title="Command", Content="Invalid amount", Duration=2 }); return end
    local ok,err = pcall(function() game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("ControllerRemote"):FireServer("/pay", amount) end)
    if ok then WindUI:Notify({ Title="Command", Content="Pay $"..amount.." sent", Duration=2 })
    else WindUI:Notify({ Title="Command", Content="Failed: "..tostring(err), Duration=3 }) end
end })
mainCommands:Button({ Title="Drop", Desc="Drops the currently held item", Callback=function()
    local ok,err = pcall(function() game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("ControllerRemote"):FireServer("/drop") end)
    if ok then WindUI:Notify({ Title="Command", Content="Drop command sent", Duration=2 })
    else WindUI:Notify({ Title="Command", Content="Failed: "..tostring(err), Duration=3 }) end
end })
local customCommand = ""
mainCommands:Input({ Title="Custom Command", Desc="Enter any command", Value="", Type="Input", Placeholder="e.g., /pay 500", Callback=function(input) customCommand=input end })
mainCommands:Button({ Title="Execute Command", Desc="Sends the custom command to ControllerRemote", Callback=function()
    if customCommand=="" then WindUI:Notify({ Title="Command", Content="Please enter a command", Duration=2 }); return end
    local ok,err = pcall(function() game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("ControllerRemote"):FireServer(customCommand) end)
    if ok then WindUI:Notify({ Title="Command", Content="Command sent", Duration=2 })
    else WindUI:Notify({ Title="Command", Content="Failed: "..tostring(err), Duration=3 }) end
end })

-- ========== MONEY FARM TAB ==========
local farmSection = tabs.moneyFarm:Section({ Title="Money Generator", Icon="dollar-sign", Opened=true })
do
    local farmEnabled, farmThread, farmToggle = false, nil, nil
    local MAX_BANK, BUY_COUNT, DEPOSIT_CHUNK = 5000000, 100, 500000
    local function isBankFull()
        local bankVal = LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Bank")
        return bankVal and bankVal:IsA("NumberValue") and bankVal.Value >= MAX_BANK
    end
    local function depositAll()
        if isBankFull() then return end
        local moneyVal = LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Money")
        if not moneyVal or not moneyVal:IsA("NumberValue") then return end
        local safety = 0
        while moneyVal.Value > 0 and safety < 100 do
            local amount = math.min(moneyVal.Value, DEPOSIT_CHUNK)
            if amount <= 0 then break end
            deposit(amount); task.wait(0.15); safety = safety + 1
        end
    end
    local function buyGun()
        pcall(function() game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Buy"):FireServer("MCXRattler", 13500) end)
    end
    local function equipGun()
        local char = LocalPlayer.Character; if not char then return false end
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            local tool = backpack:FindFirstChild("MCXRattler")
            if tool and tool:IsA("Tool") then char.Humanoid:EquipTool(tool); return true end
        end
        return false
    end
    local function sellGun()
        local part = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Misc") and workspace.Map.Misc:FindFirstChild("GunBuyer") and workspace.Map.Misc.GunBuyer:FindFirstChild("UpperTorso")
        if part then
            local prompt = part:FindFirstChild("Handler")
            if prompt and prompt:IsA("ProximityPrompt") then pcall(fireproximityprompt, prompt) end
        end
    end
    local function hasGunInBackpack()
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        return backpack and backpack:FindFirstChild("MCXRattler") ~= nil
    end
    local function isNearGunBuyer()
        local part = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Misc") and workspace.Map.Misc:FindFirstChild("GunBuyer") and workspace.Map.Misc.GunBuyer:FindFirstChild("UpperTorso")
        if not part then return false end
        local prompt = part:FindFirstChild("Handler")
        if not prompt or not prompt:IsA("ProximityPrompt") then return false end
        local char = LocalPlayer.Character; if not char then return false end
        local root = char:FindFirstChild("HumanoidRootPart"); if not root then return false end
        return (root.Position - part.Position).Magnitude <= prompt.MaxActivationDistance
    end
    local function stopFarm(silent)
        local wasRunning = farmThread ~= nil
        farmEnabled=false; farmThread=nil
        if farmToggle then farmToggle:Set(false) end
        if wasRunning and not silent then WindUI:Notify({ Title="Money Farm", Content="Farm stopped", Duration=2 }) end
    end
    local function farmLoop()
        while farmEnabled do
            while farmEnabled and hasGunInBackpack() do
                equipGun(); task.wait(0.2); sellGun(); task.wait(0.3)
            end
            depositAll(); task.wait(0.1)
            for i=1,BUY_COUNT do if not farmEnabled then break end; buyGun(); task.wait(0.1) end
            task.wait(0.2)
        end
    end
    local function startFarm()
        if farmThread then return end
        if isBankFull() and not hasGunInBackpack() then
            WindUI:Notify({ Title="Money Farm", Content="Bank full and no guns. Farm not needed.", Duration=3 })
            farmEnabled=false; if farmToggle then farmToggle:Set(false) end; return
        end
        if not isNearGunBuyer() then
            WindUI:Notify({ Title="Money Farm", Content="Move closer to the Gun Buyer first!", Duration=3 })
            farmEnabled=false; if farmToggle then farmToggle:Set(false) end; return
        end
        farmEnabled=true; farmThread=task.spawn(farmLoop)
        WindUI:Notify({ Title="Money Farm", Content="Farm started – buying "..BUY_COUNT.." MCXRattlers/cycle", Duration=2 })
    end

    farmSection:Paragraph({ Title="Money Generator", Desc="Stand near the Gun Buyer before enabling. Auto buys MCXRattlers and sells them." })
    farmToggle = farmSection:Toggle({ Title="Start/Stop Generator", Desc="Toggle the Generator loop (must be near Gun Buyer)", Default=false, Callback=function(v)
        if v then startFarm() else stopFarm(true) end
    end })

    local gunSpawnSection = tabs.moneyFarm:Section({ Title="Auto Gun Spawn", Icon="zap", Opened=false })
    gunSpawnSection:Paragraph({ Title="Auto Gun Spawn", Desc="Continuously buys MCXRattler until toggled off." })
    local gunSpawnEnabled, gunSpawnThread = false, nil
    gunSpawnSection:Toggle({ Title="Spawn MCXRattler", Desc="Continuously buy MCXRattler", Default=false, Callback=function(v)
        gunSpawnEnabled=v
        if v then
            if not gunSpawnThread then
                gunSpawnThread = task.spawn(function()
                    while gunSpawnEnabled do buyGun(); task.wait(0.15) end
                    gunSpawnThread=nil
                end)
            end
            WindUI:Notify({ Title="Gun Spawn", Content="Spawning MCXRattlers...", Duration=2 })
        else WindUI:Notify({ Title="Gun Spawn", Content="Stopped", Duration=2 }) end
    end })
end

-- ========== TELEPORTS TAB ==========
local teleportMainSection = tabs.teleports:Section({ Title="Teleport", Icon="map-pin", Opened=true })
teleportMainSection:Paragraph({ Title="Teleport", Desc="A car is required for teleportation. Mount your car to use these functions." })

-- Spawn Scooter
local spawnScooterSection = tabs.teleports:Section({ Title="Spawn Scooter", Icon="bike", Opened=false })
do
    spawnScooterSection:Paragraph({ Title="Spawn Scooter", Desc="Withdraws $250 (if needed) and spawns a scooter at your location." })
    local spawnInProgress = false
    local spamConnection  = nil
    local function obtainScooter()
        if spawnInProgress then WindUI:Notify({ Title="Scooter", Content="Already spawning, please wait.", Duration=2 }); return end
        spawnInProgress = true
        local character = LocalPlayer.Character
        if not character or not character.PrimaryPart then
            WindUI:Notify({ Title="Scooter", Content="Character not found", Duration=2 }); spawnInProgress=false; return
        end
        local originalPos = character.PrimaryPart.Position
        local myCar = getMyCar()
        if myCar and isScooter(myCar) then
            teleportModel(myCar, originalPos)
            WindUI:Notify({ Title="Scooter", Content="Your existing scooter has been brought to you.", Duration=2 }); spawnInProgress=false; return
        end
        if not withdraw(250) then WindUI:Notify({ Title="Scooter", Content="Failed to withdraw $250, aborting.", Duration=3 }); spawnInProgress=false; return end
        local spawnerPart, prompt, err = findSpawnScooter()
        if not spawnerPart then WindUI:Notify({ Title="Scooter", Content=err or "SpawnScooter not found", Duration=3 }); spawnInProgress=false; return end
        WindUI:Notify({ Title="Scooter", Content="Spawning scooter...", Duration=1 })
        local startTime = os.clock(); local scooterSpawned,newScooter,lastPromptTime = false,nil,0
        spamConnection = RunService.Heartbeat:Connect(function()
            if os.clock()-startTime > 10 then
                if spamConnection then spamConnection:Disconnect() end
                WindUI:Notify({ Title="Scooter", Content="Timeout – no scooter spawned.", Duration=3 }); spawnInProgress=false; return
            end
            if character and character.PrimaryPart then
                character:SetPrimaryPartCFrame(CFrame.new(spawnerPart.Position + Vector3.new(0,2,0)))
            end
            if os.clock()-lastPromptTime >= 0.3 then pcall(fireproximityprompt, prompt); lastPromptTime=os.clock() end
            myCar = getMyCar()
            if myCar and isScooter(myCar) then scooterSpawned=true; newScooter=myCar end
            if scooterSpawned and newScooter then
                if spamConnection then spamConnection:Disconnect() end
                task.spawn(function()
                    task.wait(1); teleportModel(newScooter, originalPos)
                    WindUI:Notify({ Title="Scooter", Content="Scooter teleported to you.", Duration=2 }); spawnInProgress=false
                end)
            end
        end)
    end
    spawnScooterSection:Button({ Title="Spawn Scooter & Bring to Me", Desc="Spawns or brings your existing scooter to you.", Callback=obtainScooter })
end

-- Car Spawner
local carSpawnerSection = tabs.teleports:Section({ Title="Car Spawner", Icon="car", Opened=false })
do
    carSpawnerSection:Paragraph({ Title="Car Spawner", Desc="Spawn any car from the dealership and mount it." })
    local carNames = {}
    local carsFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Misc") and game:GetService("ReplicatedStorage").Misc:FindFirstChild("Cars")
    if carsFolder then
        for _, car in ipairs(carsFolder:GetChildren()) do if car:IsA("Model") then table.insert(carNames, car.Name) end end
    end
    table.sort(carNames)
    local selectedCarName = carNames[1] or ""
    local carDropdown = carSpawnerSection:Dropdown({ Title="Select Car", Values=carNames, Multi=false, Default=selectedCarName, Callback=function(selected) if selected then selectedCarName=selected end end })
    local function refreshCarDropdown()
        local newNames = {}
        if carsFolder then for _, car in ipairs(carsFolder:GetChildren()) do if car:IsA("Model") then table.insert(newNames, car.Name) end end end
        table.sort(newNames); carDropdown:Refresh(newNames)
        if table.find(newNames, selectedCarName) then carDropdown:Select(selectedCarName)
        else selectedCarName=newNames[1] or ""; carDropdown:Select(selectedCarName) end
    end
    local function mountCar(car)
        local character = LocalPlayer.Character; if not character then return false end
        local driveSeat, start = nil, os.clock()
        while os.clock()-start < 5 do driveSeat=car:FindFirstChild("DriveSeat"); if driveSeat then break end; task.wait(0.1) end
        if not driveSeat then WindUI:Notify({ Title="Car Spawner", Content="DriveSeat not found", Duration=2 }); return false end
        local prompt = driveSeat:FindFirstChild("Interact")
        if not prompt or not prompt:IsA("ProximityPrompt") then
            prompt = car:FindFirstChildWhichIsA("ProximityPrompt", true)
            if not prompt then WindUI:Notify({ Title="Car Spawner", Content="No proximity prompt found", Duration=2 }); return false end
        end
        local mountStart, mounted, connection = os.clock(), false, nil
        connection = RunService.Heartbeat:Connect(function()
            if os.clock()-mountStart > 15 or not car or not car.Parent or not character or not character.Parent then connection:Disconnect(); return end
            if character and character.PrimaryPart then character:SetPrimaryPartCFrame(CFrame.new(driveSeat.Position+Vector3.new(0,2,0))) end
            pcall(fireproximityprompt, prompt)
            if character and character:GetAttribute("Bypass")==true then mounted=true; connection:Disconnect() end
        end)
        while not mounted and os.clock()-mountStart < 15 do task.wait() end
        if mounted then WindUI:Notify({ Title="Car Spawner", Content="Mounted successfully", Duration=2 }); return true
        else WindUI:Notify({ Title="Car Spawner", Content="Failed to mount (timeout)", Duration=2 }); return false end
    end
    local carSpawnerGroup = carSpawnerSection:Group({})
    carSpawnerGroup:Button({ Title="Spawn & Mount Car", Icon="", Justify="Center", Callback=function()
        if selectedCarName=="" then WindUI:Notify({ Title="Car Spawner", Content="No car selected", Duration=2 }); return end
        local myCarName = LocalPlayer.Name.."'s Car"
        local vehiclesFolder = workspace:FindFirstChild("Vehicles")
        local myCar = vehiclesFolder and vehiclesFolder:FindFirstChild(myCarName)
        if myCar and (myCar:GetAttribute("CarType")==selectedCarName) then
            WindUI:Notify({ Title="Car Spawner", Content="You own this car. Mounting...", Duration=1 }); mountCar(myCar); return
        end
        local carHandler = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CarHandler")
        if not carHandler then WindUI:Notify({ Title="Car Spawner", Content="CarHandler remote not found", Duration=3 }); return end
        local ok,err = pcall(function() carHandler:FireServer("Spawn", selectedCarName) end)
        if not ok then WindUI:Notify({ Title="Car Spawner", Content="Failed: "..tostring(err), Duration=3 }); return end
        WindUI:Notify({ Title="Car Spawner", Content="Spawn request sent", Duration=1 })
        task.wait(0.5)
        local newCar, spawnStart = nil, os.clock()
        while os.clock()-spawnStart < 15 do
            vehiclesFolder = workspace:FindFirstChild("Vehicles")
            if vehiclesFolder then for _, car in ipairs(vehiclesFolder:GetChildren()) do if car:IsA("Model") and car.Name==myCarName then newCar=car; break end end end
            if newCar then break end; task.wait(0.2)
        end
        if not newCar then WindUI:Notify({ Title="Car Spawner", Content="Car did not appear", Duration=3 }); return end
        local carType, typeStart = nil, os.clock()
        while os.clock()-typeStart < 5 do carType=newCar:GetAttribute("CarType"); if carType and carType~="" then break end; task.wait(0.1) end
        if not carType then WindUI:Notify({ Title="Car Spawner", Content="CarType never appeared. Aborting.", Duration=3 }); return end
        if carType ~= selectedCarName then WindUI:Notify({ Title="Car Spawner", Content="Wrong car type spawned. Aborting.", Duration=3 }); return end
        mountCar(newCar)
    end })
    carSpawnerGroup:Space()
    carSpawnerGroup:Button({ Title="Refresh Car List", Icon="", Justify="Center", Callback=refreshCarDropdown })
end

-- Other Player Car
local otherCarSection = tabs.teleports:Section({ Title="Other Player Car", Icon="lock-open", Opened=false })
do
    otherCarSection:Paragraph({ Title="Other Player Car", Desc="Unlock and teleport other players' cars. ProPad Required." })
    local vehicleNames = {}
    local vehiclesFolder = workspace:FindFirstChild("Vehicles")
    if vehiclesFolder then
        for _, vehicle in ipairs(vehiclesFolder:GetChildren()) do if vehicle:IsA("Model") then table.insert(vehicleNames, vehicle.Name) end end
    end
    table.sort(vehicleNames)
    local selectedVehicleName = vehicleNames[1] or ""
    local vehicleDropdown = otherCarSection:Dropdown({ Title="Select Vehicle", Values=vehicleNames, Multi=false, Default=selectedVehicleName, Callback=function(selected) if selected then selectedVehicleName=selected end end })
    local function refreshVehicleDropdown()
        local newNames = {}
        if vehiclesFolder then for _, v in ipairs(vehiclesFolder:GetChildren()) do if v:IsA("Model") then table.insert(newNames, v.Name) end end end
        table.sort(newNames); vehicleDropdown:Refresh(newNames)
        if table.find(newNames, selectedVehicleName) then vehicleDropdown:Select(selectedVehicleName)
        else selectedVehicleName=newNames[1] or ""; vehicleDropdown:Select(selectedVehicleName) end
    end
    local CHOP_POS = Vector3.new(1091.258, 70.044, 593.640)
    local otherCarGroup = otherCarSection:Group({})
    otherCarGroup:Button({ Title="Unlock Car", Icon="", Justify="Center", Callback=function()
        if selectedVehicleName=="" or not vehiclesFolder then WindUI:Notify({ Title="Other Car", Content="No vehicle selected", Duration=2 }); return end
        local car = vehiclesFolder:FindFirstChild(selectedVehicleName)
        if not car then WindUI:Notify({ Title="Other Car", Content="Vehicle not found", Duration=2 }); return end
        local proPad = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("ProPad")
        if not proPad then WindUI:Notify({ Title="Other Car", Content="ProPad remote not found", Duration=3 }); return end
        local ok,err = pcall(function() proPad:FireServer(car, true) end)
        if ok then WindUI:Notify({ Title="Other Car", Content="Unlock command sent", Duration=2 })
        else WindUI:Notify({ Title="Other Car", Content="Failed: "..tostring(err), Duration=3 }) end
    end })
    otherCarGroup:Space()
    otherCarGroup:Button({ Title="TP Car to CHOP", Icon="", Justify="Center", Callback=function()
        if selectedVehicleName=="" or not vehiclesFolder then WindUI:Notify({ Title="Other Car", Content="No vehicle selected", Duration=2 }); return end
        local car = vehiclesFolder:FindFirstChild(selectedVehicleName)
        if not car then WindUI:Notify({ Title="Other Car", Content="Vehicle not found", Duration=2 }); return end
        if teleportModel(car, CHOP_POS) then WindUI:Notify({ Title="Other Car", Content="Car teleported to CHOP", Duration=2 })
        else WindUI:Notify({ Title="Other Car", Content="Failed to teleport", Duration=2 }) end
    end })
    otherCarSection:Button({ Title="Refresh Vehicle List", Desc="Update the vehicle dropdown", Callback=function()
        refreshVehicleDropdown(); WindUI:Notify({ Title="Other Car", Content="List refreshed", Duration=1 })
    end })
end

-- Misc Locations
local miscLocationsSection = tabs.teleports:Section({ Title="Misc Locations", Icon="map", Opened=false })
do
    miscLocationsSection:Paragraph({ Title="Misc Locations", Desc="Teleport your car to various spots." })
    local miscPositions = {
        {name="Vault",       pos=Vector3.new(408.293,-49.648,115.566)},
        {name="Bank",        pos=Vector3.new(362.829,53.207,115.149)},
        {name="Jewel",       pos=Vector3.new(4.110,52.361,-244.427)},
        {name="Museum",      pos=Vector3.new(1388.882,53.046,-198.584)},
        {name="Loot Buyer",  pos=Vector3.new(243.874,53.045,321.512)},
        {name="Mechanic",    pos=Vector3.new(769.284,51.956,-432.562)},
        {name="Gun Store 1", pos=Vector3.new(694.004,53.086,-375.488)},
        {name="Gun Store 2", pos=Vector3.new(32.760,70.870,535.621)},
        {name="Yacht",       pos=Vector3.new(946.106,80.254,-1826.634)},
        {name="Car Dealer",  pos=Vector3.new(564.553,52.135,33.709)},
        {name="Gun Buyer",   pos=Vector3.new(991.706,52.945,-105.558)},
        {name="Car Chop",    pos=Vector3.new(1091.258,70.044,593.640)},
        {name="Oilrig",      pos=Vector3.new(-297.059,80.673,-1686.010)},
        {name="Penthouse",   pos=Vector3.new(374.303,70.846,553.403)},
        {name="Farm",        pos=Vector3.new(1039.685,52.153,-490.516)},
        {name="Merchant",    pos=Vector3.new(838.927,53.045,-730.773)},
        {name="Mansion",     pos=Vector3.new(1363.331,55.637,166.560)},
        {name="Tattoo",      pos=Vector3.new(880.464,70.898,587.179)},
        {name="Kicks Shoes", pos=Vector3.new(-53.296,70.902,495.325)},
    }
    local i = 1
    while i <= #miscPositions do
        local group = miscLocationsSection:Group({})
        local left  = miscPositions[i]
        local right = miscPositions[i+1]
        group:Button({ Title=left.name, Icon="", Justify="Center", Callback=function() teleportMyCar(left.pos) end })
        if right then
            group:Space()
            group:Button({ Title=right.name, Icon="", Justify="Center", Callback=function() teleportMyCar(right.pos) end })
        end
        i = i + 2
    end
end

-- Airdrop Locations
local airdropSection = tabs.teleports:Section({ Title="Airdrop Spawn Teleports", Icon="gift", Opened=false })
do
    airdropSection:Paragraph({ Title="Airdrop Spawn Teleports", Desc="Teleport your car to airdrop spawn locations." })
    local airdropPositions = {
        {name="Court",           pos=Vector3.new(436.615,52.198,-704.622)},
        {name="The Ice",         pos=Vector3.new(219.124,52.047,189.219)},
        {name="Oilrig",          pos=Vector3.new(-297.059,80.673,-1686.010)},
        {name="Uphill",          pos=Vector3.new(878.373,70.719,582.083)},
        {name="Parking Station", pos=Vector3.new(-117.735,113.418,-57.690)},
        {name="Beach",           pos=Vector3.new(-2.868,39.601,-875.761)},
        {name="Pier",            pos=Vector3.new(811.070,50.853,-996.581)},
        {name="Warehouse",       pos=Vector3.new(-111.110,69.828,358.302)},
    }
    local i = 1
    while i <= #airdropPositions do
        local group = airdropSection:Group({})
        local left  = airdropPositions[i]
        local right = airdropPositions[i+1]
        group:Button({ Title=left.name, Icon="", Justify="Center", Callback=function() teleportMyCar(left.pos) end })
        group:Space()
        if right then
            group:Button({ Title=right.name, Icon="", Justify="Center", Callback=function() teleportMyCar(right.pos) end })
        end
        i = i + 2
    end
end

-- Saved Positions
local savedPos = { dropdown=nil, currentName="", newName="" }
if hasFileSupport then
    local positionsFolder = "DubuHub/Streetlife/positions"
    local function getSavedPosNames()
        if not isfolder(positionsFolder) then makefolder(positionsFolder) end
        local files = listfiles(positionsFolder); local names = {}
        for _, file in ipairs(files) do local name = file:match("([^/\\]+)%.json$"); if name then table.insert(names, name) end end
        table.sort(names); return names
    end
    local function refreshSavedPosList()
        local names = getSavedPosNames()
        if savedPos.dropdown then
            savedPos.dropdown:Refresh(names)
            if table.find(names, savedPos.currentName) then savedPos.dropdown:Select(savedPos.currentName)
            else savedPos.dropdown:Select(nil) end
        end
    end
    local function saveCurrentPosition(name)
        local pos = getPlayerPosition()
        if not pos then WindUI:Notify({ Title="Save Position", Content="Character not found", Duration=2 }); return end
        if not isfolder(positionsFolder) then makefolder(positionsFolder) end
        writefile(positionsFolder.."/"..name..".json", HttpService:JSONEncode({name=name,x=pos.X,y=pos.Y,z=pos.Z}))
        refreshSavedPosList(); WindUI:Notify({ Title="Save Position", Content="'"..name.."' saved", Duration=2 })
    end
    local function loadPosition(name)
        local file = positionsFolder.."/"..name..".json"
        if not isfile(file) then WindUI:Notify({ Title="Load Position", Content="File not found", Duration=2 }); return end
        local data = HttpService:JSONDecode(readfile(file))
        teleportMyCar(Vector3.new(data.x, data.y, data.z))
    end
    local function deletePosition(name)
        local file = positionsFolder.."/"..name..".json"
        if isfile(file) then delfile(file); refreshSavedPosList(); WindUI:Notify({ Title="Delete Position", Content="'"..name.."' deleted", Duration=2 })
        else WindUI:Notify({ Title="Delete Position", Content="File not found", Duration=2 }) end
    end
    local savedPosSection = tabs.teleports:Section({ Title="Saved Positions (Player)", Icon="bookmark", Opened=false })
    savedPosSection:Paragraph({ Title="Saved Positions", Desc="Save your current location, then teleport your car there." })
    savedPos.dropdown = savedPosSection:Dropdown({ Title="Select Saved Position", Values={}, Multi=false, Default=nil, Callback=function(selected) if selected then savedPos.currentName=selected end end })
    savedPosSection:Input({ Title="New Position Name", Value="", Type="Input", Placeholder="e.g., myGarage", Callback=function(input) savedPos.newName=input end })
    local savedPosGroup1 = savedPosSection:Group({})
    savedPosGroup1:Button({ Title="Save Position", Icon="", Justify="Center", Callback=function()
        if savedPos.newName and savedPos.newName~="" then saveCurrentPosition(savedPos.newName)
        else WindUI:Notify({ Title="Save Position", Content="Please enter a name", Duration=2 }) end
    end })
    savedPosGroup1:Space()
    savedPosGroup1:Button({ Title="Load Position", Icon="", Justify="Center", Callback=function()
        if savedPos.currentName and savedPos.currentName~="" then loadPosition(savedPos.currentName)
        else WindUI:Notify({ Title="Load Position", Content="No position selected", Duration=2 }) end
    end })
    local savedPosGroup2 = savedPosSection:Group({})
    savedPosGroup2:Button({ Title="Delete Selected", Icon="", Justify="Center", Callback=function()
        if savedPos.currentName and savedPos.currentName~="" then deletePosition(savedPos.currentName); savedPos.currentName=""
        else WindUI:Notify({ Title="Delete Position", Content="No position selected", Duration=2 }) end
    end })
    savedPosGroup2:Space()
    savedPosGroup2:Button({ Title="Refresh List", Icon="", Justify="Center", Callback=function()
        refreshSavedPosList(); WindUI:Notify({ Title="Saved Positions", Content="List refreshed", Duration=1 })
    end })
    task.spawn(refreshSavedPosList)
else
    local unavailSection = tabs.teleports:Section({ Title="Saving Unavailable", Icon="x", Opened=true })
    unavailSection:Paragraph({ Title="Saving Unavailable", Desc="Your executor does not support file functions." })
end

-- Copy & Paste Position
local copyPasteSection = tabs.teleports:Section({ Title="Copy & Paste Position", Icon="clipboard", Opened=false })
do
    copyPasteSection:Paragraph({ Title="Copy & Paste Position", Desc="Copy your position or teleport your car to entered coordinates." })
    local pastedText = ""
    local copyGroup = copyPasteSection:Group({})
    copyGroup:Button({ Title="Copy My Position", Icon="", Justify="Center", Callback=function()
        local pos = getPlayerPosition()
        if pos then
            local posString = string.format("%.3f, %.3f, %.3f", pos.X, pos.Y, pos.Z)
            local ok = pcall(setclipboard, posString)
            if ok then WindUI:Notify({ Title="Copied", Content=posString, Duration=3 })
            else WindUI:Notify({ Title="Copy Failed", Content="setclipboard not supported", Duration=3 }) end
        else WindUI:Notify({ Title="Error", Content="Character not found", Duration=2 }) end
    end })
    copyPasteSection:Input({ Title="Pasted Coordinates", Desc="Enter X, Y, Z (e.g., 100, 50, -200)", Value="", Type="Input", Placeholder="e.g., 100, 50, -200", Callback=function(input) pastedText=input end })
    copyPasteSection:Button({ Title="Teleport Car to Pasted Position", Desc="Move your car to the entered coordinates", Callback=function()
        if pastedText=="" then WindUI:Notify({ Title="Error", Content="No coordinates entered", Duration=2 }); return end
        local numbers = {}
        for num in pastedText:gmatch("[-]?[%d.]+") do table.insert(numbers, tonumber(num)) end
        if #numbers >= 3 then teleportMyCar(Vector3.new(numbers[1], numbers[2], numbers[3]))
        else WindUI:Notify({ Title="Error", Content="Need X Y Z numbers", Duration=2 }) end
    end })
end

-- ========== HOUSE ROB TAB ==========
local houseRobMainSection = tabs.houseRob:Section({ Title="Unlock & Teleport", Icon="house", Opened=true })
do
    houseRobMainSection:Paragraph({ Title="Unlock & Teleport", Desc="Unlock apartment doors and teleport your car there in one click." })
    local houseRobTeleportEnabled = true
    houseRobMainSection:Toggle({ Title="Teleport After Unlock", Desc="If enabled, car will also be teleported to the apartment.", Default=true, Callback=function(v) houseRobTeleportEnabled=v end })
    houseRobMainSection:Divider()

    local houseRobData = {
        {name="First",  pos=Vector3.new(100.068,51.967,-169.557), short="1st"},
        {name="Second", pos=Vector3.new(281.713,52.132,-476.070), short="2nd"},
        {name="Third",  pos=Vector3.new(888.956,52.153,-793.251), short="3rd"},
        {name="Fourth", pos=Vector3.new(-49.480,70.049,544.030), short="4th"},
        {name="Fifth",  pos=Vector3.new(199.583,69.908,565.880), short="5th"},
    }

    local i = 1
    while i <= #houseRobData do
        local group = houseRobMainSection:Group({})
        local left  = houseRobData[i]
        local right = houseRobData[i+1]
        group:Button({ Title="Unlock "..left.short, Icon="", Justify="Center", Callback=function()
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("HouseRobbery")
            if remote then
                local apartment = workspace:FindFirstChild("RobbableApartments") and workspace.RobbableApartments:FindFirstChild(left.name)
                if apartment then
                    local ok,err = pcall(function() remote:FireServer("LOCKPICK", apartment) end)
                    if ok then WindUI:Notify({ Title="House Rob", Content="Unlock sent for "..left.name, Duration=1.5 })
                    else WindUI:Notify({ Title="House Rob", Content="Unlock failed: "..tostring(err), Duration=2 }) end
                else WindUI:Notify({ Title="House Rob", Content="Apartment not found", Duration=2 }) end
            else WindUI:Notify({ Title="House Rob", Content="HouseRobbery remote not found – only teleporting", Duration=2 }) end
            if houseRobTeleportEnabled then teleportMyCar(left.pos) end
        end })
        if right then
            group:Space()
            group:Button({ Title="Unlock "..right.short, Icon="", Justify="Center", Callback=function()
                local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("HouseRobbery")
                if remote then
                    local apartment = workspace:FindFirstChild("RobbableApartments") and workspace.RobbableApartments:FindFirstChild(right.name)
                    if apartment then
                        local ok,err = pcall(function() remote:FireServer("LOCKPICK", apartment) end)
                        if ok then WindUI:Notify({ Title="House Rob", Content="Unlock sent for "..right.name, Duration=1.5 })
                        else WindUI:Notify({ Title="House Rob", Content="Unlock failed: "..tostring(err), Duration=2 }) end
                    else WindUI:Notify({ Title="House Rob", Content="Apartment not found", Duration=2 }) end
                else WindUI:Notify({ Title="House Rob", Content="HouseRobbery remote not found – only teleporting", Duration=2 }) end
                if houseRobTeleportEnabled then teleportMyCar(right.pos) end
            end })
        end
        i = i + 2
    end

    houseRobMainSection:Divider()
    houseRobMainSection:Paragraph({ Title="Warehouse", Desc="Teleport your car to the warehouse." })
    houseRobMainSection:Button({ Title="Teleport to Warehouse", Desc="Teleport car to warehouse", Callback=function()
        teleportMyCar(Vector3.new(-111.110,69.828,358.302))
    end })
end

-- ========== COMBAT TAB ==========
local aimlockSection = tabs.combat:Section({ Title="Aimlock", Icon="crosshair", Opened=true })
if isMobileUser then
    aimlockSection:Paragraph({ Title="Aimlock", Desc="Use the button at the bottom of your screen to lock onto enemies." })
    uiRefs.AimlockToggle = aimlockSection:Toggle({ Title="Aimlock", Desc="Master switch", Flag="Aimlock", Default=false, Callback=function(v) aimlock.enabled=v; updateAimlockVisuals() end })
    uiRefs.AimlockColorpicker = aimlockSection:Colorpicker({ Title="Aimlock Color", Flag="AimlockColor", Default=aimlock.color, Transparency=0, Callback=function(c) aimlock.color=c or Color3.new(1,1,1); updateAimlockVisuals() end })
    uiRefs.FOVSlider = aimlockSection:Slider({
        Title="FOV",
        Desc="Field of view radius (pixels)",
        Flag="AimlockFOV",
        Step=1,
        Value={Min=60,Max=1000,Default=aimlock.fov},
        Callback=function(v)
            aimlock.fov = v
            FOVCircle.Radius = v / 2
            if isAimAssistReady and aimAssistInstance then
                local function pixelToDegrees(pixels)
                    local screenSize = Camera.ViewportSize
                    if screenSize and screenSize.X > 0 then
                        local camFovRad = math.rad(Camera.FieldOfView)
                        local halfScreen = screenSize.X / 2
                        local angleRad = math.atan2(pixels / 2, halfScreen / math.tan(camFovRad / 2))
                        return math.deg(angleRad) * 2
                    end
                    return math.clamp(pixels / 8, 1, 60)
                end
                aimAssistInstance:setFieldOfView(pixelToDegrees(v))
            end
        end
    })
    uiRefs.RangeSlider = aimlockSection:Slider({
        Title="Max Range",
        Flag="AimlockMaxRange",
        Step=10,
        Value={Min=100,Max=5000,Default=aimlock.maxRange},
        Callback=function(v)
            aimlock.maxRange = v
            if isAimAssistReady and aimAssistInstance then
                aimAssistInstance:setRange(v)
            end
        end
    })
    -- Mobile button toggle
    local mobileBtnSection = tabs.combat:Section({ Title="Mobile Button", Icon="smartphone", Opened=false })
    uiRefs.MobileAimlockToggle = mobileBtnSection:Toggle({ Title="Show Button", Default=true, Callback=function(v)
        if not mobileAimlockGui or not mobileAimlockGui.Parent then
            ensureMobileAimlockButton()
            task.wait(0.5)
        end
        if mobileAimlockGui then
            mobileAimlockGui.Enabled = v
        else
            WindUI:Notify({ Title="Mobile Button", Content="Failed to create button. Try again.", Duration = 3 })
        end
    end })
else
    aimlockSection:Paragraph({ Title="Aimlock", Desc="Hold the keybind to move your mouse toward the enemy's head." })
    uiRefs.AimlockToggle = aimlockSection:Toggle({
        Title="Aimlock",
        Desc="Master switch",
        Flag="Aimlock",
        Default=false,
        Callback=function(v)
            aimlock.enabled = v
            updateAimlockVisuals()
            if isAimAssistReady and aimAssistInstance then
                if v then
                    aimAssistInstance:enable()
                else
                    aimAssistInstance:disable()
                end
            end
        end
    })
    uiRefs.AimlockColorpicker = aimlockSection:Colorpicker({ Title="Aimlock Color", Desc="FOV circle and snap line", Flag="AimlockColor", Default=aimlock.color, Transparency=0, Callback=function(c) aimlock.color=c or Color3.new(1,1,1); updateAimlockVisuals() end })
    uiRefs.FOVSlider = aimlockSection:Slider({ Title="FOV", Desc="Field of view radius (pixels)", Flag="AimlockFOV", Step=1, Value={Min=60,Max=1000,Default=aimlock.fov}, Callback=function(v) aimlock.fov=v; FOVCircle.Radius=v/2 end })
    uiRefs.RangeSlider = aimlockSection:Slider({ Title="Max Range", Flag="AimlockMaxRange", Step=10, Value={Min=100,Max=5000,Default=aimlock.maxRange}, Callback=function(v) aimlock.maxRange=v end })
    uiRefs.SmoothSlider = aimlockSection:Slider({ Title="Smoothing", Desc="Mouse movement smoothness (0=instant)", Step=0.05, Value={Min=0.1,Max=1,Default=aimlock.smooth}, Callback=function(v) aimlock.smooth=v end })
    uiRefs.PredictionSlider = aimlockSection:Slider({ Title="Prediction", Desc="Lead moving targets (seconds)", Step=0.01, Value={Min=0,Max=0.5,Default=aimlock.prediction}, Callback=function(v) aimlock.prediction=v end })
    uiRefs.WallCheckToggle = aimlockSection:Toggle({ Title="Wall Check", Desc="Only lock onto visible enemies", Default=false, Callback=function(v) aimlock.wallCheck=v end })
    uiRefs.TargetPartDropdown = aimlockSection:Dropdown({ Title="Target Part", Values={"Head","Torso","HumanoidRootPart"}, Multi=false, Default="Head", Callback=function(selected) if selected then aimlock.targetPart=selected end end })
    uiRefs.TargetPartDropdown:Select("Head")
    uiRefs.AimlockKeybindButton = aimlockSection:Button({
        Title="Set Keybind", Desc="Current: "..getBindName(aimlock.bind).." (Click to change)",
        Callback=function()
            WindUI:Notify({ Title="Aimlock Keybind", Content="Press a key or click a mouse button...", Duration=3 })
            local conn
            conn = UserInputService.InputBegan:Connect(function(input, gp)
                if gp then return end
                if input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode~=Enum.KeyCode.Unknown then
                    aimlock.bind={Type="Keyboard",Key=input.KeyCode}
                    uiRefs.AimlockKeybindButton:SetDesc("Current: "..getBindName(aimlock.bind).." (Click to change)")
                    WindUI:Notify({ Title="Aimlock Keybind", Content="Set to "..getBindName(aimlock.bind), Duration=2 }); conn:Disconnect()
                elseif input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.MouseButton2 then
                    aimlock.bind={Type="Mouse",Button=input.UserInputType}
                    uiRefs.AimlockKeybindButton:SetDesc("Current: "..getBindName(aimlock.bind).." (Click to change)")
                    WindUI:Notify({ Title="Aimlock Keybind", Content="Set to "..getBindName(aimlock.bind), Duration=2 }); conn:Disconnect()
                end
            end)
            task.delay(5, function()
                if conn.Connected then conn:Disconnect(); WindUI:Notify({ Title="Aimlock Keybind", Content="Timeout – keybind not changed", Duration=2 }) end
            end)
        end
    })
end

-- Whitelist
local whitelistSection = tabs.combat:Section({ Title="Whitelist", Icon="user-check", Opened=false })
do
    -- Local refresh function that checks everything exists
    local function refreshWhitelistDropdown()
        if not uiRefs.WhitelistDropdown then
            warn("Whitelist dropdown not created yet.")
            return
        end
        local players = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(players, player.Name)
            end
        end
        table.sort(players)
        -- Use pcall to catch any errors
        local success, err = pcall(function()
            uiRefs.WhitelistDropdown:Refresh(players)
        end)
        if not success then
            warn("Failed to refresh whitelist dropdown: " .. tostring(err))
        end
        -- Update selected values
        local validSelected = {}
        for _, name in ipairs(aimlock.whitelistedPlayers) do
            if table.find(players, name) then
                table.insert(validSelected, name)
            end
        end
        aimlock.whitelistedPlayers = validSelected
        updateWhitelistSet(aimlock.whitelistedPlayers)
        pcall(function()
            uiRefs.WhitelistDropdown:Select(aimlock.whitelistedPlayers)
        end)
    end

    -- Create the dropdown
    uiRefs.WhitelistDropdown = whitelistSection:Dropdown({
        Title = "Ignore Players",
        Desc = "Select players to ignore (multi-select)",
        Flag = "WhitelistPlayers",
        Values = {},
        Multi = true,
        Default = {},
        Callback = function(selected)
            aimlock.whitelistedPlayers = selected or {}
            local newSet = {}
            for _, name in ipairs(aimlock.whitelistedPlayers) do
                newSet[name] = true
            end
            aimlock.whitelistedSet = newSet
            if EspSettings.enabled then refreshESP() end
        end
    })

    -- Refresh the list after a short delay (ensures players are loaded)
    task.spawn(function()
        task.wait(0.5)
        pcall(refreshWhitelistDropdown)
    end)

    -- Buttons
    whitelistSection:Button({
        Title = "Clear All Ignored",
        Callback = function()
            aimlock.whitelistedPlayers = {}
            aimlock.whitelistedSet = {}
            pcall(function() uiRefs.WhitelistDropdown:Select({}) end)
            if EspSettings.enabled then refreshESP() end
            WindUI:Notify({ Title = "Whitelist", Content = "All players removed from whitelist", Duration = 2 })
        end
    })

    whitelistSection:Button({
        Title = "Refresh Player List",
        Callback = function()
            pcall(refreshWhitelistDropdown)
            WindUI:Notify({ Title = "Combat", Content = "Player list refreshed!", Duration = 1.5 })
        end
    })
end

-- Gun Mods Section
local gunModsSection = tabs.combat:Section({ Title="Gun Mods", Icon="sword", Opened=false })
gunModsSection:Paragraph({ Title="Gun Mods", Desc="No recoil and fast reload for your weapons." })
uiRefs.NoRecoilToggle = gunModsSection:Toggle({ Title="No Recoil", Desc="Cancels weapon kick while shooting", Default=false, Callback=function(v) gunMods.NoRecoil=v end })
uiRefs.FastReloadToggle = gunModsSection:Toggle({ Title="Fast Reload", Desc="Speeds up reload animations", Default=false, Callback=function(v) gunMods.FastReload=v end })
uiRefs.ReloadSpeedSlider = gunModsSection:Slider({ Title="Reload Speed Multiplier", Desc="How fast the reload animation plays", Step=0.1, Value={Min=1,Max=10,Default=3}, Callback=function(v) gunMods.ReloadSpeed=v end })

-- Revert Spawn
local revertSpawnSection = tabs.combat:Section({ Title="Revert Spawn", Icon="zap", Opened=false })
do
    revertSpawnSection:Paragraph({ Title="Revert Spawn", Desc="Spawn a weapon variant using the RevertSpawn remote." })
    local revertSpawnItems = {
        {label="BlueTipSwitch",value="blue"},{label="BlueButton",value="blueb"},{label="ARPSwitch",value="arps"},
        {label="GreenButton",value="green"},{label="PurpleButtonDrum",value="purple"},{label="GalilAR",value="GalilAR"},
        {label="FN 5.7 Drum",value="FN 5.7 Drum"},{label="FRTMicroDraco",value="FRTMicroDraco"},
        {label="EasterDraco",value="easter"},{label="HeartARPDrum",value="heart"},{label="PumpkinButton",value="pumpkin"},
        {label="SparkARP",value="spark"},{label="StPatrickButton",value="stp"},{label="XMASGlockSwitch",value="xmasgl"},
        {label="XMASM4",value="xmasm"},{label="M1911S",value="m19"},{label="SkeletonBadger",value="skele"},
        {label="GlockSwitch",value="glocksw"},{label="Paintball Gun",value="paintball"},
        {label="Binary 300 BLACKOUT",value="binary 300"},{label="P90",value="p90"},
    }
    local revertSpawnLabels = {}
    for _, item in ipairs(revertSpawnItems) do table.insert(revertSpawnLabels, item.label) end
    local selectedRevertSpawnValue = revertSpawnItems[1].value
    uiRefs.RevertSpawnDropdown = revertSpawnSection:Dropdown({ Title="Select Weapon", Values=revertSpawnLabels, Multi=false, Default=revertSpawnItems[1].label, Callback=function(selected)
        for _, item in ipairs(revertSpawnItems) do if item.label==selected then selectedRevertSpawnValue=item.value; break end end
    end })
    revertSpawnSection:Button({ Title="Spawn Weapon", Callback=function()
        local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("RevertSpawn")
        if remote then
            local ok,err = pcall(function() remote:FireServer(selectedRevertSpawnValue) end)
            if ok then WindUI:Notify({ Title="Revert Spawn", Content="Spawned: "..selectedRevertSpawnValue, Duration=2 })
            else WindUI:Notify({ Title="Revert Spawn", Content="Failed: "..tostring(err), Duration=3 }) end
        else WindUI:Notify({ Title="Revert Spawn", Content="RevertSpawn remote not found", Duration=3 }) end
    end })
end

-- ========== ESP TAB UI ==========
local espMainSection = tabs.esp:Section({ Title="ESP Settings", Icon="eye", Opened=true })
espMainSection:Paragraph({ Title="ESP Settings", Desc="Configure player ESP." })

-- Render connection will be created/destroyed when ESP toggled
local espRenderConnection = nil

uiRefs.ESPToggle = espMainSection:Toggle({ Title="ESP", Desc="Enable/disable all ESP", Flag="ESP", Default=false, Callback=function(v)
    esp.enabled = v
    if v then
        refreshESP()
        if not espRenderConnection then
            espRenderConnection = RunService.RenderStepped:Connect(function()
                if EspSettings.enabled then
                    pcall(updateESP)
                end
            end)
        end
    else
        for player in pairs(esp.objects) do removeESPForPlayer(player) end
        if espRenderConnection then
            espRenderConnection:Disconnect()
            espRenderConnection = nil
        end
    end
end })

local espGroup1 = espMainSection:Group({})
espGroup1:Colorpicker({ Title="ESP Color", Flag="ESPColor", Default=esp.color, Transparency=0, Callback=function(c) esp.color=c or Color3.fromRGB(220,20,60); if esp.enabled then refreshESP() end end })
espGroup1:Space()
espGroup1:Colorpicker({ Title="Whitelist ESP Color", Flag="WhitelistESPColor", Default=esp.whitelistColor, Transparency=0, Callback=function(c) esp.whitelistColor=c or Color3.fromRGB(0,0,255); if esp.enabled then refreshESP() end end })

espMainSection:Divider()

-- 2‑column layout for toggles
local row1 = espMainSection:Group({})
row1:Toggle({ Title="Box ESP", Flag="ESPBox", Default=false, Callback=function(v) esp.boxes=v end })
row1:Space()
row1:Toggle({ Title="Name ESP", Flag="ESPName", Default=false, Callback=function(v) esp.names=v end })

local row2 = espMainSection:Group({})
row2:Toggle({ Title="Health Bar", Flag="ESPHealth", Default=false, Callback=function(v) esp.health=v end })
row2:Space()
row2:Toggle({ Title="Distance", Flag="ESPDistance", Default=false, Callback=function(v) esp.distance=v end })

local row3 = espMainSection:Group({})
row3:Toggle({ Title="Skeleton", Flag="ESPSkeleton", Default=false, Callback=function(v) esp.skeleton=v end })
row3:Space()
row3:Toggle({ Title="Tracers", Flag="ESPTracers", Default=false, Callback=function(v) esp.tracers=v end })

-- Chams (fill character with color)
local row4 = espMainSection:Group({})
row4:Toggle({ Title="Chams", Desc="Fills entire character model with solid color", Flag="ESPChams", Default=false, Callback=function(v) esp.fill=v end })

espMainSection:Divider()
espMainSection:Slider({ Title="Max Distance", Flag="ESPMaxDistance", Step=10, Value={Min=100,Max=2000,Default=esp.maxDistance}, Callback=function(v) esp.maxDistance=v end })
espMainSection:Button({ Title="Refresh ESP Now", Callback=function() refreshESP(); WindUI:Notify({ Title="ESP", Content="Refreshed!", Duration=1 }) end })

-- ========== SHOP TAB ==========
-- Item Shop
local itemShopSection = tabs.shop:Section({ Title="Item Shop", Icon="shopping-cart", Opened=false })
do
    local dealerItems = {
        {name="MentosBag",price=300},{name="C4",price=2000},{name="Knife",price=500},{name="Bat",price=750},
        {name="DuffleBag",price=500},{name="LockPick",price=500},{name="Firework",price=500},
        {name="Dice",price=50},{name="MoneyGun",price=2500},
    }
    local dealerDropdownValues = {}
    for _, item in ipairs(dealerItems) do table.insert(dealerDropdownValues, string.format("%s ($%d)", item.name, item.price)) end
    local selectedDealerItem = dealerItems[1]
    itemShopSection:Dropdown({ Title="Select Item", Values=dealerDropdownValues, Multi=false, Default=dealerDropdownValues[1], Callback=function(selected)
        for _, item in ipairs(dealerItems) do if string.format("%s ($%d)",item.name,item.price)==selected then selectedDealerItem=item; break end end
    end })
    itemShopSection:Button({ Title="Buy Selected Item", Callback=function()
        if selectedDealerItem then
            local ok,err = pcall(function() game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Buy"):FireServer(selectedDealerItem.name, selectedDealerItem.price) end)
            if ok then WindUI:Notify({ Title="Item Shop", Content="Purchased "..selectedDealerItem.name, Duration=2 })
            else WindUI:Notify({ Title="Item Shop", Content="Purchase failed: "..tostring(err), Duration=3 }) end
        end
    end })
end

-- Weapon Shop
local weaponShopSection = tabs.shop:Section({ Title="Weapon Shop", Icon="sword", Opened=false })
do
    local weaponItems = {
        {name="Ruger",price=800},{name="Makarov",price=1000},{name="Glock17",price=1200},{name="Mac",price=3000},
        {name="Tec-9",price=3500},{name="UMP",price=4800},{name="Shotgun",price=5000},{name="Glock19X",price=5000},
        {name="AUG",price=5000},{name="Draco",price=5200},{name="GlockSwitch",price=5400},{name="ARPistol",price=5000},
        {name="HoneyBadger",price=5500},{name="AK-47",price=6500},{name="TSR-15",price=8000},{name="BinaryG17",price=7000},
        {name="AKS-74U",price=8500},{name="Military Vest",price=3000},
    }
    local weaponDropdownValues = {}
    for _, item in ipairs(weaponItems) do table.insert(weaponDropdownValues, string.format("%s ($%d)",item.name,item.price)) end
    local selectedWeapon = weaponItems[1]
    weaponShopSection:Dropdown({ Title="Select Weapon", Values=weaponDropdownValues, Multi=false, Default=weaponDropdownValues[1], Callback=function(selected)
        for _, item in ipairs(weaponItems) do if string.format("%s ($%d)",item.name,item.price)==selected then selectedWeapon=item; break end end
    end })
    weaponShopSection:Button({ Title="Buy Selected Weapon", Callback=function()
        if selectedWeapon then
            local ok,err = pcall(function() game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("GunBuy"):FireServer(selectedWeapon.name, selectedWeapon.price) end)
            if ok then WindUI:Notify({ Title="Weapon Shop", Content="Purchased "..selectedWeapon.name, Duration=2 })
            else WindUI:Notify({ Title="Weapon Shop", Content="Purchase failed: "..tostring(err), Duration=3 }) end
        end
    end })
end

-- Ammo Shop
local ammoShopSection = tabs.shop:Section({ Title="Ammo Shop", Icon="target", Opened=false })
do
    local ammoItems = {
        {name="Pistol Ammo",price=50},{name="Rifle Ammo",price=100},{name="SMG Ammo",price=100},{name="Shotgun Ammo",price=100},
    }
    local ammoDropdownValues = {}
    for _, item in ipairs(ammoItems) do table.insert(ammoDropdownValues, string.format("%s ($%d)",item.name,item.price)) end
    local selectedAmmo = ammoItems[1]
    ammoShopSection:Dropdown({ Title="Select Ammo", Values=ammoDropdownValues, Multi=false, Default=ammoDropdownValues[1], Callback=function(selected)
        for _, item in ipairs(ammoItems) do if string.format("%s ($%d)",item.name,item.price)==selected then selectedAmmo=item; break end end
    end })
    ammoShopSection:Button({ Title="Buy Selected Ammo", Callback=function()
        if selectedAmmo then
            local ok,err = pcall(function() game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("GunBuy"):FireServer(selectedAmmo.name, selectedAmmo.price) end)
            if ok then WindUI:Notify({ Title="Ammo Shop", Content="Purchased "..selectedAmmo.name, Duration=2 })
            else WindUI:Notify({ Title="Ammo Shop", Content="Purchase failed: "..tostring(err), Duration=3 }) end
        end
    end })
end

-- Mask Shop
local maskSection = tabs.shop:Section({ Title="Mask Shop", Icon="theater", Opened=false })
do
    local maskItems = {
        {name="ClownMask",price=75},{name="GhostFace",price=100},{name="JasonMask",price=100},
        {name="Balaclava",price=50},{name="BlueSki",price=75},{name="RedSki",price=75},
        {name="HackerMask",price=75},{name="Bandana",price=50},{name="SkiMask",price=50},
    }
    local maskDropdownValues = {}
    for _, item in ipairs(maskItems) do table.insert(maskDropdownValues, string.format("%s ($%d)",item.name,item.price)) end
    local selectedMask = maskItems[1]
    maskSection:Dropdown({ Title="Select Mask", Values=maskDropdownValues, Multi=false, Default=maskDropdownValues[1], Callback=function(selected)
        for _, item in ipairs(maskItems) do if string.format("%s ($%d)",item.name,item.price)==selected then selectedMask=item; break end end
    end })
    maskSection:Button({ Title="Buy Selected Mask", Callback=function()
        if selectedMask then
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Buy")
            if remote then
                local ok,err = pcall(function() remote:FireServer(selectedMask.name, selectedMask.price) end)
                if ok then WindUI:Notify({ Title="Mask Shop", Content="Purchased "..selectedMask.name, Duration=2 })
                else WindUI:Notify({ Title="Mask Shop", Content="Purchase failed: "..tostring(err), Duration=3 }) end
            end
        end
    end })
end

-- Flipsy's Armory
local flipsySection = tabs.shop:Section({ Title="Flipsy's Armory", Icon="star", Opened=false })
do
    flipsySection:Paragraph({ Title="Flipsy's Armory", Desc="No armory access needed. Buy even without money (empty wallet first)." })
    local flipsyItems = {
        {name="MCXRattler",price=13500},{name="Golden Draco",price=5000},{name="FlashLight",price=2500},
        {name="NewsCamera",price=5000},{name="TAR-21S",price=7500},{name="P226",price=3000},
        {name="Beretta93R",price=7000},{name="S&W500",price=5000},{name="Binoculars",price=1000},
        {name="Katana",price=1000},{name="MP7",price=7500},{name="Golden Deagle",price=5000},
        {name="Medkit",price=2000},{name="Skorpion",price=2000},{name="AA12",price=8500},
        {name="M12",price=6000},{name="APC9K",price=6500},{name="Heavy Ammo",price=50000},
    }
    local flipsyDropdownValues = {}
    for _, item in ipairs(flipsyItems) do table.insert(flipsyDropdownValues, string.format("%s ($%d)",item.name,item.price)) end
    local selectedFlipsyItem = flipsyItems[1]
    flipsySection:Dropdown({ Title="Select Armory Item", Values=flipsyDropdownValues, Multi=false, Default=flipsyDropdownValues[1], Callback=function(selected)
        for _, item in ipairs(flipsyItems) do if string.format("%s ($%d)",item.name,item.price)==selected then selectedFlipsyItem=item; break end end
    end })
    flipsySection:Button({ Title="Buy Selected Armory Item", Callback=function()
        if selectedFlipsyItem then
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Buy")
            if remote then
                local ok,err = pcall(function() remote:FireServer(selectedFlipsyItem.name, selectedFlipsyItem.price) end)
                if ok then WindUI:Notify({ Title="Flipsy's Armory", Content="Purchased "..selectedFlipsyItem.name, Duration=2 })
                else WindUI:Notify({ Title="Flipsy's Armory", Content="Purchase failed: "..tostring(err), Duration=3 }) end
            end
        end
    end })
end

-- Seeds & Supplies
local seedsSection = tabs.shop:Section({ Title="Seeds & Supplies", Icon="bean", Opened=false })
do
    local seedSupplyItems = {
        {label="Lemon ($6500)",type="seed",value="Lemon"},
        {label="SunFlower ($5200)",type="seed",value="SunFlower"},
        {label="Tomato ($1800)",type="seed",value="Tomato"},
        {label="Pumpkin ($1800)",type="seed",value="Pumpkin"},
        {label="Garden Soil ($500)",type="supply",value="Garden Soil",price=500},
        {label="Water Can ($250)",type="supply",value="Water Can",price=250},
    }
    local seedSupplyLabels = {}
    for _, item in ipairs(seedSupplyItems) do table.insert(seedSupplyLabels, item.label) end
    local selectedSeedSupply = seedSupplyItems[1]
    seedsSection:Dropdown({ Title="Select Seed / Supply", Values=seedSupplyLabels, Multi=false, Default=seedSupplyLabels[1], Callback=function(selected)
        for _, item in ipairs(seedSupplyItems) do if item.label==selected then selectedSeedSupply=item; break end end
    end })
    seedsSection:Button({ Title="Obtain Selected", Callback=function()
        if not selectedSeedSupply then return end
        if selectedSeedSupply.type=="seed" then
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Supplies")
            if remote then pcall(function() remote:FireServer(selectedSeedSupply.value) end); WindUI:Notify({ Title="Seeds", Content="Obtained: "..selectedSeedSupply.value, Duration=2 })
            else WindUI:Notify({ Title="Seeds", Content="Supplies remote not found", Duration=3 }) end
        else
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Buy")
            if remote then pcall(function() remote:FireServer(selectedSeedSupply.value, selectedSeedSupply.price) end); WindUI:Notify({ Title="Supplies", Content="Purchased: "..selectedSeedSupply.value, Duration=2 })
            else WindUI:Notify({ Title="Supplies", Content="Buy remote not found", Duration=3 }) end
        end
    end })
end

-- Food Shop
local foodShopSection = tabs.shop:Section({ Title="Food Shop", Icon="coffee", Opened=false })
do
    local foodItems = {
        {name="Burger",price=50},{name="Water",price=50},{name="Taco",price=50},
        {name="Pizza",price=50},{name="ProteinBar",price=100},{name="ProteinShake",price=100},
    }
    local foodDropdownValues = {}
    for _, item in ipairs(foodItems) do table.insert(foodDropdownValues, string.format("%s ($%d)",item.name,item.price)) end
    local selectedFoodItem = foodItems[1]
    foodShopSection:Dropdown({ Title="Select Food", Values=foodDropdownValues, Multi=false, Default=foodDropdownValues[1], Callback=function(selected)
        for _, item in ipairs(foodItems) do if string.format("%s ($%d)",item.name,item.price)==selected then selectedFoodItem=item; break end end
    end })
    foodShopSection:Button({ Title="Buy Selected Food", Callback=function()
        if selectedFoodItem then
            local ok,err = pcall(function() game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Buy"):FireServer(selectedFoodItem.name, selectedFoodItem.price) end)
            if ok then WindUI:Notify({ Title="Food Shop", Content="Purchased "..selectedFoodItem.name, Duration=2 })
            else WindUI:Notify({ Title="Food Shop", Content="Purchase failed: "..tostring(err), Duration=3 }) end
        end
    end })
end

-- ========== UI TAB ==========
local uiLauncherSection = tabs.ui:Section({ Title="Interface Launcher", Icon="shopping-bag", Opened=true })
do
    uiLauncherSection:Paragraph({ Title="Interface Launcher", Desc="Open various game UIs." })
    local uiObjects = {
        {name="Storage UI",path="StorageUI"},{name="Jewelry UI",path="JewelryUI"},
        {name="PDCameras UI",path="PDCamerasUI"},{name="BlackMarket UI",path="BlackMarketUI"},
        {name="Clothing UI",path="ClothingUI"},{name="Car Dealer UI",path="CarDealerUI"},
        {name="Drip UI",path="DripUI"},{name="Tattoo UI",path="TattooUI"},
        {name="Mask UI",path="MaskUI"},{name="Deli UI",path="DeliUI"},
        {name="Gloves UI",path="GlovesUI"},{name="Gym UI",path="GymUI"},
        {name="Computer UI",path="ComputerUI"},{name="Station UI",path="StationUI"},
        {name="Supplies UI",path="SuppliesUI"},
    }
    local function launchUI(obj)
        local misc = game:GetService("ReplicatedStorage"):FindFirstChild("Misc")
        if not misc then WindUI:Notify({ Title="UI", Content="Misc folder not found", Duration=3 }); return end
        local target = misc:FindFirstChild(obj.path)
        if not target then WindUI:Notify({ Title="UI", Content=obj.path.." not found", Duration=3 }); return end
        if target:IsA("RemoteEvent") then
            pcall(function() target:FireServer() end)
            WindUI:Notify({ Title="UI", Content=obj.name.." opened", Duration=2 })
        elseif target:IsA("ScreenGui") then
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                local clone = target:Clone(); clone.Parent = playerGui
                WindUI:Notify({ Title="UI", Content=obj.name.." opened", Duration=2 })
            end
        else WindUI:Notify({ Title="UI", Content=obj.name.." is a "..target.ClassName..", cannot open automatically", Duration=3 }) end
    end
    local i = 1
    while i <= #uiObjects do
        local group = uiLauncherSection:Group({})
        local left  = uiObjects[i]
        local right = uiObjects[i+1]
        group:Button({ Title="Open "..left.name, Icon="", Justify="Center", Callback=function() launchUI(left) end })
        group:Space()
        if right then
            group:Button({ Title="Open "..right.name, Icon="", Justify="Center", Callback=function() launchUI(right) end })
        end
        i = i + 2
    end
end

-- ========== CAR UTILS TAB ==========
local carUtilsMainSection = tabs.carUtils:Section({ Title="Car Mods", Icon="car", Opened=true })
carUtilsMainSection:Paragraph({ Title="Car Mods", Desc="Flight, speed boost, and noclip." })

-- Car Fly toggle
uiRefs.CarFlyToggle = carUtilsMainSection:Toggle({
    Title = "Car Fly",
    Desc = "Fly your car with WASD (PC) or throttle (mobile)",
    Flag = "CarFly",
    Default = false,
    Callback = function(v)
        carFlyEnabled = v
        if v then
            if isMobileUser then createMobileFlyButtons() end
            WindUI:Notify({ Title="Car Fly", Content="Enabled" .. (isMobileUser and " – use ▲/▼ for height" or ""), Duration=2 })
        else
            destroyMobileFlyButtons()
            WindUI:Notify({ Title="Car Fly", Content="Disabled", Duration=2 })
        end
    end
})
uiRefs.CarFlyKeyButton = carUtilsMainSection:Keybind({
    Title = "Fly Keybind",
    Default = Enum.KeyCode.F,
    Callback = function(key)
        carMods.FlyKey = key
        WindUI:Notify({ Title="Car Fly", Content="Keybind set to "..key.Name, Duration=2 })
    end
})
uiRefs.FlySpeedSlider = carUtilsMainSection:Slider({
    Title = "Fly / Boost Speed",
    Flag = "CarFlySpeed",
    Step = 10,
    Value = { Min = 50, Max = 500, Default = carMods.SpeedAmount },
    Callback = function(v) carMods.SpeedAmount = v end
})

carUtilsMainSection:Divider()
uiRefs.GroundSpeedToggle = carUtilsMainSection:Toggle({
    Title = "Ground Speed Boost",
    Desc = "Increases car speed when on ground",
    Flag = "CarSpeedBoost",
    Default = false,
    Callback = function(v) carMods.SpeedBoost = v end
})

carUtilsMainSection:Divider()
uiRefs.NoclipToggle = carUtilsMainSection:Toggle({
    Title = "No-Clip (Car + Player)",
    Desc = "Disable collisions for you and your car",
    Default = false,
    Callback = function(v)
        carNoclipEnabled = v
        setNoclip(v)
        WindUI:Notify({ Title="No-Clip", Content=v and "Enabled" or "Disabled", Duration=2 })
    end
})

-- ========== CRYPTO TAB ==========
local cryptoMainSection = tabs.crypto:Section({ Title="Crypto Market", Icon="bitcoin", Opened=true })
do
    cryptoMainSection:Paragraph({ Title="Crypto Market", Desc="Current values and auto-buy/sell settings." })

    local function getCryptoValue(name)
        local folder = game:GetService("ReplicatedStorage"):FindFirstChild("Misc")
        if folder then
            local phone = folder:FindFirstChild("Phone")
            if phone then
                local crypto = phone:FindFirstChild(name)
                if crypto and crypto:IsA("NumberValue") then return crypto.Value end
            end
        end
        return nil
    end

    local cryptoAutoBuy   = {Bitcoin=false,DOGE=false,ETH=false}
    local cryptoAutoSell  = {Bitcoin=false,DOGE=false,ETH=false}
    local cryptoBuyThreshold  = {Bitcoin=300,DOGE=300,ETH=300}
    local cryptoSellThreshold = {Bitcoin=9000,DOGE=9000,ETH=9000}
    local lastActionTime  = {Bitcoin=0,DOGE=0,ETH=0}
    local COOLDOWN = 1
    local cryptoNames = {"Bitcoin","DOGE","ETH"}
    local remoteNameMap = {Bitcoin="Crypto",DOGE="DOGE",ETH="ETH"}
    local bitcoinPara, dogePara, ethPara, timerPara = nil, nil, nil, nil

    for _, cryptoName in ipairs(cryptoNames) do
        local cryptoSection = tabs.crypto:Section({ Title=cryptoName, Icon="bitcoin", Opened=false })
        local para = cryptoSection:Paragraph({ Title=cryptoName, Desc="Current value: Loading..." })
        if cryptoName=="Bitcoin" then bitcoinPara=para elseif cryptoName=="DOGE" then dogePara=para elseif cryptoName=="ETH" then ethPara=para end
        uiRefs["AutoBuy_"..cryptoName] = cryptoSection:Toggle({ Title="Auto Buy "..cryptoName, Flag="CryptoAutoBuy_"..cryptoName, Default=false, Callback=function(v) cryptoAutoBuy[cryptoName]=v end })
        uiRefs["BuyThreshold_"..cryptoName] = cryptoSection:Slider({ Title=cryptoName.." Buy Threshold", Flag="CryptoBuyThreshold_"..cryptoName, Step=1, Value={Min=1,Max=10000,Default=cryptoBuyThreshold[cryptoName]}, Callback=function(v) cryptoBuyThreshold[cryptoName]=v end })
        uiRefs["AutoSell_"..cryptoName] = cryptoSection:Toggle({ Title="Auto Sell "..cryptoName, Flag="CryptoAutoSell_"..cryptoName, Default=false, Callback=function(v) cryptoAutoSell[cryptoName]=v end })
        uiRefs["SellThreshold_"..cryptoName] = cryptoSection:Slider({ Title=cryptoName.." Sell Threshold", Flag="CryptoSellThreshold_"..cryptoName, Step=1, Value={Min=1,Max=10000,Default=cryptoSellThreshold[cryptoName]}, Callback=function(v) cryptoSellThreshold[cryptoName]=v end })
        cryptoSection:Button({ Title="Buy "..cryptoName.." Now", Callback=function()
            local current = getCryptoValue(remoteNameMap[cryptoName])
            if current then
                pcall(function() game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Phone"):FireServer(remoteNameMap[cryptoName],"Purchase",current) end)
                WindUI:Notify({ Title="Crypto", Content=string.format("Bought %s at $%d", cryptoName, current), Duration=2 })
            end
        end })
        cryptoSection:Button({ Title="Sell "..cryptoName.." Now", Callback=function()
            local current = getCryptoValue(remoteNameMap[cryptoName])
            if current then
                pcall(function() game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Phone"):FireServer(remoteNameMap[cryptoName],"Sell",current) end)
                WindUI:Notify({ Title="Crypto", Content=string.format("Sold %s at $%d", cryptoName, current), Duration=2 })
            end
        end })
    end

    local timerSection = tabs.crypto:Section({ Title="CryptoTimer", Icon="clock", Opened=false })
    timerPara = timerSection:Paragraph({ Title="CryptoTimer", Desc="Current value: Loading..." })

    task.spawn(function()
        while true do
            task.wait(0.5)
            local now = os.clock()
            for _, cryptoName in ipairs(cryptoNames) do
                local remoteName = remoteNameMap[cryptoName]
                local current = getCryptoValue(remoteName)
                if current then
                    if cryptoName=="Bitcoin" and bitcoinPara then bitcoinPara:SetDesc(string.format("Current value: $%d", current))
                    elseif cryptoName=="DOGE" and dogePara then dogePara:SetDesc(string.format("Current value: $%d", current))
                    elseif cryptoName=="ETH" and ethPara then ethPara:SetDesc(string.format("Current value: $%d", current)) end
                    if cryptoAutoBuy[cryptoName] and current<=cryptoBuyThreshold[cryptoName] and now-lastActionTime[cryptoName]>=COOLDOWN then
                        pcall(function() game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Phone"):FireServer(remoteName,"Purchase",current) end)
                        lastActionTime[cryptoName]=now
                    end
                    if cryptoAutoSell[cryptoName] and current>=cryptoSellThreshold[cryptoName] and now-lastActionTime[cryptoName]>=COOLDOWN then
                        pcall(function() game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Phone"):FireServer(remoteName,"Sell",current) end)
                        lastActionTime[cryptoName]=now
                    end
                end
            end
            local timerValue = getCryptoValue("CryptoTimer")
            if timerValue and timerPara then timerPara:SetDesc(string.format("Current value: %d", timerValue)) end
        end
    end)
end

-- ========== MISC TAB ==========
local miscMainSection = tabs.misc:Section({ Title="Graphics", Icon="settings", Opened=true })
do
    miscMainSection:Paragraph({ Title="Graphics", Desc="Visual enhancements and utilities." })
    uiRefs.RealisticGraphicsToggle = miscMainSection:Toggle({ Title="Realistic Graphics", Desc="Enables motion blur effect", Flag="RealisticGraphics", Default=false, Callback=toggleRealisticGraphics })
    miscMainSection:Button({ Title="Full Bright (No Shadows)", Desc="Set lighting to full brightness", Callback=fullBright })
    miscMainSection:Divider()
    miscMainSection:Button({ Title="Load Infinite Yield", Desc="Loads Infinite Yield admin commands", Callback=loadInfiniteYield })
    miscMainSection:Divider()
    miscMainSection:Paragraph({ Title="Team Changer", Desc="Switch your team instantly." })
    miscMainSection:Button({ Title="Switch to PD (VISUAL ONLY)", Callback=function()
        local teams = game:GetService("Teams")
        local pd = teams:FindFirstChild("PD")
        if pd then LocalPlayer.Team=pd; WindUI:Notify({ Title="Team", Content="Switched to PD", Duration=2 })
        else WindUI:Notify({ Title="Team", Content="PD team not found", Duration=3 }) end
    end })
end

-- ========== CONFIG TAB ==========
local configMainSection = tabs.config:Section({ Title="Configuration", Icon="database", Opened=true })
do
    configMainSection:Paragraph({ Title="loc:CONFIG_TITLE", Desc="loc:CONFIG_DESC" })
    configMainSection:Dropdown({ Title="loc:LANGUAGE", Desc="loc:LANGUAGE_DESC", Values=hubLangLabels, Multi=false, Default="English", Callback=function(selected)
        if selected and hubLangCodeByLabel[selected] then setHubLanguage(hubLangCodeByLabel[selected]) end
    end })
end

if hasFileSupport then
    local configSaveSection = tabs.config:Section({ Title="Config Manager", Icon="save", Opened=false })
    local ConfigManager = Window.ConfigManager
    local currentConfigName = "settings"
    local configDropdown    = nil
    local newConfigName     = ""
    local activeConfig      = ConfigManager:CreateConfig(currentConfigName)

    local function getConfig(name) return ConfigManager:CreateConfig(name) end
    local function refreshConfigList()
        local names = ConfigManager:AllConfigs() or {}; table.sort(names)
        if configDropdown then
            configDropdown:Refresh(names)
            if table.find(names, currentConfigName) then configDropdown:Select(currentConfigName)
            else configDropdown:Select(nil) end
        end
    end
    local function applyPostConfigLoad()
        refreshWhitelistDropdown(); updateAimlockVisuals(); refreshESP()
    end

    configDropdown = configSaveSection:Dropdown({ Title="loc:CONFIG_LIST", Desc="loc:CONFIG_LIST_DESC", Values={}, Multi=false, Default=nil, Callback=function(selected)
        if selected then currentConfigName=selected; activeConfig=getConfig(currentConfigName) end
    end })
    configSaveSection:Input({ Title="loc:CONFIG_NEW_NAME", Desc="loc:CONFIG_NEW_NAME_DESC", Value="", Type="Input", Placeholder="e.g., myconfig", Callback=function(input) newConfigName=input end })

    local cfgGroup1 = configSaveSection:Group({})
    cfgGroup1:Button({ Title="New Config", Icon="", Justify="Center", Callback=function()
        if newConfigName and newConfigName~="" then
            currentConfigName=newConfigName; activeConfig=getConfig(currentConfigName); activeConfig:Save(); refreshConfigList()
            WindUI:Notify({ Title="Config", Content="Created: "..currentConfigName, Duration=2 })
        else WindUI:Notify({ Title="Config", Content="Please enter a name", Duration=2 }) end
    end })
    cfgGroup1:Space()
    cfgGroup1:Button({ Title="Save Config", Icon="", Justify="Center", Callback=function()
        activeConfig=getConfig(currentConfigName)
        if activeConfig:Save() then refreshConfigList(); WindUI:Notify({ Title="Config", Content="Saved to "..currentConfigName, Duration=2 })
        else WindUI:Notify({ Title="Config", Content="Failed to save", Duration=2 }) end
    end })

    local cfgGroup2 = configSaveSection:Group({})
    cfgGroup2:Button({ Title="Load Config", Icon="", Justify="Center", Callback=function()
        activeConfig=getConfig(currentConfigName)
        if activeConfig:Load() then applyPostConfigLoad(); WindUI:Notify({ Title="Config", Content="Loaded from "..currentConfigName, Duration=2 })
        else WindUI:Notify({ Title="Config", Content="File not found", Duration=2 }) end
    end })
    cfgGroup2:Space()
    cfgGroup2:Button({ Title="Delete Config", Icon="", Justify="Center", Callback=function()
        if currentConfigName=="settings" then WindUI:Notify({ Title="Config", Content="Cannot delete 'settings'", Duration=2 }); return end
        local ok = pcall(function() getConfig(currentConfigName):Delete() end)
        if ok then refreshConfigList(); currentConfigName="settings"; activeConfig=getConfig(currentConfigName); if configDropdown then configDropdown:Select("settings") end; WindUI:Notify({ Title="Config", Content="Deleted", Duration=2 })
        else WindUI:Notify({ Title="Config", Content="File not found", Duration=2 }) end
    end })

    local cfgGroup3 = configSaveSection:Group({})
    cfgGroup3:Button({ Title="Refresh List", Icon="", Justify="Center", Callback=function()
        refreshConfigList(); WindUI:Notify({ Title="Config", Content="List refreshed", Duration=1 })
    end })
    cfgGroup3:Space()
    cfgGroup3:Button({ Title="Reset to Defaults", Icon="", Justify="Center", Callback=function()
        if uiRefs.InstantPromptsToggle  then uiRefs.InstantPromptsToggle:Set(false)  end
        if uiRefs.InfiniteStaminaToggle then uiRefs.InfiniteStaminaToggle:Set(false) end
        if uiRefs.InfiniteStrengthToggle then uiRefs.InfiniteStrengthToggle:Set(false) end
        if uiRefs.UnlockCameraToggle    then uiRefs.UnlockCameraToggle:Set(false)    end
        if uiRefs.AntiAFKToggle         then uiRefs.AntiAFKToggle:Set(false)         end
        if uiRefs.AimlockToggle         then uiRefs.AimlockToggle:Set(false)         end
        if uiRefs.AimlockColorpicker    then uiRefs.AimlockColorpicker:Set(Color3.new(1,1,1)) end
        if uiRefs.FOVSlider             then uiRefs.FOVSlider:Set(360)               end
        if uiRefs.RangeSlider           then uiRefs.RangeSlider:Set(1000)            end
        if uiRefs.WhitelistDropdown     then uiRefs.WhitelistDropdown:Select({})     end
        if uiRefs.ESPToggle             then uiRefs.ESPToggle:Set(false)             end
        if uiRefs.RealisticGraphicsToggle then uiRefs.RealisticGraphicsToggle:Set(false) end
        local cryptoNames2 = {"Bitcoin","DOGE","ETH"}
        for _, cryptoName in ipairs(cryptoNames2) do
            if uiRefs["AutoBuy_"..cryptoName]      then uiRefs["AutoBuy_"..cryptoName]:Set(false)  end
            if uiRefs["AutoSell_"..cryptoName]     then uiRefs["AutoSell_"..cryptoName]:Set(false) end
            if uiRefs["BuyThreshold_"..cryptoName] then uiRefs["BuyThreshold_"..cryptoName]:Set(300)  end
            if uiRefs["SellThreshold_"..cryptoName] then uiRefs["SellThreshold_"..cryptoName]:Set(9000) end
        end
        applyPostConfigLoad(); WindUI:Notify({ Title="Config", Content="Reset to defaults", Duration=2 })
    end })

    task.spawn(function()
        task.wait(0.5); refreshConfigList()
        if activeConfig:Load() then applyPostConfigLoad() end
    end)
else
    local unavailConfigSection = tabs.config:Section({ Title="Saving Unavailable", Icon="x", Opened=true })
    unavailConfigSection:Paragraph({ Title="loc:SAVING_UNAVAILABLE", Desc="loc:SAVING_UNAVAILABLE_DESC" })
end

-- ========== RENDER LOOP ==========
local renderSteppedConnection = nil
if renderSteppedConnection then renderSteppedConnection:Disconnect() end
renderSteppedConnection = RunService.RenderStepped:Connect(function(dt)
    pcall(function()
        if aimlock.enabled then
            if updateFOVCircle then updateFOVCircle() end
            if FOVCircle then FOVCircle.Visible = true end
        else
            if FOVCircle then FOVCircle.Visible = false end
        end
        if aimlock.enabled and aimlock.active then
            if aimlock.currentTarget then
                if not isStickyValid(aimlock.currentTarget) then aimlock.currentTarget = nil end
            else
                aimlock.currentTarget = getClosestPlayer()
            end
            if aimlock.currentTarget and isValidTarget(aimlock.currentTarget) then
                local part = aimlock.currentTarget.Character:FindFirstChild(aimlock.targetPart) or aimlock.currentTarget.Character.HumanoidRootPart
                local head = aimlock.currentTarget.Character.Head  -- for snap line
                if updateSnapLine then updateSnapLine(head.Position) end
                if not isMobileUser then
                    if moveMouseFunc then
                        local ok, screenPoint = pcall(Camera.WorldToViewportPoint, Camera, part.Position)
                        if ok and screenPoint then
                            local mousePos = UserInputService:GetMouseLocation()
                            local delta = Vector2.new(screenPoint.X, screenPoint.Y) - mousePos
                            if delta.Magnitude > 1 then
                                local move = delta * aimlock.smooth
                                if move.Magnitude > delta.Magnitude then move = delta end
                                moveMouseFunc(move.X, move.Y)
                            end
                        end
                    end
                end
            else
                if SnapLine then SnapLine.Visible = false end
            end
        else
            if SnapLine then SnapLine.Visible = false end
        end
    end)
end)

-- ========== CLEANUP ==========
local function cleanup()
    if FOVCircle then pcall(FOVCircle.Remove, FOVCircle) end
    if SnapLine  then pcall(SnapLine.Remove, SnapLine)  end
    if promptConnection        then promptConnection:Disconnect()        end
    if staminaConnection       then staminaConnection:Disconnect()       end
    if strengthConnection      then strengthConnection:Disconnect()      end
    if antiAFKConnection       then antiAFKConnection:Disconnect()       end
    if blurHeartbeatConnection then blurHeartbeatConnection:Disconnect() end
    if cameraChangedConnection then cameraChangedConnection:Disconnect() end
    if blurEffect              then blurEffect:Destroy()                 end
    if renderSteppedConnection then renderSteppedConnection:Disconnect() end
    for player in pairs(EspSettings.objects) do removeESPForPlayer(player) end
    if mobileAimlockGui then mobileAimlockGui:Destroy() end
    mobileAimlockGui = nil
    mobileAimlockButton = nil
    if _G.AimAssistDummy then
        _G.AimAssistDummy:Destroy()
        _G.AimAssistDummy = nil
    end
    if aimAssistInstance then
        aimAssistInstance:destroy()
        aimAssistInstance = nil
    end
end

-- ========== FINALIZE ==========
Window:SetToggleKey(Enum.KeyCode.LeftAlt)
WindUI:Notify({ Title="loc:LOADED_TITLE", Content="loc:LOADED_CONTENT", Duration=3 })
print("Dubu Hub v6.5 (Rosewave) loaded.")

return { cleanup = cleanup }
