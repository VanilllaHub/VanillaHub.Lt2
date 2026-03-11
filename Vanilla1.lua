-- DESTROY OLD GUI + cleanup
if type(_G.VanillaHubCleanup) == "function" then
    pcall(_G.VanillaHubCleanup)
    _G.VanillaHubCleanup = nil
end

for _, name in pairs({"VanillaHub", "VanillaHubWarning"}) do
    if game.CoreGui:FindFirstChild(name) then
        game.CoreGui[name]:Destroy()
    end
end

if _G.VH then
    if _G.VH.butter and _G.VH.butter.running then
        _G.VH.butter.running = false
        if _G.VH.butter.thread then pcall(task.cancel, _G.VH.butter.thread) end
        _G.VH.butter.thread = nil
    end
    _G.VH = nil
end

if workspace:FindFirstChild("VanillaHubTpCircle") then
    workspace.VanillaHubTpCircle:Destroy()
end

-- Only Lumber Tycoon 2
if game.PlaceId ~= 13822889 then
    task.spawn(function()
        task.wait(0.4)
        local warnGui = Instance.new("ScreenGui")
        warnGui.Name = "VanillaHubWarning"
        warnGui.Parent = game.CoreGui
        warnGui.ResetOnSpawn = false
        local frame = Instance.new("Frame", warnGui)
        frame.Size = UDim2.new(0, 400, 0, 220)
        frame.Position = UDim2.new(0.5, -200, 0.5, -110)
        frame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
        frame.BackgroundTransparency = 0.25
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)
        local uiStroke = Instance.new("UIStroke", frame)
        uiStroke.Color = Color3.fromRGB(190, 50, 50)
        uiStroke.Thickness = 1.5; uiStroke.Transparency = 0.45
        local icon = Instance.new("TextLabel", frame)
        icon.Size = UDim2.new(0, 48, 0, 48); icon.Position = UDim2.new(0, 24, 0, 24)
        icon.BackgroundTransparency = 1; icon.Font = Enum.Font.GothamBlack
        icon.TextSize = 42; icon.TextColor3 = Color3.fromRGB(255, 90, 90); icon.Text = "!"
        local msg = Instance.new("TextLabel", frame)
        msg.Size = UDim2.new(1, -100, 0, 120); msg.Position = UDim2.new(0, 90, 0, 30)
        msg.BackgroundTransparency = 1; msg.Font = Enum.Font.GothamSemibold; msg.TextSize = 15
        msg.TextColor3 = Color3.fromRGB(220, 220, 220); msg.TextXAlignment = Enum.TextXAlignment.Left
        msg.TextYAlignment = Enum.TextYAlignment.Top; msg.TextWrapped = true
        msg.Text = "VanillaHub is made exclusively for Lumber Tycoon 2 (Place ID: 13822889).\n\nPlease join Lumber Tycoon 2 and re-execute the script there."
        local okBtn = Instance.new("TextButton", frame)
        okBtn.Size = UDim2.new(0, 160, 0, 50); okBtn.Position = UDim2.new(0.5, -80, 1, -70)
        okBtn.BackgroundColor3 = Color3.fromRGB(190, 50, 50); okBtn.BorderSizePixel = 0
        okBtn.Font = Enum.Font.GothamBold; okBtn.TextSize = 17
        okBtn.TextColor3 = Color3.fromRGB(255, 255, 255); okBtn.Text = "I Understand"
        Instance.new("UICorner", okBtn).CornerRadius = UDim.new(0, 12)
        local TS2 = game:GetService("TweenService")
        frame.BackgroundTransparency = 1; msg.TextTransparency = 1; icon.TextTransparency = 1
        okBtn.BackgroundTransparency = 1; okBtn.TextTransparency = 1
        TS2:Create(frame, TweenInfo.new(0.75, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.25}):Play()
        TS2:Create(msg,   TweenInfo.new(0.85, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
        TS2:Create(icon,  TweenInfo.new(0.85, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
        TS2:Create(okBtn, TweenInfo.new(0.95, Enum.EasingStyle.Quint), {BackgroundTransparency = 0, TextTransparency = 0}):Play()
        okBtn.MouseButton1Click:Connect(function()
            local ot = TS2:Create(frame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {BackgroundTransparency = 1})
            ot:Play()
            TS2:Create(msg,   TweenInfo.new(0.8), {TextTransparency = 1}):Play()
            TS2:Create(icon,  TweenInfo.new(0.8), {TextTransparency = 1}):Play()
            TS2:Create(okBtn, TweenInfo.new(0.8), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
            ot.Completed:Connect(function() if warnGui and warnGui.Parent then warnGui:Destroy() end end)
        end)
    end)
    return
end

-- ════════════════════════════════════════════════════
-- SERVICES & PLAYER
-- ════════════════════════════════════════════════════
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TeleportService   = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats             = game:GetService("Stats")
local Lighting          = game:GetService("Lighting")
local player            = Players.LocalPlayer
local mouse             = player:GetMouse()

-- ════════════════════════════════════════════════════
-- THEME
-- ════════════════════════════════════════════════════
local THEME_TEXT   = Color3.fromRGB(220, 220, 220)
local BTN_COLOR    = Color3.fromRGB(32, 32, 36)
local BTN_HOVER    = Color3.fromRGB(52, 52, 58)
local ACCENT       = Color3.fromRGB(100, 100, 115)
local BG_DARK      = Color3.fromRGB(10, 10, 11)
local BG_SIDE      = Color3.fromRGB(8, 8, 9)
local BG_TOP       = Color3.fromRGB(12, 12, 14)
local BORDER_COLOR = Color3.fromRGB(40, 40, 45)
local SEP_COLOR    = Color3.fromRGB(35, 35, 40)
local SECTION_TEXT = Color3.fromRGB(110, 110, 120)
local CAT_TEXT     = Color3.fromRGB(70, 70, 82)

-- ════════════════════════════════════════════════════
-- EXECUTOR DETECTION
-- ════════════════════════════════════════════════════
local function detectExecutor()
    if syn and syn.request then return "Synapse X"
    elseif KRNL_LOADED then return "Krnl"
    elseif SENTINEL_V2 then return "Sentinel"
    elseif pebc_execute then return "ProtoSmasher"
    elseif getgenv and getgenv().Script_Builder then return "Script-Ware"
    elseif fluxus then return "Fluxus"
    elseif type(Drawing) == "table" then
        if identifyexecutor then
            local n = identifyexecutor()
            if n and n ~= "" then return n end
        end
        if typeof(gethui) == "function" then return "Electron / Generic" end
        return "Unknown Executor"
    elseif identifyexecutor then
        local n = identifyexecutor()
        if n and n ~= "" then return n end
        return "Unknown Executor"
    end
    return "Unknown / Studio"
end

-- ════════════════════════════════════════════════════
-- CLEANUP REGISTRY
-- ════════════════════════════════════════════════════
local cleanupTasks = {}
local butterRunning = false
local butterThread  = nil

local function onExit()
    butterRunning = false
    if butterThread then pcall(task.cancel, butterThread); butterThread = nil end
    if _G.VH and _G.VH.butter then
        _G.VH.butter.running = false
        if _G.VH.butter.thread then pcall(task.cancel, _G.VH.butter.thread); _G.VH.butter.thread = nil end
    end
    for _, fn in ipairs(cleanupTasks) do pcall(fn) end
    cleanupTasks = {}
    pcall(function()
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum then
            hum.PlatformStand = false
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end
        if hrp then
            for _, obj in ipairs(hrp:GetChildren()) do
                if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") then
                    pcall(function() obj:Destroy() end)
                end
            end
        end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide = true end) end
        end
    end)
    pcall(function()
        if workspace:FindFirstChild("VanillaHubTpCircle") then
            workspace.VanillaHubTpCircle:Destroy()
        end
    end)
    pcall(function()
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name == "WalkWaterPlane" then obj:Destroy() end
        end
    end)
    _G.VH = nil
    _G.VanillaHubCleanup = nil
end

-- ════════════════════════════════════════════════════
-- GUI SCAFFOLD
-- ════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name = "VanillaHub"; gui.Parent = game.CoreGui; gui.ResetOnSpawn = false
table.insert(cleanupTasks, function() if gui and gui.Parent then gui:Destroy() end end)

_G.VanillaHubCleanup = onExit

local wrapper = Instance.new("Frame", gui)
wrapper.Size = UDim2.new(0, 0, 0, 0)
wrapper.Position = UDim2.new(0.5, -265, 0.5, -175)
wrapper.BackgroundTransparency = 1
wrapper.BorderSizePixel = 0
wrapper.ClipsDescendants = false

local main = Instance.new("Frame", wrapper)
main.Size = UDim2.new(0, 0, 0, 0)
main.Position = UDim2.new(0, 0, 0, 0)
main.BackgroundColor3 = BG_DARK
main.BackgroundTransparency = 1
main.BorderSizePixel = 0
main.ClipsDescendants = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = BORDER_COLOR
mainStroke.Thickness = 1.2
mainStroke.Transparency = 0.3

TweenService:Create(wrapper, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 540, 0, 360)
}):Play()
TweenService:Create(main, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 540, 0, 360),
    BackgroundTransparency = 0
}):Play()

-- TOP BAR
local topBar = Instance.new("Frame", main)
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = BG_TOP
topBar.BorderSizePixel = 0
topBar.ZIndex = 4

local topBarSep = Instance.new("Frame", topBar)
topBarSep.Size = UDim2.new(1, 0, 0, 1)
topBarSep.Position = UDim2.new(0, 0, 1, -1)
topBarSep.BackgroundColor3 = SEP_COLOR
topBarSep.BorderSizePixel = 0
topBarSep.ZIndex = 5

-- Forward declarations so topBar back button can reference them
local showMenuPage
local switchTab
local isOnMenuPage = true

local hubIcon = Instance.new("ImageLabel", topBar)
hubIcon.Size = UDim2.new(0, 26, 0, 26); hubIcon.Position = UDim2.new(0, 9, 0.5, -13)
hubIcon.BackgroundTransparency = 1; hubIcon.BorderSizePixel = 0
hubIcon.ScaleType = Enum.ScaleType.Fit; hubIcon.ZIndex = 6
hubIcon.Image = "rbxassetid://97128823316544"
Instance.new("UICorner", hubIcon).CornerRadius = UDim.new(0, 5)

-- Invisible click region over icon + title for back-to-menu
-- (handled via InputBegan below, not a TextButton overlay)

local titleLbl = Instance.new("TextLabel", topBar)
titleLbl.Size = UDim2.new(1, -110, 1, 0); titleLbl.Position = UDim2.new(0, 44, 0, 0)
titleLbl.BackgroundTransparency = 1; titleLbl.Text = "VanillaHub | LT2"
titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 15
titleLbl.TextColor3 = THEME_TEXT; titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.ZIndex = 5

