-- ════════════════════════════════════════════════════
-- VANILLA5 — Player Tab + World Tab + Pixel Art Tab
-- Execute AFTER Vanilla1
-- ════════════════════════════════════════════════════

if not _G.VH then
    warn("[VanillaHub] Vanilla5: _G.VH not found. Execute Vanilla1 first.")
    return
end

local TweenService     = _G.VH.TweenService
local UserInputService = _G.VH.UserInputService
local RunService       = _G.VH.RunService
local player           = _G.VH.player
local cleanupTasks     = _G.VH.cleanupTasks
local pages            = _G.VH.pages
local BTN_COLOR        = _G.VH.BTN_COLOR
local BTN_HOVER        = _G.VH.BTN_HOVER
local THEME_TEXT       = _G.VH.THEME_TEXT
local SEP_COLOR        = _G.VH.SEP_COLOR
local SECTION_TEXT     = _G.VH.SECTION_TEXT
local SW_ON            = _G.VH.SW_ON
local SW_OFF           = _G.VH.SW_OFF
local SW_KNOB_ON       = _G.VH.SW_KNOB_ON
local SW_KNOB_OFF      = _G.VH.SW_KNOB_OFF
local PB_BAR           = _G.VH.PB_BAR
local PB_TEXT          = _G.VH.PB_TEXT

local Lighting = game:GetService("Lighting")
local camera   = workspace.CurrentCamera
local mouse    = player:GetMouse()

-- ════════════════════════════════════════════════════
-- PIXEL ART THEME CONSTANTS
-- ════════════════════════════════════════════════════
local C = {
    CARD       = Color3.fromRGB(10,  10,  10),
    ROW        = Color3.fromRGB(16,  16,  16),
    TRACK      = Color3.fromRGB(38,  38,  38),
    BORDER     = Color3.fromRGB(55,  55,  55),
    TEXT       = Color3.fromRGB(210, 210, 210),
    TEXT_DIM   = Color3.fromRGB(100, 100, 100),
    BTN        = Color3.fromRGB(14,  14,  14),
    BTN_HV     = Color3.fromRGB(32,  32,  32),
    BTN_DANGER = Color3.fromRGB(18,  10,  10),
    FILL       = Color3.fromRGB(200, 200, 200),
    SW_ON      = Color3.fromRGB(220, 220, 220),
    SW_OFF     = Color3.fromRGB(50,  50,  50),
    KNOB_ON    = Color3.fromRGB(30,  30,  30),
    KNOB_OFF   = Color3.fromRGB(160, 160, 160),
}

-- ════════════════════════════════════════════════════
-- ── PLAYER TAB ──────────────────────────────────────
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

local function createPButton(text, cb)
    local btn = Instance.new("TextButton", playerPage)
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = BTN_COLOR; btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = THEME_TEXT; btn.Text = text; btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", btn)
    s.Color = Color3.fromRGB(55, 55, 55); s.Thickness = 1; s.Transparency = 0
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_HOVER}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_COLOR}):Play() end)
    if cb then btn.MouseButton1Click:Connect(function() task.spawn(cb) end) end
    return btn
end

local savedWalkSpeed = 16
local savedJumpPower = 50

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
    frame.Size = UDim2.new(1, 0, 0, 54); frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 0; Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local topRow = Instance.new("Frame", frame)
    topRow.Size = UDim2.new(1, -16, 0, 22); topRow.Position = UDim2.new(0, 8, 0, 7); topRow.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", topRow)
    lbl.Size = UDim2.new(0.72, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = labelText
    local valLbl = Instance.new("TextLabel", topRow)
    valLbl.Size = UDim2.new(0.28, 0, 1, 0); valLbl.Position = UDim2.new(0.72, 0, 0, 0)
    valLbl.BackgroundTransparency = 1; valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 13
    valLbl.TextColor3 = PB_TEXT; valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.Text = tostring(defaultVal)
    local track = Instance.new("Frame", frame)
    track.Size = UDim2.new(1, -16, 0, 5); track.Position = UDim2.new(0, 8, 0, 38)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 40); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = PB_BAR; fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0, 14, 0, 14); knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255); knob.Text = ""; knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local ds = false
    local function upd(absX)
        local r = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.round(minVal + r * (maxVal - minVal))
        fill.Size = UDim2.new(r, 0, 1, 0); knob.Position = UDim2.new(r, 0, 0.5, 0); valLbl.Text = tostring(v)
        if onChanged then onChanged(v) end
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

