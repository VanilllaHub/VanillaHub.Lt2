-- ════════════════════════════════════════════════════════════════════════════════
-- VANILLA COMBINED — Vanilla2 (Butter Leak / Dupe Tab) + World Tab
-- Requires Vanilla1 (_G.VH) to be loaded first.
-- ════════════════════════════════════════════════════════════════════════════════

if not _G.VH then
    warn("[VanillaHub] Combined: _G.VH not found. Execute Vanilla1 first.")
    return
end

local VH           = _G.VH
local TweenService = VH.TweenService
local Players      = VH.Players
local player       = VH.player
local BTN_COLOR    = VH.BTN_COLOR
local BTN_HOVER    = VH.BTN_HOVER
local THEME_TEXT   = VH.THEME_TEXT
local dupePage     = VH.pages["DupeTab"]
local worldPage    = VH.pages["WorldTab"]

if not dupePage then
    warn("[VanillaHub] Combined: DupeTab page not found.")
    return
end
if not worldPage then
    warn("[VanillaHub] Combined: WorldTab page not found.")
    return
end

-- ════════════════════════════════════════════════════════════════════════════════
-- SHARED HELPERS (used by both tabs)
-- ════════════════════════════════════════════════════════════════════════════════

local function makeLabel(parent, text)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size               = UDim2.new(1, -12, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 11
    lbl.TextColor3         = Color3.fromRGB(120, 120, 150)
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 4)
    return lbl
end

local function makeSep(parent)
    local f = Instance.new("Frame", parent)
    f.Size             = UDim2.new(1, -12, 0, 1)
    f.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    f.BorderSizePixel  = 0
    return f
end

local function makeToggle(parent, text, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size             = UDim2.new(1, -12, 0, 32)
    frame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    frame.BorderSizePixel  = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size               = UDim2.new(1, -50, 1, 0)
    lbl.Position           = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamSemibold
    lbl.TextSize           = 13
    lbl.TextColor3         = THEME_TEXT
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = text
    local tb = Instance.new("TextButton", frame)
    tb.Size             = UDim2.new(0, 34, 0, 18)
    tb.Position         = UDim2.new(1, -44, 0.5, -9)
    tb.BackgroundColor3 = default and Color3.fromRGB(60, 180, 60) or BTN_COLOR
    tb.Text             = ""
    tb.BorderSizePixel  = 0
    tb.AutoButtonColor  = false
    Instance.new("UICorner", tb).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame", tb)
    knob.Size             = UDim2.new(0, 14, 0, 14)
    knob.Position         = UDim2.new(0, default and 18 or 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel  = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local toggled = default
    if callback then callback(toggled) end
    tb.MouseButton1Click:Connect(function()
        toggled = not toggled
        TweenService:Create(tb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            BackgroundColor3 = toggled and Color3.fromRGB(60, 180, 60) or BTN_COLOR
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, toggled and 18 or 2, 0.5, -7)
        }):Play()
        if callback then callback(toggled) end
    end)
    -- Return frame + getter (for dupePage usage) AND tb/knob refs (for worldPage auto-enable)
    return frame, function() return toggled end, tb, knob
end

local function makeBtn(parent, text, color, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size             = UDim2.new(1, -12, 0, 34)
    btn.BackgroundColor3 = color or BTN_COLOR
    btn.BorderSizePixel  = 0
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.TextColor3       = THEME_TEXT
    btn.Text             = text
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local base = color or BTN_COLOR
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_HOVER}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = base}):Play()
    end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end


local function makeProgressBar(parent, labelText)
    local wrap = Instance.new("Frame", parent)
    wrap.Size             = UDim2.new(1, -12, 0, 44)
    wrap.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    wrap.BorderSizePixel  = 0
    wrap.Visible          = false
    Instance.new("UICorner", wrap).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", wrap)
    stroke.Color       = Color3.fromRGB(60, 60, 80)
    stroke.Thickness   = 1
    stroke.Transparency = 0.5
    local topRow = Instance.new("Frame", wrap)
    topRow.Size                 = UDim2.new(1, -12, 0, 18)
    topRow.Position             = UDim2.new(0, 6, 0, 4)
    topRow.BackgroundTransparency = 1
    local nameLbl = Instance.new("TextLabel", topRow)
    nameLbl.Size               = UDim2.new(0.6, 0, 1, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font               = Enum.Font.GothamSemibold
    nameLbl.TextSize           = 11
    nameLbl.TextColor3         = THEME_TEXT
    nameLbl.TextXAlignment     = Enum.TextXAlignment.Left
    nameLbl.Text               = labelText
    local cntLbl = Instance.new("TextLabel", topRow)
    cntLbl.Size               = UDim2.new(0.4, 0, 1, 0)
    cntLbl.Position           = UDim2.new(0.6, 0, 0, 0)
    cntLbl.BackgroundTransparency = 1
    cntLbl.Font               = Enum.Font.GothamBold
    cntLbl.TextSize           = 11
    cntLbl.TextColor3         = Color3.fromRGB(120, 200, 120)
    cntLbl.TextXAlignment     = Enum.TextXAlignment.Right
    cntLbl.Text               = "0 / 0"
    local track = Instance.new("Frame", wrap)
    track.Size             = UDim2.new(1, -12, 0, 10)
    track.Position         = UDim2.new(0, 6, 0, 26)
    track.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    track.BorderSizePixel  = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track)
    fill.Size             = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(80, 180, 100)
    fill.BorderSizePixel  = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local function setProgress(done, total)
        local pct = math.clamp(done / math.max(total, 1), 0, 1)
        cntLbl.Text = done .. " / " .. total
        TweenService:Create(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Size = UDim2.new(pct, 0, 1, 0)
        }):Play()
    end
    local function reset()
        fill.Size    = UDim2.new(0, 0, 1, 0)
        cntLbl.Text  = "0 / 0"
        wrap.Visible = false
    end
    return wrap, setProgress, reset
end

