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
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        frame.BackgroundTransparency = 0.15
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)
        local uiStroke = Instance.new("UIStroke", frame)
        uiStroke.Color = Color3.fromRGB(80, 80, 80)
        uiStroke.Thickness = 1.5; uiStroke.Transparency = 0.3
        local icon = Instance.new("TextLabel", frame)
        icon.Size = UDim2.new(0, 48, 0, 48); icon.Position = UDim2.new(0, 24, 0, 24)
        icon.BackgroundTransparency = 1; icon.Font = Enum.Font.GothamBlack
        icon.TextSize = 42; icon.TextColor3 = Color3.fromRGB(200, 200, 200); icon.Text = "!"
        local msg = Instance.new("TextLabel", frame)
        msg.Size = UDim2.new(1, -100, 0, 120); msg.Position = UDim2.new(0, 90, 0, 30)
        msg.BackgroundTransparency = 1; msg.Font = Enum.Font.GothamSemibold; msg.TextSize = 15
        msg.TextColor3 = Color3.fromRGB(210, 210, 210); msg.TextXAlignment = Enum.TextXAlignment.Left
        msg.TextYAlignment = Enum.TextYAlignment.Top; msg.TextWrapped = true
        msg.Text = "VanillaHub is made exclusively for Lumber Tycoon 2 (Place ID: 13822889).\n\nPlease join Lumber Tycoon 2 and re-execute the script there."
        local okBtn = Instance.new("TextButton", frame)
        okBtn.Size = UDim2.new(0, 160, 0, 50); okBtn.Position = UDim2.new(0.5, -80, 1, -70)
        okBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
        okBtn.BorderSizePixel = 0
        okBtn.Font = Enum.Font.GothamBold; okBtn.TextSize = 17
        okBtn.TextColor3 = Color3.fromRGB(255, 255, 255); okBtn.Text = "I Understand"
        Instance.new("UICorner", okBtn).CornerRadius = UDim.new(0, 12)
        local TS2 = game:GetService("TweenService")
        frame.BackgroundTransparency = 1; msg.TextTransparency = 1; icon.TextTransparency = 1
        okBtn.BackgroundTransparency = 1; okBtn.TextTransparency = 1
        TS2:Create(frame, TweenInfo.new(0.75, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.15}):Play()
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
local BTN_COLOR    = Color3.fromRGB(14, 14, 14)
local BTN_HOVER    = Color3.fromRGB(32,  32,  32)
local ACCENT       = Color3.fromRGB(160, 160, 160)
local BG_DARK      = Color3.fromRGB(6,  6,  6 )
local BG_SIDE      = Color3.fromRGB(10, 10, 10)
local BG_TOP       = Color3.fromRGB(8,  8,  8 )
local BORDER_COLOR = Color3.fromRGB(60, 60, 60)
local SEP_COLOR    = Color3.fromRGB(50, 50, 50)
local SECTION_TEXT = Color3.fromRGB(130, 130, 130)
local OUTER_BG     = Color3.fromRGB(8,   8,   8 )

local SW_OFF      = Color3.fromRGB(55, 55, 55)
local SW_ON       = Color3.fromRGB(230, 230, 230)
local SW_KNOB_OFF = Color3.fromRGB(160, 160, 160)
local SW_KNOB_ON  = Color3.fromRGB(30, 30, 30)

local PB_BAR  = Color3.fromRGB(255, 255, 255)
local PB_TEXT = Color3.fromRGB(255, 255, 255)

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
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
table.insert(cleanupTasks, function() if gui and gui.Parent then gui:Destroy() end end)

_G.VanillaHubCleanup = onExit

local wrapper = Instance.new("Frame", gui)
wrapper.Size = UDim2.new(0, 0, 0, 0)
wrapper.Position = UDim2.new(0.5, -265, 0.5, -175)
wrapper.BackgroundColor3 = OUTER_BG
wrapper.BackgroundTransparency = 0
wrapper.BorderSizePixel = 0
wrapper.ClipsDescendants = false
Instance.new("UICorner", wrapper).CornerRadius = UDim.new(0, 16)

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

local hubIcon = Instance.new("ImageLabel", topBar)
hubIcon.Size = UDim2.new(0, 26, 0, 26); hubIcon.Position = UDim2.new(0, 9, 0.5, -13)
hubIcon.BackgroundTransparency = 1; hubIcon.BorderSizePixel = 0
hubIcon.ScaleType = Enum.ScaleType.Fit; hubIcon.ZIndex = 6
hubIcon.Image = "rbxassetid://97128823316544"
Instance.new("UICorner", hubIcon).CornerRadius = UDim.new(0, 5)

local titleLbl = Instance.new("TextLabel", topBar)
titleLbl.Size = UDim2.new(1, -110, 1, 0); titleLbl.Position = UDim2.new(0, 44, 0, 0)
titleLbl.BackgroundTransparency = 1; titleLbl.Text = "VanillaHub | LT2"
titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 15
titleLbl.TextColor3 = THEME_TEXT; titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.ZIndex = 5

local versionLbl = Instance.new("TextLabel", topBar)
versionLbl.Size = UDim2.new(0, 52, 0, 20); versionLbl.Position = UDim2.new(1, -60, 0.5, -10)
versionLbl.BackgroundTransparency = 1; versionLbl.Text = "v1.1.0"
versionLbl.Font = Enum.Font.Gotham; versionLbl.TextSize = 11
versionLbl.TextColor3 = Color3.fromRGB(130, 130, 130); versionLbl.TextXAlignment = Enum.TextXAlignment.Right
versionLbl.ZIndex = 5