local versionLbl = Instance.new("TextLabel", topBar)
versionLbl.Size = UDim2.new(0, 52, 0, 20); versionLbl.Position = UDim2.new(1, -60, 0.5, -10)
versionLbl.BackgroundTransparency = 1; versionLbl.Text = "v1.1.0"
versionLbl.Font = Enum.Font.Gotham; versionLbl.TextSize = 11
versionLbl.TextColor3 = Color3.fromRGB(100, 100, 115); versionLbl.TextXAlignment = Enum.TextXAlignment.Right
versionLbl.ZIndex = 5

-- DRAG + BACK BUTTON (combined topBar handler)
local dragging, dragStart, startPos = false, nil, nil
local clickStartPos = nil

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        clickStartPos = input.Position
        -- Check if click is within the back region (icon + title, left 180px)
        local relX = input.Position.X - topBar.AbsolutePosition.X
        if relX <= 180 then
            -- Will handle as back click on InputEnded if not dragged
            return
        end
        dragging = true; dragStart = input.Position; startPos = wrapper.Position
    end
end)

topBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and clickStartPos then
        local relX = clickStartPos.X - topBar.AbsolutePosition.X
        local moved = (input.Position - clickStartPos).Magnitude
        if relX <= 180 and moved < 6 then
            if showMenuPage then showMenuPage() end
        end
        clickStartPos = nil
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        wrapper.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- ════════════════════════════════════════════════════
-- SIDE PANEL
-- ════════════════════════════════════════════════════
local side = Instance.new("ScrollingFrame", main)
side.Size = UDim2.new(0, 155, 1, -40)
side.Position = UDim2.new(0, 0, 0, 40)
side.BackgroundColor3 = BG_SIDE
side.BorderSizePixel = 0
side.ScrollBarThickness = 3
side.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 68)
side.CanvasSize = UDim2.new(0, 0, 0, 0)

local sidePad = Instance.new("UIPadding", side)
sidePad.PaddingTop = UDim.new(0, 6)
sidePad.PaddingBottom = UDim.new(0, 6)
sidePad.PaddingLeft = UDim.new(0, 8)
sidePad.PaddingRight = UDim.new(0, 8)

local sideLayout = Instance.new("UIListLayout", side)
sideLayout.Padding = UDim.new(0, 2)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    side.CanvasSize = UDim2.new(0, 0, 0, sideLayout.AbsoluteContentSize.Y + 20)
end)

local sideSep = Instance.new("Frame", main)
sideSep.Size = UDim2.new(0, 1, 1, -40)
sideSep.Position = UDim2.new(0, 155, 0, 40)
sideSep.BackgroundColor3 = SEP_COLOR
sideSep.BorderSizePixel = 0
sideSep.ZIndex = 3

-- CONTENT AREA
local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, -156, 1, -40)
content.Position = UDim2.new(0, 156, 0, 40)
content.BackgroundColor3 = BG_DARK
content.BorderSizePixel = 0

-- ════════════════════════════════════════════════════
-- CATEGORY LABEL HELPER (removed - no categories)
-- ════════════════════════════════════════════════════
-- (intentionally empty)

-- ════════════════════════════════════════════════════
-- WELCOME POPUP
-- ════════════════════════════════════════════════════
task.spawn(function()
    task.wait(0.8)
    if not (gui and gui.Parent) then return end
    local wf = Instance.new("Frame", gui)
    wf.Size = UDim2.new(0, 380, 0, 90); wf.Position = UDim2.new(0.5, -190, 1, -110)
    wf.BackgroundColor3 = Color3.fromRGB(14, 14, 16); wf.BackgroundTransparency = 1; wf.BorderSizePixel = 0
    Instance.new("UICorner", wf).CornerRadius = UDim.new(0, 14)
    local ws = Instance.new("UIStroke", wf)
    ws.Color = BORDER_COLOR; ws.Thickness = 1.2; ws.Transparency = 0.4
    local pfp = Instance.new("ImageLabel", wf)
    pfp.Size = UDim2.new(0, 64, 0, 64); pfp.Position = UDim2.new(0, 20, 0.5, -32)
    pfp.BackgroundTransparency = 1; pfp.ImageTransparency = 1
    pfp.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    Instance.new("UICorner", pfp).CornerRadius = UDim.new(1, 0)
    local wt = Instance.new("TextLabel", wf)
    wt.Size = UDim2.new(1, -110, 1, -20); wt.Position = UDim2.new(0, 100, 0, 10)
    wt.BackgroundTransparency = 1; wt.Font = Enum.Font.GothamSemibold; wt.TextSize = 18
    wt.TextColor3 = THEME_TEXT; wt.TextXAlignment = Enum.TextXAlignment.Left
    wt.TextYAlignment = Enum.TextYAlignment.Center; wt.TextWrapped = true; wt.TextTransparency = 1
    wt.Text = "You're back, " .. player.DisplayName .. ".\nVanillaHub is ready to use."
    TweenService:Create(wf, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.25}):Play()
    TweenService:Create(wt, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
    TweenService:Create(pfp, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {ImageTransparency = 0}):Play()
    task.delay(7, function()
        if not (wf and wf.Parent) then return end
        local ot = TweenService:Create(wf, TweenInfo.new(1.2, Enum.EasingStyle.Quint), {BackgroundTransparency = 1})
        ot:Play()
        TweenService:Create(wt, TweenInfo.new(1.2), {TextTransparency = 1}):Play()
        TweenService:Create(pfp, TweenInfo.new(1.2), {ImageTransparency = 1}):Play()
        ot.Completed:Connect(function() if wf and wf.Parent then wf:Destroy() end end)
    end)
end)

-- ════════════════════════════════════════════════════
-- TABS DEFINITION (ordered with category grouping)
-- ════════════════════════════════════════════════════
--[[
    Categories:
      CORE        → Home, Settings
      CHARACTER   → Player
      WORLD       → World, Teleport
      ITEMS & ECO → Item, Wood, Slot, Dupe, Sorter, AutoBuy
      CREATIVE    → Pixel Art, Build
      UTILITY     → Vehicle, Search
]]

local tabCategories = {
    { category = "Core",          tabs = {"Home", "Settings"} },
    { category = "Character",     tabs = {"Player"} },
    { category = "World",         tabs = {"World", "Teleport"} },
    { category = "Items & Eco",   tabs = {"Item", "Wood", "Slot", "Dupe", "Sorter", "AutoBuy"} },
    { category = "Creative",      tabs = {"Pixel Art", "Build"} },
    { category = "Utility",       tabs = {"Vehicle", "Search"} },
}

-- Flat ordered tab list (for page creation etc.)
local tabs = {}
for _, group in ipairs(tabCategories) do
    for _, t in ipairs(group.tabs) do
        table.insert(tabs, t)
    end
end

local pages = {}

-- ── MENU PAGE (icon grid shown on launch) ──────────────
local menuPage = Instance.new("Frame", content)
menuPage.Name = "MenuPage"
menuPage.Size = UDim2.new(1, 0, 1, 0)
menuPage.BackgroundTransparency = 1
menuPage.BorderSizePixel = 0
menuPage.Visible = true
pages["MenuPage"] = menuPage

for _, name in ipairs(tabs) do
    local page = Instance.new("ScrollingFrame", content)
    page.Name = name .. "Tab"; page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1; page.BorderSizePixel = 0
    page.ScrollBarThickness = 4; page.ScrollBarImageColor3 = Color3.fromRGB(55, 55, 62)
    page.Visible = false; page.CanvasSize = UDim2.new(0, 0, 0, 0)
    local list = Instance.new("UIListLayout", page)
    list.Padding = UDim.new(0, 10); list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.SortOrder = Enum.SortOrder.LayoutOrder
    local pad = Instance.new("UIPadding", page)
    pad.PaddingTop = UDim.new(0, 14); pad.PaddingBottom = UDim.new(0, 14)
    pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12)
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 32)
    end)
    pages[name .. "Tab"] = page
end

-- TAB SWITCHING
local activeTabButton = nil

showMenuPage = function()
    isOnMenuPage = true
    for _, page in pairs(pages) do
        page.Visible = (page.Name == "MenuPage")
    end
    if activeTabButton then
        TweenService:Create(activeTabButton, TweenInfo.new(0.22), {
            BackgroundColor3 = Color3.fromRGB(16, 16, 18),
            TextColor3 = Color3.fromRGB(110, 110, 120)
        }):Play()
        activeTabButton = nil
    end
    -- Hide sidebar and separator, expand content to full width
    side.Visible = false
    sideSep.Visible = false
    content.Size = UDim2.new(1, 0, 1, -40)
    content.Position = UDim2.new(0, 0, 0, 40)
    -- Also resize menuPage to fill the full content
    menuPage.Size = UDim2.new(1, 0, 1, 0)
    TweenService:Create(titleLbl, TweenInfo.new(0.2), {TextColor3 = THEME_TEXT}):Play()
end

switchTab = function(targetName)
    isOnMenuPage = false
    for _, page in pairs(pages) do page.Visible = (page.Name == targetName) end
    if activeTabButton then
        TweenService:Create(activeTabButton, TweenInfo.new(0.22), {
            BackgroundColor3 = Color3.fromRGB(16, 16, 18),
            TextColor3 = Color3.fromRGB(110, 110, 120)
        }):Play()
    end
    -- Show sidebar and separator, restore content area
    side.Visible = true
    sideSep.Visible = true
    content.Size = UDim2.new(1, -156, 1, -40)
    content.Position = UDim2.new(0, 156, 0, 40)
    local btn = side:FindFirstChild(targetName:gsub("Tab",""))
    if btn then
        activeTabButton = btn
        TweenService:Create(btn, TweenInfo.new(0.22), {
            BackgroundColor3 = Color3.fromRGB(42, 42, 48),
            TextColor3 = THEME_TEXT
        }):Play()
    end
    TweenService:Create(titleLbl, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(160, 160, 175)}):Play()
end

-- BUILD FLAT SIDEBAR (no categories)
for _, name in ipairs(tabs) do
    local btn = Instance.new("TextButton", side)
    btn.Name = name
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(110, 110, 120)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local btnPad = Instance.new("UIPadding", btn)
    btnPad.PaddingLeft = UDim.new(0, 12)
    btn.MouseEnter:Connect(function()
        if activeTabButton ~= btn then
            TweenService:Create(btn, TweenInfo.new(0.18), {
                BackgroundColor3 = Color3.fromRGB(28, 28, 32),
                TextColor3 = Color3.fromRGB(175, 175, 185)
            }):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeTabButton ~= btn then
            TweenService:Create(btn, TweenInfo.new(0.18), {
                BackgroundColor3 = Color3.fromRGB(16, 16, 18),
                TextColor3 = Color3.fromRGB(110, 110, 120)
            }):Play()
        end
    end)
    btn.MouseButton1Click:Connect(function() switchTab(name.."Tab") end)
end

showMenuPage()

