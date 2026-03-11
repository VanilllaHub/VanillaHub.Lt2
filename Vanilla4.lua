-- ════════════════════════════════════════════════════
-- VANILLA4 — Sorter Tab  (v5)
-- Execute AFTER Vanilla1, Vanilla2, Vanilla3
-- ════════════════════════════════════════════════════

if not _G.VH then
    warn("[VanillaHub] Vanilla4: _G.VH not found. Execute Vanilla1 first.")
    return
end

-- ── Services & shared state ─────────────────────────
local TS   = _G.VH.TweenService
local UIS  = _G.VH.UserInputService
local RS2  = game:GetService("ReplicatedStorage")
local RUN  = _G.VH.RunService
local plr  = _G.VH.player
local mouse = plr:GetMouse()
local cam   = workspace.CurrentCamera

local cleanupTasks = _G.VH.cleanupTasks
local pages        = _G.VH.pages
local sorterPage   = pages["SorterTab"]

-- ── Theme (inherit from hub) ────────────────────────
local BTN_COLOR  = _G.VH.BTN_COLOR   or Color3.fromRGB(30,30,40)
local ACCENT     = _G.VH.ACCENT      or Color3.fromRGB(100,80,200)
local THEME_TEXT = _G.VH.THEME_TEXT  or Color3.fromRGB(230,206,226)
local SEC_TEXT   = _G.VH.SECTION_TEXT or Color3.fromRGB(120,110,140)
local SEP_COL    = _G.VH.SEP_COLOR   or Color3.fromRGB(40,40,55)

local C_DARK    = Color3.fromRGB(16,16,20)
local C_CARD    = Color3.fromRGB(22,18,30)
local C_GREEN   = Color3.fromRGB(35,100,50)
local C_PREVIEW = Color3.fromRGB(80,160,255)
local C_PLACED  = Color3.fromRGB(60,210,100)
local C_SEL_OUT = Color3.fromRGB(0,172,240)
local C_SEL_SRF = Color3.fromRGB(0,0,0)

-- ════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════
local sel        = {}   -- [model] = SelectionBox
local prevPart   = nil  -- preview box Part
local prevFollow = nil  -- RenderStepped conn
local prevPlaced = false

local sorting    = false
local stopped    = false
local sortThread = nil
local sortSlots  = nil
local sortIdx    = 1
local sortTotal  = 0
local sortDone   = 0

local gridCols   = 5
local gridRows   = 0   -- 0 = auto
local gridLayers = 1
local itemDelay  = 0.3

local modeClick  = false
local modeLasso  = false
local modeGroup  = false

local lassoAnchor = nil
local lassoActive = false

-- ════════════════════════════════════════════════════
-- ITEM HELPERS
-- ════════════════════════════════════════════════════
local function mainPart(m)
    return m:FindFirstChild("Main")
        or m:FindFirstChild("WoodSection")
        or m:FindFirstChildWhichIsA("BasePart")
end

-- An item is sortable if it has Owner as a direct child.
-- That's the exact same gate the Item Tab (Vanilla3) uses.
-- We do NOT require PlayerModels ancestry — items can be in sub-folders.
local function isSortable(m)
    if not (m and m:IsA("Model") and m ~= workspace) then return false end
    if not m:FindFirstChild("Owner")  then return false end
    if not mainPart(m)                then return false end
    if m:FindFirstChild("TreeClass")  then return false end
    return true
end

local function modelOf(target)
    local o = target
    while o and o ~= workspace do
        if o:IsA("Model") and isSortable(o) then return o end
        o = o.Parent
    end
end

local function itemName(m)
    local v = m:FindFirstChild("ItemName") or m:FindFirstChild("PurchasedBoxItemName")
    return v and v.Value or m.Name
end

-- ════════════════════════════════════════════════════
-- SELECTION  (SelectionBox on the Main part, same as Item Tab)
-- ════════════════════════════════════════════════════
local function selPart(m)
    return m:FindFirstChild("Main")
        or m:FindFirstChild("WoodSection")
        or m:FindFirstChildWhichIsA("BasePart")
end

local function highlight(m)
    if sel[m] then return end
    local p = selPart(m); if not p then return end
    if p:FindFirstChild("VH_Sel") then p:FindFirstChild("VH_Sel"):Destroy() end
    local sb = Instance.new("SelectionBox")
    sb.Name               = "VH_Sel"
    sb.Color3             = C_SEL_OUT
    sb.SurfaceColor3      = C_SEL_SRF
    sb.LineThickness      = 0.09
    sb.SurfaceTransparency = 0.5
    sb.Adornee            = p
    sb.Parent             = p
    sel[m] = sb
end

local function unhighlight(m)
    if sel[m] then sel[m]:Destroy(); sel[m] = nil end
end

local function clearAll()
    for m, sb in pairs(sel) do if sb and sb.Parent then sb:Destroy() end end
    sel = {}
end

local function selCount()
    local n = 0; for _ in pairs(sel) do n = n + 1 end; return n
end

