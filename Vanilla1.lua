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
local Camera            = workspace.CurrentCamera

local THEME_TEXT = Color3.fromRGB(230, 206, 226)
local BTN_COLOR  = Color3.fromRGB(38, 38, 50)
local BTN_HOVER  = Color3.fromRGB(58, 58, 75)
local CARD_BG    = Color3.fromRGB(20, 20, 27)

-- ════════════════════════════════════════════════════
-- CLEANUP REGISTRY
-- ════════════════════════════════════════════════════
local cleanupTasks = {}

local function onExit()
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

-- Wrapper holds position and size; never hidden so ALT toggle has no leftover background
local wrapper = Instance.new("Frame", gui)
wrapper.Size = UDim2.new(0, 520, 0, 340)
wrapper.Position = UDim2.new(0.5, -260, 0.5, -170)
wrapper.BackgroundTransparency = 1
wrapper.BorderSizePixel = 0
wrapper.ClipsDescendants = false

-- Main is the visible container that animates in/out
local main = Instance.new("Frame", wrapper)
main.Size = UDim2.new(0, 0, 0, 0)
main.Position = UDim2.new(0, 0, 0, 0)
main.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
main.BackgroundTransparency = 1
main.BorderSizePixel = 0
main.ClipsDescendants = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

TweenService:Create(main, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 0
}):Play()

-- TOP BAR
local topBar = Instance.new("Frame", main)
topBar.Size = UDim2.new(1, 0, 0, 38)
topBar.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
topBar.BorderSizePixel = 0; topBar.ZIndex = 4

local hubIcon = Instance.new("ImageLabel", topBar)
hubIcon.Size = UDim2.new(0, 24, 0, 24); hubIcon.Position = UDim2.new(0, 9, 0.5, -12)
hubIcon.BackgroundTransparency = 1; hubIcon.ScaleType = Enum.ScaleType.Fit; hubIcon.ZIndex = 6
hubIcon.Image = "rbxassetid://97128823316544"
Instance.new("UICorner", hubIcon).CornerRadius = UDim.new(0, 5)

local titleLbl = Instance.new("TextLabel", topBar)
titleLbl.Size = UDim2.new(1, -90, 1, 0); titleLbl.Position = UDim2.new(0, 40, 0, 0)
titleLbl.BackgroundTransparency = 1; titleLbl.Text = "VanillaHub"
titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 16
titleLbl.TextColor3 = THEME_TEXT; titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.ZIndex = 5

local topLine = Instance.new("Frame", main)
topLine.Size = UDim2.new(1, 0, 0, 1); topLine.Position = UDim2.new(0, 0, 0, 38)
topLine.BackgroundColor3 = Color3.fromRGB(32, 30, 42); topLine.BorderSizePixel = 0; topLine.ZIndex = 4

local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, 28, 0, 28); closeBtn.Position = UDim2.new(1, -36, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(155, 40, 40); closeBtn.Text = "x"
closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 15
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255); closeBtn.BorderSizePixel = 0; closeBtn.ZIndex = 5
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 7)
closeBtn.MouseEnter:Connect(function() TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(200,55,55)}):Play() end)
closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(155,40,40)}):Play() end)

local function showConfirmClose()
    if main:FindFirstChild("ConfirmOverlay") then return end
    local overlay = Instance.new("Frame", main)
    overlay.Name = "ConfirmOverlay"; overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0); overlay.BackgroundTransparency = 0.45; overlay.ZIndex = 9
    local dialog = Instance.new("Frame", main)
    dialog.Name = "ConfirmDialog"; dialog.Size = UDim2.new(0, 330, 0, 160)
    dialog.Position = UDim2.new(0.5, -165, 0.5, -80)
    dialog.BackgroundColor3 = Color3.fromRGB(18, 18, 24); dialog.BorderSizePixel = 0; dialog.ZIndex = 10
    Instance.new("UICorner", dialog).CornerRadius = UDim.new(0, 12)
    local dStroke = Instance.new("UIStroke", dialog)
    dStroke.Color = Color3.fromRGB(55, 50, 75); dStroke.Thickness = 1; dStroke.Transparency = 0.5
    local dtitle = Instance.new("TextLabel", dialog)
    dtitle.Size = UDim2.new(1, 0, 0, 36); dtitle.BackgroundTransparency = 1
    dtitle.Font = Enum.Font.GothamBold; dtitle.TextSize = 16
    dtitle.TextColor3 = THEME_TEXT; dtitle.Text = "Close VanillaHub?"; dtitle.ZIndex = 11
    local dmsg = Instance.new("TextLabel", dialog)
    dmsg.Size = UDim2.new(1, -28, 0, 44); dmsg.Position = UDim2.new(0, 14, 0, 38)
    dmsg.BackgroundTransparency = 1; dmsg.Font = Enum.Font.Gotham; dmsg.TextSize = 13
    dmsg.TextColor3 = Color3.fromRGB(150, 140, 165)
    dmsg.Text = "You will need to re-execute the script to use VanillaHub again."
    dmsg.TextWrapped = true; dmsg.TextYAlignment = Enum.TextYAlignment.Top; dmsg.ZIndex = 11
    local cancelBtn2 = Instance.new("TextButton", dialog)
    cancelBtn2.Size = UDim2.new(0, 136, 0, 36); cancelBtn2.Position = UDim2.new(0.5, -144, 1, -50)
    cancelBtn2.BackgroundColor3 = BTN_COLOR; cancelBtn2.Text = "Cancel"
    cancelBtn2.Font = Enum.Font.GothamSemibold; cancelBtn2.TextSize = 13
    cancelBtn2.TextColor3 = THEME_TEXT; cancelBtn2.ZIndex = 11; cancelBtn2.BorderSizePixel = 0
    Instance.new("UICorner", cancelBtn2).CornerRadius = UDim.new(0, 8)
    local confirmBtn2 = Instance.new("TextButton", dialog)
    confirmBtn2.Size = UDim2.new(0, 136, 0, 36); confirmBtn2.Position = UDim2.new(0.5, 8, 1, -50)
    confirmBtn2.BackgroundColor3 = Color3.fromRGB(155, 40, 40); confirmBtn2.Text = "Exit"
    confirmBtn2.Font = Enum.Font.GothamSemibold; confirmBtn2.TextSize = 13
    confirmBtn2.TextColor3 = Color3.fromRGB(255, 255, 255); confirmBtn2.ZIndex = 11; confirmBtn2.BorderSizePixel = 0
    Instance.new("UICorner", confirmBtn2).CornerRadius = UDim.new(0, 8)
    for _, b in {cancelBtn2, confirmBtn2} do
        b.MouseEnter:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.15), {
                BackgroundColor3 = (b == confirmBtn2) and Color3.fromRGB(195,55,55) or BTN_HOVER
            }):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.15), {
                BackgroundColor3 = (b == confirmBtn2) and Color3.fromRGB(155,40,40) or BTN_COLOR
            }):Play()
        end)
    end
    cancelBtn2.MouseButton1Click:Connect(function() overlay:Destroy(); dialog:Destroy() end)
    confirmBtn2.MouseButton1Click:Connect(function()
        overlay:Destroy(); dialog:Destroy()
        onExit()
        local t = TweenService:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
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

-- SIDE PANEL
local sideLine = Instance.new("Frame", main)
sideLine.Size = UDim2.new(0, 1, 1, -39); sideLine.Position = UDim2.new(0, 154, 0, 39)
sideLine.BackgroundColor3 = Color3.fromRGB(28, 26, 38); sideLine.BorderSizePixel = 0; sideLine.ZIndex = 3

local side = Instance.new("ScrollingFrame", main)
side.Size = UDim2.new(0, 154, 1, -39); side.Position = UDim2.new(0, 0, 0, 39)
side.BackgroundColor3 = Color3.fromRGB(11, 11, 15); side.BorderSizePixel = 0
side.ScrollBarThickness = 3; side.ScrollBarImageColor3 = Color3.fromRGB(45, 45, 60)
side.CanvasSize = UDim2.new(0, 0, 0, 0)
local sideLayout = Instance.new("UIListLayout", side)
sideLayout.Padding = UDim.new(0, 3); sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
local sidePad = Instance.new("UIPadding", side)
sidePad.PaddingTop = UDim.new(0, 8)
sideLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    side.CanvasSize = UDim2.new(0, 0, 0, sideLayout.AbsoluteContentSize.Y + 20)
end)

