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

-- SERVICES & PLAYER
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
local BTN_COLOR  = Color3.fromRGB(45, 45, 50)
local BTN_HOVER  = Color3.fromRGB(70, 70, 80)

-- CLEANUP REGISTRY
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

-- GUI SCAFFOLD
local gui = Instance.new("ScreenGui")
gui.Name = "VanillaHub"; gui.Parent = game.CoreGui; gui.ResetOnSpawn = false
table.insert(cleanupTasks, function() if gui and gui.Parent then gui:Destroy() end end)

_G.VanillaHubCleanup = onExit

local wrapper = Instance.new("Frame", gui)
wrapper.Size = UDim2.new(0, 0, 0, 0)
wrapper.Position = UDim2.new(0.5, -260, 0.5, -170)
wrapper.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
wrapper.BackgroundTransparency = 1; wrapper.BorderSizePixel = 0; wrapper.ClipsDescendants = false
Instance.new("UICorner", wrapper).CornerRadius = UDim.new(0, 12)

local main = Instance.new("Frame", wrapper)
main.Size = UDim2.new(1, 0, 1, 0); main.Position = UDim2.new(0, 0, 0, 0)
main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
main.BackgroundTransparency = 1; main.BorderSizePixel = 0; main.ClipsDescendants = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

TweenService:Create(wrapper, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 520, 0, 340), BackgroundTransparency = 0
}):Play()
TweenService:Create(main, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    BackgroundTransparency = 0
}):Play()

-- TOP BAR
local topBar = Instance.new("Frame", main)
topBar.Size = UDim2.new(1, 0, 0, 38); topBar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
topBar.BorderSizePixel = 0; topBar.ZIndex = 4

local hubIcon = Instance.new("ImageLabel", topBar)
hubIcon.Size = UDim2.new(0, 26, 0, 26); hubIcon.Position = UDim2.new(0, 7, 0.5, -13)
hubIcon.BackgroundTransparency = 1; hubIcon.BorderSizePixel = 0
hubIcon.ScaleType = Enum.ScaleType.Fit; hubIcon.ZIndex = 6
hubIcon.Image = "rbxassetid://97128823316544"
Instance.new("UICorner", hubIcon).CornerRadius = UDim.new(0, 5)

local titleLbl = Instance.new("TextLabel", topBar)
titleLbl.Size = UDim2.new(1, -90, 1, 0); titleLbl.Position = UDim2.new(0, 42, 0, 0)
titleLbl.BackgroundTransparency = 1; titleLbl.Text = "VanillaHub"
titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 17
titleLbl.TextColor3 = THEME_TEXT; titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.ZIndex = 5

local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, 32, 0, 32); closeBtn.Position = UDim2.new(1, -38, 0, 3)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40); closeBtn.Text = "x"
closeBtn.Font = Enum.Font.Gotham; closeBtn.TextSize = 20
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255); closeBtn.BorderSizePixel = 0; closeBtn.ZIndex = 5
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

local function showConfirmClose()
    if main:FindFirstChild("ConfirmOverlay") then return end
    local overlay = Instance.new("Frame", main)
    overlay.Name = "ConfirmOverlay"; overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0); overlay.BackgroundTransparency = 0.4; overlay.ZIndex = 9
    local dialog = Instance.new("Frame", main)
    dialog.Name = "ConfirmDialog"; dialog.Size = UDim2.new(0, 360, 0, 180)
    dialog.Position = UDim2.new(0.5, -180, 0.5, -90)
    dialog.BackgroundColor3 = Color3.fromRGB(20, 20, 22); dialog.BorderSizePixel = 0; dialog.ZIndex = 10
    Instance.new("UICorner", dialog).CornerRadius = UDim.new(0, 14)
    local dStroke = Instance.new("UIStroke", dialog)
    dStroke.Color = Color3.fromRGB(90, 90, 100); dStroke.Thickness = 1.2; dStroke.Transparency = 0.6
    local dtitle = Instance.new("TextLabel", dialog)
    dtitle.Size = UDim2.new(1, 0, 0, 40); dtitle.BackgroundTransparency = 1
    dtitle.Font = Enum.Font.GothamBold; dtitle.TextSize = 19
    dtitle.TextColor3 = THEME_TEXT; dtitle.Text = "Confirm Exit"; dtitle.ZIndex = 11
    local dmsg = Instance.new("TextLabel", dialog)
    dmsg.Size = UDim2.new(1, -40, 0, 60); dmsg.Position = UDim2.new(0, 20, 0, 45)
    dmsg.BackgroundTransparency = 1; dmsg.Font = Enum.Font.Gotham; dmsg.TextSize = 15
    dmsg.TextColor3 = THEME_TEXT
    dmsg.Text = "Are you sure you want to close VanillaHub?\n\nYou will need to re-execute the script to use it again."
    dmsg.TextWrapped = true; dmsg.TextYAlignment = Enum.TextYAlignment.Center; dmsg.ZIndex = 11
    local cancelBtn2 = Instance.new("TextButton", dialog)
    cancelBtn2.Size = UDim2.new(0, 150, 0, 46); cancelBtn2.Position = UDim2.new(0.5, -160, 1, -65)
    cancelBtn2.BackgroundColor3 = Color3.fromRGB(45, 45, 50); cancelBtn2.Text = "Cancel"
    cancelBtn2.Font = Enum.Font.GothamSemibold; cancelBtn2.TextSize = 16
    cancelBtn2.TextColor3 = THEME_TEXT; cancelBtn2.ZIndex = 11
    Instance.new("UICorner", cancelBtn2).CornerRadius = UDim.new(0, 10)
    local confirmBtn2 = Instance.new("TextButton", dialog)
    confirmBtn2.Size = UDim2.new(0, 150, 0, 46); confirmBtn2.Position = UDim2.new(0.5, 10, 1, -65)
    confirmBtn2.BackgroundColor3 = Color3.fromRGB(180, 45, 45); confirmBtn2.Text = "Exit VanillaHub"
    confirmBtn2.Font = Enum.Font.GothamSemibold; confirmBtn2.TextSize = 16
    confirmBtn2.TextColor3 = Color3.fromRGB(255, 255, 255); confirmBtn2.ZIndex = 11
    Instance.new("UICorner", confirmBtn2).CornerRadius = UDim.new(0, 10)
    for _, b in {cancelBtn2, confirmBtn2} do
        b.MouseEnter:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.15), {
                BackgroundColor3 = (b == confirmBtn2) and Color3.fromRGB(210,60,60) or Color3.fromRGB(70,70,80)
            }):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.15), {
                BackgroundColor3 = (b == confirmBtn2) and Color3.fromRGB(180,45,45) or Color3.fromRGB(45,45,50)
            }):Play()
        end)
    end
    cancelBtn2.MouseButton1Click:Connect(function() overlay:Destroy(); dialog:Destroy() end)
    confirmBtn2.MouseButton1Click:Connect(function()
        overlay:Destroy(); dialog:Destroy()
        onExit()
        local t = TweenService:Create(wrapper, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
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
local side = Instance.new("ScrollingFrame", main)
side.Size = UDim2.new(0, 160, 1, -38); side.Position = UDim2.new(0, 0, 0, 38)
side.BackgroundColor3 = Color3.fromRGB(10, 10, 10); side.BorderSizePixel = 0
side.ScrollBarThickness = 4; side.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
side.CanvasSize = UDim2.new(0, 0, 0, 0)
local sideLayout = Instance.new("UIListLayout", side)
sideLayout.Padding = UDim.new(0, 8); sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    side.CanvasSize = UDim2.new(0, 0, 0, sideLayout.AbsoluteContentSize.Y + 24)
end)

-- CONTENT AREA
local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, -160, 1, -38); content.Position = UDim2.new(0, 160, 0, 38)
content.BackgroundColor3 = Color3.fromRGB(0, 0, 0); content.BorderSizePixel = 0

