-- VanillaHub | Vanilla7_Vehicle.lua
-- Vehicle (Section 1) + Spawner (Section 2) + Sorter (Section 3).
-- Requires Vanilla1 (_G.VH) to already be loaded.

if not _G.VH then
    warn("[VanillaHub] Vanilla7: _G.VH not found. Load Vanilla1 first.")
    return
end

local VH              = _G.VH
local TS              = VH.TweenService
local Players         = VH.Players
local UIS             = VH.UserInputService
local RS_Run          = VH.RunService
local LP              = Players.LocalPlayer
local Mouse           = LP:GetMouse()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera          = workspace.CurrentCamera
local pages           = VH.pages

-- ════════════════════════════════════════════════════
-- MERGED THEME
-- ════════════════════════════════════════════════════
local C = {
    -- Shared
    BG          = Color3.fromRGB(6,   6,   6),
    CARD        = Color3.fromRGB(20,  20,  20),
    ROW         = Color3.fromRGB(16,  16,  16),
    INPUT       = Color3.fromRGB(30,  30,  30),
    BTN         = Color3.fromRGB(14,  14,  14),
    BTN_HV      = Color3.fromRGB(32,  32,  32),
    BORDER      = Color3.fromRGB(55,  55,  55),
    SEP         = Color3.fromRGB(50,  50,  50),
    TEXT        = Color3.fromRGB(220, 220, 220),
    TEXT_MID    = Color3.fromRGB(150, 150, 150),
    TEXT_DIM    = Color3.fromRGB(90,  90,  90),
    FILL        = Color3.fromRGB(255, 255, 255),
    TRACK       = Color3.fromRGB(40,  40,  40),
    ACTIVE      = Color3.fromRGB(50,  50,  50),
    -- Vehicle tab specific
    DOT_IDLE    = Color3.fromRGB(70,  70,  70),
    DOT_ACT     = Color3.fromRGB(200, 200, 200),
    TOGGLE_ON   = Color3.fromRGB(200, 200, 200),
    TOGGLE_OFF  = Color3.fromRGB(50,  50,  50),
    -- Sorter tab specific
    SW_ON       = Color3.fromRGB(230, 230, 230),
    SW_OFF      = Color3.fromRGB(55,  55,  55),
    KNOB_ON     = Color3.fromRGB(30,  30,  30),
    KNOB_OFF    = Color3.fromRGB(160, 160, 160),
}

-- ════════════════════════════════════════════════════
-- SHARED LOW-LEVEL HELPERS
-- ════════════════════════════════════════════════════
local function corner(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = inst
end

local function stroke(inst, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color        = color        or C.BORDER
    s.Thickness    = thickness    or 1
    s.Transparency = transparency or 0
    s.Parent       = inst
end

-- ════════════════════════════════════════════════════════════════════════════
-- ██╗   ██╗███████╗██╗  ██╗██╗ ██████╗██╗     ███████╗
-- ██║   ██║██╔════╝██║  ██║██║██╔════╝██║     ██╔════╝
-- ██║   ██║█████╗  ███████║██║██║     ██║     █████╗
-- ╚██╗ ██╔╝██╔══╝  ██╔══██║██║██║     ██║     ██╔══╝
--  ╚████╔╝ ███████╗██║  ██║██║╚██████╗███████╗███████╗
--   ╚═══╝  ╚══════╝╚═╝  ╚═╝╚═╝ ╚═════╝╚══════╝╚══════╝
-- ════════════════════════════════════════════════════════════════════════════
local vh = pages["VehicleTab"]

-- ── Vehicle Tab UI helpers (page as param) ──────────────────────────────────

local function vSectionLabel(page, text)
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

local function vMakeButton(page, text, cb)
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
    local s = Instance.new("UIStroke", btn)
    s.Color = C.BORDER; s.Thickness = 1; s.Transparency = 0
    btn.MouseEnter:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN_HV}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN}):Play()
    end)
    btn.MouseButton1Click:Connect(function() task.spawn(cb) end)
    return btn
end