-- CONTENT AREA
local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, -155, 1, -39); content.Position = UDim2.new(0, 155, 0, 39)
content.BackgroundColor3 = Color3.fromRGB(14, 14, 18); content.BorderSizePixel = 0

-- WELCOME POPUP
task.spawn(function()
    task.wait(0.8)
    if not (gui and gui.Parent) then return end
    local wf = Instance.new("Frame", gui)
    wf.Size = UDim2.new(0, 340, 0, 72); wf.Position = UDim2.new(0.5, -170, 1, -90)
    wf.BackgroundColor3 = Color3.fromRGB(14, 14, 18); wf.BackgroundTransparency = 1; wf.BorderSizePixel = 0
    Instance.new("UICorner", wf).CornerRadius = UDim.new(0, 10)
    local ws = Instance.new("UIStroke", wf)
    ws.Color = Color3.fromRGB(45, 42, 60); ws.Thickness = 1; ws.Transparency = 0.4
    local pfp = Instance.new("ImageLabel", wf)
    pfp.Size = UDim2.new(0, 46, 0, 46); pfp.Position = UDim2.new(0, 14, 0.5, -23)
    pfp.BackgroundTransparency = 1; pfp.ImageTransparency = 1
    pfp.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    Instance.new("UICorner", pfp).CornerRadius = UDim.new(1, 0)
    local wt = Instance.new("TextLabel", wf)
    wt.Size = UDim2.new(1, -80, 1, -12); wt.Position = UDim2.new(0, 72, 0, 6)
    wt.BackgroundTransparency = 1; wt.Font = Enum.Font.GothamSemibold; wt.TextSize = 14
    wt.TextColor3 = THEME_TEXT; wt.TextXAlignment = Enum.TextXAlignment.Left
    wt.TextYAlignment = Enum.TextYAlignment.Center; wt.TextWrapped = true; wt.TextTransparency = 1
    wt.Text = "Welcome back, " .. player.DisplayName
    TweenService:Create(wf, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.25}):Play()
    TweenService:Create(wt, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
    TweenService:Create(pfp, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {ImageTransparency = 0}):Play()
    task.delay(6, function()
        if not (wf and wf.Parent) then return end
        local ot = TweenService:Create(wf, TweenInfo.new(1, Enum.EasingStyle.Quint), {BackgroundTransparency = 1})
        ot:Play()
        TweenService:Create(wt, TweenInfo.new(1), {TextTransparency = 1}):Play()
        TweenService:Create(pfp, TweenInfo.new(1), {ImageTransparency = 1}):Play()
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
    page.ScrollBarThickness = 4; page.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 65)
    page.Visible = false; page.CanvasSize = UDim2.new(0, 0, 0, 0)
    local list = Instance.new("UIListLayout", page)
    list.Padding = UDim.new(0, 8); list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.SortOrder = Enum.SortOrder.LayoutOrder
    local pad = Instance.new("UIPadding", page)
    pad.PaddingTop = UDim.new(0, 14); pad.PaddingBottom = UDim.new(0, 16)
    pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12)
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 36)
    end)
    pages[name .. "Tab"] = page
end

-- TAB SWITCHING
local activeTabButton = nil
local function switchTab(targetName)
    for _, page in pairs(pages) do page.Visible = (page.Name == targetName) end
    if activeTabButton then
        TweenService:Create(activeTabButton, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(15, 15, 19), TextColor3 = Color3.fromRGB(105, 100, 125)
        }):Play()
        local ai = activeTabButton:FindFirstChild("AI")
        if ai then TweenService:Create(ai, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play() end
    end
    local btn = side:FindFirstChild(targetName:gsub("Tab",""))
    if btn then
        activeTabButton = btn
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(28, 27, 36), TextColor3 = THEME_TEXT
        }):Play()
        local ai = btn:FindFirstChild("AI")
        if ai then TweenService:Create(ai, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play() end
    end
end

for _, name in ipairs(tabs) do
    local btn = Instance.new("TextButton", side)
    btn.Name = name; btn.Size = UDim2.new(1, -12, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(15, 15, 19); btn.BorderSizePixel = 0
    btn.Text = name; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(105, 100, 125)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    Instance.new("UIPadding", btn).PaddingLeft = UDim.new(0, 14)
    local ai = Instance.new("Frame", btn)
    ai.Name = "AI"; ai.Size = UDim2.new(0, 3, 0.55, 0)
    ai.Position = UDim2.new(0, 0, 0.225, 0)
    ai.BackgroundColor3 = THEME_TEXT; ai.BorderSizePixel = 0; ai.BackgroundTransparency = 1
    Instance.new("UICorner", ai).CornerRadius = UDim.new(1, 0)
    btn.MouseEnter:Connect(function()
        if activeTabButton ~= btn then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(22, 21, 28), TextColor3 = Color3.fromRGB(155, 148, 175)}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeTabButton ~= btn then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(15, 15, 19), TextColor3 = Color3.fromRGB(105, 100, 125)}):Play()
        end
    end)
    btn.MouseButton1Click:Connect(function() switchTab(name.."Tab") end)
end

switchTab("HomeTab")

-- ════════════════════════════════════════════════════
-- GUI TOGGLE — only animates main, wrapper is invisible and stays
-- ════════════════════════════════════════════════════
local currentToggleKey = Enum.KeyCode.LeftAlt
local guiOpen = true
local isAnimatingGUI = false

