-- ════════════════════════════════════════════════════
-- VANILLA4 — Sorter Tab  (v4 — server-sided, lag-free lasso)
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
local BTN_COLOR        = _G.VH.BTN_COLOR        or Color3.fromRGB(30, 30, 40)
local ACCENT           = _G.VH.ACCENT           or Color3.fromRGB(100, 80, 200)
local THEME_TEXT       = _G.VH.THEME_TEXT        or Color3.fromRGB(230, 206, 226)
local SECTION_TEXT     = _G.VH.SECTION_TEXT      or Color3.fromRGB(120, 110, 140)
local SEP_COLOR        = _G.VH.SEP_COLOR         or Color3.fromRGB(40, 40, 55)

local sorterPage = pages["SorterTab"]
local camera     = workspace.CurrentCamera
local RS         = game:GetService("ReplicatedStorage")
local mouse      = player:GetMouse()

-- ════════════════════════════════════════════════════
-- THEME COLOURS
-- ════════════════════════════════════════════════════
-- Selection colours match Vanilla1 Item Tab exactly:
--   outline = RGB(0,172,240)  surface = black  surfaceAlpha=0.5  line=0.09
local C_SEL_OUTLINE  = Color3.fromRGB(0, 172, 240)
local C_SEL_SURFACE  = Color3.fromRGB(0, 0, 0)
local C_PREVIEW      = Color3.fromRGB(80,  160, 255)
local C_PLACED       = Color3.fromRGB(60,  210, 100)
local C_GREEN        = Color3.fromRGB(35,  100, 50)
local C_DARK         = Color3.fromRGB(16,  16,  20)
local C_CARD         = Color3.fromRGB(22,  18,  30)
local ITEM_GAP       = 0.10

-- ════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════
local selectedItems  = {}   -- [model] = SelectionBox
local previewPart    = nil
local previewFollow  = nil  -- RenderStepped connection
local previewPlaced  = false

local isSorting      = false
local isStopped      = false
local sortThread     = nil
local sortSlots      = nil  -- saved slot list for resume
local sortIndex      = 1
local sortTotal      = 0
local sortDone       = 0

local gridCols   = 3
local gridLayers = 1
local gridRows   = 0   -- 0 = auto

local sortDelay  = 0.3  -- seconds between items

-- selection mode flags (mutually exclusive)
local modeClick = false
local modeLasso = false
local modeGroup = false

-- lasso UI
local lassoAnchor  = nil   -- Vector2 where drag started
local lassoActive  = false

-- ════════════════════════════════════════════════════
-- ITEM HELPERS
-- Mirrors Vanilla1 Item Tab selection logic exactly:
--   • Item must live under workspace.PlayerModels
--   • Its direct parent must have an "Owner" StringValue
--   • We adorn the Main or WoodSection part, not the model,
--     so land/terrain/other models are never accidentally picked
-- ════════════════════════════════════════════════════
local function getMainPart(model)
    return model:FindFirstChild("Main") or model:FindFirstChild("WoodSection")
        or model:FindFirstChildWhichIsA("BasePart")
end

-- Returns true only for models that are valid draggable items.
-- Requires Owner as a DIRECT child (not just anywhere in hierarchy)
-- so that plot land, terrain, and other workspace objects are excluded.
local function isSortable(model)
    if not (model and model:IsA("Model") and model ~= workspace) then return false end
    -- Must be under workspace.PlayerModels (same gate as Item Tab)
    local pm = workspace:FindFirstChild("PlayerModels")
    if not pm then return false end
    if not model:IsDescendantOf(pm) then return false end
    -- Must have Owner as a direct child
    if not model:FindFirstChild("Owner") then return false end
    -- Must have a physical part we can move
    if not getMainPart(model) then return false end
    -- Skip trees / non-draggable props
    if model:FindFirstChild("TreeClass") then return false end
    return true
end

-- From a clicked BasePart, resolve the correct sortable model.
-- Mirrors Item Tab: walks up to the model whose direct parent has Owner.
local function modelFromTarget(target)
    if not target then return nil end
    -- Walk up through ancestor models
    local obj = target
    while obj do
        if obj:IsA("Model") and isSortable(obj) then return obj end
        obj = obj.Parent
    end
    return nil
end

local function itemName(model)
    local v = model:FindFirstChild("ItemName") or model:FindFirstChild("PurchasedBoxItemName")
    return v and v.Value or model.Name
end

-- ════════════════════════════════════════════════════
-- SELECTION
-- Adorn the Main/WoodSection part, not the model — matches Item Tab.
-- ════════════════════════════════════════════════════
local function getAdornPart(model)
    return model:FindFirstChild("Main") or model:FindFirstChild("WoodSection")
        or model:FindFirstChildWhichIsA("BasePart")
end

local function highlight(model)
    if selectedItems[model] then return end
    local part = getAdornPart(model)
    if not part then return end
    -- Already has one (e.g. from a previous failed cleanup)
    if part:FindFirstChild("VH_Sel") then part:FindFirstChild("VH_Sel"):Destroy() end
    local sb = Instance.new("SelectionBox")
    sb.Name              = "VH_Sel"
    sb.Color3            = C_SEL_OUTLINE          -- RGB(0,172,240) — same as Item Tab
    sb.SurfaceColor3     = C_SEL_SURFACE          -- black surface tint
    sb.LineThickness     = 0.09                   -- same as Item Tab
    sb.SurfaceTransparency = 0.5                  -- same as Item Tab
    sb.Adornee           = part                   -- adorn the PART, not the model
    sb.Parent            = part
    selectedItems[model] = sb
end