local function createPToggle(text, defaultState, callback)
    local frame = Instance.new("Frame", playerPage)
    frame.Size = UDim2.new(1, 0, 0, 36); frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 0; Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -54, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0); lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local tb = Instance.new("TextButton", frame)
    tb.Size = UDim2.new(0, 36, 0, 20); tb.Position = UDim2.new(1, -46, 0.5, -10)
    tb.BackgroundColor3 = defaultState and SW_ON or SW_OFF
    tb.Text = ""; tb.BorderSizePixel = 0; Instance.new("UICorner", tb).CornerRadius = UDim.new(1, 0)
    local circle = Instance.new("Frame", tb)
    circle.Size = UDim2.new(0, 14, 0, 14); circle.Position = UDim2.new(0, defaultState and 20 or 2, 0.5, -7)
    circle.BackgroundColor3 = defaultState and SW_KNOB_ON or SW_KNOB_OFF; circle.BorderSizePixel = 0
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    local toggled = defaultState
    if callback then callback(toggled) end
    local function setToggled(val)
        toggled = val
        TweenService:Create(tb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = toggled and SW_ON or SW_OFF}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, toggled and 20 or 2, 0.5, -7),
            BackgroundColor3 = toggled and SW_KNOB_ON or SW_KNOB_OFF
        }):Play()
    end
    tb.MouseButton1Click:Connect(function()
        toggled = not toggled; setToggled(toggled)
        if callback then callback(toggled) end
    end)
    return frame, setToggled, function() return toggled end
end

-- ── Movement ──
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

-- ── Fly ──
local flySpeed    = 100
local flyEnabled  = true
local isFlyActive = false
local flyBV, flyBG, flyConn
local currentFlyKey = Enum.KeyCode.Q

local function stopFly()
    isFlyActive = false
    if _G.VH then _G.VH.isFlyActive = false end
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    pcall(function()
        if flyBV and flyBV.Parent then
            flyBV.Velocity = Vector3.zero
            flyBV.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        end
        if flyBG and flyBG.Parent then
            local _, camYaw, _ = workspace.CurrentCamera.CFrame:ToEulerAnglesYXZ()
            flyBG.CFrame    = CFrame.Angles(0, camYaw, 0)
            flyBG.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        end
    end)
    task.wait(0.07)
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
        local ch = player.Character; if not ch then stopFly(); return end
        local h  = ch:FindFirstChild("Humanoid"); if not h then stopFly(); return end
        local r  = ch:FindFirstChild("HumanoidRootPart"); if not r then stopFly(); return end
        local cf = workspace.CurrentCamera.CFrame

        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end

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

-- Fly hotkey picker
local flyKeyFrame = Instance.new("Frame", playerPage)
flyKeyFrame.Size = UDim2.new(1, 0, 0, 36)
flyKeyFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20); flyKeyFrame.BorderSizePixel = 0
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
local btnStr_flyKeyBtn = Instance.new("UIStroke", flyKeyBtn)
btnStr_flyKeyBtn.Color = Color3.fromRGB(55, 55, 55); btnStr_flyKeyBtn.Thickness = 1; btnStr_flyKeyBtn.Transparency = 0
flyKeyBtn.MouseEnter:Connect(function() TweenService:Create(flyKeyBtn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_HOVER}):Play() end)
flyKeyBtn.MouseLeave:Connect(function() TweenService:Create(flyKeyBtn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_COLOR}):Play() end)

local waitingForFlyKey = false
flyKeyBtn.MouseButton1Click:Connect(function()
    if waitingForFlyKey then return end
    waitingForFlyKey = true
    flyKeyBtn.Text = "..."
    flyKeyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
end)

-- Fly toggle switch
local flyToggleFrame = Instance.new("Frame", playerPage)
flyToggleFrame.Size = UDim2.new(1, 0, 0, 36)
flyToggleFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20); flyToggleFrame.BorderSizePixel = 0
Instance.new("UICorner", flyToggleFrame).CornerRadius = UDim.new(0, 8)
local flyToggleLbl = Instance.new("TextLabel", flyToggleFrame)
flyToggleLbl.Size = UDim2.new(1, -54, 1, 0); flyToggleLbl.Position = UDim2.new(0, 12, 0, 0)
flyToggleLbl.BackgroundTransparency = 1; flyToggleLbl.Font = Enum.Font.GothamSemibold; flyToggleLbl.TextSize = 13
flyToggleLbl.TextColor3 = THEME_TEXT; flyToggleLbl.TextXAlignment = Enum.TextXAlignment.Left
flyToggleLbl.Text = "Fly"
local flyToggleTb = Instance.new("TextButton", flyToggleFrame)
flyToggleTb.Size = UDim2.new(0, 36, 0, 20); flyToggleTb.Position = UDim2.new(1, -46, 0.5, -10)
flyToggleTb.BackgroundColor3 = SW_ON
flyToggleTb.Text = ""; flyToggleTb.BorderSizePixel = 0
Instance.new("UICorner", flyToggleTb).CornerRadius = UDim.new(1, 0)
local flyToggleCircle = Instance.new("Frame", flyToggleTb)
flyToggleCircle.Size = UDim2.new(0, 14, 0, 14)
flyToggleCircle.Position = UDim2.new(0, 20, 0.5, -7)
flyToggleCircle.BackgroundColor3 = SW_KNOB_ON; flyToggleCircle.BorderSizePixel = 0
Instance.new("UICorner", flyToggleCircle).CornerRadius = UDim.new(1, 0)
flyToggleTb.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    TweenService:Create(flyToggleTb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
        BackgroundColor3 = flyEnabled and SW_ON or SW_OFF
    }):Play()
    TweenService:Create(flyToggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
        Position = UDim2.new(0, flyEnabled and 20 or 2, 0.5, -7),
        BackgroundColor3 = flyEnabled and SW_KNOB_ON or SW_KNOB_OFF
    }):Play()
    if not flyEnabled and isFlyActive then stopFly() end
