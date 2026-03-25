-- VanillaHub | Vanilla7_Vehicle.lua
-- Vehicle (Section 1) + Spawner (Section 2) + Sorter (Section 3).
-- Requires Vanilla1 (_G.VH) to already be loaded.

if not _G.VH then
    warn("[VanillaHub] Vanilla7: _G.VH not found. Load Vanilla1 first.")
    return
end

local VH               = _G.VH
local TS               = VH.TweenService
local Players          = VH.Players
local UserInputService = VH.UserInputService
local RunService       = VH.RunService
local LP               = Players.LocalPlayer
local Mouse            = LP:GetMouse()
local RS               = game:GetService("ReplicatedStorage")
local Camera           = workspace.CurrentCamera

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
    SEP        = Color3.fromRGB(50,  50,  50),
    SECTION    = Color3.fromRGB(130, 130, 130),
    SW_ON      = Color3.fromRGB(230, 230, 230),
    SW_OFF     = Color3.fromRGB(55,  55,  55),
    SW_KNOB_ON = Color3.fromRGB(30,  30,  30),
    SW_KNOB_OFF= Color3.fromRGB(160, 160, 160),
}

local pages = VH.pages

-- ════════════════════════════════════════════════════
-- SHARED UI HELPERS
-- ════════════════════════════════════════════════════

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
end

local function sectionLabel(page, text)
    local w = Instance.new("Frame", page)
    w.Size = UDim2.new(1, 0, 0, 24)
    w.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", w)
    lbl.Size               = UDim2.new(1, -4, 1, 0)
    lbl.Position           = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 10
    lbl.TextColor3         = C.SECTION
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = "  " .. string.upper(text)
end

local function makeButton(page, text, cb)
    local btn = Instance.new("TextButton", page)
    btn.Size             = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = C.BTN
    btn.BorderSizePixel  = 0
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.TextColor3       = C.TEXT
    btn.Text             = text
    btn.AutoButtonColor  = false
    corner(btn, 8)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color        = Color3.fromRGB(55, 55, 55)
    stroke.Thickness    = 1
    stroke.Transparency = 0
    btn.MouseEnter:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN_HV}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN}):Play()
    end)
    if cb then btn.MouseButton1Click:Connect(function() task.spawn(cb) end) end
    return btn
end

local function makeSlider(page, labelText, minVal, maxVal, defaultVal, cb)
    local TRACK_H  = 4
    local THUMB_SZ = 14
    local ROW_H    = 46

    local outer = Instance.new("Frame", page)
    outer.Size             = UDim2.new(1, 0, 0, ROW_H)
    outer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
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
        if cb then cb(currentVal) end
    end

    local function updateFromMouse()
        local relX = UserInputService:GetMouseLocation().X - trackOuter.AbsolutePosition.X
        local pct  = math.clamp(relX / trackOuter.AbsoluteSize.X, 0, 1)
        setValue(minVal + pct * (maxVal - minVal))
    end

    hitbox.MouseButton1Down:Connect(function()
        dragging = true
        updateFromMouse()
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromMouse()
        end
    end)

    setValue(defaultVal)
    return outer, function() return currentVal end
end

