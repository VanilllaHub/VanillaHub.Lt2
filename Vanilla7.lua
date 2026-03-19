-- VanillaHub | Vanilla7.lua
-- Populates: Vehicle tab (Spawner only)
-- Requires Vanilla1 (_G.VH) to already be loaded.

if not _G.VH then
    warn("[VanillaHub] Vanilla7: _G.VH not found. Load Vanilla1 first.")
    return
end

local VH         = _G.VH
local TS         = VH.TweenService
local Players    = VH.Players
local RS         = game:GetService("ReplicatedStorage")
local UIS        = VH.UserInputService
local LP         = Players.LocalPlayer
local Mouse      = LP:GetMouse()

local pages      = VH.pages

-- ════════════════════════════════════════════════════
-- THEME
-- ════════════════════════════════════════════════════
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
}

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
    lbl.Size               = UDim2.new(1, -12, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 11
    lbl.TextColor3         = C.TEXT_DIM
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = string.upper(text)
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
    arrowLbl.Text           = "▾"
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
    listScroll.Position             = UDim2.new(0, 0, 0, HEADER_H + 2)
    listScroll.Size                 = UDim2.new(1, 0, 0, 0)
    listScroll.BackgroundTransparency = 1
    listScroll.BorderSizePixel      = 0
    listScroll.ScrollBarThickness   = 3
    listScroll.ScrollBarImageColor3 = C.BORDER
    listScroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
    listScroll.ClipsDescendants     = true

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
            iLbl.Size           = UDim2.new(1, -16, 1, 0)
            iLbl.Position       = UDim2.new(0, 10, 0, 0)
            iLbl.BackgroundTransparency = 1
            iLbl.Text           = opt
            iLbl.Font           = Enum.Font.GothamSemibold
            iLbl.TextSize       = 12
            iLbl.TextColor3     = C.TEXT
            iLbl.TextXAlignment = Enum.TextXAlignment.Left
            iLbl.TextTruncate   = Enum.TextTruncate.AtEnd
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
-- VEHICLE TAB
-- ════════════════════════════════════════════════════

local vh = pages["VehicleTab"]

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
-- SPAWNER UI
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
-- CLEANUP
-- ════════════════════════════════════════════════════
table.insert(VH.cleanupTasks, function()
    abortSpawner = true
end)

print("[VanillaHub] Vanilla7 loaded")