end)

-- ── Character ──
createPSep()
createPSection("Character")

local noclipEnabled = false
local noclipConn
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

local infJumpEnabled = false
local infJumpConn
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

-- ── Misc ──
createPSep()
createPSection("Misc")

local hardDragEnabled = false
local draggerConn

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
                    bp.P = 120000; bp.D = 1000
                    bp.maxForce  = Vector3.new(math.huge, math.huge, math.huge)
                    bg.maxTorque = Vector3.new(math.huge, math.huge, math.huge)
                else
                    bp.P = 10000; bp.D = 800
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
            if bp then bp.P = 10000; bp.D = 800; bp.maxForce = Vector3.new(17000, 17000, 17000) end
            if bg then bg.maxTorque = Vector3.new(200, 200, 200) end
        end
    end
end)

table.insert(cleanupTasks, stopHardDrag)

-- ════════════════════════════════════════════════════
-- BTOOLS
-- ════════════════════════════════════════════════════
local btoolsEditedParts = {}
local btoolsParentFix   = {}
local btoolsPosFix      = {}

local function giveBtools()
    local backpack = player.Backpack
    -- Remove any existing btools first so we don't stack them
    for _, t in pairs(backpack:GetChildren()) do
        if t.Name == "Delete" or t.Name == "Undo" then t:Destroy() end
    end
    if player.Character then
        for _, t in pairs(player.Character:GetChildren()) do
            if t.Name == "Delete" or t.Name == "Undo" then t:Destroy() end
        end
    end

    local deleteTool = Instance.new("Tool", backpack)
    deleteTool.Name           = "Delete"
    deleteTool.CanBeDropped   = false
    deleteTool.RequiresHandle = false

    local undoTool = Instance.new("Tool", backpack)
    undoTool.Name           = "Undo"
    undoTool.CanBeDropped   = false
    undoTool.RequiresHandle = false

    deleteTool.Activated:Connect(function()
        local target = mouse.Target
        if not target then return end
        table.insert(btoolsEditedParts, target)
        table.insert(btoolsParentFix,   target.Parent)
        table.insert(btoolsPosFix,      target.CFrame)
        target.Parent = nil
    end)

    undoTool.Activated:Connect(function()
        if #btoolsEditedParts == 0 then return end
        local n = #btoolsEditedParts
        pcall(function()
            btoolsEditedParts[n].Parent = btoolsParentFix[n]
            btoolsEditedParts[n].CFrame = btoolsPosFix[n]
        end)
        table.remove(btoolsEditedParts, n)
        table.remove(btoolsParentFix,   n)
        table.remove(btoolsPosFix,      n)
    end)
end

local function removeBtools()
    local backpack = player.Backpack
    for _, t in pairs(backpack:GetChildren()) do
        if t.Name == "Delete" or t.Name == "Undo" then t:Destroy() end
    end
    if player.Character then
        for _, t in pairs(player.Character:GetChildren()) do
            if t.Name == "Delete" or t.Name == "Undo" then t:Destroy() end
        end
    end
    btoolsEditedParts = {}
    btoolsParentFix   = {}
    btoolsPosFix      = {}
end

createPToggle("BTools", false, function(val)
    if val then
        giveBtools()
    else
        removeBtools()
    end
end)

table.insert(cleanupTasks, removeBtools)

-- ════════════════════════════════════════════════════
-- HEADLIGHT
-- ════════════════════════════════════════════════════
local headlightOn = false