local function makeToggle(page, labelText, defaultVal, cb)
    local ROW_H  = 36
    local TRACK_W = 36
    local TRACK_H = 20
    local KNOB_SZ = 14

    local outer = Instance.new("Frame", page)
    outer.Size             = UDim2.new(1, 0, 0, ROW_H)
    outer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    outer.BorderSizePixel  = 0
    corner(outer, 8)

    local lbl = Instance.new("TextLabel", outer)
    lbl.Size               = UDim2.new(1, -(TRACK_W + 24), 1, 0)
    lbl.Position           = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamSemibold
    lbl.TextSize           = 13
    lbl.TextColor3         = C.TEXT
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = labelText

    local track = Instance.new("TextButton", outer)
    track.Size             = UDim2.new(0, TRACK_W, 0, TRACK_H)
    track.Position         = UDim2.new(1, -(TRACK_W + 10), 0.5, -TRACK_H/2)
    track.BackgroundColor3 = defaultVal and C.SW_ON or C.SW_OFF
    track.Text             = ""
    track.BorderSizePixel  = 0
    track.AutoButtonColor  = false
    corner(track, TRACK_H)

    local knob = Instance.new("Frame", track)
    knob.Size             = UDim2.new(0, KNOB_SZ, 0, KNOB_SZ)
    knob.Position         = defaultVal
        and UDim2.new(1, -(KNOB_SZ + 2), 0.5, -KNOB_SZ/2)
        or  UDim2.new(0, 2, 0.5, -KNOB_SZ/2)
    knob.BackgroundColor3 = defaultVal and C.SW_KNOB_ON or C.SW_KNOB_OFF
    knob.BorderSizePixel  = 0
    corner(knob, KNOB_SZ)

    local state = defaultVal
    track.MouseButton1Click:Connect(function()
        state = not state
        TS:Create(track, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
            BackgroundColor3 = state and C.SW_ON or C.SW_OFF
        }):Play()
        TS:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
            Position = state
                and UDim2.new(1, -(KNOB_SZ + 2), 0.5, -KNOB_SZ/2)
                or  UDim2.new(0, 2, 0.5, -KNOB_SZ/2),
            BackgroundColor3 = state and C.SW_KNOB_ON or C.SW_KNOB_OFF
        }):Play()
        if cb then cb(state) end
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
    outer.Size             = UDim2.new(1, 0, 0, HEADER_H)
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
    arrowLbl.Text           = "v"
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
        if cb then cb(name) end
    end

    local function buildList()
        for _, c in ipairs(listScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
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
                arrowLbl.Text = "v"
                TS:Create(outer,      TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, HEADER_H)}):Play()
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
        arrowLbl.Text = "^"
        TS:Create(outer,      TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, HEADER_H + 2 + listH)}):Play()
        TS:Create(listScroll, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, listH)}):Play()
    end
    local function closeList()
        isOpen = false
        arrowLbl.Text = "v"
        TS:Create(outer,      TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, HEADER_H)}):Play()
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
    }
end

local function makeStatus(page, initText)
    local f = Instance.new("Frame", page)
    f.Size             = UDim2.new(1, 0, 0, 28)
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
        SetText = function(msg)
            lb.Text = msg
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
            seat.CFrame                         = CFRAME
            car.RightSteer.Wheel.CFrame         = CFRAME
            car.LeftSteer.Wheel.CFrame          = CFRAME
            car.RightPower.Wheel.CFrame         = CFRAME
            car.LeftPower.Wheel.CFrame          = CFRAME
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
                spawnStat.SetActive(false, "Spawned  -  " .. color)
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
-- SORTER — SHARED HELPERS
-- ════════════════════════════════════════════════════

local function selectPart(part)
    if not part then return end
    if part:FindFirstChild("VHSorterSel") then return end
    local sb = Instance.new("SelectionBox", part)
    sb.Name               = "VHSorterSel"
    sb.Adornee            = part
    sb.SurfaceTransparency = 0.5
    sb.LineThickness      = 0.09
    sb.SurfaceColor3      = Color3.fromRGB(0, 0, 0)
    sb.Color3             = Color3.fromRGB(180, 180, 180)
end

local function deselectPart(part)
    if not part then return end
    local s = part:FindFirstChild("VHSorterSel")
    if s then s:Destroy() end
end

local function sorterDeselectAll()
    if not workspace:FindFirstChild("PlayerModels") then return end
    for _, v in pairs(workspace.PlayerModels:GetChildren()) do
        if v:FindFirstChild("Main") then deselectPart(v.Main) end
        if v:FindFirstChild("WoodSection") then deselectPart(v.WoodSection) end
    end
end

local function getSelectedParts()
    local result = {}
    if not workspace:FindFirstChild("PlayerModels") then return result end
    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
        if v.Name == "VHSorterSel" then
            local part = v.Parent
            if part and part.Parent then
                table.insert(result, part)
            end
        end
    end
    return result