-- WELCOME POPUP
task.spawn(function()
    task.wait(0.8)
    if not (gui and gui.Parent) then return end
    local wf = Instance.new("Frame", gui)
    wf.Size = UDim2.new(0, 380, 0, 90); wf.Position = UDim2.new(0.5, -190, 1, -110)
    wf.BackgroundColor3 = Color3.fromRGB(12, 12, 12); wf.BackgroundTransparency = 1; wf.BorderSizePixel = 0
    Instance.new("UICorner", wf).CornerRadius = UDim.new(0, 14)
    local ws = Instance.new("UIStroke", wf)
    ws.Color = Color3.fromRGB(35,35,35); ws.Thickness = 1.2; ws.Transparency = 0.6
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
    wt.Text = "Welcome back,\n" .. player.DisplayName
    TweenService:Create(wf, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.35}):Play()
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

-- TABS
local tabs = {"Home","Player","World","Teleport","Wood","Slot","Dupe","Item","Sorter","AutoBuy","Pixel Art","Build","Vehicle","Search","Settings"}
local pages = {}

for _, name in ipairs(tabs) do
    local page = Instance.new("ScrollingFrame", content)
    page.Name = name .. "Tab"; page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1; page.BorderSizePixel = 0
    page.ScrollBarThickness = 5; page.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70)
    page.Visible = false; page.CanvasSize = UDim2.new(0, 0, 0, 0)
    local list = Instance.new("UIListLayout", page)
    list.Padding = UDim.new(0, 8); list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.SortOrder = Enum.SortOrder.LayoutOrder
    local pad = Instance.new("UIPadding", page)
    pad.PaddingTop = UDim.new(0, 12); pad.PaddingBottom = UDim.new(0, 16)
    pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12)
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 40)
    end)
    pages[name .. "Tab"] = page
end

-- TAB SWITCHING
local activeTabButton = nil
local function switchTab(targetName)
    for _, page in pairs(pages) do page.Visible = (page.Name == targetName) end
    if activeTabButton then
        TweenService:Create(activeTabButton, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(18,18,18), TextColor3 = Color3.fromRGB(160,160,160)
        }):Play()
    end
    local btn = side:FindFirstChild(targetName:gsub("Tab",""))
    if btn then
        activeTabButton = btn
        TweenService:Create(btn, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(40,40,40), TextColor3 = THEME_TEXT
        }):Play()
    end
end

for _, name in ipairs(tabs) do
    local btn = Instance.new("TextButton", side)
    btn.Name = name; btn.Size = UDim2.new(0.92, 0, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(18,18,18); btn.BorderSizePixel = 0
    btn.Text = name; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(160,160,160); btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    Instance.new("UIPadding", btn).PaddingLeft = UDim.new(0, 16)
    local rippleContainer = Instance.new("Frame", btn)
    rippleContainer.Size = UDim2.new(1,0,1,0); rippleContainer.BackgroundTransparency = 1
    rippleContainer.BorderSizePixel = 0; rippleContainer.ZIndex = 2; rippleContainer.ClipsDescendants = true
    Instance.new("UICorner", rippleContainer).CornerRadius = UDim.new(0, 6)
    btn.MouseEnter:Connect(function()
        if activeTabButton ~= btn then
            TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3=Color3.fromRGB(30,30,38), TextColor3=Color3.fromRGB(200,185,200)}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeTabButton ~= btn then
            TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3=Color3.fromRGB(18,18,18), TextColor3=Color3.fromRGB(160,160,160)}):Play()
        end
    end)
    btn.MouseButton1Click:Connect(function()
        task.spawn(function()
            local ripple = Instance.new("Frame", rippleContainer)
            ripple.Size = UDim2.new(0,8,0,8); ripple.Position = UDim2.new(0.5,-4,0.5,-4)
            ripple.BackgroundColor3 = Color3.fromRGB(200,185,200)
            ripple.BackgroundTransparency = 0.75; ripple.BorderSizePixel = 0
            Instance.new("UICorner", ripple).CornerRadius = UDim.new(1,0)
            TweenService:Create(ripple, TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size=UDim2.new(0,140,0,140), Position=UDim2.new(0.5,-70,0.5,-70), BackgroundTransparency=1
            }):Play()
            task.wait(0.4)
            if ripple and ripple.Parent then ripple:Destroy() end
        end)
        switchTab(name.."Tab")
    end)
end

switchTab("HomeTab")

-- ════════════════════════════════════════════════════
-- GUI TOGGLE  — ALT key hides/shows wrapper only.
-- No fog, no background overlay, no Lighting changes.
-- ════════════════════════════════════════════════════
local currentToggleKey = Enum.KeyCode.LeftAlt
local guiOpen        = true
local isAnimatingGUI = false
local keybindButtonGUI

local function toggleGUI()
    if isAnimatingGUI then return end
    guiOpen = not guiOpen
    isAnimatingGUI = true
    if guiOpen then
        wrapper.Visible = true
        main.Visible    = true
        wrapper.Size               = UDim2.new(0,0,0,0)
        wrapper.BackgroundTransparency = 1
        main.BackgroundTransparency    = 1
        local tw = TweenService:Create(wrapper, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0,520,0,340), BackgroundTransparency = 0
        })
        local tm = TweenService:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0
        })
        tw:Play(); tm:Play()
        tw.Completed:Connect(function() isAnimatingGUI = false end)
    else
        local tw = TweenService:Create(wrapper, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0,0,0,0), BackgroundTransparency = 1
        })
        local tm = TweenService:Create(main, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1
        })
        tw:Play(); tm:Play()
        tw.Completed:Connect(function()
            wrapper.Visible = false
            main.Visible    = false
            isAnimatingGUI  = false
        end)
    end
