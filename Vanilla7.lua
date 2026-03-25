-- VanillaHub | Vanilla7.lua
-- Vehicle Tab + Sorter Tab (Complete)
-- Requires Vanilla1 (_G.VH) to already be loaded.

if not _G.VH then
    warn("[VanillaHub] Vanilla7: _G.VH not found. Load Vanilla1 first.")
    return
end

local VH      = _G.VH
local TS      = VH.TweenService
local Players = VH.Players
local LP      = Players.LocalPlayer
local Mouse   = LP:GetMouse()
local RS      = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local C = {
    CARD     = Color3.fromRGB(10,  10,  10),
    ROW      = Color3.fromRGB(16,  16,  16),
    INPUT    = Color3.fromRGB(30,  30,  30),
    BORDER   = Color3.fromRGB(55,  55,  55),
    TEXT     = Color3.fromRGB(210, 210, 210),
    TEXT_MID = Color3.fromRGB(150, 150, 150),
    TEXT_DIM = Color3.fromRGB(90,  90,  90),
    BTN      = Color3.fromRGB(14,  14,  14),
    BTN_HV   = Color3.fromRGB(32,  32,  32),
    DOT_IDLE = Color3.fromRGB(70,  70,  70),
    DOT_ACT  = Color3.fromRGB(200, 200, 200),
    TRACK    = Color3.fromRGB(35,  35,  35),
    FILL     = Color3.fromRGB(190, 190, 190),
    TOGGLE_ON  = Color3.fromRGB(200, 200, 200),
    TOGGLE_OFF = Color3.fromRGB(50,  50,  50),
    PREVIEW    = Color3.fromRGB(100, 150, 200),
    PREVIEW_BORDER = Color3.fromRGB(150, 200, 255),
}

local pages = VH.pages

-- Clean existing Vehicle and Sorter tabs if they exist
if pages["VehicleTab"] then
    for _, child in ipairs(pages["VehicleTab"]:GetChildren()) do
        if child:IsA("Frame") or child:IsA("ScrollingFrame") then
            child:Destroy()
        end
    end
end

if pages["SorterTab"] then
    for _, child in ipairs(pages["SorterTab"]:GetChildren()) do
        if child:IsA("Frame") or child:IsA("ScrollingFrame") then
            child:Destroy()
        end
    end
end

-- ════════════════════════════════════════════════════
-- SHARED UI HELPERS
-- ════════════════════════════════════════════════════

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
end

local function sectionLabel(page, text)
    local lbl = Instance.new("TextLabel", page)
    lbl.Size = UDim2.new(1, -12, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextColor3 = C.TEXT_DIM
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    local pad = Instance.new("UIPadding", lbl)
    pad.PaddingLeft = UDim.new(0, 4)
end

local function makeButton(page, text, cb)
    local btn = Instance.new("TextButton", page)
    btn.Size = UDim2.new(1, -12, 0, 38)
    btn.BackgroundColor3 = C.BTN
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextColor3 = C.TEXT
    btn.Text = text
    btn.AutoButtonColor = false
    corner(btn, 8)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = C.BORDER
    stroke.Thickness = 1
    stroke.Transparency = 0
    btn.MouseEnter:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN_HV}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN}):Play()
    end)
    if cb then btn.MouseButton1Click:Connect(cb) end
    return btn
end

