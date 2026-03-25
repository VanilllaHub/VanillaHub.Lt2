-- VanillaHub | Vanilla7_Vehicle.lua
-- Vehicle (Section 1) + Spawner (Section 2) + Sorter Tab (Section 3).
-- Requires Vanilla1 (_G.VH) to already be loaded.
-- Selection system ported from Item Tab (Vanilla1). Theme: white / grey / black.

if not _G.VH then
    warn("[VanillaHub] Vanilla7: _G.VH not found. Load Vanilla1 first.")
    return
end

local VH               = _G.VH
local TS               = VH.TweenService
local TweenService     = TS
local UserInputService = VH.UserInputService or game:GetService("UserInputService")
local RunService       = VH.RunService       or game:GetService("RunService")
local Players          = VH.Players
local LP               = Players.LocalPlayer
local player           = LP
local Mouse            = LP:GetMouse()
local mouse            = Mouse
local RS               = game:GetService("ReplicatedStorage")
local cleanupTasks     = VH.cleanupTasks
local pages            = VH.pages
local camera           = workspace.CurrentCamera

-- ════════════════════════════════════════════════════
-- THEME  (matches Vanilla1 Item Tab — white/grey/black)
-- ════════════════════════════════════════════════════

local THEME_TEXT   = VH.THEME_TEXT   or Color3.fromRGB(220, 220, 220)
local BTN_COLOR    = VH.BTN_COLOR    or Color3.fromRGB(14,  14,  14)
local BTN_HOVER    = VH.BTN_HOVER    or Color3.fromRGB(32,  32,  32)
local SEP_COLOR    = VH.SEP_COLOR    or Color3.fromRGB(50,  50,  50)
local SECTION_TEXT = VH.SECTION_TEXT or Color3.fromRGB(130, 130, 130)
local SW_ON        = VH.SW_ON        or Color3.fromRGB(230, 230, 230)
local SW_OFF       = VH.SW_OFF       or Color3.fromRGB(55,  55,  55)
local SW_KNOB_ON   = VH.SW_KNOB_ON   or Color3.fromRGB(30,  30,  30)
local SW_KNOB_OFF  = VH.SW_KNOB_OFF  or Color3.fromRGB(160, 160, 160)
local PB_BAR       = VH.PB_BAR       or Color3.fromRGB(255, 255, 255)
local PB_TEXT      = VH.PB_TEXT      or Color3.fromRGB(255, 255, 255)

-- ════════════════════════════════════════════════════
-- SHARED UI HELPERS  (Vanilla1 Item Tab style)
-- ════════════════════════════════════════════════════

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
end

local function addStroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke", parent)
    s.Color        = color        or SEP_COLOR
    s.Thickness    = thickness    or 1
    s.Transparency = transparency or 0
    return s
end

-- Section label (matches Item Tab style: ALL CAPS, grey, indented)
local function sectionLabel(page, text)
    local w = Instance.new("Frame", page)
    w.Size             = UDim2.new(1, 0, 0, 22)
    w.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", w)
    lbl.Size               = UDim2.new(1, -4, 1, 0)
    lbl.Position           = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 10
    lbl.TextColor3         = SECTION_TEXT
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = "  " .. string.upper(text)
end

-- Separator line
local function sep(page)
    local s = Instance.new("Frame", page)
    s.Size             = UDim2.new(1, 0, 0, 1)
    s.BackgroundColor3 = SEP_COLOR
    s.BorderSizePixel  = 0
end

-- Button (Vanilla1 style)
local function makeButton(page, text, cb)
    local btn = Instance.new("TextButton", page)
    btn.Size             = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = BTN_COLOR
    btn.BorderSizePixel  = 0
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.TextColor3       = THEME_TEXT
    btn.Text             = text
    btn.AutoButtonColor  = false
    corner(btn, 8)
    addStroke(btn, Color3.fromRGB(55, 55, 55), 1, 0)
    btn.MouseEnter:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_HOVER}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_COLOR}):Play()
    end)
    if cb then btn.MouseButton1Click:Connect(function() task.spawn(cb) end) end
    return btn
end

-- Toggle (Vanilla1 style — matches iToggle exactly)
local function makeToggle(page, text, default, cb)
    local frame = Instance.new("Frame", page)
    frame.Size             = UDim2.new(1, 0, 0, 36)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel  = 0
    corner(frame, 8)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size               = UDim2.new(1, -54, 1, 0)
    lbl.Position           = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = text
    lbl.Font               = Enum.Font.GothamSemibold
    lbl.TextSize           = 13
    lbl.TextColor3         = THEME_TEXT
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    local tb = Instance.new("TextButton", frame)
    tb.Size             = UDim2.new(0, 36, 0, 20)
    tb.Position         = UDim2.new(1, -46, 0.5, -10)
    tb.BackgroundColor3 = default and SW_ON or SW_OFF
    tb.Text             = ""
    tb.BorderSizePixel  = 0
    corner(tb, 10)
    local circle = Instance.new("Frame", tb)
    circle.Size             = UDim2.new(0, 14, 0, 14)
    circle.Position         = UDim2.new(0, default and 20 or 2, 0.5, -7)
    circle.BackgroundColor3 = default and SW_KNOB_ON or SW_KNOB_OFF
    circle.BorderSizePixel  = 0
    corner(circle, 7)
    local toggled = default
    if cb then cb(toggled) end
    tb.MouseButton1Click:Connect(function()
        toggled = not toggled
        TS:Create(tb, TweenInfo.new(0.2, Enum.EasingStyle.Quint),
            {BackgroundColor3 = toggled and SW_ON or SW_OFF}):Play()
        TS:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position         = UDim2.new(0, toggled and 20 or 2, 0.5, -7),
            BackgroundColor3 = toggled and SW_KNOB_ON or SW_KNOB_OFF,
        }):Play()
        if cb then cb(toggled) end
    end)
    return frame
end