local function toggleGUI()
    if isAnimatingGUI then return end
    guiOpen = not guiOpen; isAnimatingGUI = true
    if guiOpen then
        main.Visible = true
        main.Size = UDim2.new(0, 0, 0, 0)
        main.BackgroundTransparency = 1
        local t = TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 0
        })
        t:Play(); t.Completed:Connect(function() isAnimatingGUI = false end)
    else
        local t = TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1
        })
        t:Play(); t.Completed:Connect(function() main.Visible = false; isAnimatingGUI = false end)
    end
end

-- ════════════════════════════════════════════════════
-- HOME TAB
-- ════════════════════════════════════════════════════
local homePage = pages["HomeTab"]

local bubbleRow = Instance.new("Frame", homePage)
bubbleRow.Size = UDim2.new(1, 0, 0, 86); bubbleRow.BackgroundTransparency = 1

local bubbleIcon = Instance.new("ImageLabel", bubbleRow)
bubbleIcon.Size = UDim2.new(0, 46, 0, 46); bubbleIcon.Position = UDim2.new(0, 4, 0.5, -23)
bubbleIcon.BackgroundColor3 = Color3.fromRGB(20, 14, 22); bubbleIcon.BorderSizePixel = 0
bubbleIcon.ScaleType = Enum.ScaleType.Fit; bubbleIcon.Image = "rbxassetid://97128823316544"
Instance.new("UICorner", bubbleIcon).CornerRadius = UDim.new(1, 0)
local iconStroke = Instance.new("UIStroke", bubbleIcon)
iconStroke.Color = Color3.fromRGB(230, 206, 226); iconStroke.Thickness = 1.4; iconStroke.Transparency = 0.5

local iconName = Instance.new("TextLabel", bubbleRow)
iconName.Size = UDim2.new(0, 54, 0, 13); iconName.Position = UDim2.new(0, 0, 0.5, 24)
iconName.BackgroundTransparency = 1; iconName.Font = Enum.Font.GothamBold; iconName.TextSize = 9
iconName.TextColor3 = THEME_TEXT; iconName.TextXAlignment = Enum.TextXAlignment.Center; iconName.Text = "Vanilla"

local tailShape = Instance.new("Frame", bubbleRow)
tailShape.Size = UDim2.new(0, 11, 0, 11); tailShape.Position = UDim2.new(0, 56, 0.5, -5)
tailShape.Rotation = 45; tailShape.BackgroundColor3 = Color3.fromRGB(28, 16, 30)
tailShape.BorderSizePixel = 0; tailShape.ZIndex = 1

local bubbleBody = Instance.new("Frame", bubbleRow)
bubbleBody.Size = UDim2.new(1, -68, 0, 72); bubbleBody.Position = UDim2.new(0, 63, 0.5, -36)
bubbleBody.BackgroundColor3 = Color3.fromRGB(28, 16, 30); bubbleBody.BorderSizePixel = 0; bubbleBody.ZIndex = 2
Instance.new("UICorner", bubbleBody).CornerRadius = UDim.new(0, 11)
local bubbleStroke = Instance.new("UIStroke", bubbleBody)
bubbleStroke.Color = Color3.fromRGB(230, 206, 226); bubbleStroke.Thickness = 1.2; bubbleStroke.Transparency = 0.62
local bubbleGrad = Instance.new("UIGradient", bubbleBody)
bubbleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(44, 24, 46)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 13, 23))
})
bubbleGrad.Rotation = 135
local bubbleGreeting = Instance.new("TextLabel", bubbleBody)
bubbleGreeting.Size = UDim2.new(1, -14, 0, 24); bubbleGreeting.Position = UDim2.new(0, 12, 0, 8)
bubbleGreeting.BackgroundTransparency = 1; bubbleGreeting.Font = Enum.Font.GothamBold; bubbleGreeting.TextSize = 15
bubbleGreeting.TextColor3 = THEME_TEXT; bubbleGreeting.TextXAlignment = Enum.TextXAlignment.Left
bubbleGreeting.Text = "Hey " .. player.DisplayName .. "!"; bubbleGreeting.ZIndex = 3
local bubbleMsg = Instance.new("TextLabel", bubbleBody)
bubbleMsg.Size = UDim2.new(1, -14, 0, 28); bubbleMsg.Position = UDim2.new(0, 12, 0, 32)
bubbleMsg.BackgroundTransparency = 1; bubbleMsg.Font = Enum.Font.Gotham; bubbleMsg.TextSize = 12
bubbleMsg.TextColor3 = Color3.fromRGB(175, 158, 178); bubbleMsg.TextXAlignment = Enum.TextXAlignment.Left
bubbleMsg.TextYAlignment = Enum.TextYAlignment.Top; bubbleMsg.TextWrapped = true
bubbleMsg.Text = "Welcome back to VanillaHub. Enjoy your time here."; bubbleMsg.ZIndex = 3

-- STATS GRID
local statsContainer = Instance.new("Frame", homePage)
statsContainer.Size = UDim2.new(1, 0, 0, 130); statsContainer.BackgroundTransparency = 1
local gridLayout = Instance.new("UIGridLayout", statsContainer)
gridLayout.CellSize = UDim2.new(0, 140, 0, 36); gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; gridLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function createStatusBox(text, color)
    local box = Instance.new("Frame", statsContainer)
    box.BackgroundColor3 = CARD_BG; box.BorderSizePixel = 0
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 7)
    local lbl = Instance.new("TextLabel", box)
    lbl.Size = UDim2.new(1, -8, 1, -4); lbl.Position = UDim2.new(0, 4, 0, 2)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12
    lbl.TextColor3 = color or THEME_TEXT; lbl.Text = text; lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    return lbl
end

local pingLabel = createStatusBox("Ping: --")
createStatusBox("Lag: None", Color3.fromRGB(85, 185, 85))
createStatusBox("Acct Age: " .. player.AccountAge .. "d")
createStatusBox("Executor: Custom")

local rejoinBtn = Instance.new("TextButton", statsContainer)
rejoinBtn.BackgroundColor3 = CARD_BG; rejoinBtn.BorderSizePixel = 0
rejoinBtn.Font = Enum.Font.GothamSemibold; rejoinBtn.TextSize = 13
rejoinBtn.TextColor3 = THEME_TEXT; rejoinBtn.Text = "Rejoin"
Instance.new("UICorner", rejoinBtn).CornerRadius = UDim.new(0, 7)
rejoinBtn.MouseEnter:Connect(function() TweenService:Create(rejoinBtn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_HOVER}):Play() end)
rejoinBtn.MouseLeave:Connect(function() TweenService:Create(rejoinBtn, TweenInfo.new(0.15), {BackgroundColor3 = CARD_BG}):Play() end)
rejoinBtn.MouseButton1Click:Connect(function() pcall(function() TeleportService:Teleport(game.PlaceId, player) end) end)

