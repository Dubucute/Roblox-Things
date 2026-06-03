-- Dubu Hub – Spin Wheel Edition (Final: Spin + Teleport + Player + Misc + Config)
-- UI Library: WindUI by Footagesus

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Check for file system support
local hasFileSupport = (isfolder ~= nil and makefolder ~= nil and listfiles ~= nil and readfile ~= nil and writefile ~= nil and delfile ~= nil)
if not hasFileSupport then
    warn("Dubu Hub: Your executor does not support file functions. Config saving will be disabled.")
end

-- Load WindUI Library
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
if not WindUI then
    warn("Failed to load WindUI.")
    return
end

-- Safe folder creation
local function ensureFolder(path)
    if not hasFileSupport then return end
    if not isfolder then return end
    local parts = string.split(path, "/")
    local current = ""
    for _, part in ipairs(parts) do
        if current == "" then
            current = part
        else
            current = current .. "/" .. part
        end
        if not isfolder(current) then
            pcall(makefolder, current)
        end
    end
end

-- ========== GET GAME NAME AND SANITIZE FOR FOLDER ==========
local function getGameName()
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if success and info and info.Name then
        return info.Name
    end
    return "UnknownGame"
end

local rawGameName = getGameName()
local function sanitizeName(name)
    local invalid = '[\\/:*?"<>|]'
    local sanitized = string.gsub(name, invalid, "_")
    sanitized = string.match(sanitized, "^%s*(.-)%s*$")
    if sanitized == "" then sanitized = "UnknownGame" end
    return sanitized
end
local gameFolderName = sanitizeName(rawGameName)
local gameFolder = "DubuHub/" .. gameFolderName

if hasFileSupport then
    ensureFolder(gameFolder)
    ensureFolder(gameFolder .. "/config")
    ensureFolder(gameFolder .. "/locations")
end

-- ========== THEME ==========
WindUI:AddTheme({
    Name = "DubuPink",
    Accent = Color3.fromHex("#ff79b0"),
    Background = Color3.fromHex("#101010"),
    BackgroundTransparency = 0,
    Outline = Color3.fromHex("#ff79b0"),
    Text = Color3.fromHex("#ffffff"),
    Placeholder = Color3.fromHex("#e8d5db"),
    Button = Color3.fromHex("#ff79b0"),
    Icon = Color3.fromHex("#ff79b0"),
    Hover = Color3.fromHex("#ffcde1"),
    WindowBackground = Color3.fromHex("#101010"),
    WindowShadow = Color3.fromHex("#000000"),
    DialogBackground = Color3.fromHex("#101010"),
    DialogBackgroundTransparency = 0,
    DialogTitle = Color3.fromHex("#ffffff"),
    DialogContent = Color3.fromHex("#ffffff"),
    DialogIcon = Color3.fromHex("#ff79b0"),
    WindowTopbarButtonIcon = Color3.fromHex("#ff79b0"),
    WindowTopbarTitle = Color3.fromHex("#ffffff"),
    WindowTopbarAuthor = Color3.fromHex("#ffffff"),
    WindowTopbarIcon = Color3.fromHex("#ff79b0"),
    TabBackground = Color3.fromHex("#0b0b0b"),
    TabTitle = Color3.fromHex("#ffffff"),
    TabIcon = Color3.fromHex("#ff79b0"),
    ElementBackground = Color3.fromHex("#0b0b0b"),
    ElementTitle = Color3.fromHex("#ffffff"),
    ElementDesc = Color3.fromHex("#d1c7cf"),
    ElementIcon = Color3.fromHex("#ff79b0"),
    PopupBackground = Color3.fromHex("#101010"),
    PopupBackgroundTransparency = 0,
    PopupTitle = Color3.fromHex("#ffffff"),
    PopupContent = Color3.fromHex("#ffffff"),
    PopupIcon = Color3.fromHex("#ff79b0"),
    Toggle = Color3.fromHex("#ff79b0"),
    ToggleBar = Color3.fromHex("#ffffff"),
    Checkbox = Color3.fromHex("#ff79b0"),
    CheckboxIcon = Color3.fromHex("#ffffff"),
    Slider = Color3.fromHex("#ff79b0"),
    SliderThumb = Color3.fromHex("#ffffff"),
})

WindUI:SetTheme("DubuPink")

-- ========== VERSION & WINDOW ==========
local VERSION = "v3.2"

local Window = WindUI:CreateWindow({
    Title = "Dubu Hub",
    Icon = "paw-print",
    Author = "by Dubu",
    Theme = "DubuPink",
    Size = UDim2.fromOffset(600, 480),
    MinSize = Vector2.new(550, 400),
    MaxSize = Vector2.new(900, 600),
    Transparent = true,
    Resizable = true,
    SideBarWidth = 200,
    HideSearchBar = true,
    ScrollBarEnabled = false,
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function() print("User clicked") end,
    },
})

Window:Tag({
    Title = rawGameName,
    Icon = "gamepad",
    Color = Color3.fromHex("#ff79b0"),
    Radius = 8,
})
Window:Tag({
    Title = VERSION,
    Color = Color3.fromHex("#ff79b0"),
    Radius = 8,
})

if not Window then
    warn("Failed to create WindUI window.")
    return
end

Window:EditOpenButton({
    Title = "Open Dubu Hub",
    Icon = "paw-print",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHex("FF0F7B")),
        ColorSequenceKeypoint.new(1, Color3.fromHex("F89B29"))
    }),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

