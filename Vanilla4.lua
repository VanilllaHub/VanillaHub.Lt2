-- ════════════════════════════════════════════════════
-- VANILLA4 — Sorter Tab  (v3 — clean layout + unified selection)
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
local BTN_COLOR        = _G.VH.BTN_COLOR
local BTN_HOVER        = _G.VH.BTN_HOVER        or Color3.fromRGB(50, 50, 65)
local ACCENT           = _G.VH.ACCENT           or Color3.fromRGB(100, 80, 200)
local THEME_TEXT       = _G.VH.THEME_TEXT        or Color3.fromRGB(230, 206, 226)
local SECTION_TEXT     = _G.VH.SECTION_TEXT      or Color3.fromRGB(120, 110, 140)
local SEP_COLOR        = _G.VH.SEP_COLOR         or Color3.fromRGB(40, 40, 55)

local sorterPage = pages["SorterTab"]
local camera     = workspace.CurrentCamera
local RS         = game:GetService("ReplicatedStorage")
local mouse      = player:GetMouse()

-- ════════════════════════════════════════════════════
-- CONSTANTS
-- ════════════════════════════════════════════════════
local HIGHLIGHT_COLOR = Color3.fromRGB(255, 180, 0)
local PREVIEW_COLOR   = Color3.fromRGB(80, 160, 255)
local PLACED_COLOR    = Color3.fromRGB(60, 210, 100)
local ITEM_GAP        = 0.08
local DRIVE_TIMEOUT   = 8.0
local HOLD_SECONDS    = 1.2
local STABLE_NEEDED   = 40
local STABLE_DIST     = 0.6
local CONFIRM_DIST    = 2.5
local VERIFY_DIST     = 4.0
local SLOT_RETRY_MAX  = 5

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

-- ── selection modes (mirrors Item Tab pattern exactly) ──
local clickSelEnabled = false
local lassoEnabled    = false
local groupSelEnabled = false

-- ── lasso drag state ──
local lassoStartPos = nil
local lassoDragging = false

-- ── preview follow connection ──
local followConn = nil