local pingConn = RunService.Heartbeat:Connect(function()
    local ok, ping = pcall(function() return math.round(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
    pingLabel.Text = ok and ("Ping: " .. ping .. "ms") or "Ping: N/A"
end)
table.insert(cleanupTasks, function() if pingConn then pingConn:Disconnect(); pingConn = nil end end)

-- ════════════════════════════════════════════════════
-- TELEPORT TAB
-- ════════════════════════════════════════════════════
local teleportPage = pages["TeleportTab"]
local tpHeader = Instance.new("TextLabel", teleportPage)
tpHeader.Size = UDim2.new(1, -12, 0, 20); tpHeader.BackgroundTransparency = 1
tpHeader.Font = Enum.Font.GothamBold; tpHeader.TextSize = 10
tpHeader.TextColor3 = Color3.fromRGB(100, 95, 125); tpHeader.TextXAlignment = Enum.TextXAlignment.Left
tpHeader.Text = "QUICK TELEPORT"
Instance.new("UIPadding", tpHeader).PaddingLeft = UDim.new(0, 4)

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
    local btn = Instance.new("TextButton", teleportPage)
    btn.Size = UDim2.new(1, -12, 0, 34); btn.BackgroundColor3 = CARD_BG
    btn.BorderSizePixel = 0; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = THEME_TEXT; btn.Text = loc.name
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_HOVER, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = CARD_BG, TextColor3 = THEME_TEXT}):Play() end)
    btn.MouseButton1Click:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(loc.x, loc.y + 3, loc.z)
        end
    end)
end

-- ════════════════════════════════════════════════════
-- ITEM TAB
-- ════════════════════════════════════════════════════
local itemPage = pages["ItemTab"]
local itemLayout = itemPage:FindFirstChildOfClass("UIListLayout")
if itemLayout then itemLayout.Padding = UDim.new(0, 6) end

local tpItemSpeed     = 0.3
local tpMode          = "group"
local tpStopFlag      = false
local clickSelectEnabled  = false
local lassoEnabled        = false
local groupSelectEnabled  = false
local tpCircle            = nil

local function isnetworkowner(part)
    return part.ReceiveAge == 0
end

-- Item tab UI helpers
local function iSectionLabel(text)
    local lbl = Instance.new("TextLabel", itemPage)
    lbl.Size = UDim2.new(1, -12, 0, 17)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextColor3 = Color3.fromRGB(100, 95, 125)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 4)
end

local function iSep()
    local sep = Instance.new("Frame", itemPage)
    sep.Size = UDim2.new(1, -12, 0, 1)
    sep.BackgroundColor3 = Color3.fromRGB(30, 29, 40)
    sep.BorderSizePixel = 0
end

local function iButton(text, bgColor, cb)
    if type(bgColor) == "function" then cb = bgColor; bgColor = nil end
    local base = bgColor or BTN_COLOR
    local btn = Instance.new("TextButton", itemPage)
    btn.Size = UDim2.new(1, -12, 0, 34)
    btn.BackgroundColor3 = base
    btn.Text = text
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextColor3 = THEME_TEXT
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_HOVER}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = base}):Play() end)
    if cb then btn.MouseButton1Click:Connect(cb) end
    return btn
end

local function iToggleCard(text, default, cb)
    local card = Instance.new("Frame", itemPage)
    card.Size = UDim2.new(1, -12, 0, 34)
    card.BackgroundColor3 = CARD_BG
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 7)
    local lbl = Instance.new("TextLabel", card)
    lbl.Size = UDim2.new(1, -52, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local tb = Instance.new("TextButton", card)
    tb.Size = UDim2.new(0, 32, 0, 17)
    tb.Position = UDim2.new(1, -44, 0.5, -8.5)
    tb.BackgroundColor3 = default and Color3.fromRGB(55, 175, 55) or BTN_COLOR
    tb.Text = ""; tb.BorderSizePixel = 0
    Instance.new("UICorner", tb).CornerRadius = UDim.new(1, 0)
    local circle = Instance.new("Frame", tb)
    circle.Size = UDim2.new(0, 13, 0, 13)
    circle.Position = UDim2.new(0, default and 17 or 2, 0.5, -6.5)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.BorderSizePixel = 0
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    local toggled = default
    if cb then cb(toggled) end
    tb.MouseButton1Click:Connect(function()
        toggled = not toggled
        TweenService:Create(tb, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
            BackgroundColor3 = toggled and Color3.fromRGB(55, 175, 55) or BTN_COLOR
        }):Play()
        TweenService:Create(circle, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, toggled and 17 or 2, 0.5, -6.5)
        }):Play()
        if cb then cb(toggled) end
    end)
    return card
end