-- ════════════════════════════════════════════════════
-- GUI TOGGLE
-- ════════════════════════════════════════════════════
local currentToggleKey = Enum.KeyCode.LeftAlt
local guiOpen = true
local isAnimatingGUI = false
local keybindButtonGUI

local function toggleGUI()
    if isAnimatingGUI then return end
    guiOpen = not guiOpen; isAnimatingGUI = true
    if guiOpen then
        main.Visible = true
        main.Size = UDim2.new(0, 0, 0, 0)
        main.BackgroundTransparency = 1
        wrapper.Size = UDim2.new(0, 0, 0, 0)
        local t = TweenService:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 540, 0, 360),
            BackgroundTransparency = 0
        })
        TweenService:Create(wrapper, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 540, 0, 360)
        }):Play()
        t:Play()
        t.Completed:Connect(function() isAnimatingGUI = false end)
    else
        local t = TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        })
        TweenService:Create(wrapper, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        t:Play()
        t.Completed:Connect(function()
            main.Visible = false
            isAnimatingGUI = false
        end)
    end
end

-- ════════════════════════════════════════════════════
-- MENU PAGE (launch grid)
-- ════════════════════════════════════════════════════
do
    -- Title
    local menuTitle = Instance.new("TextLabel", menuPage)
    menuTitle.Size = UDim2.new(1, 0, 0, 36)
    menuTitle.Position = UDim2.new(0, 0, 0, 10)
    menuTitle.BackgroundTransparency = 1
    menuTitle.Font = Enum.Font.GothamBold
    menuTitle.TextSize = 18
    menuTitle.TextColor3 = THEME_TEXT
    menuTitle.TextXAlignment = Enum.TextXAlignment.Center
    menuTitle.Text = "VanillaHub"

    local menuSub = Instance.new("TextLabel", menuPage)
    menuSub.Size = UDim2.new(1, 0, 0, 16)
    menuSub.Position = UDim2.new(0, 0, 0, 44)
    menuSub.BackgroundTransparency = 1
    menuSub.Font = Enum.Font.Gotham
    menuSub.TextSize = 11
    menuSub.TextColor3 = Color3.fromRGB(90, 90, 105)
    menuSub.TextXAlignment = Enum.TextXAlignment.Center
    menuSub.Text = "Lumber Tycoon 2  •  v1.1.0"

    -- 8 icon tiles: the most useful tabs
    local menuTiles = {
        { name = "Home",     color = Color3.fromRGB(180, 60,  55),  icon = "🏠" },
        { name = "Player",   color = Color3.fromRGB(55,  100, 190), icon = "👤" },
        { name = "World",    color = Color3.fromRGB(160, 100, 40),  icon = "🌍" },
        { name = "Teleport", color = Color3.fromRGB(40,  140, 80),  icon = "📍" },
        { name = "AutoBuy",  color = Color3.fromRGB(185, 155, 30),  icon = "🛒" },
        { name = "Slot",     color = Color3.fromRGB(120, 55,  175), icon = "🔲" },
        { name = "Wood",     color = Color3.fromRGB(45,  110, 80),  icon = "🌲" },
        { name = "Dupe",     color = Color3.fromRGB(160, 50,  145), icon = "♊" },
    }

    local gridHolder = Instance.new("Frame", menuPage)
    gridHolder.Size = UDim2.new(1, -32, 0, 220)
    gridHolder.Position = UDim2.new(0, 16, 0, 68)
    gridHolder.BackgroundTransparency = 1

    local grid = Instance.new("UIGridLayout", gridHolder)
    grid.CellSize = UDim2.new(0, 110, 0, 100)
    grid.CellPadding = UDim2.new(0, 10, 0, 10)
    grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
    grid.VerticalAlignment = Enum.VerticalAlignment.Top
    grid.SortOrder = Enum.SortOrder.LayoutOrder

    for i, tile in ipairs(menuTiles) do
        local cell = Instance.new("TextButton", gridHolder)
        cell.LayoutOrder = i
        cell.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
        cell.BorderSizePixel = 0
        cell.Text = ""
        cell.AutoButtonColor = false
        Instance.new("UICorner", cell).CornerRadius = UDim.new(0, 12)
        local cellStroke = Instance.new("UIStroke", cell)
        cellStroke.Color = BORDER_COLOR
        cellStroke.Thickness = 1
        cellStroke.Transparency = 0.5

        -- Colored icon box
        local iconBox = Instance.new("Frame", cell)
        iconBox.Size = UDim2.new(0, 44, 0, 44)
        iconBox.Position = UDim2.new(0.5, -22, 0, 10)
        iconBox.BackgroundColor3 = tile.color
        iconBox.BorderSizePixel = 0
        Instance.new("UICorner", iconBox).CornerRadius = UDim.new(0, 10)

        local iconLbl = Instance.new("TextLabel", iconBox)
        iconLbl.Size = UDim2.new(1, 0, 1, 0)
        iconLbl.BackgroundTransparency = 1
        iconLbl.Font = Enum.Font.GothamBold
        iconLbl.TextSize = 22
        iconLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        iconLbl.TextXAlignment = Enum.TextXAlignment.Center
        iconLbl.Text = tile.icon

        local nameLbl = Instance.new("TextLabel", cell)
        nameLbl.Size = UDim2.new(1, -4, 0, 18)
        nameLbl.Position = UDim2.new(0, 2, 1, -22)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Font = Enum.Font.GothamSemibold
        nameLbl.TextSize = 12
        nameLbl.TextColor3 = THEME_TEXT
        nameLbl.TextXAlignment = Enum.TextXAlignment.Center
        nameLbl.Text = tile.name

        -- Hover
        cell.MouseEnter:Connect(function()
            TweenService:Create(cell, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(28, 28, 34)}):Play()
            TweenService:Create(iconBox, TweenInfo.new(0.15), {
                BackgroundColor3 = tile.color:Lerp(Color3.fromRGB(255,255,255), 0.15)
            }):Play()
        end)
        cell.MouseLeave:Connect(function()
            TweenService:Create(cell, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18, 18, 22)}):Play()
            TweenService:Create(iconBox, TweenInfo.new(0.15), {BackgroundColor3 = tile.color}):Play()
        end)
        cell.MouseButton1Click:Connect(function()
            switchTab(tile.name .. "Tab")
        end)
    end
end

-- ════════════════════════════════════════════════════
-- HOME TAB
-- ════════════════════════════════════════════════════
local homePage = pages["HomeTab"]

local bubbleRow = Instance.new("Frame", homePage)
bubbleRow.Size = UDim2.new(1, 0, 0, 100); bubbleRow.BackgroundTransparency = 1; bubbleRow.LayoutOrder = 1

local bubbleIcon = Instance.new("ImageLabel", bubbleRow)
bubbleIcon.Size=UDim2.new(0,52,0,52); bubbleIcon.Position=UDim2.new(0,6,0.5,-26)
bubbleIcon.BackgroundColor3=Color3.fromRGB(16,16,18); bubbleIcon.BorderSizePixel=0
bubbleIcon.ScaleType=Enum.ScaleType.Fit; bubbleIcon.Image="rbxassetid://97128823316544"
Instance.new("UICorner", bubbleIcon).CornerRadius = UDim.new(1,0)
local iconStroke = Instance.new("UIStroke", bubbleIcon)
iconStroke.Color=THEME_TEXT; iconStroke.Thickness=1.5; iconStroke.Transparency=0.55

local iconName = Instance.new("TextLabel", bubbleRow)
iconName.Size=UDim2.new(0,64,0,16); iconName.Position=UDim2.new(0,0,0.5,28)
iconName.BackgroundTransparency=1; iconName.Font=Enum.Font.GothamBold; iconName.TextSize=10
iconName.TextColor3=THEME_TEXT; iconName.TextXAlignment=Enum.TextXAlignment.Center; iconName.Text="Vanilla"

local tailShape = Instance.new("Frame", bubbleRow)
tailShape.Size=UDim2.new(0,14,0,14); tailShape.Position=UDim2.new(0,64,0.5,-7)
tailShape.Rotation=45; tailShape.BackgroundColor3=Color3.fromRGB(22,22,26); tailShape.BorderSizePixel=0; tailShape.ZIndex=1

local bubbleBody = Instance.new("Frame", bubbleRow)
bubbleBody.Size=UDim2.new(1,-82,0,84); bubbleBody.Position=UDim2.new(0,72,0.5,-42)
bubbleBody.BackgroundColor3=Color3.fromRGB(22,22,26); bubbleBody.BorderSizePixel=0; bubbleBody.ZIndex=2
Instance.new("UICorner", bubbleBody).CornerRadius=UDim.new(0,14)
local bubbleStroke=Instance.new("UIStroke",bubbleBody)
bubbleStroke.Color=BORDER_COLOR; bubbleStroke.Thickness=1.2; bubbleStroke.Transparency=0.4
local bubbleGreeting=Instance.new("TextLabel",bubbleBody)
bubbleGreeting.Size=UDim2.new(1,-20,0,28); bubbleGreeting.Position=UDim2.new(0,14,0,10)
bubbleGreeting.BackgroundTransparency=1; bubbleGreeting.Font=Enum.Font.GothamBold; bubbleGreeting.TextSize=15
bubbleGreeting.TextColor3=THEME_TEXT; bubbleGreeting.TextXAlignment=Enum.TextXAlignment.Left
bubbleGreeting.TextTruncate=Enum.TextTruncate.AtEnd; bubbleGreeting.ClipsDescendants=false
bubbleGreeting.Text="Hey, "..player.DisplayName.." ♡"; bubbleGreeting.ZIndex=3
local bubbleMsg=Instance.new("TextLabel",bubbleBody)
bubbleMsg.Size=UDim2.new(1,-20,0,36); bubbleMsg.Position=UDim2.new(0,14,0,38)
bubbleMsg.BackgroundTransparency=1; bubbleMsg.Font=Enum.Font.Gotham; bubbleMsg.TextSize=13
bubbleMsg.TextColor3=Color3.fromRGB(170,170,180); bubbleMsg.TextXAlignment=Enum.TextXAlignment.Left
bubbleMsg.TextYAlignment=Enum.TextYAlignment.Top; bubbleMsg.TextWrapped=true
bubbleMsg.Text="Welcome back, "..player.DisplayName.."!\nSo glad you're here. Let's get to it 🌿"; bubbleMsg.ZIndex=3

-- STATS GRID
local statsContainer = Instance.new("Frame", homePage)
statsContainer.Size=UDim2.new(1,0,0,160); statsContainer.BackgroundTransparency=1
statsContainer.LayoutOrder = 2
local gridLayout=Instance.new("UIGridLayout",statsContainer)
gridLayout.CellSize=UDim2.new(0,148,0,36); gridLayout.CellPadding=UDim2.new(0,8,0,8)
gridLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center; gridLayout.SortOrder=Enum.SortOrder.LayoutOrder

