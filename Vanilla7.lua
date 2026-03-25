-- VanillaHub | Vanilla7_Vehicle.lua
-- Vehicle (Section 1) + Spawner (Section 2) + Sorter Tab (Section 3).
-- Requires Vanilla1 (_G.VH) to already be loaded.

if not _G.VH then
    warn("[VanillaHub] Vanilla7: _G.VH not found. Load Vanilla1 first.")
    return
end

local VH             = _G.VH
local TS             = VH.TweenService
local TweenService   = TS
local UserInputService = VH.UserInputService or game:GetService("UserInputService")
local RunService     = VH.RunService or game:GetService("RunService")
local Players        = VH.Players
local LP             = Players.LocalPlayer
local player         = LP
local Mouse          = LP:GetMouse()
local mouse          = Mouse
local RS             = game:GetService("ReplicatedStorage")
local cleanupTasks   = VH.cleanupTasks
local pages          = VH.pages
local BTN_COLOR      = VH.BTN_COLOR or Color3.fromRGB(14, 14, 14)
local THEME_TEXT     = VH.THEME_TEXT or Color3.fromRGB(230, 206, 226)
local camera         = workspace.CurrentCamera

-- ════════════════════════════════════════════════════
-- SHARED COLOUR PALETTE  (Vehicle tab style)
-- ════════════════════════════════════════════════════

local C = {
    CARD       = Color3.fromRGB(10,  10,  10),
    ROW        = Color3.fromRGB(16,  16,  16),
    INPUT      = Color3.fromRGB(30,  30,  30),
    BORDER     = Color3.fromRGB(55,  55,  55),
    TEXT       = Color3.fromRGB(210, 210, 210),
    TEXT_MID   = Color3.fromRGB(150, 150, 150),
    TEXT_DIM   = Color3.fromRGB(90,  90,  90),
    BTN        = Color3.fromRGB(14,  14,  14),
    BTN_HV     = Color3.fromRGB(32,  32,  32),
    DOT_IDLE   = Color3.fromRGB(70,  70,  70),
    DOT_ACT    = Color3.fromRGB(200, 200, 200),
    TRACK      = Color3.fromRGB(35,  35,  35),
    FILL       = Color3.fromRGB(190, 190, 190),
    TOGGLE_ON  = Color3.fromRGB(200, 200, 200),
    TOGGLE_OFF = Color3.fromRGB(50,  50,  50),
}

-- ════════════════════════════════════════════════════
-- SHARED UI HELPERS  (Vehicle tab style)
-- ════════════════════════════════════════════════════

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
end

local function sectionLabel(page, text)
    local lbl = Instance.new("TextLabel", page)
    lbl.Size                   = UDim2.new(1, -12, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextSize               = 11
    lbl.TextColor3             = C.TEXT_DIM
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.Text                   = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 4)
end

local function makeButton(page, text, cb)
    local btn = Instance.new("TextButton", page)
    btn.Size             = UDim2.new(1, -12, 0, 34)
    btn.BackgroundColor3 = C.BTN
    btn.BorderSizePixel  = 0
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.TextColor3       = C.TEXT
    btn.Text             = text
    btn.AutoButtonColor  = false
    corner(btn, 6)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color        = C.BORDER
    stroke.Thickness    = 1
    stroke.Transparency = 0
    btn.MouseEnter:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN_HV}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN}):Play()
    end)
    btn.MouseButton1Click:Connect(function() task.spawn(cb) end)
    return btn
end

local function makeSlider(page, labelText, minVal, maxVal, defaultVal, cb)
    local TRACK_H  = 4
    local THUMB_SZ = 14
    local ROW_H    = 46

    local outer = Instance.new("Frame", page)
    outer.Size             = UDim2.new(1, -12, 0, ROW_H)
    outer.BackgroundColor3 = C.ROW
    outer.BorderSizePixel  = 0
    corner(outer, 8)
    local outerStroke = Instance.new("UIStroke", outer)
    outerStroke.Color        = C.BORDER
    outerStroke.Thickness    = 1
    outerStroke.Transparency = 0.4

    local lbl = Instance.new("TextLabel", outer)
    lbl.Size               = UDim2.new(0.55, 0, 0, 20)
    lbl.Position           = UDim2.new(0, 12, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 12
    lbl.TextColor3         = C.TEXT
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = labelText

    local valLbl = Instance.new("TextLabel", outer)
    valLbl.Size              = UDim2.new(0.4, -12, 0, 20)
    valLbl.Position          = UDim2.new(0.6, 0, 0, 4)
    valLbl.BackgroundTransparency = 1
    valLbl.Font              = Enum.Font.GothamSemibold
    valLbl.TextSize          = 12
    valLbl.TextColor3        = C.TEXT_MID
    valLbl.TextXAlignment    = Enum.TextXAlignment.Right
    valLbl.Text              = tostring(defaultVal)

    local trackOuter = Instance.new("Frame", outer)
    trackOuter.Size             = UDim2.new(1, -24, 0, TRACK_H)
    trackOuter.Position         = UDim2.new(0, 12, 1, -14)
    trackOuter.BackgroundColor3 = C.TRACK
    trackOuter.BorderSizePixel  = 0
    corner(trackOuter, 3)

    local fill = Instance.new("Frame", trackOuter)
    fill.Size             = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = C.FILL
    fill.BorderSizePixel  = 0
    corner(fill, 3)

    local thumb = Instance.new("Frame", trackOuter)
    thumb.Size             = UDim2.new(0, THUMB_SZ, 0, THUMB_SZ)
    thumb.Position         = UDim2.new(0, -THUMB_SZ/2, 0.5, -THUMB_SZ/2)
    thumb.BackgroundColor3 = C.TEXT
    thumb.BorderSizePixel  = 0
    corner(thumb, THUMB_SZ)

    local hitbox = Instance.new("TextButton", outer)
    hitbox.Size                   = UDim2.new(1, 0, 1, 0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text                   = ""
    hitbox.AutoButtonColor        = false
    hitbox.ZIndex                 = 5

    local currentVal = defaultVal
    local dragging   = false

    local function setValue(v)
        currentVal  = math.clamp(math.round(v), minVal, maxVal)
        local pct   = (currentVal - minVal) / (maxVal - minVal)
        fill.Size   = UDim2.new(pct, 0, 1, 0)
        thumb.Position = UDim2.new(pct, -THUMB_SZ/2, 0.5, -THUMB_SZ/2)
        valLbl.Text = tostring(currentVal)
        cb(currentVal)
    end

    local function updateFromInput(input)
        local relX = input.Position.X - trackOuter.AbsolutePosition.X
        local pct  = math.clamp(relX / trackOuter.AbsoluteSize.X, 0, 1)
        setValue(minVal + pct * (maxVal - minVal))
    end

    hitbox.MouseButton1Down:Connect(function()
        dragging = true
    end)
    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromInput(input)
        end
    end)
    hitbox.MouseButton1Down:Connect(function(_, input)
        updateFromInput(game:GetService("UserInputService"):GetMouseLocation() and
            {Position = game:GetService("UserInputService"):GetMouseLocation()} or input)
    end)

    setValue(defaultVal)
    return outer
end

local function makeToggle(page, labelText, defaultVal, cb)
    local ROW_H   = 40
    local TRACK_W = 38
    local TRACK_H = 20
    local KNOB_SZ = 14

    local outer = Instance.new("Frame", page)
    outer.Size             = UDim2.new(1, -12, 0, ROW_H)
    outer.BackgroundColor3 = C.ROW
    outer.BorderSizePixel  = 0
    corner(outer, 8)
    local outerStroke = Instance.new("UIStroke", outer)
    outerStroke.Color        = C.BORDER
    outerStroke.Thickness    = 1
    outerStroke.Transparency = 0.4

    local lbl = Instance.new("TextLabel", outer)
    lbl.Size               = UDim2.new(1, -(TRACK_W + 24), 1, 0)
    lbl.Position           = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 12
    lbl.TextColor3         = C.TEXT
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = labelText

    local track = Instance.new("Frame", outer)
    track.Size             = UDim2.new(0, TRACK_W, 0, TRACK_H)
    track.Position         = UDim2.new(1, -(TRACK_W + 10), 0.5, -TRACK_H/2)
    track.BackgroundColor3 = defaultVal and C.TOGGLE_ON or C.TOGGLE_OFF
    track.BorderSizePixel  = 0
    corner(track, TRACK_H)

    local knob = Instance.new("Frame", track)
    knob.Size             = UDim2.new(0, KNOB_SZ, 0, KNOB_SZ)
    knob.Position         = defaultVal
        and UDim2.new(1, -(KNOB_SZ + 3), 0.5, -KNOB_SZ/2)
        or  UDim2.new(0, 3, 0.5, -KNOB_SZ/2)
    knob.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    knob.BorderSizePixel  = 0
    corner(knob, KNOB_SZ)

    local hitbox = Instance.new("TextButton", outer)
    hitbox.Size                   = UDim2.new(1, 0, 1, 0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text                   = ""
    hitbox.AutoButtonColor        = false
    hitbox.ZIndex                 = 5

    local state = defaultVal
    hitbox.MouseButton1Click:Connect(function()
        state = not state
        TS:Create(track, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
            BackgroundColor3 = state and C.TOGGLE_ON or C.TOGGLE_OFF
        }):Play()
        TS:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
            Position = state
                and UDim2.new(1, -(KNOB_SZ + 3), 0.5, -KNOB_SZ/2)
                or  UDim2.new(0, 3, 0.5, -KNOB_SZ/2)
        }):Play()
        cb(state)
    end)

    return outer