end

-- ALT key listener (separate from fly key listener below)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == currentToggleKey then toggleGUI() end
end)

-- HOME TAB
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
bubbleMsg.Text="Welcome back to VanillaHub!\nEnjoy your time here"; bubbleMsg.ZIndex=3

-- STATS GRID
local statsContainer = Instance.new("Frame", homePage)
statsContainer.Size=UDim2.new(1,0,0,160); statsContainer.BackgroundTransparency=1
local gridLayout=Instance.new("UIGridLayout",statsContainer)
gridLayout.CellSize=UDim2.new(0,148,0,42); gridLayout.CellPadding=UDim2.new(0,12,0,12)
gridLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center; gridLayout.SortOrder=Enum.SortOrder.LayoutOrder

local function createStatusBox(text, color)
    local box=Instance.new("Frame",statsContainer)
    box.BackgroundColor3=Color3.fromRGB(22,22,28); box.BorderSizePixel=0
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
rejoinBtn.Size=UDim2.new(0,148,0,42); rejoinBtn.BackgroundColor3=Color3.fromRGB(22,22,28); rejoinBtn.BorderSizePixel=0
rejoinBtn.Font=Enum.Font.Gotham; rejoinBtn.TextSize=14; rejoinBtn.TextColor3=THEME_TEXT; rejoinBtn.Text="Rejoin"
Instance.new("UICorner",rejoinBtn).CornerRadius=UDim.new(0,8)
rejoinBtn.MouseEnter:Connect(function() TweenService:Create(rejoinBtn,TweenInfo.new(0.18),{BackgroundColor3=Color3.fromRGB(35,35,45)}):Play() end)
rejoinBtn.MouseLeave:Connect(function() TweenService:Create(rejoinBtn,TweenInfo.new(0.18),{BackgroundColor3=Color3.fromRGB(22,22,28)}):Play() end)
rejoinBtn.MouseButton1Click:Connect(function() pcall(function() TeleportService:Teleport(game.PlaceId,player) end) end)

local pingConn = RunService.Heartbeat:Connect(function()
    local ok, ping = pcall(function() return math.round(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
    pingLabel.Text = ok and ("Ping: "..ping.." ms") or "Ping: N/A"
end)
table.insert(cleanupTasks, function() if pingConn then pingConn:Disconnect(); pingConn=nil end end)

-- TELEPORT TAB
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
    btn.Size=UDim2.new(1,-12,0,36); btn.BackgroundColor3=Color3.fromRGB(20,20,26)
    btn.BorderSizePixel=0; btn.Font=Enum.Font.GothamSemibold; btn.TextSize=13
    btn.TextColor3=THEME_TEXT; btn.Text=loc.name
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)
    btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(38,38,50),TextColor3=Color3.fromRGB(255,255,255)}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(20,20,26),TextColor3=THEME_TEXT}):Play() end)
    btn.MouseButton1Click:Connect(function()
        local char=player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame=CFrame.new(loc.x,loc.y+3,loc.z)
        end
    end)
end

-- ════════════════════════════════════════════════════
-- ITEM TAB
-- ════════════════════════════════════════════════════
local itemPage = pages["ItemTab"]
local _ipl = itemPage:FindFirstChildOfClass("UIListLayout")
if _ipl then _ipl.Padding = UDim.new(0, 6) end

local clickSelectEnabled = false
local lassoEnabled       = false
local groupSelectEnabled = false
local tpCircle           = nil
local tpItemSpeed        = 0.3
local tpMode             = "random"
local tpRunning          = false

local function isnetworkowner(part)
    return part.ReceiveAge == 0
end

-- Item Tab UI helpers

local function iLabel(text)
    local lbl = Instance.new("TextLabel", itemPage)
    lbl.Size = UDim2.new(1, -4, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 10
    lbl.TextColor3 = Color3.fromRGB(100, 100, 130)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    local p = Instance.new("UIPadding", lbl)
    p.PaddingLeft = UDim.new(0, 2); p.PaddingTop = UDim.new(0, 4)
end

local function iSep()
    local sep = Instance.new("Frame", itemPage)
    sep.Size = UDim2.new(1, 0, 0, 1)
    sep.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
    sep.BorderSizePixel = 0
end

local function iToggle(text, default, cb)
    local frame = Instance.new("Frame", itemPage)
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 7)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -52, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = text
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local tb = Instance.new("TextButton", frame)
    tb.Size = UDim2.new(0, 32, 0, 17); tb.Position = UDim2.new(1, -43, 0.5, -8)
    tb.BackgroundColor3 = default and Color3.fromRGB(55,170,55) or BTN_COLOR
    tb.Text = ""; tb.BorderSizePixel = 0
    Instance.new("UICorner", tb).CornerRadius = UDim.new(1, 0)
    local dot = Instance.new("Frame", tb)
    dot.Size = UDim2.new(0, 13, 0, 13)
    dot.Position = UDim2.new(0, default and 17 or 2, 0.5, -6)
    dot.BackgroundColor3 = Color3.fromRGB(255,255,255); dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local toggled = default
    if cb then cb(toggled) end
    tb.MouseButton1Click:Connect(function()
        toggled = not toggled
        TweenService:Create(tb, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
            BackgroundColor3 = toggled and Color3.fromRGB(55,170,55) or BTN_COLOR
        }):Play()
        TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, toggled and 17 or 2, 0.5, -6)
        }):Play()
        if cb then cb(toggled) end
    end)
    return frame
end