local function setHeadlight(enabled)
    local char = player.Character
    local head = char and char:FindFirstChild("Head")
    if not head then return end
    -- Remove any existing light first
    local existing = head:FindFirstChildOfClass("PointLight")
    if existing then existing:Destroy() end
    if enabled then
        local light = Instance.new("PointLight", head)
        light.Range      = 60
        light.Brightness = 2
        light.Shadows    = false
    end
end

-- Re-apply headlight on respawn
player.CharacterAdded:Connect(function()
    if headlightOn then
        task.wait(1)
        setHeadlight(true)
    end
end)

createPToggle("Headlight", false, function(val)
    headlightOn = val
    setHeadlight(val)
end)

table.insert(cleanupTasks, function()
    headlightOn = false
    setHeadlight(false)
end)

-- ── Fly key listener (lives here since fly is in this file) ──
local flyKeyConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
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
    if input.KeyCode == currentFlyKey then
        if not flyEnabled then
            if isFlyActive then stopFly() end
            return
        end
        if isFlyActive then stopFly() else startFly() end
    end
end)
table.insert(cleanupTasks, function()
    if flyKeyConn then flyKeyConn:Disconnect(); flyKeyConn = nil end
end)

-- Push fly refs into _G.VH so other modules can read state
_G.VH.stopFly        = stopFly
_G.VH.startFly       = startFly
_G.VH.flyKeyBtn      = flyKeyBtn
_G.VH.currentFlyKey  = currentFlyKey

-- ════════════════════════════════════════════════════
-- ── WORLD TAB ───────────────────────────────────────
-- ════════════════════════════════════════════════════
local worldPage = pages["WorldTab"]

local origClockTime = Lighting.ClockTime
local origShadows   = Lighting.GlobalShadows

-- LT2 neutral fog values (replace the blue game fog on load)
local LT2_FOG_END   = 10000
local LT2_FOG_START = 0
local LT2_FOG_COLOR = Color3.fromRGB(200, 200, 200)

Lighting.FogColor = LT2_FOG_COLOR
Lighting.FogEnd   = LT2_FOG_END
Lighting.FogStart = LT2_FOG_START

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
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20); frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -54, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = labelText
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local tb = Instance.new("TextButton", frame)
    tb.Size = UDim2.new(0, 36, 0, 20); tb.Position = UDim2.new(1, -46, 0.5, -10)
    tb.BackgroundColor3 = default and SW_ON or SW_OFF
    tb.Text = ""; tb.BorderSizePixel = 0
    Instance.new("UICorner", tb).CornerRadius = UDim.new(1, 0)
    local circle = Instance.new("Frame", tb)
    circle.Size = UDim2.new(0, 14, 0, 14)
    circle.Position = UDim2.new(0, default and 20 or 2, 0.5, -7)
    circle.BackgroundColor3 = default and SW_KNOB_ON or SW_KNOB_OFF
    circle.BorderSizePixel = 0
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    local toggled = default
    local function setState(val)
        toggled = val
        TweenService:Create(tb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            BackgroundColor3 = val and SW_ON or SW_OFF
        }):Play()
        TweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, val and 20 or 2, 0.5, -7),
            BackgroundColor3 = val and SW_KNOB_ON or SW_KNOB_OFF
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

-- Start with always day active
stopDayNight()
Lighting.ClockTime = 14
dayConn = RunService.Heartbeat:Connect(function() Lighting.ClockTime = 14 end)

-- ════════════════════════════════════════════════════
-- REMOVE FOG
-- Uses Lighting.Changed to lock fog out — the game's
-- own lighting scripts can't push it back.
-- ════════════════════════════════════════════════════
makeWorldToggle("Remove Fog", false, function(v)
    if fogConn then fogConn:Disconnect(); fogConn = nil end
    if v then
        Lighting.FogEnd   = 1e9
        Lighting.FogStart = 1e9
        -- Re-lock every time LT2's lighting system tries to change it
        fogConn = Lighting.Changed:Connect(function()
            if Lighting.FogEnd ~= 1e9 then
                Lighting.FogEnd   = 1e9
                Lighting.FogStart = 1e9
            end
        end)
    else
        -- Restore neutral LT2 fog (no blue game fog)
        Lighting.FogEnd   = LT2_FOG_END
        Lighting.FogStart = LT2_FOG_START
        Lighting.FogColor = LT2_FOG_COLOR
    end
end)

-- ════════════════════════════════════════════════════
-- SHADOWS
-- ════════════════════════════════════════════════════
makeWorldToggle("Shadows", true, function(v)
    Lighting.GlobalShadows = v
end)

makeWorldSep()
makeWorldSectionLabel("Water")