-- ── PLAYER DROPDOWN ───────────────────────────────────────────────────────────
local function makeDupeDropdown(labelText, parentPage)
    local selected  = ""
    local isOpen    = false
    local ITEM_H    = 34
    local MAX_SHOW  = 5
    local HEADER_H  = 40

    local outer = Instance.new("Frame", parentPage)
    outer.Size             = UDim2.new(1, -12, 0, HEADER_H)
    outer.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    outer.BorderSizePixel  = 0
    outer.ClipsDescendants = true
    Instance.new("UICorner", outer).CornerRadius = UDim.new(0, 8)
    local outerStroke = Instance.new("UIStroke", outer)
    outerStroke.Color        = Color3.fromRGB(60, 60, 90)
    outerStroke.Thickness    = 1
    outerStroke.Transparency = 0.5

    local header = Instance.new("Frame", outer)
    header.Size                   = UDim2.new(1, 0, 0, HEADER_H)
    header.BackgroundTransparency = 1
    header.BorderSizePixel        = 0

    local lbl = Instance.new("TextLabel", header)
    lbl.Size               = UDim2.new(0, 80, 1, 0)
    lbl.Position           = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = labelText
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 12
    lbl.TextColor3         = THEME_TEXT
    lbl.TextXAlignment     = Enum.TextXAlignment.Left

    local selFrame = Instance.new("Frame", header)
    selFrame.Size             = UDim2.new(1, -96, 0, 28)
    selFrame.Position         = UDim2.new(0, 90, 0.5, -14)
    selFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    selFrame.BorderSizePixel  = 0
    Instance.new("UICorner", selFrame).CornerRadius = UDim.new(0, 6)
    local selStroke = Instance.new("UIStroke", selFrame)
    selStroke.Color        = Color3.fromRGB(70, 70, 110)
    selStroke.Thickness    = 1
    selStroke.Transparency = 0.4

    local avatar = Instance.new("ImageLabel", selFrame)
    avatar.Size             = UDim2.new(0, 20, 0, 20)
    avatar.Position         = UDim2.new(0, 6, 0.5, -10)
    avatar.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    avatar.BorderSizePixel  = 0
    avatar.Image            = ""
    avatar.ScaleType        = Enum.ScaleType.Crop
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

    local selLbl = Instance.new("TextLabel", selFrame)
    selLbl.Size               = UDim2.new(1, -60, 1, 0)
    selLbl.Position           = UDim2.new(0, 32, 0, 0)
    selLbl.BackgroundTransparency = 1
    selLbl.Text               = "Select a player..."
    selLbl.Font               = Enum.Font.GothamSemibold
    selLbl.TextSize           = 12
    selLbl.TextColor3         = Color3.fromRGB(110, 110, 140)
    selLbl.TextXAlignment     = Enum.TextXAlignment.Left
    selLbl.TextTruncate       = Enum.TextTruncate.AtEnd

    local arrowLbl = Instance.new("TextLabel", selFrame)
    arrowLbl.Size               = UDim2.new(0, 22, 1, 0)
    arrowLbl.Position           = UDim2.new(1, -24, 0, 0)
    arrowLbl.BackgroundTransparency = 1
    arrowLbl.Text               = "▾"
    arrowLbl.Font               = Enum.Font.GothamBold
    arrowLbl.TextSize           = 14
    arrowLbl.TextColor3         = Color3.fromRGB(120, 120, 160)
    arrowLbl.TextXAlignment     = Enum.TextXAlignment.Center

    local headerBtn = Instance.new("TextButton", selFrame)
    headerBtn.Size               = UDim2.new(1, 0, 1, 0)
    headerBtn.BackgroundTransparency = 1
    headerBtn.Text               = ""
    headerBtn.ZIndex             = 5

    local divider = Instance.new("Frame", outer)
    divider.Size             = UDim2.new(1, -16, 0, 1)
    divider.Position         = UDim2.new(0, 8, 0, HEADER_H)
    divider.BackgroundColor3 = Color3.fromRGB(50, 50, 75)
    divider.BorderSizePixel  = 0
    divider.Visible          = false

    local listScroll = Instance.new("ScrollingFrame", outer)
    listScroll.Position               = UDim2.new(0, 0, 0, HEADER_H + 2)
    listScroll.Size                   = UDim2.new(1, 0, 0, 0)
    listScroll.BackgroundTransparency = 1
    listScroll.BorderSizePixel        = 0
    listScroll.ScrollBarThickness     = 3
    listScroll.ScrollBarImageColor3   = Color3.fromRGB(90, 90, 130)
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

    local function setSelected(name, userId)
        selected            = name
        selLbl.Text         = name
        selLbl.TextColor3   = THEME_TEXT
        arrowLbl.TextColor3 = Color3.fromRGB(160, 160, 210)
        outerStroke.Color   = Color3.fromRGB(90, 90, 160)
        if userId then
            pcall(function()
                avatar.Image = Players:GetUserThumbnailAsync(
                    userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            end)
        end
    end

    local function clearSelected()
        selected            = ""
        selLbl.Text         = "Select a player..."
        selLbl.TextColor3   = Color3.fromRGB(110, 110, 140)
        avatar.Image        = ""
        arrowLbl.TextColor3 = Color3.fromRGB(120, 120, 160)
        outerStroke.Color   = Color3.fromRGB(60, 60, 90)
    end

    local function closeList()
        isOpen = false
        TweenService:Create(arrowLbl,   TweenInfo.new(0.2,  Enum.EasingStyle.Quint), {Rotation = 0}):Play()
        TweenService:Create(outer,      TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,-12,0,HEADER_H)}):Play()
        TweenService:Create(listScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,0)}):Play()
        divider.Visible = false
    end

    local function buildList()
        for _, c in ipairs(listScroll:GetChildren()) do
            if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
        end
        local playerList = Players:GetPlayers()
        table.sort(playerList, function(a, b) return a.Name < b.Name end)
        for i, plr in ipairs(playerList) do
            local isSelected = (plr.Name == selected)
            local row = Instance.new("Frame", listScroll)
            row.Size             = UDim2.new(1, 0, 0, ITEM_H)
            row.BackgroundColor3 = isSelected and Color3.fromRGB(45,45,75) or Color3.fromRGB(28,28,40)
            row.BorderSizePixel  = 0
            row.LayoutOrder      = i
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

            local miniAvatar = Instance.new("ImageLabel", row)
            miniAvatar.Size             = UDim2.new(0, 22, 0, 22)
            miniAvatar.Position         = UDim2.new(0, 8, 0.5, -11)
            miniAvatar.BackgroundColor3 = Color3.fromRGB(40, 40, 58)
            miniAvatar.BorderSizePixel  = 0
            miniAvatar.ScaleType        = Enum.ScaleType.Crop
            Instance.new("UICorner", miniAvatar).CornerRadius = UDim.new(1, 0)
            task.spawn(function()
                pcall(function()
                    miniAvatar.Image = Players:GetUserThumbnailAsync(
                        plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                end)
            end)

            local nameLbl = Instance.new("TextLabel", row)
            nameLbl.Size               = UDim2.new(1, -70, 1, 0)
            nameLbl.Position           = UDim2.new(0, 36, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text               = plr.Name
            nameLbl.Font               = Enum.Font.GothamSemibold
            nameLbl.TextSize           = 13
            nameLbl.TextColor3         = isSelected and THEME_TEXT or Color3.fromRGB(200, 200, 215)
            nameLbl.TextXAlignment     = Enum.TextXAlignment.Left
            nameLbl.TextTruncate       = Enum.TextTruncate.AtEnd

            if isSelected then
                local check = Instance.new("TextLabel", row)
                check.Size               = UDim2.new(0, 24, 1, 0)
                check.Position           = UDim2.new(1, -28, 0, 0)
                check.BackgroundTransparency = 1
                check.Text               = "✓"
                check.Font               = Enum.Font.GothamBold
                check.TextSize           = 14
                check.TextColor3         = Color3.fromRGB(120, 180, 255)
                check.TextXAlignment     = Enum.TextXAlignment.Center
            end

            local rowBtn = Instance.new("TextButton", row)
            rowBtn.Size               = UDim2.new(1, 0, 1, 0)
            rowBtn.BackgroundTransparency = 1
            rowBtn.Text               = ""
            rowBtn.ZIndex             = 5
            rowBtn.MouseEnter:Connect(function()
                if plr.Name ~= selected then
                    TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(38,38,58)}):Play()
                end
            end)
            rowBtn.MouseLeave:Connect(function()
                if plr.Name ~= selected then
                    TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(28,28,40)}):Play()
                end
            end)
            rowBtn.MouseButton1Click:Connect(function()
                if plr.Name == selected then clearSelected() else setSelected(plr.Name, plr.UserId) end
                buildList()
                task.delay(0.05, closeList)
            end)
        end
    end

    local function openList()
        isOpen = true
        buildList()
        local count  = #Players:GetPlayers()
        local listH  = math.min(count, MAX_SHOW) * (ITEM_H + 3) + 8
        local totalH = HEADER_H + 2 + listH
        divider.Visible = true
        TweenService:Create(arrowLbl,   TweenInfo.new(0.2,  Enum.EasingStyle.Quint), {Rotation = 180}):Play()
        TweenService:Create(outer,      TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(1,-12,0,totalH)}):Play()
        TweenService:Create(listScroll, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,listH)}):Play()
    end

    headerBtn.MouseButton1Click:Connect(function()
        if isOpen then closeList() else openList() end
    end)
    headerBtn.MouseEnter:Connect(function()
        TweenService:Create(selFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(38,38,55)}):Play()
    end)
    headerBtn.MouseLeave:Connect(function()
        TweenService:Create(selFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(30,30,42)}):Play()
    end)

    Players.PlayerAdded:Connect(function()
        if isOpen then
            buildList()
            local count = #Players:GetPlayers()
            local listH = math.min(count, MAX_SHOW) * (ITEM_H + 3) + 8
            outer.Size      = UDim2.new(1, -12, 0, HEADER_H + 2 + listH)
            listScroll.Size = UDim2.new(1, 0, 0, listH)
        end
    end)
    Players.PlayerRemoving:Connect(function(leaving)
        if leaving.Name == selected then clearSelected() end
        if isOpen then
            buildList()
            local count = #Players:GetPlayers()
            local listH = math.min(math.max(count - 1, 0), MAX_SHOW) * (ITEM_H + 3) + 8
            outer.Size      = UDim2.new(1, -12, 0, HEADER_H + 2 + listH)
            listScroll.Size = UDim2.new(1, 0, 0, listH)
        end
    end)

    return outer, function() return selected end
end

-- ════════════════════════════════════════════════════════════════════════════════
-- DUPE TAB — Butter Leak
-- ════════════════════════════════════════════════════════════════════════════════