-- DRAG
local dragging, dragStart, startPos = false, nil, nil
topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = wrapper.Position
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
side.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
side.CanvasSize = UDim2.new(0, 0, 0, 0)
side.ZIndex = 2

local sidePad = Instance.new("UIPadding", side)
sidePad.PaddingTop = UDim.new(0, 10)
sidePad.PaddingBottom = UDim.new(0, 10)
sidePad.PaddingLeft = UDim.new(0, 8)
sidePad.PaddingRight = UDim.new(0, 8)

local sideLayout = Instance.new("UIListLayout", side)
sideLayout.Padding = UDim.new(0, 5)
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
-- WELCOME POPUP
-- ════════════════════════════════════════════════════
task.spawn(function()
    task.wait(0.8)
    if not (gui and gui.Parent) then return end
    local wf = Instance.new("Frame", gui)
    wf.Size = UDim2.new(0, 380, 0, 90); wf.Position = UDim2.new(0.5, -190, 1, -110)
    wf.BackgroundColor3 = Color3.fromRGB(20, 20, 20); wf.BackgroundTransparency = 1; wf.BorderSizePixel = 0
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
    TweenService:Create(wf, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.2}):Play()
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
-- TABS
-- ════════════════════════════════════════════════════
local tabs = {"Home","Player","World","Teleport","Wood","Slot","Dupe","Item","Sorter","AutoBuy","Pixel Art","Build","Vehicle","Search","Settings"}
local pages = {}