local function createStatusBox(text, color)
    local box=Instance.new("Frame",statsContainer)
    box.BackgroundColor3=Color3.fromRGB(16,16,20); box.BorderSizePixel=0
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,7)
    local stroke = Instance.new("UIStroke", box)
    stroke.Color = SEP_COLOR; stroke.Thickness = 1; stroke.Transparency = 0.55
    local lbl=Instance.new("TextLabel",box)
    lbl.Size=UDim2.new(1,-10,1,-4); lbl.Position=UDim2.new(0,5,0,2)
    lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.Gotham; lbl.TextSize=12
    lbl.TextColor3=color or THEME_TEXT; lbl.Text=text; lbl.TextWrapped=true
    lbl.TextXAlignment=Enum.TextXAlignment.Center; lbl.TextTruncate=Enum.TextTruncate.AtEnd
    return lbl
end

local pingLabel   = createStatusBox("Ping: …")
local lagLabel    = createStatusBox("Lag: …", Color3.fromRGB(160, 160, 170))
createStatusBox("Acc Age: "..player.AccountAge.."d")
local execLabel   = createStatusBox("Exec: detecting…", Color3.fromRGB(175, 175, 185))
local uptimeLabel = createStatusBox("Uptime: …", Color3.fromRGB(160, 200, 160))

local rejoinBtn=Instance.new("TextButton",statsContainer)
rejoinBtn.Size=UDim2.new(0,148,0,36); rejoinBtn.BackgroundColor3=Color3.fromRGB(16,16,20); rejoinBtn.BorderSizePixel=0
rejoinBtn.Font=Enum.Font.Gotham; rejoinBtn.TextSize=13; rejoinBtn.TextColor3=THEME_TEXT; rejoinBtn.Text="Rejoin"
Instance.new("UICorner",rejoinBtn).CornerRadius=UDim.new(0,7)
local rjStroke = Instance.new("UIStroke", rejoinBtn)
rjStroke.Color = SEP_COLOR; rjStroke.Thickness = 1; rjStroke.Transparency = 0.55
rejoinBtn.MouseEnter:Connect(function() TweenService:Create(rejoinBtn,TweenInfo.new(0.18),{BackgroundColor3=BTN_HOVER}):Play() end)
rejoinBtn.MouseLeave:Connect(function() TweenService:Create(rejoinBtn,TweenInfo.new(0.18),{BackgroundColor3=Color3.fromRGB(16,16,20)}):Play() end)
rejoinBtn.MouseButton1Click:Connect(function() pcall(function() TeleportService:Teleport(game.PlaceId,player) end) end)

local pingConn = RunService.Heartbeat:Connect(function()
    local ok, ping = pcall(function() return math.round(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
    pingLabel.Text = ok and ("Ping: "..ping.." ms") or "Ping: N/A"
end)
table.insert(cleanupTasks, function() if pingConn then pingConn:Disconnect(); pingConn=nil end end)

local _serverAgeSnapshot = 0
local _loadClock = os.clock()
pcall(function() _serverAgeSnapshot = workspace.DistributedGameTime end)

local uptimeThread
uptimeThread = task.spawn(function()
    while gui and gui.Parent do
        pcall(function()
            local elapsed = os.clock() - _loadClock
            local secs = math.floor(_serverAgeSnapshot + elapsed)
            local h = math.floor(secs / 3600)
            local m = math.floor((secs % 3600) / 60)
            local s = secs % 60
            local upStr
            if h > 0 then upStr = string.format("%dh %02dm", h, m)
            elseif m > 0 then upStr = string.format("%dm %02ds", m, s)
            else upStr = string.format("%ds", s) end
            if uptimeLabel and uptimeLabel.Parent then uptimeLabel.Text = "Server: " .. upStr end
        end)
        task.wait(1)
    end
end)
table.insert(cleanupTasks, function()
    if uptimeThread then pcall(task.cancel, uptimeThread); uptimeThread = nil end
end)

task.delay(1, function()
    local execName = detectExecutor()
    if execLabel and execLabel.Parent then execLabel.Text = "Exec: " .. execName end
end)

local lagThread
lagThread = task.spawn(function()
    while gui and gui.Parent do
        local ok, ping = pcall(function() return math.round(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        if lagLabel and lagLabel.Parent then
            if ok then
                if ping > 250 then
                    lagLabel.Text = "Bad Ping"; lagLabel.TextColor3 = Color3.fromRGB(240, 100, 100)
                elseif ping > 120 then
                    lagLabel.Text = "High Ping"; lagLabel.TextColor3 = Color3.fromRGB(240, 200, 80)
                else
                    lagLabel.Text = "Good Ping"; lagLabel.TextColor3 = Color3.fromRGB(100, 210, 100)
                end
            else
                lagLabel.Text = "Lag: N/A"
            end
        end
        task.wait(5)
    end
end)
table.insert(cleanupTasks, function()
    if lagThread then pcall(task.cancel, lagThread); lagThread = nil end
end)

-- ════════════════════════════════════════════════════
-- WORLD TAB
-- ════════════════════════════════════════════════════
local worldPage = pages["WorldTab"]

local origClockTime = Lighting.ClockTime
local origFogEnd    = Lighting.FogEnd
local origFogStart  = Lighting.FogStart
local origFogColor  = Lighting.FogColor
local origShadows   = Lighting.GlobalShadows

local dayConn   = nil
local nightConn = nil
local fogConn   = nil

local alwaysDayActive   = true
local alwaysNightActive = false

local function stopDayNight()
    if dayConn   then dayConn:Disconnect();   dayConn   = nil end
    if nightConn then nightConn:Disconnect(); nightConn = nil end
end

local function makeWorldSectionLabel(text)
    local w = Instance.new("Frame", worldPage)
    w.Size = UDim2.new(1, 0, 0, 24); w.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", w)
    lbl.Size = UDim2.new(1, -4, 1, 0); lbl.Position = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 10
    lbl.TextColor3 = SECTION_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "  " .. string.upper(text)
end

local function makeWorldSep()
    local s = Instance.new("Frame", worldPage)
    s.Size = UDim2.new(1, 0, 0, 1)
    s.BackgroundColor3 = SEP_COLOR; s.BorderSizePixel = 0
end

local function makeWorldToggle(labelText, default, callback)
    local frame = Instance.new("Frame", worldPage)
    frame.Size = UDim2.new(1, 0, 0, 36)
    frame.BackgroundColor3 = Color3.fromRGB(16, 16, 20); frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -54, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = labelText
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local tb = Instance.new("TextButton", frame)
    tb.Size = UDim2.new(0, 36, 0, 20); tb.Position = UDim2.new(1, -46, 0.5, -10)
    tb.BackgroundColor3 = default and Color3.fromRGB(80, 160, 80) or Color3.fromRGB(38, 38, 45)
    tb.Text = ""; tb.BorderSizePixel = 0
    Instance.new("UICorner", tb).CornerRadius = UDim.new(1, 0)
    local circle = Instance.new("Frame", tb)
    circle.Size = UDim2.new(0, 14, 0, 14)
    circle.Position = UDim2.new(0, default and 20 or 2, 0.5, -7)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255); circle.BorderSizePixel = 0
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    local toggled = default
    local function setState(val)
        toggled = val
        TweenService:Create(tb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            BackgroundColor3 = val and Color3.fromRGB(80, 160, 80) or Color3.fromRGB(38, 38, 45)
        }):Play()
        TweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, val and 20 or 2, 0.5, -7)
        }):Play()
    end
    tb.MouseButton1Click:Connect(function()
        toggled = not toggled
        setState(toggled)
        if callback then callback(toggled) end
    end)
    return frame, setState
end

makeWorldSectionLabel("Environment")

local setDayState
local setNightState

local _, _setDay = makeWorldToggle("Always Day", true, function(v)
    alwaysDayActive = v
    if v then
        alwaysNightActive = false
        if setNightState then setNightState(false) end
        stopDayNight()
        Lighting.ClockTime = 14
        dayConn = RunService.Heartbeat:Connect(function() Lighting.ClockTime = 14 end)
    else
        stopDayNight()
        Lighting.ClockTime = origClockTime
    end
end)
setDayState = _setDay

local _, _setNight = makeWorldToggle("Always Night", false, function(v)
    alwaysNightActive = v
    if v then
        alwaysDayActive = false
        if setDayState then setDayState(false) end
        stopDayNight()
        Lighting.ClockTime = 0
        nightConn = RunService.Heartbeat:Connect(function() Lighting.ClockTime = 0 end)
    else
        stopDayNight()
        Lighting.ClockTime = origClockTime
    end
end)
setNightState = _setNight

stopDayNight()
Lighting.ClockTime = 14
dayConn = RunService.Heartbeat:Connect(function() Lighting.ClockTime = 14 end)

makeWorldToggle("Remove Fog", false, function(v)
    if fogConn then fogConn:Disconnect(); fogConn = nil end
    if v then
        Lighting.FogEnd   = 1e9
        Lighting.FogStart = 1e9
        fogConn = RunService.Heartbeat:Connect(function()
            Lighting.FogEnd   = 1e9
            Lighting.FogStart = 1e9
        end)
    else
        Lighting.FogEnd   = origFogEnd
        Lighting.FogStart = origFogStart
        Lighting.FogColor = origFogColor
    end
end)

makeWorldToggle("Shadows", true, function(v)
    Lighting.GlobalShadows = v
end)

makeWorldSep()
makeWorldSectionLabel("Water")

local walkOnWaterConn  = nil
local walkOnWaterParts = {}

local function removeWalkWater()
    if walkOnWaterConn then walkOnWaterConn:Disconnect(); walkOnWaterConn = nil end
    for _, p in ipairs(walkOnWaterParts) do
        if p and p.Parent then p:Destroy() end
    end
    walkOnWaterParts = {}
end

makeWorldToggle("Walk On Water", false, function(v)
    removeWalkWater()
    if v then
        local function makeSolid(part)
            if part:IsA("Part") and part.Name == "Water" then
                local clone = Instance.new("Part")
                clone.Size         = part.Size
                clone.CFrame       = part.CFrame
                clone.Anchored     = true
                clone.CanCollide   = true
                clone.Transparency = 1
                clone.Name         = "WalkWaterPlane"
                clone.Parent       = workspace
                table.insert(walkOnWaterParts, clone)
            end
        end
        for _, p in ipairs(workspace:GetDescendants()) do makeSolid(p) end
        walkOnWaterConn = workspace.DescendantAdded:Connect(makeSolid)
    end
end)

makeWorldToggle("Remove Water", false, function(v)
    for _, p in ipairs(workspace:GetDescendants()) do
        if p:IsA("Part") and p.Name == "Water" then
            p.Transparency = v and 1 or 0.5
            p.CanCollide   = false
        end
    end
end)

makeWorldSep()
makeWorldSectionLabel("World")