end

local function makeFancyDropdown(page, labelText, getOptions, cb)
    local selected = ""
    local isOpen   = false
    local ITEM_H   = 34
    local MAX_SHOW = 5
    local HEADER_H = 40

    local outer = Instance.new("Frame", page)
    outer.Size             = UDim2.new(1, -12, 0, HEADER_H)
    outer.BackgroundColor3 = C.ROW
    outer.BorderSizePixel  = 0
    outer.ClipsDescendants = true
    corner(outer, 8)
    local outerStroke = Instance.new("UIStroke", outer)
    outerStroke.Color        = C.BORDER
    outerStroke.Thickness    = 1
    outerStroke.Transparency = 0.4

    local header = Instance.new("Frame", outer)
    header.Size                   = UDim2.new(1, 0, 0, HEADER_H)
    header.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", header)
    lbl.Size               = UDim2.new(0, 80, 1, 0)
    lbl.Position           = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = labelText
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 12
    lbl.TextColor3         = C.TEXT
    lbl.TextXAlignment     = Enum.TextXAlignment.Left

    local selFrame = Instance.new("Frame", header)
    selFrame.Size             = UDim2.new(1, -96, 0, 28)
    selFrame.Position         = UDim2.new(0, 90, 0.5, -14)
    selFrame.BackgroundColor3 = C.INPUT
    selFrame.BorderSizePixel  = 0
    corner(selFrame, 6)
    local sfStroke = Instance.new("UIStroke", selFrame)
    sfStroke.Color        = C.BORDER
    sfStroke.Thickness    = 1
    sfStroke.Transparency = 0.3

    local selLbl = Instance.new("TextLabel", selFrame)
    selLbl.Size           = UDim2.new(1, -36, 1, 0)
    selLbl.Position       = UDim2.new(0, 10, 0, 0)
    selLbl.BackgroundTransparency = 1
    selLbl.Text           = "Select..."
    selLbl.Font           = Enum.Font.GothamSemibold
    selLbl.TextSize       = 12
    selLbl.TextColor3     = C.TEXT_DIM
    selLbl.TextXAlignment = Enum.TextXAlignment.Left
    selLbl.TextTruncate   = Enum.TextTruncate.AtEnd

    local arrowLbl = Instance.new("TextLabel", selFrame)
    arrowLbl.Size           = UDim2.new(0, 22, 1, 0)
    arrowLbl.Position       = UDim2.new(1, -24, 0, 0)
    arrowLbl.BackgroundTransparency = 1
    arrowLbl.Text           = "▲"
    arrowLbl.Font           = Enum.Font.GothamBold
    arrowLbl.TextSize       = 14
    arrowLbl.TextColor3     = C.TEXT_MID
    arrowLbl.TextXAlignment = Enum.TextXAlignment.Center

    local headerBtn = Instance.new("TextButton", selFrame)
    headerBtn.Size                   = UDim2.new(1, 0, 1, 0)
    headerBtn.BackgroundTransparency = 1
    headerBtn.Text                   = ""
    headerBtn.AutoButtonColor        = false
    headerBtn.ZIndex                 = 5

    local divider = Instance.new("Frame", outer)
    divider.Size             = UDim2.new(1, -16, 0, 1)
    divider.Position         = UDim2.new(0, 8, 0, HEADER_H)
    divider.BackgroundColor3 = C.BORDER
    divider.BorderSizePixel  = 0
    divider.Visible          = false

    local listScroll = Instance.new("ScrollingFrame", outer)
    listScroll.Position               = UDim2.new(0, 0, 0, HEADER_H + 2)
    listScroll.Size                   = UDim2.new(1, 0, 0, 0)
    listScroll.BackgroundTransparency = 1
    listScroll.BorderSizePixel        = 0
    listScroll.ScrollBarThickness     = 3
    listScroll.ScrollBarImageColor3   = C.BORDER
    listScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
    listScroll.ClipsDescendants       = true

    local listLayout = Instance.new("UIListLayout", listScroll)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding   = UDim.new(0, 3)
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 6)
    end)
    local listPad = Instance.new("UIPadding", listScroll)
    listPad.PaddingTop    = UDim.new(0, 4)
    listPad.PaddingBottom = UDim.new(0, 4)
    listPad.PaddingLeft   = UDim.new(0, 6)
    listPad.PaddingRight  = UDim.new(0, 6)

    local function setSelected(name)
        selected          = name
        selLbl.Text       = name
        selLbl.TextColor3 = C.TEXT
        outerStroke.Color = C.BORDER
        cb(name)
    end

    local function buildList()
        for _, ch in ipairs(listScroll:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        local opts = getOptions()
        for _, opt in ipairs(opts) do
            local item = Instance.new("TextButton", listScroll)
            item.Size             = UDim2.new(1, 0, 0, ITEM_H)
            item.BackgroundColor3 = C.ROW
            item.Text             = ""
            item.BorderSizePixel  = 0
            item.AutoButtonColor  = false
            corner(item, 6)
            local iLbl = Instance.new("TextLabel", item)
            iLbl.Size               = UDim2.new(1, -16, 1, 0)
            iLbl.Position           = UDim2.new(0, 10, 0, 0)
            iLbl.BackgroundTransparency = 1
            iLbl.Text               = opt
            iLbl.Font               = Enum.Font.GothamSemibold
            iLbl.TextSize           = 12
            iLbl.TextColor3         = C.TEXT
            iLbl.TextXAlignment     = Enum.TextXAlignment.Left
            iLbl.TextTruncate       = Enum.TextTruncate.AtEnd
            item.MouseEnter:Connect(function()
                TS:Create(item, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
            end)
            item.MouseLeave:Connect(function()
                TS:Create(item, TweenInfo.new(0.1), {BackgroundColor3 = C.ROW}):Play()
            end)
            item.MouseButton1Click:Connect(function()
                setSelected(opt)
                isOpen = false
                TS:Create(arrowLbl,   TweenInfo.new(0.2,  Enum.EasingStyle.Quint), {Rotation = 0}):Play()
                TS:Create(outer,      TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1, -12, 0, HEADER_H)}):Play()
                TS:Create(listScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                divider.Visible = false
            end)
        end
        return #opts
    end

    local function openList()
        isOpen = true
        local count = buildList()
        local listH = math.min(count, MAX_SHOW) * (ITEM_H + 3) + 8
        divider.Visible = true
        TS:Create(arrowLbl,   TweenInfo.new(0.2,  Enum.EasingStyle.Quint), {Rotation = 180}):Play()
        TS:Create(outer,      TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(1, -12, 0, HEADER_H + 2 + listH)}):Play()
        TS:Create(listScroll, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, listH)}):Play()
    end
    local function closeList()
        isOpen = false
        TS:Create(arrowLbl,   TweenInfo.new(0.2,  Enum.EasingStyle.Quint), {Rotation = 0}):Play()
        TS:Create(outer,      TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1, -12, 0, HEADER_H)}):Play()
        TS:Create(listScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, 0)}):Play()
        divider.Visible = false
    end

    headerBtn.MouseButton1Click:Connect(function()
        if isOpen then closeList() else openList() end
    end)
    headerBtn.MouseEnter:Connect(function()
        TS:Create(selFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(42, 42, 42)}):Play()
    end)
    headerBtn.MouseLeave:Connect(function()
        TS:Create(selFrame, TweenInfo.new(0.12), {BackgroundColor3 = C.INPUT}):Play()
    end)

    return {
        GetSelected = function() return selected end,
        Refresh = function()
            if isOpen then
                local count = buildList()
                local listH = math.min(count, MAX_SHOW) * (ITEM_H + 3) + 8
                outer.Size      = UDim2.new(1, -12, 0, HEADER_H + 2 + listH)
                listScroll.Size = UDim2.new(1, 0, 0, listH)
            end
        end,
    }