-- ── STATUS BAR ────────────────────────────────────────────────────────────────
local statusBar = Instance.new("Frame", dupePage)
statusBar.Size             = UDim2.new(1, -12, 0, 28)
statusBar.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
statusBar.BorderSizePixel  = 0
Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", statusBar).Color = Color3.fromRGB(50, 50, 70)

local statusDot = Instance.new("Frame", statusBar)
statusDot.Size             = UDim2.new(0, 8, 0, 8)
statusDot.Position         = UDim2.new(0, 10, 0.5, -4)
statusDot.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
statusDot.BorderSizePixel  = 0
Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)

local statusLbl = Instance.new("TextLabel", statusBar)
statusLbl.Size                 = UDim2.new(1, -28, 1, 0)
statusLbl.Position             = UDim2.new(0, 26, 0, 0)
statusLbl.BackgroundTransparency = 1
statusLbl.Font                 = Enum.Font.Gotham
statusLbl.TextSize             = 12
statusLbl.TextColor3           = Color3.fromRGB(160, 155, 175)
statusLbl.TextXAlignment       = Enum.TextXAlignment.Left
statusLbl.Text                 = "Ready"

local function setStatus(msg, active)
    statusLbl.Text = msg
    TweenService:Create(statusDot, TweenInfo.new(0.2), {
        BackgroundColor3 = active and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(100, 100, 120)
    }):Play()
end

-- ── PLAYER DROPDOWNS ──────────────────────────────────────────────────────────
makeLabel(dupePage, "Players")
local _, getGiverName    = makeDupeDropdown("Giver",    dupePage)
local _, getReceiverName = makeDupeDropdown("Receiver", dupePage)

makeSep(dupePage)
makeLabel(dupePage, "What to Transfer")

local _, getStructures = makeToggle(dupePage, "Structures",     false)
local _, getFurniture  = makeToggle(dupePage, "Furniture",      false)
local _, getTrucks     = makeToggle(dupePage, "Trucks + Cargo", false)
local _, getGifs       = makeToggle(dupePage, "Gift/Items",     false)
local _, getWood       = makeToggle(dupePage, "Wood",           false)

makeSep(dupePage)
makeLabel(dupePage, "Progress")

local progStructures, setProgStructures, resetProgStructures = makeProgressBar(dupePage, "Structures")
local progFurniture,  setProgFurniture,  resetProgFurniture  = makeProgressBar(dupePage, "Furniture")
local progTrucks,     setProgTrucks,     resetProgTrucks     = makeProgressBar(dupePage, "Trucks + Cargo")
local progGifs,       setProgGifs,       resetProgGifs       = makeProgressBar(dupePage, "Gift/Items")
local progWood,       setProgWood,       resetProgWood       = makeProgressBar(dupePage, "Wood")

makeSep(dupePage)

local runBtn  = makeBtn(dupePage, "▶  Run Butter Dupe", Color3.fromRGB(35, 65, 35),  function() end)
local stopBtn = makeBtn(dupePage, "■  Stop",            Color3.fromRGB(65, 25, 25),  function() end)

-- ── LOGIC ─────────────────────────────────────────────────────────────────────
local butterRunning = false
local butterThread  = nil

local function resetAllProgress()
    resetProgStructures(); resetProgFurniture(); resetProgTrucks()
    resetProgGifs();       resetProgWood()
end

stopBtn.MouseButton1Click:Connect(function()
    butterRunning = false; VH.butter.running = false
    if butterThread then pcall(task.cancel, butterThread); butterThread = nil end
    VH.butter.thread = nil
    setStatus("Stopped", false)
    resetAllProgress()
end)