-- ========== TABS ==========
local spinTab = Window:Tab({ Title = "Spin", Icon = "rotate-cw", Locked = false })
local teleportTab = Window:Tab({ Title = "Teleport", Icon = "map-pin", Locked = false })
local shopTab = Window:Tab({ Title = "Shop", Icon = "shopping-cart", Locked = false })
local playerTab = Window:Tab({ Title = "Player", Icon = "user", Locked = false })
local miscTab = Window:Tab({ Title = "Misc", Icon = "settings", Locked = false })

-- ========== UI REFERENCES ==========
local uiRefs = {
    sliders = {},
    toggles = {},
}

-- ========== INSTANT PROMPTS ==========
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
                    if prompt:IsA("ProximityPrompt") then
                        pcall(function() prompt.HoldDuration = 0 end)
                    end
                    task.wait()
                end
                scanningPrompts = false
            end)
        end
        promptConnection = ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
            if prompt and prompt.Parent then
                pcall(function() prompt.HoldDuration = 0 end)
            end
        end)
    else
        if promptConnection then
            promptConnection:Disconnect()
            promptConnection = nil
        end
    end
end

-- ========== ANTI AFK ==========
local antiAFKEnabled = false
local antiAFKConnection = nil

local function toggleAntiAFK(value)
    antiAFKEnabled = value
    if value then
        if antiAFKConnection then return end
        antiAFKConnection = LocalPlayer.Idled:Connect(function()
            VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end)
        WindUI:Notify({ Title = "Anti AFK", Content = "Enabled - You won't be kicked", Duration = 2 })
    else
        if antiAFKConnection then
            antiAFKConnection:Disconnect()
            antiAFKConnection = nil
            WindUI:Notify({ Title = "Anti AFK", Content = "Disabled", Duration = 2 })
        end
    end
end

-- ========== LOAD INFINITE YIELD ==========
local function loadInfiniteYield()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    WindUI:Notify({ Title = "Infinite Yield", Content = "Loaded!", Duration = 2 })
end

-- ========== SPIN WHEEL TAB (TWO BUTTONS: START / STOP, NO STATUS) ==========
spinTab:Paragraph({ Title = "Spin & Reveal", Desc = "Spin for unique parts. Auto-stops when a non-blacklisted part appears.", Icon = "rotate-cw" })

-- Locate remotes
local SpinRemote = nil
local RevealRemote = nil
local spinType = nil

local function findRemotes()
    local Packages = ReplicatedStorage:FindFirstChild("Packages")
    if not Packages then return end
    local Index = Packages:FindFirstChild("_Index")
    if not Index then return end
    local KnitPackage = Index:FindFirstChild("sleitnick_knit@1.7.0")
    if not KnitPackage then return end
    local Knit = KnitPackage:FindFirstChild("knit")
    if not Knit then return end
    local Services = Knit:FindFirstChild("Services")
    if not Services then return end
    local SpinService = Services:FindFirstChild("SpinService")
    if not SpinService then return end
    local RF = SpinService:FindFirstChild("RF")
    if not RF then return end
    SpinRemote = RF:FindFirstChild("Spin")
    RevealRemote = RF:FindFirstChild("Reveal")
    if SpinRemote then
        spinType = SpinRemote:IsA("RemoteFunction") and "Function" or "Event"
    end
end

findRemotes()

if not SpinRemote then
    spinTab:Paragraph({ Title = "Remote Missing", Desc = "Spin remote not found.", Icon = "alert-circle" })