local function unhighlight(model)
    if selectedItems[model] then
        selectedItems[model]:Destroy()
        selectedItems[model] = nil
    end
end

local function clearAll()
    for m, sb in pairs(selectedItems) do
        if sb and sb.Parent then sb:Destroy() end
    end
    selectedItems = {}
end

local function selCount()
    local n = 0; for _ in pairs(selectedItems) do n = n + 1 end; return n
end

-- ════════════════════════════════════════════════════
-- LASSO  —  zero-lag design:
--   • RenderStepped ONLY updates the rectangle UI (no iteration)
--   • World-scan happens ONCE on mouse-release
-- ════════════════════════════════════════════════════
local coreGui    = game:GetService("CoreGui")
local lassoUI    = Instance.new("Frame", coreGui:FindFirstChild("VanillaHub") or coreGui)
lassoUI.Name                    = "VH_SorterLasso"
lassoUI.BackgroundColor3        = Color3.fromRGB(90, 130, 210)
lassoUI.BackgroundTransparency  = 0.84
lassoUI.BorderSizePixel         = 0
lassoUI.ZIndex                  = 25
lassoUI.Visible                 = false
local lassoStroke = Instance.new("UIStroke", lassoUI)
lassoStroke.Color       = Color3.fromRGB(140, 170, 255)
lassoStroke.Thickness   = 1.5
lassoStroke.Transparency = 0

-- Cached item list — rebuilt only when needed, not every frame
local _cachedSortables  = nil
local _cacheFrame       = 0

local function getSortables()
    -- Only scan workspace.PlayerModels — same scope as isSortable requires.
    -- Cache for 1.5 s so lasso commit and group-select don't re-scan unnecessarily.
    if _cachedSortables and (time() - _cacheFrame) < 1.5 then
        return _cachedSortables
    end
    local list = {}
    local pm = workspace:FindFirstChild("PlayerModels")
    if pm then
        for _, obj in ipairs(pm:GetChildren()) do
            if isSortable(obj) then table.insert(list, obj) end
        end
    end
    _cachedSortables = list
    _cacheFrame = time()
    return list
end

local function updateLassoRect(cur)
    local ax = lassoAnchor.X; local ay = lassoAnchor.Y
    local cx = cur.X;         local cy = cur.Y
    lassoUI.Position = UDim2.fromOffset(math.min(ax,cx), math.min(ay,cy))
    lassoUI.Size     = UDim2.fromOffset(math.abs(cx-ax), math.abs(cy-ay))
end

local function commitLasso()
    -- Called ONCE on mouse-up — do the scan here, not during drag
    if not lassoAnchor then return end
    local cur  = Vector2.new(mouse.X, mouse.Y)
    local minX = math.min(lassoAnchor.X, cur.X)
    local maxX = math.max(lassoAnchor.X, cur.X)
    local minY = math.min(lassoAnchor.Y, cur.Y)
    local maxY = math.max(lassoAnchor.Y, cur.Y)

    -- Only scan if the box is large enough to be intentional
    if (maxX - minX) < 4 and (maxY - minY) < 4 then return end

    for _, model in ipairs(getSortables()) do
        local mp = getMainPart(model)
        if mp then
            local sp, vis = camera:WorldToScreenPoint(mp.Position)
            if vis and sp.X >= minX and sp.X <= maxX
                    and sp.Y >= minY and sp.Y <= maxY then
                highlight(model)
            end
        end
    end
end

-- RenderStepped connection only active while lasso is being dragged
local lassoRenderConn = nil

local function startLasso(x, y)
    lassoAnchor = Vector2.new(x, y)
    lassoActive = true
    lassoUI.Position = UDim2.fromOffset(x, y)
    lassoUI.Size     = UDim2.fromOffset(0, 0)
    lassoUI.Visible  = true
    if lassoRenderConn then lassoRenderConn:Disconnect() end
    lassoRenderConn = RunService.RenderStepped:Connect(function()
        if not lassoActive then
            lassoRenderConn:Disconnect(); lassoRenderConn = nil; return
        end
        updateLassoRect(Vector2.new(mouse.X, mouse.Y))
    end)
end

local function endLasso()
    lassoActive = false
    if lassoRenderConn then lassoRenderConn:Disconnect(); lassoRenderConn = nil end
    lassoUI.Visible = false
    commitLasso()
    lassoAnchor = nil
end

