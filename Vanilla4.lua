-- ════════════════════════════════════════════════════
-- VANILLA4 — Sorter Tab  (v2 — layer-fill-first, bulletproof)
-- Execute AFTER Vanilla1, Vanilla2, Vanilla3
-- ════════════════════════════════════════════════════

if not _G.VH then
    warn("[VanillaHub] Vanilla4: _G.VH not found. Execute Vanilla1 first.")
    return
end

local TweenService     = _G.VH.TweenService
local UserInputService = _G.VH.UserInputService
local RunService       = _G.VH.RunService
local player           = _G.VH.player
local cleanupTasks     = _G.VH.cleanupTasks
local pages            = _G.VH.pages
local BTN_COLOR        = _G.VH.BTN_COLOR           -- grey (set in Vanilla1)
local THEME_TEXT       = _G.VH.THEME_TEXT or Color3.fromRGB(220, 220, 220)

local sorterPage = pages["SorterTab"]
local camera     = workspace.CurrentCamera
local RS         = game:GetService("ReplicatedStorage")
local mouse      = player:GetMouse()

-- ════════════════════════════════════════════════════
-- THEME  (Black / Grey / White only)
-- ════════════════════════════════════════════════════
local C = {
    BG         = Color3.fromRGB(10,  10,  10 ),
    CARD       = Color3.fromRGB(20,  20,  20 ),
    ROW        = Color3.fromRGB(28,  28,  28 ),
    TRACK      = Color3.fromRGB(38,  38,  38 ),

    BORDER     = Color3.fromRGB(55,  55,  55 ),
    BORDER_DIM = Color3.fromRGB(40,  40,  40 ),

    TEXT       = Color3.fromRGB(210, 210, 210),
    TEXT_MID   = Color3.fromRGB(150, 150, 150),
    TEXT_DIM   = Color3.fromRGB(90,  90,  90 ),

    -- buttons (grey)
    BTN        = Color3.fromRGB(70,  70,  70 ),
    BTN_HV     = Color3.fromRGB(100, 100, 100),
    BTN_ACT    = Color3.fromRGB(90,  90,  90 ),   -- "active" button state (lighter grey)
    BTN_DIS    = Color3.fromRGB(32,  32,  32 ),   -- disabled

    -- progress bar
    PB_FILL    = Color3.fromRGB(255, 255, 255),   -- white bar
    PB_DONE    = Color3.fromRGB(220, 220, 220),   -- white when done
    PB_TRACK   = Color3.fromRGB(30,  30,  30 ),

    -- status
    STATUS_TXT = Color3.fromRGB(200, 200, 200),
    STATUS_BG  = Color3.fromRGB(22,  22,  22 ),

    -- selection / preview colours (kept as-is, these are world highlights)
    HL         = Color3.fromRGB(255, 180,   0),
    PREVIEW    = Color3.fromRGB( 80, 160, 255),
    PLACED     = Color3.fromRGB( 60, 210, 100),

    -- axis tag colours (kept as-is for clarity)
    AXIS_X     = Color3.fromRGB(220,  70,  70),
    AXIS_Y     = Color3.fromRGB( 70, 200,  70),
    AXIS_Z     = Color3.fromRGB( 70, 120, 255),
}

-- ════════════════════════════════════════════════════
-- CONSTANTS
-- ════════════════════════════════════════════════════
local HIGHLIGHT_COLOR  = C.HL
local PREVIEW_COLOR    = C.PREVIEW
local PLACED_COLOR     = C.PLACED
local ITEM_GAP         = 0.08
local DRIVE_TIMEOUT    = 8.0
local HOLD_SECONDS     = 1.2
local STABLE_NEEDED    = 40
local STABLE_DIST      = 0.6
local CONFIRM_DIST     = 2.5
local VERIFY_DIST      = 4.0
local SLOT_RETRY_MAX   = 5

-- ════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════
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

local gridCols   = 3
local gridLayers = 1
local gridRows   = 0

local clickSelEnabled = false
local lassoEnabled    = false
local groupSelEnabled = false
local lassoStartPos   = nil
local lassoDragging   = false

local followConn = nil