for _, name in ipairs(tabs) do
    local page = Instance.new("ScrollingFrame", content)
    page.Name = name .. "Tab"; page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1; page.BorderSizePixel = 0
    page.ScrollBarThickness = 4; page.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
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
local function switchTab(targetName)
    for _, page in pairs(pages) do page.Visible = (page.Name == targetName) end
    if activeTabButton then
        local oldLbl  = activeTabButton:FindFirstChild("TabLabel")
        local oldIcon = activeTabButton:FindFirstChild("TabIcon")
        TweenService:Create(activeTabButton, TweenInfo.new(0.22), {BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
        if oldLbl  then TweenService:Create(oldLbl,  TweenInfo.new(0.22), {TextColor3  = Color3.fromRGB(110, 110, 110)}):Play() end
        if oldIcon then TweenService:Create(oldIcon, TweenInfo.new(0.22), {ImageColor3 = Color3.fromRGB(110, 110, 110)}):Play() end
    end
    local frame = side:FindFirstChild(targetName:gsub("Tab",""))
    if frame then
        activeTabButton = frame
        local newLbl  = frame:FindFirstChild("TabLabel")
        local newIcon = frame:FindFirstChild("TabIcon")
        TweenService:Create(frame, TweenInfo.new(0.22), {BackgroundColor3 = Color3.fromRGB(38, 38, 38)}):Play()
        if newLbl  then TweenService:Create(newLbl,  TweenInfo.new(0.22), {TextColor3  = THEME_TEXT}):Play() end
        if newIcon then TweenService:Create(newIcon, TweenInfo.new(0.22), {ImageColor3 = THEME_TEXT}):Play() end
    end
end

-- TAB ICONS
local tabIcons = {
    ["Home"]      = "😭",
    ["Player"]    = "rbxassetid://124010641391821",
    ["World"]     = "rbxassetid://126582208494394",
    ["Teleport"]  = "rbxassetid://126517940797776",
    ["Wood"]      = "rbxassetid://84914860062890",
    ["Slot"]      = "rbxassetid://91125189715601",
    ["Dupe"]      = "rbxassetid://84061260593530",
    ["Item"]      = "rbxassetid://77054718226216",
    ["Sorter"]    = "rbxassetid://104900927627815",
    ["AutoBuy"]   = "rbxassetid://76236698231155",
    ["Pixel Art"] = "rbxassetid://112117095344788",
    ["Build"]     = "rbxassetid://97668717322455",
    ["Vehicle"]   = "rbxassetid://131533481576470",
    ["Search"]    = "rbxassetid://75885588738364",
    ["Settings"]  = "rbxassetid://116984423831131",
}

for _, name in ipairs(tabs) do
    local frame = Instance.new("Frame", side)
    frame.Name             = name
    frame.Size             = UDim2.new(1, 0, 0, 34)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BorderSizePixel  = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 7)

    local icon = Instance.new("ImageLabel", frame)
    icon.Name                   = "TabIcon"
    icon.Size                   = UDim2.new(0, 16, 0, 16)
    icon.Position               = UDim2.new(0, 10, 0.5, -8)
    icon.BackgroundTransparency = 1
    icon.BorderSizePixel        = 0
    icon.ScaleType              = Enum.ScaleType.Fit
    icon.Image                  = tabIcons[name] or ""
    icon.ImageColor3            = Color3.fromRGB(110, 110, 110)

    local nameLbl = Instance.new("TextLabel", frame)
    nameLbl.Name               = "TabLabel"
    nameLbl.Size               = UDim2.new(1, -34, 1, 0)
    nameLbl.Position           = UDim2.new(0, 32, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font               = Enum.Font.GothamSemibold
    nameLbl.TextSize           = 13
    nameLbl.TextColor3         = Color3.fromRGB(110, 110, 110)
    nameLbl.TextXAlignment     = Enum.TextXAlignment.Left
    nameLbl.Text               = name

    local btn = Instance.new("TextButton", frame)
    btn.Name                 = name .. "_Btn"
    btn.Size                 = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text                 = ""
    btn.ZIndex               = 10
    btn.AutoButtonColor      = false

    btn.MouseEnter:Connect(function()
        if activeTabButton ~= frame then
            TweenService:Create(frame,   TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(22, 22, 22)}):Play()
            TweenService:Create(nameLbl, TweenInfo.new(0.18), {TextColor3       = Color3.fromRGB(180, 180, 180)}):Play()
            TweenService:Create(icon,    TweenInfo.new(0.18), {ImageColor3      = Color3.fromRGB(180, 180, 180)}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeTabButton ~= frame then
            TweenService:Create(frame,   TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
            TweenService:Create(nameLbl, TweenInfo.new(0.18), {TextColor3       = Color3.fromRGB(110, 110, 110)}):Play()
            TweenService:Create(icon,    TweenInfo.new(0.18), {ImageColor3      = Color3.fromRGB(110, 110, 110)}):Play()
        end
    end)
    btn.MouseButton1Click:Connect(function() switchTab(name.."Tab") end)
end

switchTab("HomeTab")

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
-- HOME TAB
-- ════════════════════════════════════════════════════
local homePage = pages["HomeTab"]

local bubbleRow = Instance.new("Frame", homePage)
bubbleRow.Size = UDim2.new(1, 0, 0, 100); bubbleRow.BackgroundTransparency = 1; bubbleRow.LayoutOrder = 1

local bubbleIcon = Instance.new("ImageLabel", bubbleRow)
bubbleIcon.Size=UDim2.new(0,52,0,52); bubbleIcon.Position=UDim2.new(0,6,0.5,-26)
bubbleIcon.BackgroundColor3=Color3.fromRGB(30,30,30); bubbleIcon.BorderSizePixel=0
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
tailShape.Rotation=45; tailShape.BackgroundColor3=Color3.fromRGB(25,25,25); tailShape.BorderSizePixel=0; tailShape.ZIndex=1

local bubbleBody = Instance.new("Frame", bubbleRow)
bubbleBody.Size=UDim2.new(1,-82,0,84); bubbleBody.Position=UDim2.new(0,72,0.5,-42)
bubbleBody.BackgroundColor3=Color3.fromRGB(25,25,25); bubbleBody.BorderSizePixel=0; bubbleBody.ZIndex=2
Instance.new("UICorner", bubbleBody).CornerRadius=UDim.new(0,14)
local bubbleStroke=Instance.new("UIStroke",bubbleBody)
bubbleStroke.Color=BORDER_COLOR; bubbleStroke.Thickness=1.2; bubbleStroke.Transparency=0.4
local bubbleGreeting=Instance.new("TextLabel",bubbleBody)
bubbleGreeting.Size=UDim2.new(1,-20,0,28); bubbleGreeting.Position=UDim2.new(0,14,0,10)
bubbleGreeting.BackgroundTransparency=1; bubbleGreeting.Font=Enum.Font.GothamBold; bubbleGreeting.TextSize=15
bubbleGreeting.TextColor3=THEME_TEXT; bubbleGreeting.TextXAlignment=Enum.TextXAlignment.Left
bubbleGreeting.TextTruncate=Enum.TextTruncate.AtEnd; bubbleGreeting.ClipsDescendants=false
bubbleGreeting.Text="Hey, "..player.DisplayName; bubbleGreeting.ZIndex=3
local bubbleMsg=Instance.new("TextLabel",bubbleBody)
bubbleMsg.Size=UDim2.new(1,-20,0,36); bubbleMsg.Position=UDim2.new(0,14,0,38)
bubbleMsg.BackgroundTransparency=1; bubbleMsg.Font=Enum.Font.Gotham; bubbleMsg.TextSize=13
bubbleMsg.TextColor3=Color3.fromRGB(160,160,160); bubbleMsg.TextXAlignment=Enum.TextXAlignment.Left
bubbleMsg.TextYAlignment=Enum.TextYAlignment.Top; bubbleMsg.TextWrapped=true
bubbleMsg.Text="Welcome back, "..player.DisplayName.."!\nSo glad you're here. Let's get to it."; bubbleMsg.ZIndex=3

-- STATS GRID
local statsContainer = Instance.new("Frame", homePage)
statsContainer.Size=UDim2.new(1,0,0,160); statsContainer.BackgroundTransparency=1
statsContainer.LayoutOrder = 2
local gridLayout=Instance.new("UIGridLayout",statsContainer)
gridLayout.CellSize=UDim2.new(0,148,0,36); gridLayout.CellPadding=UDim2.new(0,8,0,8)
gridLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center; gridLayout.SortOrder=Enum.SortOrder.LayoutOrder

local function createStatusBox(text, color)
    local box=Instance.new("Frame",statsContainer)
    box.BackgroundColor3=Color3.fromRGB(20,20,20); box.BorderSizePixel=0
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,7)
    local stroke = Instance.new("UIStroke", box)
    stroke.Color = SEP_COLOR; stroke.Thickness = 1; stroke.Transparency = 0.4
    local lbl=Instance.new("TextLabel",box)
    lbl.Size=UDim2.new(1,-10,1,-4); lbl.Position=UDim2.new(0,5,0,2)
    lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.Gotham; lbl.TextSize=12
    lbl.TextColor3=color or THEME_TEXT; lbl.Text=text; lbl.TextWrapped=true
    lbl.TextXAlignment=Enum.TextXAlignment.Center; lbl.TextTruncate=Enum.TextTruncate.AtEnd
    return lbl
end

local pingLabel   = createStatusBox("Ping: ...", PB_TEXT)
local lagLabel    = createStatusBox("Lag: ...", Color3.fromRGB(180, 180, 180))
createStatusBox("Acc Age: "..player.AccountAge.."d")
local execLabel   = createStatusBox("Exec: detecting...", Color3.fromRGB(200, 200, 200))
local uptimeLabel = createStatusBox("Uptime: ...", Color3.fromRGB(210, 210, 210))

local rejoinBtn=Instance.new("TextButton",statsContainer)
rejoinBtn.Size=UDim2.new(0,148,0,36); rejoinBtn.BackgroundColor3=BTN_COLOR; rejoinBtn.BorderSizePixel=0
rejoinBtn.Font=Enum.Font.Gotham; rejoinBtn.TextSize=13; rejoinBtn.TextColor3=THEME_TEXT; rejoinBtn.Text="Rejoin"
Instance.new("UICorner",rejoinBtn).CornerRadius=UDim.new(0,7)
local rjStroke = Instance.new("UIStroke", rejoinBtn)
rjStroke.Color = SEP_COLOR; rjStroke.Thickness = 1; rjStroke.Transparency = 0.4
rejoinBtn.MouseEnter:Connect(function() TweenService:Create(rejoinBtn,TweenInfo.new(0.18),{BackgroundColor3=BTN_HOVER}):Play() end)
rejoinBtn.MouseLeave:Connect(function() TweenService:Create(rejoinBtn,TweenInfo.new(0.18),{BackgroundColor3=BTN_COLOR}):Play() end)
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
                    lagLabel.Text = "Bad Ping"; lagLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                elseif ping > 120 then
                    lagLabel.Text = "High Ping"; lagLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
                else
                    lagLabel.Text = "Good Ping"; lagLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
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

-- DISCORD ROW
local discordFrame = Instance.new("Frame", homePage)
discordFrame.Size = UDim2.new(1, 0, 0, 44)
discordFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
discordFrame.BorderSizePixel = 0
discordFrame.LayoutOrder = 3
Instance.new("UICorner", discordFrame).CornerRadius = UDim.new(0, 8)
local discordStroke = Instance.new("UIStroke", discordFrame)
discordStroke.Color = SEP_COLOR; discordStroke.Thickness = 1; discordStroke.Transparency = 0.4

local discordLabel = Instance.new("TextLabel", discordFrame)
discordLabel.Size = UDim2.new(1, -130, 1, 0)
discordLabel.Position = UDim2.new(0, 12, 0, 0)
discordLabel.BackgroundTransparency = 1
discordLabel.Font = Enum.Font.GothamSemibold
discordLabel.TextSize = 13
discordLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
discordLabel.TextXAlignment = Enum.TextXAlignment.Left
discordLabel.Text = "discord.gg/bpfjSze8VB"

local copyBtn = Instance.new("TextButton", discordFrame)
copyBtn.Size = UDim2.new(0, 110, 0, 28)
copyBtn.Position = UDim2.new(1, -118, 0.5, -14)
copyBtn.BackgroundColor3 = BTN_COLOR
copyBtn.Font = Enum.Font.GothamSemibold
copyBtn.TextSize = 12
copyBtn.TextColor3 = THEME_TEXT
copyBtn.Text = "Copy Invite"
copyBtn.BorderSizePixel = 0
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 7)
local copyStroke = Instance.new("UIStroke", copyBtn)
copyStroke.Color = Color3.fromRGB(55, 55, 55); copyStroke.Thickness = 1; copyStroke.Transparency = 0
copyBtn.MouseEnter:Connect(function()
    TweenService:Create(copyBtn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_HOVER}):Play()
end)
copyBtn.MouseLeave:Connect(function()
    TweenService:Create(copyBtn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_COLOR}):Play()
