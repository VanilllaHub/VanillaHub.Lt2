-- ════════════════════════════════════════════════════════════════════════════════
-- VANILLA 8 — Wire Art Tab
-- Requires Vanilla1 (_G.VH) to be loaded first.
-- ════════════════════════════════════════════════════════════════════════════════

if not _G.VH then
    warn("[VanillaHub] Vanilla8: _G.VH not found. Execute Vanilla1 first.")
    return
end

local VH           = _G.VH
local TweenService = VH.TweenService
local Players      = VH.Players
local player       = VH.player
local cleanupTasks = VH.cleanupTasks

local RS = game:GetService("ReplicatedStorage")

local wirePage = VH.pages["Wire ArtTab"]
if not wirePage then
    warn("[VanillaHub] Vanilla8: Wire ArtTab page not found.")
    return
end

-- ════════════════════════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════════════════════════
local parsedPoints = {}
local chunks       = {}
local buildRunning = false
local buildThread  = nil
local stopFlag     = false

-- ════════════════════════════════════════════════════════════════════════════════
-- PARSE HELPERS
-- ════════════════════════════════════════════════════════════════════════════════
local function parseVector3Input(raw)
    local pts = {}
    for x, y, z in raw:gmatch("Vector3%.new%s*%(%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*%)") do
        local px, py, pz = tonumber(x), tonumber(y), tonumber(z)
        if px and py and pz then
            table.insert(pts, Vector3.new(px, py, pz))
        end
    end
    if #pts == 0 then
        for line in raw:gmatch("[^\n]+") do
            local nums = {}
            for n in line:gmatch("[%-%.%deE]+") do table.insert(nums, tonumber(n)) end
            if #nums >= 3 and nums[1] and nums[2] and nums[3] then
                table.insert(pts, Vector3.new(nums[1], nums[2], nums[3]))
            end
        end
    end
    return pts
end

local function chunkByLength(pts, maxLen)
    local out = {}
    local i = 1
    while i <= #pts do
        local c = { pts[i] }
        local len = 0
        local j = i + 1
        while j <= #pts do
            local seg = (pts[j] - pts[j-1]).Magnitude
            if len + seg > maxLen and #c >= 2 then break end
            len = len + seg
            table.insert(c, pts[j])
            j = j + 1
        end
        table.insert(out, c)
        i = j - 1
        if j > #pts then break end
    end
    return out
end

local function applyOffset(pts, tx, ty, tz)
    local sx, sy, sz = 0, 0, 0
    for _, v in ipairs(pts) do sx = sx + v.X; sy = sy + v.Y; sz = sz + v.Z end
    local n = #pts
    local cx, cy, cz = sx / n, sy / n, sz / n
    local out = {}
    for _, v in ipairs(pts) do
        table.insert(out, Vector3.new(
            math.floor((v.X - cx + tx) * 10000 + 0.5) / 10000,
            math.floor((v.Y - cy + ty) * 10000 + 0.5) / 10000,
            math.floor((v.Z - cz + tz) * 10000 + 0.5) / 10000
        ))
    end
    return out
end

-- ════════════════════════════════════════════════════════════════════════════════
-- BUY / PLACE LOGIC
-- ════════════════════════════════════════════════════════════════════════════════
local DRAG_ITERS     = 50
local RETURN_TIMEOUT = 10

local function isnetworkowner(part)
    return part.ReceiveAge == 0
end

local function getItem(name)
    for _, store in next, workspace.Stores:GetChildren() do
        if store.Name == "ShopItems" then
            for _, v in next, store:GetChildren() do
                local box = v:FindFirstChild("BoxItemName")
                local own = v:FindFirstChild("Owner")
                if box and box.Value == name and own and own.Value == nil then
                    return v
                end
            end
        end
    end
    return nil
end