-- ════════════════════════════════════════════════════
-- SLOT CALCULATOR
-- Fills X (cols) → Z (rows) → Y (layers), tallest items first.
-- Returns an ordered list so a full layer is placed before the next.
-- ════════════════════════════════════════════════════
local function calcSlots(models, anchorCF, cols, layers, rows)
    cols   = math.max(1, cols)
    layers = math.max(1, layers)
    rows   = math.max(0, rows)

    -- Measure every item
    local entries = {}
    for _, m in ipairs(models) do
        local ok, _, sz = pcall(function() return m:GetBoundingBox() end)
        local s = (ok and sz) or Vector3.new(2,2,2)
        table.insert(entries, { model=m, w=s.X, h=s.Y, d=s.Z })
    end

    -- Tallest first so bottom layer has the tallest items
    table.sort(entries, function(a,b) return a.h > b.h end)

    local total    = #entries
    local rowsPerLayer = rows > 0 and rows
        or math.max(1, math.ceil(math.ceil(total/layers)/cols))
    local perLayer = cols * rowsPerLayer

    -- Assign grid position
    for i, e in ipairs(entries) do
        local idx   = i - 1
        e.layer     = math.floor(idx / perLayer)
        local rem   = idx % perLayer
        e.row       = math.floor(rem / cols)
        e.col       = rem % cols
    end

    -- Max height per layer
    local layH = {}
    for _, e in ipairs(entries) do
        layH[e.layer] = math.max(layH[e.layer] or 0, e.h)
    end

    -- Max depth per (layer, row)
    local rowD = {}
    for _, e in ipairs(entries) do
        if not rowD[e.layer] then rowD[e.layer] = {} end
        rowD[e.layer][e.row] = math.max(rowD[e.layer][e.row] or 0, e.d)
    end

    -- Max width per col
    local colW = {}
    for _, e in ipairs(entries) do
        colW[e.col] = math.max(colW[e.col] or 0, e.w)
    end

    -- Accumulate Y per layer
    local layY = {}; local ay = 0
    local maxLayer = 0
    for _, e in ipairs(entries) do if e.layer > maxLayer then maxLayer = e.layer end end
    for l = 0, maxLayer do
        layY[l] = ay; ay = ay + (layH[l] or 0) + ITEM_GAP
    end

    -- Accumulate Z per (layer, row)
    local rowZ = {}
    for l = 0, maxLayer do
        rowZ[l] = {}; local az = 0
        local maxRow = 0
        for _, e in ipairs(entries) do
            if e.layer == l and e.row > maxRow then maxRow = e.row end
        end
        for r = 0, maxRow do
            rowZ[l][r] = az; az = az + ((rowD[l] and rowD[l][r]) or 0) + ITEM_GAP
        end
    end

    -- Accumulate X per col
    local colX = {}; local ax2 = 0
    for c = 0, cols-1 do
        colX[c] = ax2; ax2 = ax2 + (colW[c] or 0) + ITEM_GAP
    end

    -- Build final slot list (already layer-ordered because entries is sorted)
    local slots = {}
    for _, e in ipairs(entries) do
        local lx = colX[e.col]  + e.w/2
        local ly = layY[e.layer]+ e.h/2
        local lz = (rowZ[e.layer] and rowZ[e.layer][e.row] or 0) + e.d/2
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
    if previewFollow then previewFollow:Disconnect(); previewFollow = nil end
    if previewPart and previewPart.Parent then previewPart:Destroy() end
    previewPart   = nil
    previewPlaced = false
end

