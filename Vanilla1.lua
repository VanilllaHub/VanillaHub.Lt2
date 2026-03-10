-- DESTROY OLD GUI + cleanup (also kills all active connections from a previous run)
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
        msg.TextColor3 = Color3.fromRGB(230, 206, 226); msg.TextXAlignment = Enum.TextXAlignment.Left
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
local player            = Players.LocalPlayer
local mouse             = player:GetMouse()

local THEME_TEXT = Color3.fromRGB(230, 206, 226)

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
        if hum then hum.PlatformStand = false; hum.WalkSpeed = 16; hum.JumpPower = 50 end
        if hrp then
            for _, obj in ipairs(hrp:GetChildren()) do
                if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") then pcall(function() obj:Destroy() end) end
            end
        end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide = true end) end
        end
    end)
    pcall(function()
        if workspace:FindFirstChild("VanillaHubTpCircle") then workspace.VanillaHubTpCircle:Destroy() end
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
wrapper.Position = UDim2.new(0.5, -270, 0.5, -175)
wrapper.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
wrapper.BackgroundTransparency = 1; wrapper.BorderSizePixel = 0; wrapper.ClipsDescendants = false
Instance.new("UICorner", wrapper).CornerRadius = UDim.new(0, 14)

local main = Instance.new("Frame", wrapper)
main.Size = UDim2.new(1, 0, 1, 0); main.Position = UDim2.new(0, 0, 0, 0)
main.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
main.BackgroundTransparency = 1; main.BorderSizePixel = 0; main.ClipsDescendants = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

-- Subtle border stroke on main
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = Color3.fromRGB(45, 35, 50)
mainStroke.Thickness = 1.2
mainStroke.Transparency = 0.4

TweenService:Create(wrapper, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 540, 0, 350), BackgroundTransparency = 0
}):Play()
TweenService:Create(main, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    BackgroundTransparency = 0
}):Play()

-- TOP BAR
local topBar = Instance.new("Frame", main)
topBar.Size = UDim2.new(1, 0, 0, 40); topBar.BackgroundColor3 = Color3.fromRGB(10, 10, 13)
topBar.BorderSizePixel = 0; topBar.ZIndex = 4

-- Separator line under top bar (subtle)
local topBarSep = Instance.new("Frame", main)
topBarSep.Size = UDim2.new(1, 0, 0, 1)
topBarSep.Position = UDim2.new(0, 0, 0, 40)
topBarSep.BackgroundColor3 = Color3.fromRGB(35, 25, 40)
topBarSep.BorderSizePixel = 0
topBarSep.ZIndex = 4

local hubIcon = Instance.new("ImageLabel", topBar)
hubIcon.Size = UDim2.new(0, 26, 0, 26); hubIcon.Position = UDim2.new(0, 10, 0.5, -13)
hubIcon.BackgroundTransparency = 1; hubIcon.BorderSizePixel = 0
hubIcon.ScaleType = Enum.ScaleType.Fit; hubIcon.ZIndex = 6
hubIcon.Image = "rbxassetid://97128823316544"
Instance.new("UICorner", hubIcon).CornerRadius = UDim.new(0, 5)

local titleLbl = Instance.new("TextLabel", topBar)
titleLbl.Size = UDim2.new(1, -90, 1, 0); titleLbl.Position = UDim2.new(0, 44, 0, 0)
titleLbl.BackgroundTransparency = 1; titleLbl.Text = "VanillaHub"
titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 16
titleLbl.TextColor3 = THEME_TEXT; titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.ZIndex = 5

local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, 30, 0, 30); closeBtn.Position = UDim2.new(1, -38, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(160, 38, 38); closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255); closeBtn.BorderSizePixel = 0; closeBtn.ZIndex = 5
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
closeBtn.MouseEnter:Connect(function() TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(210, 55, 55)}):Play() end)
closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(160, 38, 38)}):Play() end)

local function showConfirmClose()
    if main:FindFirstChild("ConfirmOverlay") then return end
    local overlay = Instance.new("Frame", main)
    overlay.Name = "ConfirmOverlay"; overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0); overlay.BackgroundTransparency = 0.45; overlay.ZIndex = 9
    local dialog = Instance.new("Frame", main)
    dialog.Name = "ConfirmDialog"; dialog.Size = UDim2.new(0, 360, 0, 180)
    dialog.Position = UDim2.new(0.5, -180, 0.5, -90)
    dialog.BackgroundColor3 = Color3.fromRGB(16, 16, 20); dialog.BorderSizePixel = 0; dialog.ZIndex = 10
    Instance.new("UICorner", dialog).CornerRadius = UDim.new(0, 14)
    local dStroke = Instance.new("UIStroke", dialog)
    dStroke.Color = Color3.fromRGB(60, 50, 70); dStroke.Thickness = 1.2; dStroke.Transparency = 0.5
    local dtitle = Instance.new("TextLabel", dialog)
    dtitle.Size = UDim2.new(1, 0, 0, 40); dtitle.BackgroundTransparency = 1
    dtitle.Font = Enum.Font.GothamBold; dtitle.TextSize = 18
    dtitle.TextColor3 = THEME_TEXT; dtitle.Text = "Confirm Exit"; dtitle.ZIndex = 11
    local dmsg = Instance.new("TextLabel", dialog)
    dmsg.Size = UDim2.new(1, -40, 0, 60); dmsg.Position = UDim2.new(0, 20, 0, 45)
    dmsg.BackgroundTransparency = 1; dmsg.Font = Enum.Font.Gotham; dmsg.TextSize = 14
    dmsg.TextColor3 = Color3.fromRGB(180, 165, 180)
    dmsg.Text = "Are you sure you want to close VanillaHub?\nYou will need to re-execute to use it again."
    dmsg.TextWrapped = true; dmsg.TextYAlignment = Enum.TextYAlignment.Center; dmsg.ZIndex = 11
    local cancelBtn2 = Instance.new("TextButton", dialog)
    cancelBtn2.Size = UDim2.new(0, 150, 0, 44); cancelBtn2.Position = UDim2.new(0.5, -160, 1, -62)
    cancelBtn2.BackgroundColor3 = Color3.fromRGB(38, 38, 46); cancelBtn2.Text = "Cancel"
    cancelBtn2.Font = Enum.Font.GothamSemibold; cancelBtn2.TextSize = 15
    cancelBtn2.TextColor3 = THEME_TEXT; cancelBtn2.ZIndex = 11; cancelBtn2.BorderSizePixel = 0
    Instance.new("UICorner", cancelBtn2).CornerRadius = UDim.new(0, 10)
    local confirmBtn2 = Instance.new("TextButton", dialog)
    confirmBtn2.Size = UDim2.new(0, 150, 0, 44); confirmBtn2.Position = UDim2.new(0.5, 10, 1, -62)
    confirmBtn2.BackgroundColor3 = Color3.fromRGB(160, 40, 40); confirmBtn2.Text = "Exit"
    confirmBtn2.Font = Enum.Font.GothamSemibold; confirmBtn2.TextSize = 15
    confirmBtn2.TextColor3 = Color3.fromRGB(255, 255, 255); confirmBtn2.ZIndex = 11; confirmBtn2.BorderSizePixel = 0
    Instance.new("UICorner", confirmBtn2).CornerRadius = UDim.new(0, 10)
    for _, b in {cancelBtn2, confirmBtn2} do
        b.MouseEnter:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.15), {
                BackgroundColor3 = (b == confirmBtn2) and Color3.fromRGB(200,55,55) or Color3.fromRGB(55,55,68)
            }):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.15), {
                BackgroundColor3 = (b == confirmBtn2) and Color3.fromRGB(160,40,40) or Color3.fromRGB(38,38,46)
            }):Play()
        end)
    end
    cancelBtn2.MouseButton1Click:Connect(function() overlay:Destroy(); dialog:Destroy() end)
    confirmBtn2.MouseButton1Click:Connect(function()
        overlay:Destroy(); dialog:Destroy()
        onExit()
        local t = TweenService:Create(wrapper, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0,0,0,0), BackgroundTransparency = 1
        })
        t:Play()
        t.Completed:Connect(function() if gui and gui.Parent then gui:Destroy() end end)
    end)
end