-- Slider (Vanilla1 style — matches iSlider exactly)
local function makeSlider(page, text, minV, maxV, defV, cb)
    local frame = Instance.new("Frame", page)
    frame.Size             = UDim2.new(1, 0, 0, 54)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel  = 0
    corner(frame, 8)
    local topRow = Instance.new("Frame", frame)
    topRow.Size                   = UDim2.new(1, -16, 0, 22)
    topRow.Position               = UDim2.new(0, 8, 0, 7)
    topRow.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", topRow)
    lbl.Size               = UDim2.new(0.72, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamSemibold
    lbl.TextSize           = 13
    lbl.TextColor3         = THEME_TEXT
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = text
    local valLbl = Instance.new("TextLabel", topRow)
    valLbl.Size               = UDim2.new(0.28, 0, 1, 0)
    valLbl.Position           = UDim2.new(0.72, 0, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Font               = Enum.Font.GothamBold
    valLbl.TextSize           = 13
    valLbl.TextColor3         = PB_TEXT
    valLbl.TextXAlignment     = Enum.TextXAlignment.Right
    valLbl.Text               = tostring(defV)
    local track = Instance.new("Frame", frame)
    track.Size             = UDim2.new(1, -16, 0, 5)
    track.Position         = UDim2.new(0, 8, 0, 38)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    track.BorderSizePixel  = 0
    corner(track, 3)
    local fill = Instance.new("Frame", track)
    fill.Size             = UDim2.new((defV - minV) / (maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = PB_BAR
    fill.BorderSizePixel  = 0
    corner(fill, 3)
    local knob = Instance.new("TextButton", track)
    knob.Size             = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint      = Vector2.new(0.5, 0.5)
    knob.Position         = UDim2.new((defV - minV) / (maxV - minV), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Text             = ""
    knob.BorderSizePixel  = 0
    corner(knob, 7)
    local ds = false
    local function upd(absX)
        local r = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.round(minV + r * (maxV - minV))
        fill.Size     = UDim2.new(r, 0, 1, 0)
        knob.Position = UDim2.new(r, 0, 0.5, 0)
        valLbl.Text   = tostring(v)
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

-- Fancy dropdown (Vanilla1 teleport tab style)
local function makeFancyDropdown(page, labelText, getOptions, cb)
    local selected   = ""
    local isOpen     = false
    local ITEM_H     = 36
    local MAX_SHOW   = 5
    local HEADER_H   = 42

    local outer = Instance.new("Frame", page)
    outer.Size             = UDim2.new(1, 0, 0, HEADER_H)
    outer.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
    outer.BorderSizePixel  = 0
    outer.ClipsDescendants = true
    corner(outer, 9)
    local outerStroke = Instance.new("UIStroke", outer)
    outerStroke.Color        = Color3.fromRGB(60, 60, 60)
    outerStroke.Thickness    = 1.2
    outerStroke.Transparency = 0.3

    local header = Instance.new("Frame", outer)
    header.Size                   = UDim2.new(1, 0, 0, HEADER_H)
    header.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", header)
    lbl.Size               = UDim2.new(0, 70, 1, 0)
    lbl.Position           = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = labelText
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 12
    lbl.TextColor3         = THEME_TEXT
    lbl.TextXAlignment     = Enum.TextXAlignment.Left

    local selFrame = Instance.new("Frame", header)
    selFrame.Size             = UDim2.new(1, -88, 0, 28)
    selFrame.Position         = UDim2.new(0, 80, 0.5, -14)
    selFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
    selFrame.BorderSizePixel  = 0
    corner(selFrame, 7)
    local sfStroke = Instance.new("UIStroke", selFrame)
    sfStroke.Color        = Color3.fromRGB(60, 60, 60)
    sfStroke.Thickness    = 1
    sfStroke.Transparency = 0.35

    local selLbl = Instance.new("TextLabel", selFrame)
    selLbl.Size               = UDim2.new(1, -32, 1, 0)
    selLbl.Position           = UDim2.new(0, 10, 0, 0)
    selLbl.BackgroundTransparency = 1
    selLbl.Text               = "Select..."
    selLbl.Font               = Enum.Font.GothamSemibold
    selLbl.TextSize           = 12
    selLbl.TextColor3         = Color3.fromRGB(80, 80, 80)
    selLbl.TextXAlignment     = Enum.TextXAlignment.Left
    selLbl.TextTruncate       = Enum.TextTruncate.AtEnd

    local arrowLbl = Instance.new("TextLabel", selFrame)
    arrowLbl.Size               = UDim2.new(0, 22, 1, 0)
    arrowLbl.Position           = UDim2.new(1, -24, 0, 0)
    arrowLbl.BackgroundTransparency = 1
    arrowLbl.Text               = "▲"
    arrowLbl.Font               = Enum.Font.GothamBold
    arrowLbl.TextSize           = 11
    arrowLbl.TextColor3         = Color3.fromRGB(140, 140, 140)
    arrowLbl.TextXAlignment     = Enum.TextXAlignment.Center

    local headerBtn = Instance.new("TextButton", selFrame)
    headerBtn.Size                   = UDim2.new(1, 0, 1, 0)
    headerBtn.BackgroundTransparency = 1
    headerBtn.Text                   = ""
    headerBtn.AutoButtonColor        = false
    headerBtn.ZIndex                 = 5

    local divider = Instance.new("Frame", outer)
    divider.Size             = UDim2.new(1, -14, 0, 1)
    divider.Position         = UDim2.new(0, 7, 0, HEADER_H)
    divider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    divider.BorderSizePixel  = 0
    divider.Visible          = false

    local listScroll = Instance.new("ScrollingFrame", outer)
    listScroll.Position               = UDim2.new(0, 0, 0, HEADER_H + 2)
    listScroll.Size                   = UDim2.new(1, 0, 0, 0)
    listScroll.BackgroundTransparency = 1
    listScroll.BorderSizePixel        = 0
    listScroll.ScrollBarThickness     = 3
    listScroll.ScrollBarImageColor3   = Color3.fromRGB(90, 90, 90)
    listScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
    listScroll.ClipsDescendants       = true

    local listLayout = Instance.new("UIListLayout", listScroll)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding   = UDim.new(0, 3)
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
    end)
    local listPad = Instance.new("UIPadding", listScroll)
    listPad.PaddingTop    = UDim.new(0, 4)
    listPad.PaddingBottom = UDim.new(0, 4)
    listPad.PaddingLeft   = UDim.new(0, 6)
    listPad.PaddingRight  = UDim.new(0, 6)

    local function buildList()
        for _, ch in ipairs(listScroll:GetChildren()) do
            if ch:IsA("Frame") or ch:IsA("TextButton") then ch:Destroy() end
        end
        local opts = getOptions()
        for i, opt in ipairs(opts) do
            local row = Instance.new("Frame", listScroll)
            row.Size             = UDim2.new(1, 0, 0, ITEM_H)
            row.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            row.BorderSizePixel  = 0
            row.LayoutOrder      = i
            corner(row, 7)
            local rowLbl = Instance.new("TextLabel", row)
            rowLbl.Size               = UDim2.new(1, -16, 1, 0)
            rowLbl.Position           = UDim2.new(0, 12, 0, 0)
            rowLbl.BackgroundTransparency = 1
            rowLbl.Text               = opt
            rowLbl.Font               = Enum.Font.GothamSemibold
            rowLbl.TextSize           = 12
            rowLbl.TextColor3         = THEME_TEXT
            rowLbl.TextXAlignment     = Enum.TextXAlignment.Left
            rowLbl.TextTruncate       = Enum.TextTruncate.AtEnd
            local rowBtn = Instance.new("TextButton", row)
            rowBtn.Size                   = UDim2.new(1, 0, 1, 0)
            rowBtn.BackgroundTransparency = 1
            rowBtn.Text                   = ""
            rowBtn.AutoButtonColor        = false
            rowBtn.ZIndex                 = 5
            rowBtn.MouseEnter:Connect(function()
                TS:Create(row, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(34, 34, 34)}):Play()
            end)
            rowBtn.MouseLeave:Connect(function()
                TS:Create(row, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}):Play()
            end)
            rowBtn.MouseButton1Click:Connect(function()
                selected            = opt
                selLbl.Text         = opt
                selLbl.TextColor3   = THEME_TEXT
                isOpen              = false
                TS:Create(arrowLbl,   TweenInfo.new(0.18, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
                TS:Create(outer,      TweenInfo.new(0.20, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, HEADER_H)}):Play()
                TS:Create(listScroll, TweenInfo.new(0.20, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                divider.Visible = false
                if cb then cb(opt) end
            end)
        end
        return #opts
    end

    local function closeList()
        isOpen = false
        TS:Create(arrowLbl,   TweenInfo.new(0.18, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
        TS:Create(outer,      TweenInfo.new(0.20, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, HEADER_H)}):Play()
        TS:Create(listScroll, TweenInfo.new(0.20, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, 0)}):Play()
        divider.Visible = false
    end

    local function openList()
        isOpen = true
        local count = buildList()
        local listH = math.min(count, MAX_SHOW) * (ITEM_H + 3) + 10
        divider.Visible = true
        TS:Create(arrowLbl,   TweenInfo.new(0.18, Enum.EasingStyle.Quint), {Rotation = 180}):Play()
        TS:Create(outer,      TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, HEADER_H + 2 + listH)}):Play()
        TS:Create(listScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, listH)}):Play()
    end

    headerBtn.MouseButton1Click:Connect(function()
        if isOpen then closeList() else openList() end
    end)
    headerBtn.MouseEnter:Connect(function()
        TS:Create(selFrame, TweenInfo.new(0.10), {BackgroundColor3 = Color3.fromRGB(36, 36, 36)}):Play()
    end)
    headerBtn.MouseLeave:Connect(function()
        TS:Create(selFrame, TweenInfo.new(0.10), {BackgroundColor3 = Color3.fromRGB(26, 26, 26)}):Play()
    end)

    return {
        GetSelected = function() return selected end,
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
-- VEHICLE UI  (Vehicle Tab)
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
local spawnStatusLbl

local carColors = {
    "Medium stone grey", "Sand green",        "Sand red",      "Faded green",
    "Dark grey metallic","Dark grey",          "Earth yellow",  "Earth orange",
    "Silver",            "Brick yellow",       "Dark red",      "Hot pink",
}

local function vehicleSpawner(color)
    if not color or color == "" then
        if spawnStatusLbl then spawnStatusLbl.Text = "Select a color first" end
        return
    end
    abortSpawner = false
    if spawnStatusLbl then spawnStatusLbl.Text = "Click your spawn pad..." end

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
        if spawnStatusLbl then spawnStatusLbl.Text = "Waiting for " .. color .. "..." end

        task.spawn(function()
            repeat
                if abortSpawner then
                    carAddedConn:Disconnect()
                    if spawnStatusLbl then spawnStatusLbl.Text = "Stopped" end
                    return
                end
                spawnedPartColor = nil
                pcall(function() RS.Interaction.RemoteProxy:FireServer(car.ButtonRemote_SpawnButton) end)
                local t0 = tick()
                repeat task.wait(0.05) until spawnedPartColor ~= nil or (tick() - t0 > 0.6) or abortSpawner
            until spawnedPartColor == color or abortSpawner

            carAddedConn:Disconnect()
            if spawnStatusLbl then
                spawnStatusLbl.Text = abortSpawner and "Stopped" or ("Spawned · " .. color)
            end
        end)
    end)
end

-- ════════════════════════════════════════════════════
-- SPAWNER UI  (Vehicle Tab continued)
-- ════════════════════════════════════════════════════

sep(vh)
sectionLabel(vh, "Spawner")

makeFancyDropdown(vh, "Color", function() return carColors end, function(val)
    spawnColor = val
end)

-- Spawner status bar (Vanilla1 style)
do
    local f = Instance.new("Frame", vh)
    f.Size             = UDim2.new(1, 0, 0, 28)
    f.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    f.BorderSizePixel  = 0
    corner(f, 7)
    addStroke(f, SEP_COLOR, 1, 0.4)
    local lbl = Instance.new("TextLabel", f)
    lbl.Size               = UDim2.new(1, -12, 1, 0)
    lbl.Position           = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.Gotham
    lbl.TextSize           = 12
    lbl.TextColor3         = Color3.fromRGB(150, 150, 150)
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = "Pick a color, then start"
    spawnStatusLbl = lbl
end

makeButton(vh, "Start Spawner", function() task.spawn(vehicleSpawner, spawnColor) end)
makeButton(vh, "Stop Spawner",  function()
    abortSpawner = true
    if spawnStatusLbl then spawnStatusLbl.Text = "Stopped" end
end)

-- ════════════════════════════════════════════════════
-- SORTER TAB
-- ════════════════════════════════════════════════════

local sorterPage = pages["SorterTab"]

-- ── Constants ──────────────────────────────────────
local ITEM_GAP       = 0.08
local DRIVE_TIMEOUT  = 8.0
local HOLD_SECONDS   = 1.2
local STABLE_NEEDED  = 40
local CONFIRM_DIST   = 2.5
local VERIFY_DIST    = 4.0
local SLOT_RETRY_MAX = 5

-- SelectionBox colours (matching Item Tab exactly)
local SEL_BOX_SURFACE = Color3.fromRGB(0,   0,   0)
local SEL_BOX_BORDER  = Color3.fromRGB(180, 180, 180)
local PREVIEW_COLOR   = Color3.fromRGB(80,  160, 255)
local PLACED_COLOR    = Color3.fromRGB(60,  210, 100)

-- ── State ───────────────────────────────────────────
local selectedItems    = {}   -- model → SelectionBox
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
local followConn       = nil

-- selection mode flags — exactly one may be true (mirrors Item Tab mutual exclusion)
local clickSelEnabled = false
local lassoEnabled    = false
local groupSelEnabled = false

-- lasso drag state
local lassoStartPos = nil
local lassoDragging = false

-- ────────────────────────────────────────────────────
-- SELECTION HELPERS  (ported 1:1 from Item Tab)
-- ────────────────────────────────────────────────────

local function isSortableItem(model)
    if not model or not model:IsA("Model") then return false end
    if model == workspace then return false end
    if not (model:FindFirstChild("Main") or model:FindFirstChildWhichIsA("BasePart")) then return false end
    if model:FindFirstChild("TreeClass") then return false end
    return model:FindFirstChild("Owner")               ~= nil
        or model:FindFirstChild("PurchasedBoxItemName") ~= nil
        or model:FindFirstChild("DraggableItem")        ~= nil
        or model:FindFirstChild("ItemName")             ~= nil
end

local function getMainPart(model)
    return model:FindFirstChild("Main") or model:FindFirstChildWhichIsA("BasePart")
end

-- selectModel: adds SelectionBox exactly like Item Tab's selectPart
local function selectModel(model)
    if not model then return end
    if selectedItems[model] then return end
    local mp = getMainPart(model)
    if not mp then return end
    local sb                = Instance.new("SelectionBox", mp)
    sb.Name                 = "Selection"
    sb.Adornee              = mp
    sb.SurfaceTransparency  = 0.5
    sb.LineThickness        = 0.09
    sb.SurfaceColor3        = SEL_BOX_SURFACE
    sb.Color3               = SEL_BOX_BORDER
    selectedItems[model]    = sb
end

-- deselectModel: removes SelectionBox exactly like Item Tab's deselectPart
local function deselectModel(model)
    if not model then return end
    local sb = selectedItems[model]
    if sb then
        if sb.Parent then sb:Destroy() end
        selectedItems[model] = nil
    end
    -- belt-and-braces: remove any lingering named child
    local mp = getMainPart(model)
    if mp then
        local s = mp:FindFirstChild("Selection")
        if s then s:Destroy() end
    end
end

local function deselectAll()
    for model in pairs(selectedItems) do
        deselectModel(model)
    end
    selectedItems = {}
end

local function countSelected()
    local n = 0
    for _ in pairs(selectedItems) do n = n + 1 end
    return n
end

-- trySelect: toggle individual item — mirrors Item Tab's trySelect exactly
local function trySelect(target)
    if not target then return end
    local par = target.Parent; if not par then return end

    local function handleModel(model)
        if not (model and model.Parent) then return end
        local function toggle(part)
            if not part then return end
            if selectedItems[model] then deselectModel(model)
            else selectModel(model) end
        end
        if model:FindFirstChild("Main") then
            local p = model.Main
            if target == p or target:IsDescendantOf(p) then toggle(p); return end
        end
        if model:FindFirstChild("WoodSection") then
            local p = model.WoodSection
            if target == p or target:IsDescendantOf(p) then toggle(p); return end
        end
        toggle(getMainPart(model))
    end

    if par:FindFirstChild("Owner") then handleModel(par); return end
    local model = target:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChild("Owner") then handleModel(model) end
end

-- tryGroupSelect: select all of same type — mirrors Item Tab's tryGroupSelect exactly
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

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and isSortableItem(obj) then
            local vOwner = obj:FindFirstChild("Owner")
            if vOwner and vOwner.Value == clickedOwner then
                local viv   = obj:FindFirstChild("ItemName")
                local vName = viv and viv.Value or obj.Name
                if vName == groupName then selectModel(obj) end
            end
        end
    end
end

-- ── Lasso overlay (identical to Item Tab lassoFrame) ────────────────────────
local coreGui    = game:GetService("CoreGui")
local lassoFrame = Instance.new("Frame", coreGui:FindFirstChild("VanillaHub") or coreGui)
lassoFrame.Name                   = "SorterLasso"
lassoFrame.BackgroundColor3       = Color3.fromRGB(100, 100, 100)
lassoFrame.BackgroundTransparency = 0.82
lassoFrame.BorderSizePixel        = 0
lassoFrame.Visible                = false
lassoFrame.ZIndex                 = 20
local lstroke = Instance.new("UIStroke", lassoFrame)
lstroke.Color        = Color3.fromRGB(200, 200, 200)
lstroke.Thickness    = 1.5
lstroke.Transparency = 0

local function is_in_frame(screenPos, frame)
    local xPos  = frame.AbsolutePosition.X; local yPos  = frame.AbsolutePosition.Y
    local xSize = frame.AbsoluteSize.X;      local ySize = frame.AbsoluteSize.Y
    local c1 = screenPos.X >= xPos and screenPos.X <= xPos + xSize
    local c2 = screenPos.X <= xPos and screenPos.X >= xPos + xSize
    local c3 = screenPos.Y >= yPos and screenPos.Y <= yPos + ySize
    local c4 = screenPos.Y <= yPos and screenPos.Y >= yPos + ySize
    return (c1 and c3) or (c2 and c3) or (c1 and c4) or (c2 and c4)
end

local function updateLassoVis(s, cur2)
    local minX = math.min(s.X, cur2.X); local minY = math.min(s.Y, cur2.Y)
    lassoFrame.Position = UDim2.new(0, minX, 0, minY)
    lassoFrame.Size     = UDim2.new(0, math.abs(cur2.X - s.X), 0, math.abs(cur2.Y - s.Y))
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

    local layerY, accY = {}, 0
    for l = 0, maxLayer do
        layerY[l] = accY
        accY = accY + (layerMaxH[l] or 0) + ITEM_GAP
    end

    local rowZ = {}
    for l = 0, maxLayer do
        rowZ[l] = {}
        local accZ, maxRow = 0, 0
        for _, e in ipairs(entries) do
            if e.layer == l and e.row > maxRow then maxRow = e.row end
        end
        for r = 0, maxRow do
            rowZ[l][r] = accZ
            accZ = accZ + ((rowMaxD[l] and rowMaxD[l][r]) or 0) + ITEM_GAP
        end
    end

    local colMaxW, colX, accX = {}, {}, 0
    for _, e in ipairs(entries) do
        colMaxW[e.col] = math.max(colMaxW[e.col] or 0, e.w)
    end
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
    local totalItems   = #entries
    local slotPerLayer = rows > 0 and (cols * rows) or math.ceil(totalItems / layers)
    local actualRows   = math.ceil(slotPerLayer / cols)
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
        hitPos = (t and t > 0) and (unitRay.Origin + unitRay.Direction * t)
               or (unitRay.Origin + unitRay.Direction * 40)
    end
    return CFrame.new(hitPos.X, hitPos.Y + halfH, hitPos.Z)
end

local function buildPreviewBox(sX, sY, sZ)
    if previewPart and previewPart.Parent then previewPart:Destroy() end
    previewPart              = Instance.new("Part")
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
    local sb               = Instance.new("SelectionBox")
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
    previewPart.CFrame = getMouseSurfaceCF(previewPart.Size.Y / 2)
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
    if interaction then _dragRemote = interaction:FindFirstChild("ClientIsDragging") end
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

    local driveStart, holdStart = tick(), nil
    local stableStreak = 0
    local locked, done = false, false

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

        if holdStart then
            local held   = tick() - holdStart
            local stable = stableStreak >= STABLE_NEEDED
            if held >= HOLD_SECONDS and stable then
                locked = true; done = true; conn:Disconnect()
            elseif held > HOLD_SECONDS * 6 then
                done = true; conn:Disconnect()
            end
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

-- ════════════════════════════════════════════════════
-- SORTER UI  (Vanilla1 style throughout)
-- ════════════════════════════════════════════════════

-- Forward refs filled in after UI blocks below
local startBtn, stopBtn, sortStatusLbl2, pbContainer, pbFill, pbLabel
local overflowPopup, overflowLabel

local function setSortStatus(msg)
    if sortStatusLbl2 then sortStatusLbl2.Text = msg end
end

local function refreshStatus()
    local n = countSelected()
    if isSorting then
        setSortStatus("Sorting in progress...")
    elseif isStopped then
        setSortStatus("Paused — hit Start to resume.")
    elseif overflowBlocked then
        setSortStatus("Too many items! Increase X, Y, or Z.")
    elseif n == 0 then
        setSortStatus("Select items with Click, Group, or Lasso.")
    elseif previewFollowing then
        setSortStatus("Preview following mouse — click to place.")
    elseif previewPlaced then
        setSortStatus(n .. " item(s) ready — Hit Start Sorting!")
    elseif previewPart then
        setSortStatus("Preview exists. Click anywhere to place it.")
    else
        setSortStatus(n .. " selected. Click Generate Preview.")
    end

    if startBtn then
        local canSort = (n > 0 or isStopped)
                        and (previewPlaced or isStopped)
                        and not isSorting
                        and not overflowBlocked
        TS:Create(startBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = canSort and Color3.fromRGB(35, 35, 35) or BTN_COLOR,
            TextColor3       = canSort and THEME_TEXT or Color3.fromRGB(80, 80, 80),
        }):Play()
        startBtn.Text = isStopped and "Resume Sorting" or "Start Sorting"
    end
    if stopBtn then
        TS:Create(stopBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = isSorting and Color3.fromRGB(30, 20, 20) or BTN_COLOR,
            TextColor3       = isSorting and Color3.fromRGB(200, 120, 120) or Color3.fromRGB(80, 80, 80),
        }):Play()
    end