local function vMakeSlider(page, labelText, minVal, maxVal, defaultVal, cb)
    local TRACK_H  = 4
    local THUMB_SZ = 14
    local ROW_H    = 46

    local outer = Instance.new("Frame", page)
    outer.Size             = UDim2.new(1, -12, 0, ROW_H)
    outer.BackgroundColor3 = C.ROW
    outer.BorderSizePixel  = 0
    corner(outer, 8)
    local outerStroke = Instance.new("UIStroke", outer)
    outerStroke.Color = C.BORDER; outerStroke.Thickness = 1; outerStroke.Transparency = 0.4

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
        currentVal     = math.clamp(math.round(v), minVal, maxVal)
        local pct      = (currentVal - minVal) / (maxVal - minVal)
        fill.Size      = UDim2.new(pct, 0, 1, 0)
        thumb.Position = UDim2.new(pct, -THUMB_SZ/2, 0.5, -THUMB_SZ/2)
        valLbl.Text    = tostring(currentVal)
        cb(currentVal)
    end

    local function updateFromInput(input)
        local relX = input.Position.X - trackOuter.AbsolutePosition.X
        local pct  = math.clamp(relX / trackOuter.AbsoluteSize.X, 0, 1)
        setValue(minVal + pct * (maxVal - minVal))
    end

    hitbox.MouseButton1Down:Connect(function() dragging = true end)
    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
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

local function vMakeToggle(page, labelText, defaultVal, cb)
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
    outerStroke.Color = C.BORDER; outerStroke.Thickness = 1; outerStroke.Transparency = 0.4

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