closeBtn.MouseButton1Click:Connect(showConfirmClose)

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
-- SIDE PANEL — slightly wider, cleaner
-- ════════════════════════════════════════════════════
local side = Instance.new("ScrollingFrame", main)
side.Size = UDim2.new(0, 168, 1, -41); side.Position = UDim2.new(0, 0, 0, 41)
side.BackgroundColor3 = Color3.fromRGB(8, 8, 10); side.BorderSizePixel = 0
side.ScrollBarThickness = 3; side.ScrollBarImageColor3 = Color3.fromRGB(55, 45, 65)
side.CanvasSize = UDim2.new(0, 0, 0, 0)

-- Vertical separator between side and content (no white line)
local sideSep = Instance.new("Frame", main)
sideSep.Size = UDim2.new(0, 1, 1, -41)
sideSep.Position = UDim2.new(0, 168, 0, 41)
sideSep.BackgroundColor3 = Color3.fromRGB(30, 22, 36)
sideSep.BorderSizePixel = 0
sideSep.ZIndex = 3

local sideLayout = Instance.new("UIListLayout", side)
sideLayout.Padding = UDim.new(0, 4); sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
local sidePadding = Instance.new("UIPadding", side)
sidePadding.PaddingTop = UDim.new(0, 10)
sideLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    side.CanvasSize = UDim2.new(0, 0, 0, sideLayout.AbsoluteContentSize.Y + 24)
end)

-- CONTENT AREA
local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, -169, 1, -41); content.Position = UDim2.new(0, 169, 0, 41)
content.BackgroundColor3 = Color3.fromRGB(8, 8, 10); content.BorderSizePixel = 0

-- WELCOME POPUP
task.spawn(function()
    task.wait(0.8)
    if not (gui and gui.Parent) then return end
    local wf = Instance.new("Frame", gui)
    wf.Size = UDim2.new(0, 380, 0, 90); wf.Position = UDim2.new(0.5, -190, 1, -110)
    wf.BackgroundColor3 = Color3.fromRGB(12, 12, 16); wf.BackgroundTransparency = 1; wf.BorderSizePixel = 0
    Instance.new("UICorner", wf).CornerRadius = UDim.new(0, 14)
    local ws = Instance.new("UIStroke", wf)
    ws.Color = Color3.fromRGB(45,35,55); ws.Thickness = 1.2; ws.Transparency = 0.5
    local pfp = Instance.new("ImageLabel", wf)
    pfp.Size = UDim2.new(0, 64, 0, 64); pfp.Position = UDim2.new(0, 18, 0.5, -32)
    pfp.BackgroundTransparency = 1; pfp.ImageTransparency = 1
    pfp.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    Instance.new("UICorner", pfp).CornerRadius = UDim.new(1, 0)
    local wt = Instance.new("TextLabel", wf)
    wt.Size = UDim2.new(1, -100, 1, -20); wt.Position = UDim2.new(0, 96, 0, 10)
    wt.BackgroundTransparency = 1; wt.Font = Enum.Font.GothamSemibold; wt.TextSize = 17
    wt.TextColor3 = THEME_TEXT; wt.TextXAlignment = Enum.TextXAlignment.Left
    wt.TextYAlignment = Enum.TextYAlignment.Center; wt.TextWrapped = true; wt.TextTransparency = 1
    wt.Text = "Welcome back,\n" .. player.DisplayName
    TweenService:Create(wf, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.3}):Play()
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
    page.ScrollBarThickness = 4; page.ScrollBarImageColor3 = Color3.fromRGB(60, 50, 80)
    page.Visible = false; page.CanvasSize = UDim2.new(0, 0, 0, 0)
    local list = Instance.new("UIListLayout", page)
    list.Padding = UDim.new(0, 10); list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.SortOrder = Enum.SortOrder.LayoutOrder
    local pad = Instance.new("UIPadding", page)
    pad.PaddingTop = UDim.new(0, 14); pad.PaddingBottom = UDim.new(0, 16)
    pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12)
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 40)
    end)
    pages[name .. "Tab"] = page
end

-- TAB SWITCHING
local activeTabButton = nil
local TAB_ACTIVE_BG    = Color3.fromRGB(36, 28, 44)
local TAB_ACTIVE_TEXT  = THEME_TEXT
local TAB_IDLE_BG      = Color3.fromRGB(12, 12, 15)
local TAB_HOVER_BG     = Color3.fromRGB(26, 20, 34)
local TAB_IDLE_TEXT    = Color3.fromRGB(140, 130, 150)
local TAB_HOVER_TEXT   = Color3.fromRGB(200, 185, 210)

local function switchTab(targetName)
    for _, page in pairs(pages) do page.Visible = (page.Name == targetName) end
    if activeTabButton then
        TweenService:Create(activeTabButton, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {
            BackgroundColor3 = TAB_IDLE_BG, TextColor3 = TAB_IDLE_TEXT,
            Size = UDim2.new(0.94, 0, 0, 38)
        }):Play()
        local ind = activeTabButton:FindFirstChild("ActiveIndicator")
        if ind then TweenService:Create(ind, TweenInfo.new(0.22), {BackgroundTransparency = 1}):Play() end
    end
    local btn = side:FindFirstChild(targetName:gsub("Tab",""))
    if btn then
        activeTabButton = btn
        TweenService:Create(btn, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {
            BackgroundColor3 = TAB_ACTIVE_BG, TextColor3 = TAB_ACTIVE_TEXT,
            Size = UDim2.new(0.96, 0, 0, 40)
        }):Play()
        local ind = btn:FindFirstChild("ActiveIndicator")
        if ind then TweenService:Create(ind, TweenInfo.new(0.22), {BackgroundTransparency = 0}):Play() end
    end
end

for _, name in ipairs(tabs) do
    local btn = Instance.new("TextButton", side)
    btn.Name = name; btn.Size = UDim2.new(0.94, 0, 0, 38)
    btn.BackgroundColor3 = TAB_IDLE_BG; btn.BorderSizePixel = 0
    btn.Text = name; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = TAB_IDLE_TEXT; btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local pad2 = Instance.new("UIPadding", btn); pad2.PaddingLeft = UDim.new(0, 14)

    -- Active left indicator bar
    local indicator = Instance.new("Frame", btn)
    indicator.Name = "ActiveIndicator"
    indicator.Size = UDim2.new(0, 3, 0.65, 0)
    indicator.Position = UDim2.new(0, 0, 0.5, 0)
    indicator.AnchorPoint = Vector2.new(0, 0.5)
    indicator.BackgroundColor3 = THEME_TEXT
    indicator.BackgroundTransparency = 1
    indicator.BorderSizePixel = 0
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

    -- Ripple container
    local rippleContainer = Instance.new("Frame", btn)
    rippleContainer.Size = UDim2.new(1,0,1,0); rippleContainer.BackgroundTransparency = 1
    rippleContainer.BorderSizePixel = 0; rippleContainer.ZIndex = 2; rippleContainer.ClipsDescendants = true
    Instance.new("UICorner", rippleContainer).CornerRadius = UDim.new(0, 8)

    btn.MouseEnter:Connect(function()
        if activeTabButton ~= btn then
            TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
                BackgroundColor3 = TAB_HOVER_BG, TextColor3 = TAB_HOVER_TEXT,
                Size = UDim2.new(0.95, 0, 0, 39)
            }):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeTabButton ~= btn then
            TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
                BackgroundColor3 = TAB_IDLE_BG, TextColor3 = TAB_IDLE_TEXT,
                Size = UDim2.new(0.94, 0, 0, 38)
            }):Play()
        end
    end)
    btn.MouseButton1Click:Connect(function()
        -- Ripple
        task.spawn(function()
            local ripple = Instance.new("Frame", rippleContainer)
            ripple.Size = UDim2.new(0, 6, 0, 6)
            ripple.Position = UDim2.new(0.5, -3, 0.5, -3)
            ripple.BackgroundColor3 = Color3.fromRGB(210, 190, 220)
            ripple.BackgroundTransparency = 0.72; ripple.BorderSizePixel = 0
            Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)
            TweenService:Create(ripple, TweenInfo.new(0.36, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 130, 0, 130),
                Position = UDim2.new(0.5, -65, 0.5, -65),
                BackgroundTransparency = 1
            }):Play()
            task.wait(0.4)
            if ripple and ripple.Parent then ripple:Destroy() end
        end)
        switchTab(name.."Tab")
    end)
end