-- ── speed (shared with Item Tab's tpItemSpeed if present) ──
local sortSpeed = 0.3   -- seconds between items, default 0.3 = slider pos 3

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
-- SELECTION  (same style as Item Tab)
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

-- Click-toggle a single item
local function tryClickSelect(target)
    if not target then return end
    local model = target:FindFirstAncestorOfClass("Model") or target.Parent
    if not model then return end
    if not isSortableItem(model) then return end
    if selectedItems[model] then unhighlightItem(model) else highlightItem(model) end
end

-- Select all items of the same type as clicked target
local function tryGroupSelect(target)
    if not target then return end
    local model = target:FindFirstAncestorOfClass("Model") or target.Parent
    if not (model and isSortableItem(model)) then return end
    local nv = model:FindFirstChild("ItemName") or model:FindFirstChild("PurchasedBoxItemName")
    local targetName = nv and nv.Value or model.Name
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and isSortableItem(obj) then
            local v = obj:FindFirstChild("ItemName") or obj:FindFirstChild("PurchasedBoxItemName")
            local n = v and v.Value or obj.Name
            if n == targetName then highlightItem(obj) end
        end
    end
end

-- ════════════════════════════════════════════════════
-- LASSO  (same approach as Item Tab)
-- ════════════════════════════════════════════════════
local coreGui    = game:GetService("CoreGui")
local lassoFrame = Instance.new("Frame", coreGui:FindFirstChild("VanillaHub") or coreGui)
lassoFrame.Name                  = "SorterLasso"
lassoFrame.BackgroundColor3      = Color3.fromRGB(90, 130, 210)
lassoFrame.BackgroundTransparency = 0.82
lassoFrame.BorderSizePixel       = 0
lassoFrame.Visible               = false
lassoFrame.ZIndex                = 20
local lstroke = Instance.new("UIStroke", lassoFrame)
lstroke.Color       = Color3.fromRGB(130, 160, 240)
lstroke.Thickness   = 1.5
lstroke.Transparency = 0

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

-- ════════════════════════════════════════════════════
-- SORT SLOT CALCULATOR  (unchanged logic)
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
            model = e.model,
            cf    = anchorCF * CFrame.new(lx, ly, lz),
            layer = e.layer,
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
        hitPos = (t and t > 0)
            and (unitRay.Origin + unitRay.Direction * t)
            or  (unitRay.Origin + unitRay.Direction * 40)
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
    previewPart.CFrame = getMouseSurfaceCF(previewPart.Size.Y / 2)
    previewPart.Color  = PLACED_COLOR
    local sb = previewPart:FindFirstChildOfClass("SelectionBox")
    if sb then sb.Color3 = PLACED_COLOR end
    previewPlaced = true
end

-- ════════════════════════════════════════════════════
-- SORT ENGINE  (unchanged logic)
-- ════════════════════════════════════════════════════
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

local function isnetworkowner(part)
    return part.ReceiveAge == 0
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

local pbLabel  -- forward ref (defined in UI section below)

local function fixDriftedSlots(slots, upTo)
    for i = 1, upTo do
        if not isSorting then break end
        local slot = slots[i]
        if slot and not isSlotFilled(slot) then
            if pbLabel then pbLabel.Text = "🔧 Re-fixing slot " .. i .. " ..." end
            placeAndLock(slot.model, slot.cf)
        end
    end
end

-- ════════════════════════════════════════════════════
-- UI PRIMITIVES
-- ════════════════════════════════════════════════════
local function sSection(text)
    local w = Instance.new("Frame", sorterPage)
    w.Size = UDim2.new(1, 0, 0, 22); w.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", w)
    lbl.Size = UDim2.new(1, -4, 1, 0); lbl.Position = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 10
    lbl.TextColor3 = SECTION_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "  " .. string.upper(text)
end

local function sSep()
    local sep = Instance.new("Frame", sorterPage)
    sep.Size = UDim2.new(1, 0, 0, 1)
    sep.BackgroundColor3 = SEP_COLOR; sep.BorderSizePixel = 0
end

local function sButton(text, col, cb)
    col = col or BTN_COLOR
    local btn = Instance.new("TextButton", sorterPage)
    btn.Size = UDim2.new(1, 0, 0, 34); btn.BackgroundColor3 = col
    btn.Text = text; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = THEME_TEXT; btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local hov = Color3.fromRGB(
        math.min(col.R*255+20,255)/255,
        math.min(col.G*255+10,255)/255,
        math.min(col.B*255+20,255)/255)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3=hov}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3=col}):Play()
    end)
    if cb then btn.MouseButton1Click:Connect(cb) end
    return btn
end

-- Identical toggle style to Item Tab
local function sToggle(text, default, cb)
    local frame = Instance.new("Frame", sorterPage)
    frame.Size = UDim2.new(1, 0, 0, 36); frame.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -54, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13; lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local tb = Instance.new("TextButton", frame)
    tb.Size = UDim2.new(0, 36, 0, 20); tb.Position = UDim2.new(1, -46, 0.5, -10)
    tb.BackgroundColor3 = default and Color3.fromRGB(80,160,80) or Color3.fromRGB(38,38,45)
    tb.Text = ""; tb.BorderSizePixel = 0
    Instance.new("UICorner", tb).CornerRadius = UDim.new(1, 0)
    local circle = Instance.new("Frame", tb)
    circle.Size = UDim2.new(0, 14, 0, 14)
    circle.Position = UDim2.new(0, default and 20 or 2, 0.5, -7)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255); circle.BorderSizePixel = 0
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    local toggled = default
    if cb then cb(toggled) end
    tb.MouseButton1Click:Connect(function()
        toggled = not toggled
        TweenService:Create(tb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            BackgroundColor3 = toggled and Color3.fromRGB(80,160,80) or Color3.fromRGB(38,38,45)
        }):Play()
        TweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, toggled and 20 or 2, 0.5, -7)
        }):Play()
        if cb then cb(toggled) end
    end)
    return frame
