-- ╔══════════════════════════════════════════════════════════════╗
-- ║              VANILLA4 — Sorter Tab                           ║
-- ║         Execute AFTER Vanilla1, Vanilla2, Vanilla3           ║
-- ╚══════════════════════════════════════════════════════════════╝

if not _G.VH then
    warn("[VanillaHub] Vanilla4 requires Vanilla1 to be executed first.")
    return
end

-- ── Services ────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = _G.VH.RunService
local TweenService     = _G.VH.TweenService
local UserInputService = _G.VH.UserInputService
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui          = game:GetService("CoreGui")

-- ── Shared hub state ────────────────────────────────────────────
local plr          = _G.VH.player
local mouse        = plr:GetMouse()
local cam          = workspace.CurrentCamera
local cleanupTasks = _G.VH.cleanupTasks
local sorterPage   = _G.VH.pages["SorterTab"]

-- ── Theme ────────────────────────────────────────────────────────
local T = {
    bg       = _G.VH.BTN_COLOR    or Color3.fromRGB(30, 30, 40),
    accent   = _G.VH.ACCENT       or Color3.fromRGB(100, 80, 200),
    text     = _G.VH.THEME_TEXT   or Color3.fromRGB(230, 206, 226),
    secText  = _G.VH.SECTION_TEXT or Color3.fromRGB(120, 110, 140),
    sep      = _G.VH.SEP_COLOR    or Color3.fromRGB(40, 40, 55),
    dark     = Color3.fromRGB(14, 14, 18),
    card     = Color3.fromRGB(20, 17, 28),
    green    = Color3.fromRGB(30, 95, 45),
    preview  = Color3.fromRGB(70, 150, 255),
    placed   = Color3.fromRGB(55, 205, 95),
    selOut   = Color3.fromRGB(0, 172, 240),
    selSurf  = Color3.fromRGB(0, 0, 0),
    axisX    = Color3.fromRGB(220, 65, 65),
    axisY    = Color3.fromRGB(60, 195, 60),
    axisZ    = Color3.fromRGB(60, 115, 255),
    warn     = Color3.fromRGB(255, 200, 60),
    good     = Color3.fromRGB(90, 220, 110),
    info     = Color3.fromRGB(130, 215, 255),
}

-- ── Constants ────────────────────────────────────────────────────
local GRID_GAP     = 0.05   -- studs between items in the grid
local CACHE_TTL    = 1.5    -- seconds before item list is re-scanned

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  STATE                                                       ║
-- ╚══════════════════════════════════════════════════════════════╝
local selected    = {}      -- [model] = SelectionBox
local prevPart    = nil
local prevConn    = nil
local prevPlaced  = false

local isSorting   = false
local isStopped   = false
local sortThread  = nil
local sortSlots   = nil
local sortIdx     = 1
local sortTotal   = 0
local sortDone    = 0

local gridCols    = 5
local gridLayers  = 1
local gridRows    = 0   -- 0 = auto
local sortDelay   = 0.3

local modeClick   = false
local modeLasso   = false
local modeGroup   = false

local lassoAnchor = nil
local lassoActive = false

local itemCache   = nil
local itemCacheT  = 0

local noclipConn  = nil

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  ITEM IDENTIFICATION                                         ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Primary part used for positioning and ownership checks
local function getMainPart(model)
    return model:FindFirstChild("Main")
        or model:FindFirstChild("WoodSection")
        or model:FindFirstChildWhichIsA("BasePart")
end

-- A model is a valid draggable item if and only if it has an "Owner"
-- StringValue as a direct child. This is the same gate Vanilla3 uses
-- and naturally excludes land, terrain, trees, and all static props.
local function isItem(model)
    if not (model and model:IsA("Model") and model ~= workspace) then return false end
    if not model:FindFirstChild("Owner")  then return false end
    if not getMainPart(model)             then return false end
    if model:FindFirstChild("TreeClass")  then return false end
    return true
end

-- Walk up from a clicked BasePart to find the owning item model
local function itemFromPart(target)
    local obj = target
    while obj and obj ~= workspace do
        if obj:IsA("Model") and isItem(obj) then return obj end
        obj = obj.Parent
    end
end