switchTab("HomeTab")

-- ════════════════════════════════════════════════════
-- GUI TOGGLE (hide only main, no fog changes)
-- ════════════════════════════════════════════════════
local currentToggleKey = Enum.KeyCode.LeftAlt
local guiOpen = true
local isAnimatingGUI = false
local keybindButtonGUI

local function toggleGUI()
    if isAnimatingGUI then return end
    guiOpen = not guiOpen; isAnimatingGUI = true
    if guiOpen then
        wrapper.Visible = true
        TweenService:Create(wrapper, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 540, 0, 350), BackgroundTransparency = 0
        }):Play()
        local t = TweenService:Create(main, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0
        })
        t:Play()
        t.Completed:Connect(function() isAnimatingGUI = false end)
    else
        local t = TweenService:Create(wrapper, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1
        })
        TweenService:Create(main, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            BackgroundTransparency = 1
        }):Play()
        t:Play()
        t.Completed:Connect(function()
            wrapper.Visible = false
            isAnimatingGUI = false
        end)
    end
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == currentToggleKey then
        toggleGUI()
    end
end)

-- ════════════════════════════════════════════════════
-- HOME TAB
-- ════════════════════════════════════════════════════
local homePage = pages["HomeTab"]

local bubbleRow = Instance.new("Frame", homePage)
bubbleRow.Size = UDim2.new(1,0,0,100); bubbleRow.BackgroundTransparency = 1

local bubbleIcon = Instance.new("ImageLabel", bubbleRow)
bubbleIcon.Size=UDim2.new(0,52,0,52); bubbleIcon.Position=UDim2.new(0,6,0.5,-26)
bubbleIcon.BackgroundColor3=Color3.fromRGB(20,14,22); bubbleIcon.BorderSizePixel=0
bubbleIcon.ScaleType=Enum.ScaleType.Fit; bubbleIcon.Image="rbxassetid://97128823316544"
Instance.new("UICorner", bubbleIcon).CornerRadius = UDim.new(1,0)
local iconStroke = Instance.new("UIStroke", bubbleIcon)
iconStroke.Color=Color3.fromRGB(230,206,226); iconStroke.Thickness=1.8; iconStroke.Transparency=0.45

local iconName = Instance.new("TextLabel", bubbleRow)
iconName.Size=UDim2.new(0,64,0,16); iconName.Position=UDim2.new(0,0,0.5,28)
iconName.BackgroundTransparency=1; iconName.Font=Enum.Font.GothamBold; iconName.TextSize=10
iconName.TextColor3=THEME_TEXT; iconName.TextXAlignment=Enum.TextXAlignment.Center; iconName.Text="Vanilla"

local tailShape = Instance.new("Frame", bubbleRow)
tailShape.Size=UDim2.new(0,14,0,14); tailShape.Position=UDim2.new(0,64,0.5,-7)
tailShape.Rotation=45; tailShape.BackgroundColor3=Color3.fromRGB(36,22,38); tailShape.BorderSizePixel=0; tailShape.ZIndex=1

local bubbleBody = Instance.new("Frame", bubbleRow)
bubbleBody.Size=UDim2.new(1,-82,0,84); bubbleBody.Position=UDim2.new(0,72,0.5,-42)
bubbleBody.BackgroundColor3=Color3.fromRGB(36,22,38); bubbleBody.BorderSizePixel=0; bubbleBody.ZIndex=2
Instance.new("UICorner", bubbleBody).CornerRadius=UDim.new(0,14)
local bubbleStroke=Instance.new("UIStroke",bubbleBody)
bubbleStroke.Color=Color3.fromRGB(230,206,226); bubbleStroke.Thickness=1.4; bubbleStroke.Transparency=0.55
local bubbleGrad=Instance.new("UIGradient",bubbleBody)
bubbleGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(52,30,54)),ColorSequenceKeypoint.new(1,Color3.fromRGB(28,16,30))})
bubbleGrad.Rotation=135
local bubbleGreeting=Instance.new("TextLabel",bubbleBody)
bubbleGreeting.Size=UDim2.new(1,-20,0,28); bubbleGreeting.Position=UDim2.new(0,14,0,10)
bubbleGreeting.BackgroundTransparency=1; bubbleGreeting.Font=Enum.Font.GothamBold; bubbleGreeting.TextSize=17
bubbleGreeting.TextColor3=THEME_TEXT; bubbleGreeting.TextXAlignment=Enum.TextXAlignment.Left
bubbleGreeting.Text="Hey "..player.DisplayName.."! 🌸"; bubbleGreeting.ZIndex=3
local bubbleMsg=Instance.new("TextLabel",bubbleBody)
bubbleMsg.Size=UDim2.new(1,-20,0,36); bubbleMsg.Position=UDim2.new(0,14,0,38)
bubbleMsg.BackgroundTransparency=1; bubbleMsg.Font=Enum.Font.Gotham; bubbleMsg.TextSize=13
bubbleMsg.TextColor3=Color3.fromRGB(200,180,200); bubbleMsg.TextXAlignment=Enum.TextXAlignment.Left
bubbleMsg.TextYAlignment=Enum.TextYAlignment.Top; bubbleMsg.TextWrapped=true
bubbleMsg.Text="Welcome back to VanillaHub!\nEnjoy your time here ✨"; bubbleMsg.ZIndex=3

-- STATS GRID
local statsContainer = Instance.new("Frame", homePage)
statsContainer.Size=UDim2.new(1,0,0,160); statsContainer.BackgroundTransparency=1
local gridLayout=Instance.new("UIGridLayout",statsContainer)
gridLayout.CellSize=UDim2.new(0,148,0,42); gridLayout.CellPadding=UDim2.new(0,12,0,12)
gridLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center; gridLayout.SortOrder=Enum.SortOrder.LayoutOrder

local function createStatusBox(text, color)
    local box=Instance.new("Frame",statsContainer)
    box.BackgroundColor3=Color3.fromRGB(18,18,24); box.BorderSizePixel=0
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,8)
    local lbl=Instance.new("TextLabel",box)
    lbl.Size=UDim2.new(1,-8,1,-4); lbl.Position=UDim2.new(0,4,0,2)
    lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.Gotham; lbl.TextSize=13
    lbl.TextColor3=color or THEME_TEXT; lbl.Text=text; lbl.TextWrapped=true; lbl.TextXAlignment=Enum.TextXAlignment.Center
    return lbl
end

local pingLabel = createStatusBox("Ping: calculating...")
createStatusBox("Lag detected: No", Color3.fromRGB(100,200,100))
createStatusBox("Account age: "..player.AccountAge.." days")
createStatusBox("Executor: Unknown / Custom")

local rejoinBtn=Instance.new("TextButton",statsContainer)
rejoinBtn.Size=UDim2.new(0,148,0,42); rejoinBtn.BackgroundColor3=Color3.fromRGB(22,22,30); rejoinBtn.BorderSizePixel=0
rejoinBtn.Font=Enum.Font.Gotham; rejoinBtn.TextSize=14; rejoinBtn.TextColor3=THEME_TEXT; rejoinBtn.Text="Rejoin"
Instance.new("UICorner",rejoinBtn).CornerRadius=UDim.new(0,8)
rejoinBtn.MouseEnter:Connect(function() TweenService:Create(rejoinBtn,TweenInfo.new(0.18),{BackgroundColor3=Color3.fromRGB(35,35,48)}):Play() end)
rejoinBtn.MouseLeave:Connect(function() TweenService:Create(rejoinBtn,TweenInfo.new(0.18),{BackgroundColor3=Color3.fromRGB(22,22,30)}):Play() end)
rejoinBtn.MouseButton1Click:Connect(function() pcall(function() TeleportService:Teleport(game.PlaceId,player) end) end)