end

local function getSelectionCount()
    return #getSelectedParts()
end

local function tryClickSelect(target)
    if not target then return end
    local par = target.Parent; if not par then return end
    if not par:FindFirstChild("Owner") then return end
    if par:FindFirstChild("Main") then
        local tPart = par.Main
        if target == tPart or target:IsDescendantOf(tPart) then
            if tPart:FindFirstChild("VHSorterSel") then deselectPart(tPart) else selectPart(tPart) end
            return
        end
    end
    if par:FindFirstChild("WoodSection") then
        local tPart = par.WoodSection
        if target == tPart or target:IsDescendantOf(tPart) then
            if tPart:FindFirstChild("VHSorterSel") then deselectPart(tPart) else selectPart(tPart) end
            return
        end
    end
    local model = target:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChild("Owner") then
        if model:FindFirstChild("Main") then
            local p = model.Main
            if p:FindFirstChild("VHSorterSel") then deselectPart(p) else selectPart(p) end
        elseif model:FindFirstChild("WoodSection") then
            local p = model.WoodSection
            if p:FindFirstChild("VHSorterSel") then deselectPart(p) else selectPart(p) end
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
                if v:FindFirstChild("Main") then selectPart(v.Main) end
                if v:FindFirstChild("WoodSection") then selectPart(v.WoodSection) end
            end
        end
    end
end

local function isnetworkowner(part)
    return part.ReceiveAge == 0
end

-- ════════════════════════════════════════════════════
-- SORTER UI — Section 3
-- ════════════════════════════════════════════════════

local sp = pages["SorterTab"]
local spList = sp:FindFirstChildOfClass("UIListLayout")
if spList then spList.Padding = UDim.new(0, 8) end

-- State
local sorterClickSelect  = false
local sorterLassoEnabled = false
local sorterGroupSelect  = false
local sorterAbort        = false
local sorterRunning      = false

local sorterGridX = 3
local sorterGridY = 3
local sorterGridZ = 3

local previewBox      = nil
local previewLocked   = false
local previewConn     = nil
local previewClickConn = nil

-- Lasso frame (reuse gui root)
local gui = sp:FindFirstAncestorOfClass("ScreenGui")
local sorterLassoFrame = Instance.new("Frame", gui)
sorterLassoFrame.Name                 = "VHSorterLasso"
sorterLassoFrame.BackgroundColor3     = Color3.fromRGB(100, 100, 100)
sorterLassoFrame.BackgroundTransparency = 0.82
sorterLassoFrame.BorderSizePixel      = 0
sorterLassoFrame.Visible              = false
sorterLassoFrame.ZIndex               = 20
local sorterLassoStroke = Instance.new("UIStroke", sorterLassoFrame)
sorterLassoStroke.Color       = Color3.fromRGB(200, 200, 200)
sorterLassoStroke.Thickness   = 1.5
sorterLassoStroke.Transparency = 0

local function is_in_frame(screenpos, frame)
    local xPos  = frame.AbsolutePosition.X
    local yPos  = frame.AbsolutePosition.Y
    local xSize = frame.AbsoluteSize.X
    local ySize = frame.AbsoluteSize.Y
    local c1 = screenpos.X >= xPos and screenpos.X <= xPos + xSize
    local c2 = screenpos.X <= xPos and screenpos.X >= xPos + xSize
    local c3 = screenpos.Y >= yPos and screenpos.Y <= yPos + ySize
    local c4 = screenpos.Y <= yPos and screenpos.Y >= yPos + ySize
    return (c1 and c3) or (c2 and c3) or (c1 and c4) or (c2 and c4)
end