local function iSlider(text, minV, maxV, defV, cb)
    local frame = Instance.new("Frame", itemPage)
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 27); frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 7)
    local row = Instance.new("Frame", frame)
    row.Size = UDim2.new(1,-14,0,20); row.Position = UDim2.new(0,7,0,5); row.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.65,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 12; lbl.TextColor3 = THEME_TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = text
    local valLbl = Instance.new("TextLabel", row)
    valLbl.Size = UDim2.new(0.35,0,1,0); valLbl.Position = UDim2.new(0.65,0,0,0)
    valLbl.BackgroundTransparency = 1; valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 12
    valLbl.TextColor3 = THEME_TEXT; valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Text = tostring(defV)
    local track = Instance.new("Frame", frame)
    track.Size = UDim2.new(1,-14,0,5); track.Position = UDim2.new(0,7,0,34)
    track.BackgroundColor3 = Color3.fromRGB(35,35,50); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((defV-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(85,85,110); fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0,14,0,14); knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new((defV-minV)/(maxV-minV),0,0.5,0)
    knob.BackgroundColor3 = Color3.fromRGB(210,210,225); knob.Text = ""; knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local ds = false
    local function upd(absX)
        local r = math.clamp((absX-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local v = math.round(minV+r*(maxV-minV))
        fill.Size = UDim2.new(r,0,1,0); knob.Position = UDim2.new(r,0,0.5,0); valLbl.Text = tostring(v)
        if cb then cb(v) end
    end
    knob.MouseButton1Down:Connect(function() ds = true end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then ds=true; upd(i.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if ds and i.UserInputType == Enum.UserInputType.MouseMovement then upd(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then ds = false end
    end)
end

-- Selection helpers

local function selectPart(part)
    if not part or part:FindFirstChild("Selection") then return end
    local sb = Instance.new("SelectionBox", part)
    sb.Name = "Selection"; sb.Adornee = part
    sb.SurfaceTransparency = 0.5; sb.LineThickness = 0.09
    sb.SurfaceColor3 = Color3.fromRGB(0,0,0); sb.Color3 = Color3.fromRGB(0,172,240)
end

local function deselectPart(part)
    if not part then return end
    local s = part:FindFirstChild("Selection"); if s then s:Destroy() end
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
    local par = target.Parent; if not (par and par:FindFirstChild("Owner")) then return end
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
            local p = model.Main; if p:FindFirstChild("Selection") then deselectPart(p) else selectPart(p) end
        elseif model:FindFirstChild("WoodSection") then
            local p = model.WoodSection; if p:FindFirstChild("Selection") then deselectPart(p) else selectPart(p) end
        end
    end
end

local function tryGroupSelect(target)
    if not target then return end
    local model = target.Parent
    if not (model and model:FindFirstChild("Owner")) then model = target:FindFirstAncestorOfClass("Model") end
    if not (model and model:FindFirstChild("Owner")) then return end
    local iv = model:FindFirstChild("ItemName")
    local groupName = iv and iv.Value or model.Name
    for _, v in pairs(workspace.PlayerModels:GetChildren()) do
        if v:FindFirstChild("Owner") then
            local viv = v:FindFirstChild("ItemName")
            if (viv and viv.Value or v.Name) == groupName then
                if v:FindFirstChild("Main") then selectPart(v.Main) end
                if v:FindFirstChild("WoodSection") then selectPart(v.WoodSection) end
            end
        end
    end
end

-- Lasso
local lassoFrame = Instance.new("Frame", gui)
lassoFrame.Name = "VHLassoRect"; lassoFrame.BackgroundColor3 = Color3.fromRGB(60,120,200)
lassoFrame.BackgroundTransparency = 0.82; lassoFrame.BorderSizePixel = 0
lassoFrame.Visible = false; lassoFrame.ZIndex = 20
local lassoStroke = Instance.new("UIStroke", lassoFrame)
lassoStroke.Color = Color3.fromRGB(100,160,255); lassoStroke.Thickness = 1.5

local function is_in_frame(sp, frame)
    local x,y = frame.AbsolutePosition.X, frame.AbsolutePosition.Y
    local w,h = frame.AbsoluteSize.X, frame.AbsoluteSize.Y
    return sp.X>=math.min(x,x+w) and sp.X<=math.max(x,x+w)
       and sp.Y>=math.min(y,y+h) and sp.Y<=math.max(y,y+h)
end

local Camera = workspace.CurrentCamera

UserInputService.InputBegan:Connect(function(input)
    if not lassoEnabled then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    lassoFrame.Visible = true
    lassoFrame.Position = UDim2.new(0,mouse.X,0,mouse.Y)
    lassoFrame.Size = UDim2.new(0,0,0,0)
    while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
        RunService.RenderStepped:Wait()
        lassoFrame.Size = UDim2.new(0,mouse.X,0,mouse.Y) - lassoFrame.Position
        for _, v in pairs(workspace.PlayerModels:GetChildren()) do
            if v:FindFirstChild("Main") then
                local sp,vis = Camera:WorldToScreenPoint(v.Main.CFrame.p)
                if vis and is_in_frame(sp,lassoFrame) then selectPart(v.Main) end
            end
            if v:FindFirstChild("WoodSection") then
                local sp,vis = Camera:WorldToScreenPoint(v.WoodSection.CFrame.p)
                if vis and is_in_frame(sp,lassoFrame) then selectPart(v.WoodSection) end
            end
        end
    end
    lassoFrame.Size = UDim2.new(0,1,0,1); lassoFrame.Visible = false
end)

mouse.Button1Up:Connect(function()
    if lassoEnabled then return end
    if clickSelectEnabled then trySelect(mouse.Target)
    elseif groupSelectEnabled then tryGroupSelect(mouse.Target) end
end)

-- SECTION: Selection Mode
iLabel("Selection Mode")
iToggle("Click Select", false, function(v)
    clickSelectEnabled = v
    if v then lassoEnabled=false; groupSelectEnabled=false end
end)
iToggle("Lasso Select", false, function(v)
    lassoEnabled = v
    if v then clickSelectEnabled=false; groupSelectEnabled=false end
end)
iToggle("Group Select", false, function(v)
    groupSelectEnabled = v
    if v then clickSelectEnabled=false; lassoEnabled=false end
end)

iSep()

-- SECTION: Teleport Mode
iLabel("Teleport Mode")

local modeDesc = Instance.new("TextLabel", itemPage)
modeDesc.Size = UDim2.new(1,0,0,26)
modeDesc.BackgroundColor3 = Color3.fromRGB(18,18,26); modeDesc.BorderSizePixel = 0
modeDesc.Font = Enum.Font.Gotham; modeDesc.TextSize = 11
modeDesc.TextColor3 = Color3.fromRGB(115,108,140); modeDesc.TextXAlignment = Enum.TextXAlignment.Left
modeDesc.TextWrapped = true; modeDesc.Text = "    Items teleported in shuffled order"
Instance.new("UICorner", modeDesc).CornerRadius = UDim.new(0, 6)

local modeRow = Instance.new("Frame", itemPage)
modeRow.Size = UDim2.new(1,0,0,30); modeRow.BackgroundTransparency = 1

local ACTIVE_C   = Color3.fromRGB(58,55,82)
local INACTIVE_C = Color3.fromRGB(26,26,34)

local randomBtn = Instance.new("TextButton", modeRow)
randomBtn.Size = UDim2.new(0.5,-3,1,0); randomBtn.Position = UDim2.new(0,0,0,0)
randomBtn.BackgroundColor3 = ACTIVE_C; randomBtn.BorderSizePixel = 0
randomBtn.Font = Enum.Font.GothamBold; randomBtn.TextSize = 12
randomBtn.TextColor3 = Color3.fromRGB(220,215,235); randomBtn.Text = "Random"
Instance.new("UICorner", randomBtn).CornerRadius = UDim.new(0, 7)

local groupBtn = Instance.new("TextButton", modeRow)
groupBtn.Size = UDim2.new(0.5,-3,1,0); groupBtn.Position = UDim2.new(0.5,3,0,0)
groupBtn.BackgroundColor3 = INACTIVE_C; groupBtn.BorderSizePixel = 0
groupBtn.Font = Enum.Font.GothamBold; groupBtn.TextSize = 12
groupBtn.TextColor3 = Color3.fromRGB(130,125,155); groupBtn.Text = "Group"
Instance.new("UICorner", groupBtn).CornerRadius = UDim.new(0, 7)

local function setTpMode(mode)
    tpMode = mode
    TweenService:Create(randomBtn, TweenInfo.new(0.18), {
        BackgroundColor3 = mode=="random" and ACTIVE_C or INACTIVE_C,
        TextColor3       = mode=="random" and Color3.fromRGB(220,215,235) or Color3.fromRGB(130,125,155)
    }):Play()
    TweenService:Create(groupBtn, TweenInfo.new(0.18), {
        BackgroundColor3 = mode=="group" and ACTIVE_C or INACTIVE_C,
        TextColor3       = mode=="group" and Color3.fromRGB(220,215,235) or Color3.fromRGB(130,125,155)
    }):Play()
    modeDesc.Text = mode=="random"
        and "    Items teleported in shuffled order"
        or  "    Finishes one item type before the next"
end

randomBtn.MouseButton1Click:Connect(function() setTpMode("random") end)
groupBtn.MouseButton1Click:Connect(function()  setTpMode("group")  end)

iSep()

-- SECTION: Destination
iLabel("Destination")

local destRow = Instance.new("Frame", itemPage)
destRow.Size = UDim2.new(1,0,0,30); destRow.BackgroundTransparency = 1

local setHereBtn = Instance.new("TextButton", destRow)
setHereBtn.Size = UDim2.new(0.5,-3,1,0); setHereBtn.Position = UDim2.new(0,0,0,0)
setHereBtn.BackgroundColor3 = BTN_COLOR; setHereBtn.BorderSizePixel = 0
setHereBtn.Font = Enum.Font.GothamSemibold; setHereBtn.TextSize = 12
setHereBtn.TextColor3 = THEME_TEXT; setHereBtn.Text = "Set Here"
Instance.new("UICorner", setHereBtn).CornerRadius = UDim.new(0, 7)

local removeDestBtn = Instance.new("TextButton", destRow)
removeDestBtn.Size = UDim2.new(0.5,-3,1,0); removeDestBtn.Position = UDim2.new(0.5,3,0,0)
removeDestBtn.BackgroundColor3 = BTN_COLOR; removeDestBtn.BorderSizePixel = 0
removeDestBtn.Font = Enum.Font.GothamSemibold; removeDestBtn.TextSize = 12
removeDestBtn.TextColor3 = THEME_TEXT; removeDestBtn.Text = "Remove"
Instance.new("UICorner", removeDestBtn).CornerRadius = UDim.new(0, 7)

for _, b in {setHereBtn, removeDestBtn} do
    b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.14),{BackgroundColor3=BTN_HOVER}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.14),{BackgroundColor3=BTN_COLOR}):Play() end)
end

setHereBtn.MouseButton1Click:Connect(function()
    if tpCircle then tpCircle:Destroy() end
    tpCircle = Instance.new("Part")
    tpCircle.Name = "VanillaHubTpCircle"; tpCircle.Shape = Enum.PartType.Ball
    tpCircle.Size = Vector3.new(3,3,3); tpCircle.Material = Enum.Material.SmoothPlastic
    tpCircle.Color = Color3.fromRGB(120,120,130); tpCircle.Anchored = true; tpCircle.CanCollide = false
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        tpCircle.Position = char.HumanoidRootPart.Position
    end
    tpCircle.Parent = workspace
    setHereBtn.Text = "Set"
    TweenService:Create(setHereBtn,TweenInfo.new(0.18),{BackgroundColor3=Color3.fromRGB(36,68,46)}):Play()
end)

removeDestBtn.MouseButton1Click:Connect(function()
    if tpCircle then tpCircle:Destroy(); tpCircle = nil end
    setHereBtn.Text = "Set Here"
    TweenService:Create(setHereBtn,TweenInfo.new(0.18),{BackgroundColor3=BTN_COLOR}):Play()
end)

table.insert(cleanupTasks, function()
    if tpCircle and tpCircle.Parent then tpCircle:Destroy(); tpCircle = nil end
end)

iSep()

-- SECTION: Speed
iLabel("Speed")
iSlider("Delay per item (sec)", 1, 20, 3, function(v) tpItemSpeed = v/10 end)

iSep()

-- SECTION: Actions
iLabel("Actions")

-- Core teleport logic
local function teleportItemPart(part, destCF)
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = CFrame.new(part.CFrame.p) * CFrame.new(5,0,0) end
    task.wait(tpItemSpeed)
    pcall(function()
        if not part.Parent.PrimaryPart then part.Parent.PrimaryPart = part end
        local dragger = ReplicatedStorage:FindFirstChild("Interaction")
            and ReplicatedStorage.Interaction:FindFirstChild("ClientIsDragging")
        local t = 0
        while not isnetworkowner(part) and t < 3 do
            if dragger then dragger:FireServer(part.Parent) end
            task.wait(0.05); t = t + 0.05
        end
        if dragger then dragger:FireServer(part.Parent) end
        part:PivotTo(destCF)
    end)
    task.wait(tpItemSpeed)
end

-- Random: collect all selected parts then Fisher-Yates shuffle
-- This ensures items of the same type are genuinely mixed, not sequential
local function getRandomOrderParts()
    local list = {}
    for _, v in next, workspace.PlayerModels:GetDescendants() do
        if v.Name == "Selection" then
            local part = v.Parent
            if part and part.Parent then table.insert(list, part) end
        end
    end
    for i = #list, 2, -1 do
        local j = math.random(1, i)
        list[i], list[j] = list[j], list[i]
    end
    return list
end

-- Group: bucket by ItemName, process each bucket fully before moving on
local function getGroupedParts()
    local groups, order = {}, {}
    for _, v in next, workspace.PlayerModels:GetDescendants() do
        if v.Name == "Selection" then
            local part = v.Parent
            if part and part.Parent then
                local model = part.Parent
                local iv    = model:FindFirstChild("ItemName")
                local key   = iv and iv.Value or model.Name
                if not groups[key] then groups[key]={} ; table.insert(order,key) end
                table.insert(groups[key], part)
            end
        end
    end
    return groups, order
end

-- Progress bar
local progressLabel = Instance.new("TextLabel", itemPage)
progressLabel.Size = UDim2.new(1,0,0,22)
progressLabel.BackgroundColor3 = Color3.fromRGB(18,18,26); progressLabel.BorderSizePixel = 0
progressLabel.Font = Enum.Font.Gotham; progressLabel.TextSize = 11
progressLabel.TextColor3 = Color3.fromRGB(100,200,130); progressLabel.TextXAlignment = Enum.TextXAlignment.Center
progressLabel.Text = ""; progressLabel.Visible = false
Instance.new("UICorner", progressLabel).CornerRadius = UDim.new(0, 6)

local function runTeleport(destCF)
    if tpRunning then return end
    if not tpCircle then return end
    tpRunning = true
    progressLabel.Visible = true
    local oldPos = player.Character
        and player.Character:FindFirstChild("HumanoidRootPart")
        and player.Character.HumanoidRootPart.CFrame
    task.spawn(function()
        if tpMode == "random" then
            local parts = getRandomOrderParts()
            for i, part in ipairs(parts) do
                if not tpRunning then break end
                progressLabel.Text = "Teleporting " .. i .. "/" .. #parts
                teleportItemPart(part, destCF)
            end
        else
            local groups, order = getGroupedParts()
            local total, done = 0, 0
            for _, k in ipairs(order) do total = total + #groups[k] end
            for _, key in ipairs(order) do
                for _, part in ipairs(groups[key]) do
                    if not tpRunning then break end
                    done = done + 1
                    progressLabel.Text = "[" .. key .. "] " .. done .. "/" .. total
                    teleportItemPart(part, destCF)
                end
                if not tpRunning then break end
            end
        end
        tpRunning = false
        if progressLabel.Text ~= "" then
            progressLabel.Text = "Done"
            task.delay(2, function() progressLabel.Visible = false; progressLabel.Text = "" end)
        else
            progressLabel.Visible = false
        end
        if oldPos and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = oldPos
        end
    end)
end

-- Teleport to destination row (Go + Stop)
local tpRow = Instance.new("Frame", itemPage)
tpRow.Size = UDim2.new(1,0,0,32); tpRow.BackgroundTransparency = 1

local tpGoBtn = Instance.new("TextButton", tpRow)
tpGoBtn.Size = UDim2.new(1,-68,1,0); tpGoBtn.Position = UDim2.new(0,0,0,0)
tpGoBtn.BackgroundColor3 = Color3.fromRGB(42,52,68); tpGoBtn.BorderSizePixel = 0
tpGoBtn.Font = Enum.Font.GothamBold; tpGoBtn.TextSize = 12
tpGoBtn.TextColor3 = Color3.fromRGB(175,205,240); tpGoBtn.Text = "Teleport Selected"
Instance.new("UICorner", tpGoBtn).CornerRadius = UDim.new(0, 7)

local tpStopBtn = Instance.new("TextButton", tpRow)
tpStopBtn.Size = UDim2.new(0,60,1,0); tpStopBtn.Position = UDim2.new(1,-60,0,0)
tpStopBtn.BackgroundColor3 = Color3.fromRGB(72,26,26); tpStopBtn.BorderSizePixel = 0
tpStopBtn.Font = Enum.Font.GothamBold; tpStopBtn.TextSize = 12
tpStopBtn.TextColor3 = Color3.fromRGB(255,155,155); tpStopBtn.Text = "Stop"
Instance.new("UICorner", tpStopBtn).CornerRadius = UDim.new(0, 7)

tpGoBtn.MouseEnter:Connect(function() TweenService:Create(tpGoBtn,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(58,70,90)}):Play() end)
tpGoBtn.MouseLeave:Connect(function() TweenService:Create(tpGoBtn,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(42,52,68)}):Play() end)
tpStopBtn.MouseEnter:Connect(function() TweenService:Create(tpStopBtn,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(96,35,35)}):Play() end)
tpStopBtn.MouseLeave:Connect(function() TweenService:Create(tpStopBtn,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(72,26,26)}):Play() end)