local pingConn = RunService.Heartbeat:Connect(function()
    local ok, ping = pcall(function() return math.round(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
    pingLabel.Text = ok and ("Ping: "..ping.." ms") or "Ping: N/A"
end)
table.insert(cleanupTasks, function() if pingConn then pingConn:Disconnect(); pingConn=nil end end)

-- ════════════════════════════════════════════════════
-- TELEPORT TAB
-- ════════════════════════════════════════════════════
local teleportPage = pages["TeleportTab"]
local tpHeader=Instance.new("TextLabel",teleportPage)
tpHeader.Size=UDim2.new(1,-12,0,28); tpHeader.BackgroundTransparency=1
tpHeader.Font=Enum.Font.GothamBold; tpHeader.TextSize=14
tpHeader.TextColor3=THEME_TEXT; tpHeader.TextXAlignment=Enum.TextXAlignment.Left
tpHeader.Text="Quick Teleport Locations"

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

for _, loc in ipairs(locations) do
    local btn=Instance.new("TextButton",teleportPage)
    btn.Size=UDim2.new(1,-12,0,36); btn.BackgroundColor3=Color3.fromRGB(18,18,24)
    btn.BorderSizePixel=0; btn.Font=Enum.Font.GothamSemibold; btn.TextSize=13
    btn.TextColor3=THEME_TEXT; btn.Text=loc.name
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)
    btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(36,30,48),TextColor3=Color3.fromRGB(255,255,255)}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(18,18,24),TextColor3=THEME_TEXT}):Play() end)
    btn.MouseButton1Click:Connect(function()
        local char=player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame=CFrame.new(loc.x,loc.y+3,loc.z)
        end
    end)
end

-- ════════════════════════════════════════════════════
-- SHARED UI HELPERS (used by Item & Dupe tabs)
-- ════════════════════════════════════════════════════
local BTN_COLOR = Color3.fromRGB(32, 32, 40)
local BTN_HOVER = Color3.fromRGB(52, 48, 66)
local BTN_ACCENT = Color3.fromRGB(75, 55, 95)

local function makeSectionLabel(parent, text)
    local wrapper2 = Instance.new("Frame", parent)
    wrapper2.Size = UDim2.new(1, -12, 0, 26)
    wrapper2.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", wrapper2)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 10
    lbl.TextColor3 = Color3.fromRGB(130, 110, 155)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    lbl.LayoutOrder = 0
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 6)
    return wrapper2
end

local function makeSep(parent)
    local sep = Instance.new("Frame", parent)
    sep.Size = UDim2.new(1, -12, 0, 1)
    sep.BackgroundColor3 = Color3.fromRGB(32, 24, 42)
    sep.BackgroundTransparency = 0.2
    sep.BorderSizePixel = 0
    return sep
end

local function makeButton(parent, text, color, cb)
    color = color or BTN_COLOR
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -12, 0, 34)
    btn.BackgroundColor3 = color
    btn.Text = text; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = THEME_TEXT; btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {BackgroundColor3 = BTN_HOVER}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {BackgroundColor3 = color}):Play()
    end)
    if cb then btn.MouseButton1Click:Connect(cb) end
    return btn
end

local function makeToggleRow(parent, text, default, cb)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -12, 0, 34)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -56, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = text

    local trackBg = Instance.new("TextButton", frame)
    trackBg.Size = UDim2.new(0, 36, 0, 20); trackBg.Position = UDim2.new(1, -48, 0.5, -10)
    trackBg.BackgroundColor3 = default and Color3.fromRGB(80, 160, 80) or Color3.fromRGB(40, 36, 52)
    trackBg.Text = ""; trackBg.BorderSizePixel = 0
    Instance.new("UICorner", trackBg).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", trackBg)
    knob.Size = UDim2.new(0, 14, 0, 14); knob.Position = UDim2.new(0, default and 18 or 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(240, 240, 255); knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local toggled = default
    if cb then cb(toggled) end

    local function setVal(val)
        toggled = val
        TweenService:Create(trackBg, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            BackgroundColor3 = val and Color3.fromRGB(80,160,80) or Color3.fromRGB(40,36,52)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, val and 18 or 2, 0.5, -7)
        }):Play()
        if cb then cb(val) end
    end

    trackBg.MouseButton1Click:Connect(function() setVal(not toggled) end)
    return frame, setVal, function() return toggled end
end

local function makeSlider(parent, text, minV, maxV, defV, cb)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -12, 0, 54)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 24); frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.7, 0, 0, 22); lbl.Position = UDim2.new(0, 12, 0, 6)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 12
    lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = text

    local valLbl = Instance.new("TextLabel", frame)
    valLbl.Size = UDim2.new(0.3, -12, 0, 22); valLbl.Position = UDim2.new(0.7, 0, 0, 6)
    valLbl.BackgroundTransparency = 1; valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 12
    valLbl.TextColor3 = Color3.fromRGB(180, 160, 200); valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Text = tostring(defV)

    local track = Instance.new("Frame", frame)
    track.Size = UDim2.new(1, -24, 0, 5); track.Position = UDim2.new(0, 12, 0, 36)
    track.BackgroundColor3 = Color3.fromRGB(35, 30, 48); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((defV-minV)/(maxV-minV), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(120, 90, 160); fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0, 14, 0, 14); knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((defV-minV)/(maxV-minV), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(220, 205, 240); knob.Text = ""; knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local ds = false
    local function upd(absX)
        local r = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.round(minV + r * (maxV - minV))
        fill.Size = UDim2.new(r, 0, 1, 0); knob.Position = UDim2.new(r, 0, 0.5, 0); valLbl.Text = tostring(v)
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
    return frame
end

-- ════════════════════════════════════════════════════
-- ITEM TAB  —  Clean rebuild
-- ════════════════════════════════════════════════════
local itemPage = pages["ItemTab"]

-- isnetworkowner helper
local function isnetworkowner(part)
    return part.ReceiveAge == 0
end

-- ── SELECTION ────────────────────────────────────────────────
local function selectPart(part)
    if not part or part:FindFirstChild("Selection") then return end
    local sb = Instance.new("SelectionBox", part)
    sb.Name = "Selection"; sb.Adornee = part
    sb.SurfaceTransparency = 0.5; sb.LineThickness = 0.09
    sb.SurfaceColor3 = Color3.fromRGB(0,0,0); sb.Color3 = Color3.fromRGB(0,172,240)
end
local function deselectPart(part)
    if not part then return end
    local s = part:FindFirstChild("Selection")
    if s then s:Destroy() end
end
local function deselectAll()
    for _, v in pairs(workspace.PlayerModels:GetChildren()) do
        if v:FindFirstChild("Main") and v.Main:FindFirstChild("Selection") then v.Main.Selection:Destroy() end
        if v:FindFirstChild("WoodSection") and v.WoodSection:FindFirstChild("Selection") then v.WoodSection.Selection:Destroy() end
    end
end
table.insert(cleanupTasks, deselectAll)

local function trySelect(target)
    if not target then return end
    local par = target.Parent
    if not par then return end
    if not par:FindFirstChild("Owner") then return end
    if par:FindFirstChild("Main") then
        local p = par.Main
        if target == p or target:IsDescendantOf(p) then
            if p:FindFirstChild("Selection") then deselectPart(p) else selectPart(p) end; return
        end
    end
    if par:FindFirstChild("WoodSection") then
        local p = par.WoodSection
        if target == p or target:IsDescendantOf(p) then
            if p:FindFirstChild("Selection") then deselectPart(p) else selectPart(p) end; return
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

-- ── Selection mode state ────────────────────────────────────
local clickSelectEnabled = false
local lassoEnabled       = false
local groupSelectEnabled = false

-- ── Lasso overlay ────────────────────────────────────────────
local lassoFrame = Instance.new("Frame", gui)
lassoFrame.Name = "VHLassoRect"
lassoFrame.BackgroundColor3 = Color3.fromRGB(60,120,200)
lassoFrame.BackgroundTransparency = 0.82; lassoFrame.BorderSizePixel = 0
lassoFrame.Visible = false; lassoFrame.ZIndex = 20
local lassoStroke = Instance.new("UIStroke", lassoFrame)
lassoStroke.Color = Color3.fromRGB(100,160,255); lassoStroke.Thickness = 1.5; lassoStroke.Transparency = 0

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
    lassoFrame.Visible = true
    lassoFrame.Position = UDim2.new(0, mouse.X, 0, mouse.Y)
    lassoFrame.Size = UDim2.new(0,0,0,0)
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
    lassoFrame.Size = UDim2.new(0,1,0,1); lassoFrame.Visible = false
end)

mouse.Button1Up:Connect(function()
    if lassoEnabled then return end
    if clickSelectEnabled then trySelect(mouse.Target)
    elseif groupSelectEnabled then tryGroupSelect(mouse.Target)
    end
end)