else
    print("[Spin] Remote found. Type:", spinType)

    -- Blacklist parts
    local allParts = { "Basic", "Office", "Pro", "Gamer", "Gold", "Diamond", "Ocean", "Nature", "Anime", "Kittie", "Void", "Underwater", "Volcano", "Space" }
    local blacklist = { "Basic" }

    -- Helper functions
    local function formatPad(padName, padData)
        if type(padData) ~= "table" then
            return string.format("%s: %s", padName, tostring(padData))
        end
        local group = padData.Group or "?"
        local name = padData.Name or "?"
        return string.format("%s: %s > %s", padName, name, group)
    end

    local function getSortedPads(resultTable)
        local pads = {}
        for k, v in pairs(resultTable) do
            local num = string.match(k, "Pad(%d+)")
            if num then
                table.insert(pads, { num = tonumber(num), key = k, data = v })
            else
                table.insert(pads, { num = 999, key = k, data = v })
            end
        end
        table.sort(pads, function(a, b) return a.num < b.num end)
        return pads
    end

    local function formatFullResult(resultTable)
        local sorted = getSortedPads(resultTable)
        local lines = {}
        for _, pad in ipairs(sorted) do
            lines[#lines+1] = formatPad(pad.key, pad.data)
        end
        if #lines == 0 then return "No parts received (cooldown?)" end
        return table.concat(lines, "\n")
    end

    local function isBlacklisted(padData)
        if type(padData) ~= "table" then return false end
        local name = padData.Name
        if not name then return false end
        for _, bl in ipairs(blacklist) do
            if name == bl then return true end
        end
        return false
    end

    local function findUniqueParts(resultTable)
        local unique = {}
        for padName, padData in pairs(resultTable) do
            if type(padData) == "table" and padData.Name then
                if not isBlacklisted(padData) then
                    table.insert(unique, { pad = padName, data = padData })
                end
            end
        end
        table.sort(unique, function(a, b)
            local numA = tonumber(string.match(a.pad, "Pad(%d+)")) or 999
            local numB = tonumber(string.match(b.pad, "Pad(%d+)")) or 999
            return numA < numB
        end)
        return unique
    end

    local function playSound()
        local sound = game:GetService("ReplicatedStorage"):FindFirstChild("Utility")
        if sound then sound = sound:FindFirstChild("Temps") end
        if sound then sound = sound:FindFirstChild("Sounds") end
        if sound then sound = sound:FindFirstChild("ConfettiSound") end
        if sound and sound:IsA("Sound") then
            local newSound = sound:Clone()
            newSound.Parent = game:GetService("SoundService")
            newSound:Play()
            task.wait(1)
            newSound:Destroy()
        else
            local beep = Instance.new("Sound")
            beep.SoundId = "rbxassetid://9120373636"
            beep.Volume = 0.5
            beep.Parent = game:GetService("SoundService")
            beep:Play()
            task.wait(1)
            beep:Destroy()
        end
    end

    -- Spin function
    local function doSpin()
        if not SpinRemote then return nil end
        local success, result
        if spinType == "Function" then
            success, result = pcall(function() return SpinRemote:InvokeServer() end)
        else
            success, result = pcall(function() SpinRemote:FireServer() end)
            result = nil
        end
        if not success then return nil end
        if spinType == "Event" then return nil end
        if result == nil or (type(result) == "table" and next(result) == nil) then return nil end
        return result
    end

    -- Spin Computer section
    spinTab:Section({ Title = "Spin Computer", Icon = "cpu", Opened = true })
    
    spinTab:Button({
        Title = "Spin Once",
        Icon = "rotate-cw",
        Callback = function()
            local result = doSpin()
            if result then
                local formatted = formatFullResult(result)
                WindUI:Notify({ Title = "Spin Result", Content = formatted, Duration = 5 })
            else
                WindUI:Notify({ Title = "Spin", Content = "No result (cooldown?)", Duration = 2 })
            end
        end
    })
    
    if RevealRemote then
        spinTab:Button({
            Title = "Reveal Once",
            Icon = "eye",
            Callback = function()
                if RevealRemote:IsA("RemoteFunction") then
                    pcall(function() RevealRemote:InvokeServer() end)
                else
                    pcall(function() RevealRemote:FireServer() end)
                end
                WindUI:Notify({ Title = "Reveal", Content = "Reveal triggered – check in-game UI", Duration = 3 })
            end
        })
    end
    
    spinTab:Divider()
    spinTab:Space()
    
    -- Auto Spin section
    spinTab:Section({ Title = "Auto Spin", Icon = "zap", Opened = true })
    
    spinTab:Dropdown({
        Title = "Blacklisted Parts (Auto-skip)",
        Desc = "Select parts to treat as common. Auto-spin stops when a part NOT in this list appears.",
        Values = allParts,
        Value = blacklist,
        Multi = true,
        AllowNone = false,
        Callback = function(selected)
            blacklist = selected
        end
    })
    
    -- Two separate buttons: Start and Stop (no status)
    local autoActive = false
    local autoTask = nil
    local spinDelay = 3.0
    
    local function stopAutoSpin(manual)
        if autoActive then
            autoActive = false
            if autoTask then
                task.cancel(autoTask)
                autoTask = nil
            end
            WindUI:Notify({ Title = "Auto-Spin", Content = manual and "Stopped manually" or "Stopped", Duration = 2 })
        end
    end
    
    local function startAutoSpin()
        if autoActive then
            WindUI:Notify({ Title = "Auto-Spin", Content = "Already running!", Duration = 2 })
            return
        end
        autoActive = true
        WindUI:Notify({ Title = "Auto-Spin", Content = "Started! Spinning every 3s...", Duration = 3 })
        autoTask = task.spawn(function()
            local spinCount = 0
            while autoActive do
                spinCount = spinCount + 1
                local foundUnique = false
                local success, result
                if spinType == "Function" then
                    success, result = pcall(function() return SpinRemote:InvokeServer() end)
                else
                    success, result = pcall(function() SpinRemote:FireServer() end)
                    result = nil
                end
                if not success then
                    -- error, will retry
                elseif result and type(result) == "table" then
                    local parts = {}
                    local sorted = getSortedPads(result)
                    for _, pad in ipairs(sorted) do
                        parts[#parts+1] = formatPad(pad.key, pad.data)
                    end
                    WindUI:Notify({ Title = "Spin #" .. spinCount, Content = table.concat(parts, "\n"), Duration = 3 })
                    local unique = findUniqueParts(result)
                    if #unique > 0 then
                        foundUnique = true
                        local uniqueLines = {}
                        for _, u in ipairs(unique) do
                            uniqueLines[#uniqueLines+1] = formatPad(u.pad, u.data)
                        end
                        local uniqueText = table.concat(uniqueLines, "\n")
                        WindUI:Notify({ Title = "Unique Parts Found!", Content = uniqueText, Duration = 8 })
                        playSound()
                        task.wait(2.0)
                        if RevealRemote then
                            if RevealRemote:IsA("RemoteFunction") then
                                pcall(function() RevealRemote:InvokeServer() end)
                            else
                                pcall(function() RevealRemote:FireServer() end)
                            end
                            WindUI:Notify({ Title = "Reveal", Content = "Reveal triggered – check in-game for the parts list", Duration = 4 })
                        end
                    end
                elseif spinType == "Event" then
                    WindUI:Notify({ Title = "Spin #" .. spinCount, Content = "Event fired", Duration = 2 })
                else
                    WindUI:Notify({ Title = "Spin #" .. spinCount, Content = "No result (cooldown?)", Duration = 2 })
                end
                if foundUnique then
                    stopAutoSpin(false)
                    break
                end
                if autoActive then
                    local waited = 0
                    while waited < spinDelay and autoActive do
                        task.wait(0.1)
                        waited = waited + 0.1
                    end
                end
            end
            autoActive = false
            autoTask = nil
            WindUI:Notify({ Title = "Auto-Spin", Content = "Stopped", Duration = 2 })
        end)
    end
    
    -- Start button
    spinTab:Button({
        Title = "Start Auto-Spin",
        Desc = "Begin auto-spinning until a unique part appears",
        Icon = "play",
        Callback = startAutoSpin
    })
    
    -- Stop button
    spinTab:Button({
        Title = "Stop Auto-Spin",
        Desc = "Manually stop the auto-spin process",
        Icon = "square",
        Callback = function()
            stopAutoSpin(true)
        end
    })
end

-- ========== TELEPORT TAB (BUTTONS FOR EACH FLOOR, NO STATUS MESSAGES) ==========
teleportTab:Paragraph({ Title = "Floor Teleporter", Desc = "Click a button to teleport to the middle of that floor.", Icon = "map-pin" })

local LocalPlayer = Players.LocalPlayer
local userId = LocalPlayer.UserId

-- Find the player's plot by scanning workspace.Main.Plots for Owner attribute
local function findPlayerPlot()
    local main = workspace:FindFirstChild("Main")
    if not main then return nil end
    local plots = main:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plotModel in ipairs(plots:GetChildren()) do
        local owner = plotModel:GetAttribute("Owner")
        if owner and owner == userId then
            return plotModel
        end
    end
    return nil
end

-- Teleport to a specific floor (middle of its "Floor" part)
local function teleportToFloor(floorName, floorObj)
    local floorPart = floorObj:FindFirstChild("Floor")
    if not floorPart or not floorPart:IsA("BasePart") then
        floorPart = floorObj:FindFirstChildWhichIsA("BasePart")
    end
    if not floorPart then
        WindUI:Notify({ Title = "Error", Content = "No floor part found for " .. floorName, Duration = 2 })
        return
    end
    
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        WindUI:Notify({ Title = "Error", Content = "Character not ready", Duration = 2 })
        return
    end
    
    LocalPlayer:SetAttribute("CurrentFloor", floorName)
    local teleportPos = floorPart.Position + Vector3.new(0, 2, 0)
    rootPart.CFrame = CFrame.new(teleportPos)
    WindUI:Notify({ Title = "Teleported", Content = "Now on " .. floorName, Duration = 2 })
end

-- Create buttons for each floor
local function createFloorButtons()
    local plot = findPlayerPlot()
    if not plot then
        teleportTab:Paragraph({ Title = "Error", Desc = "Could not locate your plot. Make sure you are in the game world.", Icon = "alert-circle" })
        return
    end
    
    local floorsFolder = plot:FindFirstChild("Floors")
    if not floorsFolder then
        teleportTab:Paragraph({ Title = "Error", Desc = "Your plot does not have a Floors folder.", Icon = "alert-circle" })
        return
    end
    
    local floorFolders = {}
    for _, child in ipairs(floorsFolder:GetChildren()) do
        if child.Name:match("^Floor%d+$") then
            table.insert(floorFolders, child)
        end
    end
    if #floorFolders == 0 then
        teleportTab:Paragraph({ Title = "Error", Desc = "No floors found in your plot.", Icon = "alert-circle" })
        return
    end
    
    table.sort(floorFolders, function(a, b)
        local na = tonumber(string.match(a.Name, "%d+")) or 0
        local nb = tonumber(string.match(b.Name, "%d+")) or 0
        return na < nb
    end)
    
    for _, floorObj in ipairs(floorFolders) do
        local floorName = floorObj.Name
        local floorNum = string.match(floorName, "%d+")
        teleportTab:Button({
            Title = string.format("Floor %s", floorNum),
            Desc = string.format("Teleport to %s", floorName),
            Icon = "arrow-up",
            Callback = function()
                teleportToFloor(floorName, floorObj)
            end
        })
    end
end

-- Execute
task.spawn(function()
    task.wait(0.5) -- brief delay to ensure workspace is loaded
    createFloorButtons()
end)

-- ========== SHOP TAB (Auto-Buy Tables & Chairs) ==========
shopTab:Paragraph({ Title = "Decoration Shop Auto-Buy", Desc = "Select items to automatically buy when they are in stock.", Icon = "shopping-cart" })

-- Shop data tables
local TablesShopData = {
    ["Office Table"] = { Rarity = "Common", Price = 20000, Image = "", RobuxPrice = 59, Boost = { Type = "Cash", Amount = 0.025 } },
    ["Modern Table"] = { Rarity = "Common", Price = 5000, Image = "", RobuxPrice = 29, Boost = { Type = "Speed", Amount = 0.025 } },
    ["Studio Table"] = { Rarity = "Uncommon", Price = 100000, Image = "", RobuxPrice = 99, Boost = { Type = "Cash", Amount = 0.05 } },
    ["Glass Table"] = { Rarity = "Rare", Price = 1000000, Image = "", RobuxPrice = 149, Boost = { Type = "Speed", Amount = 0.1 } },
    ["Gaming Table"] = { Rarity = "Rare", Price = 5000000, Image = "", RobuxPrice = 219, Boost = { Type = "Cash", Amount = 0.075 } },
    ["Pro Table"] = { Rarity = "Epic", Price = 15000000, Image = "", RobuxPrice = 299, Boost = { Type = "Speed", Amount = 0.125 } },
    ["Chess Table"] = { Rarity = "Epic", Price = 50000000, Image = "", RobuxPrice = 349, Boost = { Type = "Cash", Amount = 0.1 } },
    ["Surfer Table"] = { Rarity = "Legendary", Price = 100000000, Image = "", RobuxPrice = 499, Boost = { Type = "Speed", Amount = 0.2 } },
    ["Pizza Table"] = { Rarity = "Mythic", Price = 500000000, Image = "", RobuxPrice = 599, Boost = { Type = "Cash", Amount = 0.2 } },
    ["Princess Table"] = { Rarity = "Divine", Price = 1000000000, Image = "", RobuxPrice = 799, Boost = { Type = "Cash", Amount = 0.3 } },
    ["Royal Table"] = { Rarity = "Secret", Price = 10000000000, Image = "", RobuxPrice = 1199, Boost = { Type = "Cash", Amount = 0.4 } },
}

local ChairsShopData = {
    ["Office Chair"] = { Rarity = "Common", Price = 5000, Image = "", RobuxPrice = 29, Boost = { Type = "Speed", Amount = 0.025 } },
    ["BeanBag Chair"] = { Rarity = "Common", Price = 20000, Image = "", RobuxPrice = 59, Boost = { Type = "Cash", Amount = 0.025 } },
    ["Gaming Chair"] = { Rarity = "Uncommon", Price = 50000, Image = "", RobuxPrice = 99, Boost = { Type = "Speed", Amount = 0.05 } },
    ["Toilet Chair"] = { Rarity = "Uncommon", Price = 100000, Image = "", RobuxPrice = 149, Boost = { Type = "Cash", Amount = 0.05 } },
    ["Kittie Chair"] = { Rarity = "Rare", Price = 1000000, Image = "", RobuxPrice = 299, Boost = { Type = "Speed", Amount = 0.1 } },
    ["Gummy Chair"] = { Rarity = "Rare", Price = 5000000, Image = "", RobuxPrice = 219, Boost = { Type = "Cash", Amount = 0.075 } },
    ["Rainbow Chair"] = { Rarity = "Epic", Price = 15000000, Image = "", RobuxPrice = 349, Boost = { Type = "Speed", Amount = 0.125 } },
    ["Rocket Chair"] = { Rarity = "Epic", Price = 50000000, Image = "", RobuxPrice = 499, Boost = { Type = "Cash", Amount = 0.1 } },
    ["Golden Chair"] = { Rarity = "Legendary", Price = 100000000, Image = "", RobuxPrice = 599, Boost = { Type = "Cash", Amount = 0.15 } },
    ["UFO Chair"] = { Rarity = "Mythic", Price = 500000000, Image = "", RobuxPrice = 799, Boost = { Type = "Speed", Amount = 0.25 } },
    ["Royal Chair"] = { Rarity = "Divine", Price = 1000000000, Image = "", RobuxPrice = 1199, Boost = { Type = "Cash", Amount = 0.3 } },
}

-- Rarity order for sorting (lowest to highest)
local RarityOrder = {
    Common = 1,
    Uncommon = 2,
    Rare = 3,
    Epic = 4,
    Legendary = 5,
    Mythic = 6,
    Divine = 7,
    Secret = 8,
    Limited = 9,
}

-- Sort items by rarity (lowest first) then by price within same rarity
local function sortByRarity(data)
    local items = {}
    for name, info in pairs(data) do
        table.insert(items, { name = name, data = info })
    end
    table.sort(items, function(a, b)
        local ra = RarityOrder[a.data.Rarity] or 99
        local rb = RarityOrder[b.data.Rarity] or 99
        if ra ~= rb then return ra < rb end
        return a.data.Price < b.data.Price
    end)
    local sorted = {}
    for _, item in ipairs(items) do
        table.insert(sorted, item.name)
    end
    return sorted
end

-- Build dropdown values with price info: "Name — $Price"
local function buildDropdownValues(data, sortedNames)
    local values = {}
    for _, name in ipairs(sortedNames) do
        local info = data[name]
        local priceStr = tostring(info.Price)
        -- Add commas for readability
        local formattedPrice = ""
        while #priceStr > 3 do
            formattedPrice = "," .. priceStr:sub(-3) .. formattedPrice
            priceStr = priceStr:sub(1, -4)
        end
        formattedPrice = priceStr .. formattedPrice
        table.insert(values, name .. " — $" .. formattedPrice)
    end
    return values
end

local tableNames = sortByRarity(TablesShopData)
local chairNames = sortByRarity(ChairsShopData)
local tableDropdownValues = buildDropdownValues(TablesShopData, tableNames)
local chairDropdownValues = buildDropdownValues(ChairsShopData, chairNames)

-- Locate BuyDecoration remote
local function findBuyDecorationRemote()
    local Packages = ReplicatedStorage:FindFirstChild("Packages")
    if not Packages then return nil end
    local Index = Packages:FindFirstChild("_Index")
    if not Index then return nil end
    local KnitPackage = Index:FindFirstChild("sleitnick_knit@1.7.0")
    if not KnitPackage then return nil end
    local Knit = KnitPackage:FindFirstChild("knit")
    if not Knit then return nil end
    local Services = Knit:FindFirstChild("Services")
    if not Services then return nil end
    local RestockService = Services:FindFirstChild("RestockService")
    if not RestockService then return nil end
    local RF = RestockService:FindFirstChild("RF")
    if not RF then return nil end
    return RF:FindFirstChild("BuyDecoration")
end

local BuyDecorationRemote = findBuyDecorationRemote()

if not BuyDecorationRemote then
    shopTab:Paragraph({ Title = "Remote Missing", Desc = "BuyDecoration remote not found.", Icon = "alert-circle" })
else
    print("[Shop] BuyDecoration remote found.")

        -- State
    local tablesRunning = false
    local chairsRunning = false
    local tablesTask = nil
    local chairsTask = nil
    local selectedTables = {}
    local selectedChairs = {}
    local tableCooldowns = {}
    local chairCooldowns = {}
    local SHOP_COOLDOWN = 2.0

    -- Helper to get stock for an item from LocalPlayer.Stock
    local function getItemStock(itemName)
        local stock = LocalPlayer:FindFirstChild("Stock")
        if not stock then return 0 end
        local stockValue = stock:FindFirstChild(itemName)
        if stockValue and stockValue:IsA("ValueBase") then
            return tonumber(stockValue.Value) or 0
        end
        return 0
    end

    -- Buy function
    local function attemptBuy(itemName)
        local stock = getItemStock(itemName)
        if stock <= 0 then return false end
        local cooldowns = (TablesShopData[itemName] and tableCooldowns) or chairCooldowns
        local now = os.clock()
        local last = cooldowns[itemName] or 0
        if now - last < SHOP_COOLDOWN then return false end
        cooldowns[itemName] = now
        local success, result = pcall(function()
            return BuyDecorationRemote:InvokeServer(itemName)
        end)
        if success then
            local name = string.match(itemName, "^(.+) [TC]able$") or string.match(itemName, "^(.+) [TC]hair$") or itemName
            WindUI:Notify({ Title = "Bought!", Content = "Purchased " .. itemName, Duration = 3 })
            return true
        else
            return false
        end
    end

    -- Tables loop
    local function tablesLoop()
        while tablesRunning do
            for _, itemName in ipairs(selectedTables) do
                local stock = getItemStock(itemName)
                if stock > 0 then
                    attemptBuy(itemName)
                end
                if not tablesRunning then break end
                task.wait(0.3)
            end
            if tablesRunning then
                task.wait(1.0)
            end
        end
    end

    -- Chairs loop
    local function chairsLoop()
        while chairsRunning do
            for _, itemName in ipairs(selectedChairs) do
                local stock = getItemStock(itemName)
                if stock > 0 then
                    attemptBuy(itemName)
                end
                if not chairsRunning then break end
                task.wait(0.3)
            end
            if chairsRunning then
                task.wait(1.0)
            end
        end
    end

        -- Stock change watcher with restock notifications
    local prevStock = {}

    local function checkAndNotifyRestock(itemName, currentStock)
        local prev = prevStock[itemName]
        if prev and currentStock > prev then
            local diff = currentStock - prev
            WindUI:Notify({
                Title = "Restocked!",
                Content = itemName .. " +" .. tostring(diff) .. " (Stock: " .. tostring(currentStock) .. ")",
                Duration = 4
            })
        end
        prevStock[itemName] = currentStock
    end

    local function watchStock()
        local stock = LocalPlayer:FindFirstChild("Stock")
        if stock then
            -- Initialize previous stock values
            for _, child in ipairs(stock:GetChildren()) do
                if child:IsA("ValueBase") then
                    prevStock[child.Name] = tonumber(child.Value) or 0
                end
            end

            -- Watch existing stock values
            for _, child in ipairs(stock:GetChildren()) do
                if child:IsA("ValueBase") then
                    child:GetPropertyChangedSignal("Value"):Connect(function()
                        local itemName = child.Name
                        local val = tonumber(child.Value) or 0
                        -- Restock notification
                        checkAndNotifyRestock(itemName, val)
                        -- Auto-buy check
                        if val > 0 then
                            if tablesRunning then
                                for _, name in ipairs(selectedTables) do
                                    if name == itemName then
                                        attemptBuy(itemName)
                                        break
                                    end
                                end
                            end
                            if chairsRunning then
                                for _, name in ipairs(selectedChairs) do
                                    if name == itemName then
                                        attemptBuy(itemName)
                                        break
                                    end
                                end
                            end
                        end
                    end)
                end
            end
            -- Watch for new stock values
            stock.ChildAdded:Connect(function(child)
                if child:IsA("ValueBase") then
                    prevStock[child.Name] = tonumber(child.Value) or 0
                    child:GetPropertyChangedSignal("Value"):Connect(function()
                        local itemName = child.Name
                        local val = tonumber(child.Value) or 0
                        -- Restock notification
                        checkAndNotifyRestock(itemName, val)
                        -- Auto-buy check
                        if val > 0 then
                            if tablesRunning then
                                for _, name in ipairs(selectedTables) do
                                    if name == itemName then
                                        attemptBuy(itemName)
                                        break
                                    end
                                end
                            end
                            if chairsRunning then
                                for _, name in ipairs(selectedChairs) do
                                    if name == itemName then
                                        attemptBuy(itemName)
                                        break
                                    end
                                end
                            end
                        end
                    end)
                end
            end)
        end
    end

    task.spawn(watchStock)

    -- ========== SHOP TAB UI ==========

    -- Tables Shop Section
    shopTab:Section({ Title = "Tables Shop", Icon = "table", Opened = true })

    shopTab:Dropdown({
        Title = "Select Tables to Auto-Buy",
        Desc = "Automatically purchase selected tables when they're in stock",
        Values = tableDropdownValues,
        Value = {},
        Multi = true,
        Callback = function(selected)
            -- Extract item names from display strings
            selectedTables = {}
            for _, display in ipairs(selected) do
                local name = string.match(display, "^(.+) — %$")
                if name then
                    table.insert(selectedTables, name)
                end
            end
        end
    })

        shopTab:Toggle({
        Title = "Auto-Buy Tables",
        Desc = "Toggle to automatically buy selected tables when in stock",
        Icon = "table",
        Value = false,
        Callback = function(state)
            if state then
                if #selectedTables == 0 then
                    WindUI:Notify({ Title = "Shop", Content = "Select at least one table first!", Duration = 3 })
                    return false
                end
                tablesRunning = true
                WindUI:Notify({ Title = "Tables", Content = "Auto-buy started! Monitoring stock...", Duration = 3 })
                tablesTask = task.spawn(tablesLoop)
            else
                tablesRunning = false
                if tablesTask then
                    task.cancel(tablesTask)
                    tablesTask = nil
                end
                WindUI:Notify({ Title = "Tables", Content = "Auto-buy stopped", Duration = 2 })
            end
        end
    })

    shopTab:Space()

    -- Chairs Shop Section
    shopTab:Section({ Title = "Chairs Shop", Icon = "armchair", Opened = true })

    shopTab:Dropdown({
        Title = "Select Chairs to Auto-Buy",
        Desc = "Automatically purchase selected chairs when they're in stock",
        Values = chairDropdownValues,
        Value = {},
        Multi = true,
        Callback = function(selected)
            -- Extract item names from display strings
            selectedChairs = {}
            for _, display in ipairs(selected) do
                local name = string.match(display, "^(.+) — %$")
                if name then
                    table.insert(selectedChairs, name)
                end
            end
        end
    })

        shopTab:Toggle({
        Title = "Auto-Buy Chairs",
        Desc = "Toggle to automatically buy selected chairs when in stock",
        Icon = "armchair",
        Value = false,
        Callback = function(state)
            if state then
                if #selectedChairs == 0 then
                    WindUI:Notify({ Title = "Shop", Content = "Select at least one chair first!", Duration = 3 })
                    return false
                end
                chairsRunning = true
                WindUI:Notify({ Title = "Chairs", Content = "Auto-buy started! Monitoring stock...", Duration = 3 })
                chairsTask = task.spawn(chairsLoop)
            else
                chairsRunning = false
                if chairsTask then
                    task.cancel(chairsTask)
                    chairsTask = nil
                end
                WindUI:Notify({ Title = "Chairs", Content = "Auto-buy stopped", Duration = 2 })
            end
        end
    })

    -- Manual buy buttons
    shopTab:Space()
    shopTab:Divider()
    shopTab:Paragraph({ Title = "Manual Buy", Desc = "Click to instantly buy any item", Icon = "shopping-bag" })

    -- Manual Tables Section
    shopTab:Section({ Title = "Buy Tables", Icon = "table", Opened = false })
    for _, itemName in ipairs(tableNames) do
        local data = TablesShopData[itemName]
        local rarityColor = data.Rarity
        local priceStr = string.format("$%s (%s)", tostring(data.Price), rarityColor)
        shopTab:Button({
            Title = itemName,
            Desc = priceStr .. " | Boost: " .. (data.Boost.Type or "?") .. " +" .. math.floor((data.Boost.Amount or 0) * 100 + 0.5) .. "%",
            Icon = "dollar-sign",
            Callback = function()
                local success, result = pcall(function()
                    return BuyDecorationRemote:InvokeServer(itemName)
                end)
                if success then
                    WindUI:Notify({ Title = "Bought!", Content = "Purchased " .. itemName, Duration = 3 })
                else
                    WindUI:Notify({ Title = "Error", Content = "Failed to buy " .. itemName, Duration = 3 })
                end
            end
        })
    end

    -- Manual Chairs Section
    shopTab:Section({ Title = "Buy Chairs", Icon = "armchair", Opened = false })
    for _, itemName in ipairs(chairNames) do
        local data = ChairsShopData[itemName]
        local priceStr = string.format("$%s (%s)", tostring(data.Price), data.Rarity)
        shopTab:Button({
            Title = itemName,
            Desc = priceStr .. " | Boost: " .. (data.Boost.Type or "?") .. " +" .. math.floor((data.Boost.Amount or 0) * 100 + 0.5) .. "%",
            Icon = "dollar-sign",
            Callback = function()
                local success, result = pcall(function()
                    return BuyDecorationRemote:InvokeServer(itemName)
                end)
                if success then
                    WindUI:Notify({ Title = "Bought!", Content = "Purchased " .. itemName, Duration = 3 })
                else
                    WindUI:Notify({ Title = "Error", Content = "Failed to buy " .. itemName, Duration = 3 })
                end
            end
        })
    end
end

-- ========== PLAYER TAB ==========
playerTab:Paragraph({ Title = "Player Controls", Desc = "Adjust character movement and world settings." })
uiRefs.sliders.Walkspeed = playerTab:Slider({
    Title = "Walkspeed",
    Value = { Min = 1, Max = 500, Default = 16 },
    Callback = function(v)
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.WalkSpeed = v end
        end
    end
})
uiRefs.sliders.JumpPower = playerTab:Slider({
    Title = "Jump Power",
    Value = { Min = 1, Max = 1000, Default = 50 },
    Callback = function(v)
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.JumpPower = v end
        end
    end
})
uiRefs.sliders.Gravity = playerTab:Slider({
    Title = "Gravity",
    Value = { Min = 1, Max = 1000, Default = 196.2, Step = 0.1 },
    Callback = function(v)
        workspace.Gravity = v
    end
})
uiRefs.sliders.Time = playerTab:Slider({
    Title = "Time",
    Value = { Min = 1, Max = 24, Default = 12 },
    Callback = function(v)
        Lighting.TimeOfDay = v .. ":00:00"
    end
})
playerTab:Button({
    Title = "Rejoin",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/roburox/s1mple/main/scripts/rejoin"))()
    end
})
playerTab:Button({
    Title = "Spoof Walkspeed & JP",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/roburox/s1mple/main/scripts/spoofwsjp"))()
    end
})
local infiniteJumpConnection = nil
uiRefs.toggles.InfiniteJump = playerTab:Toggle({
    Title = "Infinite Jump",
    Default = false,
    Callback = function(v)
        if v then
            infiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
                local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        else
            if infiniteJumpConnection then
                infiniteJumpConnection:Disconnect()
                infiniteJumpConnection = nil
            end
        end
    end
})
local noclipEnabled = false
local noclipConnection = nil
local function setNoclip(state)
    local character = LocalPlayer.Character
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state
        end
    end
end
local function enableNoclip()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Heartbeat:Connect(function()
        if noclipEnabled and LocalPlayer.Character then
            setNoclip(true)
        end
    end)
    setNoclip(true)
end
local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    setNoclip(false)
end
uiRefs.toggles.Noclip = playerTab:Toggle({
    Title = "Noclip",
    Default = false,
    Callback = function(v)
        noclipEnabled = v
        if v then
            enableNoclip()
            WindUI:Notify({ Title = "Noclip", Content = "Enabled", Duration = 2 })
        else
            disableNoclip()
            WindUI:Notify({ Title = "Noclip", Content = "Disabled", Duration = 2 })
        end
    end
})
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(1)
    if noclipEnabled then
        setNoclip(true)
    end
end)

-- ========== MISC TAB ==========
miscTab:Paragraph({ Title = "Miscellaneous", Desc = "Utility features." })

uiRefs.InstantPromptsToggle = miscTab:Toggle({
    Title = "Instant Prompts",
    Desc = "Make all proximity prompts instant (no hold)",
    Default = false,
    Callback = toggleInstantPrompts
})

uiRefs.AntiAFKToggle = miscTab:Toggle({
    Title = "Anti AFK",
    Desc = "Prevent being kicked for idle",
    Default = false,
    Callback = toggleAntiAFK
})

miscTab:Button({
    Title = "Load Infinite Yield",
    Desc = "Loads the Infinite Yield admin commands",
    Callback = loadInfiniteYield
})

-- ========== CLEANUP ==========
local function cleanup()
    if promptConnection then promptConnection:Disconnect() end
    if antiAFKConnection then antiAFKConnection:Disconnect() end
    if infiniteJumpConnection then infiniteJumpConnection:Disconnect() end
    if noclipConnection then noclipConnection:Disconnect() end
    if tablesTask then
        tablesRunning = false
        task.cancel(tablesTask)
        tablesTask = nil
    end
    if chairsTask then
        chairsRunning = false
        task.cancel(chairsTask)
        chairsTask = nil
    end
end

RunService.Stepped:Connect(function() end)

Window:SetToggleKey(Enum.KeyCode.LeftAlt)

-- Show update popup on launch
task.wait(1)
WindUI:Popup({
    Title = "New Update! " .. VERSION,
    Icon = "sparkles",
    Content = "What's new:\n- Shop Tab — Auto-buy Tables & Chairs\n- Restock notifications with stock counts",
    Buttons = {
        {
            Title = "Close",
            Icon = "x",
            Callback = function() end,
            Variant = "Tertiary",
        },
            {
                    Title = "Visit Site",
            Callback = function()
                if setclipboard then
                    pcall(setclipboard, "https://dubuhub.vercel.app")
                end
                WindUI:Popup({
                    Title = "Link Copied!",
                    Icon = "clipboard-check",
                    Content = "The link has been copied to your clipboard.",
                    Buttons = {
                        {
                            Title = "OK",
                            Callback = function() end,
                            Variant = "Primary",
                        }
                    }
                })
            end,
            Variant = "Primary",
        }
    }
})

WindUI:Notify({ Title = "Dubu Hub", Content = "Loaded! Press Left Alt to toggle UI.", Duration = 3 })
print("Dubu Hub " .. VERSION .. " (Spin + Teleport + Shop) loaded.")

return { cleanup = cleanup }