table.insert(cleanupTasks, function()
    stopDayNight()
    if fogConn then fogConn:Disconnect(); fogConn = nil end
    removeWalkWater()
    Lighting.ClockTime     = origClockTime
    Lighting.FogEnd        = origFogEnd
    Lighting.FogStart      = origFogStart
    Lighting.FogColor      = origFogColor
    Lighting.GlobalShadows = origShadows
end)

-- ════════════════════════════════════════════════════
-- TELEPORT TAB
-- ════════════════════════════════════════════════════
local teleportPage = pages["TeleportTab"]

local locations = {
    {name="Spawn",x=172,y=3,z=74},{name="The Den",x=323,y=41.8,z=1930},
    {name="LightHouse",x=1464.8,y=355.25,z=3257.2},{name="Safari",x=111.85,y=11,z=-998.8},
    {name="Bridge",x=112.31,y=11,z=-782.36},{name="Bob's Shack",x=260,y=8.4,z=-2542},
    {name="EndTimesCave",x=113,y=-213,z=-951},{name="The Swamp",x=-1209,y=132.32,z=-801},
    {name="The Cabin",x=1244,y=63.6,z=2306},{name="Volcano",x=-1585,y=622.8,z=1140},
    {name="Boxed Cars",x=509,y=3.2,z=-1463},{name="Tiaga Peak",x=1560,y=410.32,z=3274},
    {name="Land Store",x=258,y=3.2,z=-99},{name="Link's Logic",x=4605,y=3,z=-727},
    {name="Palm Island",x=2549,y=-5.9,z=-42},{name="Palm Island 2",x=1960,y=-5.9,z=-1501},
    {name="Palm Island 3",x=4344,y=-5.9,z=-1813},{name="Fine Art Shop",x=5207,y=-166.2,z=719},
    {name="SnowGlow Biome",x=-1086.85,y=-5.9,z=-945.32},{name="Cave",x=3581,y=-179.54,z=430},
    {name="Shrine Of Sight",x=-1600,y=195.4,z=919},{name="Fancy Furnishings",x=491,y=3.2,z=-1720},
    {name="Docks",x=1114,y=-1.2,z=-197},{name="Strange Man",x=1061,y=16.8,z=1131},
    {name="Wood Dropoff",x=323.41,y=-2.8,z=134.73},{name="Snow Biome",x=889.96,y=59.8,z=1195.55},
    {name="Wood RU's",x=265,y=3.2,z=57},{name="Green Box",x=-1668.05,y=349.6,z=1475.39},
    {name="Cherry Meadow",x=220.9,y=59.8,z=1305.8},{name="Bird Cave",x=4813.1,y=17.7,z=-978.8},
}

local tpGrid = Instance.new("Frame", teleportPage)
tpGrid.Size = UDim2.new(1, 0, 0, math.ceil(#locations / 2) * 34 + math.ceil(#locations / 2) * 6)
tpGrid.BackgroundTransparency = 1
local tpUIGrid = Instance.new("UIGridLayout", tpGrid)
tpUIGrid.CellSize = UDim2.new(0.5, -5, 0, 30)
tpUIGrid.CellPadding = UDim2.new(0, 6, 0, 6)
tpUIGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left
tpUIGrid.SortOrder = Enum.SortOrder.LayoutOrder

for i, loc in ipairs(locations) do
    local btn = Instance.new("TextButton", tpGrid)
    btn.LayoutOrder = i
    btn.BackgroundColor3 = BTN_COLOR; btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 12
    btn.TextColor3 = THEME_TEXT; btn.Text = loc.name
    btn.TextTruncate = Enum.TextTruncate.AtEnd
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=BTN_HOVER,TextColor3=Color3.fromRGB(255,255,255)}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=BTN_COLOR,TextColor3=THEME_TEXT}):Play() end)
    btn.MouseButton1Click:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(loc.x, loc.y + 3, loc.z)
        end
    end)
end

-- ════════════════════════════════════════════════════
-- SHARED ITEM/DUPE STATE
-- ════════════════════════════════════════════════════
local tpCircle    = nil
local tpItemSpeed = 0.3

-- ════════════════════════════════════════════════════
-- ITEM TAB
-- ════════════════════════════════════════════════════
local itemPage = pages["ItemTab"]
local itemPageList = itemPage:FindFirstChildOfClass("UIListLayout")
if itemPageList then itemPageList.Padding = UDim.new(0, 8) end

local clickSelectEnabled  = false
local lassoEnabled        = false
local groupSelectEnabled  = false
local isTeleportingItems  = false
local stopTeleportItems   = false

local function iSectionLabel(text)
    local w = Instance.new("Frame", itemPage)
    w.Size = UDim2.new(1, 0, 0, 24); w.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", w)
    lbl.Size = UDim2.new(1, -4, 1, 0); lbl.Position = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 10
    lbl.TextColor3 = SECTION_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "  " .. string.upper(text)
end

local function iSep()
    local sep = Instance.new("Frame", itemPage)
    sep.Size = UDim2.new(1, 0, 0, 1)
    sep.BackgroundColor3 = SEP_COLOR; sep.BorderSizePixel = 0
end

local function iButton(text, cb)
    local btn = Instance.new("TextButton", itemPage)
    btn.Size = UDim2.new(1, 0, 0, 34); btn.BackgroundColor3 = BTN_COLOR
    btn.Text = text; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = THEME_TEXT; btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=BTN_HOVER}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=BTN_COLOR}):Play() end)
    if cb then btn.MouseButton1Click:Connect(cb) end
    return btn
end

local function iToggle(text, default, cb)
    local frame = Instance.new("Frame", itemPage)
    frame.Size = UDim2.new(1, 0, 0, 36); frame.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -54, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13; lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local tb = Instance.new("TextButton", frame)
    tb.Size = UDim2.new(0, 36, 0, 20); tb.Position = UDim2.new(1, -46, 0.5, -10)
    tb.BackgroundColor3 = default and Color3.fromRGB(80,160,80) or Color3.fromRGB(38,38,45)
    tb.Text = ""; tb.BorderSizePixel = 0
    Instance.new("UICorner", tb).CornerRadius = UDim.new(1, 0)
    local circle = Instance.new("Frame", tb)
    circle.Size = UDim2.new(0, 14, 0, 14)
    circle.Position = UDim2.new(0, default and 20 or 2, 0.5, -7)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255); circle.BorderSizePixel = 0
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    local toggled = default
    if cb then cb(toggled) end
    tb.MouseButton1Click:Connect(function()
        toggled = not toggled
        TweenService:Create(tb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            BackgroundColor3 = toggled and Color3.fromRGB(80,160,80) or Color3.fromRGB(38,38,45)
        }):Play()
        TweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, toggled and 20 or 2, 0.5, -7)
        }):Play()
        if cb then cb(toggled) end
    end)
    return frame
end