-- ── Destination marker ───────────────────────────────────────
local tpCircle = nil
local tpItemSpeed = 0.3
local isTeleporting = false
local tpStopRequested = false

table.insert(cleanupTasks, function()
    if tpCircle and tpCircle.Parent then tpCircle:Destroy(); tpCircle = nil end
end)

-- ── BUILD ITEM TAB UI ────────────────────────────────────────

-- Section: Selection Mode
makeSectionLabel(itemPage, "Selection Mode")
makeToggleRow(itemPage, "Click Select", false, function(val)
    clickSelectEnabled = val
    if val then lassoEnabled = false; groupSelectEnabled = false end
end)
makeToggleRow(itemPage, "Lasso Tool", false, function(val)
    lassoEnabled = val
    if val then clickSelectEnabled = false; groupSelectEnabled = false end
end)
makeToggleRow(itemPage, "Group Select", false, function(val)
    groupSelectEnabled = val
    if val then clickSelectEnabled = false; lassoEnabled = false end
end)

makeSep(itemPage)

-- Section: Teleport Destination
makeSectionLabel(itemPage, "Teleport Destination")

local tpDestRow = Instance.new("Frame", itemPage)
tpDestRow.Size = UDim2.new(1, -12, 0, 34)
tpDestRow.BackgroundTransparency = 1

local tpSetBtn = Instance.new("TextButton", tpDestRow)
tpSetBtn.Size = UDim2.new(0.5, -5, 1, 0); tpSetBtn.Position = UDim2.new(0,0,0,0)
tpSetBtn.BackgroundColor3 = BTN_COLOR; tpSetBtn.Font = Enum.Font.GothamSemibold
tpSetBtn.TextSize = 12; tpSetBtn.TextColor3 = THEME_TEXT; tpSetBtn.Text = "Set Destination"
tpSetBtn.BorderSizePixel = 0
Instance.new("UICorner", tpSetBtn).CornerRadius = UDim.new(0, 8)

local tpRemoveBtn = Instance.new("TextButton", tpDestRow)
tpRemoveBtn.Size = UDim2.new(0.5, -5, 1, 0); tpRemoveBtn.Position = UDim2.new(0.5, 5, 0, 0)
tpRemoveBtn.BackgroundColor3 = BTN_COLOR; tpRemoveBtn.Font = Enum.Font.GothamSemibold
tpRemoveBtn.TextSize = 12; tpRemoveBtn.TextColor3 = THEME_TEXT; tpRemoveBtn.Text = "Clear Destination"
tpRemoveBtn.BorderSizePixel = 0
Instance.new("UICorner", tpRemoveBtn).CornerRadius = UDim.new(0, 8)

for _, b in {tpSetBtn, tpRemoveBtn} do
    b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = BTN_HOVER}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = BTN_COLOR}):Play() end)
end

tpSetBtn.MouseButton1Click:Connect(function()
    if tpCircle then tpCircle:Destroy() end
    tpCircle = Instance.new("Part")
    tpCircle.Name = "VanillaHubTpCircle"; tpCircle.Shape = Enum.PartType.Ball
    tpCircle.Size = Vector3.new(3,3,3); tpCircle.Material = Enum.Material.SmoothPlastic
    tpCircle.Color = Color3.fromRGB(120,100,160); tpCircle.Anchored = true; tpCircle.CanCollide = false
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        tpCircle.Position = char.HumanoidRootPart.Position
    end
    tpCircle.Parent = workspace
end)

tpRemoveBtn.MouseButton1Click:Connect(function()
    if tpCircle then tpCircle:Destroy(); tpCircle = nil end
end)

makeSep(itemPage)

-- Speed slider
makeSectionLabel(itemPage, "Teleport Speed")
makeSlider(itemPage, "Delay per item (×0.1s)", 1, 20, 3, function(v) tpItemSpeed = v / 10 end)

makeSep(itemPage)

-- Actions
makeSectionLabel(itemPage, "Actions")

-- Main TP button (toggles to Stop)
local tpSelectedBtn = makeButton(itemPage, "Teleport Selected", BTN_ACCENT)

local function doTeleportSelected()
    if not tpCircle then return end
    if isTeleporting then tpStopRequested = true; return end

    isTeleporting = true; tpStopRequested = false
    tpSelectedBtn.Text = "Stop Teleporting"
    TweenService:Create(tpSelectedBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(160,50,50)}):Play()

    local destCF = tpCircle.CFrame
    local OldPos = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.CFrame

    task.spawn(function()
        for _, v in next, workspace.PlayerModels:GetDescendants() do
            if tpStopRequested then break end
            if v.Name == "Selection" then
                local part = v.Parent
                if not (part and part.Parent) then continue end
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CFrame = CFrame.new(part.CFrame.p) * CFrame.new(5,0,0) end
                task.wait(tpItemSpeed)
                if tpStopRequested then break end
                pcall(function()
                    if not part.Parent.PrimaryPart then part.Parent.PrimaryPart = part end
                    local dragger = ReplicatedStorage:FindFirstChild("Interaction")
                        and ReplicatedStorage.Interaction:FindFirstChild("ClientIsDragging")
                    local timeout = 0
                    while not isnetworkowner(part) and timeout < 3 do
                        if dragger then dragger:FireServer(part.Parent) end
                        task.wait(0.05); timeout += 0.05
                    end
                    if dragger then dragger:FireServer(part.Parent) end
                    part:PivotTo(destCF)
                end)
                task.wait(tpItemSpeed)
            end
        end
        if OldPos and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = OldPos
        end
        isTeleporting = false; tpStopRequested = false
        tpSelectedBtn.Text = "Teleport Selected"
        TweenService:Create(tpSelectedBtn, TweenInfo.new(0.2), {BackgroundColor3 = BTN_ACCENT}):Play()
    end)
end

tpSelectedBtn.MouseButton1Click:Connect(doTeleportSelected)

-- Sell selected items
local sellBtn = makeButton(itemPage, "Sell Selected (Dropoff)")
local isSelling = false; local sellStopReq = false
local function doSellSelected()
    if isSelling then sellStopReq = true; return end
    isSelling = true; sellStopReq = false
    sellBtn.Text = "Stop Selling"
    TweenService:Create(sellBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(160,50,50)}):Play()
    local OldPos = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.CFrame
    task.spawn(function()
        for _, v in next, workspace.PlayerModels:GetDescendants() do
            if sellStopReq then break end
            if v.Name == "Selection" then
                local part = v.Parent
                if not (part and part.Parent) then continue end
                local char = player.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CFrame = CFrame.new(part.CFrame.p) * CFrame.new(5,0,0) end
                task.wait(tpItemSpeed)
                if sellStopReq then break end
                pcall(function()
                    if not part.Parent.PrimaryPart then part.Parent.PrimaryPart = part end
                    local dragger = ReplicatedStorage:FindFirstChild("Interaction")
                        and ReplicatedStorage.Interaction:FindFirstChild("ClientIsDragging")
                    local timeout = 0
                    while not isnetworkowner(part) and timeout < 3 do
                        if dragger then dragger:FireServer(part.Parent) end
                        task.wait(0.05); timeout += 0.05
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
        isSelling = false; sellStopReq = false
        sellBtn.Text = "Sell Selected (Dropoff)"
        TweenService:Create(sellBtn, TweenInfo.new(0.2), {BackgroundColor3 = BTN_COLOR}):Play()
    end)
end
sellBtn.MouseButton1Click:Connect(doSellSelected)

makeButton(itemPage, "Deselect All", BTN_COLOR, function() deselectAll() end)

-- ════════════════════════════════════════════════════
-- DUPE TAB  —  Random & Group teleport modes
-- ════════════════════════════════════════════════════
local dupePage = pages["DupeTab"]

local DUPE_NORMAL = 1
local DUPE_RANDOM = 2
local DUPE_GROUP  = 3
local dupeTpMode = DUPE_NORMAL

local dupeRunning = false
local dupeStopReq = false
local dupeTpSpeed = 0.3
local dupeTpCircle = nil

makeSectionLabel(dupePage, "Teleport Mode")

-- Mode selector row (3 buttons acting as radio)
local modeRow = Instance.new("Frame", dupePage)
modeRow.Size = UDim2.new(1, -12, 0, 36)
modeRow.BackgroundTransparency = 1

local modeButtons = {}
local modeNames = {"Normal", "Random", "Group"}
local MODESEL_COLOR = Color3.fromRGB(60, 45, 80)
local MODEIDLE_COLOR = Color3.fromRGB(24, 22, 32)

for i, mname in ipairs(modeNames) do
    local mb = Instance.new("TextButton", modeRow)
    local w = 1/3
    mb.Size = UDim2.new(w, i < 3 and -3 or 0, 1, 0)
    mb.Position = UDim2.new((i-1)*w, i > 1 and 3 or 0, 0, 0)
    mb.BackgroundColor3 = i == 1 and MODESEL_COLOR or MODEIDLE_COLOR
    mb.Font = Enum.Font.GothamSemibold; mb.TextSize = 12
    mb.TextColor3 = i == 1 and THEME_TEXT or Color3.fromRGB(130,120,150)
    mb.Text = mname; mb.BorderSizePixel = 0
    Instance.new("UICorner", mb).CornerRadius = UDim.new(0, 8)
    mb.MouseEnter:Connect(function()
        if dupeTpMode ~= i then TweenService:Create(mb, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(38,34,52)}):Play() end
    end)
    mb.MouseLeave:Connect(function()
        if dupeTpMode ~= i then TweenService:Create(mb, TweenInfo.new(0.15), {BackgroundColor3 = MODEIDLE_COLOR}):Play() end
    end)
    mb.MouseButton1Click:Connect(function()
        dupeTpMode = i
        for j, b in ipairs(modeButtons) do
            TweenService:Create(b, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                BackgroundColor3 = j == i and MODESEL_COLOR or MODEIDLE_COLOR,
                TextColor3 = j == i and THEME_TEXT or Color3.fromRGB(130,120,150)
            }):Play()
        end
    end)
    modeButtons[i] = mb