tpGoBtn.MouseButton1Click:Connect(function() runTeleport(tpCircle and tpCircle.CFrame) end)
tpStopBtn.MouseButton1Click:Connect(function() tpRunning = false end)

-- Sell row (Go + Stop)
local sellRow = Instance.new("Frame", itemPage)
sellRow.Size = UDim2.new(1,0,0,32); sellRow.BackgroundTransparency = 1

local sellGoBtn = Instance.new("TextButton", sellRow)
sellGoBtn.Size = UDim2.new(1,-68,1,0); sellGoBtn.Position = UDim2.new(0,0,0,0)
sellGoBtn.BackgroundColor3 = Color3.fromRGB(36,54,38); sellGoBtn.BorderSizePixel = 0
sellGoBtn.Font = Enum.Font.GothamBold; sellGoBtn.TextSize = 12
sellGoBtn.TextColor3 = Color3.fromRGB(155,228,165); sellGoBtn.Text = "Sell Selected"
Instance.new("UICorner", sellGoBtn).CornerRadius = UDim.new(0, 7)

local sellStopBtn = Instance.new("TextButton", sellRow)
sellStopBtn.Size = UDim2.new(0,60,1,0); sellStopBtn.Position = UDim2.new(1,-60,0,0)
sellStopBtn.BackgroundColor3 = Color3.fromRGB(72,26,26); sellStopBtn.BorderSizePixel = 0
sellStopBtn.Font = Enum.Font.GothamBold; sellStopBtn.TextSize = 12
sellStopBtn.TextColor3 = Color3.fromRGB(255,155,155); sellStopBtn.Text = "Stop"
Instance.new("UICorner", sellStopBtn).CornerRadius = UDim.new(0, 7)