end)
copyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard("https://discord.gg/bpfjSze8VB")
        copyBtn.Text = "Copied"
        task.delay(2, function()
            if copyBtn and copyBtn.Parent then copyBtn.Text = "Copy Invite" end
        end)
    end
end)

-- ════════════════════════════════════════════════════
-- TELEPORT TAB
-- ════════════════════════════════════════════════════
local teleportPage = pages["TeleportTab"]

local locations = {
    {name="Spawn",            x=172,     y=3,      z=74},
    {name="The Den",          x=323,     y=41.8,   z=1930},
    {name="LightHouse",       x=1464.8,  y=355.25, z=3257.2},
    {name="Safari",           x=111.85,  y=11,     z=-998.8},
    {name="Bridge",           x=112.31,  y=11,     z=-782.36},
    {name="Bob's Shack",      x=260,     y=8.4,    z=-2542},
    {name="EndTimesCave",     x=113,     y=-213,   z=-951},
    {name="The Swamp",        x=-1209,   y=132.32, z=-801},
    {name="The Cabin",        x=1244,    y=63.6,   z=2306},
    {name="Volcano",          x=-1585,   y=622.8,  z=1140},
    {name="Boxed Cars",       x=509,     y=3.2,    z=-1463},
    {name="Tiaga Peak",       x=1560,    y=410.32, z=3274},
    {name="Land Store",       x=258,     y=3.2,    z=-99},
    {name="Link's Logic",     x=4605,    y=3,      z=-727},
    {name="Palm Island",      x=2549,    y=-5.9,   z=-42},
    {name="Palm Island 2",    x=1960,    y=-5.9,   z=-1501},
    {name="Palm Island 3",    x=4344,    y=-5.9,   z=-1813},
    {name="Fine Art Shop",    x=5207,    y=-166.2, z=719},
    {name="SnowGlow Biome",   x=-1086.85,y=-5.9,   z=-945.32},
    {name="Cave",             x=3581,    y=-179.54,z=430},
    {name="Shrine Of Sight",  x=-1600,   y=195.4,  z=919},
    {name="Fancy Furnishings",x=491,     y=3.2,    z=-1720},
    {name="Docks",            x=1114,    y=-1.2,   z=-197},
    {name="Strange Man",      x=1061,    y=16.8,   z=1131},
    {name="Wood Dropoff",     x=323.41,  y=-2.8,   z=134.73},
    {name="Snow Biome",       x=889.96,  y=59.8,   z=1195.55},
    {name="Wood RU's",        x=265,     y=3.2,    z=57},
    {name="Green Box",        x=-1668.05,y=349.6,  z=1475.39},
    {name="Cherry Meadow",    x=220.9,   y=59.8,   z=1305.8},
    {name="Bird Cave",        x=4813.1,  y=17.7,   z=-978.8},
}