end

-- Mode description hint
local modeHint = Instance.new("TextLabel", dupePage)
modeHint.Size = UDim2.new(1,-12,0,28); modeHint.BackgroundColor3 = Color3.fromRGB(14,14,20)
modeHint.BorderSizePixel = 0; modeHint.Font = Enum.Font.Gotham; modeHint.TextSize = 11
modeHint.TextColor3 = Color3.fromRGB(110,100,140); modeHint.TextWrapped = true
modeHint.TextXAlignment = Enum.TextXAlignment.Left
modeHint.Text = "  Normal: move selected items  |  Random: one of each type  |  Group: all of one type"
Instance.new("UICorner", modeHint).CornerRadius = UDim.new(0, 6)
Instance.new("UIPadding", modeHint).PaddingLeft = UDim.new(0, 4)

makeSep(dupePage)

-- Destination
makeSectionLabel(dupePage, "Destination")

local dupeDestRow = Instance.new("Frame", dupePage)
dupeDestRow.Size = UDim2.new(1,-12,0,34); dupeDestRow.BackgroundTransparency = 1

local dupeSetBtn = Instance.new("TextButton", dupeDestRow)
dupeSetBtn.Size = UDim2.new(0.5,-5,1,0); dupeSetBtn.BackgroundColor3 = BTN_COLOR
dupeSetBtn.Font = Enum.Font.GothamSemibold; dupeSetBtn.TextSize = 12
dupeSetBtn.TextColor3 = THEME_TEXT; dupeSetBtn.Text = "Set Destination"; dupeSetBtn.BorderSizePixel = 0
Instance.new("UICorner", dupeSetBtn).CornerRadius = UDim.new(0, 8)

local dupeClearBtn = Instance.new("TextButton", dupeDestRow)
dupeClearBtn.Size = UDim2.new(0.5,-5,1,0); dupeClearBtn.Position = UDim2.new(0.5,5,0,0)
dupeClearBtn.BackgroundColor3 = BTN_COLOR; dupeClearBtn.Font = Enum.Font.GothamSemibold
dupeClearBtn.TextSize = 12; dupeClearBtn.TextColor3 = THEME_TEXT; dupeClearBtn.Text = "Clear"; dupeClearBtn.BorderSizePixel = 0
Instance.new("UICorner", dupeClearBtn).CornerRadius = UDim.new(0, 8)

for _, b in {dupeSetBtn, dupeClearBtn} do
    b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = BTN_HOVER}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = BTN_COLOR}):Play() end)
end

dupeSetBtn.MouseButton1Click:Connect(function()
    if dupeTpCircle then dupeTpCircle:Destroy() end
    dupeTpCircle = Instance.new("Part")
    dupeTpCircle.Name = "VanillaHubDupeTpCircle"
    dupeTpCircle.Shape = Enum.PartType.Ball; dupeTpCircle.Size = Vector3.new(3,3,3)
    dupeTpCircle.Material = Enum.Material.SmoothPlastic
    dupeTpCircle.Color = Color3.fromRGB(90,140,100); dupeTpCircle.Anchored = true; dupeTpCircle.CanCollide = false
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        dupeTpCircle.Position = char.HumanoidRootPart.Position
    end
    dupeTpCircle.Parent = workspace
end)
dupeClearBtn.MouseButton1Click:Connect(function()
    if dupeTpCircle then dupeTpCircle:Destroy(); dupeTpCircle = nil end
end)
table.insert(cleanupTasks, function()
    if dupeTpCircle and dupeTpCircle.Parent then dupeTpCircle:Destroy(); dupeTpCircle = nil end
end)

makeSep(dupePage)

-- Group name filter (used in Group mode)
local groupFilterRow = Instance.new("Frame", dupePage)
groupFilterRow.Size = UDim2.new(1,-12,0,34); groupFilterRow.BackgroundColor3 = Color3.fromRGB(18,18,24)
groupFilterRow.BorderSizePixel = 0
Instance.new("UICorner", groupFilterRow).CornerRadius = UDim.new(0, 8)

local gfLabel = Instance.new("TextLabel", groupFilterRow)
gfLabel.Size = UDim2.new(0.42,0,1,0); gfLabel.Position = UDim2.new(0,12,0,0)
gfLabel.BackgroundTransparency = 1; gfLabel.Font = Enum.Font.GothamSemibold; gfLabel.TextSize = 12
gfLabel.TextColor3 = THEME_TEXT; gfLabel.TextXAlignment = Enum.TextXAlignment.Left; gfLabel.Text = "Group Name Filter"

local gfInput = Instance.new("TextBox", groupFilterRow)
gfInput.Size = UDim2.new(0.55,-8,0,24); gfInput.Position = UDim2.new(0.45,0,0.5,-12)
gfInput.BackgroundColor3 = Color3.fromRGB(26,24,36); gfInput.BorderSizePixel = 0
gfInput.Font = Enum.Font.Gotham; gfInput.TextSize = 12; gfInput.TextColor3 = THEME_TEXT
gfInput.PlaceholderText = "e.g. WoodLog"; gfInput.PlaceholderColor3 = Color3.fromRGB(80,70,100)
gfInput.Text = ""; gfInput.ClearTextOnFocus = false
Instance.new("UICorner", gfInput).CornerRadius = UDim.new(0, 6)
Instance.new("UIPadding", gfInput).PaddingLeft = UDim.new(0, 8)

makeSep(dupePage)

-- Speed
makeSectionLabel(dupePage, "Speed")
makeSlider(dupePage, "Delay per item (×0.1s)", 1, 20, 3, function(v) dupeTpSpeed = v / 10 end)

makeSep(dupePage)

-- Actions
makeSectionLabel(dupePage, "Actions")

local dupeGoBtn = makeButton(dupePage, "Start Teleport", BTN_ACCENT)

local function getDupeItems()
    local items = {}
    -- Collect all valid items (have Owner, have Main or WoodSection)
    for _, v in pairs(workspace.PlayerModels:GetChildren()) do
        if v:FindFirstChild("Owner") then
            local part = v:FindFirstChild("Main") or v:FindFirstChild("WoodSection")
            if part then
                local iv = v:FindFirstChild("ItemName")
                local name = iv and iv.Value or v.Name
                table.insert(items, {part = part, name = name, model = v})
            end
        end
    end
    return items
end