sellGoBtn.MouseEnter:Connect(function() TweenService:Create(sellGoBtn,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(50,72,52)}):Play() end)
sellGoBtn.MouseLeave:Connect(function() TweenService:Create(sellGoBtn,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(36,54,38)}):Play() end)
sellStopBtn.MouseEnter:Connect(function() TweenService:Create(sellStopBtn,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(96,35,35)}):Play() end)
sellStopBtn.MouseLeave:Connect(function() TweenService:Create(sellStopBtn,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(72,26,26)}):Play() end)

sellGoBtn.MouseButton1Click:Connect(function()
    -- temporarily point tpCircle at dropoff then run
    local fakeCF = CFrame.new(314.776, -1.593, 87.807)
    if tpRunning then return end
    if not tpCircle then
        -- create a temporary invisible destination at the dropoff
        tpCircle = Instance.new("Part")
        tpCircle.Name = "VanillaHubTpCircle"; tpCircle.Anchored = true; tpCircle.CanCollide = false
        tpCircle.Size = Vector3.new(1,1,1); tpCircle.Transparency = 1
        tpCircle.CFrame = fakeCF; tpCircle.Parent = workspace
        runTeleport(fakeCF)
        tpCircle:Destroy(); tpCircle = nil
        setHereBtn.Text = "Set Here"
        TweenService:Create(setHereBtn,TweenInfo.new(0.18),{BackgroundColor3=BTN_COLOR}):Play()
    else
        runTeleport(fakeCF)
    end
end)
sellStopBtn.MouseButton1Click:Connect(function() tpRunning = false end)