local function makeSlider(page, labelText, minVal, maxVal, defaultVal, cb)
    local TRACK_H = 4
    local THUMB_SZ = 14
    local ROW_H = 52

    local outer = Instance.new("Frame", page)
    outer.Size = UDim2.new(1, -12, 0, ROW_H)
    outer.BackgroundColor3 = C.ROW
    outer.BorderSizePixel = 0
    corner(outer, 8)
    local outerStroke = Instance.new("UIStroke", outer)
    outerStroke.Color = C.BORDER
    outerStroke.Thickness = 1
    outerStroke.Transparency = 0.4

    local lbl = Instance.new("TextLabel", outer)
    lbl.Size = UDim2.new(0.55, 0, 0, 22)
    lbl.Position = UDim2.new(0, 12, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextColor3 = C.TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = labelText

    local valLbl = Instance.new("TextLabel", outer)
    valLbl.Size = UDim2.new(0.4, -12, 0, 22)
    valLbl.Position = UDim2.new(0.6, 0, 0, 6)
    valLbl.BackgroundTransparency = 1
    valLbl.Font = Enum.Font.GothamSemibold
    valLbl.TextSize = 12
    valLbl.TextColor3 = C.TEXT_MID
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Text = tostring(defaultVal)

    local trackOuter = Instance.new("Frame", outer)
    trackOuter.Size = UDim2.new(1, -24, 0, TRACK_H)
    trackOuter.Position = UDim2.new(0, 12, 1, -14)
    trackOuter.BackgroundColor3 = C.TRACK
    trackOuter.BorderSizePixel = 0
    corner(trackOuter, 3)

    local fill = Instance.new("Frame", trackOuter)
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = C.FILL
    fill.BorderSizePixel = 0
    corner(fill, 3)

    local thumb = Instance.new("Frame", trackOuter)
    thumb.Size = UDim2.new(0, THUMB_SZ, 0, THUMB_SZ)
    thumb.Position = UDim2.new(0, -THUMB_SZ/2, 0.5, -THUMB_SZ/2)
    thumb.BackgroundColor3 = C.TEXT
    thumb.BorderSizePixel = 0
    corner(thumb, THUMB_SZ)

    local hitbox = Instance.new("TextButton", outer)
    hitbox.Size = UDim2.new(1, 0, 1, 0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text = ""
    hitbox.AutoButtonColor = false
    hitbox.ZIndex = 5

    local currentVal = defaultVal
    local dragging = false

    local function setValue(v)
        currentVal = math.clamp(math.round(v), minVal, maxVal)
        local pct = (currentVal - minVal) / (maxVal - minVal)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        thumb.Position = UDim2.new(pct, -THUMB_SZ/2, 0.5, -THUMB_SZ/2)
        valLbl.Text = tostring(currentVal)
        if cb then cb(currentVal) end
    end

    local function updateFromInput(input)
        local relX = input.Position.X - trackOuter.AbsolutePosition.X
        local pct = math.clamp(relX / trackOuter.AbsoluteSize.X, 0, 1)
        setValue(minVal + pct * (maxVal - minVal))
    end

    hitbox.MouseButton1Down:Connect(function()
        dragging = true
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromInput(input)
        end
    end)
    hitbox.MouseButton1Down:Connect(function(_, input)
        updateFromInput(UserInputService:GetMouseLocation() and
            {Position = UserInputService:GetMouseLocation()} or input)
    end)

    setValue(defaultVal)
    return outer
end

local function makeToggle(page, labelText, defaultVal, cb)
    local ROW_H = 44
    local TRACK_W = 38
    local TRACK_H = 20
    local KNOB_SZ = 14

    local outer = Instance.new("Frame", page)
    outer.Size = UDim2.new(1, -12, 0, ROW_H)
    outer.BackgroundColor3 = C.ROW
    outer.BorderSizePixel = 0
    corner(outer, 8)
    local outerStroke = Instance.new("UIStroke", outer)
    outerStroke.Color = C.BORDER
    outerStroke.Thickness = 1
    outerStroke.Transparency = 0.4

    local lbl = Instance.new("TextLabel", outer)
    lbl.Size = UDim2.new(1, -(TRACK_W + 24), 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextColor3 = C.TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = labelText

    local track = Instance.new("Frame", outer)
    track.Size = UDim2.new(0, TRACK_W, 0, TRACK_H)
    track.Position = UDim2.new(1, -(TRACK_W + 10), 0.5, -TRACK_H/2)
    track.BackgroundColor3 = defaultVal and C.TOGGLE_ON or C.TOGGLE_OFF
    track.BorderSizePixel = 0
    corner(track, TRACK_H)

    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0, KNOB_SZ, 0, KNOB_SZ)
    knob.Position = defaultVal
        and UDim2.new(1, -(KNOB_SZ + 3), 0.5, -KNOB_SZ/2)
        or UDim2.new(0, 3, 0.5, -KNOB_SZ/2)
    knob.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    knob.BorderSizePixel = 0
    corner(knob, KNOB_SZ)

    local hitbox = Instance.new("TextButton", outer)
    hitbox.Size = UDim2.new(1, 0, 1, 0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text = ""
    hitbox.AutoButtonColor = false
    hitbox.ZIndex = 5

    local state = defaultVal
    hitbox.MouseButton1Click:Connect(function()
        state = not state
        TS:Create(track, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
            BackgroundColor3 = state and C.TOGGLE_ON or C.TOGGLE_OFF
        }):Play()
        TS:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
            Position = state
                and UDim2.new(1, -(KNOB_SZ + 3), 0.5, -KNOB_SZ/2)
                or UDim2.new(0, 3, 0.5, -KNOB_SZ/2)
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
    outer.Size = UDim2.new(1, -12, 0, HEADER_H)
    outer.BackgroundColor3 = C.ROW
    outer.BorderSizePixel = 0
    outer.ClipsDescendants = true
    corner(outer, 8)
    local outerStroke = Instance.new("UIStroke", outer)
    outerStroke.Color = C.BORDER
    outerStroke.Thickness = 1
    outerStroke.Transparency = 0.4

    local header = Instance.new("Frame", outer)
    header.Size = UDim2.new(1, 0, 0, HEADER_H)
    header.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", header)
    lbl.Size = UDim2.new(0, 80, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextColor3 = C.TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local selFrame = Instance.new("Frame", header)
    selFrame.Size = UDim2.new(1, -96, 0, 28)
    selFrame.Position = UDim2.new(0, 90, 0.5, -14)
    selFrame.BackgroundColor3 = C.INPUT
    selFrame.BorderSizePixel = 0
    corner(selFrame, 6)
    local sfStroke = Instance.new("UIStroke", selFrame)
    sfStroke.Color = C.BORDER
    sfStroke.Thickness = 1
    sfStroke.Transparency = 0.3

    local selLbl = Instance.new("TextLabel", selFrame)
    selLbl.Size = UDim2.new(1, -36, 1, 0)
    selLbl.Position = UDim2.new(0, 10, 0, 0)
    selLbl.BackgroundTransparency = 1
    selLbl.Text = "Select..."
    selLbl.Font = Enum.Font.GothamSemibold
    selLbl.TextSize = 12
    selLbl.TextColor3 = C.TEXT_DIM
    selLbl.TextXAlignment = Enum.TextXAlignment.Left
    selLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local arrowLbl = Instance.new("TextLabel", selFrame)
    arrowLbl.Size = UDim2.new(0, 22, 1, 0)
    arrowLbl.Position = UDim2.new(1, -24, 0, 0)
    arrowLbl.BackgroundTransparency = 1
    arrowLbl.Text = "▲"
    arrowLbl.Font = Enum.Font.GothamBold
    arrowLbl.TextSize = 14
    arrowLbl.TextColor3 = C.TEXT_MID
    arrowLbl.TextXAlignment = Enum.TextXAlignment.Center

    local headerBtn = Instance.new("TextButton", selFrame)
    headerBtn.Size = UDim2.new(1, 0, 1, 0)
    headerBtn.BackgroundTransparency = 1
    headerBtn.Text = ""
    headerBtn.AutoButtonColor = false
    headerBtn.ZIndex = 5

    local divider = Instance.new("Frame", outer)
    divider.Size = UDim2.new(1, -16, 0, 1)
    divider.Position = UDim2.new(0, 8, 0, HEADER_H)
    divider.BackgroundColor3 = C.BORDER
    divider.BorderSizePixel = 0
    divider.Visible = false

    local listScroll = Instance.new("ScrollingFrame", outer)
    listScroll.Position = UDim2.new(0, 0, 0, HEADER_H + 2)
    listScroll.Size = UDim2.new(1, 0, 0, 0)
    listScroll.BackgroundTransparency = 1
    listScroll.BorderSizePixel = 0
    listScroll.ScrollBarThickness = 3
    listScroll.ScrollBarImageColor3 = C.BORDER
    listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    listScroll.ClipsDescendants = true

    local listLayout = Instance.new("UIListLayout", listScroll)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 3)
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 6)
    end)
    local listPad = Instance.new("UIPadding", listScroll)
    listPad.PaddingTop = UDim.new(0, 4)
    listPad.PaddingBottom = UDim.new(0, 4)
    listPad.PaddingLeft = UDim.new(0, 6)
    listPad.PaddingRight = UDim.new(0, 6)

    local function setSelected(name)
        selected = name
        selLbl.Text = name
        selLbl.TextColor3 = C.TEXT
        outerStroke.Color = C.BORDER
        cb(name)
    end

    local function buildList()
        for _, c in ipairs(listScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local opts = getOptions()
        for _, opt in ipairs(opts) do
            local item = Instance.new("TextButton", listScroll)
            item.Size = UDim2.new(1, 0, 0, ITEM_H)
            item.BackgroundColor3 = C.ROW
            item.Text = ""
            item.BorderSizePixel = 0
            item.AutoButtonColor = false
            corner(item, 6)
            local iLbl = Instance.new("TextLabel", item)
            iLbl.Size = UDim2.new(1, -16, 1, 0)
            iLbl.Position = UDim2.new(0, 10, 0, 0)
            iLbl.BackgroundTransparency = 1
            iLbl.Text = opt
            iLbl.Font = Enum.Font.GothamSemibold
            iLbl.TextSize = 12
            iLbl.TextColor3 = C.TEXT
            iLbl.TextXAlignment = Enum.TextXAlignment.Left
            iLbl.TextTruncate = Enum.TextTruncate.AtEnd
            item.MouseEnter:Connect(function()
                TS:Create(item, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
            end)
            item.MouseLeave:Connect(function()
                TS:Create(item, TweenInfo.new(0.1), {BackgroundColor3 = C.ROW}):Play()
            end)
            item.MouseButton1Click:Connect(function()
                setSelected(opt)
                isOpen = false
                TS:Create(arrowLbl, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
                TS:Create(outer, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1, -12, 0, HEADER_H)}):Play()
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
        TS:Create(arrowLbl, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation = 180}):Play()
        TS:Create(outer, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(1, -12, 0, HEADER_H + 2 + listH)}):Play()
        TS:Create(listScroll, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, listH)}):Play()
    end
    local function closeList()
        isOpen = false
        TS:Create(arrowLbl, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
        TS:Create(outer, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1, -12, 0, HEADER_H)}):Play()
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
                outer.Size = UDim2.new(1, -12, 0, HEADER_H + 2 + listH)
                listScroll.Size = UDim2.new(1, 0, 0, listH)
            end
        end,
    }