-- ════════════════════════════════════════════════════
-- ITEM IDENTIFICATION
-- ════════════════════════════════════════════════════
local function isSortableItem(model)
    if not model or not model:IsA("Model") then return false end
    if model == workspace then return false end
    local mp = model:FindFirstChild("Main") or model:FindFirstChildWhichIsA("BasePart")
    if not mp then return false end
    if model:FindFirstChild("TreeClass") then return false end
    return model:FindFirstChild("Owner") ~= nil
        or model:FindFirstChild("PurchasedBoxItemName") ~= nil
        or model:FindFirstChild("DraggableItem") ~= nil
        or model:FindFirstChild("ItemName") ~= nil
end

local function getMainPart(model)
    return model:FindFirstChild("Main") or model:FindFirstChildWhichIsA("BasePart")
end

-- ════════════════════════════════════════════════════
-- SELECTION
-- ════════════════════════════════════════════════════
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

-- ════════════════════════════════════════════════════
-- SLOT CALCULATOR
-- ════════════════════════════════════════════════════
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
            model  = e.model,
            cf     = anchorCF * CFrame.new(lx, ly, lz),
            layer  = e.layer,
        })
    end
    return slots
end

-- ════════════════════════════════════════════════════
-- PREVIEW BOX
-- ════════════════════════════════════════════════════
local function destroyPreview()
    if followConn then followConn:Disconnect(); followConn = nil end
    if previewPart and previewPart.Parent then previewPart:Destroy() end
    previewPart = nil; previewFollowing = false; previewPlaced = false
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
    previewPart.Size         = Vector3.new(math.max(sX,0.5), math.max(sY,0.5), math.max(sZ,0.5))
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
    previewFollowing = true; previewPlaced = false
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

-- ════════════════════════════════════════════════════
-- SORT ENGINE
-- ════════════════════════════════════════════════════
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
        if (hrp.Position - mp.Position).Magnitude > 16 then goNear(mp.Position, hrp) end
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

-- ════════════════════════════════════════════════════
-- UI HELPERS
-- ════════════════════════════════════════════════════
local function mkLabel(text)
    local lbl = Instance.new("TextLabel", sorterPage)
    lbl.Size = UDim2.new(1, -12, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
    lbl.TextColor3 = C.TEXT_DIM
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 4)
end

local function mkSep()
    local s = Instance.new("Frame", sorterPage)
    s.Size = UDim2.new(1, -12, 0, 1)
    s.BackgroundColor3 = C.BORDER
    s.BorderSizePixel  = 0
end

-- Toggle: dark grey OFF / white ON
local function mkToggle(text, default, cb)
    local fr = Instance.new("Frame", sorterPage)
    fr.Size = UDim2.new(1, -12, 0, 32)
    fr.BackgroundColor3 = C.CARD
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", fr)
    lbl.Size = UDim2.new(1, -50, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = text
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = C.TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left

    -- white ON / dark grey OFF
    local SW_ON  = Color3.fromRGB(220, 220, 220)
    local SW_OFF = Color3.fromRGB(50,  50,  50)

    local tb = Instance.new("TextButton", fr)
    tb.Size = UDim2.new(0, 34, 0, 18); tb.Position = UDim2.new(1, -44, 0.5, -9)
    tb.BackgroundColor3 = default and SW_ON or SW_OFF
    tb.Text = ""; tb.AutoButtonColor = false
    Instance.new("UICorner", tb).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame", tb)
    dot.Size = UDim2.new(0, 14, 0, 14)
    dot.Position = UDim2.new(0, default and 18 or 2, 0.5, -7)
    dot.BackgroundColor3 = default and Color3.fromRGB(30,30,30) or Color3.fromRGB(160,160,160)
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local on = default
    if cb then cb(on) end
    tb.MouseButton1Click:Connect(function()
        on = not on
        TweenService:Create(tb,  TweenInfo.new(0.18, Enum.EasingStyle.Quint),
            { BackgroundColor3 = on and SW_ON or SW_OFF }):Play()
        TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
            Position         = UDim2.new(0, on and 18 or 2, 0.5, -7),
            BackgroundColor3 = on and Color3.fromRGB(30,30,30) or Color3.fromRGB(160,160,160)
        }):Play()
        if cb then cb(on) end
    end)
    return fr
end