-- Selection input handling
local sorterLassoConn = UserInputService.InputBegan:Connect(function(input)
    if not sorterLassoEnabled then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not workspace:FindFirstChild("PlayerModels") then return end
    sorterLassoFrame.Visible  = true
    sorterLassoFrame.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)
    sorterLassoFrame.Size     = UDim2.new(0, 0, 0, 0)
    while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
        RunService.RenderStepped:Wait()
        sorterLassoFrame.Size = UDim2.new(0, Mouse.X, 0, Mouse.Y) - sorterLassoFrame.Position
        for _, v in pairs(workspace.PlayerModels:GetChildren()) do
            if v:FindFirstChild("Main") then
                local screenPos, vis = Camera:WorldToScreenPoint(v.Main.CFrame.p)
                if vis and is_in_frame(screenPos, sorterLassoFrame) then selectPart(v.Main) end
            end
            if v:FindFirstChild("WoodSection") then
                local screenPos, vis = Camera:WorldToScreenPoint(v.WoodSection.CFrame.p)
                if vis and is_in_frame(screenPos, sorterLassoFrame) then selectPart(v.WoodSection) end
            end
        end
    end
    sorterLassoFrame.Size    = UDim2.new(0, 1, 0, 1)
    sorterLassoFrame.Visible = false
end)

local sorterClickConn = Mouse.Button1Up:Connect(function()
    if sorterLassoEnabled then return end
    if sorterClickSelect then
        tryClickSelect(Mouse.Target)
    elseif sorterGroupSelect then
        tryGroupSelect(Mouse.Target)
    end
end)

-- Count label updater
local countLabel

local function updateCount()
    if countLabel then
        countLabel.Text = "Selected: " .. getSelectionCount()
    end
end

RunService.Heartbeat:Connect(function()
    updateCount()
end)

-- SECTION: Selection
sectionLabel(sp, "Selection")

-- Toggle helpers scoped to sorter page
local function sSectionLabel(text)
    local w = Instance.new("Frame", sp)
    w.Size = UDim2.new(1, 0, 0, 22)
    w.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", w)
    lbl.Size               = UDim2.new(1, -4, 1, 0)
    lbl.Position           = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 10
    lbl.TextColor3         = C.SECTION
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = "  " .. string.upper(text)
end

local function sToggle(labelText, defaultVal, cb)
    local ROW_H   = 36
    local TRACK_W = 36
    local TRACK_H = 20
    local KNOB_SZ = 14

    local outer = Instance.new("Frame", sp)
    outer.Size             = UDim2.new(1, 0, 0, ROW_H)
    outer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    outer.BorderSizePixel  = 0
    corner(outer, 8)

    local lbl = Instance.new("TextLabel", outer)
    lbl.Size               = UDim2.new(1, -(TRACK_W + 24), 1, 0)
    lbl.Position           = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamSemibold
    lbl.TextSize           = 13
    lbl.TextColor3         = C.TEXT
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = labelText

    local track = Instance.new("TextButton", outer)
    track.Size             = UDim2.new(0, TRACK_W, 0, TRACK_H)
    track.Position         = UDim2.new(1, -(TRACK_W + 10), 0.5, -TRACK_H/2)
    track.BackgroundColor3 = defaultVal and C.SW_ON or C.SW_OFF
    track.Text             = ""
    track.BorderSizePixel  = 0
    track.AutoButtonColor  = false
    corner(track, TRACK_H)

    local knob = Instance.new("Frame", track)
    knob.Size             = UDim2.new(0, KNOB_SZ, 0, KNOB_SZ)
    knob.Position         = defaultVal
        and UDim2.new(1, -(KNOB_SZ + 2), 0.5, -KNOB_SZ/2)
        or  UDim2.new(0, 2, 0.5, -KNOB_SZ/2)
    knob.BackgroundColor3 = defaultVal and C.SW_KNOB_ON or C.SW_KNOB_OFF
    knob.BorderSizePixel  = 0
    corner(knob, KNOB_SZ)

    local state = defaultVal
    local ref = {setValue = nil}

    local function apply(newState, silent)
        state = newState
        TS:Create(track, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
            BackgroundColor3 = state and C.SW_ON or C.SW_OFF
        }):Play()
        TS:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
            Position = state
                and UDim2.new(1, -(KNOB_SZ + 2), 0.5, -KNOB_SZ/2)
                or  UDim2.new(0, 2, 0.5, -KNOB_SZ/2),
            BackgroundColor3 = state and C.SW_KNOB_ON or C.SW_KNOB_OFF
        }):Play()
        if not silent and cb then cb(state) end
    end

    ref.setValue = apply

    track.MouseButton1Click:Connect(function()
        apply(not state)
    end)

    return outer, ref