-- Deselect All
local deselectBtn = Instance.new("TextButton", itemPage)
deselectBtn.Size = UDim2.new(1,0,0,30); deselectBtn.BackgroundColor3 = BTN_COLOR
deselectBtn.BorderSizePixel = 0; deselectBtn.Font = Enum.Font.GothamSemibold; deselectBtn.TextSize = 12
deselectBtn.TextColor3 = THEME_TEXT; deselectBtn.Text = "Deselect All"
Instance.new("UICorner", deselectBtn).CornerRadius = UDim.new(0, 7)
deselectBtn.MouseEnter:Connect(function() TweenService:Create(deselectBtn,TweenInfo.new(0.14),{BackgroundColor3=BTN_HOVER}):Play() end)
deselectBtn.MouseLeave:Connect(function() TweenService:Create(deselectBtn,TweenInfo.new(0.14),{BackgroundColor3=BTN_COLOR}):Play() end)
deselectBtn.MouseButton1Click:Connect(function() deselectAll() end)

-- ════════════════════════════════════════════════════
-- PLAYER TAB
-- ════════════════════════════════════════════════════
local playerPage = pages["PlayerTab"]

local function createPSection(text)
    local lbl=Instance.new("TextLabel",playerPage)
    lbl.Size=UDim2.new(1,-12,0,22); lbl.BackgroundTransparency=1
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=11
    lbl.TextColor3=Color3.fromRGB(120,120,150); lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Text=string.upper(text)
    Instance.new("UIPadding",lbl).PaddingLeft=UDim.new(0,4)
end

local function createPSep()
    local s=Instance.new("Frame",playerPage)
    s.Size=UDim2.new(1,-12,0,1); s.BackgroundColor3=Color3.fromRGB(40,40,55); s.BorderSizePixel=0
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
    frame.Size=UDim2.new(1,-12,0,52); frame.BackgroundColor3=Color3.fromRGB(24,24,30)
    frame.BorderSizePixel=0; Instance.new("UICorner",frame).CornerRadius=UDim.new(0,6)
    local topRow=Instance.new("Frame",frame)
    topRow.Size=UDim2.new(1,-16,0,22); topRow.Position=UDim2.new(0,8,0,6); topRow.BackgroundTransparency=1
    local lbl=Instance.new("TextLabel",topRow)
    lbl.Size=UDim2.new(0.7,0,1,0); lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=13
    lbl.TextColor3=THEME_TEXT; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=labelText
    local valLbl=Instance.new("TextLabel",topRow)
    valLbl.Size=UDim2.new(0.3,0,1,0); valLbl.Position=UDim2.new(0.7,0,0,0); valLbl.BackgroundTransparency=1
    valLbl.Font=Enum.Font.GothamBold; valLbl.TextSize=13; valLbl.TextColor3=THEME_TEXT
    valLbl.TextXAlignment=Enum.TextXAlignment.Right; valLbl.Text=tostring(defaultVal)
    local track=Instance.new("Frame",frame)
    track.Size=UDim2.new(1,-16,0,6); track.Position=UDim2.new(0,8,0,36)
    track.BackgroundColor3=Color3.fromRGB(40,40,55); track.BorderSizePixel=0
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new((defaultVal-minVal)/(maxVal-minVal),0,1,0)
    fill.BackgroundColor3=Color3.fromRGB(80,80,100); fill.BorderSizePixel=0
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("TextButton",track)
    knob.Size=UDim2.new(0,16,0,16); knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new((defaultVal-minVal)/(maxVal-minVal),0,0.5,0)
    knob.BackgroundColor3=Color3.fromRGB(210,210,225); knob.Text=""; knob.BorderSizePixel=0
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
    frame.Size=UDim2.new(1,-12,0,32); frame.BackgroundColor3=Color3.fromRGB(24,24,30)
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,6)
    local lbl=Instance.new("TextLabel",frame)
    lbl.Size=UDim2.new(1,-50,1,0); lbl.Position=UDim2.new(0,10,0,0); lbl.BackgroundTransparency=1
    lbl.Text=text; lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=13
    lbl.TextColor3=THEME_TEXT; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local tb=Instance.new("TextButton",frame)
    tb.Size=UDim2.new(0,34,0,18); tb.Position=UDim2.new(1,-44,0.5,-9)
    tb.BackgroundColor3=defaultState and Color3.fromRGB(60,180,60) or BTN_COLOR
    tb.Text=""; Instance.new("UICorner",tb).CornerRadius=UDim.new(1,0)
    local circle=Instance.new("Frame",tb)
    circle.Size=UDim2.new(0,14,0,14); circle.Position=UDim2.new(0,defaultState and 18 or 2,0.5,-7)
    circle.BackgroundColor3=Color3.fromRGB(255,255,255)
    Instance.new("UICorner",circle).CornerRadius=UDim.new(1,0)
    local toggled=defaultState
    if callback then callback(toggled) end
    local function setToggled(val)
        toggled=val
        TweenService:Create(tb,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=toggled and Color3.fromRGB(60,180,60) or BTN_COLOR}):Play()
        TweenService:Create(circle,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{Position=UDim2.new(0,toggled and 18 or 2,0.5,-7)}):Play()
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

local flySpeed = 100
createPSlider("Fly Speed", 100, 500, 100, function(val) flySpeed=val end)