local function getCounter(main)
    local best, bd = nil, math.huge
    for _, store in next, workspace.Stores:GetChildren() do
        for _, c in next, store:GetChildren() do
            if c.Name:lower() == "counter" then
                local d = (main.CFrame.p - c.CFrame.p).Magnitude
                if d < bd then bd = d; best = c end
            end
        end
    end
    return best
end

local function buyWire(wireName, base)
    local item = getItem(wireName)
    if not item then warn("[VanillaHub/Wire] Item not found: " .. wireName); return false end
    local main = item:FindFirstChild("Main")
    if not main then warn("[VanillaHub/Wire] No Main part"); return false end

    player.Character.HumanoidRootPart.CFrame = main.CFrame + Vector3.new(5, 0, 5)
    task.wait(0.09)
    local counter = getCounter(main)
    if not counter then warn("[VanillaHub/Wire] No counter found"); return false end

    for _ = 1, DRAG_ITERS do
        RS.Interaction.ClientIsDragging:FireServer(item)
        main.CFrame = counter.CFrame + Vector3.new(0, main.Size.Y, 0.5)
        task.wait()
    end
    task.wait(0.08)
    player.Character.HumanoidRootPart.CFrame = counter.CFrame + Vector3.new(5, 0, 5)
    task.wait(0.08)

    local args = {Character = "Lincoln", Name = "Lincoln", ID = 14, Dialog = "Dialog"}
    RS:FindFirstChild("PlayerChatted", true):InvokeServer(args, "Initiate")
    task.wait(0.04)
    RS:FindFirstChild("PlayerChatted", true):InvokeServer(args, "ConfirmPurchase")
    task.wait(0.03)
    RS:FindFirstChild("PlayerChatted", true):InvokeServer(args, "EndChat")
    task.wait(0.04)
    mousemoveabs(762, 151)
    task.wait(0.01)

    local t0, done = tick(), false
    repeat
        if tick() - t0 > RETURN_TIMEOUT then warn("[VanillaHub/Wire] Return timeout"); break end
        pcall(function()
            player.Character.HumanoidRootPart.CFrame = main.CFrame + Vector3.new(5, 0, 5)
            RS.Interaction.ClientIsDragging:FireServer(item)
            task.wait()
            if isnetworkowner(main) then
                RS.Interaction.ClientIsDragging:FireServer(item)
                main.CFrame = CFrame.new(base.p)
                done = true
            end
        end)
        task.wait(0.05)
    until done
    player.Character.HumanoidRootPart.CFrame = base + Vector3.new(5, 1, 0)
    return done
end

local function placeWire(chunkData, wireName, orderTag, permId)
    mousemoveabs(619, 84);  task.wait(0.05)
    mousemoveabs(400, 149); task.wait(0.08)
    for _ = 1, 6 do
        RS:FindFirstChild("ClientGetUserPermissions", true):InvokeServer(
            permId, {[1]="PlaceStructure", [2]="MoveStructure", [3]="Destroy"})
        task.wait(0.08)
    end
    task.wait(0.08)
    RS:FindFirstChild("ClientPlacedWire", true):FireServer(
        RS:FindFirstChild(wireName, true)    or workspace:FindFirstChild(wireName, true),
        chunkData,
        RS:FindFirstChild(orderTag, true)    or workspace:FindFirstChild(orderTag, true),
        RS:FindFirstChild("Box Purchased by " .. orderTag, true)
            or workspace:FindFirstChild("Box Purchased by " .. orderTag, true),
        true
    )
    task.wait(0.65)
    mousemoveabs(735, 84); task.wait(0.15)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- THEME