local function runDupeTeleport()
    if not dupeTpCircle then return end
    if dupeRunning then dupeStopReq = true; return end

    dupeRunning = true; dupeStopReq = false
    dupeGoBtn.Text = "Stop Teleporting"
    TweenService:Create(dupeGoBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(160,50,50)}):Play()

    local destCF = dupeTpCircle.CFrame
    local OldPos = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.CFrame

    task.spawn(function()
        local allItems = getDupeItems()
        local toProcess = {}

        if dupeTpMode == DUPE_NORMAL then
            -- All selected items
            for _, v in next, workspace.PlayerModels:GetDescendants() do
                if v.Name == "Selection" and v.Parent and v.Parent.Parent then
                    table.insert(toProcess, v.Parent)
                end
            end

        elseif dupeTpMode == DUPE_RANDOM then
            -- One item per unique name (never repeat same category)
            local seen = {}
            -- Shuffle allItems for randomness
            for i = #allItems, 2, -1 do
                local j = math.random(1, i)
                allItems[i], allItems[j] = allItems[j], allItems[i]
            end
            for _, item in ipairs(allItems) do
                if not seen[item.name] then
                    seen[item.name] = true
                    table.insert(toProcess, item.part)
                end
            end

        elseif dupeTpMode == DUPE_GROUP then
            -- All items matching the group filter name
            local filter = gfInput.Text:lower():gsub("^%s+",""):gsub("%s+$","")
            for _, item in ipairs(allItems) do
                local n = item.name:lower()
                if filter == "" or n:find(filter, 1, true) then
                    table.insert(toProcess, item.part)
                end
            end
        end

        for _, part in ipairs(toProcess) do
            if dupeStopReq then break end
            if not (part and part.Parent) then continue end
            local char = player.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = CFrame.new(part.CFrame.p) * CFrame.new(5,0,0) end
            task.wait(dupeTpSpeed)
            if dupeStopReq then break end
            pcall(function()
                if not part.Parent.PrimaryPart then part.Parent.PrimaryPart = part end
                local dragger = ReplicatedStorage:FindFirstChild("Interaction")
                    and ReplicatedStorage.Interaction:FindFirstChild("ClientIsDragging")
                local timeout = 0
                while not isnetworkowner(part) and timeout < 3 do
                    if dragger then dragger:FireServer(part.Parent) end
                    task.wait(0.05); timeout += 0.05
                end
                if dragger then dragger:FireServer(part.Parent) end
                part:PivotTo(destCF)
            end)
            task.wait(dupeTpSpeed)
        end

        if OldPos and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = OldPos
        end
        dupeRunning = false; dupeStopReq = false
        dupeGoBtn.Text = "Start Teleport"
        TweenService:Create(dupeGoBtn, TweenInfo.new(0.2), {BackgroundColor3 = BTN_ACCENT}):Play()
    end)
end

dupeGoBtn.MouseButton1Click:Connect(runDupeTeleport)

-- ════════════════════════════════════════════════════
-- PLAYER TAB
-- ════════════════════════════════════════════════════
local playerPage = pages["PlayerTab"]

local savedWalkSpeed = 16
local savedJumpPower  = 50

local statsConn2 = RunService.Heartbeat:Connect(function()
    local char = player.Character; if not char then return end
    local hum = char:FindFirstChild("Humanoid"); if not hum then return end
    if hum.WalkSpeed ~= savedWalkSpeed then hum.WalkSpeed = savedWalkSpeed end
    if hum.JumpPower  ~= savedJumpPower  then hum.JumpPower  = savedJumpPower  end
end)
table.insert(cleanupTasks, function()
    if statsConn2 then statsConn2:Disconnect(); statsConn2 = nil end
    local char = player.Character
    if char then local hum = char:FindFirstChild("Humanoid"); if hum then hum.WalkSpeed=16; hum.JumpPower=50 end end
end)

local function createPSection(text)
    local lbl = Instance.new("TextLabel", playerPage)
    lbl.Size=UDim2.new(1,-12,0,22); lbl.BackgroundTransparency=1
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=11
    lbl.TextColor3=Color3.fromRGB(120,100,145); lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Text=string.upper(text)
    Instance.new("UIPadding",lbl).PaddingLeft=UDim.new(0,6)
end
local function createPSep()
    local s=Instance.new("Frame",playerPage)
    s.Size=UDim2.new(1,-12,0,1); s.BackgroundColor3=Color3.fromRGB(32,24,42); s.BorderSizePixel=0
end

local function createPSlider(labelText, minVal, maxVal, defaultVal, onChanged)
    local frame=Instance.new("Frame",playerPage)
    frame.Size=UDim2.new(1,-12,0,54); frame.BackgroundColor3=Color3.fromRGB(18,18,24)
    frame.BorderSizePixel=0; Instance.new("UICorner",frame).CornerRadius=UDim.new(0,8)
    local topRow=Instance.new("Frame",frame)
    topRow.Size=UDim2.new(1,-16,0,22); topRow.Position=UDim2.new(0,8,0,6); topRow.BackgroundTransparency=1
    local lbl=Instance.new("TextLabel",topRow)
    lbl.Size=UDim2.new(0.7,0,1,0); lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=12
    lbl.TextColor3=THEME_TEXT; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=labelText
    local valLbl=Instance.new("TextLabel",topRow)
    valLbl.Size=UDim2.new(0.3,0,1,0); valLbl.Position=UDim2.new(0.7,0,0,0); valLbl.BackgroundTransparency=1
    valLbl.Font=Enum.Font.GothamBold; valLbl.TextSize=12; valLbl.TextColor3=Color3.fromRGB(180,160,200)
    valLbl.TextXAlignment=Enum.TextXAlignment.Right; valLbl.Text=tostring(defaultVal)
    local track=Instance.new("Frame",frame)
    track.Size=UDim2.new(1,-16,0,5); track.Position=UDim2.new(0,8,0,37)
    track.BackgroundColor3=Color3.fromRGB(35,30,48); track.BorderSizePixel=0
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new((defaultVal-minVal)/(maxVal-minVal),0,1,0)
    fill.BackgroundColor3=Color3.fromRGB(120,90,160); fill.BorderSizePixel=0
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("TextButton",track)
    knob.Size=UDim2.new(0,14,0,14); knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new((defaultVal-minVal)/(maxVal-minVal),0,0.5,0)
    knob.BackgroundColor3=Color3.fromRGB(220,205,240); knob.Text=""; knob.BorderSizePixel=0
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
    frame.Size=UDim2.new(1,-12,0,34); frame.BackgroundColor3=Color3.fromRGB(18,18,24)
    frame.BorderSizePixel=0; Instance.new("UICorner",frame).CornerRadius=UDim.new(0,8)
    local lbl=Instance.new("TextLabel",frame)
    lbl.Size=UDim2.new(1,-56,1,0); lbl.Position=UDim2.new(0,12,0,0); lbl.BackgroundTransparency=1
    lbl.Text=text; lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=13
    lbl.TextColor3=THEME_TEXT; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local tb=Instance.new("TextButton",frame)
    tb.Size=UDim2.new(0,36,0,20); tb.Position=UDim2.new(1,-48,0.5,-10)
    tb.BackgroundColor3=defaultState and Color3.fromRGB(80,160,80) or Color3.fromRGB(40,36,52)
    tb.Text=""; tb.BorderSizePixel=0; Instance.new("UICorner",tb).CornerRadius=UDim.new(1,0)
    local circle=Instance.new("Frame",tb)
    circle.Size=UDim2.new(0,14,0,14); circle.Position=UDim2.new(0,defaultState and 18 or 2,0.5,-7)
    circle.BackgroundColor3=Color3.fromRGB(240,240,255); circle.BorderSizePixel=0
    Instance.new("UICorner",circle).CornerRadius=UDim.new(1,0)
    local toggled=defaultState
    if callback then callback(toggled) end
    local function setToggled(val)
        toggled=val
        TweenService:Create(tb,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=val and Color3.fromRGB(80,160,80) or Color3.fromRGB(40,36,52)}):Play()
        TweenService:Create(circle,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{Position=UDim2.new(0,val and 18 or 2,0.5,-7)}):Play()
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

createPSlider("Jumpower", 50, 300, 50, function(val)
    savedJumpPower=val
    local char=player.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.JumpPower=val end
end)

-- Fly speed
local flySpeed = 100
createPSlider("Fly Speed", 100, 500, 100, function(val) flySpeed=val end)