end

local function sButton(text, cb)
    local btn = Instance.new("TextButton", sp)
    btn.Size             = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = C.BTN
    btn.BorderSizePixel  = 0
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.TextColor3       = C.TEXT
    btn.Text             = text
    btn.AutoButtonColor  = false
    corner(btn, 8)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color        = Color3.fromRGB(55, 55, 55)
    stroke.Thickness    = 1
    stroke.Transparency = 0
    btn.MouseEnter:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN_HV}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN}):Play()
    end)
    if cb then btn.MouseButton1Click:Connect(function() task.spawn(cb) end) end
    return btn
end

local function sSep()
    local sep = Instance.new("Frame", sp)
    sep.Size             = UDim2.new(1, 0, 0, 1)
    sep.BackgroundColor3 = C.SEP
    sep.BorderSizePixel  = 0
end

local function sSlider(labelText, minVal, maxVal, defaultVal, cb)
    local TRACK_H  = 4
    local THUMB_SZ = 14
    local ROW_H    = 46

    local outer = Instance.new("Frame", sp)
    outer.Size             = UDim2.new(1, 0, 0, ROW_H)
    outer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
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
        currentVal     = math.clamp(math.round(v), minVal, maxVal)
        local pct      = (currentVal - minVal) / (maxVal - minVal)
        fill.Size      = UDim2.new(pct, 0, 1, 0)
        thumb.Position = UDim2.new(pct, -THUMB_SZ/2, 0.5, -THUMB_SZ/2)
        valLbl.Text    = tostring(currentVal)
        if cb then cb(currentVal) end
    end

    local function updateFromMouse()
        local relX = UserInputService:GetMouseLocation().X - trackOuter.AbsolutePosition.X
        local pct  = math.clamp(relX / trackOuter.AbsoluteSize.X, 0, 1)
        setValue(minVal + pct * (maxVal - minVal))
    end

    hitbox.MouseButton1Down:Connect(function()
        dragging = true
        updateFromMouse()
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromMouse()
        end
    end)

    setValue(defaultVal)
    return outer
end

-- Toggle rows
local _, clickRef  = sToggle("Click Select",  false, function(val)
    sorterClickSelect  = val
    if val then sorterLassoEnabled = false; sorterGroupSelect = false end
end)
local _, lassoRef  = sToggle("Lasso Select",  false, function(val)
    sorterLassoEnabled = val
    if val then sorterClickSelect = false; sorterGroupSelect = false end
end)
local _, groupRef  = sToggle("Group Select",  false, function(val)
    sorterGroupSelect = val
    if val then sorterClickSelect = false; sorterLassoEnabled = false end
end)

-- Count display
local countFrame = Instance.new("Frame", sp)
countFrame.Size             = UDim2.new(1, 0, 0, 28)
countFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
countFrame.BorderSizePixel  = 0
corner(countFrame, 7)
local countStroke = Instance.new("UIStroke", countFrame)
countStroke.Color = C.BORDER; countStroke.Thickness = 1; countStroke.Transparency = 0.4
countLabel = Instance.new("TextLabel", countFrame)
countLabel.Size               = UDim2.new(1, -16, 1, 0)
countLabel.Position           = UDim2.new(0, 10, 0, 0)
countLabel.BackgroundTransparency = 1
countLabel.Font               = Enum.Font.GothamSemibold
countLabel.TextSize           = 12
countLabel.TextColor3         = C.TEXT_MID
countLabel.TextXAlignment     = Enum.TextXAlignment.Left
countLabel.Text               = "Selected: 0"