end

-- Identical slider style to Item Tab
local function sSlider(text, minV, maxV, defV, cb)
    local frame = Instance.new("Frame", sorterPage)
    frame.Size = UDim2.new(1, 0, 0, 54); frame.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local topRow = Instance.new("Frame", frame)
    topRow.Size = UDim2.new(1, -16, 0, 22); topRow.Position = UDim2.new(0, 8, 0, 7)
    topRow.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", topRow)
    lbl.Size = UDim2.new(0.72, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = text
    local valLbl = Instance.new("TextLabel", topRow)
    valLbl.Size = UDim2.new(0.28, 0, 1, 0); valLbl.Position = UDim2.new(0.72, 0, 0, 0)
    valLbl.BackgroundTransparency = 1; valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 13
    valLbl.TextColor3 = Color3.fromRGB(160, 160, 175); valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Text = tostring(defV)
    local track = Instance.new("Frame", frame)
    track.Size = UDim2.new(1, -16, 0, 5); track.Position = UDim2.new(0, 8, 0, 38)
    track.BackgroundColor3 = Color3.fromRGB(32, 32, 38); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((defV-minV)/(maxV-minV), 0, 1, 0)
    fill.BackgroundColor3 = ACCENT; fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0, 14, 0, 14); knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((defV-minV)/(maxV-minV), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(210, 210, 220); knob.Text = ""; knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local ds = false
    local function upd(absX)
        local r = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.round(minV + r * (maxV - minV))
        fill.Size = UDim2.new(r, 0, 1, 0); knob.Position = UDim2.new(r, 0, 0.5, 0)
        valLbl.Text = tostring(v)
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
end

-- Compact axis slider (X/Y/Z grid controls, coloured axis tag)
local AXIS_COLORS = {
    X = Color3.fromRGB(220, 70,  70),
    Y = Color3.fromRGB(70,  200, 70),
    Z = Color3.fromRGB(70,  120, 255),
}

local function sAxisSlider(label, axis, minV, maxV, defaultV, cb)
    local axCol = AXIS_COLORS[axis] or THEME_TEXT
    local fr = Instance.new("Frame", sorterPage)
    fr.Size = UDim2.new(1, 0, 0, 54)
    fr.BackgroundColor3 = Color3.fromRGB(16, 16, 20); fr.BorderSizePixel = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 8)

    local axTag = Instance.new("TextLabel", fr)
    axTag.Size = UDim2.new(0, 18, 0, 22); axTag.Position = UDim2.new(0, 8, 0, 7)
    axTag.BackgroundTransparency = 1; axTag.Font = Enum.Font.GothamBold
    axTag.TextSize = 14; axTag.TextColor3 = axCol; axTag.Text = axis

    local topLbl = Instance.new("TextLabel", fr)
    topLbl.Size = UDim2.new(0.6, 0, 0, 22); topLbl.Position = UDim2.new(0, 28, 0, 7)
    topLbl.BackgroundTransparency = 1; topLbl.Font = Enum.Font.GothamSemibold
    topLbl.TextSize = 12; topLbl.TextColor3 = THEME_TEXT
    topLbl.TextXAlignment = Enum.TextXAlignment.Left; topLbl.Text = label

    local valLbl = Instance.new("TextLabel", fr)
    valLbl.Size = UDim2.new(0.25, 0, 0, 22); valLbl.Position = UDim2.new(0.75, -8, 0, 7)
    valLbl.BackgroundTransparency = 1; valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 13; valLbl.TextColor3 = axCol
    valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.Text = tostring(defaultV)

    local track = Instance.new("Frame", fr)
    track.Size = UDim2.new(1, -16, 0, 5); track.Position = UDim2.new(0, 8, 0, 38)
    track.BackgroundColor3 = Color3.fromRGB(32, 32, 38); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((defaultV-minV)/(maxV-minV), 0, 1, 0)
    fill.BackgroundColor3 = axCol; fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0, 14, 0, 14); knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((defaultV-minV)/(maxV-minV), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(210, 210, 220); knob.Text = ""; knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local ds = false; local cur = defaultV
    local function upd(absX)
        local ratio = math.clamp(
            (absX - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local val = math.round(minV + ratio * (maxV - minV))
        if val == cur then return end
        cur = val
        fill.Size = UDim2.new(ratio, 0, 1, 0); knob.Position = UDim2.new(ratio, 0, 0.5, 0)
        valLbl.Text = tostring(val)
        if cb then cb(val) end
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

-- Hint bar (small muted info text)
local function sHint(text)
    local lbl = Instance.new("TextLabel", sorterPage)
    lbl.Size = UDim2.new(1, 0, 0, 22); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(85, 85, 105)
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.TextWrapped = true
    lbl.Text = "  " .. text
end

-- ════════════════════════════════════════════════════
-- STATUS CARD  (forward ref: statusLabel)
-- ════════════════════════════════════════════════════
local statusLabel
do
    local card = Instance.new("Frame", sorterPage)
    card.Size = UDim2.new(1, 0, 0, 44)
    card.BackgroundColor3 = Color3.fromRGB(24, 18, 34)
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(255, 180, 0); stroke.Thickness = 1; stroke.Transparency = 0.55
    local lbl = Instance.new("TextLabel", card)
    lbl.Size = UDim2.new(1, -16, 1, 0); lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(255, 210, 100)
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.TextWrapped = true
    lbl.Text = "Select items to get started."
    statusLabel = lbl
end

local function setStatus(msg, col)
    statusLabel.Text       = msg
    statusLabel.TextColor3 = col or Color3.fromRGB(255, 210, 100)
end

-- ════════════════════════════════════════════════════
-- PROGRESS BAR  (forward refs: pbContainer, pbFill, pbLabel)
-- ════════════════════════════════════════════════════
local pbContainer, pbFill
do
    local pb = Instance.new("Frame")
    pb.Size = UDim2.new(1, 0, 0, 44)
    pb.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    pb.BorderSizePixel = 0; pb.Visible = false
    Instance.new("UICorner", pb).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", pb)
    stroke.Color = Color3.fromRGB(60, 60, 80); stroke.Thickness = 1; stroke.Transparency = 0.5

    local lbl = Instance.new("TextLabel", pb)
    lbl.Size = UDim2.new(1, -12, 0, 16); lbl.Position = UDim2.new(0, 6, 0, 4)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 11
    lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "Sorting..."

    local track = Instance.new("Frame", pb)
    track.Size = UDim2.new(1, -12, 0, 12); track.Position = UDim2.new(0, 6, 0, 26)
    track.BackgroundColor3 = Color3.fromRGB(30, 30, 42); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fl = Instance.new("Frame", track)
    fl.Size = UDim2.new(0, 0, 1, 0)
    fl.BackgroundColor3 = Color3.fromRGB(255, 175, 55)
    fl.BorderSizePixel = 0
    Instance.new("UICorner", fl).CornerRadius = UDim.new(1, 0)

    pbContainer = pb; pbFill = fl; pbLabel = lbl
end

local function hideProgress(delay)
    task.delay(delay or 2.0, function()
        if not pbContainer then return end
        TweenService:Create(pbContainer, TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
        TweenService:Create(pbFill,      TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
        TweenService:Create(pbLabel,     TweenInfo.new(0.4), {TextTransparency=1}):Play()
        task.delay(0.45, function()
            if not pbContainer then return end
            pbContainer.Visible = false
            pbContainer.BackgroundTransparency = 0
            pbFill.BackgroundTransparency = 0
            pbFill.BackgroundColor3 = Color3.fromRGB(255, 175, 55)
            pbFill.Size = UDim2.new(0, 0, 1, 0)
            pbLabel.TextTransparency = 0
        end)
    end)
end

-- ════════════════════════════════════════════════════
-- START / STOP forward refs
-- ════════════════════════════════════════════════════
local startBtn, stopBtn

local function refreshStatus()
    local n = countSelected()
    if isSorting then
        setStatus("⏳  Sorting in progress...", Color3.fromRGB(140,220,255))
    elseif isStopped then
        setStatus("⏸  Paused — hit Start to resume.", Color3.fromRGB(255,210,80))
    elseif overflowBlocked then
        setStatus("❌  Too many items! Increase X, Y, or Z then regenerate.", Color3.fromRGB(255,100,100))
    elseif n == 0 then
        setStatus("👆  Select items with Click, Group, or Lasso.")
    elseif previewFollowing then
        setStatus("🖱  Preview following mouse — click to place.", Color3.fromRGB(140,220,255))
    elseif previewPlaced then
        setStatus("✅  " .. n .. " item(s) ready. Hit Start Sorting!", Color3.fromRGB(100,220,120))
    elseif previewPart then
        setStatus("📦  Preview exists. Click anywhere to place it.", Color3.fromRGB(200,200,100))
    else
        setStatus("📦  " .. n .. " selected. Click Generate Preview.")
    end

    if startBtn then
        local canSort = (n > 0 or isStopped)
            and (previewPlaced or isStopped)
            and not isSorting
            and not overflowBlocked
        startBtn.BackgroundColor3 = canSort
            and Color3.fromRGB(35,100,50)
            or  Color3.fromRGB(28,28,38)
        startBtn.TextColor3 = canSort and THEME_TEXT or Color3.fromRGB(72,72,82)
        startBtn.Text = isStopped and "▶  Resume Sorting" or "▶  Start Sorting"
    end
    if stopBtn then
        stopBtn.BackgroundColor3 = isSorting
            and Color3.fromRGB(100,60,20)
            or  Color3.fromRGB(28,28,38)
        stopBtn.TextColor3 = isSorting
            and Color3.fromRGB(255,190,80)
            or  Color3.fromRGB(72,72,82)
    end
end

-- ════════════════════════════════════════════════════
-- BUILD UI  — clean linear layout
-- ════════════════════════════════════════════════════

-- ── 1. STATUS ───────────────────────────────────────
-- (statusCard already parented to sorterPage above)

sSep()

-- ── 2. SELECTION MODE ───────────────────────────────
sSection("Selection Mode")

sToggle("Click Selection", false, function(val)
    clickSelEnabled = val
    if val then lassoEnabled = false; groupSelEnabled = false end
end)
sToggle("Lasso Tool", false, function(val)
    lassoEnabled = val
    if val then clickSelEnabled = false; groupSelEnabled = false end
end)
sToggle("Group Selection", false, function(val)
    groupSelEnabled = val
    if val then clickSelEnabled = false; lassoEnabled = false end
end)

sHint("Lasso: drag to box-select.  Group: click to select all of same type.")
sButton("Deselect All", BTN_COLOR, function()
    unhighlightAll(); refreshStatus()
end)

sSep()

-- ── 3. SPEED ────────────────────────────────────────
sSection("Sort Speed")

sSlider("Delay per item (x0.1s)", 1, 20, 3, function(v)
    sortSpeed = v / 10
    -- keep Item Tab in sync if it exists
    if _G.VH and _G.VH.tpItemSpeed ~= nil then
        _G.VH.tpItemSpeed = sortSpeed
    end
end)

sSep()

-- ── 4. GRID ─────────────────────────────────────────
sSection("Sort Grid")

local function onGridChange()
    overflowBlocked = false
    -- live-update preview size if it's following
    if previewFollowing and previewPart and previewPart.Parent then
        local sX, sY, sZ = computePreviewSize()
        previewPart.Size = Vector3.new(
            math.max(sX, 0.5), math.max(sY, 0.5), math.max(sZ, 0.5))
    end
end

sAxisSlider("Width  (items per row)",    "X", 1, 12, 3, function(v) gridCols   = v; onGridChange() end)
sAxisSlider("Height  (vertical layers)", "Y", 1,  5, 1, function(v) gridLayers = v; onGridChange() end)
sAxisSlider("Depth  (rows, 0 = auto)",   "Z", 0, 12, 0, function(v) gridRows   = v; onGridChange() end)

sHint("Fills left→right (X), front→back (Z), bottom→top (Y). Tallest items first.")

-- Overflow warning
local overflowCard = Instance.new("Frame", sorterPage)
overflowCard.Size = UDim2.new(1, 0, 0, 44)
overflowCard.BackgroundColor3 = Color3.fromRGB(70, 18, 18)
overflowCard.BorderSizePixel = 0; overflowCard.Visible = false
Instance.new("UICorner", overflowCard).CornerRadius = UDim.new(0, 8)
local ovStroke = Instance.new("UIStroke", overflowCard)
ovStroke.Color = Color3.fromRGB(255, 80, 80); ovStroke.Thickness = 1.5; ovStroke.Transparency = 0.35
local overflowLabel = Instance.new("TextLabel", overflowCard)
overflowLabel.Size = UDim2.new(1, -16, 1, 0); overflowLabel.Position = UDim2.new(0, 8, 0, 0)
overflowLabel.BackgroundTransparency = 1; overflowLabel.Font = Enum.Font.GothamSemibold
overflowLabel.TextSize = 12; overflowLabel.TextColor3 = Color3.fromRGB(255, 130, 130)
overflowLabel.TextXAlignment = Enum.TextXAlignment.Left; overflowLabel.TextWrapped = true

local function gridCapacity()
    local cols   = math.max(1, gridCols)
    local layers = math.max(1, gridLayers)
    local rows   = math.max(0, gridRows)
    if rows == 0 then return math.huge end
    return cols * rows * layers
end

local function showOverflow(msg)
    overflowBlocked = true
    overflowLabel.Text = "⚠  " .. msg
    overflowCard.Visible = true
end

local function hideOverflow()
    overflowBlocked = false
    overflowCard.Visible = false
end

sSep()

-- ── 5. PREVIEW ──────────────────────────────────────
sSection("Preview")

local previewRow = Instance.new("Frame", sorterPage)
previewRow.Size = UDim2.new(1, 0, 0, 34); previewRow.BackgroundTransparency = 1

local genBtn = Instance.new("TextButton", previewRow)
genBtn.Size = UDim2.new(0.62, -4, 1, 0); genBtn.Position = UDim2.new(0, 0, 0, 0)
genBtn.BackgroundColor3 = Color3.fromRGB(30, 55, 110)
genBtn.Text = "Generate Preview"; genBtn.Font = Enum.Font.GothamSemibold; genBtn.TextSize = 13
genBtn.TextColor3 = THEME_TEXT; genBtn.BorderSizePixel = 0
Instance.new("UICorner", genBtn).CornerRadius = UDim.new(0, 8)

local clrPreviewBtn = Instance.new("TextButton", previewRow)
clrPreviewBtn.Size = UDim2.new(0.38, -4, 1, 0); clrPreviewBtn.Position = UDim2.new(0.62, 4, 0, 0)
clrPreviewBtn.BackgroundColor3 = BTN_COLOR
clrPreviewBtn.Text = "Clear Preview"; clrPreviewBtn.Font = Enum.Font.GothamSemibold; clrPreviewBtn.TextSize = 12
clrPreviewBtn.TextColor3 = THEME_TEXT; clrPreviewBtn.BorderSizePixel = 0
Instance.new("UICorner", clrPreviewBtn).CornerRadius = UDim.new(0, 8)

for _, b in {genBtn, clrPreviewBtn} do
    local base = b.BackgroundColor3
    local hov  = Color3.fromRGB(
        math.min(base.R*255+20,255)/255,
        math.min(base.G*255+10,255)/255,
        math.min(base.B*255+20,255)/255)
    b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=hov}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=base}):Play() end)
end

genBtn.MouseButton1Click:Connect(function()
    if countSelected() == 0 then
        setStatus("⚠  No items selected!"); return
    end
    local n   = countSelected()
    local cap = gridCapacity()
    if n > cap then
        showOverflow(n .. " items but grid only fits " .. cap
            .. "  (X=" .. gridCols .. " × Z=" .. gridRows .. " × Y=" .. gridLayers
            .. "). Increase sliders.")
        refreshStatus(); return
    end
    hideOverflow()
    local sX, sY, sZ = computePreviewSize()
    buildPreviewBox(sX, sY, sZ)
    startPreviewFollow()
    refreshStatus()
end)

clrPreviewBtn.MouseButton1Click:Connect(function()
    destroyPreview(); refreshStatus()
end)

sHint("Preview follows mouse — left-click to place it in the world.")

sSep()

-- ── 6. ACTIONS ──────────────────────────────────────
sSection("Actions")

startBtn = Instance.new("TextButton", sorterPage)
startBtn.Size = UDim2.new(1, 0, 0, 36)
startBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
startBtn.Text = "▶  Start Sorting"; startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 14; startBtn.TextColor3 = Color3.fromRGB(72,72,82)
startBtn.BorderSizePixel = 0
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 8)