-- ════════════════════════════════════════════════════════════════════════════════
local C = {
    CARD       = Color3.fromRGB(14,  14,  14),
    CARD2      = Color3.fromRGB(20,  20,  20),
    BORDER     = Color3.fromRGB(55,  55,  55),
    TEXT       = Color3.fromRGB(210, 210, 210),
    TEXT_MID   = Color3.fromRGB(130, 130, 130),
    TEXT_DIM   = Color3.fromRGB(75,  75,  75),
    BTN        = Color3.fromRGB(14,  14,  14),
    BTN_HV     = Color3.fromRGB(32,  32,  32),
    SEP        = Color3.fromRGB(50,  50,  50),
    INPUT_BG   = Color3.fromRGB(18,  18,  18),
    PROG_TRACK = Color3.fromRGB(30,  30,  30),
    PROG_FILL  = Color3.fromRGB(255, 255, 255),
    DOT_IDLE   = Color3.fromRGB(70,  70,  70),
    DOT_ACTIVE = Color3.fromRGB(200, 200, 200),
}

-- ════════════════════════════════════════════════════════════════════════════════
-- UI HELPERS
-- ════════════════════════════════════════════════════════════════════════════════

local function corner(p, r)
    Instance.new("UICorner", p).CornerRadius = UDim.new(0, r or 8)
end

local function addStroke(p, col, thick, trans)
    local s = Instance.new("UIStroke", p)
    s.Color        = col   or C.BORDER
    s.Thickness    = thick or 1
    s.Transparency = trans or 0.4
    return s
end

-- Section header
local function wSectionLabel(text)
    local w = Instance.new("Frame", wirePage)
    w.Size             = UDim2.new(1, 0, 0, 24)
    w.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", w)
    lbl.Size              = UDim2.new(1, -4, 1, 0)
    lbl.Position          = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font              = Enum.Font.GothamBold
    lbl.TextSize          = 10
    lbl.TextColor3        = C.TEXT_MID
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.Text              = "  " .. string.upper(text)
end

-- Separator
local function wSep()
    local s = Instance.new("Frame", wirePage)
    s.Size             = UDim2.new(1, 0, 0, 1)
    s.BackgroundColor3 = C.SEP
    s.BorderSizePixel  = 0
end

-- Card container (auto-sizes to content)
local function wCard()
    local f = Instance.new("Frame", wirePage)
    f.Size             = UDim2.new(1, 0, 0, 0)
    f.AutomaticSize    = Enum.AutomaticSize.Y
    f.BackgroundColor3 = C.CARD2
    f.BorderSizePixel  = 0
    corner(f, 8)
    addStroke(f)
    local pad = Instance.new("UIPadding", f)
    pad.PaddingLeft   = UDim.new(0, 12)
    pad.PaddingRight  = UDim.new(0, 12)
    pad.PaddingTop    = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    local list = Instance.new("UIListLayout", f)
    list.Padding   = UDim.new(0, 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    return f
end

-- Full-width button
local function wButton(parent, text, cb)
    local btn = Instance.new("TextButton", parent)
    btn.Size             = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = C.BTN
    btn.BorderSizePixel  = 0
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.TextColor3       = C.TEXT
    btn.Text             = text
    btn.AutoButtonColor  = false
    corner(btn, 8)
    addStroke(btn)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = C.BTN_HV}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = C.BTN}):Play()
    end)
    if cb then btn.MouseButton1Click:Connect(function() task.spawn(cb) end) end
    return btn
end

-- Half-width button row
local function wButtonRow(parent, leftText, rightText, leftCb, rightCb)
    local row = Instance.new("Frame", parent)
    row.Size                   = UDim2.new(1, 0, 0, 34)
    row.BackgroundTransparency = 1
    local rl = Instance.new("UIListLayout", row)
    rl.FillDirection = Enum.FillDirection.Horizontal
    rl.Padding       = UDim.new(0, 6)
    rl.SortOrder     = Enum.SortOrder.LayoutOrder

    local function half(text, order, cb)
        local btn = Instance.new("TextButton", row)
        btn.Size             = UDim2.new(0.5, -3, 1, 0)
        btn.BackgroundColor3 = C.BTN
        btn.BorderSizePixel  = 0
        btn.Font             = Enum.Font.GothamSemibold
        btn.TextSize         = 12
        btn.TextColor3       = C.TEXT
        btn.Text             = text
        btn.LayoutOrder      = order
        btn.AutoButtonColor  = false
        corner(btn, 8)
        addStroke(btn)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = C.BTN_HV}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = C.BTN}):Play()
        end)
        if cb then btn.MouseButton1Click:Connect(function() task.spawn(cb) end) end
        return btn
    end

    local leftBtn  = half(leftText,  1, leftCb)
    local rightBtn = half(rightText, 2, rightCb)
    return row, leftBtn, rightBtn