-- ════════════════════════════════════════════════════
-- WALK ON WATER
-- Directly sets CanCollide on the Water parts inside
-- workspace.Water — the same approach as VanillaHub.
-- Also watches for new parts added at runtime.
-- ════════════════════════════════════════════════════
local walkOnWaterConn = nil

local function removeWalkWater()
    if walkOnWaterConn then walkOnWaterConn:Disconnect(); walkOnWaterConn = nil end
    -- Restore CanCollide = false on all water parts
    pcall(function()
        for _, part in next, workspace.Water:GetChildren() do
            if part.Name == "Water" then
                part.CanCollide = false
            end
        end
    end)
    -- Also remove any clone planes from the old system
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "WalkWaterPlane" then obj:Destroy() end
    end
end

makeWorldToggle("Walk On Water", false, function(v)
    removeWalkWater()
    if v then
        pcall(function()
            for _, part in next, workspace.Water:GetChildren() do
                if part.Name == "Water" then
                    part.CanCollide = true
                end
            end
        end)
        -- Watch for any new water parts added at runtime
        pcall(function()
            walkOnWaterConn = workspace.Water.ChildAdded:Connect(function(part)
                if part.Name == "Water" then
                    part.CanCollide = true
                end
            end)
        end)
    end
end)

-- ════════════════════════════════════════════════════
-- REMOVE WATER
-- Hides/shows the Water parts by setting transparency.
-- ════════════════════════════════════════════════════
makeWorldToggle("Remove Water", false, function(v)
    pcall(function()
        for _, part in next, workspace.Water:GetChildren() do
            if part.Name == "Water" then
                part.Transparency = v and 1 or 0.5
                part.CanCollide   = false  -- ensure we don't ghost-collide invisible water
            end
        end
    end)
end)

makeWorldSep()
makeWorldSectionLabel("World")

-- ════════════════════════════════════════════════════
-- LOWER BRIDGE
-- Moves every part inside workspace.Bridge.VerticalLiftBridge.Lift
-- down 26 studs on enable, restores on disable.
-- ════════════════════════════════════════════════════
local bridgeLowered = false

local function setBridge(lower)
    pcall(function()
        local lift = workspace.Bridge.VerticalLiftBridge.Lift
        for _, v in next, lift:GetChildren() do
            if v:IsA("BasePart") then
                v.CFrame = v.CFrame + Vector3.new(0, lower and -0.1 or 0.1, 0)
            end
        end
    end)
end

makeWorldToggle("Lower Bridge", false, function(v)
    if v == bridgeLowered then return end
    setBridge(v)
    bridgeLowered = v
end)

table.insert(cleanupTasks, function()
    if bridgeLowered then
        setBridge(false)
        bridgeLowered = false
    end
end)

table.insert(cleanupTasks, function()
    stopDayNight()
    if fogConn then fogConn:Disconnect(); fogConn = nil end
    removeWalkWater()
    Lighting.ClockTime     = origClockTime
    Lighting.FogEnd        = LT2_FOG_END
    Lighting.FogStart      = LT2_FOG_START
    Lighting.FogColor      = LT2_FOG_COLOR
    Lighting.GlobalShadows = origShadows
end)

-- ════════════════════════════════════════════════════
-- ── PIXEL ART TAB ───────────────────────────────────
-- ════════════════════════════════════════════════════
local cfg = {
    moveStep       = 1,
    rotStep        = 90,
    followingMouse = false,
}

local function getBuilds()
    local folder = workspace:FindFirstChild("Builds")
    if not folder then return {} end
    local out = {}
    for _, m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") then
            if not m.PrimaryPart then
                m.PrimaryPart = m:FindFirstChildWhichIsA("BasePart")
            end
            if m.PrimaryPart then table.insert(out, m) end
        end
    end
    return out
end

local function getPivot(models)
    local sum, n = Vector3.zero, 0
    for _, m in ipairs(models) do sum = sum + m.PrimaryPart.Position; n = n + 1 end
    return n > 0 and CFrame.new(sum / n) or CFrame.new()
end

local function snap(x, s)  return math.round(x / s) * s end
local function snapV3(v, s) return Vector3.new(snap(v.X, s), snap(v.Y, s), snap(v.Z, s)) end

local function moveModels(delta)
    for _, m in ipairs(getBuilds()) do
        m:SetPrimaryPartCFrame(m.PrimaryPart.CFrame + delta)
    end
end

local function rotateModels(axis, deg)
    local models = getBuilds()
    if #models == 0 then return end
    local pivot = getPivot(models)
    local rot = CFrame.Angles(
        axis.X * math.rad(deg),
        axis.Y * math.rad(deg),
        axis.Z * math.rad(deg)
    )
    for _, m in ipairs(models) do
        local rel = pivot:ToObjectSpace(m.PrimaryPart.CFrame)
        m:SetPrimaryPartCFrame(pivot * rot * rel)
    end