sButton("Deselect All", function()
    sorterDeselectAll()
end)

sSep()

-- SECTION: Grid Dimensions
sSectionLabel("Grid Dimensions")

sSlider("X  (Width)",  1, 20, 3, function(val) sorterGridX = val end)
sSlider("Y  (Height)", 1, 20, 3, function(val) sorterGridY = val end)
sSlider("Z  (Depth)",  1, 20, 3, function(val) sorterGridZ = val end)

sSep()

-- SECTION: Preview + Sort
sSectionLabel("Sorting")

local sorterStatus = makeStatus(sp, "Configure grid, then load preview")

-- Helper: can the selected items fit in the grid?
local function canFitGrid()
    local count = getSelectionCount()
    return count > 0 and count <= (sorterGridX * sorterGridY * sorterGridZ)
end

-- Helper: destroy preview box
local function destroyPreview()
    if previewConn    then previewConn:Disconnect();      previewConn    = nil end
    if previewClickConn then previewClickConn:Disconnect(); previewClickConn = nil end
    if previewBox and previewBox.Parent then previewBox:Destroy() end
    previewBox    = nil
    previewLocked = false
end

-- Generate grid offsets (fills bottom layer first, then up)
local CELL_SIZE = 5  -- studs between item positions

local function getGridPositions(originCF)
    local positions = {}
    for y = 0, sorterGridY - 1 do
        for z = 0, sorterGridZ - 1 do
            for x = 0, sorterGridX - 1 do
                local offset = Vector3.new(x * CELL_SIZE, y * CELL_SIZE, z * CELL_SIZE)
                table.insert(positions, originCF + offset)
            end
        end
    end
    return positions
end

-- Build the visual preview adornment box
local function buildPreviewBox(cf)
    destroyPreview()
    previewLocked = false

    local sizeX = sorterGridX * CELL_SIZE
    local sizeY = sorterGridY * CELL_SIZE
    local sizeZ = sorterGridZ * CELL_SIZE

    local part = Instance.new("Part")
    part.Name        = "VHSorterPreview"
    part.Anchored    = true
    part.CanCollide  = false
    part.Transparency = 0.7
    part.Color       = Color3.fromRGB(180, 180, 180)
    part.Size        = Vector3.new(sizeX, sizeY, sizeZ)
    part.CFrame      = cf
    part.Material    = Enum.Material.SmoothPlastic
    part.Parent      = workspace

    local sel = Instance.new("SelectionBox", part)
    sel.Adornee            = part
    sel.SurfaceTransparency = 0.85
    sel.LineThickness      = 0.05
    sel.Color3             = Color3.fromRGB(200, 200, 200)
    sel.SurfaceColor3      = Color3.fromRGB(200, 200, 200)

    previewBox = part
    return part
end

-- Preview follow mouse
local function startPreviewFollow()
    if previewConn then previewConn:Disconnect() end
    previewConn = RunService.RenderStepped:Connect(function()
        if previewLocked then return end
        if not (previewBox and previewBox.Parent) then return end
        local unitRay = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
        local rayResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500,
            RaycastParams.new())
        local hitPos = rayResult and rayResult.Position
            or (unitRay.Origin + unitRay.Direction * 50)
        local sizeY = sorterGridY * CELL_SIZE
        previewBox.CFrame = CFrame.new(hitPos + Vector3.new(0, sizeY / 2, 0))
    end)

    if previewClickConn then previewClickConn:Disconnect() end
    previewClickConn = Mouse.Button1Up:Connect(function()
        if not (previewBox and previewBox.Parent) then return end
        if previewLocked then return end
        previewLocked = true
        TS:Create(previewBox, TweenInfo.new(0.15), {
            Color = Color3.fromRGB(130, 200, 130)
        }):Play()
        sorterStatus.SetText("Preview locked. Press Start to sort.")
    end)
end