end

-- ── Status label ────────────────────────────────────
sectionLabel(sorterPage, "Status")
do
    local f = Instance.new("Frame", sorterPage)
    f.Size             = UDim2.new(1, 0, 0, 28)
    f.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    f.BorderSizePixel  = 0
    corner(f, 7)
    addStroke(f, SEP_COLOR, 1, 0.4)
    local dot = Instance.new("Frame", f)
    dot.Size             = UDim2.new(0, 7, 0, 7)
    dot.Position         = UDim2.new(0, 10, 0.5, -3)
    dot.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    dot.BorderSizePixel  = 0
    corner(dot, 4)
    local lbl = Instance.new("TextLabel", f)
    lbl.Size               = UDim2.new(1, -26, 1, 0)
    lbl.Position           = UDim2.new(0, 22, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.Gotham
    lbl.TextSize           = 12
    lbl.TextColor3         = Color3.fromRGB(150, 150, 150)
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.TextTruncate       = Enum.TextTruncate.AtEnd
    lbl.Text               = "Select items to get started."
    sortStatusLbl2 = lbl
end

sep(sorterPage)

-- ── Selection Mode ──────────────────────────────────
sectionLabel(sorterPage, "Selection Mode")

makeToggle(sorterPage, "Click Select", false, function(v)
    clickSelEnabled = v
    if v then lassoEnabled = false; groupSelEnabled = false end
end)
makeToggle(sorterPage, "Lasso Select", false, function(v)
    lassoEnabled = v
    if v then clickSelEnabled = false; groupSelEnabled = false end
end)
makeToggle(sorterPage, "Group Select", false, function(v)
    groupSelEnabled = v
    if v then clickSelEnabled = false; lassoEnabled = false end
end)

do
    local hint = Instance.new("Frame", sorterPage)
    hint.Size             = UDim2.new(1, 0, 0, 26)
    hint.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    hint.BorderSizePixel  = 0
    corner(hint, 7)
    addStroke(hint, SEP_COLOR, 1, 0.5)
    local lbl = Instance.new("TextLabel", hint)
    lbl.Size               = UDim2.new(1, -16, 1, 0)
    lbl.Position           = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.Gotham
    lbl.TextSize           = 11
    lbl.TextColor3         = Color3.fromRGB(100, 100, 100)
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.TextWrapped        = true
    lbl.Text               = "Lasso: drag to box-select.  Group: click to select all of same type."
end

makeButton(sorterPage, "Deselect All", function()
    deselectAll(); refreshStatus()
end)

sep(sorterPage)

-- ── Sort Grid ────────────────────────────────────────
sectionLabel(sorterPage, "Sort Grid  —  X Width · Y Height · Z Depth")

local AXIS_COLORS = {
    X = Color3.fromRGB(220, 70,  70),
    Y = Color3.fromRGB(70,  200, 70),
    Z = Color3.fromRGB(70,  120, 255),
}

local function gridSlider(page, label, axis, minV, maxV, defaultV, cb)
    local axCol = AXIS_COLORS[axis] or THEME_TEXT
    local frame = Instance.new("Frame", page)
    frame.Size             = UDim2.new(1, 0, 0, 54)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel  = 0
    corner(frame, 8)

    local axTag = Instance.new("TextLabel", frame)
    axTag.Size               = UDim2.new(0, 18, 0, 22)
    axTag.Position           = UDim2.new(0, 8, 0, 7)
    axTag.BackgroundTransparency = 1
    axTag.Font               = Enum.Font.GothamBold
    axTag.TextSize           = 14
    axTag.TextColor3         = axCol
    axTag.Text               = axis

    local topLbl = Instance.new("TextLabel", frame)
    topLbl.Size               = UDim2.new(0.58, 0, 0, 22)
    topLbl.Position           = UDim2.new(0, 28, 0, 7)
    topLbl.BackgroundTransparency = 1
    topLbl.Font               = Enum.Font.GothamSemibold
    topLbl.TextSize           = 12
    topLbl.TextColor3         = THEME_TEXT
    topLbl.TextXAlignment     = Enum.TextXAlignment.Left
    topLbl.Text               = label

    local valLbl = Instance.new("TextLabel", frame)
    valLbl.Size               = UDim2.new(0.3, -8, 0, 22)
    valLbl.Position           = UDim2.new(0.7, 0, 0, 7)
    valLbl.BackgroundTransparency = 1
    valLbl.Font               = Enum.Font.GothamBold
    valLbl.TextSize           = 13
    valLbl.TextColor3         = axCol
    valLbl.TextXAlignment     = Enum.TextXAlignment.Right
    valLbl.Text               = tostring(defaultV)

    local track = Instance.new("Frame", frame)
    track.Size             = UDim2.new(1, -16, 0, 5)
    track.Position         = UDim2.new(0, 8, 0, 38)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    track.BorderSizePixel  = 0
    corner(track, 3)

    local fill = Instance.new("Frame", track)
    fill.Size             = UDim2.new((defaultV - minV) / (maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = axCol
    fill.BorderSizePixel  = 0
    corner(fill, 3)

    local knob = Instance.new("TextButton", track)
    knob.Size             = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint      = Vector2.new(0.5, 0.5)
    knob.Position         = UDim2.new((defaultV - minV) / (maxV - minV), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Text             = ""
    knob.BorderSizePixel  = 0
    corner(knob, 7)

    local dragging = false
    local cur      = defaultV
    local function apply(screenX)
        local ratio = math.clamp(
            (screenX - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local val = math.round(minV + ratio * (maxV - minV))
        if val == cur then return end
        cur           = val
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
    return frame
end

gridSlider(sorterPage, "Width  (items per row)", "X", 1, 12, 3, function(v)
    gridCols = v; overflowBlocked = false
    if previewFollowing and previewPart and previewPart.Parent then
        local sX, sY, sZ = computePreviewSize()
        previewPart.Size = Vector3.new(math.max(sX,.5), math.max(sY,.5), math.max(sZ,.5))
    end
end)

gridSlider(sorterPage, "Height  (vertical layers)", "Y", 1, 5, 1, function(v)
    gridLayers = v; overflowBlocked = false
    if previewFollowing and previewPart and previewPart.Parent then
        local sX, sY, sZ = computePreviewSize()
        previewPart.Size = Vector3.new(math.max(sX,.5), math.max(sY,.5), math.max(sZ,.5))
    end
end)

gridSlider(sorterPage, "Depth  (rows, 0=auto)", "Z", 0, 12, 0, function(v)
    gridRows = v; overflowBlocked = false
    if previewFollowing and previewPart and previewPart.Parent then
        local sX, sY, sZ = computePreviewSize()
        previewPart.Size = Vector3.new(math.max(sX,.5), math.max(sY,.5), math.max(sZ,.5))
    end
end)

do
    local hint = Instance.new("Frame", sorterPage)
    hint.Size             = UDim2.new(1, 0, 0, 26)
    hint.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    hint.BorderSizePixel  = 0
    corner(hint, 7)
    addStroke(hint, SEP_COLOR, 1, 0.5)
    local lbl = Instance.new("TextLabel", hint)
    lbl.Size               = UDim2.new(1, -16, 1, 0)
    lbl.Position           = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.Gotham
    lbl.TextSize           = 11
    lbl.TextColor3         = Color3.fromRGB(100, 100, 100)
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.TextWrapped        = true
    lbl.Text               = "Fills left→right (X), front→back (Z), bottom→top (Y). Tallest first. Z=0 auto."
end

-- Overflow error block
do
    local pop = Instance.new("Frame", sorterPage)
    pop.Size             = UDim2.new(1, 0, 0, 40)
    pop.BackgroundColor3 = Color3.fromRGB(28, 10, 10)
    pop.BorderSizePixel  = 0
    pop.Visible          = false
    corner(pop, 8)
    addStroke(pop, Color3.fromRGB(140, 40, 40), 1, 0.2)
    local lbl = Instance.new("TextLabel", pop)
    lbl.Size               = UDim2.new(1, -16, 1, 0)
    lbl.Position           = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamSemibold
    lbl.TextSize           = 11
    lbl.TextColor3         = Color3.fromRGB(200, 100, 100)
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.TextWrapped        = true
    lbl.Text               = ""
    overflowPopup = pop
    overflowLabel = lbl
end

local function showOverflow(msg)
    overflowBlocked     = true
    overflowLabel.Text  = msg
    overflowPopup.Visible = true
end

local function hideOverflow()
    overflowBlocked       = false
    overflowPopup.Visible = false
end

local function gridCapacity()
    local cols   = math.max(1, gridCols)
    local layers = math.max(1, gridLayers)
    local rows   = math.max(0, gridRows)
    if rows == 0 then return math.huge end
    return cols * rows * layers
end

sep(sorterPage)

-- ── Preview ──────────────────────────────────────────
sectionLabel(sorterPage, "Preview")

makeButton(sorterPage, "Generate Preview  (follows mouse)", function()
    if countSelected() == 0 then setSortStatus("No items selected!"); return end
    local n   = countSelected()
    local cap = gridCapacity()
    if n > cap then
        showOverflow(n .. " items but grid only fits " .. cap
            .. "  (X=" .. gridCols .. " × Z=" .. gridRows .. " × Y=" .. gridLayers .. ").")
        refreshStatus(); return
    end
    hideOverflow()
    local sX, sY, sZ = computePreviewSize()
    buildPreviewBox(sX, sY, sZ)
    startPreviewFollow()
    refreshStatus()
end)

makeButton(sorterPage, "Clear Preview", function()
    destroyPreview(); refreshStatus()
end)

sep(sorterPage)

-- ── Progress bar ─────────────────────────────────────
do
    local pb = Instance.new("Frame", sorterPage)
    pb.Size             = UDim2.new(1, 0, 0, 44)
    pb.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    pb.BorderSizePixel  = 0
    pb.Visible          = false
    corner(pb, 8)
    addStroke(pb, SEP_COLOR, 1, 0.4)

    local lbl = Instance.new("TextLabel", pb)
    lbl.Size               = UDim2.new(1, -12, 0, 18)
    lbl.Position           = UDim2.new(0, 8, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamSemibold
    lbl.TextSize           = 11
    lbl.TextColor3         = Color3.fromRGB(160, 160, 160)
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = "Sorting..."

    local track = Instance.new("Frame", pb)
    track.Size             = UDim2.new(1, -16, 0, 10)
    track.Position         = UDim2.new(0, 8, 0, 28)
    track.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    track.BorderSizePixel  = 0
    corner(track, 5)

    local fl = Instance.new("Frame", track)
    fl.Size             = UDim2.new(0, 0, 1, 0)
    fl.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    fl.BorderSizePixel  = 0
    corner(fl, 5)

    pbContainer = pb; pbFill = fl; pbLabel = lbl
end

local function hideProgress(delay)
    task.delay(delay or 2.0, function()
        if not pbContainer then return end
        TS:Create(pbContainer, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        TS:Create(pbFill,      TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        TS:Create(pbLabel,     TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        task.delay(0.45, function()
            if not pbContainer then return end
            pbContainer.Visible                = false
            pbContainer.BackgroundTransparency = 0
            pbFill.BackgroundTransparency      = 0
            pbFill.BackgroundColor3            = Color3.fromRGB(200, 200, 200)
            pbFill.Size                        = UDim2.new(0, 0, 1, 0)
            pbLabel.TextTransparency           = 0
        end)
    end)
end

-- ── Actions ──────────────────────────────────────────
sectionLabel(sorterPage, "Actions")

-- Start button
startBtn = Instance.new("TextButton", sorterPage)
startBtn.Size             = UDim2.new(1, 0, 0, 34)
startBtn.BackgroundColor3 = BTN_COLOR
startBtn.Text             = "Start Sorting"
startBtn.Font             = Enum.Font.GothamBold
startBtn.TextSize         = 14
startBtn.TextColor3       = Color3.fromRGB(80, 80, 80)
startBtn.BorderSizePixel  = 0
corner(startBtn, 8)
addStroke(startBtn, Color3.fromRGB(55, 55, 55), 1, 0)
startBtn.MouseEnter:Connect(function()
    local canSort = (countSelected() > 0 or isStopped) and (previewPlaced or isStopped)
                    and not isSorting and not overflowBlocked
    if canSort then TS:Create(startBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50,50,50)}):Play() end
end)
startBtn.MouseLeave:Connect(function()
    local canSort = (countSelected() > 0 or isStopped) and (previewPlaced or isStopped)
                    and not isSorting and not overflowBlocked
    TS:Create(startBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = canSort and Color3.fromRGB(35,35,35) or BTN_COLOR,
    }):Play()
end)

local function fixDriftedSlots(slots, upTo)
    for i = 1, upTo do
        if not isSorting then break end
        local slot = slots[i]
        if slot and not isSlotFilled(slot) then
            pbLabel.Text = "Re-fixing slot " .. i .. " ..."
            placeAndLock(slot.model, slot.cf)
        end
    end
end

local function runSortLoop(slots, startI, total, doneStart)
    local done = doneStart
    sortThread = task.spawn(function()
        local i         = startI
        local prevLayer = slots[startI] and slots[startI].layer or 0

        while i <= total and isSorting do
            local slot = slots[i]
            local curLayer = slot.layer or 0

            if curLayer > prevLayer then
                pbLabel.Text = "Checking layer " .. prevLayer .. "..."
                fixDriftedSlots(slots, i - 1)
                prevLayer = curLayer
                if not isSorting then sortIndex = i; break end
            end

            if not (slot.model and slot.model.Parent) then
                done = done + 1; sortDone = done; sortIndex = i + 1
                i = i + 1; continue
            end

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

            deselectModel(slot.model)   -- remove highlight as item is placed
            done = done + 1; sortDone = done; sortIndex = i + 1

            local pct = math.clamp(done / math.max(total, 1), 0, 1)
            TS:Create(pbFill, TweenInfo.new(0.15, Enum.EasingStyle.Quad),
                {Size = UDim2.new(pct, 0, 1, 0)}):Play()
            pbLabel.Text = "Sorting... " .. done .. " / " .. total
            task.wait(0.25)
            i = i + 1
        end

        if isSorting and done >= total then
            pbLabel.Text = "Final check..."
            fixDriftedSlots(slots, total)
        end

        isSorting  = false
        sortThread = nil

        if done >= total then
            isStopped = false; sortSlots = nil
            TS:Create(pbFill, TweenInfo.new(0.25),
                {Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.fromRGB(120, 200, 120)}):Play()
            pbLabel.Text = "Sorting complete!"
            destroyPreview(); deselectAll(); hideProgress(2.5)
        else
            isStopped    = true
            pbLabel.Text = "Stopped at " .. done .. " / " .. total
        end
        refreshStatus()
    end)
end

startBtn.MouseButton1Click:Connect(function()
    if isSorting then return end
    if overflowBlocked then setSortStatus("Fix grid size first!"); return end

    if isStopped and sortSlots then
        isStopped = false; isSorting = true
        pbContainer.Visible     = true
        pbFill.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        pbLabel.Text            = "Sorting... " .. sortDone .. " / " .. sortTotal
        refreshStatus()
        runSortLoop(sortSlots, sortIndex, sortTotal, sortDone)
        return
    end

    if not (previewPlaced and previewPart and previewPart.Parent) then
        setSortStatus("Generate a preview and place it first!"); return
    end
    if countSelected() == 0 then setSortStatus("No items selected!"); return end

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
    pbFill.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    pbLabel.Text            = "Sorting... 0 / " .. sortTotal
    refreshStatus()
    runSortLoop(sortSlots, 1, sortTotal, 0)
end)

-- Stop button
stopBtn = Instance.new("TextButton", sorterPage)
stopBtn.Size             = UDim2.new(1, 0, 0, 32)
stopBtn.BackgroundColor3 = BTN_COLOR
stopBtn.Text             = "Stop"
stopBtn.Font             = Enum.Font.GothamBold
stopBtn.TextSize         = 13
stopBtn.TextColor3       = Color3.fromRGB(80, 80, 80)
stopBtn.BorderSizePixel  = 0
corner(stopBtn, 8)
addStroke(stopBtn, Color3.fromRGB(55, 55, 55), 1, 0)
stopBtn.MouseEnter:Connect(function()
    if isSorting then TS:Create(stopBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40,20,20)}):Play() end
end)
stopBtn.MouseLeave:Connect(function()
    TS:Create(stopBtn, TweenInfo.new(0.15), {BackgroundColor3 = isSorting and Color3.fromRGB(30,20,20) or BTN_COLOR}):Play()
end)
stopBtn.MouseButton1Click:Connect(function()
    if not isSorting then return end
    isSorting = false; pbLabel.Text = "Stopping..."
    refreshStatus()
end)

makeButton(sorterPage, "Cancel  (clear all)", function()
    isSorting = false; isStopped = false
    sortSlots = nil; sortIndex = 1; sortTotal = 0; sortDone = 0
    if sortThread then pcall(task.cancel, sortThread); sortThread = nil end
    destroyPreview(); deselectAll(); hideOverflow()
    if pbLabel then pbLabel.Text = "Cancelled." end
    hideProgress(1.0)
    refreshStatus()
end)

-- Parent progress bar after buttons so it sits below them in the list layout
pbContainer.Parent = sorterPage

-- ════════════════════════════════════════════════════
-- MOUSE INPUT  (Vanilla1 Item Tab pattern exactly)
-- ════════════════════════════════════════════════════

-- Button1Up: lasso finalise OR click/group select (mirrors Item Tab mouse.Button1Up)
local mouseUpConn = mouse.Button1Up:Connect(function()
    if lassoDragging and lassoEnabled then
        lassoDragging      = false
        lassoFrame.Visible = false
        lassoFrame.Size    = UDim2.new(0, 1, 0, 1)
        lassoStartPos      = nil
        refreshStatus()
        return
    end
    lassoDragging = false

    if clickSelEnabled then trySelect(mouse.Target); refreshStatus()
    elseif groupSelEnabled then tryGroupSelect(mouse.Target); refreshStatus() end
end)

-- Button1Down: start lasso OR place preview (mirrors Item Tab InputBegan lasso)
local mouseDownConn = mouse.Button1Down:Connect(function()
    if previewFollowing then
        placePreview(); refreshStatus(); return
    end

    if lassoEnabled then
        lassoDragging      = true
        lassoStartPos      = Vector2.new(mouse.X, mouse.Y)
        lassoFrame.Position = UDim2.new(0, mouse.X, 0, mouse.Y)
        lassoFrame.Size    = UDim2.new(0, 0, 0, 0)
        lassoFrame.Visible = true

        -- Live lasso loop — identical to Item Tab's RunService.RenderStepped lasso
        task.spawn(function()
            while lassoDragging and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                RunService.RenderStepped:Wait()
                if not lassoStartPos then break end
                -- resize rect
                lassoFrame.Size = UDim2.new(0, mouse.X, 0, mouse.Y) - lassoFrame.Position
                -- select any item whose Main lands inside the rect
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("Model") and isSortableItem(obj) then
                        local mp2 = getMainPart(obj)
                        if mp2 then
                            local sp, vis = camera:WorldToScreenPoint(mp2.Position)
                            if vis and is_in_frame(Vector3.new(sp.X, sp.Y, 0), lassoFrame) then
                                selectModel(obj)
                            end
                        end
                    end
                end
            end
        end)
    end
end)

local mouseMoveConn = mouse.Move:Connect(function()
    if lassoDragging and lassoEnabled and lassoStartPos then
        updateLassoVis(lassoStartPos, Vector2.new(mouse.X, mouse.Y))
    end
end)

-- ════════════════════════════════════════════════════
-- CLEANUP
-- ════════════════════════════════════════════════════

table.insert(VH.cleanupTasks, function()
    -- Vehicle
    abortSpawner = true
    NOFLY()
    -- Sorter
    isSorting = false; isStopped = false
    sortSlots = nil; sortIndex = 1; sortTotal = 0; sortDone = 0
    if followConn  then followConn:Disconnect();        followConn  = nil end
    if sortThread  then pcall(task.cancel, sortThread); sortThread  = nil end
    mouseDownConn:Disconnect()
    mouseUpConn:Disconnect()
    mouseMoveConn:Disconnect()
    if lassoFrame and lassoFrame.Parent then lassoFrame:Destroy() end
    destroyPreview()
    deselectAll()
end)

refreshStatus()
print("[VanillaHub] Vanilla7_Vehicle (+ Sorter) loaded")