-- Display name used for Group Select matching
local function getItemName(model)
    local v = model:FindFirstChild("ItemName") or model:FindFirstChild("PurchasedBoxItemName")
    return v and v.Value or model.Name
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  ITEM CACHE                                                  ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Scan PlayerModels (and sub-folders) for all valid items.
-- Result is cached for CACHE_TTL seconds to keep lasso/group fast.
local function getAllItems()
    if itemCache and (time() - itemCacheT) < CACHE_TTL then return itemCache end
    local list = {}
    local pm   = workspace:FindFirstChild("PlayerModels")
    local src  = pm and pm:GetDescendants() or workspace:GetDescendants()
    for _, obj in ipairs(src) do
        if obj:IsA("Model") and isItem(obj) then
            list[#list + 1] = obj
        end
    end
    itemCache  = list
    itemCacheT = time()
    return list
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SELECTION                                                   ║
-- ╚══════════════════════════════════════════════════════════════╝

local function doSelect(model)
    if selected[model] then return end
    local part = getMainPart(model)
    if not part then return end
    -- Remove any stale selection box first
    local old = part:FindFirstChild("VH_Sel")
    if old then old:Destroy() end
    local sb = Instance.new("SelectionBox")
    sb.Name               = "VH_Sel"
    sb.Color3             = T.selOut
    sb.SurfaceColor3      = T.selSurf
    sb.LineThickness      = 0.09
    sb.SurfaceTransparency = 0.5
    sb.Adornee            = part
    sb.Parent             = part
    selected[model] = sb
end

local function doDeselect(model)
    if selected[model] then
        selected[model]:Destroy()
        selected[model] = nil
    end
end

local function deselectAll()
    for _, sb in pairs(selected) do
        if sb and sb.Parent then sb:Destroy() end
    end
    selected = {}
end

local function selectionCount()
    local n = 0
    for _ in pairs(selected) do n = n + 1 end
    return n
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  NOCLIP                                                      ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Character noclip uses a Stepped loop because Roblox resets CanCollide
-- every physics step; a one-shot assignment doesn't survive.
local function setCharNoclip(enabled)
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    local char = plr.Character
    if not char then return end
    if enabled then
        noclipConn = RunService.Stepped:Connect(function()
            local c = plr.Character
            if not c then return end
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    else
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end
end

local function setItemNoclip(model, enabled)
    pcall(function()
        for _, p in ipairs(model:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = not enabled end
        end
    end)
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SERVER-SIDE PLACEMENT ENGINE                                ║
-- ║                                                              ║
-- ║  Flow (mirrors Vanilla3 Item Tab exactly):                   ║
-- ║    1. Unanchor item → physics object the server can own      ║
-- ║    2. Enable noclip on item + character                      ║
-- ║    3. Teleport character beside item                         ║
-- ║    4. Fire ClientIsDragging(model) ×3 then loop until        ║
-- ║       all unanchored parts have ReceiveAge == 0              ║
-- ║    5. model:PivotTo(targetCF)  — replicates because we own   ║
-- ║    6. Anchor item + disable item noclip                      ║
-- ║    7. Fire ClientIsDragging(nil) to release                  ║
-- ╚══════════════════════════════════════════════════════════════╝

local dragRemote = nil
local function getDragRemote()
    if dragRemote then return dragRemote end
    local interaction = ReplicatedStorage:FindFirstChild("Interaction")
    dragRemote = interaction and interaction:FindFirstChild("ClientIsDragging")
    return dragRemote
end

local function setAnchored(model, state)
    pcall(function()
        for _, p in ipairs(model:GetDescendants()) do
            if p:IsA("BasePart") then p.Anchored = state end
        end
        if model.PrimaryPart then model.PrimaryPart.Anchored = state end
    end)
end

local function waitForOwnership(model, timeout)
    local deadline = tick() + (timeout or 4)
    local remote   = getDragRemote()
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

local function placeItem(model, targetCF)
    if not (model and model.Parent) then return end
    local mp     = getMainPart(model)
    local remote = getDragRemote()
    if not mp then return end

    setAnchored(model, false)
    setItemNoclip(model, true)
    setCharNoclip(true)

    -- Teleport character next to the item (server proximity check)
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = CFrame.new(mp.Position) * CFrame.new(0, 2, 4) end

    -- Initial ownership bursts
    if remote then
        for _ = 1, 3 do
            pcall(remote.FireServer, remote, model)
            task.wait(0.05)
        end
    end

    waitForOwnership(model, 3)

    -- Move — replicates server-side because client owns the parts
    pcall(function()
        if not model.PrimaryPart then model.PrimaryPart = mp end
        model:PivotTo(targetCF)
    end)

    task.wait(0.08)   -- let position propagate to server

    -- Lock in place and restore collision
    setAnchored(model, true)
    setItemNoclip(model, false)
    task.wait(0.05)   -- let anchor state replicate

    if remote then pcall(remote.FireServer, remote, nil) end
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  GRID CALCULATOR                                             ║
-- ║                                                              ║
-- ║  Uses a UNIFORM cell size (global max W / H / D).            ║
-- ║  Every slot is the same size → clean, even grid.             ║
-- ║  Fill order:  X (columns) → Z (rows) → Y (layers)           ║
-- ╚══════════════════════════════════════════════════════════════╝

local function measureBounds(models)
    local maxW, maxH, maxD = 0, 0, 0
    for _, m in ipairs(models) do
        local ok, _, sz = pcall(function() return m:GetBoundingBox() end)
        local s = (ok and sz) or Vector3.new(2, 2, 2)
        if s.X > maxW then maxW = s.X end
        if s.Y > maxH then maxH = s.Y end
        if s.Z > maxD then maxD = s.Z end
    end
    return math.max(maxW, 0.1), math.max(maxH, 0.1), math.max(maxD, 0.1)
end

local function calcSlots(models, anchorCF, cols, layers, rows)
    cols   = math.max(1, cols)
    layers = math.max(1, layers)
    rows   = math.max(0, rows)

    local n = #models
    if n == 0 then return {} end

    local maxW, maxH, maxD = measureBounds(models)
    local perLayer     = math.ceil(n / layers)
    local rowsPerLayer = rows > 0 and rows
        or math.max(1, math.ceil(perLayer / cols))

    local stepX = maxW + GRID_GAP
    local stepY = maxH + GRID_GAP
    local stepZ = maxD + GRID_GAP

    local slots = {}
    for i, model in ipairs(models) do
        local idx = i - 1
        local lay = math.floor(idx / (cols * rowsPerLayer))
        local rem = idx % (cols * rowsPerLayer)
        local row = math.floor(rem / cols)
        local col = rem % cols

        slots[#slots + 1] = {
            model = model,
            cf    = anchorCF * CFrame.new(
                col * stepX + maxW * 0.5,
                lay * stepY + maxH * 0.5,
                row * stepZ + maxD * 0.5
            ),
        }
    end
    return slots
end

-- Returns the preview box dimensions that exactly match calcSlots
local function calcPreviewSize(models, cols, layers, rows)
    local n = #models
    if n == 0 then return 4, 4, 4 end
    cols   = math.max(1, cols)
    layers = math.max(1, layers)
    rows   = math.max(0, rows)

    local maxW, maxH, maxD = measureBounds(models)
    local perLayer     = math.ceil(n / layers)
    local rowsPerLayer = rows > 0 and rows
        or math.max(1, math.ceil(perLayer / cols))
    local colsUsed = math.min(cols, n)

    return math.max(colsUsed     * (maxW + GRID_GAP) - GRID_GAP, 0.5),
           math.max(layers       * (maxH + GRID_GAP) - GRID_GAP, 0.5),
           math.max(rowsPerLayer * (maxD + GRID_GAP) - GRID_GAP, 0.5)
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PREVIEW BOX                                                 ║
-- ╚══════════════════════════════════════════════════════════════╝

local function destroyPreview()
    if prevConn then prevConn:Disconnect(); prevConn = nil end
    if prevPart and prevPart.Parent then prevPart:Destroy() end
    prevPart = nil; prevPlaced = false
end

local function getGroundCF(halfH)
    local ray = cam:ScreenPointToRay(mouse.X, mouse.Y)
    local rp  = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local excl = {}
    if prevPart    then excl[#excl+1] = prevPart end
    if plr.Character then excl[#excl+1] = plr.Character end
    rp.FilterDescendantsInstances = excl
    local hit = workspace:Raycast(ray.Origin, ray.Direction * 600, rp)
    local pos
    if hit then
        pos = hit.Position
    else
        local t = ray.Direction.Y ~= 0 and (-ray.Origin.Y / ray.Direction.Y) or nil
        pos = (t and t > 0) and (ray.Origin + ray.Direction * t) or (ray.Origin + ray.Direction * 40)
    end
    return CFrame.new(pos.X, pos.Y + halfH, pos.Z)
end

local function buildPreview(sX, sY, sZ)
    destroyPreview()
    local p = Instance.new("Part")
    p.Name         = "VH_SorterPreview"
    p.Anchored     = true
    p.CanCollide   = false
    p.CanQuery     = false
    p.CastShadow   = false
    p.Size         = Vector3.new(sX, sY, sZ)
    p.Color        = T.preview
    p.Material     = Enum.Material.SmoothPlastic
    p.Transparency = 0.5
    p.Parent       = workspace
    local sb = Instance.new("SelectionBox")
    sb.Color3 = T.preview; sb.LineThickness = 0.06
    sb.SurfaceTransparency = 1; sb.Adornee = p; sb.Parent = p
    prevPart    = p
    prevPlaced  = false
    prevConn = RunService.RenderStepped:Connect(function()
        if not (prevPart and prevPart.Parent) then
            prevConn:Disconnect(); prevConn = nil; return
        end
        prevPart.CFrame = prevPart.CFrame:Lerp(getGroundCF(prevPart.Size.Y / 2), 0.2)
    end)
end

local function lockPreview()
    if not (prevPart and prevPart.Parent and not prevPlaced) then return end
    if prevConn then prevConn:Disconnect(); prevConn = nil end
    prevPart.CFrame = getGroundCF(prevPart.Size.Y / 2)
    prevPart.Color  = T.placed
    local sb = prevPart:FindFirstChildOfClass("SelectionBox")
    if sb then sb.Color3 = T.placed end
    prevPlaced = true
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  LASSO                                                       ║
-- ║  RenderStepped only moves the rectangle — no world scans.    ║
-- ║  World scan fires exactly once on mouse-up.                  ║
-- ╚══════════════════════════════════════════════════════════════╝

local lassoUI = Instance.new("Frame", CoreGui:FindFirstChild("VanillaHub") or CoreGui)
lassoUI.Name                   = "VH_SorterLasso"
lassoUI.BackgroundColor3       = Color3.fromRGB(80, 120, 210)
lassoUI.BackgroundTransparency = 0.82
lassoUI.BorderSizePixel        = 0
lassoUI.ZIndex                 = 25
lassoUI.Visible                = false
do
    local sk = Instance.new("UIStroke", lassoUI)
    sk.Color = Color3.fromRGB(130, 165, 255); sk.Thickness = 1.4
end

local lassoRenderConn = nil

local function lassoBegin(x, y)
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
        local mx, my = mouse.X, mouse.Y
        local ax, ay = lassoAnchor.X, lassoAnchor.Y
        lassoUI.Position = UDim2.fromOffset(math.min(ax, mx), math.min(ay, my))
        lassoUI.Size     = UDim2.fromOffset(math.abs(mx - ax), math.abs(my - ay))
    end)
end

local function lassoFinish()
    lassoActive = false
    if lassoRenderConn then lassoRenderConn:Disconnect(); lassoRenderConn = nil end
    lassoUI.Visible = false
    -- One-time scan on release
    if not lassoAnchor then return end
    local mx, my = mouse.X, mouse.Y
    local x0 = math.min(lassoAnchor.X, mx); local x1 = math.max(lassoAnchor.X, mx)
    local y0 = math.min(lassoAnchor.Y, my); local y1 = math.max(lassoAnchor.Y, my)
    if (x1 - x0) < 4 and (y1 - y0) < 4 then lassoAnchor = nil; return end
    for _, model in ipairs(getAllItems()) do
        local mp = getMainPart(model)
        if mp then
            local sp, vis = cam:WorldToScreenPoint(mp.Position)
            if vis and sp.X >= x0 and sp.X <= x1 and sp.Y >= y0 and sp.Y <= y1 then
                doSelect(model)
            end
        end
    end
    lassoAnchor = nil
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  UI PRIMITIVES                                               ║
-- ╚══════════════════════════════════════════════════════════════╝

local pageLayout = sorterPage:FindFirstChildOfClass("UIListLayout")
if pageLayout then pageLayout.Padding = UDim.new(0, 6) end

local function mkSep()
    local f = Instance.new("Frame", sorterPage)
    f.Size = UDim2.new(1, 0, 0, 1)
    f.BackgroundColor3 = T.sep
    f.BorderSizePixel  = 0
end

local function mkHeader(text)
    local f = Instance.new("Frame", sorterPage)
    f.Size = UDim2.new(1, 0, 0, 22)
    f.BackgroundTransparency = 1
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1, -8, 1, 0); l.Position = UDim2.new(0, 8, 0, 0)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold; l.TextSize = 10
    l.TextColor3 = T.secText
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = "  " .. string.upper(text)
end

local function mkHint(text)
    local l = Instance.new("TextLabel", sorterPage)
    l.Size = UDim2.new(1, 0, 0, 16)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.Gotham; l.TextSize = 11
    l.TextColor3 = Color3.fromRGB(75, 75, 95)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextWrapped = true
    l.Text = "  " .. text
end

local function mkButton(text, color, callback)
    color = color or T.bg
    local b = Instance.new("TextButton", sorterPage)
    b.Size             = UDim2.new(1, 0, 0, 34)
    b.BackgroundColor3 = color
    b.Text             = text
    b.Font             = Enum.Font.GothamSemibold
    b.TextSize         = 13
    b.TextColor3       = T.text
    b.BorderSizePixel  = 0
    b.AutoButtonColor  = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    local hover = Color3.fromRGB(
        math.min(color.R * 255 + 20, 255) / 255,
        math.min(color.G * 255 + 10, 255) / 255,
        math.min(color.B * 255 + 20, 255) / 255)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.14), {BackgroundColor3 = hover}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.14), {BackgroundColor3 = color}):Play()
    end)
    if callback then b.MouseButton1Click:Connect(callback) end
    return b