local function previewSize()
    local entries = {}
    for m in pairs(selectedItems) do
        local ok, _, sz = pcall(function() return m:GetBoundingBox() end)
        table.insert(entries, (ok and sz) or Vector3.new(2,2,2))
    end
    if #entries == 0 then return 4,4,4 end

    local cols = math.max(1, gridCols)
    local lays = math.max(1, gridLayers)
    local rws  = math.max(0, gridRows)
    local maxW,maxH,maxD = 0,0,0
    for _, s in ipairs(entries) do
        if s.X > maxW then maxW = s.X end
        if s.Y > maxH then maxH = s.Y end
        if s.Z > maxD then maxD = s.Z end
    end
    local spl = rws > 0 and (cols*rws) or math.ceil(#entries/lays)
    local ar  = math.ceil(spl/cols)
    return math.max(cols*(maxW+ITEM_GAP)-ITEM_GAP, 1),
           math.max(lays*(maxH+ITEM_GAP)-ITEM_GAP, 1),
           math.max(ar  *(maxD+ITEM_GAP)-ITEM_GAP, 1)
end

local function getGroundCF(halfH)
    local ray    = camera:ScreenPointToRay(mouse.X, mouse.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local excl = {}
    if previewPart then table.insert(excl, previewPart) end
    if player.Character then table.insert(excl, player.Character) end
    params.FilterDescendantsInstances = excl
    local res = workspace:Raycast(ray.Origin, ray.Direction * 600, params)
    local pos
    if res then
        pos = res.Position
    else
        local t = -ray.Origin.Y / ray.Direction.Y
        pos = (t and t > 0) and (ray.Origin + ray.Direction*t) or (ray.Origin + ray.Direction*40)
    end
    return CFrame.new(pos.X, pos.Y + halfH, pos.Z)
end

local function buildPreview(sX, sY, sZ)
    if previewPart and previewPart.Parent then previewPart:Destroy() end
    previewPart              = Instance.new("Part")
    previewPart.Name         = "VH_SorterPreview"
    previewPart.Anchored     = true
    previewPart.CanCollide   = false
    previewPart.CanQuery     = false
    previewPart.CastShadow   = false
    previewPart.Size         = Vector3.new(math.max(sX,0.5), math.max(sY,0.5), math.max(sZ,0.5))
    previewPart.Color        = C_PREVIEW
    previewPart.Material     = Enum.Material.SmoothPlastic
    previewPart.Transparency = 0.52
    previewPart.Parent       = workspace
    local sb = Instance.new("SelectionBox")
    sb.Color3              = C_PREVIEW
    sb.LineThickness       = 0.07
    sb.SurfaceTransparency = 1
    sb.Adornee             = previewPart
    sb.Parent              = previewPart

    -- Follow mouse
    previewPlaced = false
    if previewFollow then previewFollow:Disconnect() end
    previewFollow = RunService.RenderStepped:Connect(function()
        if not (previewPart and previewPart.Parent) then
            previewFollow:Disconnect(); previewFollow = nil; return
        end
        previewPart.CFrame = previewPart.CFrame:Lerp(getGroundCF(previewPart.Size.Y/2), 0.22)
    end)
end

local function placePreview()
    if not (previewPart and previewPart.Parent and not previewPlaced) then return end
    if previewFollow then previewFollow:Disconnect(); previewFollow = nil end
    previewPart.CFrame = getGroundCF(previewPart.Size.Y/2)
    previewPart.Color  = C_PLACED
    local sb = previewPart:FindFirstChildOfClass("SelectionBox")
    if sb then sb.Color3 = C_PLACED end
    previewPlaced = true
end

-- ════════════════════════════════════════════════════
-- SERVER-SIDED SORT ENGINE
--
-- Per-item flow:
--   1. Teleport character next to item (server requires proximity to drag)
--   2. Fire ClientIsDragging(model) to acquire network ownership
--   3. Wait for ReceiveAge == 0 (ownership confirmed)
--   4. PivotTo target — replicates to server because we own the parts
--   5. Anchor every BasePart in the model so physics can't knock it away
--      (still replicates because we own them)
--   6. Release ownership — part stays anchored on the server
--
-- Step 5 is what v3 was missing. Without it, later items passing near an
-- already-placed item can push it via Roblox physics simulation.
-- ════════════════════════════════════════════════════
local _dragRemote = nil
local function dragRemote()
    if _dragRemote then return _dragRemote end
    local i = RS:FindFirstChild("Interaction")
    _dragRemote = i and i:FindFirstChild("ClientIsDragging")
    return _dragRemote
end

-- Wait until we have network ownership of all unanchored parts
local function waitForOwnership(model, timeout)
    timeout = timeout or 4
    local deadline = tick() + timeout
    local remote   = dragRemote()
    while tick() < deadline do
        local owned = true
        for _, p in ipairs(model:GetDescendants()) do
            if p:IsA("BasePart") and not p.Anchored and p.ReceiveAge ~= 0 then
                owned = false; break
            end
        end
        if owned then return true end
        if remote then pcall(remote.FireServer, remote, model) end
        task.wait(0.05)
    end
    return false
end

local function approachItem(model)
    local mp  = getMainPart(model); if not mp then return end
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = CFrame.new(mp.Position) * CFrame.new(0, 2, 4) end
end

-- Anchor/unanchor all BaseParts in a model (replicates while we own them)
local function setAnchored(model, state)
    pcall(function()
        for _, p in ipairs(model:GetDescendants()) do
            if p:IsA("BasePart") then p.Anchored = state end
        end
        -- Also set the primary part if present
        if model.PrimaryPart then model.PrimaryPart.Anchored = state end
    end)
end

local function placeItem(model, targetCF)
    if not (model and model.Parent) then return end
    local mp     = getMainPart(model)
    local remote = dragRemote()
    if not mp then return end

    -- Unanchor first (in case it was left anchored from a previous sort)
    setAnchored(model, false)

    approachItem(model)

    -- Request network ownership
    if remote then
        for _ = 1, 3 do
            pcall(remote.FireServer, remote, model)
            task.wait(0.05)
        end
    end
    waitForOwnership(model, 3)

    -- Move server-side via PivotTo (replicates because we own the parts)
    pcall(function()
        if not model.PrimaryPart then model.PrimaryPart = mp end
        model:PivotTo(targetCF)
    end)

    task.wait(0.08)   -- let the server receive the new CFrame

    -- Anchor in place — replicates while we still own the parts.
    -- This prevents any passing item from knocking this one away.
    setAnchored(model, true)

    task.wait(0.05)   -- let anchor state replicate

    -- Release ownership
    if remote then pcall(remote.FireServer, remote, nil) end
end

-- ════════════════════════════════════════════════════
-- UI PRIMITIVES  (consistent with Item Tab)
-- ════════════════════════════════════════════════════
local pageList = sorterPage:FindFirstChildOfClass("UIListLayout")
if pageList then pageList.Padding = UDim.new(0, 8) end

local function uSection(text)
    local w = Instance.new("Frame", sorterPage)
    w.Size = UDim2.new(1,0,0,22); w.BackgroundTransparency = 1
    local l = Instance.new("TextLabel", w)
    l.Size = UDim2.new(1,-4,1,0); l.Position = UDim2.new(0,4,0,0)
    l.BackgroundTransparency = 1; l.Font = Enum.Font.GothamBold; l.TextSize = 10
    l.TextColor3 = SECTION_TEXT; l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = "  " .. string.upper(text)
end

local function uSep()
    local s = Instance.new("Frame", sorterPage)
    s.Size = UDim2.new(1,0,0,1); s.BackgroundColor3 = SEP_COLOR; s.BorderSizePixel = 0
end

local function uHint(text)
    local l = Instance.new("TextLabel", sorterPage)
    l.Size = UDim2.new(1,0,0,20); l.BackgroundTransparency = 1
    l.Font = Enum.Font.Gotham; l.TextSize = 11
    l.TextColor3 = Color3.fromRGB(80,80,100)
    l.TextXAlignment = Enum.TextXAlignment.Left; l.TextWrapped = true
    l.Text = "  " .. text
end

local function uButton(text, col, cb)
    col = col or BTN_COLOR
    local btn = Instance.new("TextButton", sorterPage)
    btn.Size = UDim2.new(1,0,0,34); btn.BackgroundColor3 = col
    btn.Text = text; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
    btn.TextColor3 = THEME_TEXT; btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    local hov = Color3.fromRGB(
        math.min(col.R*255+22,255)/255, math.min(col.G*255+10,255)/255, math.min(col.B*255+22,255)/255)
    btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=hov}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=col}):Play() end)
    if cb then btn.MouseButton1Click:Connect(cb) end
    return btn
end