runBtn.MouseButton1Click:Connect(function()
    if butterRunning then setStatus("Already running!", true) return end

    local giverName    = getGiverName()
    local receiverName = getReceiverName()
    if giverName == "" or receiverName == "" then
        setStatus("⚠ Select both players!", false) return
    end

    butterRunning = true; VH.butter.running = true
    setStatus("Finding bases...", true)
    resetAllProgress()

    butterThread = task.spawn(function()
        VH.butter.thread = butterThread

        local RS   = game:GetService("ReplicatedStorage")
        local LP   = Players.LocalPlayer
        local Char = LP.Character or LP.CharacterAdded:Wait()

        local GiveBaseOrigin, ReceiverBaseOrigin

        for _, v in pairs(workspace.Properties:GetDescendants()) do
            if v.Name == "Owner" then
                local val = tostring(v.Value)
                if val == giverName    then GiveBaseOrigin     = v.Parent:FindFirstChild("OriginSquare") end
                if val == receiverName then ReceiverBaseOrigin = v.Parent:FindFirstChild("OriginSquare") end
            end
        end

        if not (GiveBaseOrigin and ReceiverBaseOrigin) then
            setStatus("⚠ Couldn't find bases!", false)
            butterRunning = false; VH.butter.running = false; butterThread = nil; VH.butter.thread = nil
            return
        end

        local function isPointInside(point, boxCFrame, boxSize)
            local r = boxCFrame:PointToObjectSpace(point)
            return math.abs(r.X) <= boxSize.X / 2
               and math.abs(r.Y) <= boxSize.Y / 2 + 2
               and math.abs(r.Z) <= boxSize.Z / 2
        end

        local function countItems(typeCheck)
            local n = 0
            for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                if v.Name == "Owner" and tostring(v.Value) == giverName and typeCheck(v.Parent) then
                    n += 1
                end
            end
            return n
        end

        -- ── STRUCTURES ────────────────────────────────────────────────────────
        if getStructures() and butterRunning then
            local total = countItems(function(p)
                return p:FindFirstChild("Type") and tostring(p.Type.Value) == "Structure"
                    and (p:FindFirstChildOfClass("Part") or p:FindFirstChildOfClass("WedgePart"))
            end)
            if total > 0 then
                progStructures.Visible = true; setProgStructures(0, total)
                setStatus("Sending structures...", true)
                local done = 0
                pcall(function()
                    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                        if not butterRunning then break end
                        if v.Name == "Owner" and tostring(v.Value) == giverName then
                            local p = v.Parent
                            if p:FindFirstChild("Type") and tostring(p.Type.Value) == "Structure" then
                                if p:FindFirstChildOfClass("Part") or p:FindFirstChildOfClass("WedgePart") then
                                    local PCF  = (p:FindFirstChild("MainCFrame") and p.MainCFrame.Value) or p:FindFirstChildOfClass("Part").CFrame
                                    local DA   = p:FindFirstChild("BlueprintWoodClass") and p.BlueprintWoodClass.Value or nil
                                    local nPos = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                                    local Off  = CFrame.new(nPos) * PCF.Rotation
                                    repeat task.wait()
                                        pcall(function()
                                            RS.PlaceStructure.ClientPlacedStructure:FireServer(p.ItemName.Value, Off, LP, DA, p, true)
                                        end)
                                    until not p.Parent
                                    done += 1; setProgStructures(done, total)
                                end
                            end
                        end
                    end
                end)
                setProgStructures(total, total)
            end
        end

        -- ── FURNITURE ─────────────────────────────────────────────────────────
        if getFurniture() and butterRunning then
            local total = countItems(function(p)
                return p:FindFirstChild("Type") and tostring(p.Type.Value) == "Furniture"
                    and p:FindFirstChildOfClass("Part")
            end)
            if total > 0 then
                progFurniture.Visible = true; setProgFurniture(0, total)
                setStatus("Sending furniture...", true)
                local done = 0
                pcall(function()
                    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                        if not butterRunning then break end
                        if v.Name == "Owner" and tostring(v.Value) == giverName then
                            local p = v.Parent
                            if p:FindFirstChild("Type") and tostring(p.Type.Value) == "Furniture" then
                                if p:FindFirstChildOfClass("Part") then
                                    local PCF  = (p:FindFirstChild("MainCFrame") and p.MainCFrame.Value)
                                             or (p:FindFirstChild("Main") and p.Main.CFrame)
                                             or p:FindFirstChildOfClass("Part").CFrame
                                    local DA   = p:FindFirstChild("BlueprintWoodClass") and p.BlueprintWoodClass.Value or nil
                                    local nPos = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                                    local Off  = CFrame.new(nPos) * PCF.Rotation
                                    repeat task.wait()
                                        pcall(function()
                                            RS.PlaceStructure.ClientPlacedStructure:FireServer(p.ItemName.Value, Off, LP, DA, p, true)
                                        end)
                                    until not p.Parent
                                    done += 1; setProgFurniture(done, total)
                                end
                            end
                        end
                    end
                end)
                setProgFurniture(total, total)
            end
        end

        -- ── TRUCKS + CARGO ────────────────────────────────────────────────────
        if getTrucks() and butterRunning then
            local teleportedParts  = {}
            local ignoredParts     = {}
            local DidTruckTeleport = false

            local function TeleportTruck()
                if DidTruckTeleport then return end
                if not Char.Humanoid.SeatPart then return end
                local TCF  = Char.Humanoid.SeatPart.Parent:FindFirstChild("Main").CFrame
                local nPos = TCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                Char.Humanoid.SeatPart.Parent:SetPrimaryPartCFrame(CFrame.new(nPos) * TCF.Rotation)
                DidTruckTeleport = true
            end

            local truckCount = 0
            for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                if v.Name == "Owner" and tostring(v.Value) == giverName and v.Parent:FindFirstChild("DriveSeat") then
                    truckCount += 1
                end
            end

            if truckCount > 0 then
                progTrucks.Visible = true; setProgTrucks(0, truckCount)
                setStatus("Sending trucks...", true)
                local truckDone = 0

                -- Phase 1: teleport all trucks
                for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                    if not butterRunning then break end
                    if v.Name == "Owner" and tostring(v.Value) == giverName and v.Parent:FindFirstChild("DriveSeat") then
                        v.Parent.DriveSeat:Sit(Char.Humanoid)
                        repeat task.wait() v.Parent.DriveSeat:Sit(Char.Humanoid) until Char.Humanoid.SeatPart

                        local tModel   = Char.Humanoid.SeatPart.Parent
                        local mCF, mSz = tModel:GetBoundingBox()

                        for _, p in ipairs(tModel:GetDescendants()) do
                            if p:IsA("BasePart") then ignoredParts[p] = true end
                        end
                        for _, p in ipairs(Char:GetDescendants()) do
                            if p:IsA("BasePart") then ignoredParts[p] = true end
                        end

                        for _, part in ipairs(workspace:GetDescendants()) do
                            if part:IsA("BasePart") and not ignoredParts[part] then
                                if part.Name == "Main" or part.Name == "WoodSection" then
                                    if part:FindFirstChild("Weld") and part.Weld.Part1.Parent ~= part.Parent then continue end
                                    task.spawn(function()
                                        if isPointInside(part.Position, mCF, mSz) then
                                            TeleportTruck()
                                            local PCF  = part.CFrame
                                            local nP   = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                                            local tOff = CFrame.new(nP) * PCF.Rotation
                                            part.CFrame = tOff
                                            task.wait(0.3)
                                            table.insert(teleportedParts, {
                                                Instance     = part,
                                                OldPos       = part.Position,
                                                TargetCFrame = tOff,
                                            })
                                        end
                                    end)
                                end
                            end
                        end

                        local SitPart   = Char.Humanoid.SeatPart
                        local DoorHinge = SitPart.Parent:FindFirstChild("PaintParts")
                            and SitPart.Parent.PaintParts:FindFirstChild("DoorLeft")
                            and SitPart.Parent.PaintParts.DoorLeft:FindFirstChild("ButtonRemote_Hinge")
                        task.wait()
                        Char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        task.wait(0.1); SitPart:Destroy(); TeleportTruck(); DidTruckTeleport = false; task.wait(0.1)
                        if DoorHinge then
                            for i = 1, 10 do RS.Interaction.RemoteProxy:FireServer(DoorHinge) end
                        end
                        truckDone += 1; setProgTrucks(truckDone, truckCount)
                    end
                end

                -- Phase 2: retry any cargo that didn't reach TargetCFrame.
                -- FIX: Progress bar now only counts + shows the MISSED items still on
                -- the giver's plot, not the full teleportedParts list.
                task.wait(2) -- give task.spawns time to finish recording

                local MAX_TRIES = 25
                local attempt   = 0

                -- Helper: returns only items that are still far from their target
                -- AND are still on the giver's plot (i.e. not yet on receiver side).
                local function getMissed()
                    local missed = {}
                    for _, data in ipairs(teleportedParts) do
                        if data.Instance and data.Instance.Parent then
                            local dist = (data.Instance.Position - data.TargetCFrame.Position).Magnitude
                            if dist > 8 then
                                -- Only include if the part is still near the giver's plot origin
                                -- (within 500 studs, a generous threshold covering any plot size).
                                local distFromGiver = (data.Instance.Position - GiveBaseOrigin.Position).Magnitude
                                if distFromGiver < 500 then
                                    table.insert(missed, data)
                                end
                            end
                        end
                    end
                    return missed
                end

                local missedList = getMissed()

                if #missedList > 0 then
                    -- FIX: Show progress bar with ONLY the missed count, not cargoTotal
                    progTrucks.Visible = true
                    setProgTrucks(0, #missedList)
                    local missedTotal = #missedList  -- fixed denominator for Part 2

                    local itemsDone = 0

                    while #missedList > 0 and VH.butter.running and attempt < MAX_TRIES do
                        attempt += 1
                        setStatus(string.format("Cargo retry %d/%d — %d part(s) left...", attempt, MAX_TRIES, #missedList), true)

                        for _, data in ipairs(missedList) do
                            if not VH.butter.running then break end
                            local item = data.Instance

                            if not (item and item.Parent) then continue end

                            local tries = 0
                            while (Char.HumanoidRootPart.Position - item.Position).Magnitude > 25 and tries < 15 do
                                Char.HumanoidRootPart.CFrame = item.CFrame
                                task.wait(0.1)
                                tries += 1
                            end

                            RS.Interaction.ClientIsDragging:FireServer(item.Parent)
                            task.wait(0.6)
                            item.CFrame = data.TargetCFrame
                            task.wait(0.3)

                            -- Update progress immediately after each individual item
                            itemsDone += 1
                            setProgTrucks(itemsDone, missedTotal)
                            task.wait() -- yield so the UI tween actually renders
                        end

                        task.wait(1)
                        missedList = getMissed()
                        -- Only advance itemsDone forward, never backwards
                        local confirmed = missedTotal - #missedList
                        if confirmed > itemsDone then
                            itemsDone = confirmed
                            setProgTrucks(itemsDone, missedTotal)
                        end
                    end

                    if #missedList == 0 then
                        setStatus("✓ All cargo teleported!", true)
                    else
                        setStatus(string.format("Gave up after %d tries — %d part(s) missed", MAX_TRIES, #missedList), false)
                    end

                    setProgTrucks(missedTotal, missedTotal)
                    task.wait(1)
                else
                    -- No missed cargo at all — mark trucks bar as fully complete
                    setProgTrucks(truckCount, truckCount)
                end
            end
        end

        -- ── SEND ITEM HELPER ──────────────────────────────────────────────────
        local function seekNetOwn(part)
            if not butterRunning then return end
            if (Char.HumanoidRootPart.Position - part.Position).Magnitude > 25 then
                Char.HumanoidRootPart.CFrame = part.CFrame; task.wait(0.1)
            end
            for i = 1, 50 do task.wait(0.05); RS.Interaction.ClientIsDragging:FireServer(part.Parent) end
        end

        local function sendItem(part, Offset)
            if not butterRunning then return end
            if (Char.HumanoidRootPart.Position - part.Position).Magnitude > 25 then
                Char.HumanoidRootPart.CFrame = part.CFrame; task.wait(0.1)
            end
            seekNetOwn(part)
            for i = 1, 200 do part.CFrame = Offset end
            task.wait(0.2)
        end

        -- ── GIFT ITEMS ────────────────────────────────────────────────────────
        if getGifs() and butterRunning then
            local total = countItems(function(p)
                return p:FindFirstChildOfClass("Script") and p:FindFirstChild("DraggableItem")
                    and (p:FindFirstChild("Main") or p:FindFirstChildOfClass("Part"))
            end)
            if total > 0 then
                progGifs.Visible = true; setProgGifs(0, total)
                setStatus("Sending gift/items...", true)
                local done = 0
                pcall(function()
                    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                        if not butterRunning then break end
                        if v.Name == "Owner" and tostring(v.Value) == giverName then
                            local p = v.Parent
                            if p:FindFirstChildOfClass("Script") and p:FindFirstChild("DraggableItem") then
                                local part = p:FindFirstChild("Main") or p:FindFirstChildOfClass("Part")
                                if not part then continue end
                                local PCF  = (p:FindFirstChild("Main") and p.Main.CFrame) or p:FindFirstChildOfClass("Part").CFrame
                                local nPos = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                                sendItem(part, CFrame.new(nPos) * PCF.Rotation)
                                done += 1; setProgGifs(done, total)
                            end
                        end
                    end
                end)
                setProgGifs(total, total)
            end
        end

        -- ── WOOD ──────────────────────────────────────────────────────────────
        if getWood() and butterRunning then
            local total = countItems(function(p)
                return p:FindFirstChild("TreeClass")
                    and (p:FindFirstChild("Main") or p:FindFirstChildOfClass("Part"))
            end)
            if total > 0 then
                progWood.Visible = true; setProgWood(0, total)
                setStatus("Sending wood...", true)
                local done = 0
                pcall(function()
                    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                        if not butterRunning then break end
                        if v.Name == "Owner" and tostring(v.Value) == giverName then
                            local p = v.Parent
                            if p:FindFirstChild("TreeClass") then
                                local part = p:FindFirstChild("Main") or p:FindFirstChildOfClass("Part")
                                if not part then continue end
                                local PCF  = (p:FindFirstChild("Main") and p.Main.CFrame) or p:FindFirstChildOfClass("Part").CFrame
                                local nPos = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                                if (Char.HumanoidRootPart.Position - part.Position).Magnitude > 25 then
                                    Char.HumanoidRootPart.CFrame = part.CFrame; task.wait(0.1)
                                end
                                for i = 1, 50 do task.wait(0.05); RS.Interaction.ClientIsDragging:FireServer(part.Parent) end
                                for i = 1, 200 do part.CFrame = CFrame.new(nPos) * PCF.Rotation end
                                task.wait(0.2)
                                done += 1; setProgWood(done, total)
                            end
                        end
                    end
                end)
                setProgWood(total, total)
            end
        end

        if butterRunning then setStatus("✓ Done!", false) end
        butterRunning = false; VH.butter.running = false
        butterThread = nil; VH.butter.thread = nil
    end)
end)

-- Register cleanup with Vanilla1 so closing the hub stops any running dupe
table.insert(VH.cleanupTasks, function()
    butterRunning = false; VH.butter.running = false
    if butterThread then pcall(task.cancel, butterThread); butterThread = nil end
    VH.butter.thread = nil
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- SINGLE TRUCK TELEPORT (Dupe Tab — below Butter Leak)
-- ════════════════════════════════════════════════════════════════════════════════

makeSep(dupePage)
makeLabel(dupePage, "Single Truck Teleport")

local _, getTruckGiverName    = makeDupeDropdown("Giver",    dupePage)
local _, getTruckReceiverName = makeDupeDropdown("Receiver", dupePage)

-- Status bar
local truckStatusBar = Instance.new("Frame", dupePage)
truckStatusBar.Size             = UDim2.new(1, -12, 0, 28)
truckStatusBar.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
truckStatusBar.BorderSizePixel  = 0
Instance.new("UICorner", truckStatusBar).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", truckStatusBar).Color = Color3.fromRGB(50, 50, 70)

local truckStatusDot = Instance.new("Frame", truckStatusBar)
truckStatusDot.Size             = UDim2.new(0, 8, 0, 8)
truckStatusDot.Position         = UDim2.new(0, 10, 0.5, -4)
truckStatusDot.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
truckStatusDot.BorderSizePixel  = 0
Instance.new("UICorner", truckStatusDot).CornerRadius = UDim.new(1, 0)

local truckStatusLbl = Instance.new("TextLabel", truckStatusBar)
truckStatusLbl.Size                   = UDim2.new(1, -28, 1, 0)
truckStatusLbl.Position               = UDim2.new(0, 26, 0, 0)
truckStatusLbl.BackgroundTransparency = 1
truckStatusLbl.Font                   = Enum.Font.Gotham
truckStatusLbl.TextSize               = 12
truckStatusLbl.TextColor3             = Color3.fromRGB(160, 155, 175)
truckStatusLbl.TextXAlignment         = Enum.TextXAlignment.Left
truckStatusLbl.Text                   = "Ready — sit in a truck first"

local function setTruckStatus(msg, active)
    truckStatusLbl.Text = msg
    TweenService:Create(truckStatusDot, TweenInfo.new(0.2), {
        BackgroundColor3 = active
            and Color3.fromRGB(80, 200, 100)
            or  Color3.fromRGB(100, 100, 120)
    }):Play()
end

local truckProgBar, setTruckProg, resetTruckProg = makeProgressBar(dupePage, "Truck + Cargo")

local singleTruckRunning = false
local singleTruckThread  = nil

local stopTruckBtn = makeBtn(dupePage, "■  Stop Truck", Color3.fromRGB(65, 25, 25), function()
    singleTruckRunning = false
    if singleTruckThread then
        pcall(task.cancel, singleTruckThread)
        singleTruckThread = nil
    end
    setTruckStatus("Stopped", false)
    resetTruckProg()
    stopTruckBtn.Visible = false
end)
stopTruckBtn.Visible = false

makeBtn(dupePage, "▶  Teleport Truck", Color3.fromRGB(35, 55, 65), function()
    if singleTruckRunning then setTruckStatus("Already running!", true) return end

    local LP   = Players.LocalPlayer
    local Char = LP.Character
    if not Char then setTruckStatus("No character found!", false) return end

    local hum = Char:FindFirstChildOfClass("Humanoid")
    if not (hum and hum.SeatPart) then
        setTruckStatus("Not sitting in a truck!", false) return
    end

    local truckModel = hum.SeatPart.Parent
    if not truckModel:FindFirstChild("DriveSeat") then
        setTruckStatus("Seat is not a truck DriveSeat!", false) return
    end

    local gName = getTruckGiverName()
    local rName = getTruckReceiverName()
    if gName == "" or rName == "" then
        setTruckStatus("Select both players!", false) return
    end

    local GiveBaseOrigin, ReceiverBaseOrigin
    for _, v in pairs(workspace.Properties:GetDescendants()) do
        if v.Name == "Owner" then
            local val = tostring(v.Value)
            if val == gName then GiveBaseOrigin     = v.Parent:FindFirstChild("OriginSquare") end
            if val == rName then ReceiverBaseOrigin = v.Parent:FindFirstChild("OriginSquare") end
        end
    end

    if not GiveBaseOrigin     then setTruckStatus("Giver base not found!",    false) return end
    if not ReceiverBaseOrigin then setTruckStatus("Receiver base not found!", false) return end

    singleTruckRunning   = true
    stopTruckBtn.Visible = true
    resetTruckProg()
    setTruckStatus("Sending truck...", true)

    singleTruckThread = task.spawn(function()
        local RS = game:GetService("ReplicatedStorage")

        local function isPointInside(point, boxCFrame, boxSize)
            local r = boxCFrame:PointToObjectSpace(point)
            return math.abs(r.X) <= boxSize.X / 2
               and math.abs(r.Y) <= boxSize.Y / 2 + 2
               and math.abs(r.Z) <= boxSize.Z / 2
        end

        local teleportedParts  = {}
        local ignoredParts     = {}
        local DidTruckTeleport = false

        local function TeleportTruck()
            if DidTruckTeleport then return end
            if not Char.Humanoid.SeatPart then return end
            local TCF  = Char.Humanoid.SeatPart.Parent:FindFirstChild("Main").CFrame
            local nPos = TCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
            Char.Humanoid.SeatPart.Parent:SetPrimaryPartCFrame(CFrame.new(nPos) * TCF.Rotation)
            DidTruckTeleport = true
        end

        truckProgBar.Visible = true
        setTruckProg(0, 1)

        truckModel.DriveSeat:Sit(Char.Humanoid)
        repeat task.wait() truckModel.DriveSeat:Sit(Char.Humanoid) until Char.Humanoid.SeatPart

        local mCF, mSz = truckModel:GetBoundingBox()

        for _, p in ipairs(truckModel:GetDescendants()) do
            if p:IsA("BasePart") then ignoredParts[p] = true end
        end
        for _, p in ipairs(Char:GetDescendants()) do
            if p:IsA("BasePart") then ignoredParts[p] = true end
        end

        -- Scan all workspace parts for cargo inside the truck's bounding box
        for _, part in ipairs(workspace:GetDescendants()) do
            if not singleTruckRunning then break end
            if part:IsA("BasePart") and not ignoredParts[part] then
                if part.Name == "Main" or part.Name == "WoodSection" then
                    if part:FindFirstChild("Weld")
                        and part.Weld.Part1
                        and part.Weld.Part1.Parent ~= part.Parent then
                        continue
                    end
                    task.spawn(function()
                        if isPointInside(part.Position, mCF, mSz) then
                            TeleportTruck()
                            local PCF  = part.CFrame
                            local nP   = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                            local tOff = CFrame.new(nP) * PCF.Rotation
                            part.CFrame = tOff
                            task.wait(0.3)
                            table.insert(teleportedParts, {
                                Instance     = part,
                                OldPos       = part.Position,
                                TargetCFrame = tOff,
                            })
                        end
                    end)
                end
            end
        end

        -- Eject, destroy seat, close door, re-teleport truck
        local SitPart   = Char.Humanoid.SeatPart
        local DoorHinge = SitPart.Parent:FindFirstChild("PaintParts")
            and SitPart.Parent.PaintParts:FindFirstChild("DoorLeft")
            and SitPart.Parent.PaintParts.DoorLeft:FindFirstChild("ButtonRemote_Hinge")
        task.wait()
        Char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        task.wait(0.1)
        SitPart:Destroy()
        TeleportTruck()
        DidTruckTeleport = false
        task.wait(0.1)
        if DoorHinge then
            for i = 1, 10 do RS.Interaction.RemoteProxy:FireServer(DoorHinge) end
        end
        setTruckProg(1, 1)

        task.wait(2) -- give task.spawns time to finish recording

        -- ── Cargo retry loop (up to 25 attempts) ──────────────────────────────
        local function getMissed()
            local missed = {}
            for _, data in ipairs(teleportedParts) do
                if data.Instance and data.Instance.Parent then
                    if (data.Instance.Position - data.TargetCFrame.Position).Magnitude > 8 then
                        local distFromGiver = (data.Instance.Position - GiveBaseOrigin.Position).Magnitude
                        if distFromGiver < 500 then
                            table.insert(missed, data)
                        end
                    end
                end
            end
            return missed
        end

        local missedList = getMissed()

        if #missedList > 0 then
            truckProgBar.Visible = true
            setTruckProg(0, #missedList)
            local missedTotal    = #missedList
            local MAX_TRIES      = 25
            local attempt        = 0
            local itemsDone      = 0

            while #missedList > 0 and singleTruckRunning and attempt < MAX_TRIES do
                attempt += 1
                setTruckStatus(string.format(
                    "Cargo retry %d/%d — %d part(s) left...", attempt, MAX_TRIES, #missedList), true)

                for _, data in ipairs(missedList) do
                    if not singleTruckRunning then break end
                    local item = data.Instance
                    if not (item and item.Parent) then continue end

                    local tries = 0
                    while (Char.HumanoidRootPart.Position - item.Position).Magnitude > 25 and tries < 15 do
                        Char.HumanoidRootPart.CFrame = item.CFrame
                        task.wait(0.1)
                        tries += 1
                    end

                    RS.Interaction.ClientIsDragging:FireServer(item.Parent)
                    task.wait(0.6)
                    item.CFrame = data.TargetCFrame
                    task.wait(0.3)

                    -- Update progress immediately after each individual item
                    itemsDone += 1
                    setTruckProg(itemsDone, missedTotal)
                    task.wait() -- yield so the UI tween actually renders
                end

                task.wait(1)
                missedList = getMissed()
                -- Only advance itemsDone forward, never backwards
                local confirmed = missedTotal - #missedList
                if confirmed > itemsDone then
                    itemsDone = confirmed
                    setTruckProg(itemsDone, missedTotal)
                end
            end

            if #missedList == 0 then
                setTruckStatus("✓ All cargo teleported!", true)
            else
                setTruckStatus(string.format(
                    "Gave up after %d tries — %d part(s) missed", MAX_TRIES, #missedList), false)
            end

            setTruckProg(missedTotal, missedTotal)
        else
            setTruckStatus("✓ Truck teleported! (no cargo found)", false)
        end

        task.wait(1)
        singleTruckRunning   = false
        singleTruckThread    = nil
        stopTruckBtn.Visible = false
    end)
end)

-- Cleanup for single truck thread
table.insert(VH.cleanupTasks, function()
    singleTruckRunning = false
    if singleTruckThread then pcall(task.cancel, singleTruckThread); singleTruckThread = nil end
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- BATCH TRUCK TELEPORT (Dupe Tab — teleport a specific number of trucks)
-- ════════════════════════════════════════════════════════════════════════════════

makeSep(dupePage)
makeLabel(dupePage, "Batch Truck Teleport")

local _, getBatchGiverName    = makeDupeDropdown("Giver",    dupePage)
local _, getBatchReceiverName = makeDupeDropdown("Receiver", dupePage)

-- ── Truck count input row ─────────────────────────────────────────────────────
local batchCountRow = Instance.new("Frame", dupePage)
batchCountRow.Size             = UDim2.new(1, -12, 0, 36)
batchCountRow.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
batchCountRow.BorderSizePixel  = 0
Instance.new("UICorner", batchCountRow).CornerRadius = UDim.new(0, 8)
local batchRowStroke = Instance.new("UIStroke", batchCountRow)
batchRowStroke.Color        = Color3.fromRGB(60, 60, 90)
batchRowStroke.Thickness    = 1
batchRowStroke.Transparency = 0.5

local batchCountLbl = Instance.new("TextLabel", batchCountRow)
batchCountLbl.Size               = UDim2.new(1, -80, 1, 0)
batchCountLbl.Position           = UDim2.new(0, 12, 0, 0)
batchCountLbl.BackgroundTransparency = 1
batchCountLbl.Font               = Enum.Font.GothamSemibold
batchCountLbl.TextSize           = 13
batchCountLbl.TextColor3         = THEME_TEXT
batchCountLbl.TextXAlignment     = Enum.TextXAlignment.Left
batchCountLbl.Text               = "Trucks to Teleport"

local batchCountBox = Instance.new("TextBox", batchCountRow)
batchCountBox.Size               = UDim2.new(0, 60, 0, 24)
batchCountBox.Position           = UDim2.new(1, -68, 0.5, -12)
batchCountBox.BackgroundColor3   = Color3.fromRGB(30, 30, 45)
batchCountBox.BorderSizePixel    = 0
batchCountBox.Font               = Enum.Font.GothamBold
batchCountBox.TextSize           = 13
batchCountBox.TextColor3         = THEME_TEXT
batchCountBox.PlaceholderText    = "e.g. 3"
batchCountBox.PlaceholderColor3  = Color3.fromRGB(80, 80, 110)
batchCountBox.Text               = ""
batchCountBox.TextXAlignment     = Enum.TextXAlignment.Center
batchCountBox.ClearTextOnFocus   = false
Instance.new("UICorner", batchCountBox).CornerRadius = UDim.new(0, 6)
local batchBoxStroke = Instance.new("UIStroke", batchCountBox)
batchBoxStroke.Color        = Color3.fromRGB(70, 70, 120)
batchBoxStroke.Thickness    = 1
batchBoxStroke.Transparency = 0.4

-- Only allow numeric input
batchCountBox:GetPropertyChangedSignal("Text"):Connect(function()
    local clean = batchCountBox.Text:gsub("[^%d]", "")
    if clean ~= batchCountBox.Text then batchCountBox.Text = clean end
end)

-- ── Status bar ────────────────────────────────────────────────────────────────
local batchStatusBar = Instance.new("Frame", dupePage)
batchStatusBar.Size             = UDim2.new(1, -12, 0, 28)
batchStatusBar.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
batchStatusBar.BorderSizePixel  = 0
Instance.new("UICorner", batchStatusBar).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", batchStatusBar).Color = Color3.fromRGB(50, 50, 70)

local batchStatusDot = Instance.new("Frame", batchStatusBar)
batchStatusDot.Size             = UDim2.new(0, 8, 0, 8)
batchStatusDot.Position         = UDim2.new(0, 10, 0.5, -4)
batchStatusDot.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
batchStatusDot.BorderSizePixel  = 0
Instance.new("UICorner", batchStatusDot).CornerRadius = UDim.new(1, 0)

local batchStatusLbl = Instance.new("TextLabel", batchStatusBar)
batchStatusLbl.Size                   = UDim2.new(1, -28, 1, 0)
batchStatusLbl.Position               = UDim2.new(0, 26, 0, 0)
batchStatusLbl.BackgroundTransparency = 1
batchStatusLbl.Font                   = Enum.Font.Gotham
batchStatusLbl.TextSize               = 12
batchStatusLbl.TextColor3             = Color3.fromRGB(160, 155, 175)
batchStatusLbl.TextXAlignment         = Enum.TextXAlignment.Left
batchStatusLbl.Text                   = "Ready — enter a truck count"

local function setBatchStatus(msg, active)
    batchStatusLbl.Text = msg
    TweenService:Create(batchStatusDot, TweenInfo.new(0.2), {
        BackgroundColor3 = active
            and Color3.fromRGB(80, 200, 100)
            or  Color3.fromRGB(100, 100, 120)
    }):Play()
end

-- ── Progress bars ─────────────────────────────────────────────────────────────
local batchTruckProgBar, setBatchTruckProg, resetBatchTruckProg =
    makeProgressBar(dupePage, "Trucks")
local batchCargoProgBar, setBatchCargoProg, resetBatchCargoProg =
    makeProgressBar(dupePage, "Missed Cargo")

-- ── State ─────────────────────────────────────────────────────────────────────
local batchTruckRunning = false
local batchTruckThread  = nil

-- ── Stop button ───────────────────────────────────────────────────────────────
local stopBatchBtn = makeBtn(dupePage, "■  Stop Batch", Color3.fromRGB(65, 25, 25), function()
    batchTruckRunning = false
    if batchTruckThread then
        pcall(task.cancel, batchTruckThread)
        batchTruckThread = nil
    end
    setBatchStatus("Stopped", false)
    resetBatchTruckProg()
    resetBatchCargoProg()
    stopBatchBtn.Visible = false
end)
stopBatchBtn.Visible = false

-- ── Run button ────────────────────────────────────────────────────────────────
makeBtn(dupePage, "▶  Teleport Batch", Color3.fromRGB(35, 55, 65), function()
    if batchTruckRunning then setBatchStatus("Already running!", true) return end

    -- ── Validate player selection ─────────────────────────────────────────
    local gName = getBatchGiverName()
    local rName = getBatchReceiverName()
    if gName == "" or rName == "" then
        setBatchStatus("Select both players!", false) return
    end

    -- ── Validate count input ──────────────────────────────────────────────
    local wantedCount = tonumber(batchCountBox.Text)
    if not wantedCount or wantedCount < 1 then
        setBatchStatus("⚠ Enter a valid truck count!", false) return
    end
    wantedCount = math.floor(wantedCount)

    -- ── Count available trucks on giver's plot ────────────────────────────
    local availableTrucks = {}
    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
        if v.Name == "Owner" and tostring(v.Value) == gName
            and v.Parent:FindFirstChild("DriveSeat") then
            table.insert(availableTrucks, v.Parent)
        end
    end
    local actualCount = #availableTrucks

    if actualCount == 0 then
        setBatchStatus("⚠ No trucks found on giver's plot!", false) return
    end

    if wantedCount < actualCount then
        setBatchStatus(string.format(
            "⚠ You entered %d but giver has %d trucks — teleporting %d",
            wantedCount, actualCount, wantedCount), false)
        -- Trim the list to only the requested amount
        while #availableTrucks > wantedCount do
            table.remove(availableTrucks)
        end
        task.wait(2) -- let the user read the message before starting
    elseif wantedCount > actualCount then
        setBatchStatus(string.format(
            "⚠ You entered %d but only %d truck(s) found — teleporting %d",
            wantedCount, actualCount, actualCount), false)
        -- wantedCount is too high; we'll just do however many exist
        wantedCount = actualCount
        task.wait(2)
    end

    -- ── Find bases ────────────────────────────────────────────────────────
    local GiveBaseOrigin, ReceiverBaseOrigin
    for _, v in pairs(workspace.Properties:GetDescendants()) do
        if v.Name == "Owner" then
            local val = tostring(v.Value)
            if val == gName then GiveBaseOrigin     = v.Parent:FindFirstChild("OriginSquare") end
            if val == rName then ReceiverBaseOrigin = v.Parent:FindFirstChild("OriginSquare") end
        end
    end
    if not GiveBaseOrigin     then setBatchStatus("Giver base not found!",    false) return end
    if not ReceiverBaseOrigin then setBatchStatus("Receiver base not found!", false) return end

    -- ── All checks passed — kick off the thread ───────────────────────────
    batchTruckRunning    = true
    stopBatchBtn.Visible = true
    resetBatchTruckProg()
    resetBatchCargoProg()
    setBatchStatus(string.format("Starting — %d truck(s) queued...", #availableTrucks), true)

    batchTruckThread = task.spawn(function()
        local RS   = game:GetService("ReplicatedStorage")
        local LP   = Players.LocalPlayer
        local Char = LP.Character or LP.CharacterAdded:Wait()

        local function isPointInside(point, boxCFrame, boxSize)
            local r = boxCFrame:PointToObjectSpace(point)
            return math.abs(r.X) <= boxSize.X / 2
               and math.abs(r.Y) <= boxSize.Y / 2 + 2
               and math.abs(r.Z) <= boxSize.Z / 2
        end

        -- Collect ALL teleported cargo parts across every truck
        local allTeleportedParts = {}

        batchTruckProgBar.Visible = true
        setBatchTruckProg(0, #availableTrucks)

        -- ── Phase 1: teleport each truck (and its cargo) ──────────────────
        local trucksDone = 0
        for _, truckModel in ipairs(availableTrucks) do
            if not batchTruckRunning then break end
            if not (truckModel and truckModel.Parent) then
                trucksDone += 1
                setBatchTruckProg(trucksDone, #availableTrucks)
                continue
            end

            setBatchStatus(string.format(
                "Teleporting truck %d / %d...", trucksDone + 1, #availableTrucks), true)

            local ignoredParts     = {}
            local DidTruckTeleport = false

            local function TeleportThisTruck()
                if DidTruckTeleport then return end
                if not Char.Humanoid.SeatPart then return end
                local TCF  = Char.Humanoid.SeatPart.Parent:FindFirstChild("Main").CFrame
                local nPos = TCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                Char.Humanoid.SeatPart.Parent:SetPrimaryPartCFrame(CFrame.new(nPos) * TCF.Rotation)
                DidTruckTeleport = true
            end

            truckModel.DriveSeat:Sit(Char.Humanoid)
            repeat task.wait() truckModel.DriveSeat:Sit(Char.Humanoid) until Char.Humanoid.SeatPart

            local mCF, mSz = truckModel:GetBoundingBox()

            for _, p in ipairs(truckModel:GetDescendants()) do
                if p:IsA("BasePart") then ignoredParts[p] = true end
            end
            for _, p in ipairs(Char:GetDescendants()) do
                if p:IsA("BasePart") then ignoredParts[p] = true end
            end

            -- Scan workspace for cargo inside this truck's bounding box
            for _, part in ipairs(workspace:GetDescendants()) do
                if not batchTruckRunning then break end
                if part:IsA("BasePart") and not ignoredParts[part] then
                    if part.Name == "Main" or part.Name == "WoodSection" then
                        if part:FindFirstChild("Weld")
                            and part.Weld.Part1
                            and part.Weld.Part1.Parent ~= part.Parent then
                            continue
                        end
                        task.spawn(function()
                            if isPointInside(part.Position, mCF, mSz) then
                                TeleportThisTruck()
                                local PCF  = part.CFrame
                                local nP   = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                                local tOff = CFrame.new(nP) * PCF.Rotation
                                part.CFrame = tOff
                                task.wait(0.3)
                                table.insert(allTeleportedParts, {
                                    Instance     = part,
                                    OldPos       = part.Position,
                                    TargetCFrame = tOff,
                                })
                            end
                        end)
                    end
                end
            end

            -- Eject, destroy seat, close door, re-teleport truck
            local SitPart   = Char.Humanoid.SeatPart
            local DoorHinge = SitPart.Parent:FindFirstChild("PaintParts")
                and SitPart.Parent.PaintParts:FindFirstChild("DoorLeft")
                and SitPart.Parent.PaintParts.DoorLeft:FindFirstChild("ButtonRemote_Hinge")
            task.wait()
            Char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            task.wait(0.1)
            SitPart:Destroy()
            TeleportThisTruck()
            DidTruckTeleport = false
            task.wait(0.1)
            if DoorHinge then
                for i = 1, 10 do RS.Interaction.RemoteProxy:FireServer(DoorHinge) end
            end

            trucksDone += 1
            setBatchTruckProg(trucksDone, #availableTrucks)
            task.wait(0.3)
        end

        -- ── Phase 2: retry missed cargo across all trucks ──────────────────
        task.wait(2) -- let task.spawns finish recording

        local function getMissedBatch()
            local missed = {}
            for _, data in ipairs(allTeleportedParts) do
                if data.Instance and data.Instance.Parent then
                    local dist = (data.Instance.Position - data.TargetCFrame.Position).Magnitude
                    if dist > 8 then
                        local distFromGiver = (data.Instance.Position - GiveBaseOrigin.Position).Magnitude
                        if distFromGiver < 500 then
                            table.insert(missed, data)
                        end
                    end
                end
            end
            return missed
        end

        local missedList = getMissedBatch()

        if #missedList > 0 then
            batchCargoProgBar.Visible = true
            setBatchCargoProg(0, #missedList)
            local missedTotal = #missedList
            local MAX_TRIES   = 25
            local attempt     = 0
            local itemsDone   = 0

            while #missedList > 0 and batchTruckRunning and attempt < MAX_TRIES do
                attempt += 1
                setBatchStatus(string.format(
                    "Cargo retry %d/%d — %d part(s) left...", attempt, MAX_TRIES, #missedList), true)

                for _, data in ipairs(missedList) do
                    if not batchTruckRunning then break end
                    local item = data.Instance
                    if not (item and item.Parent) then continue end

                    local tries = 0
                    while (Char.HumanoidRootPart.Position - item.Position).Magnitude > 25 and tries < 15 do
                        Char.HumanoidRootPart.CFrame = item.CFrame
                        task.wait(0.1)
                        tries += 1
                    end

                    RS.Interaction.ClientIsDragging:FireServer(item.Parent)
                    task.wait(0.6)
                    item.CFrame = data.TargetCFrame
                    task.wait(0.3)

                    itemsDone += 1
                    setBatchCargoProg(itemsDone, missedTotal)
                    task.wait()
                end

                task.wait(1)
                missedList = getMissedBatch()
                local confirmed = missedTotal - #missedList
                if confirmed > itemsDone then
                    itemsDone = confirmed
                    setBatchCargoProg(itemsDone, missedTotal)
                end
            end

            if #missedList == 0 then
                setBatchStatus("✓ All trucks + cargo teleported!", true)
            else
                setBatchStatus(string.format(
                    "Gave up after %d tries — %d part(s) missed", MAX_TRIES, #missedList), false)
            end

            setBatchCargoProg(missedTotal, missedTotal)
        else
            setBatchStatus(string.format("✓ %d truck(s) teleported! (no missed cargo)", trucksDone), false)
        end

        task.wait(1)
        batchTruckRunning    = false
        batchTruckThread     = nil
        stopBatchBtn.Visible = false
    end)
end)

-- Cleanup for batch truck thread
table.insert(VH.cleanupTasks, function()
    batchTruckRunning = false
    if batchTruckThread then pcall(task.cancel, batchTruckThread); batchTruckThread = nil end
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- WORLD TAB
-- ════════════════════════════════════════════════════════════════════════════════

local Lighting   = game:GetService("Lighting")
local RunService = game:GetService("RunService")

-- ── Snapshot original Lighting values ─────────────────────────────────────────
local origClockTime = Lighting.ClockTime
local origFogEnd    = Lighting.FogEnd
local origFogStart  = Lighting.FogStart
local origFogColor  = Lighting.FogColor
local origShadows   = Lighting.GlobalShadows

-- ── Shared connection handles ──────────────────────────────────────────────────
local dayConn   = nil
local nightConn = nil
local fogConn   = nil

local function stopDayNight()
    if dayConn   then dayConn:Disconnect();   dayConn   = nil end
    if nightConn then nightConn:Disconnect(); nightConn = nil end
end

-- ── ENVIRONMENT ───────────────────────────────────────────────────────────────
makeLabel(worldPage, "Environment")

-- Always Day
local _, _, alwaysDayTb, alwaysDayKnob = makeToggle(worldPage, "Always Day", false, function(v)
    if v then
        stopDayNight()
        Lighting.ClockTime = 14
        dayConn = RunService.Heartbeat:Connect(function()
            Lighting.ClockTime = 14
        end)
    else
        if dayConn then dayConn:Disconnect(); dayConn = nil end
        Lighting.ClockTime = origClockTime
    end
end)

-- Auto-enable Always Day 1 second after load
task.delay(1, function()
    stopDayNight()
    Lighting.ClockTime = 14
    dayConn = RunService.Heartbeat:Connect(function()
        Lighting.ClockTime = 14
    end)
    if alwaysDayTb and alwaysDayKnob then
        TweenService:Create(alwaysDayTb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            BackgroundColor3 = Color3.fromRGB(60, 180, 60)
        }):Play()
        TweenService:Create(alwaysDayKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, 18, 0.5, -7)
        }):Play()
    end
end)

-- Always Night (mutually exclusive with Always Day)
makeToggle(worldPage, "Always Night", false, function(v)
    if v then
        stopDayNight()
        Lighting.ClockTime = 0
        nightConn = RunService.Heartbeat:Connect(function()
            Lighting.ClockTime = 0
        end)
    else
        if nightConn then nightConn:Disconnect(); nightConn = nil end
        Lighting.ClockTime = origClockTime
    end
end)

-- Remove Fog — Heartbeat-enforced so the server can't reset it
makeToggle(worldPage, "Remove Fog", false, function(v)
    if fogConn then fogConn:Disconnect(); fogConn = nil end
    if v then
        Lighting.FogEnd   = 1e9
        Lighting.FogStart = 1e9
        fogConn = RunService.Heartbeat:Connect(function()
            Lighting.FogEnd   = 1e9
            Lighting.FogStart = 1e9
        end)
    else
        Lighting.FogEnd   = origFogEnd
        Lighting.FogStart = origFogStart
        Lighting.FogColor = origFogColor
    end
end)

-- Shadows
makeToggle(worldPage, "Shadows", true, function(v)
    Lighting.GlobalShadows = v
end)

-- ── WATER ─────────────────────────────────────────────────────────────────────
makeSep(worldPage)
makeLabel(worldPage, "Water")

local walkOnWaterConn  = nil
local walkOnWaterParts = {}

local function removeWalkWater()
    if walkOnWaterConn then walkOnWaterConn:Disconnect(); walkOnWaterConn = nil end
    for _, p in ipairs(walkOnWaterParts) do
        if p and p.Parent then p:Destroy() end
    end
    walkOnWaterParts = {}
end

makeToggle(worldPage, "Walk On Water", false, function(v)
    removeWalkWater()
    if v then
        local function makeSolid(part)
            if part:IsA("Part") and part.Name == "Water" then
                local clone = Instance.new("Part")
                clone.Size         = part.Size
                clone.CFrame       = part.CFrame
                clone.Anchored     = true
                clone.CanCollide   = true
                clone.Transparency = 1
                clone.Name         = "WalkWaterPlane"
                clone.Parent       = workspace
                table.insert(walkOnWaterParts, clone)
            end
        end
        for _, p in ipairs(workspace:GetDescendants()) do makeSolid(p) end
        walkOnWaterConn = workspace.DescendantAdded:Connect(makeSolid)
    end
end)

makeToggle(worldPage, "Remove Water", false, function(v)
    if _G.VH and _G.VH.setRemovedWater then _G.VH.setRemovedWater(v) end
    for _, p in ipairs(workspace:GetDescendants()) do
        if p:IsA("Part") and p.Name == "Water" then
            p.Transparency = v and 1 or 0.5
            p.CanCollide   = false
        end
    end
end)

-- ── WORLD (reserved) ──────────────────────────────────────────────────────────
makeSep(worldPage)
makeLabel(worldPage, "World")
-- reserved for future features

-- ── Cleanup (World Tab) ────────────────────────────────────────────────────────
table.insert(VH.cleanupTasks, function()
    stopDayNight()
    if fogConn then fogConn:Disconnect(); fogConn = nil end
    removeWalkWater()
    Lighting.ClockTime     = origClockTime
    Lighting.FogEnd        = origFogEnd
    Lighting.FogStart      = origFogStart
    Lighting.FogColor      = origFogColor
    Lighting.GlobalShadows = origShadows
end)

-- ════════════════════════════════════════════════════════════════════════════════
print("[VanillaHub] Combined (Vanilla2 + WorldTab) loaded")