-- ════════════════════════════════════════════════════
-- ITEM CACHE  (rebuilt at most once per 1.5 s)
-- ════════════════════════════════════════════════════
local _cache, _cacheT = nil, 0
local function allSortables()
    if _cache and (time()-_cacheT) < 1.5 then return _cache end
    local list = {}
    local pm  = workspace:FindFirstChild("PlayerModels")
    local src = pm and pm:GetDescendants() or workspace:GetDescendants()
    for _, o in ipairs(src) do
        if o:IsA("Model") and isSortable(o) then list[#list+1] = o end
    end
    _cache, _cacheT = list, time()
    return list
end

-- ════════════════════════════════════════════════════
-- LASSO  (RenderStepped = rect only; scan on release)
-- ════════════════════════════════════════════════════
local coreGui = game:GetService("CoreGui")
local lassoFrame = Instance.new("Frame", coreGui:FindFirstChild("VanillaHub") or coreGui)
lassoFrame.Name                   = "VH_SorterLasso"
lassoFrame.BackgroundColor3       = Color3.fromRGB(90,130,210)
lassoFrame.BackgroundTransparency = 0.84
lassoFrame.BorderSizePixel        = 0
lassoFrame.ZIndex                 = 25
lassoFrame.Visible                = false
do
    local s = Instance.new("UIStroke", lassoFrame)
    s.Color = Color3.fromRGB(140,170,255); s.Thickness = 1.5
end

local lassoConn = nil

local function lassoStart(x,y)
    lassoAnchor = Vector2.new(x,y)
    lassoActive = true
    lassoFrame.Position = UDim2.fromOffset(x,y)
    lassoFrame.Size     = UDim2.fromOffset(0,0)
    lassoFrame.Visible  = true
    if lassoConn then lassoConn:Disconnect() end
    lassoConn = RUN.RenderStepped:Connect(function()
        if not lassoActive then lassoConn:Disconnect(); lassoConn=nil; return end
        local cx,cy = mouse.X, mouse.Y
        local ax,ay = lassoAnchor.X, lassoAnchor.Y
        lassoFrame.Position = UDim2.fromOffset(math.min(ax,cx), math.min(ay,cy))
        lassoFrame.Size     = UDim2.fromOffset(math.abs(cx-ax), math.abs(cy-ay))
    end)
end

local function lassoCommit()
    if not lassoAnchor then return end
    local cx,cy = mouse.X, mouse.Y
    local minX = math.min(lassoAnchor.X,cx); local maxX = math.max(lassoAnchor.X,cx)
    local minY = math.min(lassoAnchor.Y,cy); local maxY = math.max(lassoAnchor.Y,cy)
    if (maxX-minX)<4 and (maxY-minY)<4 then return end
    for _, m in ipairs(allSortables()) do
        local p = mainPart(m)
        if p then
            local sp, vis = cam:WorldToScreenPoint(p.Position)
            if vis and sp.X>=minX and sp.X<=maxX and sp.Y>=minY and sp.Y<=maxY then
                highlight(m)
            end
        end
    end
end

local function lassoEnd()
    lassoActive = false
    if lassoConn then lassoConn:Disconnect(); lassoConn=nil end
    lassoFrame.Visible = false
    lassoCommit()
    lassoAnchor = nil
end

-- ════════════════════════════════════════════════════
-- GRID CALCULATOR
-- Uses a UNIFORM cell (max W / max H / max D across all items).
-- Every slot is identical → perfectly even grid regardless of item shape.
-- Fill order: X (col) → Z (row) → Y (layer)
-- ════════════════════════════════════════════════════
local GAP = 0.05   -- stud gap between items

local function measureItems(models)
    local maxW, maxH, maxD = 0, 0, 0
    for _, m in ipairs(models) do
        local ok, _, s = pcall(function() return m:GetBoundingBox() end)
        local sz = (ok and s) or Vector3.new(2,2,2)
        if sz.X > maxW then maxW = sz.X end
        if sz.Y > maxH then maxH = sz.Y end
        if sz.Z > maxD then maxD = sz.Z end
    end
    return maxW, maxH, maxD
end

local function calcSlots(models, anchorCF, cols, layers, rows)
    cols   = math.max(1, cols)
    layers = math.max(1, layers)
    rows   = math.max(0, rows)

    local total = #models
    if total == 0 then return {} end

    local maxW, maxH, maxD = measureItems(models)
    if maxW < 0.1 then maxW = 2 end
    if maxH < 0.1 then maxH = 2 end
    if maxD < 0.1 then maxD = 2 end

    -- Items per layer
    local perLayer = math.ceil(total / layers)
    -- Rows per layer
    local rowsPerLayer = rows > 0 and rows
        or math.max(1, math.ceil(perLayer / cols))

    -- Uniform cell step
    local stepX = maxW + GAP
    local stepY = maxH + GAP
    local stepZ = maxD + GAP

    local slots = {}
    for i, m in ipairs(models) do
        local idx  = i - 1
        local lay  = math.floor(idx / (cols * rowsPerLayer))
        local rem  = idx % (cols * rowsPerLayer)
        local row  = math.floor(rem / cols)
        local col  = rem % cols

        -- Cell centre offset from anchor (bottom-left-front corner)
        local lx = col * stepX + maxW * 0.5
        local ly = lay * stepY + maxH * 0.5
        local lz = row * stepZ + maxD * 0.5

        slots[#slots+1] = {
            model = m,
            cf    = anchorCF * CFrame.new(lx, ly, lz),
        }
    end
    return slots
end

-- Preview box size matches calcSlots exactly
local function previewDims()
    local models = {}
    for m in pairs(sel) do models[#models+1] = m end
    local n = #models
    if n == 0 then return 4,4,4 end

    local cols   = math.max(1, gridCols)
    local layers = math.max(1, gridLayers)
    local rows   = math.max(0, gridRows)

    local maxW, maxH, maxD = measureItems(models)
    if maxW < 0.1 then maxW = 2 end
    if maxH < 0.1 then maxH = 2 end
    if maxD < 0.1 then maxD = 2 end

    local perLayer     = math.ceil(n / layers)
    local rowsPerLayer = rows > 0 and rows
        or math.max(1, math.ceil(perLayer / cols))
    local colsUsed     = math.min(cols, n)

    local W = colsUsed     * (maxW + GAP) - GAP
    local H = layers       * (maxH + GAP) - GAP
    local D = rowsPerLayer * (maxD + GAP) - GAP
    return math.max(W,0.5), math.max(H,0.5), math.max(D,0.5)
end

-- ════════════════════════════════════════════════════
-- PREVIEW BOX
-- ════════════════════════════════════════════════════
local function destroyPreview()
    if prevFollow then prevFollow:Disconnect(); prevFollow=nil end
    if prevPart and prevPart.Parent then prevPart:Destroy() end
    prevPart = nil; prevPlaced = false
end

local function groundCF(halfH)
    local ray = cam:ScreenPointToRay(mouse.X, mouse.Y)
    local p   = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    local excl = {}
    if prevPart then excl[#excl+1] = prevPart end
    if plr.Character then excl[#excl+1] = plr.Character end
    p.FilterDescendantsInstances = excl
    local hit = workspace:Raycast(ray.Origin, ray.Direction*600, p)
    local pos
    if hit then
        pos = hit.Position
    else
        local t = -ray.Origin.Y / ray.Direction.Y
        pos = (t and t>0) and (ray.Origin+ray.Direction*t) or (ray.Origin+ray.Direction*40)
    end
    return CFrame.new(pos.X, pos.Y+halfH, pos.Z)
end

local function buildPreview(sX,sY,sZ)
    destroyPreview()
    local p = Instance.new("Part")
    p.Name="VH_SorterPreview"; p.Anchored=true; p.CanCollide=false
    p.CanQuery=false; p.CastShadow=false
    p.Size=Vector3.new(math.max(sX,0.5),math.max(sY,0.5),math.max(sZ,0.5))
    p.Color=C_PREVIEW; p.Material=Enum.Material.SmoothPlastic
    p.Transparency=0.52; p.Parent=workspace
    local sb=Instance.new("SelectionBox")
    sb.Color3=C_PREVIEW; sb.LineThickness=0.07; sb.SurfaceTransparency=1
    sb.Adornee=p; sb.Parent=p
    prevPart=p; prevPlaced=false
    prevFollow=RUN.RenderStepped:Connect(function()
        if not (prevPart and prevPart.Parent) then
            prevFollow:Disconnect(); prevFollow=nil; return
        end
        prevPart.CFrame = prevPart.CFrame:Lerp(groundCF(prevPart.Size.Y/2),0.22)
    end)
end

local function placePrev()
    if not (prevPart and prevPart.Parent and not prevPlaced) then return end
    if prevFollow then prevFollow:Disconnect(); prevFollow=nil end
    prevPart.CFrame = groundCF(prevPart.Size.Y/2)
    prevPart.Color  = C_PLACED
    local sb = prevPart:FindFirstChildOfClass("SelectionBox")
    if sb then sb.Color3 = C_PLACED end
    prevPlaced = true
end

-- ════════════════════════════════════════════════════
-- NOCLIP
-- ════════════════════════════════════════════════════
local _noclipConn = nil
local function charNoclip(on)
    if _noclipConn then _noclipConn:Disconnect(); _noclipConn=nil end
    local char = plr.Character; if not char then return end
    if on then
        _noclipConn = RUN.Stepped:Connect(function()
            local c = plr.Character; if not c then return end
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end)
    else
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=true end
        end
    end
end

local function itemNoclip(model, on)
    pcall(function()
        for _, p in ipairs(model:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = not on end
        end
    end)
end

-- ════════════════════════════════════════════════════
-- SERVER-SIDE PLACEMENT ENGINE
-- Mirrors Item Tab (Vanilla3) exactly:
--   1. Unanchor item so it's a physics object the server can give us
--   2. Enable noclip on item + character
--   3. Teleport character beside item
--   4. Fire ClientIsDragging(model) × 3, then loop until ReceiveAge==0
--   5. model:PivotTo(targetCF)   ← replicates because we own it
--   6. Anchor item in place, disable noclip on item
--   7. Release
-- ════════════════════════════════════════════════════
local _remote = nil
local function getDrag()
    if _remote then return _remote end
    local i = RS2:FindFirstChild("Interaction")
    _remote  = i and i:FindFirstChild("ClientIsDragging")
    return _remote
end

local function setAnchored(model, state)
    pcall(function()
        for _, p in ipairs(model:GetDescendants()) do
            if p:IsA("BasePart") then p.Anchored = state end
        end
        if model.PrimaryPart then model.PrimaryPart.Anchored = state end
    end)
end

local function waitOwnership(model, timeout)
    local deadline = tick() + (timeout or 4)
    local remote   = getDrag()
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
    local mp     = mainPart(model)
    local remote = getDrag()
    if not mp then return end

    setAnchored(model, false)
    itemNoclip(model, true)
    charNoclip(true)

    -- Teleport character beside item
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = CFrame.new(mp.Position) * CFrame.new(0, 2, 4) end

    -- Initial ownership bursts
    if remote then
        for _ = 1, 3 do
            pcall(remote.FireServer, remote, model)
            task.wait(0.05)
        end
    end
    waitOwnership(model, 3)

    -- Move — replicates server-side because ReceiveAge == 0
    pcall(function()
        if not model.PrimaryPart then model.PrimaryPart = mp end
        model:PivotTo(targetCF)
    end)

    task.wait(0.08)   -- let position reach server

    setAnchored(model, true)
    itemNoclip(model, false)
    task.wait(0.05)   -- let anchor replicate

    if remote then pcall(remote.FireServer, remote, nil) end
end

-- ════════════════════════════════════════════════════
-- UI HELPERS
-- ════════════════════════════════════════════════════
local pageList = sorterPage:FindFirstChildOfClass("UIListLayout")
if pageList then pageList.Padding = UDim.new(0,8) end

local function uSep()
    local f = Instance.new("Frame", sorterPage)
    f.Size=UDim2.new(1,0,0,1); f.BackgroundColor3=SEP_COL; f.BorderSizePixel=0
end

local function uSection(txt)
    local f = Instance.new("Frame", sorterPage)
    f.Size=UDim2.new(1,0,0,22); f.BackgroundTransparency=1
    local l = Instance.new("TextLabel", f)
    l.Size=UDim2.new(1,-4,1,0); l.Position=UDim2.new(0,4,0,0)
    l.BackgroundTransparency=1; l.Font=Enum.Font.GothamBold; l.TextSize=10
    l.TextColor3=SEC_TEXT; l.TextXAlignment=Enum.TextXAlignment.Left
    l.Text="  "..string.upper(txt)
end

local function uHint(txt)
    local l = Instance.new("TextLabel", sorterPage)
    l.Size=UDim2.new(1,0,0,18); l.BackgroundTransparency=1
    l.Font=Enum.Font.Gotham; l.TextSize=11
    l.TextColor3=Color3.fromRGB(80,80,100)
    l.TextXAlignment=Enum.TextXAlignment.Left; l.TextWrapped=true
    l.Text="  "..txt
end

local function uButton(txt, col, cb)
    col = col or BTN_COLOR
    local b = Instance.new("TextButton", sorterPage)
    b.Size=UDim2.new(1,0,0,34); b.BackgroundColor3=col
    b.Text=txt; b.Font=Enum.Font.GothamSemibold; b.TextSize=13
    b.TextColor3=THEME_TEXT; b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
    local h=Color3.fromRGB(
        math.min(col.R*255+22,255)/255,
        math.min(col.G*255+10,255)/255,
        math.min(col.B*255+22,255)/255)
    b.MouseEnter:Connect(function() TS:Create(b,TweenInfo.new(0.15),{BackgroundColor3=h}):Play() end)
    b.MouseLeave:Connect(function() TS:Create(b,TweenInfo.new(0.15),{BackgroundColor3=col}):Play() end)
    if cb then b.MouseButton1Click:Connect(cb) end
    return b
end

local function uToggle(txt, def, cb)
    local fr = Instance.new("Frame", sorterPage)
    fr.Size=UDim2.new(1,0,0,36); fr.BackgroundColor3=C_DARK; fr.BorderSizePixel=0
    Instance.new("UICorner",fr).CornerRadius=UDim.new(0,8)
    local lbl=Instance.new("TextLabel",fr)
    lbl.Size=UDim2.new(1,-54,1,0); lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=txt
    lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=13
    lbl.TextColor3=THEME_TEXT; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local tb=Instance.new("TextButton",fr)
    tb.Size=UDim2.new(0,36,0,20); tb.Position=UDim2.new(1,-46,0.5,-10)
    tb.BackgroundColor3=def and Color3.fromRGB(80,160,80) or Color3.fromRGB(38,38,45)
    tb.Text=""; tb.BorderSizePixel=0
    Instance.new("UICorner",tb).CornerRadius=UDim.new(1,0)
    local dot=Instance.new("Frame",tb)
    dot.Size=UDim2.new(0,14,0,14)
    dot.Position=UDim2.new(0,def and 20 or 2,0.5,-7)
    dot.BackgroundColor3=Color3.fromRGB(255,255,255); dot.BorderSizePixel=0
    Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
    local on=def
    if cb then task.defer(function() cb(on) end) end
    local function setOn(v)
        on=v
        TS:Create(tb,TweenInfo.new(0.18),{BackgroundColor3=on and Color3.fromRGB(80,160,80) or Color3.fromRGB(38,38,45)}):Play()
        TS:Create(dot,TweenInfo.new(0.18),{Position=UDim2.new(0,on and 20 or 2,0.5,-7)}):Play()
    end
    tb.MouseButton1Click:Connect(function() on=not on; setOn(on); if cb then cb(on) end end)
    return fr, function(v) if v~=on then setOn(v) end end
end

local function uSlider(txt, minV, maxV, defV, cb)
    local fr=Instance.new("Frame",sorterPage)
    fr.Size=UDim2.new(1,0,0,54); fr.BackgroundColor3=C_DARK; fr.BorderSizePixel=0
    Instance.new("UICorner",fr).CornerRadius=UDim.new(0,8)
    local row=Instance.new("Frame",fr)
    row.Size=UDim2.new(1,-16,0,22); row.Position=UDim2.new(0,8,0,7); row.BackgroundTransparency=1
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.72,0,1,0); lbl.BackgroundTransparency=1
    lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=13
    lbl.TextColor3=THEME_TEXT; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=txt
    local val=Instance.new("TextLabel",row)
    val.Size=UDim2.new(0.28,0,1,0); val.Position=UDim2.new(0.72,0,0,0)
    val.BackgroundTransparency=1; val.Font=Enum.Font.GothamBold; val.TextSize=13
    val.TextColor3=Color3.fromRGB(160,160,175); val.TextXAlignment=Enum.TextXAlignment.Right
    val.Text=tostring(defV)
    local track=Instance.new("Frame",fr)
    track.Size=UDim2.new(1,-16,0,5); track.Position=UDim2.new(0,8,0,38)
    track.BackgroundColor3=Color3.fromRGB(32,32,38); track.BorderSizePixel=0
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new((defV-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3=ACCENT; fill.BorderSizePixel=0
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("TextButton",track)
    knob.Size=UDim2.new(0,14,0,14); knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new((defV-minV)/(maxV-minV),0,0.5,0)
    knob.BackgroundColor3=Color3.fromRGB(210,210,220); knob.Text=""; knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local drag=false
    local function upd(ax)
        local r=math.clamp((ax-track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1),0,1)
        local v=math.round(minV+r*(maxV-minV))
        fill.Size=UDim2.new(r,0,1,0); knob.Position=UDim2.new(r,0,0.5,0)
        val.Text=tostring(v); if cb then cb(v) end
    end
    knob.MouseButton1Down:Connect(function() drag=true end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; upd(i.Position.X) end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

local AXIS_COLS={X=Color3.fromRGB(220,70,70),Y=Color3.fromRGB(70,200,70),Z=Color3.fromRGB(70,120,255)}
local function uAxisSlider(lbl, axis, minV, maxV, defV, cb)
    local ac=AXIS_COLS[axis] or THEME_TEXT
    local fr=Instance.new("Frame",sorterPage)
    fr.Size=UDim2.new(1,0,0,54); fr.BackgroundColor3=C_DARK; fr.BorderSizePixel=0
    Instance.new("UICorner",fr).CornerRadius=UDim.new(0,8)
    local axL=Instance.new("TextLabel",fr)
    axL.Size=UDim2.new(0,18,0,22); axL.Position=UDim2.new(0,8,0,7)
    axL.BackgroundTransparency=1; axL.Font=Enum.Font.GothamBold
    axL.TextSize=14; axL.TextColor3=ac; axL.Text=axis
    local txtL=Instance.new("TextLabel",fr)
    txtL.Size=UDim2.new(0.6,0,0,22); txtL.Position=UDim2.new(0,28,0,7)
    txtL.BackgroundTransparency=1; txtL.Font=Enum.Font.GothamSemibold
    txtL.TextSize=12; txtL.TextColor3=THEME_TEXT
    txtL.TextXAlignment=Enum.TextXAlignment.Left; txtL.Text=lbl
    local valL=Instance.new("TextLabel",fr)
    valL.Size=UDim2.new(0.25,0,0,22); valL.Position=UDim2.new(0.75,-8,0,7)
    valL.BackgroundTransparency=1; valL.Font=Enum.Font.GothamBold
    valL.TextSize=13; valL.TextColor3=ac
    valL.TextXAlignment=Enum.TextXAlignment.Right; valL.Text=tostring(defV)
    local track=Instance.new("Frame",fr)
    track.Size=UDim2.new(1,-16,0,5); track.Position=UDim2.new(0,8,0,38)
    track.BackgroundColor3=Color3.fromRGB(32,32,38); track.BorderSizePixel=0
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new((defV-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3=ac; fill.BorderSizePixel=0
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("TextButton",track)
    knob.Size=UDim2.new(0,14,0,14); knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new((defV-minV)/(maxV-minV),0,0.5,0)
    knob.BackgroundColor3=Color3.fromRGB(210,210,220); knob.Text=""; knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local drag=false; local cur=defV
    local function upd(ax2)
        local r=math.clamp((ax2-track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1),0,1)
        local v=math.round(minV+r*(maxV-minV))
        if v==cur then return end; cur=v
        fill.Size=UDim2.new(r,0,1,0); knob.Position=UDim2.new(r,0,0.5,0)
        valL.Text=tostring(v); if cb then cb(v) end
    end
    knob.MouseButton1Down:Connect(function() drag=true end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; upd(i.Position.X) end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

-- ════════════════════════════════════════════════════
-- STATUS CARD
-- ════════════════════════════════════════════════════
local statusLbl
do
    local card=Instance.new("Frame",sorterPage)
    card.Size=UDim2.new(1,0,0,44); card.BackgroundColor3=C_CARD; card.BorderSizePixel=0
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,8)
    local sk=Instance.new("UIStroke",card)
    sk.Color=Color3.fromRGB(255,180,0); sk.Thickness=1; sk.Transparency=0.55
    local l=Instance.new("TextLabel",card)
    l.Size=UDim2.new(1,-16,1,0); l.Position=UDim2.new(0,8,0,0)
    l.BackgroundTransparency=1; l.Font=Enum.Font.GothamSemibold; l.TextSize=12
    l.TextColor3=Color3.fromRGB(255,210,100)
    l.TextXAlignment=Enum.TextXAlignment.Left; l.TextWrapped=true
    l.Text="Select items to get started."
    statusLbl=l
end
local function setStatus(msg,col)
    statusLbl.Text=msg; statusLbl.TextColor3=col or Color3.fromRGB(255,210,100)
end

-- ════════════════════════════════════════════════════
-- PROGRESS BAR
-- ════════════════════════════════════════════════════
local pbCont, pbFill, pbLbl
do
    local pb=Instance.new("Frame")
    pb.Size=UDim2.new(1,0,0,44); pb.BackgroundColor3=Color3.fromRGB(18,18,24)
    pb.BorderSizePixel=0; pb.Visible=false
    Instance.new("UICorner",pb).CornerRadius=UDim.new(0,8)
    local sk=Instance.new("UIStroke",pb)
    sk.Color=Color3.fromRGB(60,60,80); sk.Thickness=1; sk.Transparency=0.5
    local lbl=Instance.new("TextLabel",pb)
    lbl.Size=UDim2.new(1,-12,0,16); lbl.Position=UDim2.new(0,6,0,4)
    lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=11
    lbl.TextColor3=THEME_TEXT; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text="Ready."
    local track=Instance.new("Frame",pb)
    track.Size=UDim2.new(1,-12,0,12); track.Position=UDim2.new(0,6,0,26)
    track.BackgroundColor3=Color3.fromRGB(30,30,42); track.BorderSizePixel=0
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local fl=Instance.new("Frame",track)
    fl.Size=UDim2.new(0,0,1,0); fl.BackgroundColor3=Color3.fromRGB(255,175,55)
    fl.BorderSizePixel=0
    Instance.new("UICorner",fl).CornerRadius=UDim.new(1,0)
    pbCont=pb; pbFill=fl; pbLbl=lbl
end

local function setPb(frac, txt, col)
    TS:Create(pbFill,TweenInfo.new(0.18,Enum.EasingStyle.Quad),
        {Size=UDim2.new(math.clamp(frac,0,1),0,1,0)}):Play()
    if col  then pbFill.BackgroundColor3=col end
    if txt  then pbLbl.Text=txt end
end

local function hidePb(delay)
    task.delay(delay or 2, function()
        if not pbCont then return end
        TS:Create(pbCont, TweenInfo.new(0.4),{BackgroundTransparency=1}):Play()
        TS:Create(pbFill, TweenInfo.new(0.4),{BackgroundTransparency=1}):Play()
        TS:Create(pbLbl,  TweenInfo.new(0.4),{TextTransparency=1}):Play()
        task.delay(0.45,function()
            if not pbCont then return end
            pbCont.Visible=false; pbCont.BackgroundTransparency=0
            pbFill.BackgroundTransparency=0
            pbFill.BackgroundColor3=Color3.fromRGB(255,175,55)
            pbFill.Size=UDim2.new(0,0,1,0); pbLbl.TextTransparency=0
        end)
    end)
end

-- ════════════════════════════════════════════════════
-- STATUS REFRESH
-- ════════════════════════════════════════════════════
local startBtn, stopBtn  -- forward refs

local function refresh()
    local n=selCount()
    if sorting then
        setStatus("⏳  Sorting in progress…", Color3.fromRGB(140,220,255))
    elseif stopped then
        setStatus("⏸  Paused — Resume to continue.", Color3.fromRGB(255,210,80))
    elseif n==0 then
        setStatus("👆  Select items via Click, Lasso, or Group.")
    elseif prevFollow then
        setStatus("🖱  Preview following — click to place.", Color3.fromRGB(140,220,255))
    elseif prevPlaced then
        setStatus("✅  "..n.." item(s) ready. Hit Start!", Color3.fromRGB(100,220,120))
    elseif prevPart then
        setStatus("📦  Preview placed. Hit Start Sorting!")
    else
        setStatus("📦  "..n.." selected. Generate a Preview.")
    end

    if startBtn then
        local ok=(n>0 or stopped) and (prevPlaced or stopped) and not sorting
        startBtn.BackgroundColor3=ok and C_GREEN or Color3.fromRGB(28,28,38)
        startBtn.TextColor3      =ok and THEME_TEXT or Color3.fromRGB(72,72,82)
        startBtn.Text=stopped and "▶  Resume Sorting" or "▶  Start Sorting"
    end
    if stopBtn then
        stopBtn.BackgroundColor3=sorting and Color3.fromRGB(100,60,20) or Color3.fromRGB(28,28,38)
        stopBtn.TextColor3      =sorting and Color3.fromRGB(255,190,80) or Color3.fromRGB(72,72,82)
    end
end

-- ════════════════════════════════════════════════════
-- SORT LOOP
-- ════════════════════════════════════════════════════
local function runSort(slots, startI, total, doneStart)
    local done=doneStart
    sortThread=task.spawn(function()
        for i=startI, total do
            if not sorting then sortIdx=i; break end
            local slot=slots[i]
            if not (slot.model and slot.model.Parent) then
                done=done+1; sortDone=done; sortIdx=i+1
                setPb(done/total,"Skipped "..done.."/"..total)
                continue
            end
            setPb(done/total,"Placing "..(done+1).." / "..total)
            placeItem(slot.model, slot.cf)
            if not sorting then sortIdx=i; break end
            unhighlight(slot.model)
            done=done+1; sortDone=done; sortIdx=i+1
            setPb(done/total,"Sorted "..done.." / "..total)
            task.wait(itemDelay)
        end

        charNoclip(false)
        sorting=false; sortThread=nil

        if done>=total then
            stopped=false; sortSlots=nil
            setPb(1,"✔  Done! "..done.." items placed.",Color3.fromRGB(90,220,110))
            destroyPreview(); clearAll(); hidePb(3)
        else
            stopped=true
            setPb(done/math.max(total,1),"⏸  Stopped at "..done.." / "..total)
        end
        refresh()
    end)
end

-- ════════════════════════════════════════════════════
-- BUILD UI
-- ════════════════════════════════════════════════════

uSep()

-- ── Selection ──
uSection("Selection Mode")
uToggle("Click Select", false, function(v)
    modeClick=v; if v then modeLasso=false; modeGroup=false end
end)
uToggle("Lasso Select", false, function(v)
    modeLasso=v; if v then modeClick=false; modeGroup=false end
end)
uToggle("Group Select", false, function(v)
    modeGroup=v; if v then modeClick=false; modeLasso=false end
end)
uHint("Click: toggle · Lasso: drag box · Group: all of same type")
uButton("Deselect All", BTN_COLOR, function() clearAll(); refresh() end)

uSep()

-- ── Speed ──
uSection("Sort Speed")
uSlider("Delay per item (×0.1s)", 1, 20, 3, function(v)
    itemDelay=v/10
    if _G.VH then _G.VH.tpItemSpeed=itemDelay end
end)

uSep()

-- ── Grid ──
uSection("Sort Grid")
uAxisSlider("Columns (X)",          "X", 1, 12, 5, function(v) gridCols   =v end)
uAxisSlider("Layers (Y, vertical)", "Y", 1,  5, 1, function(v) gridLayers =v end)
uAxisSlider("Rows (Z, 0 = auto)",   "Z", 0, 12, 0, function(v) gridRows   =v end)
uHint("Fills columns → rows → layers. 0 rows = auto-calculated.")

uSep()

-- ── Preview ──
uSection("Preview")

local prevRow=Instance.new("Frame",sorterPage)
prevRow.Size=UDim2.new(1,0,0,34); prevRow.BackgroundTransparency=1

local genBtn=Instance.new("TextButton",prevRow)
genBtn.Size=UDim2.new(0.60,-4,1,0); genBtn.BackgroundColor3=Color3.fromRGB(28,55,110)
genBtn.Text="Generate Preview"; genBtn.Font=Enum.Font.GothamSemibold; genBtn.TextSize=13
genBtn.TextColor3=THEME_TEXT; genBtn.BorderSizePixel=0
Instance.new("UICorner",genBtn).CornerRadius=UDim.new(0,8)

local clrBtn=Instance.new("TextButton",prevRow)
clrBtn.Size=UDim2.new(0.40,-4,1,0); clrBtn.Position=UDim2.new(0.60,4,0,0)
clrBtn.BackgroundColor3=BTN_COLOR; clrBtn.Text="Clear Preview"
clrBtn.Font=Enum.Font.GothamSemibold; clrBtn.TextSize=12
clrBtn.TextColor3=THEME_TEXT; clrBtn.BorderSizePixel=0
Instance.new("UICorner",clrBtn).CornerRadius=UDim.new(0,8)

for _,b in {genBtn,clrBtn} do
    local base=b.BackgroundColor3
    local hov=Color3.fromRGB(
        math.min(base.R*255+20,255)/255,
        math.min(base.G*255+10,255)/255,
        math.min(base.B*255+20,255)/255)
    b.MouseEnter:Connect(function() TS:Create(b,TweenInfo.new(0.14),{BackgroundColor3=hov}):Play() end)
    b.MouseLeave:Connect(function() TS:Create(b,TweenInfo.new(0.14),{BackgroundColor3=base}):Play() end)
end

genBtn.MouseButton1Click:Connect(function()
    if selCount()==0 then setStatus("⚠  Select items first!"); return end
    local sX,sY,sZ=previewDims()
    buildPreview(sX,sY,sZ)
    refresh()
end)
clrBtn.MouseButton1Click:Connect(function() destroyPreview(); refresh() end)

uHint("Preview follows cursor — left-click to lock its position.")

uSep()

-- ── Actions ──
uSection("Actions")

startBtn=Instance.new("TextButton",sorterPage)
startBtn.Size=UDim2.new(1,0,0,36); startBtn.BackgroundColor3=Color3.fromRGB(28,28,38)
startBtn.Text="▶  Start Sorting"; startBtn.Font=Enum.Font.GothamBold
startBtn.TextSize=14; startBtn.TextColor3=Color3.fromRGB(72,72,82); startBtn.BorderSizePixel=0
Instance.new("UICorner",startBtn).CornerRadius=UDim.new(0,8)

local actRow=Instance.new("Frame",sorterPage)
actRow.Size=UDim2.new(1,0,0,32); actRow.BackgroundTransparency=1

stopBtn=Instance.new("TextButton",actRow)
stopBtn.Size=UDim2.new(0.48,-2,1,0)
stopBtn.BackgroundColor3=Color3.fromRGB(28,28,38)
stopBtn.Text="⏹  Stop"; stopBtn.Font=Enum.Font.GothamBold
stopBtn.TextSize=13; stopBtn.TextColor3=Color3.fromRGB(72,72,82); stopBtn.BorderSizePixel=0
Instance.new("UICorner",stopBtn).CornerRadius=UDim.new(0,8)

local cancelBtn=Instance.new("TextButton",actRow)
cancelBtn.Size=UDim2.new(0.52,-2,1,0); cancelBtn.Position=UDim2.new(0.48,2,0,0)
cancelBtn.BackgroundColor3=Color3.fromRGB(60,16,16)
cancelBtn.Text="✕  Cancel & Clear"; cancelBtn.Font=Enum.Font.GothamBold
cancelBtn.TextSize=12; cancelBtn.TextColor3=Color3.fromRGB(200,100,100); cancelBtn.BorderSizePixel=0
Instance.new("UICorner",cancelBtn).CornerRadius=UDim.new(0,8)

pbCont.Parent=sorterPage

-- ════════════════════════════════════════════════════
-- BUTTON LOGIC
-- ════════════════════════════════════════════════════
startBtn.MouseButton1Click:Connect(function()
    if sorting then return end
    -- Resume
    if stopped and sortSlots then
        stopped=false; sorting=true
        pbCont.Visible=true; pbFill.BackgroundColor3=Color3.fromRGB(255,175,55)
        refresh()
        runSort(sortSlots, sortIdx, sortTotal, sortDone)
        return
    end
    if not (prevPlaced and prevPart and prevPart.Parent) then
        setStatus("⚠  Generate + place a preview first!"); return
    end
    if selCount()==0 then setStatus("⚠  No items selected!"); return end

    local items={}
    for m in pairs(sel) do if m and m.Parent then items[#items+1]=m end end
    if #items==0 then return end

    -- Anchor = bottom-left-front corner of preview box
    local anchorCF = prevPart.CFrame
        * CFrame.new(-prevPart.Size.X/2, -prevPart.Size.Y/2, -prevPart.Size.Z/2)

    sortSlots=calcSlots(items, anchorCF, gridCols, gridLayers, gridRows)
    sortTotal=#sortSlots; sortDone=0; sortIdx=1
    stopped=false; sorting=true

    pbCont.Visible=true; pbFill.Size=UDim2.new(0,0,1,0)
    pbFill.BackgroundColor3=Color3.fromRGB(255,175,55); pbLbl.Text="Starting…"
    refresh()
    runSort(sortSlots,1,sortTotal,0)
end)

stopBtn.MouseButton1Click:Connect(function()
    if not sorting then return end
    sorting=false; pbLbl.Text="⏸  Stopping…"; refresh()
end)

cancelBtn.MouseButton1Click:Connect(function()
    sorting=false; stopped=false
    sortSlots=nil; sortIdx=1; sortTotal=0; sortDone=0
    if sortThread then pcall(task.cancel,sortThread); sortThread=nil end
    charNoclip(false)
    destroyPreview(); clearAll()
    pbLbl.Text="Cancelled."; hidePb(1)
    refresh()
end)

-- ════════════════════════════════════════════════════
-- MOUSE INPUT
-- ════════════════════════════════════════════════════
local inputConn=UIS.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    if modeLasso then lassoStart(mouse.X, mouse.Y) end
end)

local upConn=mouse.Button1Up:Connect(function()
    if modeLasso and lassoActive then lassoEnd(); refresh(); return end
    if prevPart and prevPart.Parent and not prevPlaced then placePrev(); refresh(); return end
    local target=mouse.Target
    if modeClick then
        local m=modelOf(target)
        if m then
            if sel[m] then unhighlight(m) else highlight(m) end
            refresh()
        end
    elseif modeGroup then
        local m=modelOf(target)
        if m then
            local name=itemName(m)
            for _,o in ipairs(allSortables()) do
                if itemName(o)==name then highlight(o) end
            end
            refresh()
        end
    end
end)

-- ════════════════════════════════════════════════════
-- CLEANUP
-- ════════════════════════════════════════════════════
table.insert(cleanupTasks, function()
    sorting=false; stopped=false
    sortSlots=nil; sortIdx=1; sortTotal=0; sortDone=0
    if sortThread    then pcall(task.cancel,sortThread); sortThread=nil end
    if prevFollow    then prevFollow:Disconnect();       prevFollow=nil end
    if lassoConn     then lassoConn:Disconnect();        lassoConn=nil end
    if _noclipConn   then _noclipConn:Disconnect();      _noclipConn=nil end
    inputConn:Disconnect(); upConn:Disconnect()
    if lassoFrame and lassoFrame.Parent then lassoFrame:Destroy() end
    destroyPreview(); clearAll()
end)

refresh()
print("[VanillaHub] Vanilla4 (Sorter v5) loaded")