end

-- Returns frame + external setter function
local function mkToggle(text, default, callback)
    local OFF_COL = Color3.fromRGB(38, 38, 48)
    local ON_COL  = Color3.fromRGB(55, 160, 75)

    local fr = Instance.new("Frame", sorterPage)
    fr.Size = UDim2.new(1, 0, 0, 36)
    fr.BackgroundColor3 = T.dark; fr.BorderSizePixel = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel", fr)
    lbl.Size = UDim2.new(1, -56, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = text
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = T.text; lbl.TextXAlignment = Enum.TextXAlignment.Left

    local track = Instance.new("TextButton", fr)
    track.Size = UDim2.new(0, 38, 0, 21)
    track.Position = UDim2.new(1, -48, 0.5, -10)
    track.BackgroundColor3 = default and ON_COL or OFF_COL
    track.Text = ""; track.BorderSizePixel = 0; track.AutoButtonColor = false
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0, 15, 0, 15)
    knob.Position = UDim2.new(0, default and 20 or 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(240, 240, 240); knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = default
    local TI = TweenInfo.new(0.18, Enum.EasingStyle.Quad)

    local function apply(v)
        state = v
        TweenService:Create(track, TI, {BackgroundColor3 = v and ON_COL or OFF_COL}):Play()
        TweenService:Create(knob,  TI, {Position = UDim2.new(0, v and 20 or 2, 0.5, -7)}):Play()
    end

    task.defer(function() if callback then callback(state) end end)
    track.MouseButton1Click:Connect(function()
        apply(not state)
        if callback then callback(state) end
    end)

    return fr, function(v) if v ~= state then apply(v) end end
end

local function mkSlider(text, minV, maxV, defV, callback)
    local fr = Instance.new("Frame", sorterPage)
    fr.Size = UDim2.new(1, 0, 0, 54)
    fr.BackgroundColor3 = T.dark; fr.BorderSizePixel = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 8)

    local labelRow = Instance.new("Frame", fr)
    labelRow.Size = UDim2.new(1, -16, 0, 22); labelRow.Position = UDim2.new(0, 8, 0, 7)
    labelRow.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", labelRow)
    lbl.Size = UDim2.new(0.74, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = T.text; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = text

    local valLbl = Instance.new("TextLabel", labelRow)
    valLbl.Size = UDim2.new(0.26, 0, 1, 0); valLbl.Position = UDim2.new(0.74, 0, 0, 0)
    valLbl.BackgroundTransparency = 1; valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 13
    valLbl.TextColor3 = Color3.fromRGB(155, 155, 170)
    valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.Text = tostring(defV)

    local track = Instance.new("Frame", fr)
    track.Size = UDim2.new(1, -16, 0, 5); track.Position = UDim2.new(0, 8, 0, 38)
    track.BackgroundColor3 = Color3.fromRGB(30, 30, 40); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((defV - minV) / (maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = T.accent; fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0, 15, 0, 15); knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((defV - minV) / (maxV - minV), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(215, 215, 225)
    knob.Text = ""; knob.BorderSizePixel = 0; knob.AutoButtonColor = false
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function update(absX)
        local r = math.clamp(
            (absX - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local v = math.round(minV + r * (maxV - minV))
        fill.Size = UDim2.new(r, 0, 1, 0)
        knob.Position = UDim2.new(r, 0, 0.5, 0)
        valLbl.Text = tostring(v)
        if callback then callback(v) end
    end
    knob.MouseButton1Down:Connect(function() dragging = true end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; update(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            update(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

local AXIS_COLORS = {X = T.axisX, Y = T.axisY, Z = T.axisZ}
local function mkAxisSlider(label, axis, minV, maxV, defV, callback)
    local ac = AXIS_COLORS[axis] or T.text

    local fr = Instance.new("Frame", sorterPage)
    fr.Size = UDim2.new(1, 0, 0, 54)
    fr.BackgroundColor3 = T.dark; fr.BorderSizePixel = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 8)

    local axisLbl = Instance.new("TextLabel", fr)
    axisLbl.Size = UDim2.new(0, 20, 0, 22); axisLbl.Position = UDim2.new(0, 8, 0, 7)
    axisLbl.BackgroundTransparency = 1; axisLbl.Font = Enum.Font.GothamBold
    axisLbl.TextSize = 14; axisLbl.TextColor3 = ac; axisLbl.Text = axis

    local textLbl = Instance.new("TextLabel", fr)
    textLbl.Size = UDim2.new(0.6, 0, 0, 22); textLbl.Position = UDim2.new(0, 30, 0, 7)
    textLbl.BackgroundTransparency = 1; textLbl.Font = Enum.Font.GothamSemibold
    textLbl.TextSize = 12; textLbl.TextColor3 = T.text
    textLbl.TextXAlignment = Enum.TextXAlignment.Left; textLbl.Text = label

    local valLbl = Instance.new("TextLabel", fr)
    valLbl.Size = UDim2.new(0.26, 0, 0, 22); valLbl.Position = UDim2.new(0.74, -8, 0, 7)
    valLbl.BackgroundTransparency = 1; valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 13; valLbl.TextColor3 = ac
    valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.Text = tostring(defV)

    local track = Instance.new("Frame", fr)
    track.Size = UDim2.new(1, -16, 0, 5); track.Position = UDim2.new(0, 8, 0, 38)
    track.BackgroundColor3 = Color3.fromRGB(30, 30, 40); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((defV - minV) / (maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = ac; fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0, 15, 0, 15); knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((defV - minV) / (maxV - minV), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(215, 215, 225)
    knob.Text = ""; knob.BorderSizePixel = 0; knob.AutoButtonColor = false
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local dragging = false; local last = defV
    local function update(absX)
        local r = math.clamp(
            (absX - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local v = math.round(minV + r * (maxV - minV))
        if v == last then return end; last = v
        fill.Size = UDim2.new(r, 0, 1, 0)
        knob.Position = UDim2.new(r, 0, 0.5, 0)
        valLbl.Text = tostring(v)
        if callback then callback(v) end
    end
    knob.MouseButton1Down:Connect(function() dragging = true end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; update(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            update(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  STATUS CARD                                                 ║
-- ╚══════════════════════════════════════════════════════════════╝

local statusLabel
do
    local card = Instance.new("Frame", sorterPage)
    card.Size = UDim2.new(1, 0, 0, 46)
    card.BackgroundColor3 = T.card; card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = T.warn; stroke.Thickness = 1; stroke.Transparency = 0.55

    local l = Instance.new("TextLabel", card)
    l.Size = UDim2.new(1, -18, 1, 0); l.Position = UDim2.new(0, 9, 0, 0)
    l.BackgroundTransparency = 1; l.Font = Enum.Font.GothamSemibold; l.TextSize = 12
    l.TextColor3 = T.warn; l.TextXAlignment = Enum.TextXAlignment.Left; l.TextWrapped = true
    l.Text = "Select items to get started."
    statusLabel = l
end

local function setStatus(msg, color)
    statusLabel.Text       = msg
    statusLabel.TextColor3 = color or T.warn
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PROGRESS BAR                                                ║
-- ╚══════════════════════════════════════════════════════════════╝

local pbFrame, pbFill, pbLabel
do
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 46); f.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    f.BorderSizePixel = 0; f.Visible = false
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
    local sk = Instance.new("UIStroke", f)
    sk.Color = Color3.fromRGB(55, 55, 75); sk.Thickness = 1; sk.Transparency = 0.4

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, -14, 0, 18); lbl.Position = UDim2.new(0, 7, 0, 5)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 11
    lbl.TextColor3 = T.text; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = "Ready."

    local track = Instance.new("Frame", f)
    track.Size = UDim2.new(1, -14, 0, 13); track.Position = UDim2.new(0, 7, 0, 27)
    track.BackgroundColor3 = Color3.fromRGB(28, 28, 40); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fl = Instance.new("Frame", track)
    fl.Size = UDim2.new(0, 0, 1, 0); fl.BackgroundColor3 = Color3.fromRGB(255, 170, 50)
    fl.BorderSizePixel = 0
    Instance.new("UICorner", fl).CornerRadius = UDim.new(1, 0)

    pbFrame = f; pbFill = fl; pbLabel = lbl
end

local function setPb(frac, text, color)
    TweenService:Create(pbFill, TweenInfo.new(0.16, Enum.EasingStyle.Quad),
        {Size = UDim2.new(math.clamp(frac, 0, 1), 0, 1, 0)}):Play()
    if color then pbFill.BackgroundColor3 = color end
    if text  then pbLabel.Text = text end
end

local function hidePb(after)
    task.delay(after or 2, function()
        if not pbFrame then return end
        local ti = TweenInfo.new(0.35)
        TweenService:Create(pbFrame, ti, {BackgroundTransparency = 1}):Play()
        TweenService:Create(pbFill,  ti, {BackgroundTransparency = 1}):Play()
        TweenService:Create(pbLabel, ti, {TextTransparency = 1}):Play()
        task.delay(0.4, function()
            if not pbFrame then return end
            pbFrame.Visible = false
            pbFrame.BackgroundTransparency = 0
            pbFill.BackgroundTransparency  = 0
            pbFill.BackgroundColor3        = Color3.fromRGB(255, 170, 50)
            pbFill.Size                    = UDim2.new(0, 0, 1, 0)
            pbLabel.TextTransparency       = 0
        end)
    end)
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SORT STATUS REFRESH                                         ║
-- ╚══════════════════════════════════════════════════════════════╝

local startBtn, stopBtn  -- assigned later

local function refreshUI()
    local n = selectionCount()
    if isSorting then
        setStatus("⏳  Sorting in progress…", T.info)
    elseif isStopped then
        setStatus("⏸  Paused — click Resume to continue.", T.warn)
    elseif n == 0 then
        setStatus("👆  Select items via Click, Lasso, or Group.")
    elseif prevConn then
        setStatus("🖱  Preview following — click to place.", T.info)
    elseif prevPlaced then
        setStatus("✅  " .. n .. " item(s) ready — hit Start!", T.good)
    elseif prevPart then
        setStatus("📦  Preview placed — hit Start Sorting!")
    else
        setStatus("📦  " .. n .. " selected — Generate a Preview.")
    end

    if startBtn then
        local canGo = (n > 0 or isStopped) and (prevPlaced or isStopped) and not isSorting
        startBtn.BackgroundColor3 = canGo and T.green or Color3.fromRGB(26, 26, 36)
        startBtn.TextColor3       = canGo and T.text  or Color3.fromRGB(68, 68, 78)
        startBtn.Text             = isStopped and "▶  Resume Sorting" or "▶  Start Sorting"
    end
    if stopBtn then
        local active = isSorting
        stopBtn.BackgroundColor3 = active and Color3.fromRGB(95, 55, 18) or Color3.fromRGB(26, 26, 36)
        stopBtn.TextColor3       = active and Color3.fromRGB(255, 185, 75) or Color3.fromRGB(68, 68, 78)
    end
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SORT LOOP                                                   ║
-- ╚══════════════════════════════════════════════════════════════╝

local function runSort(slots, startI, total, doneStart)
    local done = doneStart
    sortThread = task.spawn(function()
        for i = startI, total do
            if not isSorting then sortIdx = i; break end

            local slot = slots[i]
            if not (slot.model and slot.model.Parent) then
                done = done + 1; sortDone = done; sortIdx = i + 1
                setPb(done / total, "Skipped — " .. done .. "/" .. total)
                continue
            end

            setPb(done / total, "Placing " .. (done + 1) .. " / " .. total)
            placeItem(slot.model, slot.cf)

            if not isSorting then sortIdx = i; break end

            doDeselect(slot.model)
            done = done + 1; sortDone = done; sortIdx = i + 1
            setPb(done / total, "Sorted " .. done .. " / " .. total)
            task.wait(sortDelay)
        end

        -- Always restore character collision when the loop ends
        setCharNoclip(false)
        isSorting = false; sortThread = nil

        if done >= total then
            isStopped = false; sortSlots = nil
            setPb(1, "✔  Done! " .. done .. " items placed.", T.good)
            destroyPreview(); deselectAll(); hidePb(3)
        else
            isStopped = true
            setPb(done / math.max(total, 1), "⏸  Stopped at " .. done .. " / " .. total)
        end
        refreshUI()
    end)
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  BUILD UI                                                    ║
-- ╚══════════════════════════════════════════════════════════════╝

mkSep()

-- ── 1. Selection ────────────────────────────────────────────────
mkHeader("Selection Mode")

mkToggle("Click Select",  false, function(v)
    modeClick = v; if v then modeLasso = false; modeGroup = false end
end)
mkToggle("Lasso Select",  false, function(v)
    modeLasso = v; if v then modeClick = false; modeGroup = false end
end)
mkToggle("Group Select",  false, function(v)
    modeGroup = v; if v then modeClick = false; modeLasso = false end
end)
mkHint("Click: toggle one  ·  Lasso: drag a box  ·  Group: all of same type")
mkButton("Deselect All", T.bg, function() deselectAll(); refreshUI() end)

mkSep()

-- ── 2. Speed ─────────────────────────────────────────────────────
mkHeader("Sort Speed")
mkSlider("Delay per item  (×0.1 s)", 1, 20, 3, function(v)
    sortDelay = v / 10
    if _G.VH then _G.VH.tpItemSpeed = sortDelay end
end)

mkSep()

-- ── 3. Grid ──────────────────────────────────────────────────────
mkHeader("Sort Grid")
mkAxisSlider("Columns  (X axis)",           "X",  1, 12, 5, function(v) gridCols   = v end)
mkAxisSlider("Layers   (Y axis, vertical)", "Y",  1,  5, 1, function(v) gridLayers = v end)
mkAxisSlider("Rows     (Z axis, 0 = auto)", "Z",  0, 12, 0, function(v) gridRows   = v end)
mkHint("Fills cols → rows → layers.  Z = 0 auto-fits all items.")

mkSep()

-- ── 4. Preview ───────────────────────────────────────────────────
mkHeader("Preview")

local prevRow = Instance.new("Frame", sorterPage)
prevRow.Size = UDim2.new(1, 0, 0, 34); prevRow.BackgroundTransparency = 1

local genBtn = Instance.new("TextButton", prevRow)
genBtn.Size = UDim2.new(0.60, -3, 1, 0)
genBtn.BackgroundColor3 = Color3.fromRGB(25, 52, 105)
genBtn.Text = "Generate Preview"; genBtn.Font = Enum.Font.GothamSemibold; genBtn.TextSize = 13
genBtn.TextColor3 = T.text; genBtn.BorderSizePixel = 0; genBtn.AutoButtonColor = false
Instance.new("UICorner", genBtn).CornerRadius = UDim.new(0, 8)

local clrBtn = Instance.new("TextButton", prevRow)
clrBtn.Size = UDim2.new(0.40, -3, 1, 0); clrBtn.Position = UDim2.new(0.60, 3, 0, 0)
clrBtn.BackgroundColor3 = T.bg; clrBtn.Text = "Clear Preview"
clrBtn.Font = Enum.Font.GothamSemibold; clrBtn.TextSize = 12
clrBtn.TextColor3 = T.text; clrBtn.BorderSizePixel = 0; clrBtn.AutoButtonColor = false
Instance.new("UICorner", clrBtn).CornerRadius = UDim.new(0, 8)

for _, b in {genBtn, clrBtn} do
    local base = b.BackgroundColor3
    local hov  = Color3.fromRGB(
        math.min(base.R * 255 + 22, 255) / 255,
        math.min(base.G * 255 + 12, 255) / 255,
        math.min(base.B * 255 + 22, 255) / 255)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.13), {BackgroundColor3 = hov}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.13), {BackgroundColor3 = base}):Play()
    end)
end

genBtn.MouseButton1Click:Connect(function()
    if selectionCount() == 0 then setStatus("⚠  Select items first!"); return end
    local models = {}
    for m in pairs(selected) do models[#models + 1] = m end
    local sX, sY, sZ = calcPreviewSize(models, gridCols, gridLayers, gridRows)
    buildPreview(sX, sY, sZ)
    refreshUI()
end)
clrBtn.MouseButton1Click:Connect(function() destroyPreview(); refreshUI() end)

mkHint("Preview follows cursor — click to lock in place.")

mkSep()

-- ── 5. Actions ───────────────────────────────────────────────────
mkHeader("Actions")

startBtn = Instance.new("TextButton", sorterPage)
startBtn.Size = UDim2.new(1, 0, 0, 38)
startBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
startBtn.Text = "▶  Start Sorting"; startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 14; startBtn.TextColor3 = Color3.fromRGB(68, 68, 78)
startBtn.BorderSizePixel = 0; startBtn.AutoButtonColor = false
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 10)

local actionRow = Instance.new("Frame", sorterPage)
actionRow.Size = UDim2.new(1, 0, 0, 32); actionRow.BackgroundTransparency = 1

stopBtn = Instance.new("TextButton", actionRow)
stopBtn.Size = UDim2.new(0.48, -2, 1, 0)
stopBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
stopBtn.Text = "⏹  Stop"; stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 13; stopBtn.TextColor3 = Color3.fromRGB(68, 68, 78)
stopBtn.BorderSizePixel = 0; stopBtn.AutoButtonColor = false
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 8)

local cancelBtn = Instance.new("TextButton", actionRow)
cancelBtn.Size = UDim2.new(0.52, -2, 1, 0); cancelBtn.Position = UDim2.new(0.48, 2, 0, 0)
cancelBtn.BackgroundColor3 = Color3.fromRGB(58, 14, 14)
cancelBtn.Text = "✕  Cancel & Clear"; cancelBtn.Font = Enum.Font.GothamBold
cancelBtn.TextSize = 12; cancelBtn.TextColor3 = Color3.fromRGB(200, 90, 90)
cancelBtn.BorderSizePixel = 0; cancelBtn.AutoButtonColor = false
Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 8)

-- ── 6. Progress bar ──────────────────────────────────────────────
pbFrame.Parent = sorterPage

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  BUTTON LOGIC                                                ║
-- ╚══════════════════════════════════════════════════════════════╝

startBtn.MouseButton1Click:Connect(function()
    if isSorting then return end

    -- Resume a paused sort
    if isStopped and sortSlots then
        isStopped = false; isSorting = true
        pbFrame.Visible = true
        pbFill.BackgroundColor3 = Color3.fromRGB(255, 170, 50)
        refreshUI()
        runSort(sortSlots, sortIdx, sortTotal, sortDone)
        return
    end

    if not (prevPlaced and prevPart and prevPart.Parent) then
        setStatus("⚠  Generate and place a preview first!"); return
    end
    if selectionCount() == 0 then setStatus("⚠  No items selected!"); return end

    local items = {}
    for m in pairs(selected) do
        if m and m.Parent then items[#items + 1] = m end
    end
    if #items == 0 then return end

    -- Grid anchor = bottom-left-front corner of the preview box
    local anchorCF = prevPart.CFrame
        * CFrame.new(-prevPart.Size.X / 2, -prevPart.Size.Y / 2, -prevPart.Size.Z / 2)

    sortSlots  = calcSlots(items, anchorCF, gridCols, gridLayers, gridRows)
    sortTotal  = #sortSlots
    sortDone   = 0
    sortIdx    = 1
    isStopped  = false
    isSorting  = true

    pbFrame.Visible         = true
    pbFill.Size             = UDim2.new(0, 0, 1, 0)
    pbFill.BackgroundColor3 = Color3.fromRGB(255, 170, 50)
    pbLabel.Text            = "Starting…"
    refreshUI()
    runSort(sortSlots, 1, sortTotal, 0)
end)

stopBtn.MouseButton1Click:Connect(function()
    if not isSorting then return end
    isSorting = false
    pbLabel.Text = "⏸  Stopping…"
    refreshUI()
end)

cancelBtn.MouseButton1Click:Connect(function()
    isSorting  = false
    isStopped  = false
    sortSlots  = nil; sortIdx = 1; sortTotal = 0; sortDone = 0
    if sortThread then pcall(task.cancel, sortThread); sortThread = nil end
    setCharNoclip(false)
    destroyPreview(); deselectAll()
    pbLabel.Text = "Cancelled."
    hidePb(1)
    refreshUI()
end)

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  INPUT HANDLING                                              ║
-- ╚══════════════════════════════════════════════════════════════╝

local inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if modeLasso then lassoBegin(mouse.X, mouse.Y) end
end)

local upConn = mouse.Button1Up:Connect(function()
    -- Priority 1: end an active lasso
    if modeLasso and lassoActive then
        lassoFinish(); refreshUI(); return
    end
    -- Priority 2: lock preview in place
    if prevPart and prevPart.Parent and not prevPlaced then
        lockPreview(); refreshUI(); return
    end
    -- Priority 3: click / group select
    local target = mouse.Target
    if modeClick then
        local m = itemFromPart(target)
        if m then
            if selected[m] then doDeselect(m) else doSelect(m) end
            refreshUI()
        end
    elseif modeGroup then
        local m = itemFromPart(target)
        if m then
            local name = getItemName(m)
            for _, obj in ipairs(getAllItems()) do
                if getItemName(obj) == name then doSelect(obj) end
            end
            refreshUI()
        end
    end
end)

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  CLEANUP                                                     ║
-- ╚══════════════════════════════════════════════════════════════╝

table.insert(cleanupTasks, function()
    isSorting = false; isStopped = false
    sortSlots = nil; sortIdx = 1; sortTotal = 0; sortDone = 0
    if sortThread       then pcall(task.cancel, sortThread); sortThread = nil end
    if prevConn         then prevConn:Disconnect();          prevConn = nil    end
    if lassoRenderConn  then lassoRenderConn:Disconnect();   lassoRenderConn = nil end
    if noclipConn       then noclipConn:Disconnect();        noclipConn = nil  end
    inputConn:Disconnect()
    upConn:Disconnect()
    if lassoUI and lassoUI.Parent then lassoUI:Destroy() end
    destroyPreview()
    deselectAll()
end)

refreshUI()
print("[VanillaHub] Vanilla4 (Sorter) loaded")