-- Fly Key row
local flyKeyFrame=Instance.new("Frame",playerPage)
flyKeyFrame.Size=UDim2.new(1,-12,0,32); flyKeyFrame.BackgroundColor3=Color3.fromRGB(24,24,30)
Instance.new("UICorner",flyKeyFrame).CornerRadius=UDim.new(0,6)
local flyKeyLabel=Instance.new("TextLabel",flyKeyFrame)
flyKeyLabel.Size=UDim2.new(0.6,0,1,0); flyKeyLabel.Position=UDim2.new(0,10,0,0)
flyKeyLabel.BackgroundTransparency=1; flyKeyLabel.Font=Enum.Font.GothamSemibold; flyKeyLabel.TextSize=13
flyKeyLabel.TextColor3=THEME_TEXT; flyKeyLabel.TextXAlignment=Enum.TextXAlignment.Left; flyKeyLabel.Text="Fly Key"
local currentFlyKey = Enum.KeyCode.Q
local flyKeyBtn=Instance.new("TextButton",flyKeyFrame)
flyKeyBtn.Size=UDim2.new(0,60,0,22); flyKeyBtn.Position=UDim2.new(1,-68,0.5,-11)
flyKeyBtn.BackgroundColor3=BTN_COLOR; flyKeyBtn.Font=Enum.Font.GothamSemibold
flyKeyBtn.TextSize=12; flyKeyBtn.TextColor3=THEME_TEXT; flyKeyBtn.Text="Q"
flyKeyBtn.BorderSizePixel=0; Instance.new("UICorner",flyKeyBtn).CornerRadius=UDim.new(0,6)
flyKeyBtn.MouseEnter:Connect(function() TweenService:Create(flyKeyBtn,TweenInfo.new(0.15),{BackgroundColor3=BTN_HOVER}):Play() end)
flyKeyBtn.MouseLeave:Connect(function() TweenService:Create(flyKeyBtn,TweenInfo.new(0.15),{BackgroundColor3=BTN_COLOR}):Play() end)
flyKeyBtn.MouseButton1Click:Connect(function()
    if _G.VH and _G.VH.waitingForFlyKey then return end
    if _G.VH then _G.VH.waitingForFlyKey=true end
    flyKeyBtn.Text="..."; flyKeyBtn.BackgroundColor3=Color3.fromRGB(60,100,60)
end)

-- Fly enable/disable toggle (default ON)
local isFlyEnabled  = false
local flyToggleEnabled = true
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
    if not flyToggleEnabled then return end
    stopFly(); isFlyEnabled=true
    if _G.VH then _G.VH.isFlyEnabled=true end
    local char=player.Character; if not char then isFlyEnabled=false; return end
    local root=char:FindFirstChild("HumanoidRootPart")
    local hum=char:FindFirstChild("Humanoid")
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

-- Fly Enable toggle row (default ON = green)
local flyEnableFrame=Instance.new("Frame",playerPage)
flyEnableFrame.Size=UDim2.new(1,-12,0,32); flyEnableFrame.BackgroundColor3=Color3.fromRGB(24,24,30)
flyEnableFrame.BorderSizePixel=0
Instance.new("UICorner",flyEnableFrame).CornerRadius=UDim.new(0,6)
local flyEnableLbl=Instance.new("TextLabel",flyEnableFrame)
flyEnableLbl.Size=UDim2.new(1,-50,1,0); flyEnableLbl.Position=UDim2.new(0,10,0,0)
flyEnableLbl.BackgroundTransparency=1; flyEnableLbl.Font=Enum.Font.GothamSemibold; flyEnableLbl.TextSize=13
flyEnableLbl.TextColor3=THEME_TEXT; flyEnableLbl.TextXAlignment=Enum.TextXAlignment.Left
flyEnableLbl.Text="Fly Enabled"
local flyEnableTb=Instance.new("TextButton",flyEnableFrame)
flyEnableTb.Size=UDim2.new(0,34,0,18); flyEnableTb.Position=UDim2.new(1,-44,0.5,-9)
flyEnableTb.BackgroundColor3=Color3.fromRGB(60,180,60)  -- starts ON
flyEnableTb.Text=""; flyEnableTb.BorderSizePixel=0
Instance.new("UICorner",flyEnableTb).CornerRadius=UDim.new(1,0)
local flyEnableDot=Instance.new("Frame",flyEnableTb)
flyEnableDot.Size=UDim2.new(0,14,0,14); flyEnableDot.Position=UDim2.new(0,18,0.5,-7)
flyEnableDot.BackgroundColor3=Color3.fromRGB(255,255,255); flyEnableDot.BorderSizePixel=0
Instance.new("UICorner",flyEnableDot).CornerRadius=UDim.new(1,0)

flyEnableTb.MouseButton1Click:Connect(function()
    flyToggleEnabled = not flyToggleEnabled
    if not flyToggleEnabled then stopFly() end  -- immediately stop fly when disabled
    TweenService:Create(flyEnableTb,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{
        BackgroundColor3 = flyToggleEnabled and Color3.fromRGB(60,180,60) or BTN_COLOR
    }):Play()
    TweenService:Create(flyEnableDot,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{
        Position = UDim2.new(0, flyToggleEnabled and 18 or 2, 0.5, -7)
    }):Play()
end)

-- Fly key input listener
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    -- rebind
    if _G.VH and _G.VH.waitingForFlyKey then
        _G.VH.waitingForFlyKey = false
        currentFlyKey = input.KeyCode
        if _G.VH then _G.VH.currentFlyKey = currentFlyKey end
        flyKeyBtn.Text = input.KeyCode.Name
        TweenService:Create(flyKeyBtn,TweenInfo.new(0.15),{BackgroundColor3=BTN_COLOR}):Play()
        return
    end
    -- toggle fly
    if not flyToggleEnabled then return end
    if input.KeyCode == currentFlyKey then
        if isFlyEnabled then stopFly() else startFly() end
    end
end)

local flyHint=Instance.new("TextLabel",playerPage)
flyHint.Size=UDim2.new(1,-12,0,22); flyHint.BackgroundColor3=Color3.fromRGB(18,18,24)
flyHint.BorderSizePixel=0; flyHint.Font=Enum.Font.Gotham; flyHint.TextSize=11
flyHint.TextColor3=Color3.fromRGB(100,100,130); flyHint.TextWrapped=true
flyHint.TextXAlignment=Enum.TextXAlignment.Left
flyHint.Text="  Press your Fly Key (Q) to toggle fly on/off"
Instance.new("UICorner",flyHint).CornerRadius=UDim.new(0,6)
Instance.new("UIPadding",flyHint).PaddingLeft=UDim.new(0,6)

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
        if char then
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=true end
            end
        end
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
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        if infJumpConn then infJumpConn:Disconnect(); infJumpConn=nil end
    end
end)
table.insert(cleanupTasks, function()
    infJumpEnabled=false
    if infJumpConn then infJumpConn:Disconnect(); infJumpConn=nil end
end)

-- SHARED GLOBALS
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

print("[VanillaHub] Vanilla1 loaded")