local function iSlider(text, minV, maxV, defV, cb)
    local frame = Instance.new("Frame", itemPage)
    frame.Size = UDim2.new(1, 0, 0, 54); frame.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local topRow = Instance.new("Frame", frame)
    topRow.Size = UDim2.new(1, -16, 0, 22); topRow.Position = UDim2.new(0, 8, 0, 7)
    topRow.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", topRow)
    lbl.Size = UDim2.new(0.72, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = text
    local valLbl = Instance.new("TextLabel", topRow)
    valLbl.Size = UDim2.new(0.28, 0, 1, 0); valLbl.Position = UDim2.new(0.72, 0, 0, 0)
    valLbl.BackgroundTransparency = 1; valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 13
    valLbl.TextColor3 = Color3.fromRGB(160, 160, 175); valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Text = tostring(defV)
    local track = Instance.new("Frame", frame)
    track.Size = UDim2.new(1, -16, 0, 5); track.Position = UDim2.new(0, 8, 0, 38)
    track.BackgroundColor3 = Color3.fromRGB(32, 32, 38); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((defV-minV)/(maxV-minV), 0, 1, 0)
    fill.BackgroundColor3 = ACCENT; fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0, 14, 0, 14); knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((defV-minV)/(maxV-minV), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(210, 210, 220); knob.Text = ""; knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local ds = false
    local function upd(absX)
        local r = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.round(minV + r * (maxV - minV))
        fill.Size = UDim2.new(r, 0, 1, 0); knob.Position = UDim2.new(r, 0, 0.5, 0)
        valLbl.Text = tostring(v)
        if cb then cb(v) end
    end
    knob.MouseButton1Down:Connect(function() ds = true end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then ds = true; upd(i.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if ds and i.UserInputType == Enum.UserInputType.MouseMovement then upd(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then ds = false end
    end)
end

local function selectPart(part)
    if not part then return end
    if part:FindFirstChild("Selection") then return end
    local sb = Instance.new("SelectionBox", part)
    sb.Name = "Selection"; sb.Adornee = part
    sb.SurfaceTransparency = 0.5; sb.LineThickness = 0.09
    sb.SurfaceColor3 = Color3.fromRGB(0,0,0)
    sb.Color3 = Color3.fromRGB(0,172,240)
end

local function deselectPart(part)
    if not part then return end
    local s = part:FindFirstChild("Selection")
    if s then s:Destroy() end
end

local function deselectAll()
    if not (workspace:FindFirstChild("PlayerModels")) then return end
    for _, v in pairs(workspace.PlayerModels:GetChildren()) do
        if v:FindFirstChild("Main") and v.Main:FindFirstChild("Selection") then
            v.Main.Selection:Destroy()
        end
        if v:FindFirstChild("WoodSection") and v.WoodSection:FindFirstChild("Selection") then
            v.WoodSection.Selection:Destroy()
        end
    end
end
table.insert(cleanupTasks, deselectAll)

local function trySelect(target)
    if not target then return end
    local par = target.Parent; if not par then return end
    if not par:FindFirstChild("Owner") then return end
    if par:FindFirstChild("Main") then
        local tPart = par.Main
        if target == tPart or target:IsDescendantOf(tPart) then
            if tPart:FindFirstChild("Selection") then deselectPart(tPart) else selectPart(tPart) end
            return
        end
    end
    if par:FindFirstChild("WoodSection") then
        local tPart = par.WoodSection
        if target == tPart or target:IsDescendantOf(tPart) then
            if tPart:FindFirstChild("Selection") then deselectPart(tPart) else selectPart(tPart) end
            return
        end
    end
    local model = target:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChild("Owner") then
        if model:FindFirstChild("Main") then
            local p = model.Main
            if p:FindFirstChild("Selection") then deselectPart(p) else selectPart(p) end
        elseif model:FindFirstChild("WoodSection") then
            local p = model.WoodSection
            if p:FindFirstChild("Selection") then deselectPart(p) else selectPart(p) end
        end
    end
end

local function tryGroupSelect(target)
    if not target then return end
    local model = target.Parent
    if not (model and model:FindFirstChild("Owner")) then
        model = target:FindFirstAncestorOfClass("Model")
    end
    if not (model and model:FindFirstChild("Owner")) then return end
    local iv = model:FindFirstChild("ItemName")
    local groupName = iv and iv.Value or model.Name
    if not workspace:FindFirstChild("PlayerModels") then return end
    for _, v in pairs(workspace.PlayerModels:GetChildren()) do
        if v:FindFirstChild("Owner") then
            local viv = v:FindFirstChild("ItemName")
            local vName = viv and viv.Value or v.Name
            if vName == groupName then
                if v:FindFirstChild("Main") then selectPart(v.Main) end
                if v:FindFirstChild("WoodSection") then selectPart(v.WoodSection) end
            end
        end
    end
end

local lassoFrame = Instance.new("Frame", gui)
lassoFrame.Name = "VHLassoRect"
lassoFrame.BackgroundColor3 = Color3.fromRGB(90, 130, 210)
lassoFrame.BackgroundTransparency = 0.82; lassoFrame.BorderSizePixel = 0
lassoFrame.Visible = false; lassoFrame.ZIndex = 20
local lassoStroke = Instance.new("UIStroke", lassoFrame)
lassoStroke.Color = Color3.fromRGB(130,160,240); lassoStroke.Thickness = 1.5; lassoStroke.Transparency = 0

local function is_in_frame(screenpos, frame)
    local xPos = frame.AbsolutePosition.X; local yPos = frame.AbsolutePosition.Y
    local xSize = frame.AbsoluteSize.X;    local ySize = frame.AbsoluteSize.Y
    local c1 = screenpos.X >= xPos and screenpos.X <= xPos + xSize
    local c2 = screenpos.X <= xPos and screenpos.X >= xPos + xSize
    local c3 = screenpos.Y >= yPos and screenpos.Y <= yPos + ySize
    local c4 = screenpos.Y <= yPos and screenpos.Y >= yPos + ySize
    return (c1 and c3) or (c2 and c3) or (c1 and c4) or (c2 and c4)
end

local Camera = workspace.CurrentCamera

UserInputService.InputBegan:Connect(function(input)
    if not lassoEnabled then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not workspace:FindFirstChild("PlayerModels") then return end
    lassoFrame.Visible = true
    lassoFrame.Position = UDim2.new(0, mouse.X, 0, mouse.Y)
    lassoFrame.Size = UDim2.new(0, 0, 0, 0)
    while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
        RunService.RenderStepped:Wait()
        lassoFrame.Size = UDim2.new(0, mouse.X, 0, mouse.Y) - lassoFrame.Position
        for _, v in pairs(workspace.PlayerModels:GetChildren()) do
            if v:FindFirstChild("Main") then
                local sp, vis = Camera:WorldToScreenPoint(v.Main.CFrame.p)
                if vis and is_in_frame(sp, lassoFrame) then selectPart(v.Main) end
            end
            if v:FindFirstChild("WoodSection") then
                local sp, vis = Camera:WorldToScreenPoint(v.WoodSection.CFrame.p)
                if vis and is_in_frame(sp, lassoFrame) then selectPart(v.WoodSection) end
            end
        end
    end
    lassoFrame.Size = UDim2.new(0, 1, 0, 1)
    lassoFrame.Visible = false
end)

mouse.Button1Up:Connect(function()
    if lassoEnabled then return end
    if clickSelectEnabled then trySelect(mouse.Target)
    elseif groupSelectEnabled then tryGroupSelect(mouse.Target) end
end)

local function isnetworkowner(part)
    return part.ReceiveAge == 0
end

iSectionLabel("Selection Mode")
iToggle("Click Selection", false, function(val)
    clickSelectEnabled = val
    if val then lassoEnabled = false; groupSelectEnabled = false end
end)
iToggle("Lasso Tool", false, function(val)
    lassoEnabled = val
    if val then clickSelectEnabled = false; groupSelectEnabled = false end
end)
iToggle("Group Selection", false, function(val)
    groupSelectEnabled = val
    if val then clickSelectEnabled = false; lassoEnabled = false end
end)

iSep()
iSectionLabel("Delay Per Item")
iSlider("Delay (x0.1s)", 1, 20, 3, function(v) tpItemSpeed = v / 10 end)

iSep()
iSectionLabel("Teleport Mode")

local itemModeRow = Instance.new("Frame", itemPage)
itemModeRow.Size = UDim2.new(1, 0, 0, 30); itemModeRow.BackgroundTransparency = 1

local itemModeButtons = {}
local itemModeNames = {"Group", "Random"}
local itemTpMode = "group"

local function updateItemModeButtons(active)
    for _, mb in ipairs(itemModeButtons) do
        local isActive = mb.Text == active
        TweenService:Create(mb, TweenInfo.new(0.18), {
            BackgroundColor3 = isActive and ACCENT or BTN_COLOR,
            TextColor3 = isActive and Color3.fromRGB(255,255,255) or THEME_TEXT
        }):Play()
    end
end

for i, mName in ipairs(itemModeNames) do
    local mb = Instance.new("TextButton", itemModeRow)
    mb.Size = UDim2.new(0.5, -4, 1, 0)
    mb.Position = UDim2.new((i-1) * 0.5, i == 1 and 0 or 4, 0, 0)
    mb.BackgroundColor3 = BTN_COLOR; mb.Font = Enum.Font.GothamSemibold; mb.TextSize = 12
    mb.TextColor3 = THEME_TEXT; mb.Text = mName; mb.BorderSizePixel = 0
    Instance.new("UICorner", mb).CornerRadius = UDim.new(0, 7)
    table.insert(itemModeButtons, mb)
    mb.MouseButton1Click:Connect(function()
        itemTpMode = string.lower(mName)
        updateItemModeButtons(mName)
    end)
end
updateItemModeButtons("Group")

local itemModeHint = Instance.new("TextLabel", itemPage)
itemModeHint.Size = UDim2.new(1, 0, 0, 24); itemModeHint.BackgroundColor3 = Color3.fromRGB(13,13,16)
itemModeHint.BorderSizePixel = 0; itemModeHint.Font = Enum.Font.Gotham; itemModeHint.TextSize = 11
itemModeHint.TextColor3 = Color3.fromRGB(95,95,110); itemModeHint.TextWrapped = true
itemModeHint.TextXAlignment = Enum.TextXAlignment.Left
itemModeHint.Text = "  Group: sorted by item type  •  Random: shuffled order"
Instance.new("UICorner", itemModeHint).CornerRadius = UDim.new(0, 7)
Instance.new("UIPadding", itemModeHint).PaddingLeft = UDim.new(0, 4)

iButton("Deselect All", function() deselectAll() end)

iSep()
iSectionLabel("Teleport Destination")

local tpRow = Instance.new("Frame", itemPage)
tpRow.Size = UDim2.new(1, 0, 0, 30); tpRow.BackgroundTransparency = 1

local tpSetBtn = Instance.new("TextButton", tpRow)
tpSetBtn.Size = UDim2.new(0.5, -4, 1, 0); tpSetBtn.Position = UDim2.new(0, 0, 0, 0)
tpSetBtn.BackgroundColor3 = BTN_COLOR; tpSetBtn.Font = Enum.Font.GothamSemibold
tpSetBtn.TextSize = 12; tpSetBtn.TextColor3 = THEME_TEXT; tpSetBtn.Text = "Set Destination"
tpSetBtn.BorderSizePixel = 0
Instance.new("UICorner", tpSetBtn).CornerRadius = UDim.new(0, 7)

local tpRemoveBtn = Instance.new("TextButton", tpRow)
tpRemoveBtn.Size = UDim2.new(0.5, -4, 1, 0); tpRemoveBtn.Position = UDim2.new(0.5, 4, 0, 0)
tpRemoveBtn.BackgroundColor3 = BTN_COLOR; tpRemoveBtn.Font = Enum.Font.GothamSemibold
tpRemoveBtn.TextSize = 12; tpRemoveBtn.TextColor3 = THEME_TEXT; tpRemoveBtn.Text = "Remove Destination"
tpRemoveBtn.BorderSizePixel = 0
Instance.new("UICorner", tpRemoveBtn).CornerRadius = UDim.new(0, 7)

for _, b in {tpSetBtn, tpRemoveBtn} do
    b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=BTN_HOVER}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=BTN_COLOR}):Play() end)
end

tpSetBtn.MouseButton1Click:Connect(function()
    if tpCircle then tpCircle:Destroy() end
    tpCircle = Instance.new("Part")
    tpCircle.Name = "VanillaHubTpCircle"
    tpCircle.Shape = Enum.PartType.Ball; tpCircle.Size = Vector3.new(3,3,3)
    tpCircle.Material = Enum.Material.SmoothPlastic
    tpCircle.Color = Color3.fromRGB(110,110,120)
    tpCircle.Anchored = true; tpCircle.CanCollide = false
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        tpCircle.Position = char.HumanoidRootPart.Position
    end
    tpCircle.Parent = workspace
end)

tpRemoveBtn.MouseButton1Click:Connect(function()
    if tpCircle then tpCircle:Destroy(); tpCircle = nil end
end)

table.insert(cleanupTasks, function()
    if tpCircle and tpCircle.Parent then tpCircle:Destroy(); tpCircle = nil end
end)

iSep()
iSectionLabel("Actions")

local tpSelectBtn = iButton("Teleport Selected", function() end)
tpSelectBtn.MouseButton1Click:Connect(function()
    if isTeleportingItems then
        stopTeleportItems = true; return
    end
    if not tpCircle then return end
    isTeleportingItems = true; stopTeleportItems = false
    tpSelectBtn.Text = "Stop Teleporting"
    TweenService:Create(tpSelectBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(150,40,40)}):Play()
    local destCF = tpCircle.CFrame
    local OldPos = player.Character
        and player.Character:FindFirstChild("HumanoidRootPart")
        and player.Character.HumanoidRootPart.CFrame
    task.spawn(function()
        if not workspace:FindFirstChild("PlayerModels") then
            isTeleportingItems = false; stopTeleportItems = false
            tpSelectBtn.Text = "Teleport Selected"
            TweenService:Create(tpSelectBtn,TweenInfo.new(0.2),{BackgroundColor3=BTN_COLOR}):Play()
            return
        end
        local selectedParts = {}
        for _, v in next, workspace.PlayerModels:GetDescendants() do
            if v.Name == "Selection" then
                local part = v.Parent
                if part and part.Parent then table.insert(selectedParts, part) end
            end
        end
        local function getItemType(part)
            local m = part.Parent; if not m then return "unknown" end
            local iv = m:FindFirstChild("ItemName")
            return iv and iv.Value or m.Name
        end
        if itemTpMode == "random" then
            for i = #selectedParts, 2, -1 do
                local j = math.random(i)
                selectedParts[i], selectedParts[j] = selectedParts[j], selectedParts[i]
            end
            for i = 2, #selectedParts do
                if getItemType(selectedParts[i]) == getItemType(selectedParts[i-1]) then
                    for j = i+1, #selectedParts do
                        if getItemType(selectedParts[j]) ~= getItemType(selectedParts[i-1]) then
                            selectedParts[i], selectedParts[j] = selectedParts[j], selectedParts[i]
                            break
                        end
                    end
                end
            end
        elseif itemTpMode == "group" then
            table.sort(selectedParts, function(a, b)
                return getItemType(a) < getItemType(b)
            end)
        end
        for _, part in ipairs(selectedParts) do
            if stopTeleportItems then break end
            local char = player.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = CFrame.new(part.CFrame.p) * CFrame.new(5,0,0) end
            task.wait(tpItemSpeed)
            if stopTeleportItems then break end
            pcall(function()
                if not part.Parent.PrimaryPart then part.Parent.PrimaryPart = part end
                local dragger = ReplicatedStorage:FindFirstChild("Interaction")
                    and ReplicatedStorage.Interaction:FindFirstChild("ClientIsDragging")
                local timeout = 0
                while not isnetworkowner(part) and timeout < 3 do
                    if dragger then dragger:FireServer(part.Parent) end
                    task.wait(0.05); timeout = timeout + 0.05
                end
                if dragger then dragger:FireServer(part.Parent) end
                part:PivotTo(destCF)
            end)
            task.wait(tpItemSpeed)
        end
        if OldPos and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = OldPos
        end
        isTeleportingItems = false; stopTeleportItems = false
        tpSelectBtn.Text = "Teleport Selected"
        TweenService:Create(tpSelectBtn, TweenInfo.new(0.2), {BackgroundColor3 = BTN_COLOR}):Play()
    end)