end

local function setPosition(pos)
    local models = getBuilds()
    if #models == 0 then return end
    local diff = pos - getPivot(models).Position
    for _, m in ipairs(models) do
        m:SetPrimaryPartCFrame(m.PrimaryPart.CFrame + diff)
    end
end

local function snapToGrid()
    for _, m in ipairs(getBuilds()) do
        local snapped = snapV3(m.PrimaryPart.Position, cfg.moveStep)
        m:SetPrimaryPartCFrame(CFrame.new(snapped) * m.PrimaryPart.CFrame.Rotation)
    end
end

local function nudge(rawDir)
    local _, yaw, _ = camera.CFrame:ToEulerAnglesYXZ()
    local camRel = CFrame.Angles(0, yaw, 0) * rawDir * cfg.moveStep
    local function toAxis(v)
        if math.abs(v.X) > math.abs(v.Z) then
            return Vector3.new(math.sign(v.X), 0, 0)
        else
            return Vector3.new(0, 0, math.sign(v.Z))
        end
    end
    local effective
    if rawDir.Y ~= 0 then
        effective = Vector3.new(0, math.sign(rawDir.Y), 0) * cfg.moveStep
    else
        effective = toAxis(camRel) * cfg.moveStep
    end
    moveModels(effective)
end

local function centerOnPlot()
    local ray = mouse.UnitRay
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local excl = {}
    for _, m in ipairs(getBuilds()) do table.insert(excl, m) end
    if player.Character then table.insert(excl, player.Character) end
    params.FilterDescendantsInstances = excl
    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    if not (result and result.Instance) then return end
    local properties = workspace:FindFirstChild("Properties")
    if not properties then return end
    for _, plot in ipairs(properties:GetChildren()) do
        if result.Instance:IsDescendantOf(plot) then
            local floorY = math.huge
            local cSum, cCnt = Vector3.zero, 0
            for _, part in ipairs(plot:GetDescendants()) do
                if part:IsA("BasePart") then
                    floorY = math.min(floorY, part.Position.Y - part.Size.Y / 2)
                    cSum = cSum + part.Position; cCnt = cCnt + 1
                end
            end
            local pp = plot.PrimaryPart
            local plotCenterPos = (pp and pp.Position) or (cCnt > 0 and cSum / cCnt) or nil
            if not plotCenterPos then return end
            local models = getBuilds()
            if #models == 0 then return end
            local pivot = getPivot(models)
            local minY = math.huge
            for _, m in ipairs(models) do
                minY = math.min(minY, m.PrimaryPart.Position.Y - m.PrimaryPart.Size.Y / 2)
            end
            moveModels(Vector3.new(
                plotCenterPos.X - pivot.Position.X,
                (floorY - minY) + 0.05,
                plotCenterPos.Z - pivot.Position.Z
            ))
            return
        end
    end
end

local followConn

local function startFollow()
    if followConn then return end
    followConn = RunService.RenderStepped:Connect(function()
        if not cfg.followingMouse then return end
        local ray = mouse.UnitRay
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local excl = {}
        for _, m in ipairs(getBuilds()) do table.insert(excl, m) end
        if player.Character then table.insert(excl, player.Character) end
        params.FilterDescendantsInstances = excl
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        if not result then return end
        local targetPos = result.Position + result.Normal * (cfg.moveStep * 0.5)
        setPosition(snapV3(targetPos, cfg.moveStep))
    end)
end

local function stopFollow()
    cfg.followingMouse = false
    if followConn then followConn:Disconnect(); followConn = nil end
end

startFollow()
table.insert(cleanupTasks, stopFollow)

local paInputConn = UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    local paPage = pages["Pixel ArtTab"]
    if not (paPage and paPage.Visible) then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local k = input.KeyCode
    if     k == Enum.KeyCode.Up       then nudge(Vector3.new( 0, 0,-1))
    elseif k == Enum.KeyCode.Down     then nudge(Vector3.new( 0, 0, 1))
    elseif k == Enum.KeyCode.Left     then nudge(Vector3.new(-1, 0, 0))
    elseif k == Enum.KeyCode.Right    then nudge(Vector3.new( 1, 0, 0))
    elseif k == Enum.KeyCode.PageUp   then nudge(Vector3.new( 0, 1, 0))
    elseif k == Enum.KeyCode.PageDown then nudge(Vector3.new( 0,-1, 0))
    elseif k == Enum.KeyCode.R        then rotateModels(Vector3.new(0,1,0),  cfg.rotStep)
    elseif k == Enum.KeyCode.T        then rotateModels(Vector3.new(0,1,0), -cfg.rotStep)
    elseif k == Enum.KeyCode.F        then rotateModels(Vector3.new(1,0,0),  cfg.rotStep)
    elseif k == Enum.KeyCode.G        then rotateModels(Vector3.new(1,0,0), -cfg.rotStep)
    end