local stopRow = Instance.new("Frame", sorterPage)
stopRow.Size = UDim2.new(1, 0, 0, 32); stopRow.BackgroundTransparency = 1

stopBtn = Instance.new("TextButton", stopRow)
stopBtn.Size = UDim2.new(0.48, -2, 1, 0); stopBtn.Position = UDim2.new(0, 0, 0, 0)
stopBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
stopBtn.Text = "⏹  Stop"; stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 13; stopBtn.TextColor3 = Color3.fromRGB(72,72,82)
stopBtn.BorderSizePixel = 0
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 8)

local cancelBtn = Instance.new("TextButton", stopRow)
cancelBtn.Size = UDim2.new(0.52, -2, 1, 0); cancelBtn.Position = UDim2.new(0.48, 2, 0, 0)
cancelBtn.BackgroundColor3 = Color3.fromRGB(65, 18, 18)
cancelBtn.Text = "✕  Cancel & Clear"; cancelBtn.Font = Enum.Font.GothamBold
cancelBtn.TextSize = 12; cancelBtn.TextColor3 = Color3.fromRGB(200,100,100)
cancelBtn.BorderSizePixel = 0
Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 8)

-- ── 7. PROGRESS ─────────────────────────────────────
pbContainer.Parent = sorterPage

-- ════════════════════════════════════════════════════
-- SORT LOOP
-- ════════════════════════════════════════════════════
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

            task.wait(sortSpeed)   -- ← uses the speed slider value
            i = i + 1
        end

        if isSorting and done >= total then
            pbLabel.Text = "🔍 Final check..."
            fixDriftedSlots(slots, total)
        end

        isSorting = false; sortThread = nil

        if done >= total then
            isStopped = false; sortSlots = nil
            TweenService:Create(pbFill, TweenInfo.new(0.25),
                { Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.fromRGB(90,220,110) }):Play()
            pbLabel.Text = "✔  Sorting complete!"
            destroyPreview(); unhighlightAll(); hideProgress(2.5)
        else
            isStopped = true
            pbLabel.Text = "⏸  Stopped at " .. done .. " / " .. total
        end
        refreshStatus()
    end)