local tpSearchBarFrame = Instance.new("Frame", teleportPage)
tpSearchBarFrame.Size = UDim2.new(1, 0, 0, 36)
tpSearchBarFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
tpSearchBarFrame.BorderSizePixel = 0
Instance.new("UICorner", tpSearchBarFrame).CornerRadius = UDim.new(0, 9)
local tpSearchBarStroke = Instance.new("UIStroke", tpSearchBarFrame)
tpSearchBarStroke.Color = SEP_COLOR; tpSearchBarStroke.Thickness = 1; tpSearchBarStroke.Transparency = 0.4

local searchBox = Instance.new("TextBox", tpSearchBarFrame)
searchBox.Size = UDim2.new(1, -12, 1, 0)
searchBox.Position = UDim2.new(0, 10, 0, 0)
searchBox.BackgroundTransparency = 1
searchBox.Font = Enum.Font.GothamSemibold
searchBox.TextSize = 13
searchBox.TextColor3 = THEME_TEXT
searchBox.PlaceholderText = "Search locations..."
searchBox.PlaceholderColor3 = Color3.fromRGB(70, 70, 70)
searchBox.Text = ""
searchBox.ClearTextOnFocus = false
searchBox.TextXAlignment = Enum.TextXAlignment.Left

local tpCardGrid = Instance.new("Frame", teleportPage)
tpCardGrid.BackgroundTransparency = 1
tpCardGrid.Size = UDim2.new(1, 0, 0, 0)

local tpGridLayout = Instance.new("UIGridLayout", tpCardGrid)
tpGridLayout.CellSize = UDim2.new(0.5, -5, 0, 52)
tpGridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
tpGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tpGridLayout.SortOrder = Enum.SortOrder.LayoutOrder

tpGridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    tpCardGrid.Size = UDim2.new(1, 0, 0, tpGridLayout.AbsoluteContentSize.Y)
end)

local tpCards = {}

local function makeTpCard(loc, idx)
    local card = Instance.new("Frame", tpCardGrid)
    card.Name = loc.name
    card.LayoutOrder = idx
    card.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

    local accent = Instance.new("Frame", card)
    accent.Size = UDim2.new(0, 3, 0.7, 0)
    accent.Position = UDim2.new(0, 0, 0.15, 0)
    accent.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    accent.BorderSizePixel = 0
    Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)

    local nameLbl = Instance.new("TextLabel", card)
    nameLbl.Size = UDim2.new(1, -8, 1, 0)
    nameLbl.Position = UDim2.new(0, 8, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 12
    nameLbl.TextColor3 = THEME_TEXT
    nameLbl.TextXAlignment = Enum.TextXAlignment.Center
    nameLbl.TextYAlignment = Enum.TextYAlignment.Center
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.Text = loc.name

    local btn = Instance.new("TextButton", card)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""; btn.ZIndex = 10
    btn.AutoButtonColor = false

    btn.MouseEnter:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(28, 28, 28)}):Play()
        TweenService:Create(accent, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(80, 80, 80)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(16, 16, 16)}):Play()
        TweenService:Create(accent, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(55, 55, 55)}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(loc.x, loc.y + 3, loc.z)
        end
        TweenService:Create(card, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
        task.delay(0.12, function()
            TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(16, 16, 16)}):Play()
        end)
    end)

    return card
end

for i, loc in ipairs(locations) do
    local card = makeTpCard(loc, i)
    table.insert(tpCards, {card = card, name = string.lower(loc.name)})
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local query = string.lower(searchBox.Text)
    local order = 1
    for _, entry in ipairs(tpCards) do
        local visible = query == "" or string.find(entry.name, query, 1, true)
        entry.card.Visible = visible ~= nil
        if entry.card.Visible then
            entry.card.LayoutOrder = order
            order = order + 1
        end
    end