end

local function makeStatus(page, initText)
    local f = Instance.new("Frame", page)
    f.Size             = UDim2.new(1, -12, 0, 28)
    f.BackgroundColor3 = C.CARD
    f.BorderSizePixel  = 0
    corner(f, 6)
    local stroke = Instance.new("UIStroke", f)
    stroke.Color        = C.BORDER
    stroke.Thickness    = 1
    stroke.Transparency = 0.4

    local dot = Instance.new("Frame", f)
    dot.Size             = UDim2.new(0, 7, 0, 7)
    dot.Position         = UDim2.new(0, 10, 0.5, -3)
    dot.BackgroundColor3 = C.DOT_IDLE
    dot.BorderSizePixel  = 0
    corner(dot, 4)

    local lb = Instance.new("TextLabel", f)
    lb.Size               = UDim2.new(1, -26, 1, 0)
    lb.Position           = UDim2.new(0, 22, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Font               = Enum.Font.Gotham
    lb.TextSize           = 12
    lb.TextColor3         = C.TEXT_MID
    lb.TextXAlignment     = Enum.TextXAlignment.Left
    lb.Text               = initText

    local resetThread = nil
    local function scheduleReset()
        if resetThread then task.cancel(resetThread); resetThread = nil end
        resetThread = task.delay(3, function()
            TS:Create(dot, TweenInfo.new(0.4), {BackgroundColor3 = C.DOT_IDLE}):Play()
            task.wait(0.4)
            lb.Text     = initText
            resetThread = nil
        end)
    end

    return {
        SetActive = function(on, msg)
            if resetThread then task.cancel(resetThread); resetThread = nil end
            TS:Create(dot, TweenInfo.new(0.2), {BackgroundColor3 = on and C.DOT_ACT or C.DOT_IDLE}):Play()
            if msg then lb.Text = msg end
            if not on then scheduleReset() end
        end,
        Reset = function()
            if resetThread then task.cancel(resetThread); resetThread = nil end
            TS:Create(dot, TweenInfo.new(0.3), {BackgroundColor3 = C.DOT_IDLE}):Play()
            lb.Text = initText
        end,
    }
end

-- ════════════════════════════════════════════════════
-- VEHICLE LOGIC
-- ════════════════════════════════════════════════════

local function vehicleSpeed(val)
    for _, v in next, workspace.PlayerModels:GetChildren() do
        if v:FindFirstChild("Owner") and v.Owner.Value == LP then
            if v:FindFirstChild("Type") and v.Type.Value == "Vehicle" then
                if v:FindFirstChild("Configuration") then
                    v.Configuration.MaxSpeed.Value = val
                end
            end
        end
    end
end

local function carTP(CFRAME)
    local char = LP.Character; if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    if hum.Seated then
        local seat = hum.SeatPart
        if seat and seat.Parent:FindFirstChild("Type") and seat.Parent.Type.Value == "Vehicle" then
            local car = seat.Parent
            seat.CFrame                 = CFRAME
            car.RightSteer.Wheel.CFrame = CFRAME
            car.LeftSteer.Wheel.CFrame  = CFRAME
            car.RightPower.Wheel.CFrame = CFRAME
            car.LeftPower.Wheel.CFrame  = CFRAME
        end
    end
end

local FLYING          = false
local vehicleflyspeed = 1
local flyKeyDown, flyKeyUp

local function sFLY()
    repeat task.wait() until LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    repeat task.wait() until Mouse

    if flyKeyDown or flyKeyUp then
        flyKeyDown:Disconnect()
        flyKeyUp:Disconnect()
    end

    local T    = LP.Character.HumanoidRootPart
    local keys = {w=false, s=false, a=false, d=false, e=false, q=false}

    local function FLY()
        FLYING = true
        local BG = Instance.new("BodyGyro")
        local BV = Instance.new("BodyVelocity")
        BG.P         = 9e4
        BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        BG.cframe    = T.CFrame
        BG.Parent    = T
        BV.velocity  = Vector3.new(0, 0, 0)
        BV.maxForce  = Vector3.new(9e9, 9e9, 9e9)
        BV.Parent    = T

        task.spawn(function()
            repeat
                task.wait()
                local spd = vehicleflyspeed
                local F   = (keys.w and spd or 0) + (keys.s and -spd or 0)
                local L   = (keys.a and -spd or 0) + (keys.d and spd or 0)
                local V   = (keys.e and spd*2 or 0) + (keys.q and -spd*2 or 0)
                local moving = F ~= 0 or L ~= 0 or V ~= 0
                if moving then
                    BV.velocity = (
                        (workspace.CurrentCamera.CoordinateFrame.lookVector * F)
                        + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(L, (F + V) * 0.2, 0).p)
                        - workspace.CurrentCamera.CoordinateFrame.p)
                    ) * 50
                else
                    BV.velocity = Vector3.new(0, 0, 0)
                end
                BG.cframe = workspace.CurrentCamera.CoordinateFrame
            until not FLYING
            keys = {w=false, s=false, a=false, d=false, e=false, q=false}
            BG:Destroy()
            BV:Destroy()
        end)
    end

    flyKeyDown = Mouse.KeyDown:Connect(function(key)
        key = key:lower()
        if keys[key] ~= nil then keys[key] = true end
        pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Track end)
    end)
    flyKeyUp = Mouse.KeyUp:Connect(function(key)
        key = key:lower()
        if keys[key] ~= nil then keys[key] = false end
    end)
    FLY()
end

local function NOFLY()
    FLYING = false
    if flyKeyDown then flyKeyDown:Disconnect(); flyKeyDown = nil end
    if flyKeyUp   then flyKeyUp:Disconnect();   flyKeyUp   = nil end
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
    pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end

-- ════════════════════════════════════════════════════
-- VEHICLE UI — Section 1
-- ════════════════════════════════════════════════════

local vh = pages["VehicleTab"]

sectionLabel(vh, "Vehicle")

makeSlider(vh, "Vehicle Speed", 1, 10, 1, function(val)
    vehicleSpeed(val)
end)

makeSlider(vh, "Fly Speed", 1, 250, 1, function(val)
    vehicleflyspeed = val
end)

makeToggle(vh, "Vehicle Fly", false, function(on)
    if on then
        local char = LP.Character; if not char then return end
        local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        if hum.Seated then
            local seat = hum.SeatPart
            if seat and seat.Parent:FindFirstChild("Type") and seat.Parent.Type.Value == "Vehicle" then
                NOFLY()
                task.wait()
                task.spawn(sFLY)
            end
        end
    else
        NOFLY()
    end
end)

-- ════════════════════════════════════════════════════
-- SPAWNER LOGIC
-- ════════════════════════════════════════════════════

local abortSpawner = false
local spawnColor   = nil
local spawnStat

local carColors = {
    "Medium stone grey", "Sand green",        "Sand red",      "Faded green",
    "Dark grey metallic","Dark grey",          "Earth yellow",  "Earth orange",
    "Silver",            "Brick yellow",       "Dark red",      "Hot pink",
}