-- Load Preview button
local loadPreviewBtn = sButton("Load Preview", function()
    if not canFitGrid() then
        local count = getSelectionCount()
        local cap   = sorterGridX * sorterGridY * sorterGridZ
        if count == 0 then
            sorterStatus.SetActive(false, "No items selected")
        else
            sorterStatus.SetActive(false, "Too many items (" .. count .. " > " .. cap .. ")")
        end
        return
    end
    destroyPreview()
    previewLocked = false
    buildPreviewBox(CFrame.new(0, 0, 0))
    startPreviewFollow()
    sorterStatus.SetText("Move mouse to place grid, then click to lock")
end)

-- Start / Abort button
local sortRunning = false
local sortAbort   = false
local startSortBtn

startSortBtn = sButton("Start", function()
    if sortRunning then
        sortAbort = true
        return
    end

    if not canFitGrid() then
        local count = getSelectionCount()
        local cap   = sorterGridX * sorterGridY * sorterGridZ
        if count == 0 then
            sorterStatus.SetActive(false, "No items selected")
        else
            sorterStatus.SetActive(false, "Too many items (" .. count .. " > " .. cap .. ")")
        end
        return
    end

    if not (previewBox and previewBox.Parent and previewLocked) then
        sorterStatus.SetActive(false, "Load and lock a preview first")
        return
    end

    sortRunning = true
    sortAbort   = false
    startSortBtn.Text = "Abort"
    TS:Create(startSortBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()

    local originCF    = previewBox.CFrame
    local sizeY       = sorterGridY * CELL_SIZE
    -- Shift origin to bottom-left corner of the box
    local bottomCorner = originCF - Vector3.new(
        (sorterGridX * CELL_SIZE) / 2,
        sizeY / 2,
        (sorterGridZ * CELL_SIZE) / 2
    )
    local positions   = getGridPositions(CFrame.new(bottomCorner.p))
    local parts       = getSelectedParts()
    local OldPos      = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        and LP.Character.HumanoidRootPart.CFrame

    destroyPreview()

    task.spawn(function()
        local dragger = RS:FindFirstChild("Interaction")
            and RS.Interaction:FindFirstChild("ClientIsDragging")

        for i, part in ipairs(parts) do
            if sortAbort then break end
            local targetCF = positions[i]
            if not targetCF then break end

            local char = LP.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(part.CFrame.p) * CFrame.new(5, 0, 0)
            end
            task.wait(0.15)

            if sortAbort then break end

            pcall(function()
                if not part.Parent.PrimaryPart then part.Parent.PrimaryPart = part end
                local timeout = 0
                while not isnetworkowner(part) and timeout < 3 do
                    if dragger then dragger:FireServer(part.Parent) end
                    task.wait(0.05); timeout = timeout + 0.05
                end
                if dragger then dragger:FireServer(part.Parent) end
                part:PivotTo(targetCF)
            end)

            sorterStatus.SetText("Sorting " .. i .. " / " .. #parts)
            task.wait(0.15)
        end

        if OldPos and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            LP.Character.HumanoidRootPart.CFrame = OldPos
        end

        if sortAbort then
            sorterStatus.SetActive(false, "Aborted")
        else
            sorterStatus.SetActive(false, "Sort complete")
        end

        sortRunning = false
        sortAbort   = false
        startSortBtn.Text = "Start"
        TS:Create(startSortBtn, TweenInfo.new(0.2), {BackgroundColor3 = C.BTN}):Play()
    end)
end)

-- ════════════════════════════════════════════════════
-- CLEANUP
-- ════════════════════════════════════════════════════
table.insert(VH.cleanupTasks, function()
    abortSpawner = true
    NOFLY()
    sortAbort = true
    destroyPreview()
    sorterDeselectAll()
    if sorterLassoConn  then sorterLassoConn:Disconnect()  end
    if sorterClickConn  then sorterClickConn:Disconnect()  end
    if sorterLassoFrame and sorterLassoFrame.Parent then sorterLassoFrame:Destroy() end
end)

print("[VanillaHub] Vanilla7_Vehicle loaded")