end)
table.insert(cleanupTasks, function()
    if paInputConn then paInputConn:Disconnect(); paInputConn = nil end
end)

local paPage = pages["Pixel ArtTab"]

local function mkLabel(text)
    local lbl = Instance.new("TextLabel", paPage)
    lbl.Size = UDim2.new(1, -12, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
    lbl.TextColor3 = C.TEXT_DIM
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 4)
end

local function mkSep()
    local s = Instance.new("Frame", paPage)
    s.Size = UDim2.new(1, -12, 0, 1)
    s.BackgroundColor3 = C.BORDER; s.BorderSizePixel = 0
end

local function mkBtn(text, color, callback)
    color = color or C.BTN
    local btn = Instance.new("TextButton", paPage)
    btn.Size = UDim2.new(1, -12, 0, 32)
    btn.BackgroundColor3 = color
    btn.Text = text; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = C.TEXT; btn.BorderSizePixel = 0; btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", btn)
    s.Color = Color3.fromRGB(55, 55, 55); s.Thickness = 1; s.Transparency = 0
    local r = math.min(color.R * 255 + 20, 255) / 255
    local g = math.min(color.G * 255 + 20, 255) / 255
    local b = math.min(color.B * 255 + 20, 255) / 255
    local hov = Color3.new(r, g, b)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = hov}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = color}):Play() end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function mkBtnRow(textL, textR, cbL, cbR)
    local row = Instance.new("Frame", paPage)
    row.Size = UDim2.new(1, -12, 0, 32); row.BackgroundTransparency = 1
    local function half(text, posX, offsetX, cb)
        local b = Instance.new("TextButton", row)
        b.Size = UDim2.new(0.5, -4, 1, 0)
        b.Position = UDim2.new(posX, offsetX, 0, 0)
        b.BackgroundColor3 = C.BTN; b.Text = text
        b.Font = Enum.Font.GothamSemibold; b.TextSize = 12
        b.TextColor3 = C.TEXT; b.BorderSizePixel = 0; b.AutoButtonColor = false
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        local _s = Instance.new("UIStroke", b)
        _s.Color = Color3.fromRGB(55, 55, 55); _s.Thickness = 1; _s.Transparency = 0
        b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN_HV}):Play() end)
        b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN}):Play() end)
        b.MouseButton1Click:Connect(cb)
        return b
    end
    half(textL, 0,   0, cbL)
    half(textR, 0.5, 4, cbR)
    return row
end

local function mkToggle(text, default, callback)
    local frame = Instance.new("Frame", paPage)
    frame.Size = UDim2.new(1, -12, 0, 32)
    frame.BackgroundColor3 = C.CARD
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -50, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = text
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = C.TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local tb = Instance.new("TextButton", frame)
    tb.Size = UDim2.new(0, 34, 0, 18); tb.Position = UDim2.new(1, -44, 0.5, -9)
    tb.BackgroundColor3 = default and C.SW_ON or C.SW_OFF
    tb.Text = ""; tb.AutoButtonColor = false
    Instance.new("UICorner", tb).CornerRadius = UDim.new(1, 0)
    local dot = Instance.new("Frame", tb)
    dot.Size = UDim2.new(0, 14, 0, 14)
    dot.Position = UDim2.new(0, default and 18 or 2, 0.5, -7)
    dot.BackgroundColor3 = default and C.KNOB_ON or C.KNOB_OFF
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local on = default
    if callback then callback(on) end
    local function setOn(v)
        on = v
        TweenService:Create(tb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            BackgroundColor3 = v and C.SW_ON or C.SW_OFF
        }):Play()
        TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, v and 18 or 2, 0.5, -7),
            BackgroundColor3 = v and C.KNOB_ON or C.KNOB_OFF
        }):Play()
    end
    tb.MouseButton1Click:Connect(function()
        on = not on; setOn(on)
        if callback then callback(on) end
    end)
    return frame, setOn, function() return on end
end