local function uToggle(text, default, cb)
    local fr = Instance.new("Frame", sorterPage)
    fr.Size = UDim2.new(1,0,0,36); fr.BackgroundColor3 = C_DARK; fr.BorderSizePixel = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0,8)
    local lbl = Instance.new("TextLabel", fr)
    lbl.Size = UDim2.new(1,-54,1,0); lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = text
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local tb = Instance.new("TextButton", fr)
    tb.Size = UDim2.new(0,36,0,20); tb.Position = UDim2.new(1,-46,0.5,-10)
    tb.BackgroundColor3 = default and Color3.fromRGB(80,160,80) or Color3.fromRGB(38,38,45)
    tb.Text = ""; tb.BorderSizePixel = 0
    Instance.new("UICorner", tb).CornerRadius = UDim.new(1,0)
    local dot = Instance.new("Frame", tb)
    dot.Size = UDim2.new(0,14,0,14)
    dot.Position = UDim2.new(0, default and 20 or 2, 0.5,-7)
    dot.BackgroundColor3 = Color3.fromRGB(255,255,255); dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
    local on = default
    if cb then task.defer(function() cb(on) end) end
    tb.MouseButton1Click:Connect(function()
        on = not on
        TweenService:Create(tb, TweenInfo.new(0.2,Enum.EasingStyle.Quint),
            {BackgroundColor3 = on and Color3.fromRGB(80,160,80) or Color3.fromRGB(38,38,45)}):Play()
        TweenService:Create(dot, TweenInfo.new(0.2,Enum.EasingStyle.Quint),
            {Position = UDim2.new(0, on and 20 or 2, 0.5,-7)}):Play()
        if cb then cb(on) end
    end)
    return fr, function(v)   -- returns a setter for external forced-off
        if v == on then return end
        on = v
        TweenService:Create(tb, TweenInfo.new(0.18),
            {BackgroundColor3 = on and Color3.fromRGB(80,160,80) or Color3.fromRGB(38,38,45)}):Play()
        TweenService:Create(dot, TweenInfo.new(0.18),
            {Position = UDim2.new(0, on and 20 or 2, 0.5,-7)}):Play()
    end
end