end

-- Input field with label above it
local function wInputField(parent, labelText, placeholder, defaultVal)
    local wrap = Instance.new("Frame", parent)
    wrap.Size             = UDim2.new(1, 0, 0, 46)
    wrap.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", wrap)
    lbl.Size              = UDim2.new(1, 0, 0, 16)
    lbl.Position          = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font              = Enum.Font.Gotham
    lbl.TextSize          = 11
    lbl.TextColor3        = C.TEXT_MID
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.Text              = labelText

    local box = Instance.new("TextBox", wrap)
    box.Size              = UDim2.new(1, 0, 0, 28)
    box.Position          = UDim2.new(0, 0, 0, 18)
    box.BackgroundColor3  = C.INPUT_BG
    box.BorderSizePixel   = 0
    box.Font              = Enum.Font.Gotham
    box.TextSize          = 12
    box.TextColor3        = C.TEXT
    box.PlaceholderText   = placeholder or ""
    box.PlaceholderColor3 = C.TEXT_DIM
    box.Text              = defaultVal or ""
    box.ClearTextOnFocus  = false
    box.TextXAlignment    = Enum.TextXAlignment.Left
    corner(box, 6)
    local boxPad = Instance.new("UIPadding", box)
    boxPad.PaddingLeft  = UDim.new(0, 8)
    boxPad.PaddingRight = UDim.new(0, 8)
    local s = addStroke(box)
    box.Focused:Connect(function()
        TweenService:Create(s, TweenInfo.new(0.12), {
            Transparency = 0, Color = Color3.fromRGB(140, 140, 140)
        }):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(s, TweenInfo.new(0.12), {Transparency = 0.4, Color = C.BORDER}):Play()
    end)
    return box
end