end

local function makeStatus(page, initText)
    local f = Instance.new("Frame", page)
    f.Size = UDim2.new(1, -12, 0, 32)
    f.BackgroundColor3 = C.CARD
    f.BorderSizePixel = 0
    corner(f, 6)
    local stroke = Instance.new("UIStroke", f)
    stroke.Color = C.BORDER
    stroke.Thickness = 1
    stroke.Transparency = 0.4

    local dot = Instance.new("Frame", f)
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 10, 0.5, -4)
    dot.BackgroundColor3 = C.DOT_IDLE
    dot.BorderSizePixel = 0
    corner(dot, 4)

    local lb = Instance.new("TextLabel", f)
    lb.Size = UDim2.new(1, -28, 1, 0)
    lb.Position = UDim2.new(0, 24, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Font = Enum.Font.Gotham
    lb.TextSize = 12
    lb.TextColor3 = C.TEXT_MID
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Text = initText

    local resetThread = nil
    local function scheduleReset()
        if resetThread then task.cancel(resetThread); resetThread = nil end
        resetThread = task.delay(3, function()
            TS:Create(dot, TweenInfo.new(0.4), {BackgroundColor3 = C.DOT_IDLE}):Play()
            task.wait(0.4)
            lb.Text = initText
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

local function makeSep(page)
    local sep = Instance.new("Frame", page)
    sep.Size = UDim2.new(1, -12, 0, 1)
    sep.BackgroundColor3 = C.BORDER
    sep.BorderSizePixel = 0
    sep.BackgroundTransparency = 0.5
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

local FLYING = false
local vehicleflyspeed = 1
local flyKeyDown, flyKeyUp

local function sFLY()
    repeat task.wait() until LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    repeat task.wait() until Mouse

    if flyKeyDown or flyKeyUp then
        flyKeyDown:Disconnect()
        flyKeyUp:Disconnect()
    end

    local T = LP.Character.HumanoidRootPart
    local keys = {w = false, s = false, a = false, d = false, e = false, q = false}

    local function FLY()
        FLYING = true
        local BG = Instance.new("BodyGyro")
        local BV = Instance.new("BodyVelocity")
        BG.P = 9e4
        BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        BG.cframe = T.CFrame
        BG.Parent = T
        BV.velocity = Vector3.new(0, 0, 0)
        BV.maxForce = Vector3.new(9e9, 9e9, 9e9)
        BV.Parent = T

        task.spawn(function()
            repeat
                task.wait()
                local spd = vehicleflyspeed
                local F = (keys.w and spd or 0) + (keys.s and -spd or 0)
                local L = (keys.a and -spd or 0) + (keys.d and spd or 0)
                local V = (keys.e and spd * 2 or 0) + (keys.q and -spd * 2 or 0)
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
            keys = {w = false, s = false, a = false, d = false, e = false, q = false}
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
    if flyKeyUp then flyKeyUp:Disconnect(); flyKeyUp = nil end
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
    pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end

-- ════════════════════════════════════════════════════
-- VEHICLE UI
-- ════════════════════════════════════════════════════

local vehiclePage = pages["VehicleTab"]

sectionLabel(vehiclePage, "Vehicle")

makeSlider(vehiclePage, "Vehicle Speed", 1, 10, 1, function(val)
    vehicleSpeed(val)
end)

makeSlider(vehiclePage, "Fly Speed", 1, 250, 1, function(val)
    vehicleflyspeed = val
end)

makeToggle(vehiclePage, "Vehicle Fly", false, function(on)
    if on then
        local char = LP.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
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

makeSep(vehiclePage)

sectionLabel(vehiclePage, "Spawner")

local carColors = {
    "Medium stone grey", "Sand green", "Sand red", "Faded green",
    "Dark grey metallic", "Dark grey", "Earth yellow", "Earth orange",
    "Silver", "Brick yellow", "Dark red", "Hot pink",
}

makeFancyDropdown(vehiclePage, "Color", function() return carColors end, function(val)
    spawnColor = val
end)

local spawnStat = makeStatus(vehiclePage, "Pick a color, then start")
local spawnColor = nil
local abortSpawner = false

local function vehicleSpawner(color)
    if not color then spawnStat.SetActive(false, "Select a color first"); return end
    abortSpawner = false
    spawnStat.SetActive(true, "Click your spawn pad")

    local spawnedPartColor = nil

    local carAddedConn = workspace.PlayerModels.ChildAdded:Connect(function(v)
        task.spawn(function()
            local ownerVal = v:WaitForChild("Owner", 10)
            if not ownerVal or ownerVal.Value ~= LP then return end
            local pp = v:WaitForChild("PaintParts", 10)
            if not pp then return end
            local part = pp:WaitForChild("Part", 10)
            if not part then return end
            spawnedPartColor = part.BrickColor.Name
        end)
    end)

    local padConn
    padConn = Mouse.Button1Up:Connect(function()
        local target = Mouse.Target
        if not target then return end
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
                spawnStat.SetActive(false, "Spawned  " .. color)
            end
        end)
    end)
end

makeButton(vehiclePage, "Start Spawner", function()
    task.spawn(vehicleSpawner, spawnColor)
end)

makeButton(vehiclePage, "Stop Spawner", function()
    abortSpawner = true
    spawnStat.SetActive(false, "Stopped")
end)

-- ════════════════════════════════════════════════════
-- SORTER LOGIC
-- ════════════════════════════════════════════════════

local sorterPage = pages["SorterTab"]

-- Selection state
local clickSelectEnabled = false
local lassoEnabled = false
local groupSelectEnabled = false
local selectedItems = {}
local selectionCountLabel = nil

local function selectPart(part)
    if not part or not part.Parent then return end
    if part:FindFirstChild("SortSelection") then return end
    local sb = Instance.new("SelectionBox", part)
    sb.Name = "SortSelection"
    sb.Adornee = part
    sb.SurfaceTransparency = 0.6
    sb.LineThickness = 0.08
    sb.SurfaceColor3 = Color3.fromRGB(0, 0, 0)
    sb.Color3 = Color3.fromRGB(200, 200, 255)

    if not selectedItems[part] then
        selectedItems[part] = true
    end
    if selectionCountLabel then
        local count = 0
        for _ in pairs(selectedItems) do count = count + 1 end
        selectionCountLabel.Text = "Selected: " .. count .. " items"
    end
end

local function deselectPart(part)
    if not part then return end
    local s = part:FindFirstChild("SortSelection")
    if s then s:Destroy() end
    selectedItems[part] = nil
    if selectionCountLabel then
        local count = 0
        for _ in pairs(selectedItems) do count = count + 1 end
        selectionCountLabel.Text = "Selected: " .. count .. " items"
    end
end

local function deselectAll()
    for part, _ in pairs(selectedItems) do
        if part and part.Parent then
            local s = part:FindFirstChild("SortSelection")
            if s then s:Destroy() end
        end
    end
    selectedItems = {}
    if selectionCountLabel then
        selectionCountLabel.Text = "Selected: 0 items"
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
            if tPart:FindFirstChild("SortSelection") then
                deselectPart(tPart)
            else
                selectPart(tPart)
            end
            return
        end
    end

    if par:FindFirstChild("WoodSection") then
        local tPart = par.WoodSection
        if target == tPart or target:IsDescendantOf(tPart) then
            if tPart:FindFirstChild("SortSelection") then
                deselectPart(tPart)
            else
                selectPart(tPart)
            end
            return
        end
    end

    local model = target:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChild("Owner") then
        if model:FindFirstChild("Main") then
            local p = model.Main
            if p:FindFirstChild("SortSelection") then
                deselectPart(p)
            else
                selectPart(p)
            end
        elseif model:FindFirstChild("WoodSection") then
            local p = model.WoodSection
            if p:FindFirstChild("SortSelection") then
                deselectPart(p)
            else
                selectPart(p)
            end
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
    local iv = model:FindFirstChild("ItemName")
    local groupName = iv and iv.Value or model.Name

    if not workspace:FindFirstChild("PlayerModels") then return end

    for _, v in pairs(workspace.PlayerModels:GetChildren()) do
        local vOwner = v:FindFirstChild("Owner")
        if vOwner and vOwner.Value == clickedOwner then
            local viv = v:FindFirstChild("ItemName")
            local vName = viv and viv.Value or v.Name
            if vName == groupName then
                if v:FindFirstChild("Main") then
                    selectPart(v.Main)
                end
                if v:FindFirstChild("WoodSection") then
                    selectPart(v.WoodSection)
                end
            end
        end
    end
end

-- Lasso selection
local lassoFrame = Instance.new("Frame", game.CoreGui)
lassoFrame.Name = "SortLassoRect"
lassoFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
lassoFrame.BackgroundTransparency = 0.7
lassoFrame.BorderSizePixel = 0
lassoFrame.Visible = false
lassoFrame.ZIndex = 20
local lassoStroke = Instance.new("UIStroke", lassoFrame)
lassoStroke.Color = Color3.fromRGB(200, 200, 255)
lassoStroke.Thickness = 1.5
lassoStroke.Transparency = 0

local Camera = workspace.CurrentCamera

local function is_in_frame(screenpos, frame)
    local xPos = frame.AbsolutePosition.X
    local yPos = frame.AbsolutePosition.Y
    local xSize = frame.AbsoluteSize.X
    local ySize = frame.AbsoluteSize.Y
    return screenpos.X >= xPos and screenpos.X <= xPos + xSize and
           screenpos.Y >= yPos and screenpos.Y <= yPos + ySize
end

UserInputService.InputBegan:Connect(function(input)
    if not lassoEnabled then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not workspace:FindFirstChild("PlayerModels") then return end

    lassoFrame.Visible = true
    lassoFrame.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)
    lassoFrame.Size = UDim2.new(0, 0, 0, 0)

    while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
        RunService.RenderStepped:Wait()
        lassoFrame.Size = UDim2.new(0, Mouse.X - lassoFrame.AbsolutePosition.X, 0, Mouse.Y - lassoFrame.AbsolutePosition.Y)

        for _, v in pairs(workspace.PlayerModels:GetChildren()) do
            if v:FindFirstChild("Main") then
                local sp, vis = Camera:WorldToScreenPoint(v.Main.CFrame.p)
                if vis and is_in_frame(sp, lassoFrame) then
                    selectPart(v.Main)
                end
            end
            if v:FindFirstChild("WoodSection") then
                local sp, vis = Camera:WorldToScreenPoint(v.WoodSection.CFrame.p)
                if vis and is_in_frame(sp, lassoFrame) then
                    selectPart(v.WoodSection)
                end
            end
        end
    end
    lassoFrame.Size = UDim2.new(0, 1, 0, 1)
    lassoFrame.Visible = false
end)

Mouse.Button1Up:Connect(function()
    if lassoEnabled then return end
    if clickSelectEnabled then
        trySelect(Mouse.Target)
    elseif groupSelectEnabled then
        tryGroupSelect(Mouse.Target)
    end
end)

-- Sorting variables
local sortDimensions = {x = 3, y = 3, z = 3}
local previewEnabled = false
local previewBox = nil
local previewLocked = false
local previewPosition = nil
local sortingActive = false
local abortSorting = false
local sortDelay = 0.15

local function getSelectedPartsList()
    local parts = {}
    for part, _ in pairs(selectedItems) do
        if part and part.Parent and part:IsA("BasePart") then
            table.insert(parts, part)
        end
    end
    return parts
end

local function canFitItems()
    local itemCount = 0
    for _ in pairs(selectedItems) do itemCount = itemCount + 1 end
    if itemCount == 0 then return false end

    local itemsPerLayer = sortDimensions.x * sortDimensions.z
    local requiredLayers = math.ceil(itemCount / itemsPerLayer)
    local requiredHeight = requiredLayers * sortDimensions.y

    return true
end

local function createPreviewBox()
    if previewBox then previewBox:Destroy() end

    previewBox = Instance.new("Part")
    previewBox.Name = "SortPreviewBox"
    previewBox.Anchored = true
    previewBox.CanCollide = false
    previewBox.Transparency = 0.7
    previewBox.Color = C.PREVIEW
    previewBox.Material = Enum.Material.SmoothPlastic
    previewBox.Size = Vector3.new(sortDimensions.x, sortDimensions.y, sortDimensions.z)

    local boxStroke = Instance.new("SelectionBox", previewBox)
    boxStroke.Adornee = previewBox
    boxStroke.Color3 = C.PREVIEW_BORDER
    boxStroke.LineThickness = 0.05
    boxStroke.Transparency = 0.3

    previewBox.Parent = workspace
end

local function updatePreviewBoxPosition()
    if not previewBox then return end

    if previewLocked and previewPosition then
        previewBox.Position = previewPosition
    else
        local mousePos = Mouse.Hit.p
        local posX = math.floor(mousePos.X / sortDimensions.x + 0.5) * sortDimensions.x
        local posZ = math.floor(mousePos.Z / sortDimensions.z + 0.5) * sortDimensions.z
        local posY = 0

        previewBox.Position = Vector3.new(posX, posY, posZ)
    end
end

local function startPreview()
    local itemCount = 0
    for _ in pairs(selectedItems) do itemCount = itemCount + 1 end

    if itemCount == 0 then
        return false
    end

    if not canFitItems() then
        return false
    end

    if previewBox then previewBox:Destroy() end
    createPreviewBox()
    previewEnabled = true
    previewLocked = false
    previewPosition = nil

    return true
end

local function stopPreview()
    previewEnabled = false
    if previewBox then
        previewBox:Destroy()
        previewBox = nil
    end
    previewLocked = false
    previewPosition = nil
end

local function lockPreview()
    if previewBox and not previewLocked then
        previewLocked = true
        previewPosition = previewBox.Position
    end
end

local function sortItems()
    local parts = getSelectedPartsList()
    if #parts == 0 then return end

    local itemsPerLayer = sortDimensions.x * sortDimensions.z
    local layers = math.ceil(#parts / itemsPerLayer)
    local totalHeight = layers * sortDimensions.y

    local startPos = previewPosition or (Mouse.Hit.p - Vector3.new(0, totalHeight / 2, 0))
    startPos = Vector3.new(
        math.floor(startPos.X / sortDimensions.x) * sortDimensions.x,
        startPos.Y,
        math.floor(startPos.Z / sortDimensions.z) * sortDimensions.z
    )

    local function getItemType(part)
        local model = part.Parent
        if not model then return "unknown" end
        local iv = model:FindFirstChild("ItemName")
        return iv and iv.Value or model.Name
    end

    table.sort(parts, function(a, b)
        local typeA = getItemType(a)
        local typeB = getItemType(b)
        if typeA == typeB then
            return a.Name < b.Name
        end
        return typeA < typeB
    end)

    for idx, part in ipairs(parts) do
        if abortSorting then break end

        local layer = math.floor((idx - 1) / itemsPerLayer)
        local posInLayer = (idx - 1) % itemsPerLayer
        local xOffset = (posInLayer % sortDimensions.x) * sortDimensions.x
        local zOffset = math.floor(posInLayer / sortDimensions.x) * sortDimensions.z
        local yOffset = layer * sortDimensions.y

        local targetPos = startPos + Vector3.new(
            xOffset + sortDimensions.x / 2,
            yOffset + sortDimensions.y / 2,
            zOffset + sortDimensions.z / 2
        )

        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local oldPos = hrp and hrp.CFrame

        if hrp then
            hrp.CFrame = CFrame.new(part.CFrame.p) * CFrame.new(5, 0, 0)
            task.wait(sortDelay * 0.5)
        end

        local function isnetworkowner(p)
            return p.ReceiveAge == 0
        end

        pcall(function()
            if not part.Parent.PrimaryPart then
                part.Parent.PrimaryPart = part
            end

            local dragger = RS:FindFirstChild("Interaction")
                and RS.Interaction:FindFirstChild("ClientIsDragging")

            local timeout = 0
            while not isnetworkowner(part) and timeout < 3 do
                if dragger then dragger:FireServer(part.Parent) end
                task.wait(0.05)
                timeout = timeout + 0.05
            end
            if dragger then dragger:FireServer(part.Parent) end

            local tweenInfo = TweenInfo.new(sortDelay, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local targetCF = CFrame.new(targetPos)

            local tween = TS:Create(part, tweenInfo, {CFrame = targetCF})
            tween:Play()
            tween.Completed:Wait()
        end)

        task.wait(sortDelay)

        if oldPos and hrp then
            hrp.CFrame = oldPos
        end
    end
end

-- ════════════════════════════════════════════════════
-- SORTER UI
-- ════════════════════════════════════════════════════

sectionLabel(sorterPage, "Selection")

local selectionRow = Instance.new("Frame", sorterPage)
selectionRow.Size = UDim2.new(1, -12, 0, 44)
selectionRow.BackgroundTransparency = 1

local selectionModes = {"Click", "Lasso", "Group"}
local selectionButtons = {}

for i, mode in ipairs(selectionModes) do
    local btn = Instance.new("TextButton", selectionRow)
    btn.Size = UDim2.new(0.333, -4, 1, 0)
    btn.Position = UDim2.new((i - 1) * 0.333, i == 1 and 0 or (i == 2 and 2 or 4), 0, 0)
    btn.BackgroundColor3 = C.BTN
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.TextColor3 = C.TEXT
    btn.Text = mode
    btn.AutoButtonColor = false
    corner(btn, 6)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = C.BORDER
    stroke.Thickness = 1
    stroke.Transparency = 0.3

    btn.MouseEnter:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN_HV}):Play()
    end)
    btn.MouseLeave:Connect(function()
        if selectionButtons[1] and selectionButtons[1].BackgroundColor3 ~= C.BTN_HV then
            TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN}):Play()
        end
    end)

    btn.MouseButton1Click:Connect(function()
        clickSelectEnabled = (mode == "Click")
        lassoEnabled = (mode == "Lasso")
        groupSelectEnabled = (mode == "Group")

        for _, b in ipairs(selectionButtons) do
            TS:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN})
        end
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 60, 70)})
    end)

    selectionButtons[i] = btn