local function vehicleSpawner(color)
    if not color then spawnStat.SetActive(false, "Select a color first"); return end
    abortSpawner = false
    spawnStat.SetActive(true, "Click your spawn pad")

    local spawnedPartColor = nil

    local carAddedConn = workspace.PlayerModels.ChildAdded:Connect(function(v)
        task.spawn(function()
            local ownerVal = v:WaitForChild("Owner", 10)
            if not ownerVal or ownerVal.Value ~= LP then return end
            local pp   = v:WaitForChild("PaintParts", 10); if not pp   then return end
            local part = pp:WaitForChild("Part", 10);      if not part then return end
            spawnedPartColor = part.BrickColor.Name
        end)
    end)

    local padConn
    padConn = Mouse.Button1Up:Connect(function()
        local target = Mouse.Target; if not target then return end
        local car = target.Parent
        if not (car:FindFirstChild("Owner") and car.Owner.Value == LP
            and car:FindFirstChild("Type") and car.Type.Value == "Vehicle Spot") then return end
        padConn:Disconnect()
        spawnStat.SetActive(true, "Waiting for " .. color .. "...")

        task.spawn(function()
            repeat
                if abortSpawner then
                    carAddedConn:Disconnect()
                    spawnStat.SetActive(false, "Stopped")
                    return
                end
                spawnedPartColor = nil
                pcall(function() RS.Interaction.RemoteProxy:FireServer(car.ButtonRemote_SpawnButton) end)
                local t0 = tick()
                repeat task.wait(0.05) until spawnedPartColor ~= nil or (tick() - t0 > 0.6) or abortSpawner
            until spawnedPartColor == color or abortSpawner

            carAddedConn:Disconnect()
            if abortSpawner then
                spawnStat.SetActive(false, "Stopped")
            else
                spawnStat.SetActive(false, "Spawned  ·  " .. color)
            end
        end)
    end)
end

-- ════════════════════════════════════════════════════
-- SPAWNER UI — Section 2
-- ════════════════════════════════════════════════════

sectionLabel(vh, "Spawner")

makeFancyDropdown(vh, "Color", function() return carColors end, function(val)
    spawnColor = val
end)

spawnStat = makeStatus(vh, "Pick a color, then start")

makeButton(vh, "Start Spawner", function() task.spawn(vehicleSpawner, spawnColor) end)
makeButton(vh, "Stop Spawner",  function()
    abortSpawner = true
    spawnStat.SetActive(false, "Stopped")
end)

-- ════════════════════════════════════════════════════
-- SORTER LOGIC + UI — Section 3
-- ════════════════════════════════════════════════════

local sorterPage = pages["SorterTab"]

-- ── Constants ──────────────────────────────────────
local HIGHLIGHT_COLOR = Color3.fromRGB(255, 180, 0)
local PREVIEW_COLOR   = Color3.fromRGB(80,  160, 255)
local PLACED_COLOR    = Color3.fromRGB(60,  210, 100)
local ITEM_GAP        = 0.08
local DRIVE_TIMEOUT   = 8.0
local HOLD_SECONDS    = 1.2
local STABLE_NEEDED   = 40
local STABLE_DIST     = 0.6
local CONFIRM_DIST    = 2.5
local VERIFY_DIST     = 4.0
local SLOT_RETRY_MAX  = 5

-- ── State ───────────────────────────────────────────
local selectedItems    = {}
local previewPart      = nil
local previewFollowing = false
local previewPlaced    = false
local isSorting        = false
local isStopped        = false
local sortThread       = nil
local sortSlots        = nil
local sortIndex        = 1
local sortTotal        = 0
local sortDone         = 0
local overflowBlocked  = false
local gridCols         = 3
local gridLayers       = 1
local gridRows         = 0
local clickSelEnabled  = false
local lassoEnabled     = false
local groupSelEnabled  = false
local lassoStartPos    = nil
local lassoDragging    = false
local followConn       = nil

-- ── Item identification ─────────────────────────────
local function isSortableItem(model)
    if not model or not model:IsA("Model") then return false end
    if model == workspace then return false end
    local mp2 = model:FindFirstChild("Main") or model:FindFirstChildWhichIsA("BasePart")
    if not mp2 then return false end
    if model:FindFirstChild("TreeClass") then return false end
    return model:FindFirstChild("Owner") ~= nil
        or model:FindFirstChild("PurchasedBoxItemName") ~= nil
        or model:FindFirstChild("DraggableItem") ~= nil
        or model:FindFirstChild("ItemName") ~= nil
end

local function getMainPart(model)
    return model:FindFirstChild("Main") or model:FindFirstChildWhichIsA("BasePart")
end

-- ── Selection ───────────────────────────────────────
local function highlightItem(model)
    if selectedItems[model] then return end
    local hl = Instance.new("SelectionBox")
    hl.Color3              = HIGHLIGHT_COLOR
    hl.LineThickness       = 0.06
    hl.SurfaceTransparency = 0.78
    hl.SurfaceColor3       = HIGHLIGHT_COLOR
    hl.Adornee             = model
    hl.Parent              = model
    selectedItems[model]   = hl
end

local function unhighlightItem(model)
    if selectedItems[model] then
        selectedItems[model]:Destroy()
        selectedItems[model] = nil
    end
end

local function unhighlightAll()
    for model, hl in pairs(selectedItems) do
        if hl and hl.Parent then hl:Destroy() end
    end
    selectedItems = {}
end

local function countSelected()
    local n = 0
    for _ in pairs(selectedItems) do n = n + 1 end
    return n
end

local function groupSelectItem(target)
    if not isSortableItem(target) then return end
    local nv = target:FindFirstChild("ItemName") or target:FindFirstChild("PurchasedBoxItemName")
    local targetName = nv and nv.Value or target.Name
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and isSortableItem(obj) then
            local v = obj:FindFirstChild("ItemName") or obj:FindFirstChild("PurchasedBoxItemName")
            local n = v and v.Value or obj.Name
            if n == targetName then highlightItem(obj) end
        end
    end
end

-- ── Slot calculator ─────────────────────────────────
local function calculateSlots(items, anchorCF, colCount, layerCount, rowCount)
    colCount   = math.max(1, colCount)
    layerCount = math.max(1, layerCount)
    rowCount   = math.max(0, rowCount)

    local entries = {}
    for _, model in ipairs(items) do
        local ok, _, sz = pcall(function() return model:GetBoundingBox() end)
        local s = (ok and sz) or Vector3.new(2, 2, 2)
        table.insert(entries, { model = model, w = s.X, h = s.Y, d = s.Z })
    end

    table.sort(entries, function(a, b) return a.h > b.h end)

    local total = #entries
    local rpl
    if rowCount > 0 then
        rpl = rowCount
    else
        rpl = math.max(1, math.ceil(math.ceil(total / layerCount) / colCount))
    end
    local slotPerLayer = colCount * rpl

    for i, e in ipairs(entries) do
        local idx   = i - 1
        local layer = math.floor(idx / slotPerLayer)
        local rem   = idx % slotPerLayer
        local row   = math.floor(rem / colCount)
        local col   = rem % colCount
        e.layer = layer; e.row = row; e.col = col
    end

    local layerMaxH, rowMaxD = {}, {}
    for _, e in ipairs(entries) do
        local l, r = e.layer, e.row
        layerMaxH[l] = math.max(layerMaxH[l] or 0, e.h)
        if not rowMaxD[l] then rowMaxD[l] = {} end
        rowMaxD[l][r] = math.max(rowMaxD[l][r] or 0, e.d)
    end

    local maxLayer = 0
    for _, e in ipairs(entries) do
        if e.layer > maxLayer then maxLayer = e.layer end
    end

    local layerY = {}
    local accY = 0
    for l = 0, maxLayer do
        layerY[l] = accY
        accY = accY + (layerMaxH[l] or 0) + ITEM_GAP
    end

    local rowZ = {}
    for l = 0, maxLayer do
        rowZ[l] = {}
        local accZ = 0
        local maxRow = 0
        for _, e in ipairs(entries) do
            if e.layer == l and e.row > maxRow then maxRow = e.row end
        end
        for r = 0, maxRow do
            rowZ[l][r] = accZ
            accZ = accZ + ((rowMaxD[l] and rowMaxD[l][r]) or 0) + ITEM_GAP
        end
    end

    local colMaxW = {}
    for _, e in ipairs(entries) do
        colMaxW[e.col] = math.max(colMaxW[e.col] or 0, e.w)
    end
    local colX = {}
    local accX = 0
    for c = 0, colCount - 1 do
        colX[c] = accX
        accX = accX + (colMaxW[c] or 0) + ITEM_GAP
    end

    local slots = {}
    for _, e in ipairs(entries) do
        local lx = colX[e.col] + e.w / 2
        local ly = layerY[e.layer] + e.h / 2
        local lz = (rowZ[e.layer] and rowZ[e.layer][e.row] or 0) + e.d / 2
        table.insert(slots, {
            model = e.model,
            cf    = anchorCF * CFrame.new(lx, ly, lz),
            layer = e.layer,
        })
    end
    return slots