-- Status bar (dot indicator + text)
local function wStatusBar(parent, defaultText)
    local bar = Instance.new("Frame", parent)
    bar.Size             = UDim2.new(1, 0, 0, 26)
    bar.BackgroundColor3 = C.CARD
    bar.BorderSizePixel  = 0
    corner(bar, 6)
    addStroke(bar)

    local dot = Instance.new("Frame", bar)
    dot.Size             = UDim2.new(0, 7, 0, 7)
    dot.Position         = UDim2.new(0, 10, 0.5, -3.5)
    dot.BackgroundColor3 = C.DOT_IDLE
    dot.BorderSizePixel  = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local lbl = Instance.new("TextLabel", bar)
    lbl.Size               = UDim2.new(1, -28, 1, 0)
    lbl.Position           = UDim2.new(0, 24, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.Gotham
    lbl.TextSize           = 11
    lbl.TextColor3         = C.TEXT_MID
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = defaultText or "Ready"

    local function setStatus(msg, active)
        lbl.Text = msg
        TweenService:Create(dot, TweenInfo.new(0.18), {
            BackgroundColor3 = active and C.DOT_ACTIVE or C.DOT_IDLE
        }):Play()
    end
    return bar, setStatus
end

-- Progress bar
local function wProgressBar(parent, labelText)
    local wrap = Instance.new("Frame", parent)
    wrap.Size             = UDim2.new(1, 0, 0, 42)
    wrap.BackgroundColor3 = C.CARD
    wrap.BorderSizePixel  = 0
    wrap.Visible          = false
    corner(wrap, 7)
    addStroke(wrap)

    local topRow = Instance.new("Frame", wrap)
    topRow.Size             = UDim2.new(1, -12, 0, 17)
    topRow.Position         = UDim2.new(0, 6, 0, 4)
    topRow.BackgroundTransparency = 1

    local nameLbl = Instance.new("TextLabel", topRow)
    nameLbl.Size               = UDim2.new(0.6, 0, 1, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font               = Enum.Font.GothamSemibold
    nameLbl.TextSize           = 11
    nameLbl.TextColor3         = C.TEXT
    nameLbl.TextXAlignment     = Enum.TextXAlignment.Left
    nameLbl.Text               = labelText or "Progress"

    local cntLbl = Instance.new("TextLabel", topRow)
    cntLbl.Size               = UDim2.new(0.4, 0, 1, 0)
    cntLbl.Position           = UDim2.new(0.6, 0, 0, 0)
    cntLbl.BackgroundTransparency = 1
    cntLbl.Font               = Enum.Font.GothamBold
    cntLbl.TextSize           = 11
    cntLbl.TextColor3         = Color3.fromRGB(255, 255, 255)
    cntLbl.TextXAlignment     = Enum.TextXAlignment.Right
    cntLbl.Text               = "0 / 0"

    local track = Instance.new("Frame", wrap)
    track.Size             = UDim2.new(1, -12, 0, 8)
    track.Position         = UDim2.new(0, 6, 0, 26)
    track.BackgroundColor3 = C.PROG_TRACK
    track.BorderSizePixel  = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", track)
    fill.Size             = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = C.PROG_FILL
    fill.BorderSizePixel  = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local resetTimer = nil

    local function reset()
        if resetTimer then task.cancel(resetTimer); resetTimer = nil end
        fill.Size    = UDim2.new(0, 0, 1, 0)
        cntLbl.Text  = "0 / 0"
        wrap.Visible = false
    end

    local function setProgress(done, total)
        local pct = math.clamp(done / math.max(total, 1), 0, 1)
        if done >= total and total > 0 then
            cntLbl.Text = "Done"
            TweenService:Create(fill, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 1, 0)}):Play()
            if resetTimer then task.cancel(resetTimer) end
            resetTimer = task.delay(2.5, reset)
        else
            cntLbl.Text = done .. " / " .. total
            TweenService:Create(fill, TweenInfo.new(0.15), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
        end
    end

    return wrap, setProgress, reset
end

-- ════════════════════════════════════════════════════════════════════════════════
-- WIRE ART TAB — UI CONSTRUCTION
-- ════════════════════════════════════════════════════════════════════════════════

-- ── SECTION 1: Points Input ───────────────────────────────────────────────────
wSectionLabel("Vector3 Points")

local card1 = wCard()

local lbl1 = Instance.new("TextLabel", card1)
lbl1.Size               = UDim2.new(1, 0, 0, 16)
lbl1.BackgroundTransparency = 1
lbl1.Font               = Enum.Font.Gotham
lbl1.TextSize           = 11
lbl1.TextColor3         = C.TEXT_MID
lbl1.TextXAlignment     = Enum.TextXAlignment.Left
lbl1.Text               = "Paste Vector3 data:"

local pointsBox = Instance.new("TextBox", card1)
pointsBox.Size              = UDim2.new(1, 0, 0, 110)
pointsBox.BackgroundColor3  = C.INPUT_BG
pointsBox.BorderSizePixel   = 0
pointsBox.Font              = Enum.Font.Gotham
pointsBox.TextSize          = 11
pointsBox.TextColor3        = C.TEXT
pointsBox.PlaceholderText   = "Vector3.new(x, y, z),\n..."
pointsBox.PlaceholderColor3 = C.TEXT_DIM
pointsBox.Text              = ""
pointsBox.ClearTextOnFocus  = false
pointsBox.MultiLine         = true
pointsBox.TextWrapped        = true
pointsBox.TextXAlignment    = Enum.TextXAlignment.Left
pointsBox.TextYAlignment    = Enum.TextYAlignment.Top
corner(pointsBox, 6)
local ptsPad = Instance.new("UIPadding", pointsBox)
ptsPad.PaddingLeft   = UDim.new(0, 8)
ptsPad.PaddingRight  = UDim.new(0, 8)
ptsPad.PaddingTop    = UDim.new(0, 6)
local ptsStroke = addStroke(pointsBox)
pointsBox.Focused:Connect(function()
    TweenService:Create(ptsStroke, TweenInfo.new(0.12), {
        Transparency = 0, Color = Color3.fromRGB(140, 140, 140)
    }):Play()
end)
pointsBox.FocusLost:Connect(function()
    TweenService:Create(ptsStroke, TweenInfo.new(0.12), {Transparency = 0.4, Color = C.BORDER}):Play()
end)

local parseStatus = Instance.new("TextLabel", card1)
parseStatus.Size               = UDim2.new(1, 0, 0, 18)
parseStatus.BackgroundTransparency = 1
parseStatus.Font               = Enum.Font.Gotham
parseStatus.TextSize           = 11
parseStatus.TextColor3         = C.TEXT_MID
parseStatus.TextXAlignment     = Enum.TextXAlignment.Center
parseStatus.Text               = "— paste Vector3 points above —"

local parseBtn = wButton(card1, "Parse & Preview Points")

wSep()

-- ── SECTION 2: Origin / Offset ────────────────────────────────────────────────
wSectionLabel("Origin / Offset")

local card2 = wCard()

local lbl2 = Instance.new("TextLabel", card2)
lbl2.Size               = UDim2.new(1, 0, 0, 16)
lbl2.BackgroundTransparency = 1
lbl2.Font               = Enum.Font.Gotham
lbl2.TextSize           = 11
lbl2.TextColor3         = C.TEXT_MID
lbl2.TextXAlignment     = Enum.TextXAlignment.Left
lbl2.Text               = "Build center position (world coords):"

local xyzRow = Instance.new("Frame", card2)
xyzRow.Size                   = UDim2.new(1, 0, 0, 44)
xyzRow.BackgroundTransparency = 1
local xyzList = Instance.new("UIListLayout", xyzRow)
xyzList.FillDirection     = Enum.FillDirection.Horizontal
xyzList.Padding           = UDim.new(0, 6)
xyzList.SortOrder         = Enum.SortOrder.LayoutOrder
xyzList.VerticalAlignment = Enum.VerticalAlignment.Top

local function makeXYZField(labelText, order)
    local wrap = Instance.new("Frame", xyzRow)
    wrap.Size             = UDim2.new(0.333, -4, 1, 0)
    wrap.BackgroundTransparency = 1
    wrap.LayoutOrder      = order

    local lbl = Instance.new("TextLabel", wrap)
    lbl.Size              = UDim2.new(1, 0, 0, 14)
    lbl.Position          = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font              = Enum.Font.GothamBold
    lbl.TextSize          = 10
    lbl.TextColor3        = C.TEXT_MID
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.Text              = labelText

    local box = Instance.new("TextBox", wrap)
    box.Size              = UDim2.new(1, 0, 0, 28)
    box.Position          = UDim2.new(0, 0, 0, 16)
    box.BackgroundColor3  = C.INPUT_BG
    box.BorderSizePixel   = 0
    box.Font              = Enum.Font.Gotham
    box.TextSize          = 12
    box.TextColor3        = C.TEXT
    box.PlaceholderText   = "0"
    box.PlaceholderColor3 = C.TEXT_DIM
    box.Text              = "0"
    box.ClearTextOnFocus  = false
    box.TextXAlignment    = Enum.TextXAlignment.Center
    corner(box, 6)
    local s = addStroke(box)
    box.Focused:Connect(function()
        TweenService:Create(s, TweenInfo.new(0.12), {
            Transparency = 0, Color = Color3.fromRGB(140, 140, 140)
        }):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(s, TweenInfo.new(0.12), {Transparency = 0.4, Color = C.BORDER}):Play()
    end)
    return box
end

local offX = makeXYZField("X", 1)
local offY = makeXYZField("Y", 2)
local offZ = makeXYZField("Z", 3)

wButton(card2, "Reset Offset", function()
    offX.Text = "0"; offY.Text = "0"; offZ.Text = "0"
end)

wSep()

-- ── SECTION 3: Configuration ──────────────────────────────────────────────────
wSectionLabel("Configuration")

local card3 = wCard()

local cfgOrder = wInputField(card3, "Order Tag",                    "Username",         player.Name)
local cfgPerm  = wInputField(card3, "Permission ID",                "UserID",           tostring(player.UserId))
local cfgWire  = wInputField(card3, "Wire Asset Name",              "NeonWireWhite",    "NeonWireWhite")
local cfgBatch = wInputField(card3, "Batch Size (buy N → place N)", "50",               "50")

wSep()

-- ── SECTION 4: Status ─────────────────────────────────────────────────────────
wSectionLabel("Status")

local card4 = wCard()

local _, setStatus          = wStatusBar(card4, "Idle — paste points & parse")
local progBar, setProgress, resetProgress = wProgressBar(card4, "Wires")

wSep()

-- ── SECTION 5: Build Controls ─────────────────────────────────────────────────
wSectionLabel("Build")

local card5 = wCard()

local infoLabel = Instance.new("TextLabel", card5)
infoLabel.Size               = UDim2.new(1, 0, 0, 20)
infoLabel.BackgroundTransparency = 1
infoLabel.Font               = Enum.Font.Gotham
infoLabel.TextSize           = 11
infoLabel.TextColor3         = C.TEXT_MID
infoLabel.TextXAlignment     = Enum.TextXAlignment.Center
infoLabel.TextWrapped        = true
infoLabel.Text               = "Parse points first, then press Build Art."

local _, buildBtn, stopBtn = wButtonRow(card5, "Build Art", "Stop Build")

-- ════════════════════════════════════════════════════════════════════════════════
-- PARSE BUTTON
-- ════════════════════════════════════════════════════════════════════════════════
parseBtn.MouseButton1Click:Connect(function()
    local raw = pointsBox.Text
    if raw == "" then
        parseStatus.Text       = "No input."
        parseStatus.TextColor3 = Color3.fromRGB(180, 80, 80)
        return
    end

    parsedPoints = parseVector3Input(raw)
    if #parsedPoints == 0 then
        parseStatus.Text       = "No Vector3 values found."
        parseStatus.TextColor3 = Color3.fromRGB(180, 80, 80)
        return
    end

    local tx = tonumber(offX.Text) or 0
    local ty = tonumber(offY.Text) or 0
    local tz = tonumber(offZ.Text) or 0
    local offPts = applyOffset(parsedPoints, tx, ty, tz)
    chunks = chunkByLength(offPts, 25)

    parseStatus.Text       = string.format("%d points → %d wires (≤25 stud chunks)", #parsedPoints, #chunks)
    parseStatus.TextColor3 = C.TEXT
    infoLabel.Text         = string.format("Ready: %d wires to buy & place.", #chunks)

    setStatus("Ready — " .. #chunks .. " wires", false)
    progBar.Visible = true
    setProgress(0, #chunks)

    -- 3D preview (white/gray neon to match VanillaHub theme)
    task.spawn(function()
        local folder = workspace:FindFirstChild("WirePreview")
        if folder then folder:Destroy() end
        folder = Instance.new("Folder")
        folder.Name   = "WirePreview"
        folder.Parent = workspace

        for i, pt in ipairs(offPts) do
            local p = Instance.new("Part")
            p.Size       = Vector3.new(0.3, 0.3, 0.3)
            p.Shape      = Enum.PartType.Ball
            p.Material   = Enum.Material.Neon
            p.Color      = Color3.fromRGB(200, 200, 200)
            p.CFrame     = CFrame.new(pt)
            p.Anchored   = true
            p.CanCollide = false
            p.Parent     = folder

            if i > 1 then
                local prev = offPts[i-1]
                local mid  = (pt + prev) / 2
                local dist = (pt - prev).Magnitude
                if dist > 0.1 then
                    local beam = Instance.new("Part")
                    beam.Size       = Vector3.new(0.06, 0.06, dist)
                    beam.CFrame     = CFrame.new(mid, pt)
                    beam.Material   = Enum.Material.Neon
                    beam.Color      = Color3.fromRGB(130, 130, 130)
                    beam.Anchored   = true
                    beam.CanCollide = false
                    beam.Parent     = folder
                end
            end

            if i % 20 == 0 then task.wait() end
        end
        print(string.format("[VanillaHub/Wire] Preview: %d points in WirePreview folder.", #offPts))
    end)
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- BUILD BUTTON
-- ════════════════════════════════════════════════════════════════════════════════
buildBtn.MouseButton1Click:Connect(function()
    if buildRunning then
        setStatus("Already running — press Stop first.", true)
        return
    end
    if #chunks == 0 then
        setStatus("Parse points first!", false)
        return
    end

    local wireName  = cfgWire.Text  ~= "" and cfgWire.Text  or "NeonWireWhite"
    local orderTag  = cfgOrder.Text ~= "" and cfgOrder.Text or player.Name
    local permId    = cfgPerm.Text  ~= "" and cfgPerm.Text  or tostring(player.UserId)
    local batchSize = math.max(1, tonumber(cfgBatch.Text) or 50)
    local total     = #chunks

    buildRunning = true
    stopFlag     = false
    progBar.Visible = true
    setProgress(0, total)

    buildThread = task.spawn(function()
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            setStatus("No character found!", false)
            buildRunning = false
            return
        end
        local baseCF = hrp.CFrame
        local done   = 0

        setStatus("Building...", true)

        while done < total and not stopFlag do
            local bEnd  = math.min(done + batchSize, total)
            local bSize = bEnd - done

            -- Phase 1: Buy batch
            for i = 1, bSize do
                if stopFlag then break end
                setStatus(string.format("Buying %d / %d...", done + i, total), true)
                local ok = buyWire(wireName, baseCF)
                if not ok then task.wait(1) end
                task.wait(0.2)
            end

            if stopFlag then break end

            -- Phase 2: Place batch
            for i = 1, bSize do
                if stopFlag then break end
                local ci = done + i
                setStatus(string.format("Placing %d / %d...", ci, total), true)
                local chunkData = {}
                for idx, pt in ipairs(chunks[ci]) do chunkData[idx] = pt end
                placeWire(chunkData, wireName, orderTag, permId)
                setProgress(ci, total)
            end

            done = bEnd
        end

        if stopFlag then
            setStatus(string.format("Stopped at %d / %d.", done, total), false)
            print(string.format("[VanillaHub/Wire] Build stopped at %d/%d.", done, total))
        else
            setStatus(string.format("Done! %d wires placed.", total), false)
            setProgress(total, total)
            print(string.format("[VanillaHub/Wire] Build complete — %d wires placed.", total))
        end

        buildRunning = false
        buildThread  = nil
    end)
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- STOP BUTTON
-- ════════════════════════════════════════════════════════════════════════════════
stopBtn.MouseButton1Click:Connect(function()
    if not buildRunning then
        setStatus("No build is running.", false)
        return
    end
    stopFlag = true
    setStatus("Stopping — finishing current wire...", false)
    print("[VanillaHub/Wire] Stop requested.")
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- CLEANUP
-- ════════════════════════════════════════════════════════════════════════════════
table.insert(cleanupTasks, function()
    stopFlag     = true
    buildRunning = false
    if buildThread then pcall(task.cancel, buildThread); buildThread = nil end
    pcall(function()
        local f = workspace:FindFirstChild("WirePreview")
        if f then f:Destroy() end
    end)
end)

print("[VanillaHub] Vanilla8 loaded — Wire Art tab ready.")