-- Grey button
local function mkBtn(text, color, cb)
    color = color or C.BTN
    local btn = Instance.new("TextButton", sorterPage)
    btn.Size = UDim2.new(1, -12, 0, 34)
    btn.BackgroundColor3 = color
    btn.Text = text; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = C.TEXT; btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    -- simple brightness bump for hover
    local r = math.min(color.R * 255 + 22, 255) / 255
    local g = math.min(color.G * 255 + 22, 255) / 255
    local b = math.min(color.B * 255 + 22, 255) / 255
    local hov = Color3.new(r, g, b)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = hov}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = color}):Play()
    end)
    btn.MouseButton1Click:Connect(cb)
    return btn
end

-- Int slider (axis colours kept for usability)
local AXIS_COLORS = {
    X = C.AXIS_X,
    Y = C.AXIS_Y,
    Z = C.AXIS_Z,
}

local function mkIntSlider(label, axis, minV, maxV, defaultV, cb)
    local axCol = AXIS_COLORS[axis] or C.TEXT

    local fr = Instance.new("Frame", sorterPage)
    fr.Size = UDim2.new(1, -12, 0, 54)
    fr.BackgroundColor3 = C.CARD; fr.BorderSizePixel = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 6)

    local axTag = Instance.new("TextLabel", fr)
    axTag.Size = UDim2.new(0, 18, 0, 22); axTag.Position = UDim2.new(0, 8, 0, 5)
    axTag.BackgroundTransparency = 1; axTag.Font = Enum.Font.GothamBold
    axTag.TextSize = 14; axTag.TextColor3 = axCol; axTag.Text = axis

    local topLbl = Instance.new("TextLabel", fr)
    topLbl.Size = UDim2.new(0.55, 0, 0, 22); topLbl.Position = UDim2.new(0, 28, 0, 5)
    topLbl.BackgroundTransparency = 1; topLbl.Font = Enum.Font.GothamSemibold
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
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((defaultV-minV)/(maxV-minV), 0, 1, 0)
    fill.BackgroundColor3 = axCol; fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0, 18, 0, 18); knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((defaultV-minV)/(maxV-minV), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255); knob.Text = ""
    knob.BorderSizePixel = 0; knob.AutoButtonColor = false
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local dragging = false; local cur = defaultV
    local function apply(screenX)
        local ratio = math.clamp(
            (screenX - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local val = math.round(minV + ratio*(maxV-minV))
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

-- ════════════════════════════════════════════════════
-- STATUS CARD  (black inner / grey border)
-- ════════════════════════════════════════════════════
local statusCard, statusLabel
do
    local card = Instance.new("Frame")
    card.Size             = UDim2.new(1, -12, 0, 48)
    card.BackgroundColor3 = C.CARD
    card.BorderSizePixel  = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = C.BORDER; stroke.Thickness = 1; stroke.Transparency = 0.3
    local lbl = Instance.new("TextLabel", card)
    lbl.Size               = UDim2.new(1, -16, 1, 0)
    lbl.Position           = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamSemibold
    lbl.TextSize           = 12
    lbl.TextColor3         = C.TEXT
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.TextWrapped        = true
    lbl.Text               = "Select items to get started."
    statusCard  = card
    statusLabel = lbl
end

local function setStatus(msg, col)
    statusLabel.Text       = msg
    statusLabel.TextColor3 = col or C.TEXT
end

-- ════════════════════════════════════════════════════
-- PROGRESS BAR  (white bar / white text)
-- ════════════════════════════════════════════════════
local pbContainer, pbFill, pbLabel
do
    local pb = Instance.new("Frame")
    pb.Size             = UDim2.new(1, -12, 0, 44)
    pb.BackgroundColor3 = C.CARD
    pb.BorderSizePixel  = 0; pb.Visible = false
    Instance.new("UICorner", pb).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", pb)
    stroke.Color = C.BORDER; stroke.Thickness = 1; stroke.Transparency = 0.4

    local lbl = Instance.new("TextLabel", pb)
    lbl.Size               = UDim2.new(1, -12, 0, 16)
    lbl.Position           = UDim2.new(0, 6, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamSemibold; lbl.TextSize = 11
    lbl.TextColor3         = C.PB_FILL                              -- white text
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = "Sorting..."

    local track = Instance.new("Frame", pb)
    track.Size             = UDim2.new(1, -12, 0, 12)
    track.Position         = UDim2.new(0, 6, 0, 26)
    track.BackgroundColor3 = C.PB_TRACK; track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fl = Instance.new("Frame", track)
    fl.Size             = UDim2.new(0, 0, 1, 0)
    fl.BackgroundColor3 = C.PB_FILL                                 -- white bar
    fl.BorderSizePixel  = 0
    Instance.new("UICorner", fl).CornerRadius = UDim.new(1, 0)

    pbContainer = pb; pbFill = fl; pbLabel = lbl
end

local function hideProgress(delay)
    task.delay(delay or 2.0, function()
        if not pbContainer then return end
        TweenService:Create(pbContainer, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        TweenService:Create(pbFill,      TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        TweenService:Create(pbLabel,     TweenInfo.new(0.4), {TextTransparency      = 1}):Play()
        task.delay(0.45, function()
            if not pbContainer then return end
            pbContainer.Visible             = false
            pbContainer.BackgroundTransparency = 0
            pbFill.BackgroundTransparency   = 0
            pbFill.BackgroundColor3         = C.PB_FILL
            pbFill.Size                     = UDim2.new(0, 0, 1, 0)
            pbLabel.TextTransparency        = 0
        end)
    end)
end

-- ════════════════════════════════════════════════════
-- LASSO OVERLAY  (grey tones)
-- ════════════════════════════════════════════════════
local coreGui    = game:GetService("CoreGui")
local lassoFrame = Instance.new("Frame", coreGui:FindFirstChild("VanillaHub") or coreGui)
lassoFrame.Name                   = "SorterLasso"
lassoFrame.BackgroundColor3       = Color3.fromRGB(100, 100, 100)
lassoFrame.BackgroundTransparency = 0.82
lassoFrame.BorderSizePixel        = 0
lassoFrame.Visible                = false
lassoFrame.ZIndex                 = 20
local lstroke = Instance.new("UIStroke", lassoFrame)
lstroke.Color = Color3.fromRGB(190, 190, 190); lstroke.Thickness = 1.5

local function updateLassoVis(s, cur)
    local minX = math.min(s.X, cur.X); local minY = math.min(s.Y, cur.Y)
    lassoFrame.Position = UDim2.new(0, minX, 0, minY)
    lassoFrame.Size     = UDim2.new(0, math.abs(cur.X-s.X), 0, math.abs(cur.Y-s.Y))
end

local function selectLasso()
    if not lassoStartPos then return end
    local cur  = Vector2.new(mouse.X, mouse.Y)
    local minX = math.min(lassoStartPos.X, cur.X); local maxX = math.max(lassoStartPos.X, cur.X)
    local minY = math.min(lassoStartPos.Y, cur.Y); local maxY = math.max(lassoStartPos.Y, cur.Y)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and isSortableItem(obj) then
            local mp2 = getMainPart(obj)
            if mp2 then
                local sp, vis = camera:WorldToScreenPoint(mp2.Position)
                if vis and sp.X>=minX and sp.X<=maxX and sp.Y>=minY and sp.Y<=maxY then
                    highlightItem(obj)
                end
            end
        end
    end
end

-- ════════════════════════════════════════════════════
-- START / STOP (forward refs)
-- ════════════════════════════════════════════════════
local startBtn, stopBtn

local function refreshStatus()
    local n = countSelected()
    if isSorting then
        setStatus("⏳  Sorting in progress...", C.TEXT)
    elseif isStopped then
        setStatus("⏸  Paused — hit Start to resume.", C.TEXT_MID)
    elseif overflowBlocked then
        setStatus("❌  Too many items! Increase X, Y, or Z then regenerate.", C.TEXT_MID)
    elseif n == 0 then
        setStatus("👆  Select items with Click, Group, or Lasso.", C.TEXT_DIM)
    elseif previewFollowing then
        setStatus("🖱  Preview following mouse — click to place.", C.TEXT)
    elseif previewPlaced then
        setStatus("✅  " .. n .. " item(s) ready. Hit Start Sorting!", C.TEXT)
    elseif previewPart then
        setStatus("📦  Preview exists. Click anywhere to place it.", C.TEXT_MID)
    else
        setStatus("📦  " .. n .. " selected. Click Generate Preview.", C.TEXT_MID)
    end

    if startBtn then
        local canSort = (n > 0 or isStopped)
                        and (previewPlaced or isStopped)
                        and not isSorting
                        and not overflowBlocked
        -- active = mid-grey, disabled = near-black
        startBtn.BackgroundColor3 = canSort and C.BTN_ACT or C.BTN_DIS
        startBtn.TextColor3       = canSort and C.TEXT    or C.TEXT_DIM
        startBtn.Text = isStopped and "▶  Resume Sorting" or "▶  Start Sorting"
    end
    if stopBtn then
        -- active = slightly lighter grey, inactive = near-black
        stopBtn.BackgroundColor3 = isSorting and C.BTN or C.BTN_DIS
        stopBtn.TextColor3       = isSorting and C.TEXT or C.TEXT_DIM
    end
end

-- ════════════════════════════════════════════════════
-- BUILD UI
-- ════════════════════════════════════════════════════
mkLabel("Status")
statusCard.Parent = sorterPage

mkSep()
mkLabel("Selection Mode")

mkToggle("Click Selection", false, function(v)
    clickSelEnabled = v
    if v then lassoEnabled = false; groupSelEnabled = false end
end)
mkToggle("Group Selection", false, function(v)
    groupSelEnabled = v
    if v then clickSelEnabled = false; lassoEnabled = false end
end)
mkToggle("Lasso Tool", false, function(v)
    lassoEnabled = v
    if v then clickSelEnabled = false; groupSelEnabled = false end
end)

local selHint = Instance.new("TextLabel", sorterPage)
selHint.Size             = UDim2.new(1, -12, 0, 26)
selHint.BackgroundColor3 = C.CARD
selHint.BorderSizePixel  = 0
selHint.Font             = Enum.Font.Gotham; selHint.TextSize = 11
selHint.TextColor3       = C.TEXT_DIM; selHint.TextWrapped = true
selHint.TextXAlignment   = Enum.TextXAlignment.Left
selHint.Text             = "  Lasso: drag to box-select.  Group: click to select all of same type."
Instance.new("UICorner", selHint).CornerRadius = UDim.new(0, 6)
Instance.new("UIPadding", selHint).PaddingLeft = UDim.new(0, 6)

mkBtn("Clear Selection", C.BTN, function()
    unhighlightAll(); refreshStatus()
end)

mkSep()
mkLabel("Sort Grid  —  X  Width · Y  Height · Z  Depth")

mkIntSlider("Width  (items per row)", "X", 1, 12, 3, function(v)
    gridCols = v
    overflowBlocked = false
    if overflowPopup then overflowPopup.Visible = false end
    if previewFollowing and previewPart and previewPart.Parent then
        local sX, sY, sZ = computePreviewSize()
        previewPart.Size = Vector3.new(math.max(sX,0.5), math.max(sY,0.5), math.max(sZ,0.5))
    end
end)

mkIntSlider("Height  (vertical layers)", "Y", 1, 5, 1, function(v)
    gridLayers = v
    overflowBlocked = false
    if overflowPopup then overflowPopup.Visible = false end
    if previewFollowing and previewPart and previewPart.Parent then
        local sX, sY, sZ = computePreviewSize()
        previewPart.Size = Vector3.new(math.max(sX,0.5), math.max(sY,0.5), math.max(sZ,0.5))
    end
end)

mkIntSlider("Depth  (rows, 0=auto)", "Z", 0, 12, 0, function(v)
    gridRows = v
    overflowBlocked = false
    if overflowPopup then overflowPopup.Visible = false end
    if previewFollowing and previewPart and previewPart.Parent then
        local sX, sY, sZ = computePreviewSize()
        previewPart.Size = Vector3.new(math.max(sX,0.5), math.max(sY,0.5), math.max(sZ,0.5))
    end
end)

local gridHint = Instance.new("TextLabel", sorterPage)
gridHint.Size             = UDim2.new(1, -12, 0, 28)
gridHint.BackgroundColor3 = C.CARD
gridHint.BorderSizePixel  = 0
gridHint.Font             = Enum.Font.Gotham; gridHint.TextSize = 11
gridHint.TextColor3       = C.TEXT_DIM; gridHint.TextWrapped = true
gridHint.TextXAlignment   = Enum.TextXAlignment.Left
gridHint.Text             = "  Fills left→right (X), front→back (Z), bottom→top (Y). Tallest items first. Z=0 auto."
Instance.new("UICorner", gridHint).CornerRadius = UDim.new(0, 6)
Instance.new("UIPadding", gridHint).PaddingLeft = UDim.new(0, 6)

-- Overflow popup (dark card + grey border — no red)
local overflowPopup, overflowLabel
do
    local pop = Instance.new("Frame")
    pop.Size             = UDim2.new(1, -12, 0, 52)
    pop.BackgroundColor3 = C.CARD
    pop.BorderSizePixel  = 0; pop.Visible = false
    Instance.new("UICorner", pop).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", pop)
    stroke.Color = C.BORDER; stroke.Thickness = 1.5; stroke.Transparency = 0.2
    local lbl = Instance.new("TextLabel", pop)
    lbl.Size               = UDim2.new(1, -16, 1, 0)
    lbl.Position           = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamSemibold; lbl.TextSize = 12
    lbl.TextColor3         = C.TEXT_MID
    lbl.TextXAlignment     = Enum.TextXAlignment.Left; lbl.TextWrapped = true
    lbl.Text               = ""
    overflowPopup = pop
    overflowLabel = lbl
end
overflowPopup.Parent = sorterPage

local function showOverflow(msg)
    overflowBlocked = true
    overflowLabel.Text = "⚠  " .. msg
    overflowPopup.Visible = true
end

local function hideOverflow()
    overflowBlocked = false
    overflowPopup.Visible = false
end

local function gridCapacity()
    local cols   = math.max(1, gridCols)
    local layers = math.max(1, gridLayers)
    local rows   = math.max(0, gridRows)
    if rows == 0 then return math.huge end
    return cols * rows * layers
end

mkSep()
mkLabel("Preview")

mkBtn("Generate Preview  (follows mouse)", C.BTN, function()
    if countSelected() == 0 then
        setStatus("⚠  No items selected!"); return
    end
    local n   = countSelected()
    local cap = gridCapacity()
    if n > cap then
        showOverflow(n .. " items but grid only fits " .. cap ..
            "  (X=" .. gridCols .. " × Z=" .. gridRows .. " × Y=" .. gridLayers ..
            "). Increase sliders.")
        refreshStatus(); return
    end
    hideOverflow()
    local sX, sY, sZ = computePreviewSize()
    buildPreviewBox(sX, sY, sZ)
    startPreviewFollow()
    refreshStatus()
end)

mkBtn("Clear Preview", C.BTN, function()
    destroyPreview(); refreshStatus()
end)

mkSep()
mkLabel("Actions")

-- ════════════════════════════════════════════════════
-- START BUTTON
-- ════════════════════════════════════════════════════
startBtn = Instance.new("TextButton", sorterPage)
startBtn.Size             = UDim2.new(1, -12, 0, 36)
startBtn.BackgroundColor3 = C.BTN_DIS
startBtn.Text             = "▶  Start Sorting"
startBtn.Font             = Enum.Font.GothamBold
startBtn.TextSize         = 14; startBtn.TextColor3 = C.TEXT_DIM
startBtn.BorderSizePixel  = 0; startBtn.AutoButtonColor = false
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 6)

local function runSortLoop(slots, startI, total, doneStart)
    local done = doneStart

    sortThread = task.spawn(function()
        local i         = startI
        local prevLayer = slots[startI] and slots[startI].layer or 0

        while i <= total and isSorting do
            local slot     = slots[i]
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
                pbLabel.Text = "Sorting " .. done+1 .. "/" .. total
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

        isSorting = false; sortThread = nil

        if done >= total then
            isStopped = false; sortSlots = nil
            TweenService:Create(pbFill, TweenInfo.new(0.25), {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = C.PB_DONE                       -- white when done
            }):Play()
            pbLabel.Text = "✔  Sorting complete!"
            destroyPreview(); unhighlightAll(); hideProgress(2.5)
        else
            isStopped = true
            pbLabel.Text = "⏸  Stopped at " .. done .. " / " .. total
        end
        refreshStatus()
    end)
end

startBtn.MouseButton1Click:Connect(function()
    if isSorting then return end
    if overflowBlocked then setStatus("❌  Fix grid size first!"); return end

    if isStopped and sortSlots then
        isStopped = false; isSorting = true
        pbContainer.Visible     = true
        pbFill.BackgroundColor3 = C.PB_FILL
        pbLabel.Text            = "Sorting... " .. sortDone .. " / " .. sortTotal
        refreshStatus()
        runSortLoop(sortSlots, sortIndex, sortTotal, sortDone)
        return
    end

    if not (previewPlaced and previewPart and previewPart.Parent) then
        setStatus("⚠  Generate a preview and place it first!"); return
    end
    if countSelected() == 0 then setStatus("⚠  No items selected!"); return end

    local items = {}
    for model in pairs(selectedItems) do
        if model and model.Parent then table.insert(items, model) end
    end
    if #items == 0 then return end

    local anchorCF = previewPart.CFrame
        * CFrame.new(-previewPart.Size.X/2, -previewPart.Size.Y/2, -previewPart.Size.Z/2)

    sortSlots = calculateSlots(items, anchorCF, gridCols, gridLayers, gridRows)
    sortTotal = #sortSlots; sortDone = 0; sortIndex = 1
    isStopped = false; isSorting = true

    pbContainer.Visible     = true
    pbFill.Size             = UDim2.new(0, 0, 1, 0)
    pbFill.BackgroundColor3 = C.PB_FILL
    pbLabel.Text            = "Sorting... 0 / " .. sortTotal
    refreshStatus()
    runSortLoop(sortSlots, 1, sortTotal, 0)
end)

-- ════════════════════════════════════════════════════
-- STOP BUTTON
-- ════════════════════════════════════════════════════
stopBtn = Instance.new("TextButton", sorterPage)
stopBtn.Size             = UDim2.new(1, -12, 0, 32)
stopBtn.BackgroundColor3 = C.BTN_DIS
stopBtn.Text             = "⏹  Stop"
stopBtn.Font             = Enum.Font.GothamBold
stopBtn.TextSize         = 13; stopBtn.TextColor3 = C.TEXT_DIM
stopBtn.BorderSizePixel  = 0; stopBtn.AutoButtonColor = false
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 6)
stopBtn.MouseButton1Click:Connect(function()
    if not isSorting then return end
    isSorting    = false
    pbLabel.Text = "⏸  Stopping..."
    refreshStatus()
end)

-- Cancel button (dark grey — no red)
mkBtn("Cancel  (clear all)", C.BTN, function()
    isSorting = false; isStopped = false
    sortSlots = nil; sortIndex = 1; sortTotal = 0; sortDone = 0
    if sortThread then pcall(task.cancel, sortThread); sortThread = nil end
    destroyPreview(); unhighlightAll(); hideOverflow()
    pbLabel.Text = "Cancelled."
    hideProgress(1.0)
    refreshStatus()
end)

pbContainer.Parent = sorterPage

-- ════════════════════════════════════════════════════
-- MOUSE INPUT
-- ════════════════════════════════════════════════════
local mouseDownConn = mouse.Button1Down:Connect(function()
    if lassoEnabled then
        lassoDragging = true
        lassoStartPos = Vector2.new(mouse.X, mouse.Y)
        lassoFrame.Size    = UDim2.new(0, 0, 0, 0)
        lassoFrame.Visible = true
        return
    end
    if previewFollowing then
        placePreview(); refreshStatus(); return
    end
    local target = mouse.Target
    if not target then return end
    local model = target:FindFirstAncestorOfClass("Model")
    if not model then return end
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
        lassoDragging = false
        selectLasso()
        lassoFrame.Visible = false
        lassoStartPos = nil
        refreshStatus()
    end
    lassoDragging = false
end)

-- ════════════════════════════════════════════════════
-- CLEANUP
-- ════════════════════════════════════════════════════
table.insert(cleanupTasks, function()
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
print("[VanillaHub] Vanilla4 (Sorter v2) loaded — black/grey/white theme")