end)

-- ════════════════════════════════════════════════════
-- SHARED ITEM/DUPE STATE
-- ════════════════════════════════════════════════════
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
local useCustomDest       = false
local tpCircle            = nil

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
    local btnStr = Instance.new("UIStroke", btn)
    btnStr.Color = Color3.fromRGB(55, 55, 55); btnStr.Thickness = 1; btnStr.Transparency = 0
    btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=BTN_HOVER}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=BTN_COLOR}):Play() end)
    if cb then btn.MouseButton1Click:Connect(cb) end
    return btn
end

local function iToggle(text, default, cb)
    local frame = Instance.new("Frame", itemPage)
    frame.Size = UDim2.new(1, 0, 0, 36); frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -54, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13; lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local tb = Instance.new("TextButton", frame)
    tb.Size = UDim2.new(0, 36, 0, 20); tb.Position = UDim2.new(1, -46, 0.5, -10)
    tb.BackgroundColor3 = default and SW_ON or SW_OFF
    tb.Text = ""; tb.BorderSizePixel = 0
    Instance.new("UICorner", tb).CornerRadius = UDim.new(1, 0)
    local circle = Instance.new("Frame", tb)
    circle.Size = UDim2.new(0, 14, 0, 14)
    circle.Position = UDim2.new(0, default and 20 or 2, 0.5, -7)
    circle.BackgroundColor3 = default and SW_KNOB_ON or SW_KNOB_OFF; circle.BorderSizePixel = 0
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    local toggled = default
    if cb then cb(toggled) end
    tb.MouseButton1Click:Connect(function()
        toggled = not toggled
        TweenService:Create(tb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            BackgroundColor3 = toggled and SW_ON or SW_OFF
        }):Play()
        TweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, toggled and 20 or 2, 0.5, -7),
            BackgroundColor3 = toggled and SW_KNOB_ON or SW_KNOB_OFF
        }):Play()
        if cb then cb(toggled) end
    end)
    return frame
end

local function iSlider(text, minV, maxV, defV, cb)
    local frame = Instance.new("Frame", itemPage)
    frame.Size = UDim2.new(1, 0, 0, 54); frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
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
    valLbl.TextColor3 = PB_TEXT; valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Text = tostring(defV)
    local track = Instance.new("Frame", frame)
    track.Size = UDim2.new(1, -16, 0, 5); track.Position = UDim2.new(0, 8, 0, 38)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 40); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((defV-minV)/(maxV-minV), 0, 1, 0)
    fill.BackgroundColor3 = PB_BAR; fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0, 14, 0, 14); knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((defV-minV)/(maxV-minV), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255); knob.Text = ""; knob.BorderSizePixel = 0
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
    sb.Color3 = Color3.fromRGB(180,180,180)
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
lassoFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
lassoFrame.BackgroundTransparency = 0.82; lassoFrame.BorderSizePixel = 0
lassoFrame.Visible = false; lassoFrame.ZIndex = 20
local lassoStroke = Instance.new("UIStroke", lassoFrame)
lassoStroke.Color = Color3.fromRGB(200,200,200); lassoStroke.Thickness = 1.5; lassoStroke.Transparency = 0

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

-- ── Selection ────────────────────────────────────────
iSectionLabel("Selection")
iToggle("Click Select", false, function(val)
    clickSelectEnabled = val
    if val then lassoEnabled = false; groupSelectEnabled = false end
end)
iToggle("Lasso Select", false, function(val)
    lassoEnabled = val
    if val then clickSelectEnabled = false; groupSelectEnabled = false end
end)
iToggle("Group Select", false, function(val)
    groupSelectEnabled = val
    if val then clickSelectEnabled = false; lassoEnabled = false end
end)
iButton("Deselect All", function() deselectAll() end)

iSep()

-- ── Teleport ─────────────────────────────────────────
iSectionLabel("Teleport")
iSlider("Delay", 1, 20, 3, function(v) tpItemSpeed = v / 10 end)

-- Sort mode row
local itemModeRow = Instance.new("Frame", itemPage)
itemModeRow.Size = UDim2.new(1, 0, 0, 30); itemModeRow.BackgroundTransparency = 1

local itemModeButtons = {}
local itemModeNames = {"Group", "Random"}
local itemTpMode = "group"