end

-- ── Preview box ─────────────────────────────────────
local function destroyPreview()
    if followConn then followConn:Disconnect(); followConn = nil end
    if previewPart and previewPart.Parent then previewPart:Destroy() end
    previewPart      = nil
    previewFollowing = false
    previewPlaced    = false
end

local function computePreviewSize()
    local entries = {}
    for model in pairs(selectedItems) do
        local ok, _, sz = pcall(function() return model:GetBoundingBox() end)
        local s = (ok and sz) or Vector3.new(2, 2, 2)
        table.insert(entries, { w = s.X, h = s.Y, d = s.Z })
    end
    if #entries == 0 then return 4, 4, 4 end

    local cols   = math.max(1, gridCols)
    local layers = math.max(1, gridLayers)
    local rows   = math.max(0, gridRows)
    local maxW, maxH, maxD = 0, 0, 0
    for _, e in ipairs(entries) do
        if e.w > maxW then maxW = e.w end
        if e.h > maxH then maxH = e.h end
        if e.d > maxD then maxD = e.d end
    end

    local totalItems = #entries
    local slotPerLayer
    if rows > 0 then
        slotPerLayer = cols * rows
    else
        slotPerLayer = math.ceil(totalItems / layers)
    end
    local actualRows = math.ceil(slotPerLayer / cols)

    local boxW = cols       * (maxW + ITEM_GAP) - ITEM_GAP
    local boxH = layers     * (maxH + ITEM_GAP) - ITEM_GAP
    local boxD = actualRows * (maxD + ITEM_GAP) - ITEM_GAP
    return math.max(boxW, 1), math.max(boxH, 1), math.max(boxD, 1)
end

local function getMouseSurfaceCF(halfH)
    local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
    local params  = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local excl = {}
    if previewPart then table.insert(excl, previewPart) end
    local char = player.Character
    if char then table.insert(excl, char) end
    params.FilterDescendantsInstances = excl

    local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 600, params)
    local hitPos
    if result then
        hitPos = result.Position
    else
        local t = unitRay.Origin.Y / -unitRay.Direction.Y
        if t and t > 0 then
            hitPos = unitRay.Origin + unitRay.Direction * t
        else
            hitPos = unitRay.Origin + unitRay.Direction * 40
        end
    end
    return CFrame.new(hitPos.X, hitPos.Y + halfH, hitPos.Z)
end

local function buildPreviewBox(sX, sY, sZ)
    if previewPart and previewPart.Parent then previewPart:Destroy() end
    previewPart = Instance.new("Part")
    previewPart.Name         = "VHSorterPreview"
    previewPart.Anchored     = true
    previewPart.CanCollide   = false
    previewPart.CanQuery     = false
    previewPart.CastShadow   = false
    previewPart.Size         = Vector3.new(math.max(sX, 0.5), math.max(sY, 0.5), math.max(sZ, 0.5))
    previewPart.Color        = PREVIEW_COLOR
    previewPart.Material     = Enum.Material.SmoothPlastic
    previewPart.Transparency = 0.50
    previewPart.Parent       = workspace
    local sb = Instance.new("SelectionBox")
    sb.Color3              = PREVIEW_COLOR
    sb.LineThickness       = 0.07
    sb.SurfaceTransparency = 1.0
    sb.Adornee             = previewPart
    sb.Parent              = previewPart
end

local function startPreviewFollow()
    if not (previewPart and previewPart.Parent) then return end
    previewFollowing = true
    previewPlaced    = false
    if followConn then followConn:Disconnect(); followConn = nil end
    followConn = RunService.RenderStepped:Connect(function()
        if not previewFollowing then return end
        if not (previewPart and previewPart.Parent) then
            followConn:Disconnect(); followConn = nil; return
        end
        local halfH    = previewPart.Size.Y / 2
        local targetCF = getMouseSurfaceCF(halfH)
        previewPart.CFrame = previewPart.CFrame:Lerp(targetCF, 0.22)
    end)
end

local function placePreview()
    if not (previewPart and previewPart.Parent) then return end
    if not previewFollowing then return end
    previewFollowing = false
    if followConn then followConn:Disconnect(); followConn = nil end
    local halfH = previewPart.Size.Y / 2
    previewPart.CFrame = getMouseSurfaceCF(halfH)
    previewPart.Color  = PLACED_COLOR
    local sb = previewPart:FindFirstChildOfClass("SelectionBox")
    if sb then sb.Color3 = PLACED_COLOR end
    previewPlaced = true
end

-- ── Sort engine ─────────────────────────────────────
local _dragRemote = nil
local function getDragRemote()
    if _dragRemote then return _dragRemote end
    local interaction = RS:FindFirstChild("Interaction")
    if interaction then
        _dragRemote = interaction:FindFirstChild("ClientIsDragging")
    end
    return _dragRemote
end

local function goNear(pos, hrp)
    if hrp then hrp.CFrame = CFrame.new(pos) * CFrame.new(0, 3, 4) end
end

local function zeroVelocity(model)
    pcall(function()
        for _, p in ipairs(model:GetDescendants()) do
            if p:IsA("BasePart") and not p.Anchored then
                p.AssemblyLinearVelocity  = Vector3.zero
                p.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)
end

local function placeAndLock(model, targetCF)
    if not (model and model.Parent) then return true end
    local mp = getMainPart(model)
    if not mp then return true end
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local dragRemote = getDragRemote()
    local dest       = targetCF * CFrame.new(0, 0.04, 0)
    local destPos    = dest.Position

    goNear(mp.Position, hrp)

    local driveStart   = tick()
    local holdStart    = nil
    local stableStreak = 0
    local locked       = false
    local done         = false

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if done then return end
        if not (mp and mp.Parent) then
            locked = true; done = true; conn:Disconnect(); return
        end
        if (hrp.Position - mp.Position).Magnitude > 16 then
            goNear(mp.Position, hrp)
        end
        pcall(function()
            if dragRemote then dragRemote:FireServer(model) end
            mp.CFrame = dest
        end)
        zeroVelocity(model)

        local dist = (mp.Position - destPos).Magnitude
        if dist < CONFIRM_DIST then
            holdStart    = holdStart or tick()
            stableStreak = stableStreak + 1
        else
            stableStreak = 0
            if not holdStart and (tick() - driveStart) >= DRIVE_TIMEOUT then
                done = true; conn:Disconnect(); return
            end
        end

        local heldLong = holdStart and (tick() - holdStart) >= HOLD_SECONDS
        local isStable = stableStreak >= STABLE_NEEDED
        if heldLong and isStable then
            locked = true; done = true; conn:Disconnect()
        elseif holdStart and (tick() - holdStart) > HOLD_SECONDS * 6 then
            done = true; conn:Disconnect()
        end
    end)

    while not done do task.wait() end
    zeroVelocity(model)
    return locked
end

local function isSlotFilled(slot)
    local model = slot.model
    if not (model and model.Parent) then return true end
    local mp = getMainPart(model)
    if not mp then return true end
    return (mp.Position - slot.cf.Position).Magnitude < VERIFY_DIST
end

-- ── Sorter UI helpers (styled to match Vehicle tab) ─
local function sorterSectionLabel(text)
    sectionLabel(sorterPage, text)
end

local function sorterSep()
    local s = Instance.new("Frame", sorterPage)
    s.Size             = UDim2.new(1, -12, 0, 1)
    s.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    s.BorderSizePixel  = 0
end

-- Simple toggle for sorter page (styled like Vehicle toggles)
local function sorterToggle(labelText, defaultVal, cb)
    return makeToggle(sorterPage, labelText, defaultVal, cb)
end

-- Simple button for sorter page (styled like Vehicle buttons)
local function sorterButton(text, cb, bgColor)
    if bgColor then
        local btn = Instance.new("TextButton", sorterPage)
        btn.Size             = UDim2.new(1, -12, 0, 34)
        btn.BackgroundColor3 = bgColor
        btn.BorderSizePixel  = 0
        btn.Font             = Enum.Font.GothamSemibold
        btn.TextSize         = 13
        btn.TextColor3       = C.TEXT
        btn.Text             = text
        btn.AutoButtonColor  = false
        corner(btn, 6)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = C.BORDER; stroke.Thickness = 1
        btn.MouseButton1Click:Connect(function() task.spawn(cb) end)
        return btn
    else
        return makeButton(sorterPage, text, cb)
    end