end

makeButton(sorterPage, "Deselect All", function()
    deselectAll()
end)

selectionCountLabel = Instance.new("TextLabel", sorterPage)
selectionCountLabel.Size = UDim2.new(1, -12, 0, 28)
selectionCountLabel.Position = UDim2.new(0, 6, 0, 0)
selectionCountLabel.BackgroundColor3 = C.CARD
selectionCountLabel.BackgroundTransparency = 0.5
selectionCountLabel.Font = Enum.Font.Gotham
selectionCountLabel.TextSize = 11
selectionCountLabel.TextColor3 = C.TEXT_MID
selectionCountLabel.Text = "Selected: 0 items"
corner(selectionCountLabel, 6)
local countStroke = Instance.new("UIStroke", selectionCountLabel)
countStroke.Color = C.BORDER
countStroke.Thickness = 1
countStroke.Transparency = 0.5

makeSep(sorterPage)

sectionLabel(sorterPage, "Dimensions")

makeSlider(sorterPage, "Width X", 1, 20, 3, function(val)
    sortDimensions.x = val
    if previewBox then
        previewBox.Size = Vector3.new(sortDimensions.x, sortDimensions.y, sortDimensions.z)
        if previewLocked then
            updatePreviewBoxPosition()
        end
    end
end)

makeSlider(sorterPage, "Height Y", 1, 20, 3, function(val)
    sortDimensions.y = val
    if previewBox then
        previewBox.Size = Vector3.new(sortDimensions.x, sortDimensions.y, sortDimensions.z)
    end
end)