local function updateItemModeButtons(active)
    for _, mb in ipairs(itemModeButtons) do
        local isActive = mb.Text == active
        TweenService:Create(mb, TweenInfo.new(0.18), {
            BackgroundColor3 = isActive and Color3.fromRGB(110,110,110) or BTN_COLOR,
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

-- Custom destination row (hidden until toggle is ON)
local tpDestRow = Instance.new("Frame", itemPage)
tpDestRow.Size = UDim2.new(1, 0, 0, 30)
tpDestRow.BackgroundTransparency = 1
tpDestRow.Visible = false

local tpSetBtn = Instance.new("TextButton", tpDestRow)
tpSetBtn.Size = UDim2.new(0.5, -4, 1, 0); tpSetBtn.Position = UDim2.new(0, 0, 0, 0)
tpSetBtn.BackgroundColor3 = BTN_COLOR; tpSetBtn.Font = Enum.Font.GothamSemibold
tpSetBtn.TextSize = 12; tpSetBtn.TextColor3 = THEME_TEXT; tpSetBtn.Text = "Set Destination"
tpSetBtn.BorderSizePixel = 0
Instance.new("UICorner", tpSetBtn).CornerRadius = UDim.new(0, 7)

local tpRemoveBtn = Instance.new("TextButton", tpDestRow)
tpRemoveBtn.Size = UDim2.new(0.5, -4, 1, 0); tpRemoveBtn.Position = UDim2.new(0.5, 4, 0, 0)
tpRemoveBtn.BackgroundColor3 = BTN_COLOR; tpRemoveBtn.Font = Enum.Font.GothamSemibold
tpRemoveBtn.TextSize = 12; tpRemoveBtn.TextColor3 = THEME_TEXT; tpRemoveBtn.Text = "Clear Destination"
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

iToggle("Custom Destination", false, function(val)
    useCustomDest = val
    tpDestRow.Visible = val
    if not val and tpCircle then
        tpCircle:Destroy(); tpCircle = nil
    end
end)

iSep()

-- ── Actions ───────────────────────────────────────────
iSectionLabel("Actions")

local tpSelectBtn = iButton("Teleport Selected", function() end)
tpSelectBtn.MouseButton1Click:Connect(function()
    if isTeleportingItems then
        stopTeleportItems = true; return
    end
    if useCustomDest and not tpCircle then return end

    isTeleportingItems = true; stopTeleportItems = false
    tpSelectBtn.Text = "Stop"
    TweenService:Create(tpSelectBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50,50,50)}):Play()

    local destCF = useCustomDest
        and tpCircle.CFrame
        or (player.Character
            and player.Character:FindFirstChild("HumanoidRootPart")
            and player.Character.HumanoidRootPart.CFrame)

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
            if not hrp then task.wait(tpItemSpeed); continue end
            hrp.CFrame = CFrame.new(part.CFrame.p) * CFrame.new(5, 0, 0)
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

iButton("Sell Selected", function()
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
    local btnStr = Instance.new("UIStroke", btn)
    btnStr.Color = Color3.fromRGB(55, 55, 55); btnStr.Thickness = 1; btnStr.Transparency = 0
    btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=BTN_HOVER}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=BTN_COLOR}):Play() end)
    if cb then btn.MouseButton1Click:Connect(cb) end
    return btn
end

dSectionLabel("Info")

-- ════════════════════════════════════════════════════
-- SEARCH TAB
-- ════════════════════════════════════════════════════
local searchTabPage = pages["SearchTab"]
local searchTabList = searchTabPage:FindFirstChildOfClass("UIListLayout")
if searchTabList then searchTabList.Padding = UDim.new(0, 6) end

local allFeatures = {
    {"Walkspeed",        "PlayerTab"}, {"Jumppower",          "PlayerTab"},
    {"Fly Speed",        "PlayerTab"}, {"Fly Hotkey",         "PlayerTab"},
    {"Fly",              "PlayerTab"}, {"Noclip",             "PlayerTab"},
    {"InfJump",          "PlayerTab"}, {"Hard Dragger",       "PlayerTab"},
    {"Always Day",       "WorldTab"},  {"Always Night",       "WorldTab"},
    {"Remove Fog",       "WorldTab"},  {"Shadows",            "WorldTab"},
    {"Walk On Water",    "WorldTab"},  {"Remove Water",       "WorldTab"},
    {"Spawn",            "TeleportTab"}, {"The Den",          "TeleportTab"},
    {"LightHouse",       "TeleportTab"}, {"Safari",           "TeleportTab"},
    {"Bridge",           "TeleportTab"}, {"Bob's Shack",      "TeleportTab"},
    {"EndTimesCave",     "TeleportTab"}, {"The Swamp",        "TeleportTab"},
    {"The Cabin",        "TeleportTab"}, {"Volcano",          "TeleportTab"},
    {"Boxed Cars",       "TeleportTab"}, {"Tiaga Peak",       "TeleportTab"},
    {"Land Store",       "TeleportTab"}, {"Link's Logic",     "TeleportTab"},
    {"Palm Island",      "TeleportTab"}, {"Palm Island 2",    "TeleportTab"},
    {"Palm Island 3",    "TeleportTab"}, {"Fine Art Shop",    "TeleportTab"},
    {"SnowGlow Biome",   "TeleportTab"}, {"Cave",             "TeleportTab"},
    {"Shrine Of Sight",  "TeleportTab"}, {"Fancy Furnishings","TeleportTab"},
    {"Docks",            "TeleportTab"}, {"Strange Man",      "TeleportTab"},
    {"Wood Dropoff",     "TeleportTab"}, {"Snow Biome",       "TeleportTab"},
    {"Wood RU's",        "TeleportTab"}, {"Green Box",        "TeleportTab"},
    {"Cherry Meadow",    "TeleportTab"}, {"Bird Cave",        "TeleportTab"},
    {"Click Selection",  "ItemTab"},   {"Lasso Tool",         "ItemTab"},
    {"Group Selection",  "ItemTab"},   {"Delay Per Item",     "ItemTab"},
    {"Teleport Mode",    "ItemTab"},   {"Teleport Selected",  "ItemTab"},
    {"Sell Selected",    "ItemTab"},   {"Deselect All",       "ItemTab"},
    {"Grid Size",        "Pixel ArtTab"}, {"Rotation Step",  "Pixel ArtTab"},
    {"Follow Mouse",     "Pixel ArtTab"}, {"Snap to Grid",   "Pixel ArtTab"},
    {"Center on Plot",   "Pixel ArtTab"}, {"Remove Pixel Art","Pixel ArtTab"},
}