local function vMakeFancyDropdown(page, labelText, getOptions, cb)
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
    outerStroke.Color = C.BORDER; outerStroke.Thickness = 1; outerStroke.Transparency = 0.4

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
    sfStroke.Color = C.BORDER; sfStroke.Thickness = 1; sfStroke.Transparency = 0.3

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
    listPad.PaddingTop    = UDim.new(0, 4); listPad.PaddingBottom = UDim.new(0, 4)
    listPad.PaddingLeft   = UDim.new(0, 6); listPad.PaddingRight  = UDim.new(0, 6)

    local function setSelected(name)
        selected          = name
        selLbl.Text       = name
        selLbl.TextColor3 = C.TEXT
        outerStroke.Color = C.BORDER
        cb(name)
    end

    local function buildList()
        for _, child in ipairs(listScroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
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

local function vMakeStatus(page, initText)
    local f = Instance.new("Frame", page)
    f.Size             = UDim2.new(1, -12, 0, 28)
    f.BackgroundColor3 = C.CARD
    f.BorderSizePixel  = 0
    corner(f, 6)
    local s = Instance.new("UIStroke", f)
    s.Color = C.BORDER; s.Thickness = 1; s.Transparency = 0.4

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

    if flyKeyDown then flyKeyDown:Disconnect() end
    if flyKeyUp   then flyKeyUp:Disconnect()   end

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
                local F =  (keys.w and spd or 0) + (keys.s and -spd or 0)
                local L =  (keys.a and -spd or 0) + (keys.d and spd or 0)
                local V =  (keys.e and spd*2 or 0) + (keys.q and -spd*2 or 0)
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
-- VEHICLE UI — VehicleTab
-- ════════════════════════════════════════════════════

vSectionLabel(vh, "Vehicle")

vMakeSlider(vh, "Vehicle Speed", 1, 10, 1, function(val)
    vehicleSpeed(val)
end)

vMakeSlider(vh, "Fly Speed", 1, 250, 1, function(val)
    vehicleflyspeed = val
end)

vMakeToggle(vh, "Vehicle Fly", false, function(on)
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
                pcall(function() ReplicatedStorage.Interaction.RemoteProxy:FireServer(car.ButtonRemote_SpawnButton) end)
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
-- SPAWNER UI — VehicleTab
-- ════════════════════════════════════════════════════

vSectionLabel(vh, "Spawner")

vMakeFancyDropdown(vh, "Color", function() return carColors end, function(val)
    spawnColor = val
end)

spawnStat = vMakeStatus(vh, "Pick a color, then start")

vMakeButton(vh, "Start Spawner", function() task.spawn(vehicleSpawner, spawnColor) end)
vMakeButton(vh, "Stop Spawner",  function()
    abortSpawner = true
    spawnStat.SetActive(false, "Stopped")
end)

-- ════════════════════════════════════════════════════════════════════════════
-- ███████╗ ██████╗ ██████╗ ████████╗███████╗██████╗
-- ██╔════╝██╔═══██╗██╔══██╗╚══██╔══╝██╔════╝██╔══██╗
-- ███████╗██║   ██║██████╔╝   ██║   █████╗  ██████╔╝
-- ╚════██║██║   ██║██╔══██╗   ██║   ██╔══╝  ██╔══██╗
-- ███████║╚██████╔╝██║  ██║   ██║   ███████╗██║  ██║
-- ╚══════╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
-- ════════════════════════════════════════════════════════════════════════════
local sorterPage = pages["SorterTab"]

-- ── Sorter Tab UI helpers (use sorterPage closure) ──────────────────────────

local function sSectionLabel(text)
    local f = Instance.new("Frame", sorterPage)
    f.Size                   = UDim2.new(1, 0, 0, 22)
    f.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", f)
    lbl.Size                   = UDim2.new(1, -4, 1, 0)
    lbl.Position               = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextSize               = 10
    lbl.TextColor3             = Color3.fromRGB(130, 130, 130)
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.Text                   = "  " .. string.upper(text)
end

local function sSep()
    local s = Instance.new("Frame", sorterPage)
    s.Size             = UDim2.new(1, 0, 0, 1)
    s.BackgroundColor3 = C.SEP
    s.BorderSizePixel  = 0
end

local function sMakeToggle(labelText, default, cb)
    local frame = Instance.new("Frame", sorterPage)
    frame.Size             = UDim2.new(1, 0, 0, 36)
    frame.BackgroundColor3 = C.CARD
    frame.BorderSizePixel  = 0
    corner(frame, 8)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size                   = UDim2.new(1, -54, 1, 0)
    lbl.Position               = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = labelText
    lbl.Font                   = Enum.Font.GothamSemibold
    lbl.TextSize               = 13
    lbl.TextColor3             = C.TEXT
    lbl.TextXAlignment         = Enum.TextXAlignment.Left

    local tb = Instance.new("TextButton", frame)
    tb.Size             = UDim2.new(0, 36, 0, 20)
    tb.Position         = UDim2.new(1, -46, 0.5, -10)
    tb.BackgroundColor3 = default and C.SW_ON or C.SW_OFF
    tb.Text             = ""
    tb.BorderSizePixel  = 0
    tb.AutoButtonColor  = false
    corner(tb, 20)

    local knob = Instance.new("Frame", tb)
    knob.Size             = UDim2.new(0, 14, 0, 14)
    knob.Position         = UDim2.new(0, default and 20 or 2, 0.5, -7)
    knob.BackgroundColor3 = default and C.KNOB_ON or C.KNOB_OFF
    knob.BorderSizePixel  = 0
    corner(knob, 14)

    local toggled = default
    if cb then cb(toggled) end

    local function setState(val)
        toggled = val
        TS:Create(tb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            BackgroundColor3 = toggled and C.SW_ON or C.SW_OFF
        }):Play()
        TS:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position         = UDim2.new(0, toggled and 20 or 2, 0.5, -7),
            BackgroundColor3 = toggled and C.KNOB_ON or C.KNOB_OFF
        }):Play()
    end

    tb.MouseButton1Click:Connect(function()
        setState(not toggled)
        if cb then cb(toggled) end
    end)

    return frame, setState
end