end)

local sellBtn = iButton("Sell Selected (to Dropoff)", function() end)
sellBtn.MouseButton1Click:Connect(function()
    local OldPos = player.Character
        and player.Character:FindFirstChild("HumanoidRootPart")
        and player.Character.HumanoidRootPart.CFrame
    if not workspace:FindFirstChild("PlayerModels") then return end
    task.spawn(function()
        for _, v in next, workspace.PlayerModels:GetDescendants() do
            if v.Name == "Selection" then
                local part = v.Parent
                if not (part and part.Parent) then continue end
                local char = player.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CFrame = CFrame.new(part.CFrame.p) * CFrame.new(5,0,0) end
                task.wait(tpItemSpeed)
                pcall(function()
                    if not part.Parent.PrimaryPart then part.Parent.PrimaryPart = part end
                    local dragger = ReplicatedStorage:FindFirstChild("Interaction")
                        and ReplicatedStorage.Interaction:FindFirstChild("ClientIsDragging")
                    local timeout = 0
                    while not isnetworkowner(part) and timeout < 3 do
                        if dragger then dragger:FireServer(part.Parent) end
                        task.wait(0.05); timeout = timeout + 0.05
                    end
                    if dragger then dragger:FireServer(part.Parent) end
                    part:PivotTo(CFrame.new(314.776,-1.593,87.807))
                end)
                task.wait(tpItemSpeed)
            end
        end
        if OldPos and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = OldPos
        end
    end)
end)

-- ════════════════════════════════════════════════════
-- DUPE TAB
-- ════════════════════════════════════════════════════
local dupePage = pages["DupeTab"]
local dupeList = dupePage:FindFirstChildOfClass("UIListLayout")
if dupeList then dupeList.Padding = UDim.new(0, 8) end

local function dSectionLabel(text)
    local w = Instance.new("Frame", dupePage)
    w.Size = UDim2.new(1, 0, 0, 22); w.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", w)
    lbl.Size = UDim2.new(1, -4, 1, 0); lbl.Position = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 10
    lbl.TextColor3 = SECTION_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "  " .. string.upper(text)
end

local function dButton(text, cb)
    local btn = Instance.new("TextButton", dupePage)
    btn.Size = UDim2.new(1, 0, 0, 32); btn.BackgroundColor3 = BTN_COLOR
    btn.Text = text; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = THEME_TEXT; btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=BTN_HOVER}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=BTN_COLOR}):Play() end)
    if cb then btn.MouseButton1Click:Connect(cb) end
    return btn
end

dSectionLabel("Info")

-- ════════════════════════════════════════════════════
-- PLAYER TAB
-- ════════════════════════════════════════════════════
local playerPage = pages["PlayerTab"]

local function createPSection(text)
    local w = Instance.new("Frame", playerPage)
    w.Size = UDim2.new(1, 0, 0, 24); w.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", w)
    lbl.Size = UDim2.new(1, -4, 1, 0); lbl.Position = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 10
    lbl.TextColor3 = SECTION_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "  " .. string.upper(text)
end

local function createPSep()
    local s = Instance.new("Frame", playerPage)
    s.Size = UDim2.new(1, 0, 0, 1)
    s.BackgroundColor3 = SEP_COLOR; s.BorderSizePixel = 0
end

local savedWalkSpeed = 16
local savedJumpPower = 50

local statsConn2 = RunService.Heartbeat:Connect(function()
    local char=player.Character; if not char then return end
    local hum=char:FindFirstChild("Humanoid"); if not hum then return end
    if hum.WalkSpeed ~= savedWalkSpeed then hum.WalkSpeed = savedWalkSpeed end
    if hum.JumpPower  ~= savedJumpPower  then hum.JumpPower  = savedJumpPower  end
end)
table.insert(cleanupTasks, function()
    if statsConn2 then statsConn2:Disconnect(); statsConn2=nil end
    local char=player.Character
    if char then
        local hum=char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed=16; hum.JumpPower=50 end
    end
end)

local function createPSlider(labelText, minVal, maxVal, defaultVal, onChanged)
    local frame=Instance.new("Frame",playerPage)
    frame.Size=UDim2.new(1,0,0,54); frame.BackgroundColor3=Color3.fromRGB(16,16,20)
    frame.BorderSizePixel=0; Instance.new("UICorner",frame).CornerRadius=UDim.new(0,8)
    local topRow=Instance.new("Frame",frame)
    topRow.Size=UDim2.new(1,-16,0,22); topRow.Position=UDim2.new(0,8,0,7); topRow.BackgroundTransparency=1
    local lbl=Instance.new("TextLabel",topRow)
    lbl.Size=UDim2.new(0.72,0,1,0); lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=13
    lbl.TextColor3=THEME_TEXT; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=labelText
    local valLbl=Instance.new("TextLabel",topRow)
    valLbl.Size=UDim2.new(0.28,0,1,0); valLbl.Position=UDim2.new(0.72,0,0,0); valLbl.BackgroundTransparency=1
    valLbl.Font=Enum.Font.GothamBold; valLbl.TextSize=13
    valLbl.TextColor3=Color3.fromRGB(160,160,175)
    valLbl.TextXAlignment=Enum.TextXAlignment.Right; valLbl.Text=tostring(defaultVal)
    local track=Instance.new("Frame",frame)
    track.Size=UDim2.new(1,-16,0,5); track.Position=UDim2.new(0,8,0,38)
    track.BackgroundColor3=Color3.fromRGB(32,32,38); track.BorderSizePixel=0
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new((defaultVal-minVal)/(maxVal-minVal),0,1,0)
    fill.BackgroundColor3=ACCENT; fill.BorderSizePixel=0
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("TextButton",track)
    knob.Size=UDim2.new(0,14,0,14); knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new((defaultVal-minVal)/(maxVal-minVal),0,0.5,0)
    knob.BackgroundColor3=Color3.fromRGB(210,210,220); knob.Text=""; knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local ds=false
    local function upd(absX)
        local r=math.clamp((absX-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local v=math.round(minVal+r*(maxVal-minVal))
        fill.Size=UDim2.new(r,0,1,0); knob.Position=UDim2.new(r,0,0.5,0); valLbl.Text=tostring(v)
        if onChanged then onChanged(v) end
    end
    knob.MouseButton1Down:Connect(function() ds=true end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then ds=true; upd(i.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if ds and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then ds=false end
    end)
    return frame
end

local function createPToggle(text, defaultState, callback)
    local frame=Instance.new("Frame",playerPage)
    frame.Size=UDim2.new(1,0,0,36); frame.BackgroundColor3=Color3.fromRGB(16,16,20)
    frame.BorderSizePixel=0; Instance.new("UICorner",frame).CornerRadius=UDim.new(0,8)
    local lbl=Instance.new("TextLabel",frame)
    lbl.Size=UDim2.new(1,-54,1,0); lbl.Position=UDim2.new(0,12,0,0); lbl.BackgroundTransparency=1
    lbl.Text=text; lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=13
    lbl.TextColor3=THEME_TEXT; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local tb=Instance.new("TextButton",frame)
    tb.Size=UDim2.new(0,36,0,20); tb.Position=UDim2.new(1,-46,0.5,-10)
    tb.BackgroundColor3=defaultState and Color3.fromRGB(80,160,80) or Color3.fromRGB(38,38,45)
    tb.Text=""; tb.BorderSizePixel=0; Instance.new("UICorner",tb).CornerRadius=UDim.new(1,0)
    local circle=Instance.new("Frame",tb)
    circle.Size=UDim2.new(0,14,0,14); circle.Position=UDim2.new(0,defaultState and 20 or 2,0.5,-7)
    circle.BackgroundColor3=Color3.fromRGB(255,255,255); circle.BorderSizePixel=0
    Instance.new("UICorner",circle).CornerRadius=UDim.new(1,0)
    local toggled=defaultState
    if callback then callback(toggled) end
    local function setToggled(val)
        toggled=val
        TweenService:Create(tb,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=toggled and Color3.fromRGB(80,160,80) or Color3.fromRGB(38,38,45)}):Play()
        TweenService:Create(circle,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{Position=UDim2.new(0,toggled and 20 or 2,0.5,-7)}):Play()
    end
    tb.MouseButton1Click:Connect(function()
        toggled=not toggled; setToggled(toggled)
        if callback then callback(toggled) end
    end)
    return frame, setToggled, function() return toggled end
end

createPSection("Movement")
createPSlider("Walkspeed", 16, 150, 16, function(val)
    savedWalkSpeed=val
    local char=player.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed=val end
end)
createPSlider("Jumppower", 50, 300, 50, function(val)
    savedJumpPower=val
    local char=player.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.JumpPower=val end
end)

-- ════════════════════════════════════════════════════
-- FLY
-- ════════════════════════════════════════════════════
local flySpeed      = 100
local flyEnabled    = true
local isFlyActive   = false
local flyBV, flyBG, flyConn
local currentFlyKey = Enum.KeyCode.Q

local function stopFly()
    isFlyActive = false
    if _G.VH then _G.VH.isFlyActive = false end
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    pcall(function()
        if flyBV and flyBV.Parent then flyBV:Destroy() end
        if flyBG and flyBG.Parent then flyBG:Destroy() end
    end)
    flyBV = nil; flyBG = nil
    local char = player.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.PlatformStand = false end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide = true end) end
        end
    end
end

local function startFly()
    if not flyEnabled then return end
    stopFly()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChild("Humanoid")
    if not root or not hum then return end
    isFlyActive = true
    if _G.VH then _G.VH.isFlyActive = true end
    hum.PlatformStand = true
    flyBV = Instance.new("BodyVelocity", root)
    flyBV.Name = "VHFlyBV"
    flyBV.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    flyBV.Velocity  = Vector3.zero
    flyBG = Instance.new("BodyGyro", root)
    flyBG.Name = "VHFlyBG"
    flyBG.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    flyBG.P = 1e4; flyBG.D = 100
    flyBG.CFrame = workspace.CurrentCamera.CFrame
    flyConn = RunService.Heartbeat:Connect(function()
        if not isFlyActive then return end
        if not (flyBV and flyBV.Parent) then stopFly(); return end
        local ch  = player.Character; if not ch then stopFly(); return end
        local h   = ch:FindFirstChild("Humanoid"); if not h then stopFly(); return end
        local r   = ch:FindFirstChild("HumanoidRootPart"); if not r then stopFly(); return end
        local cf  = workspace.CurrentCamera.CFrame
        local dir = Vector3.zero
        local UIS = UserInputService
        if UIS:IsKeyDown(Enum.KeyCode.W)         then dir = dir + cf.LookVector  end
        if UIS:IsKeyDown(Enum.KeyCode.S)         then dir = dir - cf.LookVector  end
        if UIS:IsKeyDown(Enum.KeyCode.A)         then dir = dir - cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D)         then dir = dir + cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space)     then dir = dir + Vector3.yAxis  end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.yAxis  end
        h.PlatformStand = true
        flyBV.MaxForce  = Vector3.new(1e6, 1e6, 1e6)
        flyBV.Velocity  = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero
        flyBG.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        flyBG.CFrame    = cf
    end)