local function uSlider(text, minV, maxV, defV, cb)
    local fr = Instance.new("Frame", sorterPage)
    fr.Size = UDim2.new(1,0,0,54); fr.BackgroundColor3 = C_DARK; fr.BorderSizePixel = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0,8)
    local row = Instance.new("Frame", fr)
    row.Size = UDim2.new(1,-16,0,22); row.Position = UDim2.new(0,8,0,7); row.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.72,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = text
    local val = Instance.new("TextLabel", row)
    val.Size = UDim2.new(0.28,0,1,0); val.Position = UDim2.new(0.72,0,0,0)
    val.BackgroundTransparency = 1; val.Font = Enum.Font.GothamBold; val.TextSize = 13
    val.TextColor3 = Color3.fromRGB(160,160,175); val.TextXAlignment = Enum.TextXAlignment.Right
    val.Text = tostring(defV)
    local track = Instance.new("Frame", fr)
    track.Size = UDim2.new(1,-16,0,5); track.Position = UDim2.new(0,8,0,38)
    track.BackgroundColor3 = Color3.fromRGB(32,32,38); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((defV-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3 = ACCENT; fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0,14,0,14); knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new((defV-minV)/(maxV-minV),0,0.5,0)
    knob.BackgroundColor3 = Color3.fromRGB(210,210,220); knob.Text = ""; knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    local drag = false
    local function upd(ax)
        local r = math.clamp((ax - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
        local v = math.round(minV + r*(maxV-minV))
        fill.Size = UDim2.new(r,0,1,0); knob.Position = UDim2.new(r,0,0.5,0)
        val.Text = tostring(v); if cb then cb(v) end
    end
    knob.MouseButton1Down:Connect(function() drag = true end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; upd(i.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then upd(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
end

local AXIS_C = { X=Color3.fromRGB(220,70,70), Y=Color3.fromRGB(70,200,70), Z=Color3.fromRGB(70,120,255) }
local function uAxisSlider(label, axis, minV, maxV, defV, cb)
    local ac = AXIS_C[axis] or THEME_TEXT
    local fr = Instance.new("Frame", sorterPage)
    fr.Size = UDim2.new(1,0,0,54); fr.BackgroundColor3 = C_DARK; fr.BorderSizePixel = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0,8)
    local ax = Instance.new("TextLabel", fr)
    ax.Size = UDim2.new(0,18,0,22); ax.Position = UDim2.new(0,8,0,7)
    ax.BackgroundTransparency = 1; ax.Font = Enum.Font.GothamBold
    ax.TextSize = 14; ax.TextColor3 = ac; ax.Text = axis
    local lbl = Instance.new("TextLabel", fr)
    lbl.Size = UDim2.new(0.6,0,0,22); lbl.Position = UDim2.new(0,28,0,7)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 12; lbl.TextColor3 = THEME_TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = label
    local valL = Instance.new("TextLabel", fr)
    valL.Size = UDim2.new(0.25,0,0,22); valL.Position = UDim2.new(0.75,-8,0,7)
    valL.BackgroundTransparency = 1; valL.Font = Enum.Font.GothamBold
    valL.TextSize = 13; valL.TextColor3 = ac
    valL.TextXAlignment = Enum.TextXAlignment.Right; valL.Text = tostring(defV)
    local track = Instance.new("Frame", fr)
    track.Size = UDim2.new(1,-16,0,5); track.Position = UDim2.new(0,8,0,38)
    track.BackgroundColor3 = Color3.fromRGB(32,32,38); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((defV-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3 = ac; fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0,14,0,14); knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new((defV-minV)/(maxV-minV),0,0.5,0)
    knob.BackgroundColor3 = Color3.fromRGB(210,210,220); knob.Text = ""; knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    local drag = false; local cur = defV
    local function upd(ax2)
        local r = math.clamp((ax2 - track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1),0,1)
        local v = math.round(minV + r*(maxV-minV))
        if v == cur then return end; cur = v
        fill.Size = UDim2.new(r,0,1,0); knob.Position = UDim2.new(r,0,0.5,0)
        valL.Text = tostring(v); if cb then cb(v) end
    end
    knob.MouseButton1Down:Connect(function() drag = true end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; upd(i.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then upd(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
end

-- ════════════════════════════════════════════════════
-- STATUS CARD
-- ════════════════════════════════════════════════════
local statusLabel
do
    local card = Instance.new("Frame", sorterPage)
    card.Size = UDim2.new(1,0,0,44); card.BackgroundColor3 = C_CARD; card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,8)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(255,180,0); stroke.Thickness = 1; stroke.Transparency = 0.55
    local l = Instance.new("TextLabel", card)
    l.Size = UDim2.new(1,-16,1,0); l.Position = UDim2.new(0,8,0,0)
    l.BackgroundTransparency = 1; l.Font = Enum.Font.GothamSemibold; l.TextSize = 12
    l.TextColor3 = Color3.fromRGB(255,210,100)
    l.TextXAlignment = Enum.TextXAlignment.Left; l.TextWrapped = true
    l.Text = "Select items to get started."
    statusLabel = l
end

local function setStatus(msg, col)
    statusLabel.Text       = msg
    statusLabel.TextColor3 = col or Color3.fromRGB(255,210,100)
end

-- ════════════════════════════════════════════════════
-- PROGRESS BAR
-- ════════════════════════════════════════════════════
local pbContainer, pbFill, pbLabel
do
    local pb = Instance.new("Frame")
    pb.Size = UDim2.new(1,0,0,44); pb.BackgroundColor3 = Color3.fromRGB(18,18,24)
    pb.BorderSizePixel = 0; pb.Visible = false
    Instance.new("UICorner", pb).CornerRadius = UDim.new(0,8)
    local stroke = Instance.new("UIStroke", pb)
    stroke.Color = Color3.fromRGB(60,60,80); stroke.Thickness = 1; stroke.Transparency = 0.5
    local lbl = Instance.new("TextLabel", pb)
    lbl.Size = UDim2.new(1,-12,0,16); lbl.Position = UDim2.new(0,6,0,4)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 11
    lbl.TextColor3 = THEME_TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = "Ready."
    local track = Instance.new("Frame", pb)
    track.Size = UDim2.new(1,-12,0,12); track.Position = UDim2.new(0,6,0,26)
    track.BackgroundColor3 = Color3.fromRGB(30,30,42); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)
    local fl = Instance.new("Frame", track)
    fl.Size = UDim2.new(0,0,1,0); fl.BackgroundColor3 = Color3.fromRGB(255,175,55)
    fl.BorderSizePixel = 0
    Instance.new("UICorner", fl).CornerRadius = UDim.new(1,0)
    pbContainer = pb; pbFill = fl; pbLabel = lbl
end

local function setPb(frac, text, col)
    TweenService:Create(pbFill, TweenInfo.new(0.18, Enum.EasingStyle.Quad),
        { Size = UDim2.new(math.clamp(frac,0,1),0,1,0) }):Play()
    if col then pbFill.BackgroundColor3 = col end
    if text then pbLabel.Text = text end
end

local function hidePb(delay)
    task.delay(delay or 2, function()
        if not pbContainer then return end
        TweenService:Create(pbContainer, TweenInfo.new(0.4),{BackgroundTransparency=1}):Play()
        TweenService:Create(pbFill,      TweenInfo.new(0.4),{BackgroundTransparency=1}):Play()
        TweenService:Create(pbLabel,     TweenInfo.new(0.4),{TextTransparency=1}):Play()
        task.delay(0.45, function()
            if not pbContainer then return end
            pbContainer.Visible = false
            pbContainer.BackgroundTransparency = 0
            pbFill.BackgroundTransparency = 0
            pbFill.BackgroundColor3 = Color3.fromRGB(255,175,55)
            pbFill.Size = UDim2.new(0,0,1,0)
            pbLabel.TextTransparency = 0
        end)
    end)
end

-- ════════════════════════════════════════════════════
-- FORWARD REFS
-- ════════════════════════════════════════════════════
local startBtn, stopBtn

local function refreshStatus()
    local n = selCount()
    if isSorting then
        setStatus("⏳  Sorting in progress...", Color3.fromRGB(140,220,255))
    elseif isStopped then
        setStatus("⏸  Paused — press Resume to continue.", Color3.fromRGB(255,210,80))
    elseif n == 0 then
        setStatus("👆  Select items via Click, Lasso, or Group.")
    elseif previewFollow then
        setStatus("🖱  Preview following — click to place.", Color3.fromRGB(140,220,255))
    elseif previewPlaced then
        setStatus("✅  " .. n .. " item(s) ready.  Hit Start Sorting!", Color3.fromRGB(100,220,120))
    elseif previewPart then
        setStatus("📦  Preview placed. Hit Start Sorting!")
    else
        setStatus("📦  " .. n .. " item(s) selected.  Generate a Preview.")
    end

    if startBtn then
        local canStart = (n > 0 or isStopped) and (previewPlaced or isStopped) and not isSorting
        startBtn.BackgroundColor3 = canStart and C_GREEN or Color3.fromRGB(28,28,38)
        startBtn.TextColor3       = canStart and THEME_TEXT or Color3.fromRGB(72,72,82)
        startBtn.Text = isStopped and "▶  Resume Sorting" or "▶  Start Sorting"
    end
    if stopBtn then
        stopBtn.BackgroundColor3 = isSorting and Color3.fromRGB(100,60,20) or Color3.fromRGB(28,28,38)
        stopBtn.TextColor3       = isSorting and Color3.fromRGB(255,190,80) or Color3.fromRGB(72,72,82)
    end
end

-- ════════════════════════════════════════════════════
-- SORT LOOP
-- ════════════════════════════════════════════════════
local function runSort(slots, startI, total, doneStart)
    local done = doneStart
    sortThread = task.spawn(function()
        for i = startI, total do
            if not isSorting then sortIndex = i; break end

            local slot = slots[i]
            if not (slot.model and slot.model.Parent) then
                done = done + 1; sortDone = done; sortIndex = i + 1
                setPb(done/total, "Skipped " .. done .. "/" .. total); continue
            end

            setPb(done/total, "Placing " .. done+1 .. " / " .. total)

            placeItem(slot.model, slot.cf)

            if not isSorting then sortIndex = i; break end

            unhighlight(slot.model)
            done = done + 1; sortDone = done; sortIndex = i + 1
            setPb(done/total, "Sorting  " .. done .. " / " .. total)

            task.wait(sortDelay)
        end

        isSorting = false; sortThread = nil

        if done >= total then
            isStopped = false; sortSlots = nil
            setPb(1, "✔  Done! " .. done .. " items placed.", Color3.fromRGB(90,220,110))
            destroyPreview(); clearAll(); hidePb(3)
        else
            isStopped = true
            setPb(done/math.max(total,1), "⏸  Stopped at " .. done .. " / " .. total)
        end
        refreshStatus()
    end)
end

-- ════════════════════════════════════════════════════
-- BUILD UI
-- ════════════════════════════════════════════════════

-- 1 ── STATUS ────────────────────────────────────────
-- (status card already parented above)
uSep()

-- 2 ── SELECTION MODE ────────────────────────────────
uSection("Selection Mode")

local _, setClickOff = uToggle("Click Select", false, function(v)
    modeClick = v
    if v then modeLasso = false; modeGroup = false end
end)
local _, setLassoOff = uToggle("Lasso Select", false, function(v)
    modeLasso = v
    if v then modeClick = false; modeGroup = false end
end)
local _, setGroupOff = uToggle("Group Select", false, function(v)
    modeGroup = v
    if v then modeClick = false; modeLasso = false end
end)

uHint("Click: toggle one item  ·  Lasso: drag box  ·  Group: all of same type")
uButton("Deselect All", BTN_COLOR, function() clearAll(); refreshStatus() end)

uSep()

-- 3 ── SPEED ─────────────────────────────────────────
uSection("Sort Speed")
uSlider("Delay per item (×0.1s)", 1, 20, 3, function(v)
    sortDelay = v / 10
    if _G.VH then _G.VH.tpItemSpeed = sortDelay end
end)

uSep()

-- 4 ── GRID ──────────────────────────────────────────
uSection("Sort Grid")

uAxisSlider("Width  (items per row)",    "X", 1, 12, 3, function(v) gridCols   = v end)
uAxisSlider("Height  (vertical layers)", "Y", 1,  5, 1, function(v) gridLayers = v end)
uAxisSlider("Depth  (rows · 0 = auto)",  "Z", 0, 12, 0, function(v) gridRows   = v end)

uHint("Fills X→Z→Y.  Tallest items go on the bottom layer.  Z=0 calculates rows automatically.")

uSep()

-- 5 ── PREVIEW ───────────────────────────────────────
uSection("Preview")

local previewRow = Instance.new("Frame", sorterPage)
previewRow.Size = UDim2.new(1,0,0,34); previewRow.BackgroundTransparency = 1

local genBtn = Instance.new("TextButton", previewRow)
genBtn.Size = UDim2.new(0.60,-4,1,0); genBtn.BackgroundColor3 = Color3.fromRGB(28,55,110)
genBtn.Text = "Generate Preview"; genBtn.Font = Enum.Font.GothamSemibold; genBtn.TextSize = 13
genBtn.TextColor3 = THEME_TEXT; genBtn.BorderSizePixel = 0
Instance.new("UICorner", genBtn).CornerRadius = UDim.new(0,8)

local clrPrevBtn = Instance.new("TextButton", previewRow)
clrPrevBtn.Size = UDim2.new(0.40,-4,1,0); clrPrevBtn.Position = UDim2.new(0.60,4,0,0)
clrPrevBtn.BackgroundColor3 = BTN_COLOR
clrPrevBtn.Text = "Clear Preview"; clrPrevBtn.Font = Enum.Font.GothamSemibold; clrPrevBtn.TextSize = 12
clrPrevBtn.TextColor3 = THEME_TEXT; clrPrevBtn.BorderSizePixel = 0
Instance.new("UICorner", clrPrevBtn).CornerRadius = UDim.new(0,8)

for _, b in {genBtn, clrPrevBtn} do
    local base = b.BackgroundColor3
    local hov = Color3.fromRGB(
        math.min(base.R*255+20,255)/255,math.min(base.G*255+10,255)/255,math.min(base.B*255+20,255)/255)
    b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.14),{BackgroundColor3=hov}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.14),{BackgroundColor3=base}):Play() end)
end

genBtn.MouseButton1Click:Connect(function()
    if selCount() == 0 then setStatus("⚠  Select items first!"); return end
    local sX,sY,sZ = previewSize()
    buildPreview(sX,sY,sZ)
    refreshStatus()
end)
clrPrevBtn.MouseButton1Click:Connect(function()
    destroyPreview(); refreshStatus()
end)

uHint("Preview follows cursor — left-click to lock its position.")

uSep()

-- 6 ── ACTIONS ───────────────────────────────────────
uSection("Actions")

startBtn = Instance.new("TextButton", sorterPage)
startBtn.Size = UDim2.new(1,0,0,36); startBtn.BackgroundColor3 = Color3.fromRGB(28,28,38)
startBtn.Text = "▶  Start Sorting"; startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 14; startBtn.TextColor3 = Color3.fromRGB(72,72,82); startBtn.BorderSizePixel = 0
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0,8)

-- Stop / Cancel row
local actRow = Instance.new("Frame", sorterPage)
actRow.Size = UDim2.new(1,0,0,32); actRow.BackgroundTransparency = 1

stopBtn = Instance.new("TextButton", actRow)
stopBtn.Size = UDim2.new(0.48,-2,1,0)
stopBtn.BackgroundColor3 = Color3.fromRGB(28,28,38)
stopBtn.Text = "⏹  Stop"; stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 13; stopBtn.TextColor3 = Color3.fromRGB(72,72,82); stopBtn.BorderSizePixel = 0
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0,8)

local cancelBtn = Instance.new("TextButton", actRow)
cancelBtn.Size = UDim2.new(0.52,-2,1,0); cancelBtn.Position = UDim2.new(0.48,2,0,0)
cancelBtn.BackgroundColor3 = Color3.fromRGB(60,16,16)
cancelBtn.Text = "✕  Cancel & Clear"; cancelBtn.Font = Enum.Font.GothamBold
cancelBtn.TextSize = 12; cancelBtn.TextColor3 = Color3.fromRGB(200,100,100); cancelBtn.BorderSizePixel = 0
Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0,8)