end

-- Int slider for sorter (axis-coloured, styled to match Vehicle sliders)
local AXIS_COLORS = {
    X = Color3.fromRGB(220, 70,  70),
    Y = Color3.fromRGB(70,  200, 70),
    Z = Color3.fromRGB(70,  120, 255),
}

local function sorterIntSlider(label, axis, minV, maxV, defaultV, cb)
    local axCol = AXIS_COLORS[axis] or C.TEXT
    local ROW_H = 54

    local fr = Instance.new("Frame", sorterPage)
    fr.Size             = UDim2.new(1, -12, 0, ROW_H)
    fr.BackgroundColor3 = C.ROW
    fr.BorderSizePixel  = 0
    corner(fr, 8)
    local fStroke = Instance.new("UIStroke", fr)
    fStroke.Color = C.BORDER; fStroke.Thickness = 1; fStroke.Transparency = 0.4

    local axTag = Instance.new("TextLabel", fr)
    axTag.Size = UDim2.new(0, 18, 0, 22); axTag.Position = UDim2.new(0, 8, 0, 5)
    axTag.BackgroundTransparency = 1; axTag.Font = Enum.Font.GothamBold
    axTag.TextSize = 14; axTag.TextColor3 = axCol; axTag.Text = axis

    local topLbl = Instance.new("TextLabel", fr)
    topLbl.Size = UDim2.new(0.55, 0, 0, 22); topLbl.Position = UDim2.new(0, 28, 0, 5)
    topLbl.BackgroundTransparency = 1; topLbl.Font = Enum.Font.GothamBold
    topLbl.TextSize = 12; topLbl.TextColor3 = C.TEXT
    topLbl.TextXAlignment = Enum.TextXAlignment.Left; topLbl.Text = label

    local valLbl = Instance.new("TextLabel", fr)
    valLbl.Size = UDim2.new(0.3, 0, 0, 22); valLbl.Position = UDim2.new(0.7, 0, 0, 5)
    valLbl.BackgroundTransparency = 1; valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 13; valLbl.TextColor3 = axCol
    valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.Text = tostring(defaultV)

    local track = Instance.new("Frame", fr)
    track.Size = UDim2.new(1, -16, 0, 6); track.Position = UDim2.new(0, 8, 0, 36)
    track.BackgroundColor3 = C.TRACK; track.BorderSizePixel = 0
    corner(track, 3)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((defaultV - minV) / (maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = axCol; fill.BorderSizePixel = 0
    corner(fill, 3)

    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0, 18, 0, 18); knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((defaultV - minV) / (maxV - minV), 0, 0.5, 0)
    knob.BackgroundColor3 = C.TEXT; knob.Text = ""; knob.BorderSizePixel = 0
    corner(knob, 9)

    local dragging = false
    local cur = defaultV

    local function apply(screenX)
        local ratio = math.clamp(
            (screenX - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local val = math.round(minV + ratio * (maxV - minV))
        if val == cur then return end
        cur = val
        fill.Size     = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, 0, 0.5, 0)
        valLbl.Text   = tostring(val)
        if cb then cb(val) end
    end

    knob.MouseButton1Down:Connect(function() dragging = true end)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; apply(inp.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            apply(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    return fr
end

-- ── Status bar (sorter) ─────────────────────────────
local sortStatusBar, sortStatusLabel
do
    local f = Instance.new("Frame", sorterPage)
    f.Size             = UDim2.new(1, -12, 0, 36)
    f.BackgroundColor3 = C.CARD
    f.BorderSizePixel  = 0
    corner(f, 6)
    local stroke = Instance.new("UIStroke", f)
    stroke.Color = Color3.fromRGB(255, 180, 0); stroke.Thickness = 1; stroke.Transparency = 0.4

    local dot = Instance.new("Frame", f)
    dot.Size             = UDim2.new(0, 7, 0, 7)
    dot.Position         = UDim2.new(0, 10, 0.5, -3)
    dot.BackgroundColor3 = C.DOT_IDLE
    dot.BorderSizePixel  = 0
    corner(dot, 4)

    local lb = Instance.new("TextLabel", f)
    lb.Size               = UDim2.new(1, -30, 1, 0)
    lb.Position           = UDim2.new(0, 22, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Font               = Enum.Font.GothamSemibold
    lb.TextSize           = 11
    lb.TextColor3         = Color3.fromRGB(255, 210, 100)
    lb.TextXAlignment     = Enum.TextXAlignment.Left
    lb.TextWrapped        = true
    lb.Text               = "Select items to get started."

    sortStatusBar   = f
    sortStatusLabel = lb
end

local function setSortStatus(msg, col)
    sortStatusLabel.Text       = msg
    sortStatusLabel.TextColor3 = col or Color3.fromRGB(255, 210, 100)
end

-- ── Progress bar (sorter) ───────────────────────────
local pbContainer, pbFill, pbLabel
do
    local pb = Instance.new("Frame")
    pb.Size             = UDim2.new(1, -12, 0, 44)
    pb.BackgroundColor3 = C.CARD
    pb.BorderSizePixel  = 0
    pb.Visible          = false
    corner(pb, 8)
    local stroke = Instance.new("UIStroke", pb)
    stroke.Color = C.BORDER; stroke.Thickness = 1; stroke.Transparency = 0.5

    local lbl = Instance.new("TextLabel", pb)
    lbl.Size = UDim2.new(1, -12, 0, 16); lbl.Position = UDim2.new(0, 6, 0, 4)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 11
    lbl.TextColor3 = C.TEXT_MID; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "Sorting..."

    local track = Instance.new("Frame", pb)
    track.Size = UDim2.new(1, -12, 0, 12); track.Position = UDim2.new(0, 6, 0, 26)
    track.BackgroundColor3 = C.TRACK; track.BorderSizePixel = 0
    corner(track, 6)

    local fl = Instance.new("Frame", track)
    fl.Size = UDim2.new(0, 0, 1, 0)
    fl.BackgroundColor3 = Color3.fromRGB(255, 175, 55)
    fl.BorderSizePixel  = 0
    corner(fl, 6)

    pbContainer = pb; pbFill = fl; pbLabel = lbl
end

local function hideProgress(delay)
    task.delay(delay or 2.0, function()
        if not pbContainer then return end
        TweenService:Create(pbContainer, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        TweenService:Create(pbFill,      TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        TweenService:Create(pbLabel,     TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        task.delay(0.45, function()
            if not pbContainer then return end
            pbContainer.Visible             = false
            pbContainer.BackgroundTransparency = 0
            pbFill.BackgroundTransparency   = 0
            pbFill.BackgroundColor3         = Color3.fromRGB(255, 175, 55)
            pbFill.Size                     = UDim2.new(0, 0, 1, 0)
            pbLabel.TextTransparency        = 0
        end)
    end)
end

-- ── Lasso overlay ───────────────────────────────────
local coreGui    = game:GetService("CoreGui")
local lassoFrame = Instance.new("Frame", coreGui:FindFirstChild("VanillaHub") or coreGui)
lassoFrame.Name                   = "SorterLasso"
lassoFrame.BackgroundColor3       = Color3.fromRGB(255, 160, 40)
lassoFrame.BackgroundTransparency = 0.82
lassoFrame.BorderSizePixel        = 0
lassoFrame.Visible                = false
lassoFrame.ZIndex                 = 20
local lstroke = Instance.new("UIStroke", lassoFrame)
lstroke.Color = Color3.fromRGB(255, 210, 80); lstroke.Thickness = 1.5

local function updateLassoVis(s, cur2)
    local minX = math.min(s.X, cur2.X); local minY = math.min(s.Y, cur2.Y)
    lassoFrame.Position = UDim2.new(0, minX, 0, minY)
    lassoFrame.Size     = UDim2.new(0, math.abs(cur2.X - s.X), 0, math.abs(cur2.Y - s.Y))
end

local function selectLasso()
    if not lassoStartPos then return end
    local cur2 = Vector2.new(mouse.X, mouse.Y)
    local minX = math.min(lassoStartPos.X, cur2.X); local maxX = math.max(lassoStartPos.X, cur2.X)
    local minY = math.min(lassoStartPos.Y, cur2.Y); local maxY = math.max(lassoStartPos.Y, cur2.Y)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and isSortableItem(obj) then
            local mp2 = getMainPart(obj)
            if mp2 then
                local sp, vis = camera:WorldToScreenPoint(mp2.Position)
                if vis and sp.X >= minX and sp.X <= maxX and sp.Y >= minY and sp.Y <= maxY then
                    highlightItem(obj)
                end
            end
        end
    end
end

-- ── Forward refs ────────────────────────────────────
local startBtn, stopBtn

local function refreshStatus()
    local n = countSelected()
    if isSorting then
        setSortStatus("⏳  Sorting in progress...", Color3.fromRGB(140, 220, 255))
    elseif isStopped then
        setSortStatus("⏸  Paused — hit Start to resume.", Color3.fromRGB(255, 210, 80))
    elseif overflowBlocked then
        setSortStatus("❌  Too many items! Increase X, Y, or Z.", Color3.fromRGB(255, 100, 100))
    elseif n == 0 then
        setSortStatus("👆  Select items with Click, Group, or Lasso.")
    elseif previewFollowing then
        setSortStatus("🖱  Preview following mouse — click to place.", Color3.fromRGB(140, 220, 255))
    elseif previewPlaced then
        setSortStatus("✅  " .. n .. " item(s) ready. Hit Start Sorting!", Color3.fromRGB(100, 220, 120))
    elseif previewPart then
        setSortStatus("📦  Preview exists. Click anywhere to place it.", Color3.fromRGB(200, 200, 100))
    else
        setSortStatus("📦  " .. n .. " selected. Click Generate Preview.")
    end

    if startBtn then
        local canSort = (n > 0 or isStopped)
                        and (previewPlaced or isStopped)
                        and not isSorting
                        and not overflowBlocked
        startBtn.BackgroundColor3 = canSort and Color3.fromRGB(35, 100, 50) or C.BTN
        startBtn.TextColor3       = canSort and C.TEXT or C.TEXT_DIM
        startBtn.Text = isStopped and "▶  Resume Sorting" or "▶  Start Sorting"
    end
    if stopBtn then
        stopBtn.BackgroundColor3 = isSorting and Color3.fromRGB(100, 60, 20) or C.BTN
        stopBtn.TextColor3       = isSorting and Color3.fromRGB(255, 190, 80) or C.TEXT_DIM
    end
end

local function fixDriftedSlots(slots, upTo)
    for i = 1, upTo do
        if not isSorting then break end
        local slot = slots[i]
        if slot and not isSlotFilled(slot) then
            pbLabel.Text = "🔧 Re-fixing slot " .. i .. " ..."
            placeAndLock(slot.model, slot.cf)
        end
    end
end

-- ── Build Sorter UI ─────────────────────────────────

sorterSectionLabel("Status")

-- (sortStatusBar is already parented to sorterPage above)

sorterSep()
sorterSectionLabel("Selection Mode")

sorterToggle("Click Selection", false, function(v)
    clickSelEnabled = v
    if v then lassoEnabled = false; groupSelEnabled = false end
end)
sorterToggle("Group Selection", false, function(v)
    groupSelEnabled = v
    if v then clickSelEnabled = false; lassoEnabled = false end
end)
sorterToggle("Lasso Tool", false, function(v)
    lassoEnabled = v
    if v then clickSelEnabled = false; groupSelEnabled = false end
end)

do
    local hint = Instance.new("TextLabel", sorterPage)
    hint.Size             = UDim2.new(1, -12, 0, 26)
    hint.BackgroundColor3 = C.ROW
    hint.BorderSizePixel  = 0
    hint.Font             = Enum.Font.Gotham
    hint.TextSize         = 11
    hint.TextColor3       = C.TEXT_DIM
    hint.TextWrapped      = true
    hint.TextXAlignment   = Enum.TextXAlignment.Left
    hint.Text             = "  Lasso: drag to box-select.  Group: click to select all of same type."
    corner(hint, 6)
    Instance.new("UIPadding", hint).PaddingLeft = UDim.new(0, 6)
end

sorterButton("Clear Selection", function()
    unhighlightAll(); refreshStatus()
end)

sorterSep()
sorterSectionLabel("Sort Grid  —  X Width · Y Height · Z Depth")

sorterIntSlider("Width  (items per row)", "X", 1, 12, 3, function(v)
    gridCols = v; overflowBlocked = false
    if previewFollowing and previewPart and previewPart.Parent then
        local sX, sY, sZ = computePreviewSize()
        previewPart.Size = Vector3.new(math.max(sX, 0.5), math.max(sY, 0.5), math.max(sZ, 0.5))
    end
end)

sorterIntSlider("Height  (vertical layers)", "Y", 1, 5, 1, function(v)
    gridLayers = v; overflowBlocked = false
    if previewFollowing and previewPart and previewPart.Parent then
        local sX, sY, sZ = computePreviewSize()
        previewPart.Size = Vector3.new(math.max(sX, 0.5), math.max(sY, 0.5), math.max(sZ, 0.5))
    end
end)

sorterIntSlider("Depth  (rows, 0=auto)", "Z", 0, 12, 0, function(v)
    gridRows = v; overflowBlocked = false
    if previewFollowing and previewPart and previewPart.Parent then
        local sX, sY, sZ = computePreviewSize()
        previewPart.Size = Vector3.new(math.max(sX, 0.5), math.max(sY, 0.5), math.max(sZ, 0.5))
    end
end)

do
    local gridHint = Instance.new("TextLabel", sorterPage)
    gridHint.Size             = UDim2.new(1, -12, 0, 28)
    gridHint.BackgroundColor3 = C.ROW
    gridHint.BorderSizePixel  = 0
    gridHint.Font             = Enum.Font.Gotham
    gridHint.TextSize         = 11
    gridHint.TextColor3       = C.TEXT_DIM
    gridHint.TextWrapped      = true
    gridHint.TextXAlignment   = Enum.TextXAlignment.Left
    gridHint.Text             = "  Fills left→right (X), front→back (Z), bottom→top (Y). Tallest first. Z=0 auto."
    corner(gridHint, 6)
    Instance.new("UIPadding", gridHint).PaddingLeft = UDim.new(0, 6)
end

-- Overflow popup
local overflowPopup, overflowLabel
do
    local pop = Instance.new("Frame", sorterPage)
    pop.Size             = UDim2.new(1, -12, 0, 48)
    pop.BackgroundColor3 = Color3.fromRGB(60, 10, 10)
    pop.BorderSizePixel  = 0
    pop.Visible          = false
    corner(pop, 8)
    local stroke = Instance.new("UIStroke", pop)
    stroke.Color = Color3.fromRGB(220, 60, 60); stroke.Thickness = 1.5; stroke.Transparency = 0.3
    local lbl = Instance.new("TextLabel", pop)
    lbl.Size = UDim2.new(1, -16, 1, 0); lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(255, 120, 120)
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.TextWrapped = true; lbl.Text = ""
    overflowPopup = pop; overflowLabel = lbl
end

local function showOverflow(msg)
    overflowBlocked     = true
    overflowLabel.Text  = "⚠  " .. msg
    overflowPopup.Visible = true
end

local function hideOverflow()
    overflowBlocked       = false
    overflowPopup.Visible = false
end

local function gridCapacity()
    local cols = math.max(1, gridCols)
    local layers = math.max(1, gridLayers)
    local rows = math.max(0, gridRows)
    if rows == 0 then return math.huge end
    return cols * rows * layers
end

sorterSep()
sorterSectionLabel("Preview")

sorterButton("Generate Preview  (follows mouse)", function()
    if countSelected() == 0 then setSortStatus("⚠  No items selected!"); return end
    local n   = countSelected()
    local cap = gridCapacity()
    if n > cap then
        showOverflow(n .. " items but grid only fits " .. cap ..
            "  (X=" .. gridCols .. " × Z=" .. gridRows .. " × Y=" .. gridLayers .. ").")
        refreshStatus(); return
    end
    hideOverflow()
    local sX, sY, sZ = computePreviewSize()
    buildPreviewBox(sX, sY, sZ)
    startPreviewFollow()
    refreshStatus()
end, Color3.fromRGB(22, 40, 80))

sorterButton("Clear Preview", function()
    destroyPreview(); refreshStatus()
end)

sorterSep()
sorterSectionLabel("Actions")

-- Start button
startBtn = Instance.new("TextButton", sorterPage)
startBtn.Size             = UDim2.new(1, -12, 0, 36)
startBtn.BackgroundColor3 = C.BTN
startBtn.Text             = "▶  Start Sorting"
startBtn.Font             = Enum.Font.GothamBold
startBtn.TextSize         = 14
startBtn.TextColor3       = C.TEXT_DIM
startBtn.BorderSizePixel  = 0
corner(startBtn, 6)

local function runSortLoop(slots, startI, total, doneStart)
    local done = doneStart

    sortThread = task.spawn(function()
        local i         = startI
        local prevLayer = slots[startI] and slots[startI].layer or 0

        while i <= total and isSorting do
            local slot = slots[i]

            local curLayer = slot.layer or 0
            if curLayer > prevLayer then
                pbLabel.Text = "🔍 Checking layer " .. prevLayer .. "..."
                fixDriftedSlots(slots, i - 1)
                prevLayer = curLayer
                if not isSorting then sortIndex = i; break end
            end

            if not (slot.model and slot.model.Parent) then
                done = done + 1; sortDone = done; sortIndex = i + 1
                i = i + 1; continue
            end

            pbLabel.Text = "Sorting... " .. done .. " / " .. total

            local locked = false
            for attempt = 1, SLOT_RETRY_MAX do
                if not isSorting then break end
                pbLabel.Text = "Sorting " .. done + 1 .. "/" .. total
                    .. (attempt > 1 and ("  (retry " .. attempt .. ")") or "")
                locked = placeAndLock(slot.model, slot.cf)
                if not isSorting then break end
                task.wait(0.15)
                if isSlotFilled(slot) then locked = true; break end
                locked = false
            end

            if not isSorting then sortIndex = i; break end

            unhighlightItem(slot.model)
            done = done + 1; sortDone = done; sortIndex = i + 1

            local pct = math.clamp(done / math.max(total, 1), 0, 1)
            TweenService:Create(pbFill, TweenInfo.new(0.15, Enum.EasingStyle.Quad),
                { Size = UDim2.new(pct, 0, 1, 0) }):Play()
            pbLabel.Text = "Sorting... " .. done .. " / " .. total
            task.wait(0.25)
            i = i + 1
        end

        if isSorting and done >= total then
            pbLabel.Text = "🔍 Final check..."
            fixDriftedSlots(slots, total)
        end

        isSorting  = false
        sortThread = nil

        if done >= total then
            isStopped = false; sortSlots = nil
            TweenService:Create(pbFill, TweenInfo.new(0.25),
                { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(90, 220, 110) }):Play()
            pbLabel.Text = "✔  Sorting complete!"
            destroyPreview(); unhighlightAll(); hideProgress(2.5)
        else
            isStopped    = true
            pbLabel.Text = "⏸  Stopped at " .. done .. " / " .. total
        end
        refreshStatus()
    end)
end

startBtn.MouseButton1Click:Connect(function()
    if isSorting then return end
    if overflowBlocked then setSortStatus("❌  Fix grid size first!"); return end

    if isStopped and sortSlots then
        isStopped = false; isSorting = true
        pbContainer.Visible     = true
        pbFill.BackgroundColor3 = Color3.fromRGB(255, 175, 55)
        pbLabel.Text            = "Sorting... " .. sortDone .. " / " .. sortTotal
        refreshStatus()
        runSortLoop(sortSlots, sortIndex, sortTotal, sortDone)
        return
    end

    if not (previewPlaced and previewPart and previewPart.Parent) then
        setSortStatus("⚠  Generate a preview and place it first!"); return
    end
    if countSelected() == 0 then setSortStatus("⚠  No items selected!"); return end

    local items = {}
    for model in pairs(selectedItems) do
        if model and model.Parent then table.insert(items, model) end
    end
    if #items == 0 then return end

    local anchorCF = previewPart.CFrame
        * CFrame.new(-previewPart.Size.X / 2, -previewPart.Size.Y / 2, -previewPart.Size.Z / 2)

    sortSlots = calculateSlots(items, anchorCF, gridCols, gridLayers, gridRows)
    sortTotal = #sortSlots; sortDone = 0; sortIndex = 1
    isStopped = false; isSorting = true

    pbContainer.Visible     = true
    pbFill.Size             = UDim2.new(0, 0, 1, 0)
    pbFill.BackgroundColor3 = Color3.fromRGB(255, 175, 55)
    pbLabel.Text            = "Sorting... 0 / " .. sortTotal
    refreshStatus()
    runSortLoop(sortSlots, 1, sortTotal, 0)
end)

-- Stop button
stopBtn = Instance.new("TextButton", sorterPage)
stopBtn.Size             = UDim2.new(1, -12, 0, 32)
stopBtn.BackgroundColor3 = C.BTN
stopBtn.Text             = "⏹  Stop"
stopBtn.Font             = Enum.Font.GothamBold
stopBtn.TextSize         = 13
stopBtn.TextColor3       = C.TEXT_DIM
stopBtn.BorderSizePixel  = 0
corner(stopBtn, 6)
stopBtn.MouseButton1Click:Connect(function()
    if not isSorting then return end
    isSorting    = false
    pbLabel.Text = "⏸  Stopping..."
    refreshStatus()
end)

sorterButton("Cancel  (clear all)", function()
    isSorting = false; isStopped = false
    sortSlots = nil; sortIndex = 1; sortTotal = 0; sortDone = 0
    if sortThread then pcall(task.cancel, sortThread); sortThread = nil end
    destroyPreview(); unhighlightAll(); hideOverflow()
    pbLabel.Text = "Cancelled."
    hideProgress(1.0)
    refreshStatus()
end, Color3.fromRGB(50, 10, 10))

pbContainer.Parent = sorterPage

-- ── Mouse input (sorter) ────────────────────────────
local mouseDownConn = mouse.Button1Down:Connect(function()
    if lassoEnabled then
        lassoDragging      = true
        lassoStartPos      = Vector2.new(mouse.X, mouse.Y)
        lassoFrame.Size    = UDim2.new(0, 0, 0, 0)
        lassoFrame.Visible = true
        return
    end
    if previewFollowing then
        placePreview(); refreshStatus(); return
    end
    local target = mouse.Target; if not target then return end
    local model  = target:FindFirstAncestorOfClass("Model"); if not model then return end
    if clickSelEnabled and isSortableItem(model) then
        if selectedItems[model] then unhighlightItem(model) else highlightItem(model) end
        refreshStatus()
    elseif groupSelEnabled and isSortableItem(model) then
        groupSelectItem(model); refreshStatus()
    end
end)

local mouseMoveConn = mouse.Move:Connect(function()
    if lassoDragging and lassoEnabled and lassoStartPos then
        updateLassoVis(lassoStartPos, Vector2.new(mouse.X, mouse.Y))
    end
end)

local mouseUpConn = mouse.Button1Up:Connect(function()
    if lassoDragging and lassoEnabled and lassoStartPos then
        lassoDragging = false; selectLasso()
        lassoFrame.Visible = false; lassoStartPos = nil
        refreshStatus()
    end
    lassoDragging = false
end)

-- ════════════════════════════════════════════════════
-- CLEANUP (both systems)
-- ════════════════════════════════════════════════════
table.insert(VH.cleanupTasks, function()
    -- Vehicle
    abortSpawner = true
    NOFLY()
    -- Sorter
    isSorting = false; isStopped = false
    sortSlots = nil; sortIndex = 1; sortTotal = 0; sortDone = 0
    if followConn  then followConn:Disconnect();        followConn = nil end
    if sortThread  then pcall(task.cancel, sortThread); sortThread = nil end
    mouseDownConn:Disconnect()
    mouseMoveConn:Disconnect()
    mouseUpConn:Disconnect()
    if lassoFrame and lassoFrame.Parent then lassoFrame:Destroy() end
    destroyPreview()
    unhighlightAll()
end)

refreshStatus()
print("[VanillaHub] Vanilla7_Vehicle (+ Sorter) loaded")