local function mkSlider(label, minV, maxV, defaultV, cb)
    local fr = Instance.new("Frame", paPage)
    fr.Size = UDim2.new(1, -12, 0, 52)
    fr.BackgroundColor3 = C.CARD; fr.BorderSizePixel = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 6)
    local topRow = Instance.new("Frame", fr)
    topRow.Size = UDim2.new(1, -16, 0, 22); topRow.Position = UDim2.new(0, 8, 0, 6)
    topRow.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", topRow)
    lbl.Size = UDim2.new(0.7, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = C.TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = label
    local valLbl = Instance.new("TextLabel", topRow)
    valLbl.Size = UDim2.new(0.3, 0, 1, 0); valLbl.Position = UDim2.new(0.7, 0, 0, 0)
    valLbl.BackgroundTransparency = 1; valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 13
    valLbl.TextColor3 = C.FILL; valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Text = tostring(defaultV)
    local track = Instance.new("Frame", fr)
    track.Size = UDim2.new(1, -16, 0, 6); track.Position = UDim2.new(0, 8, 0, 36)
    track.BackgroundColor3 = C.TRACK; track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((defaultV - minV) / (maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = C.FILL; fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0, 16, 0, 16); knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((defaultV - minV) / (maxV - minV), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Text = ""; knob.BorderSizePixel = 0; knob.AutoButtonColor = false
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local dragging = false; local cur = defaultV
    local function apply(screenX)
        local ratio = math.clamp(
            (screenX - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local val = math.max(1, math.round(minV + ratio * (maxV - minV)))
        if val == cur then return end
        cur = val
        fill.Size = UDim2.new(ratio, 0, 1, 0); knob.Position = UDim2.new(ratio, 0, 0.5, 0)
        valLbl.Text = tostring(val)
        if cb then cb(val) end
    end
    knob.MouseButton1Down:Connect(function() dragging = true end)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; apply(inp.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then apply(inp.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    return fr
end

local function mkHint(text)
    local fr = Instance.new("Frame", paPage)
    fr.Size = UDim2.new(1, -12, 0, 28)
    fr.BackgroundColor3 = C.CARD; fr.BorderSizePixel = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel", fr)
    lbl.Size = UDim2.new(1, -12, 1, 0); lbl.Position = UDim2.new(0, 6, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11
    lbl.TextColor3 = C.TEXT_DIM; lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = text
end

-- Build Pixel Art UI
mkLabel("Grid Settings")
mkSlider("Grid Size (studs)", 1, 20, 1, function(v) cfg.moveStep = v end)
mkSlider("Rotation Step (deg)", 15, 180, 90, function(v) cfg.rotStep = v end)

mkSep()
mkLabel("Placement")

local _, setFollowToggle = mkToggle("Follow Mouse", false, function(v)
    cfg.followingMouse = v
    if v then startFollow() end
end)

mkHint("Click anywhere in-world while following to place and lock.")

mkSep()
mkLabel("Move  (Arrow Keys / PgUp / PgDn)")

mkBtnRow("Left",    "Right",
    function() nudge(Vector3.new(-1, 0, 0)) end,
    function() nudge(Vector3.new( 1, 0, 0)) end)
mkBtnRow("Forward", "Back",
    function() nudge(Vector3.new(0, 0,-1)) end,
    function() nudge(Vector3.new(0, 0, 1)) end)
mkBtnRow("Up",      "Down",
    function() nudge(Vector3.new(0,  1, 0)) end,
    function() nudge(Vector3.new(0, -1, 0)) end)

mkSep()
mkLabel("Rotate  (R / T / F / G)")

mkBtnRow("Yaw Left (T)",  "Yaw Right (R)",
    function() rotateModels(Vector3.new(0,1,0), -cfg.rotStep) end,
    function() rotateModels(Vector3.new(0,1,0),  cfg.rotStep) end)
mkBtnRow("Pitch Up (F)",  "Pitch Down (G)",
    function() rotateModels(Vector3.new(1,0,0),  cfg.rotStep) end,
    function() rotateModels(Vector3.new(1,0,0), -cfg.rotStep) end)

mkSep()
mkLabel("Utilities")

mkBtn("Snap to Grid", C.BTN, function() snapToGrid() end)
mkBtn("Center on Plot  (aim at plot first)", C.BTN, function() centerOnPlot() end)

mkSep()
mkLabel("Remove")

mkHint("Removes all models inside workspace.Builds. Cannot be undone.")

mkBtn("Remove Pixel Art", C.BTN_DANGER, function()
    local folder = workspace:FindFirstChild("Builds")
    if not folder then return end
    for _, m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") then pcall(function() m:Destroy() end) end
    end
    cfg.followingMouse = false
    setFollowToggle(false)
end)

local clickStopConn = UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if cfg.followingMouse then
            cfg.followingMouse = false
            setFollowToggle(false)
        end
    end
end)
table.insert(cleanupTasks, function()
    if clickStopConn then clickStopConn:Disconnect(); clickStopConn = nil end
    stopFollow()
end)

print("[VanillaHub] Vanilla5 loaded — Player / World / Pixel Art tabs ready")