local function iSliderCard(text, minV, maxV, defV, cb)
    local card = Instance.new("Frame", itemPage)
    card.Size = UDim2.new(1, -12, 0, 52)
    card.BackgroundColor3 = CARD_BG
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 7)
    local topRow = Instance.new("Frame", card)
    topRow.Size = UDim2.new(1, -16, 0, 20); topRow.Position = UDim2.new(0, 8, 0, 7)
    topRow.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", topRow)
    lbl.Size = UDim2.new(0.7, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = text
    local valLbl = Instance.new("TextLabel", topRow)
    valLbl.Size = UDim2.new(0.3, 0, 1, 0); valLbl.Position = UDim2.new(0.7, 0, 0, 0)
    valLbl.BackgroundTransparency = 1; valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 13
    valLbl.TextColor3 = THEME_TEXT; valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Text = tostring(defV)
    local track = Instance.new("Frame", card)
    track.Size = UDim2.new(1, -16, 0, 5); track.Position = UDim2.new(0, 8, 0, 38)
    track.BackgroundColor3 = Color3.fromRGB(34, 33, 46); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((defV - minV) / (maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(85, 80, 110); fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0, 14, 0, 14); knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((defV - minV) / (maxV - minV), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(215, 210, 225); knob.Text = ""; knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local ds = false
    local function upd(absX)
        local r = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.round(minV + r * (maxV - minV))
        fill.Size = UDim2.new(r, 0, 1, 0); knob.Position = UDim2.new(r, 0, 0.5, 0)
        valLbl.Text = tostring(v); if cb then cb(v) end
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

-- ── SELECTION HELPERS ──────────────────────────────
local function selectPart(part)
    if not part or part:FindFirstChild("Selection") then return end
    local sb = Instance.new("SelectionBox", part)
    sb.Name = "Selection"; sb.Adornee = part
    sb.SurfaceTransparency = 0.5; sb.LineThickness = 0.09
    sb.SurfaceColor3 = Color3.fromRGB(0, 0, 0)
    sb.Color3 = Color3.fromRGB(0, 172, 240)
end

local function deselectPart(part)
    if not part then return end
    local s = part:FindFirstChild("Selection")
    if s then s:Destroy() end
end

local function deselectAll()
    for _, v in pairs(workspace.PlayerModels:GetChildren()) do
        if v:FindFirstChild("Owner") and (v:FindFirstChild("Main") or v:FindFirstChild("WoodSection")) then
            if v:FindFirstChild("Main") and v.Main:FindFirstChild("Selection") then v.Main.Selection:Destroy() end
            if v:FindFirstChild("WoodSection") and v.WoodSection:FindFirstChild("Selection") then v.WoodSection.Selection:Destroy() end
        end
    end
end
table.insert(cleanupTasks, deselectAll)

local function trySelect(target)
    if not target then return end
    local par = target.Parent; if not par then return end
    -- Only allow selection of items that have an Owner value AND a Main or WoodSection part
    -- This prevents vehicle seats and other non-item parts from being selected
    local function isValidItemModel(model)
        if not model then return false end
        if not model:FindFirstChild("Owner") then return false end
        if not (model:FindFirstChild("Main") or model:FindFirstChild("WoodSection")) then return false end
        return true
    end
    if isValidItemModel(par) then
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
    end
    local model = target:FindFirstAncestorOfClass("Model")
    if isValidItemModel(model) then
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
    if not (model and model:FindFirstChild("Owner") and (model:FindFirstChild("Main") or model:FindFirstChild("WoodSection"))) then
        model = target:FindFirstAncestorOfClass("Model")
    end
    if not (model and model:FindFirstChild("Owner") and (model:FindFirstChild("Main") or model:FindFirstChild("WoodSection"))) then return end
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

-- ── LASSO — throttled, no RenderStepped loop ────────
local lassoFrame = Instance.new("Frame", gui)
lassoFrame.Name = "VHLassoRect"
lassoFrame.BackgroundColor3 = Color3.fromRGB(55, 110, 195)
lassoFrame.BackgroundTransparency = 0.82
lassoFrame.BorderSizePixel = 0; lassoFrame.Visible = false; lassoFrame.ZIndex = 20
local lassoStroke = Instance.new("UIStroke", lassoFrame)
lassoStroke.Color = Color3.fromRGB(90, 150, 255); lassoStroke.Thickness = 1.2; lassoStroke.Transparency = 0

local lassoActive = false
local lassoOrigin = Vector2.new()

-- Lasso uses InputChanged (fires at mouse rate) and throttles world-checks to every 0.1s
local lastLassoCheck = 0

local function is_in_lasso(screenpos)
    local xPos = lassoFrame.AbsolutePosition.X
    local yPos = lassoFrame.AbsolutePosition.Y
    local xSize = lassoFrame.AbsoluteSize.X
    local ySize = lassoFrame.AbsoluteSize.Y
    -- handle negative size (drag left/up)
    local x1 = math.min(xPos, xPos + xSize)
    local x2 = math.max(xPos, xPos + xSize)
    local y1 = math.min(yPos, yPos + ySize)
    local y2 = math.max(yPos, yPos + ySize)
    return screenpos.X >= x1 and screenpos.X <= x2 and screenpos.Y >= y1 and screenpos.Y <= y2
end

UserInputService.InputBegan:Connect(function(input, gpe)
    -- GUI toggle
    if not gpe and input.KeyCode == currentToggleKey then
        toggleGUI(); return
    end
    -- Fly key
    if _G.VH and _G.VH.waitingForFlyKey and input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode ~= Enum.KeyCode.Escape then
            currentFlyKey = input.KeyCode
            if _G.VH then _G.VH.currentFlyKey = currentFlyKey end
            local kn = input.KeyCode.Name
            flyKeyBtn.Text = kn:sub(1, 5)
            flyHint.Text = "Press the fly key (" .. kn .. ") to toggle fly"
        end
        flyKeyBtn.BackgroundColor3 = BTN_COLOR
        if _G.VH then _G.VH.waitingForFlyKey = false end
        return
    end
    if _G.VH and not _G.VH.waitingForFlyKey and input.KeyCode == currentFlyKey then
        if _G.VH and _G.VH.flyEnabled then
            if isFlyEnabled then stopFly() else startFly() end
        end
        return
    end
    -- Lasso start
    if lassoEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 and not gpe then
        lassoActive = true
        lassoOrigin = Vector2.new(mouse.X, mouse.Y)
        lassoFrame.Position = UDim2.new(0, mouse.X, 0, mouse.Y)
        lassoFrame.Size = UDim2.new(0, 0, 0, 0)
        lassoFrame.Visible = true
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not lassoActive then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    local mx, my = mouse.X, mouse.Y
    local ox, oy = lassoOrigin.X, lassoOrigin.Y
    local sx = math.min(mx, ox); local sy = math.min(my, oy)
    local sw = math.abs(mx - ox); local sh = math.abs(my - oy)
    lassoFrame.Position = UDim2.new(0, sx, 0, sy)
    lassoFrame.Size = UDim2.new(0, sw, 0, sh)
    -- throttle world selection checks
    local now = tick()
    if now - lastLassoCheck < 0.1 then return end
    lastLassoCheck = now
    for _, v in pairs(workspace.PlayerModels:GetChildren()) do
        if v:FindFirstChild("Owner") and (v:FindFirstChild("Main") or v:FindFirstChild("WoodSection")) then
            if v:FindFirstChild("Main") then
                local sp, vis = Camera:WorldToScreenPoint(v.Main.CFrame.p)
                if vis and is_in_lasso(Vector2.new(sp.X, sp.Y)) then selectPart(v.Main) end
            end
            if v:FindFirstChild("WoodSection") then
                local sp, vis = Camera:WorldToScreenPoint(v.WoodSection.CFrame.p)
                if vis and is_in_lasso(Vector2.new(sp.X, sp.Y)) then selectPart(v.WoodSection) end
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if lassoActive then
            lassoActive = false
            lassoFrame.Visible = false
            lassoFrame.Size = UDim2.new(0, 0, 0, 0)
        end
    end
end)

mouse.Button1Up:Connect(function()
    if lassoEnabled then return end
    if clickSelectEnabled then trySelect(mouse.Target)
    elseif groupSelectEnabled then tryGroupSelect(mouse.Target) end
end)

-- ── SECTION 1: SELECTION MODE ──────────────────────
iSectionLabel("Selection Mode")

iToggleCard("Click Select", false, function(val)
    clickSelectEnabled = val
    if val then lassoEnabled = false; groupSelectEnabled = false end
end)
iToggleCard("Lasso Select", false, function(val)
    lassoEnabled = val
    if val then clickSelectEnabled = false; groupSelectEnabled = false end
end)
iToggleCard("Group Select", false, function(val)
    groupSelectEnabled = val
    if val then clickSelectEnabled = false; lassoEnabled = false end
end)

iButton("Deselect All", function() deselectAll() end)

iSep()

-- ── SECTION 2: TELEPORT MODE ───────────────────────
iSectionLabel("Teleport Mode")

local modeDesc = Instance.new("TextLabel", itemPage)
modeDesc.Size = UDim2.new(1, -12, 0, 26)
modeDesc.BackgroundColor3 = Color3.fromRGB(17, 17, 23)
modeDesc.BorderSizePixel = 0
modeDesc.Font = Enum.Font.Gotham; modeDesc.TextSize = 12
modeDesc.TextColor3 = Color3.fromRGB(115, 110, 140)
modeDesc.TextWrapped = true; modeDesc.TextXAlignment = Enum.TextXAlignment.Left
modeDesc.Text = "   Group: one item type teleported at a time"
Instance.new("UICorner", modeDesc).CornerRadius = UDim.new(0, 7)
Instance.new("UIPadding", modeDesc).PaddingLeft = UDim.new(0, 4)

local modeRow = Instance.new("Frame", itemPage)
modeRow.Size = UDim2.new(1, -12, 0, 34); modeRow.BackgroundTransparency = 1

local randomModeBtn = Instance.new("TextButton", modeRow)
randomModeBtn.Size = UDim2.new(0.5, -4, 1, 0); randomModeBtn.Position = UDim2.new(0, 0, 0, 0)
randomModeBtn.BackgroundColor3 = BTN_COLOR
randomModeBtn.Font = Enum.Font.GothamBold; randomModeBtn.TextSize = 13
randomModeBtn.TextColor3 = Color3.fromRGB(155, 150, 175); randomModeBtn.Text = "Random"
randomModeBtn.BorderSizePixel = 0
Instance.new("UICorner", randomModeBtn).CornerRadius = UDim.new(0, 7)

local groupModeBtn = Instance.new("TextButton", modeRow)
groupModeBtn.Size = UDim2.new(0.5, -4, 1, 0); groupModeBtn.Position = UDim2.new(0.5, 4, 0, 0)
groupModeBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 78)
groupModeBtn.Font = Enum.Font.GothamBold; groupModeBtn.TextSize = 13
groupModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255); groupModeBtn.Text = "Group"
groupModeBtn.BorderSizePixel = 0
Instance.new("UICorner", groupModeBtn).CornerRadius = UDim.new(0, 7)

local function setTpMode(mode)
    tpMode = mode
    if mode == "random" then
        TweenService:Create(randomModeBtn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(55,55,78), TextColor3 = Color3.fromRGB(255,255,255)}):Play()
        TweenService:Create(groupModeBtn, TweenInfo.new(0.18), {BackgroundColor3 = BTN_COLOR, TextColor3 = Color3.fromRGB(155,150,175)}):Play()
        modeDesc.Text = "   Random: items teleported in shuffled order"
    else
        TweenService:Create(groupModeBtn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(55,55,78), TextColor3 = Color3.fromRGB(255,255,255)}):Play()
        TweenService:Create(randomModeBtn, TweenInfo.new(0.18), {BackgroundColor3 = BTN_COLOR, TextColor3 = Color3.fromRGB(155,150,175)}):Play()
        modeDesc.Text = "   Group: one item type teleported at a time"
    end