end

table.insert(cleanupTasks, stopFly)

player.CharacterRemoving:Connect(function()
    if isFlyActive then stopFly() end
end)

createPSlider("Fly Speed", 100, 500, 100, function(val) flySpeed = val end)

local flyKeyFrame = Instance.new("Frame", playerPage)
flyKeyFrame.Size = UDim2.new(1, 0, 0, 36)
flyKeyFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 20); flyKeyFrame.BorderSizePixel = 0
Instance.new("UICorner", flyKeyFrame).CornerRadius = UDim.new(0, 8)
local flyKeyLabel = Instance.new("TextLabel", flyKeyFrame)
flyKeyLabel.Size = UDim2.new(0.55, 0, 1, 0); flyKeyLabel.Position = UDim2.new(0, 12, 0, 0)
flyKeyLabel.BackgroundTransparency = 1; flyKeyLabel.Font = Enum.Font.GothamSemibold; flyKeyLabel.TextSize = 13
flyKeyLabel.TextColor3 = THEME_TEXT; flyKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
flyKeyLabel.Text = "Fly Hotkey"
local flyKeyBtn = Instance.new("TextButton", flyKeyFrame)
flyKeyBtn.Size = UDim2.new(0, 60, 0, 24); flyKeyBtn.Position = UDim2.new(1, -70, 0.5, -12)
flyKeyBtn.BackgroundColor3 = BTN_COLOR; flyKeyBtn.Font = Enum.Font.GothamSemibold
flyKeyBtn.TextSize = 12; flyKeyBtn.TextColor3 = THEME_TEXT; flyKeyBtn.Text = "Q"
flyKeyBtn.BorderSizePixel = 0; Instance.new("UICorner", flyKeyBtn).CornerRadius = UDim.new(0, 6)
flyKeyBtn.MouseEnter:Connect(function() TweenService:Create(flyKeyBtn,TweenInfo.new(0.15),{BackgroundColor3=BTN_HOVER}):Play() end)
flyKeyBtn.MouseLeave:Connect(function() TweenService:Create(flyKeyBtn,TweenInfo.new(0.15),{BackgroundColor3=BTN_COLOR}):Play() end)

local waitingForFlyKey = false

flyKeyBtn.MouseButton1Click:Connect(function()
    if waitingForFlyKey then return end
    waitingForFlyKey = true
    flyKeyBtn.Text = "..."
    flyKeyBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 50)
end)

local flyToggleFrame = Instance.new("Frame", playerPage)
flyToggleFrame.Size = UDim2.new(1, 0, 0, 36)
flyToggleFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 20); flyToggleFrame.BorderSizePixel = 0
Instance.new("UICorner", flyToggleFrame).CornerRadius = UDim.new(0, 8)
local flyToggleLbl = Instance.new("TextLabel", flyToggleFrame)
flyToggleLbl.Size = UDim2.new(1, -54, 1, 0); flyToggleLbl.Position = UDim2.new(0, 12, 0, 0)
flyToggleLbl.BackgroundTransparency = 1; flyToggleLbl.Font = Enum.Font.GothamSemibold; flyToggleLbl.TextSize = 13
flyToggleLbl.TextColor3 = THEME_TEXT; flyToggleLbl.TextXAlignment = Enum.TextXAlignment.Left
flyToggleLbl.Text = "Fly"
local flyToggleTb = Instance.new("TextButton", flyToggleFrame)
flyToggleTb.Size = UDim2.new(0, 36, 0, 20); flyToggleTb.Position = UDim2.new(1, -46, 0.5, -10)
flyToggleTb.BackgroundColor3 = Color3.fromRGB(80, 160, 80)
flyToggleTb.Text = ""; flyToggleTb.BorderSizePixel = 0
Instance.new("UICorner", flyToggleTb).CornerRadius = UDim.new(1, 0)
local flyToggleCircle = Instance.new("Frame", flyToggleTb)
flyToggleCircle.Size = UDim2.new(0, 14, 0, 14)
flyToggleCircle.Position = UDim2.new(0, 20, 0.5, -7)
flyToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255); flyToggleCircle.BorderSizePixel = 0
Instance.new("UICorner", flyToggleCircle).CornerRadius = UDim.new(1, 0)
flyToggleTb.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    TweenService:Create(flyToggleTb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
        BackgroundColor3 = flyEnabled and Color3.fromRGB(80, 160, 80) or Color3.fromRGB(38, 38, 45)
    }):Play()
    TweenService:Create(flyToggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
        Position = UDim2.new(0, flyEnabled and 20 or 2, 0.5, -7)
    }):Play()
    flyToggleLbl.Text = "Fly"
    if not flyEnabled and isFlyActive then stopFly() end
end)

createPSep()
createPSection("Character")

local noclipEnabled = false; local noclipConn
createPToggle("Noclip", false, function(val)
    noclipEnabled = val
    if val then
        noclipConn = RunService.Stepped:Connect(function()
            if not noclipEnabled then return end
            local char = player.Character; if not char then return end
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        local char = player.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then pcall(function() p.CanCollide = true end) end
            end
        end
    end
end)
table.insert(cleanupTasks, function()
    noclipEnabled = false
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
end)

local infJumpEnabled = false; local infJumpConn
createPToggle("InfJump", false, function(val)
    infJumpEnabled = val
    if val then
        infJumpConn = UserInputService.JumpRequest:Connect(function()
            if not infJumpEnabled then return end
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
    end
end)
table.insert(cleanupTasks, function()
    infJumpEnabled = false
    if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
end)

-- ════════════════════════════════════════════════════
-- MISC (Hard Dragger)
-- ════════════════════════════════════════════════════
createPSep()
createPSection("Misc")

local hardDragEnabled = false
local draggerConn     = nil

local function stopHardDrag()
    if draggerConn then draggerConn:Disconnect(); draggerConn = nil end
end

local function startDraggerWatch()
    stopHardDrag()
    draggerConn = workspace.ChildAdded:Connect(function(a)
        if a.Name ~= "Dragger" then return end
        local bg = a:WaitForChild("BodyGyro", 2)
        local bp = a:WaitForChild("BodyPosition", 2)
        if not (bg and bp) then return end
        task.spawn(function()
            while a and a.Parent do
                if hardDragEnabled then
                    bp.P         = 120000
                    bp.D         = 1000
                    bp.maxForce  = Vector3.new(math.huge, math.huge, math.huge)
                    bg.maxTorque = Vector3.new(math.huge, math.huge, math.huge)
                else
                    bp.P         = 10000
                    bp.D         = 800
                    bp.maxForce  = Vector3.new(17000, 17000, 17000)
                    bg.maxTorque = Vector3.new(200, 200, 200)
                end
                task.wait()
            end
        end)
    end)
end

startDraggerWatch()

createPToggle("Hard Dragger", false, function(val)
    hardDragEnabled = val
    if not val then
        local d = workspace:FindFirstChild("Dragger")
        if d then
            local bp = d:FindFirstChild("BodyPosition")
            local bg = d:FindFirstChild("BodyGyro")
            if bp then
                bp.P        = 10000
                bp.D        = 800
                bp.maxForce = Vector3.new(17000, 17000, 17000)
            end
            if bg then
                bg.maxTorque = Vector3.new(200, 200, 200)
            end
        end
    end
end)

table.insert(cleanupTasks, stopHardDrag)

-- ════════════════════════════════════════════════════
-- GLOBAL KEY LISTENER
-- ════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if waitingForFlyKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            currentFlyKey = input.KeyCode
            if _G.VH then _G.VH.currentFlyKey = currentFlyKey end
            flyKeyBtn.Text = input.KeyCode.Name
            flyKeyBtn.BackgroundColor3 = BTN_COLOR
            waitingForFlyKey = false
        end
        return
    end

    if gameProcessed then return end

    if input.KeyCode == currentToggleKey then
        toggleGUI()
        return
    end

    if input.KeyCode == currentFlyKey then
        if not flyEnabled then
            if isFlyActive then stopFly() end
            return
        end
        if isFlyActive then stopFly() else startFly() end
        return
    end
end)

-- ════════════════════════════════════════════════════
-- SHARED GLOBALS
-- ════════════════════════════════════════════════════
_G.VH = {
    TweenService     = TweenService,
    Players          = Players,
    UserInputService = UserInputService,
    RunService       = RunService,
    TeleportService  = TeleportService,
    Stats            = Stats,
    player           = player,
    cleanupTasks     = cleanupTasks,
    pages            = pages,
    tabs             = tabs,
    BTN_COLOR        = BTN_COLOR,
    BTN_HOVER        = BTN_HOVER,
    THEME_TEXT       = THEME_TEXT,
    ACCENT           = ACCENT,
    switchTab        = switchTab,
    showMenuPage     = showMenuPage,
    toggleGUI        = toggleGUI,
    stopFly          = stopFly,
    startFly         = startFly,
    butter           = { running = false, thread = nil },
    isFlyActive      = false,
    flyEnabled       = flyEnabled,
    currentFlyKey    = currentFlyKey,
    waitingForFlyKey = false,
    flyKeyBtn        = flyKeyBtn,
    currentToggleKey = currentToggleKey,
    keybindButtonGUI = nil,
}

_G.VanillaHubCleanup = onExit

print("[VanillaHub] v1.1.0 loaded")