-- 7 ── PROGRESS ──────────────────────────────────────
pbContainer.Parent = sorterPage

-- ════════════════════════════════════════════════════
-- BUTTON LOGIC
-- ════════════════════════════════════════════════════
startBtn.MouseButton1Click:Connect(function()
    if isSorting then return end

    -- Resume after stop
    if isStopped and sortSlots then
        isStopped = false; isSorting = true
        pbContainer.Visible = true
        pbFill.BackgroundColor3 = Color3.fromRGB(255,175,55)
        refreshStatus()
        runSort(sortSlots, sortIndex, sortTotal, sortDone)
        return
    end

    if not (previewPlaced and previewPart and previewPart.Parent) then
        setStatus("⚠  Generate + place a preview first!"); return
    end
    if selCount() == 0 then setStatus("⚠  No items selected!"); return end

    local items = {}
    for m in pairs(selectedItems) do
        if m and m.Parent then table.insert(items, m) end
    end
    if #items == 0 then return end

    -- Anchor is at the bottom-left-front corner of the preview box
    local anchorCF = previewPart.CFrame
        * CFrame.new(-previewPart.Size.X/2, -previewPart.Size.Y/2, -previewPart.Size.Z/2)

    sortSlots = calcSlots(items, anchorCF, gridCols, gridLayers, gridRows)
    sortTotal = #sortSlots; sortDone = 0; sortIndex = 1
    isStopped = false; isSorting = true

    pbContainer.Visible = true
    pbFill.Size = UDim2.new(0,0,1,0)
    pbFill.BackgroundColor3 = Color3.fromRGB(255,175,55)
    pbLabel.Text = "Starting..."
    refreshStatus()
    runSort(sortSlots, 1, sortTotal, 0)
end)