end

randomModeBtn.MouseButton1Click:Connect(function() setTpMode("random") end)
groupModeBtn.MouseButton1Click:Connect(function() setTpMode("group") end)

iSep()

-- ── SECTION 3: DESTINATION ─────────────────────────
iSectionLabel("Destination")

local destRow = Instance.new("Frame", itemPage)
destRow.Size = UDim2.new(1, -12, 0, 34); destRow.BackgroundTransparency = 1

local tpSetBtn = Instance.new("TextButton", destRow)
tpSetBtn.Size = UDim2.new(0.5, -4, 1, 0); tpSetBtn.Position = UDim2.new(0, 0, 0, 0)
tpSetBtn.BackgroundColor3 = BTN_COLOR; tpSetBtn.Font = Enum.Font.GothamSemibold
tpSetBtn.TextSize = 13; tpSetBtn.TextColor3 = THEME_TEXT; tpSetBtn.Text = "Set Here"
tpSetBtn.BorderSizePixel = 0
Instance.new("UICorner", tpSetBtn).CornerRadius = UDim.new(0, 7)

local tpRemoveBtn = Instance.new("TextButton", destRow)
tpRemoveBtn.Size = UDim2.new(0.5, -4, 1, 0); tpRemoveBtn.Position = UDim2.new(0.5, 4, 0, 0)
tpRemoveBtn.BackgroundColor3 = BTN_COLOR; tpRemoveBtn.Font = Enum.Font.GothamSemibold
tpRemoveBtn.TextSize = 13; tpRemoveBtn.TextColor3 = THEME_TEXT; tpRemoveBtn.Text = "Remove"
tpRemoveBtn.BorderSizePixel = 0
Instance.new("UICorner", tpRemoveBtn).CornerRadius = UDim.new(0, 7)

for _, b in {tpSetBtn, tpRemoveBtn} do
    b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = BTN_HOVER}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = BTN_COLOR}):Play() end)
end

tpSetBtn.MouseButton1Click:Connect(function()
    if tpCircle then tpCircle:Destroy() end
    tpCircle = Instance.new("Part")
    tpCircle.Name = "VanillaHubTpCircle"
    tpCircle.Shape = Enum.PartType.Ball
    tpCircle.Size = Vector3.new(3, 3, 3)
    tpCircle.Material = Enum.Material.SmoothPlastic
    tpCircle.Color = Color3.fromRGB(110, 105, 130)
    tpCircle.Anchored = true; tpCircle.CanCollide = false
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        tpCircle.Position = char.HumanoidRootPart.Position
    end
    tpCircle.Parent = workspace
    tpSetBtn.Text = "Destination Set"
    TweenService:Create(tpSetBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(36, 72, 50)}):Play()
end)

tpRemoveBtn.MouseButton1Click:Connect(function()
    if tpCircle then tpCircle:Destroy(); tpCircle = nil end
    tpSetBtn.Text = "Set Here"
    TweenService:Create(tpSetBtn, TweenInfo.new(0.2), {BackgroundColor3 = BTN_COLOR}):Play()
end)

table.insert(cleanupTasks, function()
    if tpCircle and tpCircle.Parent then tpCircle:Destroy(); tpCircle = nil end
end)

iSep()

-- ── SECTION 4: SPEED ───────────────────────────────
iSectionLabel("Speed")
iSliderCard("Delay per item (s)", 1, 20, 3, function(v) tpItemSpeed = v / 10 end)

iSep()

-- ── SECTION 5: ACTIONS ─────────────────────────────
iSectionLabel("Actions")

-- Stop button (starts hidden)
local stopBtn = iButton("Stop Teleport", Color3.fromRGB(120, 38, 38), function()
    tpStopFlag = true
end)
stopBtn.Visible = false
stopBtn.MouseEnter:Connect(function() TweenService:Create(stopBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(165, 52, 52)}):Play() end)
stopBtn.MouseLeave:Connect(function() TweenService:Create(stopBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(120, 38, 38)}):Play() end)

-- Helpers
local function getSelectedParts()
    local result = {}
    for _, v in next, workspace.PlayerModels:GetDescendants() do
        if v.Name == "Selection" then
            local part = v.Parent
            if part and part.Parent then table.insert(result, part) end
        end
    end
    return result
end