local function sMakeSlider(labelText, minV, maxV, defV, cb)
    local frame = Instance.new("Frame", sorterPage)
    frame.Size             = UDim2.new(1, 0, 0, 54)
    frame.BackgroundColor3 = C.CARD
    frame.BorderSizePixel  = 0
    corner(frame, 8)

    local topRow = Instance.new("Frame", frame)
    topRow.Size                   = UDim2.new(1, -16, 0, 22)
    topRow.Position               = UDim2.new(0, 8, 0, 7)
    topRow.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", topRow)
    lbl.Size                   = UDim2.new(0.72, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font                   = Enum.Font.GothamSemibold
    lbl.TextSize               = 13
    lbl.TextColor3             = C.TEXT
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.Text                   = labelText

    local valLbl = Instance.new("TextLabel", topRow)
    valLbl.Size                   = UDim2.new(0.28, 0, 1, 0)
    valLbl.Position               = UDim2.new(0.72, 0, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Font                   = Enum.Font.GothamBold
    valLbl.TextSize               = 13
    valLbl.TextColor3             = C.FILL
    valLbl.TextXAlignment         = Enum.TextXAlignment.Right
    valLbl.Text                   = tostring(defV)

    local trackBg = Instance.new("Frame", frame)
    trackBg.Size             = UDim2.new(1, -16, 0, 5)
    trackBg.Position         = UDim2.new(0, 8, 0, 38)
    trackBg.BackgroundColor3 = C.TRACK
    trackBg.BorderSizePixel  = 0
    corner(trackBg, 3)

    local fill = Instance.new("Frame", trackBg)
    fill.Size             = UDim2.new((defV - minV) / (maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = C.FILL
    fill.BorderSizePixel  = 0
    corner(fill, 3)

    local knob = Instance.new("TextButton", trackBg)
    knob.Size             = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint      = Vector2.new(0.5, 0.5)
    knob.Position         = UDim2.new((defV - minV) / (maxV - minV), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Text             = ""
    knob.BorderSizePixel  = 0
    knob.AutoButtonColor  = false
    corner(knob, 14)

    local dragging = false
    local function update(absX)
        local r = math.clamp((absX - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
        local v = math.round(minV + r * (maxV - minV))
        fill.Size     = UDim2.new(r, 0, 1, 0)
        knob.Position = UDim2.new(r, 0, 0.5, 0)
        valLbl.Text   = tostring(v)
        if cb then cb(v) end
    end

    knob.MouseButton1Down:Connect(function() dragging = true end)
    trackBg.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; update(i.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            update(i.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    return frame
end

local function sMakeButton(labelText, cb)
    local btn = Instance.new("TextButton", sorterPage)
    btn.Size             = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = C.BTN
    btn.Text             = labelText
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.TextColor3       = C.TEXT
    btn.BorderSizePixel  = 0
    btn.AutoButtonColor  = false
    corner(btn, 8)
    stroke(btn, Color3.fromRGB(55, 55, 55), 1, 0)
    btn.MouseEnter:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN_HV}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN}):Play()
    end)
    if cb then btn.MouseButton1Click:Connect(cb) end
    return btn
end

-- ════════════════════════════════════════════════════
-- SORTER STATE
-- ════════════════════════════════════════════════════

local clickSelectEnabled = false
local lassoEnabled       = false
local groupSelectEnabled = false
local isSorting          = false
local stopSorting        = false
local previewPart        = nil
local previewLocked      = false
local previewConn        = nil
local previewClickConn   = nil

local dimX    = 3
local dimY    = 1
local dimZ    = 3
local spacing = 4

-- ════════════════════════════════════════════════════
-- SELECTION HELPERS
-- ════════════════════════════════════════════════════

local function selectPart(part)
    if not part then return end
    if part:FindFirstChild("SorterSelection") then return end
    local sb = Instance.new("SelectionBox", part)
    sb.Name                = "SorterSelection"
    sb.Adornee             = part
    sb.SurfaceTransparency = 0.5
    sb.LineThickness       = 0.09
    sb.SurfaceColor3       = Color3.fromRGB(0, 0, 0)
    sb.Color3              = Color3.fromRGB(180, 180, 180)
end

local function deselectPart(part)
    if not part then return end
    local s = part:FindFirstChild("SorterSelection")
    if s then s:Destroy() end
end

local function deselectAll()
    if not workspace:FindFirstChild("PlayerModels") then return end
    for _, v in pairs(workspace.PlayerModels:GetChildren()) do
        if v:FindFirstChild("Main") and v.Main:FindFirstChild("SorterSelection") then
            v.Main.SorterSelection:Destroy()
        end
        if v:FindFirstChild("WoodSection") and v.WoodSection:FindFirstChild("SorterSelection") then
            v.WoodSection.SorterSelection:Destroy()
        end
    end
end

local function trySelect(target)
    if not target then return end
    local par = target.Parent
    if not par then return end
    if not par:FindFirstChild("Owner") then return end
    if par:FindFirstChild("Main") then
        local tPart = par.Main
        if target == tPart or target:IsDescendantOf(tPart) then
            if tPart:FindFirstChild("SorterSelection") then deselectPart(tPart) else selectPart(tPart) end
            return
        end
    end
    if par:FindFirstChild("WoodSection") then
        local tPart = par.WoodSection
        if target == tPart or target:IsDescendantOf(tPart) then
            if tPart:FindFirstChild("SorterSelection") then deselectPart(tPart) else selectPart(tPart) end
            return
        end
    end
    local model = target:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChild("Owner") then
        if model:FindFirstChild("Main") then
            local p = model.Main
            if p:FindFirstChild("SorterSelection") then deselectPart(p) else selectPart(p) end
        elseif model:FindFirstChild("WoodSection") then
            local p = model.WoodSection
            if p:FindFirstChild("SorterSelection") then deselectPart(p) else selectPart(p) end
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
    local clickedOwner = model.Owner.Value
    local iv           = model:FindFirstChild("ItemName")
    local groupName    = iv and iv.Value or model.Name
    if not workspace:FindFirstChild("PlayerModels") then return end
    for _, v in pairs(workspace.PlayerModels:GetChildren()) do
        local vOwner = v:FindFirstChild("Owner")
        if vOwner and vOwner.Value == clickedOwner then
            local viv   = v:FindFirstChild("ItemName")
            local vName = viv and viv.Value or v.Name
            if vName == groupName then
                if v:FindFirstChild("Main")        then selectPart(v.Main) end
                if v:FindFirstChild("WoodSection") then selectPart(v.WoodSection) end
            end
        end
    end
end

local function getSelectedParts()
    local parts = {}
    if not workspace:FindFirstChild("PlayerModels") then return parts end
    for _, v in next, workspace.PlayerModels:GetDescendants() do
        if v.Name == "SorterSelection" then
            local part = v.Parent
            if part and part.Parent then
                table.insert(parts, part)
            end
        end
    end
    return parts
end

-- ════════════════════════════════════════════════════
-- SORTER LASSO FRAME
-- ════════════════════════════════════════════════════

local gui = game.CoreGui:FindFirstChild("VanillaHub")

local sorterLasso = Instance.new("Frame", gui)
sorterLasso.Name                    = "SorterLassoRect"
sorterLasso.BackgroundColor3        = Color3.fromRGB(100, 100, 100)
sorterLasso.BackgroundTransparency  = 0.82
sorterLasso.BorderSizePixel         = 0
sorterLasso.Visible                 = false
sorterLasso.ZIndex                  = 21
local lassoStroke = Instance.new("UIStroke", sorterLasso)
lassoStroke.Color        = Color3.fromRGB(200, 200, 200)
lassoStroke.Thickness    = 1.5
lassoStroke.Transparency = 0

local function isInFrame(screenPos, frame)
    local xPos  = frame.AbsolutePosition.X
    local yPos  = frame.AbsolutePosition.Y
    local xSize = frame.AbsoluteSize.X
    local ySize = frame.AbsoluteSize.Y
    local c1 = screenPos.X >= xPos and screenPos.X <= xPos + xSize
    local c2 = screenPos.X <= xPos and screenPos.X >= xPos + xSize
    local c3 = screenPos.Y >= yPos and screenPos.Y <= yPos + ySize
    local c4 = screenPos.Y <= yPos and screenPos.Y >= yPos + ySize
    return (c1 and c3) or (c2 and c3) or (c1 and c4) or (c2 and c4)
end

-- ════════════════════════════════════════════════════
-- NETWORK OWNER CHECK
-- ════════════════════════════════════════════════════

local function isNetworkOwner(part)
    return part.ReceiveAge == 0
end

-- ════════════════════════════════════════════════════
-- SORTER UI — SorterTab
-- ════════════════════════════════════════════════════

sSectionLabel("Selection")

sMakeToggle("Click Select", false, function(val)
    clickSelectEnabled = val
    if val then lassoEnabled = false; groupSelectEnabled = false end
end)

sMakeToggle("Lasso Select", false, function(val)
    lassoEnabled = val
    if val then clickSelectEnabled = false; groupSelectEnabled = false end
end)

sMakeToggle("Group Select", false, function(val)
    groupSelectEnabled = val
    if val then clickSelectEnabled = false; lassoEnabled = false end
end)

sMakeButton("Deselect All", function()
    deselectAll()
end)

-- Selected count display
local countFrame = Instance.new("Frame", sorterPage)
countFrame.Size             = UDim2.new(1, 0, 0, 30)
countFrame.BackgroundColor3 = C.CARD
countFrame.BorderSizePixel  = 0
corner(countFrame, 8)
stroke(countFrame, C.SEP, 1, 0.4)

local countLbl = Instance.new("TextLabel", countFrame)
countLbl.Size                   = UDim2.new(1, -16, 1, 0)
countLbl.Position               = UDim2.new(0, 12, 0, 0)
countLbl.BackgroundTransparency = 1
countLbl.Font                   = Enum.Font.GothamSemibold
countLbl.TextSize               = 12
countLbl.TextColor3             = C.TEXT_MID
countLbl.TextXAlignment         = Enum.TextXAlignment.Left
countLbl.Text                   = "Selected: 0 items"

local countConn = RS_Run.Heartbeat:Connect(function()
    if not (countLbl and countLbl.Parent) then return end
    countLbl.Text = "Selected: " .. #getSelectedParts() .. " items"
end)
table.insert(VH.cleanupTasks, function()
    if countConn then countConn:Disconnect(); countConn = nil end
end)

sSep()

-- SECTION: DIMENSIONS
sSectionLabel("Grid Dimensions")

local dimInfoFrame = Instance.new("Frame", sorterPage)
dimInfoFrame.Size             = UDim2.new(1, 0, 0, 30)
dimInfoFrame.BackgroundColor3 = C.CARD
dimInfoFrame.BorderSizePixel  = 0
corner(dimInfoFrame, 8)
stroke(dimInfoFrame, C.SEP, 1, 0.4)

local dimInfoLbl = Instance.new("TextLabel", dimInfoFrame)
dimInfoLbl.Size                   = UDim2.new(1, -16, 1, 0)
dimInfoLbl.Position               = UDim2.new(0, 12, 0, 0)
dimInfoLbl.BackgroundTransparency = 1
dimInfoLbl.Font                   = Enum.Font.GothamSemibold
dimInfoLbl.TextSize               = 12
dimInfoLbl.TextColor3             = C.TEXT_MID
dimInfoLbl.TextXAlignment         = Enum.TextXAlignment.Left
dimInfoLbl.Text                   = "Capacity: 9 slots   |   Spacing: 4 studs"

local function updateDimInfo()
    local capacity = dimX * dimY * dimZ
    dimInfoLbl.Text = "Capacity: " .. capacity .. " slots   |   Spacing: " .. spacing .. " studs"
end

sMakeSlider("X (width)",  1, 20, dimX, function(v) dimX = v; updateDimInfo() end)
sMakeSlider("Y (height)", 1, 10, dimY, function(v) dimY = v; updateDimInfo() end)
sMakeSlider("Z (depth)",  1, 20, dimZ, function(v) dimZ = v; updateDimInfo() end)
sMakeSlider("Spacing (studs)", 2, 12, spacing, function(v) spacing = v; updateDimInfo() end)

sSep()

-- SECTION: PREVIEW AND SORT
sSectionLabel("Preview")

-- Capacity warning
local warnFrame = Instance.new("Frame", sorterPage)
warnFrame.Size             = UDim2.new(1, 0, 0, 30)
warnFrame.BackgroundColor3 = Color3.fromRGB(30, 18, 18)
warnFrame.BorderSizePixel  = 0
warnFrame.Visible          = false
corner(warnFrame, 8)
local warnStroke = Instance.new("UIStroke", warnFrame)
warnStroke.Color = Color3.fromRGB(100, 40, 40); warnStroke.Thickness = 1; warnStroke.Transparency = 0

local warnLbl = Instance.new("TextLabel", warnFrame)
warnLbl.Size                   = UDim2.new(1, -16, 1, 0)
warnLbl.Position               = UDim2.new(0, 12, 0, 0)
warnLbl.BackgroundTransparency = 1
warnLbl.Font                   = Enum.Font.GothamSemibold
warnLbl.TextSize               = 12
warnLbl.TextColor3             = Color3.fromRGB(210, 100, 100)
warnLbl.TextXAlignment         = Enum.TextXAlignment.Left
warnLbl.Text                   = "Not enough capacity for selected items."

local previewBtn = sMakeButton("Load Preview", nil)
local startBtn   = sMakeButton("Start", nil)

local function setButtonEnabled(btn, enabled)
    TS:Create(btn, TweenInfo.new(0.18), {
        BackgroundColor3 = enabled and C.BTN or Color3.fromRGB(8, 8, 8),
        TextColor3       = enabled and C.TEXT or C.TEXT_DIM,
    }):Play()
    btn.Active = enabled
end

setButtonEnabled(previewBtn, false)
setButtonEnabled(startBtn,   false)

local lastCapOK = false
local capCheckConn = RS_Run.Heartbeat:Connect(function()
    if not (warnFrame and warnFrame.Parent) then return end
    local count    = #getSelectedParts()
    local capacity = dimX * dimY * dimZ
    local ok       = count > 0 and count <= capacity and not isSorting
    if ok ~= lastCapOK then
        lastCapOK         = ok
        warnFrame.Visible = (count > 0 and count > capacity)
        setButtonEnabled(previewBtn, ok)
        setButtonEnabled(startBtn,   ok)
    end
end)
table.insert(VH.cleanupTasks, function()
    if capCheckConn then capCheckConn:Disconnect(); capCheckConn = nil end
end)

-- ════════════════════════════════════════════════════
-- PREVIEW LOGIC
-- ════════════════════════════════════════════════════

local function clearPreview()
    previewLocked = false
    if previewConn then previewConn:Disconnect(); previewConn = nil end
    if previewClickConn then previewClickConn:Disconnect(); previewClickConn = nil end
    if previewPart and previewPart.Parent then previewPart:Destroy() end
    previewPart     = nil
    previewBtn.Text = "Load Preview"
end

table.insert(VH.cleanupTasks, clearPreview)

local function buildPreviewPart()
    local p        = Instance.new("Part")
    p.Name         = "VanillaHubSorterPreview"
    p.Anchored     = true
    p.CanCollide   = false
    p.CastShadow   = false
    p.Material     = Enum.Material.SmoothPlastic
    p.Color        = Color3.fromRGB(130, 130, 145)
    p.Transparency = 0.65
    p.Size         = Vector3.new(dimX * spacing, dimY * spacing, dimZ * spacing)
    local sel = Instance.new("SelectionBox")
    sel.Adornee             = p
    sel.Color3              = Color3.fromRGB(200, 200, 200)
    sel.SurfaceColor3       = Color3.fromRGB(0, 0, 0)
    sel.SurfaceTransparency = 1
    sel.LineThickness       = 0.08
    sel.Parent              = p
    p.Parent = workspace
    return p
end

local function getMouseWorldPos()
    local unitRay = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
    local params  = RaycastParams.new()
    params.FilterDescendantsInstances = previewPart and {previewPart} or {}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 2000, params)
    if result then return result.Position end
    return unitRay.Origin + unitRay.Direction * 50
end

previewBtn.MouseButton1Click:Connect(function()
    if not previewBtn.Active then return end
    if previewPart then clearPreview(); return end

    previewPart   = buildPreviewPart()
    previewLocked = false
    previewBtn.Text = "Clear Preview"

    previewConn = RS_Run.RenderStepped:Connect(function()
        if not previewPart or not previewPart.Parent then return end
        if previewLocked then return end
        local pos = getMouseWorldPos()
        local halfY = (dimY * spacing) / 2
        previewPart.CFrame = CFrame.new(pos + Vector3.new(0, halfY, 0))
    end)

    previewClickConn = Mouse.Button1Down:Connect(function()
        if not previewPart or not previewPart.Parent then return end
        previewLocked = not previewLocked
    end)
end)

-- ════════════════════════════════════════════════════
-- SORT LOGIC
-- ════════════════════════════════════════════════════

local function buildSlotPositions(origin)
    local slots = {}
    for yi = 1, dimY do
        for zi = 1, dimZ do
            for xi = 1, dimX do
                table.insert(slots, origin + Vector3.new(
                    (xi - 0.5) * spacing,
                    (yi - 0.5) * spacing,
                    (zi - 0.5) * spacing
                ))
            end
        end
    end
    return slots
end

startBtn.MouseButton1Click:Connect(function()
    if not startBtn.Active and not isSorting then return end

    if isSorting then
        stopSorting = true
        return
    end

    if not (previewPart and previewPart.Parent) then
        warnLbl.Text      = "Load and place the preview first."
        warnFrame.Visible = true
        task.delay(3, function()
            if warnFrame and warnFrame.Parent then
                warnFrame.Visible = false
                warnLbl.Text      = "Not enough capacity for selected items."
            end
        end)
        return
    end

    local selectedParts = getSelectedParts()
    if #selectedParts == 0 then return end

    isSorting   = true
    stopSorting = false

    startBtn.Text = "Abort"
    TS:Create(startBtn, TweenInfo.new(0.2), {BackgroundColor3 = C.ACTIVE}):Play()

    local previewCF      = previewPart.CFrame
    local gridOriginWorld = previewCF.Position
        - Vector3.new(dimX * spacing / 2, dimY * spacing / 2, dimZ * spacing / 2)

    local slots   = buildSlotPositions(gridOriginWorld)
    local char    = LP.Character
    local hrp     = char and char:FindFirstChild("HumanoidRootPart")
    local oldPos  = hrp and hrp.CFrame
    local tpDelay = 0.3

    task.spawn(function()
        for i, part in ipairs(selectedParts) do
            if stopSorting then break end
            local targetPos = slots[i]
            if not targetPos then break end

            local freshHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if freshHrp then
                freshHrp.CFrame = CFrame.new(part.CFrame.p) * CFrame.new(5, 0, 0)
            end
            task.wait(tpDelay)
            if stopSorting then break end

            pcall(function()
                if not part.Parent.PrimaryPart then
                    part.Parent.PrimaryPart = part
                end
                local dragger = ReplicatedStorage:FindFirstChild("Interaction")
                    and ReplicatedStorage.Interaction:FindFirstChild("ClientIsDragging")
                local timeout = 0
                while not isNetworkOwner(part) and timeout < 3 do
                    if dragger then dragger:FireServer(part.Parent) end
                    task.wait(0.05)
                    timeout = timeout + 0.05
                end
                if dragger then dragger:FireServer(part.Parent) end
                part:PivotTo(CFrame.new(targetPos))
            end)

            task.wait(tpDelay)
        end

        local restoreHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if oldPos and restoreHrp then restoreHrp.CFrame = oldPos end

        isSorting   = false
        stopSorting = false

        startBtn.Text = "Start"
        TS:Create(startBtn, TweenInfo.new(0.2), {BackgroundColor3 = C.BTN}):Play()

        clearPreview()
    end)
end)

-- ════════════════════════════════════════════════════
-- INPUT EVENTS (lasso + click/group select)
-- ════════════════════════════════════════════════════

UIS.InputBegan:Connect(function(input)
    if not lassoEnabled then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not workspace:FindFirstChild("PlayerModels") then return end

    sorterLasso.Visible  = true
    sorterLasso.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)
    sorterLasso.Size     = UDim2.new(0, 0, 0, 0)

    while UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
        RS_Run.RenderStepped:Wait()
        sorterLasso.Size = UDim2.new(0, Mouse.X, 0, Mouse.Y) - sorterLasso.Position
        for _, v in pairs(workspace.PlayerModels:GetChildren()) do
            if v:FindFirstChild("Main") then
                local sp, vis = Camera:WorldToScreenPoint(v.Main.CFrame.p)
                if vis and isInFrame(sp, sorterLasso) then selectPart(v.Main) end
            end
            if v:FindFirstChild("WoodSection") then
                local sp, vis = Camera:WorldToScreenPoint(v.WoodSection.CFrame.p)
                if vis and isInFrame(sp, sorterLasso) then selectPart(v.WoodSection) end
            end
        end
    end

    sorterLasso.Size    = UDim2.new(0, 1, 0, 1)
    sorterLasso.Visible = false
end)

Mouse.Button1Up:Connect(function()
    if lassoEnabled then return end
    if clickSelectEnabled then
        trySelect(Mouse.Target)
    elseif groupSelectEnabled then
        tryGroupSelect(Mouse.Target)
    end
end)

-- ════════════════════════════════════════════════════
-- CLEANUP (combined)
-- ════════════════════════════════════════════════════

table.insert(VH.cleanupTasks, function()
    -- Vehicle
    abortSpawner = true
    NOFLY()
    -- Sorter
    stopSorting = true
    isSorting   = false
    deselectAll()
    clearPreview()
    if sorterLasso and sorterLasso.Parent then
        sorterLasso:Destroy()
    end
end)

print("[VanillaHub] Vanilla7_Vehicle loaded (Vehicle + Spawner + Sorter)")