stopBtn.MouseButton1Click:Connect(function()
    if not isSorting then return end
    isSorting = false; pbLabel.Text = "⏸  Stopping..."; refreshStatus()
end)

cancelBtn.MouseButton1Click:Connect(function()
    isSorting = false; isStopped = false
    sortSlots = nil; sortIndex = 1; sortTotal = 0; sortDone = 0
    if sortThread then pcall(task.cancel, sortThread); sortThread = nil end
    destroyPreview(); clearAll()
    pbLabel.Text = "Cancelled."; hidePb(1)
    refreshStatus()
end)

-- ════════════════════════════════════════════════════
-- MOUSE INPUT
-- ════════════════════════════════════════════════════
local inputBeganConn = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

    if modeLasso then
        startLasso(mouse.X, mouse.Y)
        return
    end
end)

local mouseUpConn = mouse.Button1Up:Connect(function()
    -- End lasso
    if modeLasso and lassoActive then
        endLasso(); refreshStatus(); return
    end

    -- Place preview
    if previewPart and previewPart.Parent and not previewPlaced then
        placePreview(); refreshStatus(); return
    end

    -- Click / Group selection
    local target = mouse.Target
    if modeClick then
        local m = modelFromTarget(target)
        if m then
            if selectedItems[m] then unhighlight(m) else highlight(m) end
            refreshStatus()
        end
    elseif modeGroup then
        local m = modelFromTarget(target)
        if m then
            local name = itemName(m)
            for _, obj in ipairs(getSortables()) do
                if itemName(obj) == name then highlight(obj) end
            end
            refreshStatus()
        end
    end
end)

-- ════════════════════════════════════════════════════
-- CLEANUP
-- ════════════════════════════════════════════════════
table.insert(cleanupTasks, function()
    isSorting = false; isStopped = false
    sortSlots = nil; sortIndex = 1; sortTotal = 0; sortDone = 0
    if sortThread    then pcall(task.cancel, sortThread); sortThread = nil end
    if previewFollow then previewFollow:Disconnect();     previewFollow = nil end
    if lassoRenderConn then lassoRenderConn:Disconnect(); lassoRenderConn = nil end
    inputBeganConn:Disconnect()
    mouseUpConn:Disconnect()
    if lassoUI and lassoUI.Parent then lassoUI:Destroy() end
    destroyPreview()
    clearAll()
end)

refreshStatus()
print("[VanillaHub] Vanilla4 (Sorter v4) loaded")