-- Fly key bind row
local flyKeyFrame=Instance.new("Frame",playerPage)
flyKeyFrame.Size=UDim2.new(1,-12,0,34); flyKeyFrame.BackgroundColor3=Color3.fromRGB(18,18,24)
flyKeyFrame.BorderSizePixel=0; Instance.new("UICorner",flyKeyFrame).CornerRadius=UDim.new(0,8)
local flyKeyLabel=Instance.new("TextLabel",flyKeyFrame)
flyKeyLabel.Size=UDim2.new(0.6,0,1,0); flyKeyLabel.Position=UDim2.new(0,12,0,0)
flyKeyLabel.BackgroundTransparency=1; flyKeyLabel.Font=Enum.Font.GothamSemibold; flyKeyLabel.TextSize=13
flyKeyLabel.TextColor3=THEME_TEXT; flyKeyLabel.TextXAlignment=Enum.TextXAlignment.Left; flyKeyLabel.Text="Fly Key"
local currentFlyKey = Enum.KeyCode.Q
local flyKeyBtn=Instance.new("TextButton",flyKeyFrame)
flyKeyBtn.Size=UDim2.new(0,58,0,22); flyKeyBtn.Position=UDim2.new(1,-66,0.5,-11)
flyKeyBtn.BackgroundColor3=BTN_COLOR; flyKeyBtn.Font=Enum.Font.GothamSemibold
flyKeyBtn.TextSize=12; flyKeyBtn.TextColor3=THEME_TEXT; flyKeyBtn.Text="Q"
flyKeyBtn.BorderSizePixel=0; Instance.new("UICorner",flyKeyBtn).CornerRadius=UDim.new(0,6)
flyKeyBtn.MouseEnter:Connect(function() TweenService:Create(flyKeyBtn,TweenInfo.new(0.15),{BackgroundColor3=BTN_HOVER}):Play() end)
flyKeyBtn.MouseLeave:Connect(function() TweenService:Create(flyKeyBtn,TweenInfo.new(0.15),{BackgroundColor3=BTN_COLOR}):Play() end)

-- Fly enabled toggle (enabled by default)
local flyFeatureEnabled = true
local flyToggleFrame, flyToggleSet
flyToggleFrame, flyToggleSet = createPToggle("Fly Enabled", true, function(val)
    flyFeatureEnabled = val
    if not val then
        -- Force fly off when toggle disabled
        if _G.VH and _G.VH.isFlyEnabled then
            if type(_G.VH.stopFly) == "function" then _G.VH.stopFly() end
        end
    end
end)

-- Fly hint
local flyHint=Instance.new("TextLabel",playerPage)
flyHint.Size=UDim2.new(1,-12,0,22); flyHint.BackgroundColor3=Color3.fromRGB(14,14,20)
flyHint.BorderSizePixel=0; flyHint.Font=Enum.Font.Gotham; flyHint.TextSize=11
flyHint.TextColor3=Color3.fromRGB(90,85,115); flyHint.TextWrapped=true
flyHint.TextXAlignment=Enum.TextXAlignment.Left
flyHint.Text="  Toggle fly with your Fly Key (Q). Requires Fly Enabled ON."
Instance.new("UICorner",flyHint).CornerRadius=UDim.new(0,6)

local isFlyEnabled = false
local flyBV, flyBG, flyConn

local function stopFly()
    isFlyEnabled=false
    if _G.VH then _G.VH.isFlyEnabled=false end
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    if flyBV and flyBV.Parent then flyBV:Destroy(); flyBV=nil end
    if flyBG and flyBG.Parent then flyBG:Destroy(); flyBG=nil end
    local char=player.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.PlatformStand=false end
end

local function startFly()
    stopFly(); isFlyEnabled=true
    if _G.VH then _G.VH.isFlyEnabled=true end
    local char=player.Character
    if not char then isFlyEnabled=false; return end
    local root=char:FindFirstChild("HumanoidRootPart"); local hum=char:FindFirstChild("Humanoid")
    if not root or not hum then isFlyEnabled=false; return end
    hum.PlatformStand=true
    flyBV=Instance.new("BodyVelocity",root)
    flyBV.MaxForce=Vector3.new(1e5,1e5,1e5); flyBV.Velocity=Vector3.zero
    flyBG=Instance.new("BodyGyro",root)
    flyBG.MaxTorque=Vector3.new(1e5,1e5,1e5); flyBG.P=1e4; flyBG.D=100
    flyConn=RunService.Heartbeat:Connect(function()
        if not (flyBV and flyBV.Parent and flyBG and flyBG.Parent) then return end
        local ch=player.Character; local h=ch and ch:FindFirstChild("Humanoid"); local r=ch and ch:FindFirstChild("HumanoidRootPart")
        if not (h and r) then return end
        local cf=workspace.CurrentCamera.CFrame
        local dir=Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir=dir+cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir=dir-cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir=dir-cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir=dir+cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir=dir+Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir=dir-Vector3.new(0,1,0) end
        h.PlatformStand=true
        flyBV.MaxForce=Vector3.new(1e5,1e5,1e5)
        flyBV.Velocity=dir.Magnitude>0 and dir.Unit*flySpeed or Vector3.zero
        flyBG.CFrame=cf
    end)
end

table.insert(cleanupTasks, stopFly)

-- Fly key rebind handler
flyKeyBtn.MouseButton1Click:Connect(function()
    if _G.VH and _G.VH.waitingForFlyKey then return end
    if _G.VH then _G.VH.waitingForFlyKey=true end
    flyKeyBtn.Text="..."; flyKeyBtn.BackgroundColor3=Color3.fromRGB(50,90,55)
end)

-- Fly key input handler (global)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    -- Rebind
    if _G.VH and _G.VH.waitingForFlyKey then
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            currentFlyKey = input.KeyCode
            if _G.VH then _G.VH.currentFlyKey = currentFlyKey; _G.VH.waitingForFlyKey = false end
            flyKeyBtn.Text = input.KeyCode.Name:sub(1,4)
            TweenService:Create(flyKeyBtn, TweenInfo.new(0.2), {BackgroundColor3 = BTN_COLOR}):Play()
        end
        return
    end
    -- Fly toggle — only when flyFeatureEnabled is true
    if input.KeyCode == currentFlyKey and flyFeatureEnabled then
        if isFlyEnabled then stopFly() else startFly() end
    end
end)

createPSep()
createPSection("Character")

local noclipEnabled=false; local noclipConn
createPToggle("Noclip", false, function(val)
    noclipEnabled=val
    if val then
        noclipConn=RunService.Stepped:Connect(function()
            if not noclipEnabled then return end
            local char=player.Character; if not char then return end
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
        local char=player.Character
        if char then for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end end
    end
end)
table.insert(cleanupTasks, function()
    noclipEnabled=false
    if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
end)

local infJumpEnabled=false; local infJumpConn
createPToggle("InfJump", false, function(val)
    infJumpEnabled=val
    if val then
        infJumpConn=UserInputService.JumpRequest:Connect(function()
            if not infJumpEnabled then return end
            local char=player.Character
            if char and char:FindFirstChild("Humanoid") then char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    else
        if infJumpConn then infJumpConn:Disconnect(); infJumpConn=nil end
    end
end)
table.insert(cleanupTasks, function()
    infJumpEnabled=false
    if infJumpConn then infJumpConn:Disconnect(); infJumpConn=nil end
end)

-- ════════════════════════════════════════════════════
-- SHARED GLOBALS
-- ════════════════════════════════════════════════════
_G.VH = {
    TweenService=TweenService, Players=Players, UserInputService=UserInputService,
    RunService=RunService, TeleportService=TeleportService, Stats=Stats,
    player=player, cleanupTasks=cleanupTasks, pages=pages, tabs=tabs,
    BTN_COLOR=BTN_COLOR, BTN_HOVER=BTN_HOVER, THEME_TEXT=THEME_TEXT,
    switchTab=switchTab, toggleGUI=toggleGUI, stopFly=stopFly, startFly=startFly,
    butter={ running=false, thread=nil },
    flyToggleEnabled=true,
    isFlyEnabled=false,
    currentFlyKey=currentFlyKey,
    waitingForFlyKey=false,
    flyKeyBtn=flyKeyBtn,
    currentToggleKey=currentToggleKey,
    waitingForKeyGUI=false,
    keybindButtonGUI=nil,
}

_G.VanillaHubCleanup = onExit

print("[VanillaHub] Vanilla2 loaded — cleaned up & improved")