end

-- ════════════════════════════════════════════════════
-- BUTTON LOGIC
-- ════════════════════════════════════════════════════
startBtn.MouseButton1Click:Connect(function()
    if isSorting then return end
    if overflowBlocked then setStatus("❌  Fix grid size first!"); return end

    -- Resume
    if isStopped and sortSlots then
        isStopped = false; isSorting = true
        pbContainer.Visible = true
        pbFill.BackgroundColor3 = Color3.fromRGB(255, 175, 55)
        pbLabel.Text = "Sorting... " .. sortDone .. " / " .. sortTotal
        refreshStatus()
        runSortLoop(sortSlots, sortIndex, sortTotal, sortDone)
        return
    end

    -- Fresh start
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

    pbContainer.Visible = true
    pbFill.Size = UDim2.new(0, 0, 1, 0)
    pbFill.BackgroundColor3 = Color3.fromRGB(255, 175, 55)
    pbLabel.Text = "Sorting... 0 / " .. sortTotal
    refreshStatus()
    runSortLoop(sortSlots, 1, sortTotal, 0)
end)

stopBtn.MouseButton1Click:Connect(function()
    if not isSorting then return end
    isSorting = false
    pbLabel.Text = "⏸  Stopping..."
    refreshStatus()
end)

cancelBtn.MouseButton1Click:Connect(function()
    isSorting = false; isStopped = false
    sortSlots = nil; sortIndex = 1; sortTotal = 0; sortDone = 0
    if sortThread then pcall(task.cancel, sortThread); sortThread = nil end
    destroyPreview(); unhighlightAll(); hideOverflow()
    pbLabel.Text = "Cancelled."
    hideProgress(1.0)
    refreshStatus()
end)