-- True random shuffle using Fisher-Yates
local function shuffleTable(t)
    for i = #t, 2, -1 do
        local j = math.random(1, i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

local function getGroupedParts()
    local groups = {}; local order = {}
    for _, v in next, workspace.PlayerModels:GetDescendants() do
        if v.Name == "Selection" then
            local part = v.Parent
            if part and part.Parent then
                local model = part.Parent
                local iv = model:FindFirstChild("ItemName")
                local key = iv and iv.Value or model.Name
                if not groups[key] then groups[key] = {}; table.insert(order, key) end
                table.insert(groups[key], part)
            end
        end
    end
    return groups, order
end

local function teleportItemPart(part, destCF)
    if tpStopFlag then return false end
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = CFrame.new(part.CFrame.p) * CFrame.new(5, 0, 0) end
    task.wait(tpItemSpeed)
    if tpStopFlag then return false end
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
    return not tpStopFlag
end

local function runTeleport(destCF, parts)
    tpStopFlag = false
    stopBtn.Visible = true
    if tpMode == "random" then
        -- Truly shuffle ALL selected parts regardless of name
        local shuffled = shuffleTable(parts)
        for _, part in ipairs(shuffled) do
            if not teleportItemPart(part, destCF) then break end
        end
    else
        local groups, order = getGroupedParts()
        for _, key in ipairs(order) do
            for _, part in ipairs(groups[key]) do
                if not teleportItemPart(part, destCF) then break end
            end
            if tpStopFlag then break end
        end
    end
    tpStopFlag = false
    stopBtn.Visible = false
end

local tpToDestBtn = iButton("Teleport to Destination", function()
    if not tpCircle then return end
    local destCF = tpCircle.CFrame
    local parts = getSelectedParts()
    local oldPos = player.Character
        and player.Character:FindFirstChild("HumanoidRootPart")
        and player.Character.HumanoidRootPart.CFrame
    task.spawn(function()
        runTeleport(destCF, parts)
        if oldPos and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = oldPos
        end
    end)
end)

local sellBtn = iButton("Sell Selected Items", function()
    local parts = getSelectedParts()
    local oldPos = player.Character
        and player.Character:FindFirstChild("HumanoidRootPart")
        and player.Character.HumanoidRootPart.CFrame
    local dropoff = CFrame.new(314.776, -1.593, 87.807)
    task.spawn(function()
        runTeleport(dropoff, parts)
        if oldPos and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = oldPos
        end
    end)
end)

-- ════════════════════════════════════════════════════
-- PLAYER TAB
-- ════════════════════════════════════════════════════
local playerPage = pages["PlayerTab"]

local function createPSection(text)
    local lbl = Instance.new("TextLabel", playerPage)
    lbl.Size = UDim2.new(1, -12, 0, 20); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 10
    lbl.TextColor3 = Color3.fromRGB(100, 95, 125); lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 4)
end

local function createPSep()
    local s = Instance.new("Frame", playerPage)
    s.Size = UDim2.new(1, -12, 0, 1); s.BackgroundColor3 = Color3.fromRGB(30, 29, 40); s.BorderSizePixel = 0
end

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
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
    end
end)

local function createPSlider(labelText, minVal, maxVal, defaultVal, onChanged)
    local frame = Instance.new("Frame", playerPage)
    frame.Size = UDim2.new(1, -12, 0, 52); frame.BackgroundColor3 = CARD_BG
    frame.BorderSizePixel = 0; Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 7)
    local topRow = Instance.new("Frame", frame)
    topRow.Size = UDim2.new(1, -16, 0, 20); topRow.Position = UDim2.new(0, 8, 0, 7); topRow.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", topRow)
    lbl.Size = UDim2.new(0.7, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = labelText
    local valLbl = Instance.new("TextLabel", topRow)
    valLbl.Size = UDim2.new(0.3, 0, 1, 0); valLbl.Position = UDim2.new(0.7, 0, 0, 0); valLbl.BackgroundTransparency = 1
    valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 13; valLbl.TextColor3 = THEME_TEXT
    valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.Text = tostring(defaultVal)
    local track = Instance.new("Frame", frame)
    track.Size = UDim2.new(1, -16, 0, 5); track.Position = UDim2.new(0, 8, 0, 38)
    track.BackgroundColor3 = Color3.fromRGB(34, 33, 46); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(85, 80, 110); fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0, 14, 0, 14); knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(215, 210, 225); knob.Text = ""; knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local ds = false
    local function upd(absX)
        local r = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.round(minVal + r * (maxVal - minVal))
        fill.Size = UDim2.new(r, 0, 1, 0); knob.Position = UDim2.new(r, 0, 0.5, 0)
        valLbl.Text = tostring(v); if onChanged then onChanged(v) end
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

local function createPToggle(text, defaultState, callback)
    local frame = Instance.new("Frame", playerPage)
    frame.Size = UDim2.new(1, -12, 0, 34); frame.BackgroundColor3 = CARD_BG
    frame.BorderSizePixel = 0; Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 7)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -50, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0); lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local tb = Instance.new("TextButton", frame)
    tb.Size = UDim2.new(0, 32, 0, 17); tb.Position = UDim2.new(1, -44, 0.5, -8.5)
    tb.BackgroundColor3 = defaultState and Color3.fromRGB(55, 175, 55) or BTN_COLOR
    tb.Text = ""; Instance.new("UICorner", tb).CornerRadius = UDim.new(1, 0)
    local circle = Instance.new("Frame", tb)
    circle.Size = UDim2.new(0, 13, 0, 13); circle.Position = UDim2.new(0, defaultState and 17 or 2, 0.5, -6.5)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    local toggled = defaultState
    if callback then callback(toggled) end
    local function setToggled(val)
        toggled = val
        TweenService:Create(tb, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {BackgroundColor3 = toggled and Color3.fromRGB(55, 175, 55) or BTN_COLOR}):Play()
        TweenService:Create(circle, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {Position = UDim2.new(0, toggled and 17 or 2, 0.5, -6.5)}):Play()
    end
    tb.MouseButton1Click:Connect(function()
        toggled = not toggled; setToggled(toggled)
        if callback then callback(toggled) end
    end)
    return frame, setToggled, function() return toggled end
end

createPSection("Movement")

createPSlider("Walkspeed", 16, 150, 16, function(val)
    savedWalkSpeed = val
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = val end
end)

createPSlider("Jumppower", 50, 300, 50, function(val)
    savedJumpPower = val
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.JumpPower = val end
end)

local flySpeed = 100
createPSlider("Fly Speed", 100, 500, 100, function(val) flySpeed = val end)