makeSlider(sorterPage, "Depth Z", 1, 20, 3, function(val)
    sortDimensions.z = val
    if previewBox then
        previewBox.Size = Vector3.new(sortDimensions.x, sortDimensions.y, sortDimensions.z)
        if previewLocked then
            updatePreviewBoxPosition()
        end
    end
end)

makeSlider(sorterPage, "Sort Delay ms", 5, 50, 15, function(val)
    sortDelay = val / 100
end)

makeSep(sorterPage)

sectionLabel(sorterPage, "Preview and Sort")

local previewBtn = makeButton(sorterPage, "Load Preview", function()
    local itemCount = 0
    for _ in pairs(selectedItems) do itemCount = itemCount + 1 end

    if itemCount == 0 then
        return
    end

    if not canFitItems() then
        return
    end

    if previewEnabled then
        stopPreview()
        previewBtn.Text = "Load Preview"
    else
        if startPreview() then
            previewBtn.Text = "Hide Preview"
        end
    end
end)

makeButton(sorterPage, "Lock Preview", function()
    if previewBox and not previewLocked then
        lockPreview()
    end
end)

local sortBtn = makeButton(sorterPage, "Start Sorting", function()
    if sortingActive then
        abortSorting = true
        sortingActive = false
        sortBtn.Text = "Start Sorting"
        stopPreview()
        return
    end

    local itemCount = 0
    for _ in pairs(selectedItems) do itemCount = itemCount + 1 end

    if itemCount == 0 then
        return
    end

    if not previewLocked or not previewBox then
        return
    end

    sortingActive = true
    abortSorting = false
    sortBtn.Text = "Abort Sorting"

    task.spawn(function()
        sortItems()
        sortingActive = false
        abortSorting = false
        sortBtn.Text = "Start Sorting"
        stopPreview()
        previewBtn.Text = "Load Preview"
    end)
end)

-- Preview follow mouse
RunService.RenderStepped:Connect(function()
    if previewEnabled and previewBox and not previewLocked then
        updatePreviewBoxPosition()
    end
end)

-- ════════════════════════════════════════════════════
-- CLEANUP
-- ════════════════════════════════════════════════════
table.insert(VH.cleanupTasks, function()
    abortSpawner = true
    NOFLY()
    stopPreview()
    deselectAll()
    if lassoFrame and lassoFrame.Parent then
        lassoFrame:Destroy()
    end
    abortSorting = true
    sortingActive = false
end)

print("[VanillaHub] Vanilla7 loaded - Vehicle Tab + Sorter Tab")