-- ════════════════════════════════════════════════════
-- MOUSE INPUT  (mirrors Item Tab's clean pattern)
-- ════════════════════════════════════════════════════

-- Lasso: driven via UserInputService like Item Tab
UserInputService.InputBegan:Connect(function(input)
    if not lassoEnabled then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

    lassoFrame.Visible  = true
    lassoFrame.Position = UDim2.new(0, mouse.X, 0, mouse.Y)
    lassoFrame.Size     = UDim2.new(0, 0, 0, 0)

    while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
        RunService.RenderStepped:Wait()
        lassoFrame.Size = UDim2.new(0, mouse.X, 0, mouse.Y) - lassoFrame.Position
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and isSortableItem(obj) then
                local mp2 = getMainPart(obj)
                if mp2 then
                    local sp, vis = camera:WorldToScreenPoint(mp2.Position)
                    if vis and is_in_frame(sp, lassoFrame) then highlightItem(obj) end
                end
            end
        end
    end
    lassoFrame.Size    = UDim2.new(0, 1, 0, 1)
    lassoFrame.Visible = false
    refreshStatus()
end)

-- Click / Group / preview-place on mouse up  (mirrors Item Tab)
local mouseUpConn = mouse.Button1Up:Connect(function()
    if lassoEnabled then return end

    -- If preview is following, place it
    if previewFollowing then
        placePreview(); refreshStatus(); return
    end

    -- Normal selection
    local target = mouse.Target
    if clickSelEnabled then
        tryClickSelect(target); refreshStatus()
    elseif groupSelEnabled then
        tryGroupSelect(target); refreshStatus()
    end
end)

-- ════════════════════════════════════════════════════
-- CLEANUP
-- ════════════════════════════════════════════════════
table.insert(cleanupTasks, function()
    isSorting = false; isStopped = false
    sortSlots = nil; sortIndex = 1; sortTotal = 0; sortDone = 0
    if followConn  then followConn:Disconnect();        followConn = nil end
    if sortThread  then pcall(task.cancel, sortThread); sortThread = nil end
    mouseUpConn:Disconnect()
    if lassoFrame and lassoFrame.Parent then lassoFrame:Destroy() end
    destroyPreview()
    unhighlightAll()
end)

refreshStatus()
print("[VanillaHub] Vanilla4 (Sorter v3) loaded")