-- Fly key row
local flyKeyFrame = Instance.new("Frame", playerPage)
flyKeyFrame.Size = UDim2.new(1, -12, 0, 34); flyKeyFrame.BackgroundColor3 = CARD_BG
flyKeyFrame.BorderSizePixel = 0; Instance.new("UICorner", flyKeyFrame).CornerRadius = UDim.new(0, 7)
local flyKeyLabel = Instance.new("TextLabel", flyKeyFrame)
flyKeyLabel.Size = UDim2.new(0.6, 0, 1, 0); flyKeyLabel.Position = UDim2.new(0, 12, 0, 0)
flyKeyLabel.BackgroundTransparency = 1; flyKeyLabel.Font = Enum.Font.GothamSemibold; flyKeyLabel.TextSize = 13
flyKeyLabel.TextColor3 = THEME_TEXT; flyKeyLabel.TextXAlignment = Enum.TextXAlignment.Left; flyKeyLabel.Text = "Fly Key"
local currentFlyKey = Enum.KeyCode.Q
local flyKeyBtn = Instance.new("TextButton", flyKeyFrame)
flyKeyBtn.Size = UDim2.new(0, 56, 0, 22); flyKeyBtn.Position = UDim2.new(1, -66, 0.5, -11)
flyKeyBtn.BackgroundColor3 = BTN_COLOR; flyKeyBtn.Font = Enum.Font.GothamSemibold
flyKeyBtn.TextSize = 12; flyKeyBtn.TextColor3 = THEME_TEXT; flyKeyBtn.Text = "Q"
flyKeyBtn.BorderSizePixel = 0; Instance.new("UICorner", flyKeyBtn).CornerRadius = UDim.new(0, 6)
flyKeyBtn.MouseEnter:Connect(function() TweenService:Create(flyKeyBtn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_HOVER}):Play() end)
flyKeyBtn.MouseLeave:Connect(function() TweenService:Create(flyKeyBtn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_COLOR}):Play() end)
flyKeyBtn.MouseButton1Click:Connect(function()
    if _G.VH and _G.VH.waitingForFlyKey then return end
    if _G.VH then _G.VH.waitingForFlyKey = true end
    flyKeyBtn.Text = "..."; flyKeyBtn.BackgroundColor3 = Color3.fromRGB(55, 90, 55)
end)

-- Fly enable/disable toggle (enabled by default)
local isFlyEnabled = false
local flyBV, flyBG, flyConn

local function stopFly()
    isFlyEnabled = false
    if _G.VH then _G.VH.isFlyEnabled = false end
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV and flyBV.Parent then flyBV:Destroy(); flyBV = nil end
    if flyBG and flyBG.Parent then flyBG:Destroy(); flyBG = nil end
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.PlatformStand = false end
end

local function startFly()
    stopFly(); isFlyEnabled = true
    if _G.VH then _G.VH.isFlyEnabled = true end
    local char = player.Character; if not char then isFlyEnabled = false; return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum then isFlyEnabled = false; return end
    hum.PlatformStand = true
    flyBV = Instance.new("BodyVelocity", root)
    flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5); flyBV.Velocity = Vector3.zero
    flyBG = Instance.new("BodyGyro", root)
    flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5); flyBG.P = 1e4; flyBG.D = 100
    flyConn = RunService.Heartbeat:Connect(function()
        if not (flyBV and flyBV.Parent and flyBG and flyBG.Parent) then return end
        local ch = player.Character; local h = ch and ch:FindFirstChild("Humanoid"); local r = ch and ch:FindFirstChild("HumanoidRootPart")
        if not (h and r) then return end
        local cf = workspace.CurrentCamera.CFrame
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W)          then dir = dir + cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)          then dir = dir - cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)          then dir = dir - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)          then dir = dir + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)      then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)  then dir = dir - Vector3.new(0,1,0) end
        h.PlatformStand = true
        flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero
        flyBG.CFrame = cf
    end)
end

table.insert(cleanupTasks, stopFly)

-- Fly toggle switch (enabled by default = true)
local flyEnabled = true

local flyToggleFrame = Instance.new("Frame", playerPage)
flyToggleFrame.Size = UDim2.new(1, -12, 0, 34); flyToggleFrame.BackgroundColor3 = CARD_BG
flyToggleFrame.BorderSizePixel = 0; Instance.new("UICorner", flyToggleFrame).CornerRadius = UDim.new(0, 7)
local flyToggleLbl = Instance.new("TextLabel", flyToggleFrame)
flyToggleLbl.Size = UDim2.new(1, -52, 1, 0); flyToggleLbl.Position = UDim2.new(0, 12, 0, 0)
flyToggleLbl.BackgroundTransparency = 1; flyToggleLbl.Font = Enum.Font.GothamSemibold; flyToggleLbl.TextSize = 13
flyToggleLbl.TextColor3 = THEME_TEXT; flyToggleLbl.TextXAlignment = Enum.TextXAlignment.Left; flyToggleLbl.Text = "Fly"
local flyToggleBtn = Instance.new("TextButton", flyToggleFrame)
flyToggleBtn.Size = UDim2.new(0, 32, 0, 17); flyToggleBtn.Position = UDim2.new(1, -44, 0.5, -8.5)
flyToggleBtn.BackgroundColor3 = Color3.fromRGB(55, 175, 55) -- starts enabled
flyToggleBtn.Text = ""; flyToggleBtn.BorderSizePixel = 0
Instance.new("UICorner", flyToggleBtn).CornerRadius = UDim.new(1, 0)
local flyToggleCircle = Instance.new("Frame", flyToggleBtn)
flyToggleCircle.Size = UDim2.new(0, 13, 0, 13); flyToggleCircle.Position = UDim2.new(0, 17, 0.5, -6.5)
flyToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255); flyToggleCircle.BorderSizePixel = 0
Instance.new("UICorner", flyToggleCircle).CornerRadius = UDim.new(1, 0)
flyToggleBtn.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    TweenService:Create(flyToggleBtn, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
        BackgroundColor3 = flyEnabled and Color3.fromRGB(55, 175, 55) or BTN_COLOR
    }):Play()
    TweenService:Create(flyToggleCircle, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
        Position = UDim2.new(0, flyEnabled and 17 or 2, 0.5, -6.5)
    }):Play()
    if _G.VH then _G.VH.flyEnabled = flyEnabled end
    if not flyEnabled and isFlyEnabled then stopFly() end
end)

local flyHint = Instance.new("TextLabel", playerPage)
flyHint.Size = UDim2.new(1, -12, 0, 20); flyHint.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
flyHint.BorderSizePixel = 0; flyHint.Font = Enum.Font.Gotham; flyHint.TextSize = 11
flyHint.TextColor3 = Color3.fromRGB(95, 90, 120); flyHint.TextWrapped = true
flyHint.TextXAlignment = Enum.TextXAlignment.Left
flyHint.Text = "  Press the fly key (Q) to toggle fly"
Instance.new("UICorner", flyHint).CornerRadius = UDim.new(0, 6)
Instance.new("UIPadding", flyHint).PaddingLeft = UDim.new(0, 6)

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
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end)
table.insert(cleanupTasks, function()
    noclipEnabled = false
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
end)

local infJumpEnabled = false; local infJumpConn
createPToggle("Inf Jump", false, function(val)
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
    switchTab        = switchTab,
    toggleGUI        = toggleGUI,
    stopFly          = stopFly,
    startFly         = startFly,
    butter           = { running = false, thread = nil },
    flyEnabled       = true,
    flyToggleEnabled = true,
    isFlyEnabled     = false,
    currentFlyKey    = Enum.KeyCode.Q,
    waitingForFlyKey = false,
    flyKeyBtn        = flyKeyBtn,
    currentToggleKey = currentToggleKey,
    waitingForKeyGUI = false,
    keybindButtonGUI = nil,
}

_G.VanillaHubCleanup = onExit

print("[VanillaHub] Loaded successfully")