local stInputFrame = Instance.new("Frame", searchTabPage)
stInputFrame.Size = UDim2.new(1, 0, 0, 36)
stInputFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
stInputFrame.BorderSizePixel = 0
Instance.new("UICorner", stInputFrame).CornerRadius = UDim.new(0, 9)
local stInputStroke = Instance.new("UIStroke", stInputFrame)
stInputStroke.Color = SEP_COLOR; stInputStroke.Thickness = 1; stInputStroke.Transparency = 0.4

local stInput = Instance.new("TextBox", stInputFrame)
stInput.Size = UDim2.new(1, -12, 1, 0)
stInput.Position = UDim2.new(0, 10, 0, 0)
stInput.BackgroundTransparency = 1
stInput.Font = Enum.Font.GothamSemibold
stInput.TextSize = 13
stInput.TextColor3 = THEME_TEXT
stInput.PlaceholderText = "Search features"
stInput.PlaceholderColor3 = Color3.fromRGB(60, 60, 60)
stInput.Text = ""
stInput.ClearTextOnFocus = false
stInput.TextXAlignment = Enum.TextXAlignment.Left

local featureRows = {}

for _, entry in ipairs(allFeatures) do
    local label   = entry[1]
    local tabName = entry[2]

    local row = Instance.new("Frame", searchTabPage)
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    row.BorderSizePixel = 0
    row.Visible = false
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

    local nameLbl = Instance.new("TextLabel", row)
    nameLbl.Size = UDim2.new(0.62, -8, 1, 0)
    nameLbl.Position = UDim2.new(0, 10, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font = Enum.Font.GothamSemibold
    nameLbl.TextSize = 12
    nameLbl.TextColor3 = THEME_TEXT
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.Text = label

    local tabLbl = Instance.new("TextLabel", row)
    tabLbl.Size = UDim2.new(0.38, -10, 1, 0)
    tabLbl.Position = UDim2.new(0.62, 0, 0, 0)
    tabLbl.BackgroundTransparency = 1
    tabLbl.Font = Enum.Font.Gotham
    tabLbl.TextSize = 10
    tabLbl.TextColor3 = Color3.fromRGB(70, 70, 70)
    tabLbl.TextXAlignment = Enum.TextXAlignment.Right
    tabLbl.TextTruncate = Enum.TextTruncate.AtEnd
    tabLbl.Text = tabName:gsub("Tab", "")

    local goBtn = Instance.new("TextButton", row)
    goBtn.Size = UDim2.new(1, 0, 1, 0)
    goBtn.BackgroundTransparency = 1
    goBtn.Text = ""
    goBtn.ZIndex = 10
    goBtn.AutoButtonColor = false
    goBtn.MouseEnter:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(26, 26, 26)}):Play()
    end)
    goBtn.MouseLeave:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(16, 16, 16)}):Play()
    end)
    goBtn.MouseButton1Click:Connect(function()
        if _G.VH and _G.VH.switchTab then _G.VH.switchTab(tabName) end
    end)

    table.insert(featureRows, {row = row, lower = string.lower(label)})
end

stInput:GetPropertyChangedSignal("Text"):Connect(function()
    local q = string.lower(stInput.Text)
    for _, entry in ipairs(featureRows) do
        entry.row.Visible = (q ~= "" and string.find(entry.lower, q, 1, true) ~= nil)
    end
end)

-- ════════════════════════════════════════════════════
-- GLOBAL KEY LISTENER
-- ════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == currentToggleKey then
        toggleGUI()
        return
    end
end)

-- ════════════════════════════════════════════════════
-- SHARED GLOBALS
-- ════════════════════════════════════════════════════
_G.VH = {
    TweenService      = TweenService,
    Players           = Players,
    UserInputService  = UserInputService,
    RunService        = RunService,
    TeleportService   = TeleportService,
    Stats             = Stats,
    player            = player,
    cleanupTasks      = cleanupTasks,
    pages             = pages,
    tabs              = tabs,
    BTN_COLOR         = BTN_COLOR,
    BTN_HOVER         = BTN_HOVER,
    THEME_TEXT        = THEME_TEXT,
    ACCENT            = ACCENT,
    SEP_COLOR         = SEP_COLOR,
    SECTION_TEXT      = SECTION_TEXT,
    SW_ON             = SW_ON,
    SW_OFF            = SW_OFF,
    SW_KNOB_ON        = SW_KNOB_ON,
    SW_KNOB_OFF       = SW_KNOB_OFF,
    PB_BAR            = PB_BAR,
    PB_TEXT           = PB_TEXT,
    switchTab         = switchTab,
    toggleGUI         = toggleGUI,
    butter            = { running = false, thread = nil },
    isFlyActive       = false,
    flyEnabled        = true,
    currentFlyKey     = Enum.KeyCode.Q,
    waitingForFlyKey  = false,
    flyKeyBtn         = nil,
    currentToggleKey  = currentToggleKey,
    keybindButtonGUI  = nil,
}

_G.VanillaHubCleanup = onExit

print("[VanillaHub] v1.1.0 loaded — execute Vanilla5 for Player / World / Pixel Art tabs")
