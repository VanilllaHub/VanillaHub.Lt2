-- ════════════════════════════════════════════════════════════════════════════════
-- VANILLA COMBINED — Vanilla2 (Butter Leak / Dupe Tab)
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
-- THEME  (Black / Grey / White only)
-- ════════════════════════════════════════════════════════════════════════════════

local C = {
    BG_DEEP      = Color3.fromRGB(8,   8,   8  ),
    BG_PANEL     = Color3.fromRGB(15,  15,  15 ),
    BG_ROW       = Color3.fromRGB(22,  22,  22 ),
    BG_INPUT     = Color3.fromRGB(32,  32,  32 ),
    BORDER       = Color3.fromRGB(55,  55,  55 ),
    BORDER_FOCUS = Color3.fromRGB(100, 100, 100),
    TEXT_DIM     = Color3.fromRGB(100, 100, 100),
    TEXT_MID     = Color3.fromRGB(155, 155, 155),
    TEXT_BRIGHT  = Color3.fromRGB(210, 210, 210),
    TEXT_WHITE   = Color3.fromRGB(240, 240, 240),
    KNOB         = Color3.fromRGB(30,  30,  30 ),
    KNOB_OFF     = Color3.fromRGB(160, 160, 160),
    TOGGLE_ON    = Color3.fromRGB(220, 220, 220),
    TOGGLE_OFF   = Color3.fromRGB(50,  50,  50 ),
    BTN_START    = Color3.fromRGB(14,  14,  14),
    BTN_START_HV = Color3.fromRGB(32,  32,  32),
    BTN_STOP     = Color3.fromRGB(14,  14,  14),
    BTN_STOP_HV  = Color3.fromRGB(32,  32,  32),
    BTN_IDLE     = Color3.fromRGB(14,  14,  14),
    BTN_IDLE_HV  = Color3.fromRGB(32,  32,  32),
    DOT_IDLE     = Color3.fromRGB(70,  70,  70 ),
    DOT_ACTIVE   = Color3.fromRGB(200, 200, 200),
    PROG_TRACK   = Color3.fromRGB(30,  30,  30 ),
    PROG_FILL    = Color3.fromRGB(255, 255, 255),
    PROG_DONE    = Color3.fromRGB(255, 255, 255),
    TAB_ACTIVE   = Color3.fromRGB(38,  38,  38),
    TAB_IDLE     = Color3.fromRGB(12,  12,  12),
    TAB_HOVER    = Color3.fromRGB(28,  28,  28),
}

-- ════════════════════════════════════════════════════════════════════════════════
-- SHARED UI HELPERS
-- ════════════════════════════════════════════════════════════════════════════════

local function makeLabel(parent, text)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size               = UDim2.new(1, -12, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 10
    lbl.TextColor3         = C.TEXT_DIM
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 6)
    return lbl
end

local function makeSep(parent)
    local f = Instance.new("Frame", parent)
    f.Size             = UDim2.new(1, -12, 0, 1)
    f.BackgroundColor3 = C.BORDER
    f.BorderSizePixel  = 0
    return f
end

local function applyHover(btn, base, hover)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = hover}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = base}):Play()
    end)
end

local function makeBtn(parent, text, color, hoverColor, callback)
    color      = color      or C.BTN_IDLE
    hoverColor = hoverColor or C.BTN_IDLE_HV
    local btn = Instance.new("TextButton", parent)
    btn.Size             = UDim2.new(1, -12, 0, 32)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel  = 0
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.TextColor3       = C.TEXT_BRIGHT
    btn.Text             = text
    btn.AutoButtonColor  = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local btnStr = Instance.new("UIStroke", btn)
    btnStr.Color        = Color3.fromRGB(55, 55, 55)
    btnStr.Thickness    = 1
    btnStr.Transparency = 0
    applyHover(btn, color, hoverColor)
    if callback then btn.MouseButton1Click:Connect(callback) end
    return btn
end

local function makeStartStop(parent, startCb, stopCb)
    local row = Instance.new("Frame", parent)
    row.Size             = UDim2.new(1, -12, 0, 34)
    row.BackgroundTransparency = 1
    row.BorderSizePixel  = 0

    local rl = Instance.new("UIListLayout", row)
    rl.FillDirection = Enum.FillDirection.Horizontal
    rl.SortOrder     = Enum.SortOrder.LayoutOrder
    rl.Padding       = UDim.new(0, 6)

    local function half(text, base, hover, cb, order)
        local btn = Instance.new("TextButton", row)
        btn.Size             = UDim2.new(0.5, -3, 1, 0)
        btn.BackgroundColor3 = base
        btn.BorderSizePixel  = 0
        btn.Font             = Enum.Font.GothamBold
        btn.TextSize         = 13
        btn.TextColor3       = C.TEXT_BRIGHT
        btn.Text             = text
        btn.AutoButtonColor  = false
        btn.LayoutOrder      = order
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        local btnStr = Instance.new("UIStroke", btn)
        btnStr.Color        = Color3.fromRGB(55, 55, 55)
        btnStr.Thickness    = 1
        btnStr.Transparency = 0
        applyHover(btn, base, hover)
        if cb then btn.MouseButton1Click:Connect(cb) end
        return btn
    end

    local startBtn = half("▶  Start", C.BTN_START, C.BTN_START_HV, startCb, 1)
    local stopBtn  = half("■  Stop",  C.BTN_STOP,  C.BTN_STOP_HV,  stopCb,  2)
    return row, startBtn, stopBtn
end

local function makeStatusBar(parent, defaultText)
    local bar = Instance.new("Frame", parent)
    bar.Size             = UDim2.new(1, -12, 0, 26)
    bar.BackgroundColor3 = C.BG_PANEL
    bar.BorderSizePixel  = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", bar)
    stroke.Color     = C.BORDER
    stroke.Thickness = 1

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

local function makeToggle(parent, text, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size             = UDim2.new(1, -12, 0, 30)
    frame.BackgroundColor3 = C.BG_ROW
    frame.BorderSizePixel  = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size               = UDim2.new(1, -50, 1, 0)
    lbl.Position           = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamSemibold
    lbl.TextSize           = 12
    lbl.TextColor3         = C.TEXT_BRIGHT
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = text

    local tb = Instance.new("TextButton", frame)
    tb.Size             = UDim2.new(0, 32, 0, 17)
    tb.Position         = UDim2.new(1, -42, 0.5, -8.5)
    tb.BackgroundColor3 = default and C.TOGGLE_ON or C.TOGGLE_OFF
    tb.Text             = ""
    tb.BorderSizePixel  = 0
    tb.AutoButtonColor  = false
    Instance.new("UICorner", tb).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", tb)
    knob.Size             = UDim2.new(0, 13, 0, 13)
    knob.Position         = UDim2.new(0, default and 17 or 2, 0.5, -6.5)
    knob.BackgroundColor3 = default and C.KNOB or C.KNOB_OFF
    knob.BorderSizePixel  = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local toggled = default
    if callback then callback(toggled) end

    tb.MouseButton1Click:Connect(function()
        toggled = not toggled
        TweenService:Create(tb,   TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
            BackgroundColor3 = toggled and C.TOGGLE_ON or C.TOGGLE_OFF
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
            Position         = UDim2.new(0, toggled and 17 or 2, 0.5, -6.5),
            BackgroundColor3 = toggled and C.KNOB or C.KNOB_OFF
        }):Play()
        if callback then callback(toggled) end
    end)

    return frame, function() return toggled end, tb, knob
end

local function makeProgressBar(parent, labelText)
    local wrap = Instance.new("Frame", parent)
    wrap.Size             = UDim2.new(1, -12, 0, 42)
    wrap.BackgroundColor3 = C.BG_PANEL
    wrap.BorderSizePixel  = 0
    wrap.Visible          = false
    Instance.new("UICorner", wrap).CornerRadius = UDim.new(0, 7)
    local stroke = Instance.new("UIStroke", wrap)
    stroke.Color        = C.BORDER
    stroke.Thickness    = 1
    stroke.Transparency = 0.4

    local topRow = Instance.new("Frame", wrap)
    topRow.Size                 = UDim2.new(1, -12, 0, 17)
    topRow.Position             = UDim2.new(0, 6, 0, 4)
    topRow.BackgroundTransparency = 1

    local nameLbl = Instance.new("TextLabel", topRow)
    nameLbl.Size               = UDim2.new(0.65, 0, 1, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font               = Enum.Font.GothamSemibold
    nameLbl.TextSize           = 11
    nameLbl.TextColor3         = C.TEXT_BRIGHT
    nameLbl.TextXAlignment     = Enum.TextXAlignment.Left
    nameLbl.Text               = labelText

    local cntLbl = Instance.new("TextLabel", topRow)
    cntLbl.Size               = UDim2.new(0.35, 0, 1, 0)
    cntLbl.Position           = UDim2.new(0.65, 0, 0, 0)
    cntLbl.BackgroundTransparency = 1
    cntLbl.Font               = Enum.Font.GothamBold
    cntLbl.TextSize           = 11
    cntLbl.TextColor3         = C.TEXT_WHITE
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
        if resetTimer then task.cancel(resetTimer) resetTimer = nil end
        fill.Size             = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = C.PROG_FILL
        cntLbl.Text           = "0 / 0"
        cntLbl.TextColor3     = C.TEXT_WHITE
        wrap.Visible          = false
    end

    local function setProgress(done, total)
        local pct = math.clamp(done / math.max(total, 1), 0, 1)
        if done >= total and total > 0 then
            cntLbl.Text       = "Done"
            cntLbl.TextColor3 = C.TEXT_WHITE
            TweenService:Create(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = C.PROG_FILL,
            }):Play()
            if resetTimer then task.cancel(resetTimer) end
            resetTimer = task.delay(2, reset)
        else
            cntLbl.Text       = done .. " / " .. total
            cntLbl.TextColor3 = C.TEXT_WHITE
            TweenService:Create(fill, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                Size             = UDim2.new(pct, 0, 1, 0),
                BackgroundColor3 = C.PROG_FILL,
            }):Play()
        end
    end

    return wrap, setProgress, reset
end

local function makeDupeDropdown(labelText, parentPage)
    local selected = ""
    local isOpen   = false
    local ITEM_H   = 32
    local MAX_SHOW = 5
    local HEADER_H = 38

    local outer = Instance.new("Frame", parentPage)
    outer.Size             = UDim2.new(1, -12, 0, HEADER_H)
    outer.BackgroundColor3 = C.BG_ROW
    outer.BorderSizePixel  = 0
    outer.ClipsDescendants = true
    Instance.new("UICorner", outer).CornerRadius = UDim.new(0, 7)
    local outerStroke = Instance.new("UIStroke", outer)
    outerStroke.Color        = C.BORDER
    outerStroke.Thickness    = 1
    outerStroke.Transparency = 0.3

    local header = Instance.new("Frame", outer)
    header.Size                   = UDim2.new(1, 0, 0, HEADER_H)
    header.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", header)
    lbl.Size               = UDim2.new(0, 76, 1, 0)
    lbl.Position           = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = labelText
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 11
    lbl.TextColor3         = C.TEXT_DIM
    lbl.TextXAlignment     = Enum.TextXAlignment.Left

    local selFrame = Instance.new("Frame", header)
    selFrame.Size             = UDim2.new(1, -92, 0, 26)
    selFrame.Position         = UDim2.new(0, 84, 0.5, -13)
    selFrame.BackgroundColor3 = C.BG_INPUT
    selFrame.BorderSizePixel  = 0
    Instance.new("UICorner", selFrame).CornerRadius = UDim.new(0, 5)
    local selStroke = Instance.new("UIStroke", selFrame)
    selStroke.Color        = C.BORDER
    selStroke.Thickness    = 1
    selStroke.Transparency = 0.3

    local avatar = Instance.new("ImageLabel", selFrame)
    avatar.Size             = UDim2.new(0, 18, 0, 18)
    avatar.Position         = UDim2.new(0, 5, 0.5, -9)
    avatar.BackgroundColor3 = C.BG_INPUT
    avatar.BorderSizePixel  = 0
    avatar.Image            = ""
    avatar.ScaleType        = Enum.ScaleType.Crop
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

    local selLbl = Instance.new("TextLabel", selFrame)
    selLbl.Size               = UDim2.new(1, -50, 1, 0)
    selLbl.Position           = UDim2.new(0, 28, 0, 0)
    selLbl.BackgroundTransparency = 1
    selLbl.Text               = "Select player..."
    selLbl.Font               = Enum.Font.GothamSemibold
    selLbl.TextSize           = 11
    selLbl.TextColor3         = C.TEXT_DIM
    selLbl.TextXAlignment     = Enum.TextXAlignment.Left
    selLbl.TextTruncate       = Enum.TextTruncate.AtEnd

    local arrowLbl = Instance.new("TextLabel", selFrame)
    arrowLbl.Size               = UDim2.new(0, 20, 1, 0)
    arrowLbl.Position           = UDim2.new(1, -22, 0, 0)
    arrowLbl.BackgroundTransparency = 1
    arrowLbl.Text               = "▾"
    arrowLbl.Font               = Enum.Font.GothamBold
    arrowLbl.TextSize           = 13
    arrowLbl.TextColor3         = C.TEXT_DIM
    arrowLbl.TextXAlignment     = Enum.TextXAlignment.Center

    local headerBtn = Instance.new("TextButton", selFrame)
    headerBtn.Size               = UDim2.new(1, 0, 1, 0)
    headerBtn.BackgroundTransparency = 1
    headerBtn.Text               = ""
    headerBtn.AutoButtonColor    = false
    headerBtn.ZIndex             = 5

    local divider = Instance.new("Frame", outer)
    divider.Size             = UDim2.new(1, -14, 0, 1)
    divider.Position         = UDim2.new(0, 7, 0, HEADER_H)
    divider.BackgroundColor3 = C.BORDER
    divider.BorderSizePixel  = 0
    divider.Visible          = false

    local listScroll = Instance.new("ScrollingFrame", outer)
    listScroll.Position               = UDim2.new(0, 0, 0, HEADER_H + 2)
    listScroll.Size                   = UDim2.new(1, 0, 0, 0)
    listScroll.BackgroundTransparency = 1
    listScroll.BorderSizePixel        = 0
    listScroll.ScrollBarThickness     = 3
    listScroll.ScrollBarImageColor3   = C.BORDER_FOCUS
    listScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
    listScroll.ClipsDescendants       = true

    local listLayout = Instance.new("UIListLayout", listScroll)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding   = UDim.new(0, 2)
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 6)
    end)
    local listPad = Instance.new("UIPadding", listScroll)
    listPad.PaddingTop    = UDim.new(0, 3)
    listPad.PaddingBottom = UDim.new(0, 3)
    listPad.PaddingLeft   = UDim.new(0, 5)
    listPad.PaddingRight  = UDim.new(0, 5)

    local function setSelected(name, userId)
        selected            = name
        selLbl.Text         = name
        selLbl.TextColor3   = C.TEXT_BRIGHT
        arrowLbl.TextColor3 = C.TEXT_MID
        outerStroke.Color   = C.BORDER_FOCUS
        if userId then
            task.spawn(function()
                pcall(function()
                    avatar.Image = Players:GetUserThumbnailAsync(
                        userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                end)
            end)
        end
    end

    local function clearSelected()
        selected            = ""
        selLbl.Text         = "Select player..."
        selLbl.TextColor3   = C.TEXT_DIM
        avatar.Image        = ""
        arrowLbl.TextColor3 = C.TEXT_DIM
        outerStroke.Color   = C.BORDER
    end

    local function closeList()
        isOpen = false
        TweenService:Create(arrowLbl,   TweenInfo.new(0.18, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
        TweenService:Create(outer,      TweenInfo.new(0.20, Enum.EasingStyle.Quint), {Size = UDim2.new(1,-12,0,HEADER_H)}):Play()
        TweenService:Create(listScroll, TweenInfo.new(0.20, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,0)}):Play()
        divider.Visible = false
    end

    local function buildList()
        for _, c in ipairs(listScroll:GetChildren()) do
            if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
        end
        local playerList = Players:GetPlayers()
        table.sort(playerList, function(a, b) return a.Name < b.Name end)
        for i, plr in ipairs(playerList) do
            local isSel = (plr.Name == selected)
            local row = Instance.new("Frame", listScroll)
            row.Size             = UDim2.new(1, 0, 0, ITEM_H)
            row.BackgroundColor3 = isSel and Color3.fromRGB(60,60,60) or C.BG_ROW
            row.BorderSizePixel  = 0
            row.LayoutOrder      = i
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)

            local miniAvatar = Instance.new("ImageLabel", row)
            miniAvatar.Size             = UDim2.new(0, 20, 0, 20)
            miniAvatar.Position         = UDim2.new(0, 6, 0.5, -10)
            miniAvatar.BackgroundColor3 = C.BG_INPUT
            miniAvatar.BorderSizePixel  = 0
            miniAvatar.ScaleType        = Enum.ScaleType.Crop
            Instance.new("UICorner", miniAvatar).CornerRadius = UDim.new(1, 0)
            task.spawn(function()
                pcall(function()
                    miniAvatar.Image = Players:GetUserThumbnailAsync(
                        plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                end)
            end)

            local nameLbl2 = Instance.new("TextLabel", row)
            nameLbl2.Size               = UDim2.new(1, -58, 1, 0)
            nameLbl2.Position           = UDim2.new(0, 32, 0, 0)
            nameLbl2.BackgroundTransparency = 1
            nameLbl2.Text               = plr.Name
            nameLbl2.Font               = Enum.Font.GothamSemibold
            nameLbl2.TextSize           = 12
            nameLbl2.TextColor3         = isSel and C.TEXT_BRIGHT or C.TEXT_MID
            nameLbl2.TextXAlignment     = Enum.TextXAlignment.Left
            nameLbl2.TextTruncate       = Enum.TextTruncate.AtEnd

            if isSel then
                local check = Instance.new("TextLabel", row)
                check.Size               = UDim2.new(0, 22, 1, 0)
                check.Position           = UDim2.new(1, -26, 0, 0)
                check.BackgroundTransparency = 1
                check.Text               = "✓"
                check.Font               = Enum.Font.GothamBold
                check.TextSize           = 13
                check.TextColor3         = C.TEXT_WHITE
                check.TextXAlignment     = Enum.TextXAlignment.Center
            end

            local rowBtn = Instance.new("TextButton", row)
            rowBtn.Size               = UDim2.new(1, 0, 1, 0)
            rowBtn.BackgroundTransparency = 1
            rowBtn.Text               = ""
            rowBtn.AutoButtonColor    = false
            rowBtn.ZIndex             = 5
            rowBtn.MouseEnter:Connect(function()
                if plr.Name ~= selected then
                    TweenService:Create(row, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(40,40,40)}):Play()
                end
            end)
            rowBtn.MouseLeave:Connect(function()
                if plr.Name ~= selected then
                    TweenService:Create(row, TweenInfo.new(0.08), {BackgroundColor3 = C.BG_ROW}):Play()
                end
            end)
            rowBtn.MouseButton1Click:Connect(function()
                if plr.Name == selected then clearSelected() else setSelected(plr.Name, plr.UserId) end
                buildList()
                task.delay(0.04, closeList)
            end)
        end
    end

    local function openList()
        isOpen = true
        buildList()
        local count  = #Players:GetPlayers()
        local listH  = math.min(count, MAX_SHOW) * (ITEM_H + 2) + 8
        local totalH = HEADER_H + 2 + listH
        divider.Visible = true
        TweenService:Create(arrowLbl,   TweenInfo.new(0.18, Enum.EasingStyle.Quint), {Rotation = 180}):Play()
        TweenService:Create(outer,      TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,-12,0,totalH)}):Play()
        TweenService:Create(listScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,listH)}):Play()
    end

    headerBtn.MouseButton1Click:Connect(function()
        if isOpen then closeList() else openList() end
    end)
    headerBtn.MouseEnter:Connect(function()
        TweenService:Create(selFrame, TweenInfo.new(0.10), {BackgroundColor3 = Color3.fromRGB(42,42,42)}):Play()
    end)
    headerBtn.MouseLeave:Connect(function()
        TweenService:Create(selFrame, TweenInfo.new(0.10), {BackgroundColor3 = C.BG_INPUT}):Play()
    end)

    Players.PlayerAdded:Connect(function()
        if isOpen then
            buildList()
            local count = #Players:GetPlayers()
            local listH = math.min(count, MAX_SHOW) * (ITEM_H + 2) + 8
            outer.Size      = UDim2.new(1, -12, 0, HEADER_H + 2 + listH)
            listScroll.Size = UDim2.new(1, 0, 0, listH)
        end
    end)
    Players.PlayerRemoving:Connect(function(leaving)
        if leaving.Name == selected then clearSelected() end
        if isOpen then
            buildList()
            local count = #Players:GetPlayers()
            local listH = math.min(math.max(count-1,0), MAX_SHOW) * (ITEM_H + 2) + 8
            outer.Size      = UDim2.new(1, -12, 0, HEADER_H + 2 + listH)
            listScroll.Size = UDim2.new(1, 0, 0, listH)
        end
    end)

    return outer, function() return selected end
end

-- ════════════════════════════════════════════════════════════════════════════════
-- TELEPORT CORE
-- ════════════════════════════════════════════════════════════════════════════════

local MAX_ITEM_TRIES = 8

local function seekNetOwn(char, part, RS)
    if not (part and part.Parent) then return end
    if (char.HumanoidRootPart.Position - part.Position).Magnitude > 25 then
        char.HumanoidRootPart.CFrame = part.CFrame
        task.wait(0.04)
    end
    for _ = 1, 15 do
        task.wait(0.015)
        RS.Interaction.ClientIsDragging:FireServer(part.Parent)
    end
end

local function sendItemPart(char, part, Offset, RS, runningRef)
    for attempt = 1, MAX_ITEM_TRIES do
        if not (part and part.Parent) then return false end
        if not runningRef() then return false end
        if (char.HumanoidRootPart.Position - part.Position).Magnitude > 25 then
            char.HumanoidRootPart.CFrame = part.CFrame
            task.wait(0.04)
        end
        seekNetOwn(char, part, RS)
        local deadline = tick() + 0.25
        repeat
            part.CFrame = Offset
            task.wait()
        until tick() >= deadline
        if not (part and part.Parent) then return false end
        if (part.Position - Offset.Position).Magnitude <= 8 then return true end
        task.wait(0.15)
    end
    return false
end

local function retryCargo(char, missedList, GiveBaseOrigin, RS, runningRef, setProgFn, statusFn, MAX_TRIES)
    MAX_TRIES = MAX_TRIES or 25
    if #missedList == 0 then return end
    local missedTotal = #missedList
    local attempt     = 0
    local itemsDone   = 0
    if setProgFn then setProgFn(0, missedTotal) end
    while #missedList > 0 and runningRef() and attempt < MAX_TRIES do
        attempt += 1
        if statusFn then
            statusFn(string.format("Retry %d/%d — %d left...", attempt, MAX_TRIES, #missedList), true)
        end
        for _, data in ipairs(missedList) do
            if not runningRef() then break end
            local item = data.Instance
            if not (item and item.Parent) then continue end
            sendItemPart(char, item, data.TargetCFrame, RS, runningRef)
            itemsDone += 1
            if setProgFn then setProgFn(itemsDone, missedTotal) end
            task.wait()
        end
        task.wait(0.8)
        local stillMissed = {}
        for _, data in ipairs(missedList) do
            if data.Instance and data.Instance.Parent then
                local dist = (data.Instance.Position - data.TargetCFrame.Position).Magnitude
                if dist > 8 then
                    if (data.Instance.Position - GiveBaseOrigin.Position).Magnitude < 500 then
                        table.insert(stillMissed, data)
                    end
                end
            end
        end
        local confirmed = missedTotal - #stillMissed
        if confirmed > itemsDone then
            itemsDone = confirmed
            if setProgFn then setProgFn(itemsDone, missedTotal) end
        end
        missedList = stillMissed
    end
    if setProgFn then setProgFn(missedTotal, missedTotal) end
    if statusFn then
        if #missedList == 0 then
            statusFn("✓ All items teleported!", false)
        else
            statusFn(string.format("Done — %d part(s) couldn't be moved", #missedList), false)
        end
    end
end

-- ════════════════════════════════════════════════════════════════════════════════
-- DUPE TAB — SUB-TAB SYSTEM
-- ════════════════════════════════════════════════════════════════════════════════

local tabBarFrame = Instance.new("Frame", dupePage)
tabBarFrame.Size             = UDim2.new(1, -12, 0, 30)
tabBarFrame.BackgroundColor3 = C.BG_DEEP
tabBarFrame.BorderSizePixel  = 0
Instance.new("UICorner", tabBarFrame).CornerRadius = UDim.new(0, 7)
local tabBarStroke = Instance.new("UIStroke", tabBarFrame)
tabBarStroke.Color     = C.BORDER
tabBarStroke.Thickness = 1

local tabLayout = Instance.new("UIListLayout", tabBarFrame)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder     = Enum.SortOrder.LayoutOrder
tabLayout.Padding       = UDim.new(0, 2)

local tabPad = Instance.new("UIPadding", tabBarFrame)
tabPad.PaddingLeft   = UDim.new(0, 3)
tabPad.PaddingRight  = UDim.new(0, 3)
tabPad.PaddingTop    = UDim.new(0, 3)
tabPad.PaddingBottom = UDim.new(0, 3)

local function makeSubPage(parent)
    local sf = Instance.new("Frame", parent)
    sf.Size             = UDim2.new(1, 0, 0, 0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel  = 0
    sf.Visible          = false
    sf.AutomaticSize    = Enum.AutomaticSize.Y
    local layout = Instance.new("UIListLayout", sf)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0, 5)
    return sf
end

local subPages   = {}
local tabButtons = {}
local TAB_NAMES  = {"Base Dupe", "Single Truck", "Batch Trucks"}

for i, name in ipairs(TAB_NAMES) do
    local tb = Instance.new("TextButton", tabBarFrame)
    tb.Size             = UDim2.new(0.333, -2, 1, 0)
    tb.BackgroundColor3 = C.TAB_IDLE
    tb.BorderSizePixel  = 0
    tb.Font             = Enum.Font.GothamSemibold
    tb.TextSize         = 11
    tb.TextColor3       = C.TEXT_DIM
    tb.Text             = name
    tb.LayoutOrder      = i
    tb.AutoButtonColor  = false
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 4)

    tb.MouseEnter:Connect(function()
        if tb.BackgroundColor3 ~= C.TAB_ACTIVE then
            TweenService:Create(tb, TweenInfo.new(0.10), {BackgroundColor3 = C.TAB_HOVER}):Play()
        end
    end)
    tb.MouseLeave:Connect(function()
        if tb.BackgroundColor3 ~= C.TAB_ACTIVE then
            TweenService:Create(tb, TweenInfo.new(0.10), {BackgroundColor3 = C.TAB_IDLE}):Play()
        end
    end)

    table.insert(tabButtons, tb)

    local sp = makeSubPage(dupePage)
    sp.LayoutOrder = i + 10
    table.insert(subPages, sp)
end

local function switchTab(idx)
    for i, sp in ipairs(subPages) do
        sp.Visible = (i == idx)
        TweenService:Create(tabButtons[i], TweenInfo.new(0.14), {
            BackgroundColor3 = (i == idx) and C.TAB_ACTIVE or C.TAB_IDLE,
            TextColor3       = (i == idx) and C.TEXT_BRIGHT or C.TEXT_DIM,
        }):Play()
    end
end

for i, tb in ipairs(tabButtons) do
    tb.MouseButton1Click:Connect(function() switchTab(i) end)
end
switchTab(1)

local baseDupePage    = subPages[1]
local singleTruckPage = subPages[2]
local batchTruckPage  = subPages[3]

-- ════════════════════════════════════════════════════════════════════════════════
-- ITEM TYPE HELPERS
-- ════════════════════════════════════════════════════════════════════════════════

local function getTypeValue(p)
    local tv = p:FindFirstChild("Type")
    return tv and tostring(tv.Value) or ""
end

local function isStructure(p)
    local tv = getTypeValue(p)
    if tv == "Structure" then return true end
    local tc = p:FindFirstChild("TreeClass")
    return tc and tostring(tc.Value) == "Structure"
end

local function isGiftOrItem(p)
    local tv = getTypeValue(p)
    if tv == "Gift" or tv == "Loose Item" or tv == "Tool" then return true end
    if tv == "Furniture" and p:FindFirstChild("PurchasedBoxItemName") then return true end
    return false
end

local function isWood(p)
    local tc = p:FindFirstChild("TreeClass")
    if not tc then return false end
    if tostring(tc.Value) == "Structure" then return false end
    if isGiftOrItem(p) then return false end
    return true
end

local function isFurniture(p)
    if getTypeValue(p) ~= "Furniture" then return false end
    if p:FindFirstChild("PurchasedBoxItemName") then return false end
    return true
end

-- ════════════════════════════════════════════════════════════════════════════════
-- SUB-TAB 1 — BASE DUPE
-- ════════════════════════════════════════════════════════════════════════════════

local _, setStatus = makeStatusBar(baseDupePage, "Ready")

makeLabel(baseDupePage, "Players")
local _, getGiverName    = makeDupeDropdown("Giver",    baseDupePage)
local _, getReceiverName = makeDupeDropdown("Receiver", baseDupePage)

makeSep(baseDupePage)
makeLabel(baseDupePage, "What to Transfer")

local _, getStructures = makeToggle(baseDupePage, "Structures",  false)
local _, getFurniture  = makeToggle(baseDupePage, "Furnitures",  false)
local _, getTrucks     = makeToggle(baseDupePage, "Truck Loads", false)
local _, getGifs       = makeToggle(baseDupePage, "Gift/Item",   false)
local _, getWood       = makeToggle(baseDupePage, "Wood",        false)

makeSep(baseDupePage)
makeLabel(baseDupePage, "Progress")

local progStructures, setProgStructures, resetProgStructures = makeProgressBar(baseDupePage, "Structures")
local progFurniture,  setProgFurniture,  resetProgFurniture  = makeProgressBar(baseDupePage, "Furnitures")
local progTrucks,     setProgTrucks,     resetProgTrucks     = makeProgressBar(baseDupePage, "Trucks")
local progGifs,       setProgGifs,       resetProgGifs       = makeProgressBar(baseDupePage, "Gift/Item")
local progWood,       setProgWood,       resetProgWood       = makeProgressBar(baseDupePage, "Wood")

makeSep(baseDupePage)

local butterRunning = false
local butterThread  = nil

local function resetAllProgress()
    resetProgStructures()
    resetProgFurniture()
    resetProgTrucks()
    resetProgGifs()
    resetProgWood()
end

local _, startButterBtn, stopButterBtn = makeStartStop(baseDupePage, nil, function()
    butterRunning = false; VH.butter.running = false
    if butterThread then pcall(task.cancel, butterThread); butterThread = nil end
    VH.butter.thread = nil
    setStatus("Stopped", false)
    resetAllProgress()
end)

startButterBtn.MouseButton1Click:Connect(function()
    if butterRunning then setStatus("Already running!", true) return end

    local giverName    = getGiverName()
    local receiverName = getReceiverName()
    if giverName == "" or receiverName == "" then return end

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
            setStatus("⚠  Couldn't find bases!", false)
            butterRunning = false; VH.butter.running = false; butterThread = nil; VH.butter.thread = nil
            return
        end

        local giveOriginCF = GiveBaseOrigin.CFrame
        local recvOriginCF = ReceiverBaseOrigin.CFrame
        local butterRunningRef = function() return butterRunning end

        local function getItemWorldCF(p)
            if p:FindFirstChild("MainCFrame") then return p.MainCFrame.Value
            elseif p:FindFirstChild("Main")   then return p.Main.CFrame
            else
                local part = p:FindFirstChildOfClass("Part") or p:FindFirstChildOfClass("WedgePart")
                return part and part.CFrame or nil
            end
        end

        -- ── STRUCTURES
        if getStructures() and butterRunning then
            local total = 0
            for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                if v.Name == "Owner" and tostring(v.Value) == giverName then
                    local p = v.Parent
                    if isStructure(p) and (p:FindFirstChild("MainCFrame") or p:FindFirstChild("Main")
                         or p:FindFirstChildOfClass("Part") or p:FindFirstChildOfClass("WedgePart")) then
                        total += 1
                    end
                end
            end
            if total > 0 then
                progStructures.Visible = true; setProgStructures(0, total)
                setStatus("Sending structures...", true)
                local done = 0
                pcall(function()
                    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                        if not butterRunning then break end
                        if v.Name == "Owner" and tostring(v.Value) == giverName then
                            local p = v.Parent
                            if isStructure(p) then
                                local PCF = getItemWorldCF(p)
                                if not PCF then continue end
                                local DA  = p:FindFirstChild("BlueprintWoodClass") and p.BlueprintWoodClass.Value or nil
                                local Off = recvOriginCF:ToWorldSpace(giveOriginCF:ToObjectSpace(PCF))
                                repeat task.wait()
                                    pcall(function()
                                        RS.PlaceStructure.ClientPlacedStructure:FireServer(p.ItemName.Value, Off, LP, DA, p, true)
                                    end)
                                until not p.Parent
                                done += 1; setProgStructures(done, total)
                            end
                        end
                    end
                end)
                setProgStructures(total, total)
            end
        end

        -- ── FURNITURE
        if getFurniture() and butterRunning then
            local total = 0
            for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                if v.Name == "Owner" and tostring(v.Value) == giverName then
                    local p = v.Parent
                    if isFurniture(p) and (p:FindFirstChild("MainCFrame") or p:FindFirstChild("Main") or p:FindFirstChildOfClass("Part")) then
                        total += 1
                    end
                end
            end
            if total > 0 then
                progFurniture.Visible = true; setProgFurniture(0, total)
                setStatus("Sending furnitures...", true)
                local done = 0
                pcall(function()
                    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                        if not butterRunning then break end
                        if v.Name == "Owner" and tostring(v.Value) == giverName then
                            local p = v.Parent
                            if isFurniture(p) then
                                local PCF = getItemWorldCF(p)
                                if not PCF then continue end
                                local DA  = p:FindFirstChild("BlueprintWoodClass") and p.BlueprintWoodClass.Value or nil
                                local Off = recvOriginCF:ToWorldSpace(giveOriginCF:ToObjectSpace(PCF))
                                repeat task.wait()
                                    pcall(function()
                                        RS.PlaceStructure.ClientPlacedStructure:FireServer(p.ItemName.Value, Off, LP, DA, p, true)
                                    end)
                                until not p.Parent
                                done += 1; setProgFurniture(done, total)
                            end
                        end
                    end
                end)
                setProgFurniture(total, total)
            end
        end

        -- ── TRUCKS + CARGO
        if getTrucks() and butterRunning then
            local teleportedParts = {}
            local ignoredParts    = {}
            local DidTruckTeleport = false

            local function isPointInside(point, boxCFrame, boxSize)
                local r = boxCFrame:PointToObjectSpace(point)
                return math.abs(r.X) <= boxSize.X/2
                   and math.abs(r.Y) <= boxSize.Y/2 + 2
                   and math.abs(r.Z) <= boxSize.Z/2
            end

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

                for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                    if not butterRunning then break end
                    if v.Name == "Owner" and tostring(v.Value) == giverName and v.Parent:FindFirstChild("DriveSeat") then
                        v.Parent.DriveSeat:Sit(Char.Humanoid)
                        repeat task.wait() v.Parent.DriveSeat:Sit(Char.Humanoid) until Char.Humanoid.SeatPart

                        local tModel   = Char.Humanoid.SeatPart.Parent
                        local mCF, mSz = tModel:GetBoundingBox()

                        for _, p in ipairs(tModel:GetDescendants()) do if p:IsA("BasePart") then ignoredParts[p] = true end end
                        for _, p in ipairs(Char:GetDescendants())   do if p:IsA("BasePart") then ignoredParts[p] = true end end

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
                                            table.insert(teleportedParts, {Instance=part, OldPos=part.Position, TargetCFrame=tOff})
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
                        if DoorHinge then for i=1,10 do RS.Interaction.RemoteProxy:FireServer(DoorHinge) end end
                        truckDone += 1; setProgTrucks(truckDone, truckCount)
                    end
                end

                task.wait(2)
                local missed = {}
                for _, data in ipairs(teleportedParts) do
                    if data.Instance and data.Instance.Parent then
                        if (data.Instance.Position - data.TargetCFrame.Position).Magnitude > 8 then
                            if (data.Instance.Position - GiveBaseOrigin.Position).Magnitude < 500 then
                                table.insert(missed, data)
                            end
                        end
                    end
                end
                if #missed > 0 then
                    progTrucks.Visible = true
                    retryCargo(Char, missed, GiveBaseOrigin, RS, butterRunningRef,
                        function(d,t) setProgTrucks(d,t) end,
                        function(msg,act) setStatus(msg,act) end, 25)
                    task.wait(1)
                else
                    setProgTrucks(truckCount, truckCount)
                end
            end
        end

        -- ── GIFT / ITEMS / BOXES
        if getGifs() and butterRunning then
            local items = {}
            for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                if not butterRunning then break end
                if v.Name == "Owner" and tostring(v.Value) == giverName then
                    local p = v.Parent
                    if isGiftOrItem(p) then
                        local mainChild = p:FindFirstChild("Main")
                        local part, PCF
                        if mainChild and mainChild:IsA("BasePart") then
                            part = mainChild; PCF = mainChild.CFrame
                        elseif mainChild then
                            part = mainChild.PrimaryPart
                                or mainChild:FindFirstChildOfClass("BasePart")
                                or mainChild:FindFirstChildWhichIsA("BasePart", true)
                            PCF  = part and part.CFrame or nil
                        end
                        if not part then
                            part = p:FindFirstChildOfClass("BasePart")
                                or p:FindFirstChildWhichIsA("BasePart", true)
                            PCF  = part and part.CFrame or nil
                        end
                        if part and PCF then
                            local nPos = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                            table.insert(items, {part = part, offset = CFrame.new(nPos) * PCF.Rotation})
                        end
                    end
                end
            end

            if #items > 0 then
                local total  = #items
                local done   = 0
                local missed = {}
                progGifs.Visible = true; setProgGifs(0, total)
                setStatus(string.format("Sending %d gift/item(s)...", total), true)

                for _, entry in ipairs(items) do
                    if not butterRunning then break end
                    local part   = entry.part
                    local Offset = entry.offset
                    if not (part and part.Parent) then done += 1; setProgGifs(done, total); continue end
                    if (Char.HumanoidRootPart.Position - part.Position).Magnitude > 25 then
                        Char.HumanoidRootPart.CFrame = part.CFrame; task.wait(0.04)
                    end
                    for _ = 1, 15 do
                        task.wait(0.015)
                        RS.Interaction.ClientIsDragging:FireServer(part.Parent)
                    end
                    local deadline = tick() + 0.25
                    repeat part.CFrame = Offset; task.wait() until tick() >= deadline
                    if part and part.Parent then
                        if (part.Position - Offset.Position).Magnitude > 8 then
                            table.insert(missed, {Instance = part, TargetCFrame = Offset})
                        end
                    end
                    done += 1; setProgGifs(done, total)
                end

                if #missed > 0 and butterRunning then
                    progGifs.Visible = true
                    setStatus(string.format("Gift retry — %d item(s) missed...", #missed), true)
                    retryCargo(Char, missed, GiveBaseOrigin, RS, butterRunningRef,
                        function(d, t) setProgGifs(d, t) end,
                        function(msg, act) setStatus(msg, act) end, 25)
                    task.wait(1)
                else
                    setProgGifs(total, total)
                end
            end
        end

        -- ── WOOD
        if getWood() and butterRunning then
            local items = {}
            for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                if not butterRunning then break end
                if v.Name == "Owner" and tostring(v.Value) == giverName then
                    local p = v.Parent
                    if isWood(p) then
                        local part = p:FindFirstChild("Main") or p:FindFirstChildOfClass("Part")
                        if part then
                            local PCF  = (p:FindFirstChild("Main") and p.Main.CFrame) or part.CFrame
                            local nPos = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                            table.insert(items, {part = part, offset = CFrame.new(nPos) * PCF.Rotation})
                        end
                    end
                end
            end

            if #items > 0 then
                local total  = #items
                local done   = 0
                local missed = {}
                progWood.Visible = true; setProgWood(0, total)
                setStatus(string.format("Sending %d wood piece(s)...", total), true)

                for _, entry in ipairs(items) do
                    if not butterRunning then break end
                    local part   = entry.part
                    local Offset = entry.offset
                    if not (part and part.Parent) then done += 1; setProgWood(done, total); continue end
                    if (Char.HumanoidRootPart.Position - part.Position).Magnitude > 25 then
                        Char.HumanoidRootPart.CFrame = part.CFrame; task.wait(0.04)
                    end
                    for _ = 1, 15 do
                        task.wait(0.015)
                        RS.Interaction.ClientIsDragging:FireServer(part.Parent)
                    end
                    local deadline = tick() + 0.25
                    repeat part.CFrame = Offset; task.wait() until tick() >= deadline
                    if part and part.Parent then
                        if (part.Position - Offset.Position).Magnitude > 8 then
                            table.insert(missed, {Instance = part, TargetCFrame = Offset})
                        end
                    end
                    done += 1; setProgWood(done, total)
                end

                if #missed > 0 and butterRunning then
                    progWood.Visible = true
                    setStatus(string.format("Wood retry — %d piece(s) missed...", #missed), true)
                    retryCargo(Char, missed, GiveBaseOrigin, RS, butterRunningRef,
                        function(d, t) setProgWood(d, t) end,
                        function(msg, act) setStatus(msg, act) end, 25)
                    task.wait(1)
                else
                    setProgWood(total, total)
                end
            end
        end

        if butterRunning then setStatus("✓ All done!", false) end
        butterRunning = false; VH.butter.running = false
        butterThread = nil; VH.butter.thread = nil
        task.delay(2.1, resetAllProgress)
    end)
end)

table.insert(VH.cleanupTasks, function()
    butterRunning = false; VH.butter.running = false
    if butterThread then pcall(task.cancel, butterThread); butterThread = nil end
    VH.butter.thread = nil
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- SUB-TAB 2 — SINGLE TRUCK TELEPORT
-- ════════════════════════════════════════════════════════════════════════════════

local _, setTruckStatus = makeStatusBar(singleTruckPage, "Ready")

makeLabel(singleTruckPage, "Players")
local _, getTruckGiverName    = makeDupeDropdown("Giver",    singleTruckPage)
local _, getTruckReceiverName = makeDupeDropdown("Receiver", singleTruckPage)

makeSep(singleTruckPage)
makeLabel(singleTruckPage, "Progress")

local truckProgBar, setTruckProg, resetTruckProg = makeProgressBar(singleTruckPage, "Truck + Cargo")

makeSep(singleTruckPage)

local singleTruckRunning = false
local singleTruckThread  = nil

local _, startSingleBtn, stopSingleBtn = makeStartStop(singleTruckPage, nil, function()
    singleTruckRunning = false
    if singleTruckThread then pcall(task.cancel, singleTruckThread); singleTruckThread = nil end
    setTruckStatus("Stopped", false)
    resetTruckProg()
end)

startSingleBtn.MouseButton1Click:Connect(function()
    if singleTruckRunning then setTruckStatus("Already running!", true) return end

    local LP   = Players.LocalPlayer
    local Char = LP.Character
    if not Char then setTruckStatus("No character found!", false) return end
    local hum = Char:FindFirstChildOfClass("Humanoid")
    if not (hum and hum.SeatPart) then setTruckStatus("Not sitting in a truck!", false) return end
    local truckModel = hum.SeatPart.Parent
    if not truckModel:FindFirstChild("DriveSeat") then setTruckStatus("Seat is not a DriveSeat!", false) return end

    local gName = getTruckGiverName()
    local rName = getTruckReceiverName()
    if gName == "" or rName == "" then return end

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

    singleTruckRunning = true
    resetTruckProg()
    setTruckStatus("Sending truck...", true)

    singleTruckThread = task.spawn(function()
        local RS = game:GetService("ReplicatedStorage")

        local function isPointInside(point, boxCFrame, boxSize)
            local r = boxCFrame:PointToObjectSpace(point)
            return math.abs(r.X)<=boxSize.X/2 and math.abs(r.Y)<=boxSize.Y/2+2 and math.abs(r.Z)<=boxSize.Z/2
        end

        local teleportedParts = {}
        local ignoredParts    = {}
        local DidTruckTeleport = false

        local function TeleportTruck()
            if DidTruckTeleport then return end
            if not Char.Humanoid.SeatPart then return end
            local TCF  = Char.Humanoid.SeatPart.Parent:FindFirstChild("Main").CFrame
            local nPos = TCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
            Char.Humanoid.SeatPart.Parent:SetPrimaryPartCFrame(CFrame.new(nPos) * TCF.Rotation)
            DidTruckTeleport = true
        end

        truckProgBar.Visible = true; setTruckProg(0, 1)

        truckModel.DriveSeat:Sit(Char.Humanoid)
        repeat task.wait() truckModel.DriveSeat:Sit(Char.Humanoid) until Char.Humanoid.SeatPart

        local mCF, mSz = truckModel:GetBoundingBox()
        for _, p in ipairs(truckModel:GetDescendants()) do if p:IsA("BasePart") then ignoredParts[p] = true end end
        for _, p in ipairs(Char:GetDescendants())       do if p:IsA("BasePart") then ignoredParts[p] = true end end

        for _, part in ipairs(workspace:GetDescendants()) do
            if not singleTruckRunning then break end
            if part:IsA("BasePart") and not ignoredParts[part] then
                if part.Name == "Main" or part.Name == "WoodSection" then
                    if part:FindFirstChild("Weld") and part.Weld.Part1 and part.Weld.Part1.Parent ~= part.Parent then continue end
                    task.spawn(function()
                        if isPointInside(part.Position, mCF, mSz) then
                            TeleportTruck()
                            local PCF  = part.CFrame
                            local nP   = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                            local tOff = CFrame.new(nP) * PCF.Rotation
                            part.CFrame = tOff; task.wait(0.3)
                            table.insert(teleportedParts, {Instance=part, OldPos=part.Position, TargetCFrame=tOff})
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
        if DoorHinge then for i=1,10 do RS.Interaction.RemoteProxy:FireServer(DoorHinge) end end
        setTruckProg(1, 1)
        task.wait(2)

        local missed = {}
        for _, data in ipairs(teleportedParts) do
            if data.Instance and data.Instance.Parent then
                if (data.Instance.Position - data.TargetCFrame.Position).Magnitude > 8 then
                    if (data.Instance.Position - GiveBaseOrigin.Position).Magnitude < 500 then
                        table.insert(missed, data)
                    end
                end
            end
        end

        local singleRunRef = function() return singleTruckRunning end
        if #missed > 0 then
            truckProgBar.Visible = true
            retryCargo(Char, missed, GiveBaseOrigin, RS, singleRunRef,
                function(d,t) setTruckProg(d,t) end,
                function(msg,act) setTruckStatus(msg,act) end, 25)
        else
            setTruckStatus("✓ Truck teleported!", false)
        end

        task.wait(1)
        singleTruckRunning = false
        singleTruckThread  = nil
        task.delay(2.1, resetTruckProg)
    end)
end)

table.insert(VH.cleanupTasks, function()
    singleTruckRunning = false
    if singleTruckThread then pcall(task.cancel, singleTruckThread); singleTruckThread = nil end
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- EMPTY TRUCKS — auto-teleport trucks with no cargo, one every 1.5s
-- Uses the same Giver / Receiver dropdowns as Single Truck
-- ════════════════════════════════════════════════════════════════════════════════

makeSep(singleTruckPage)
makeLabel(singleTruckPage, "Empty Trucks")

local _, setEmptyStatus = makeStatusBar(singleTruckPage, "Ready")

local emptyTruckRunning = false
local emptyTruckThread  = nil

-- Check whether a truck model has any cargo inside its bounding box
local function truckHasCargo(truckModel)
    local mCF, mSz = truckModel:GetBoundingBox()
    -- Build ignore set from the truck's own parts
    local ignoredParts = {}
    for _, p in ipairs(truckModel:GetDescendants()) do
        if p:IsA("BasePart") then ignoredParts[p] = true end
    end
    local LP   = Players.LocalPlayer
    local Char = LP.Character
    if Char then
        for _, p in ipairs(Char:GetDescendants()) do
            if p:IsA("BasePart") then ignoredParts[p] = true end
        end
    end
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and not ignoredParts[part] then
            if part.Name == "Main" or part.Name == "WoodSection" then
                local r = mCF:PointToObjectSpace(part.Position)
                if math.abs(r.X) <= mSz.X / 2
                and math.abs(r.Y) <= mSz.Y / 2 + 2
                and math.abs(r.Z) <= mSz.Z / 2 then
                    return true
                end
            end
        end
    end
    return false
end

makeToggle(singleTruckPage, "Empty Trucks", false, function(on)
    if on then
        emptyTruckRunning = true
        emptyTruckThread = task.spawn(function()
            while emptyTruckRunning do
                local gName = getTruckGiverName()
                local rName = getTruckReceiverName()

                if gName ~= "" and rName ~= "" then
                    local GiveBase, RecvBase
                    for _, v in pairs(workspace.Properties:GetDescendants()) do
                        if v.Name == "Owner" then
                            local val = tostring(v.Value)
                            if val == gName then GiveBase = v.Parent:FindFirstChild("OriginSquare") end
                            if val == rName then RecvBase  = v.Parent:FindFirstChild("OriginSquare") end
                        end
                    end

                    if GiveBase and RecvBase then
                        local RS   = game:GetService("ReplicatedStorage")
                        local LP   = Players.LocalPlayer
                        local Char = LP.Character

                        if Char then
                            -- Find first empty truck owned by giver
                            local emptyTruck = nil
                            for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                                if v.Name == "Owner" and tostring(v.Value) == gName then
                                    local m = v.Parent
                                    if m:FindFirstChild("DriveSeat") and not truckHasCargo(m) then
                                        emptyTruck = m
                                        break
                                    end
                                end
                            end

                            if emptyTruck then
                                setEmptyStatus("Teleporting empty truck...", true)
                                local DidTeleport = false

                                local function DoTeleport()
                                    if DidTeleport then return end
                                    if not Char.Humanoid.SeatPart then return end
                                    local TCF  = Char.Humanoid.SeatPart.Parent:FindFirstChild("Main").CFrame
                                    local nPos = TCF.Position - GiveBase.Position + RecvBase.Position
                                    Char.Humanoid.SeatPart.Parent:SetPrimaryPartCFrame(CFrame.new(nPos) * TCF.Rotation)
                                    DidTeleport = true
                                end

                                -- Sit in the truck
                                emptyTruck.DriveSeat:Sit(Char.Humanoid)
                                local t0 = tick()
                                repeat
                                    task.wait()
                                    emptyTruck.DriveSeat:Sit(Char.Humanoid)
                                until Char.Humanoid.SeatPart or (tick() - t0 > 5)

                                if Char.Humanoid.SeatPart then
                                    local SitPart   = Char.Humanoid.SeatPart
                                    local DoorHinge = SitPart.Parent:FindFirstChild("PaintParts")
                                        and SitPart.Parent.PaintParts:FindFirstChild("DoorLeft")
                                        and SitPart.Parent.PaintParts.DoorLeft:FindFirstChild("ButtonRemote_Hinge")
                                    task.wait(0.1)
                                    Char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    task.wait(0.1)
                                    DoTeleport()
                                    SitPart:Destroy()
                                    if DoorHinge then
                                        for _ = 1, 10 do
                                            RS.Interaction.RemoteProxy:FireServer(DoorHinge)
                                        end
                                    end
                                    setEmptyStatus("Sent ✓ — waiting...", false)
                                else
                                    setEmptyStatus("Couldn't sit — skipping", false)
                                end
                            else
                                setEmptyStatus("No empty trucks found", false)
                            end
                        end
                    else
                        setEmptyStatus("Select Giver & Receiver first", false)
                    end
                else
                    setEmptyStatus("Select Giver & Receiver first", false)
                end

                task.wait(1.5)
            end
        end)
    else
        emptyTruckRunning = false
        if emptyTruckThread then pcall(task.cancel, emptyTruckThread); emptyTruckThread = nil end
        setEmptyStatus("Stopped", false)
    end
end)

table.insert(VH.cleanupTasks, function()
    emptyTruckRunning = false
    if emptyTruckThread then pcall(task.cancel, emptyTruckThread); emptyTruckThread = nil end
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- SUB-TAB 3 — BATCH TRUCK TELEPORT
-- ════════════════════════════════════════════════════════════════════════════════

local _, setBatchStatus = makeStatusBar(batchTruckPage, "Ready")

makeLabel(batchTruckPage, "Players")
local _, getBatchGiverName    = makeDupeDropdown("Giver",    batchTruckPage)
local _, getBatchReceiverName = makeDupeDropdown("Receiver", batchTruckPage)

makeLabel(batchTruckPage, "Options")

local batchCountRow = Instance.new("Frame", batchTruckPage)
batchCountRow.Size             = UDim2.new(1, -12, 0, 34)
batchCountRow.BackgroundColor3 = C.BG_ROW
batchCountRow.BorderSizePixel  = 0
Instance.new("UICorner", batchCountRow).CornerRadius = UDim.new(0, 7)
local bcrStroke = Instance.new("UIStroke", batchCountRow)
bcrStroke.Color = C.BORDER; bcrStroke.Thickness = 1; bcrStroke.Transparency = 0.4

local batchCountLbl = Instance.new("TextLabel", batchCountRow)
batchCountLbl.Size = UDim2.new(1,-82,1,0); batchCountLbl.Position = UDim2.new(0,12,0,0)
batchCountLbl.BackgroundTransparency = 1; batchCountLbl.Font = Enum.Font.GothamSemibold
batchCountLbl.TextSize = 12; batchCountLbl.TextColor3 = C.TEXT_BRIGHT
batchCountLbl.TextXAlignment = Enum.TextXAlignment.Left; batchCountLbl.Text = "Trucks to Teleport"

local batchCountBox = Instance.new("TextBox", batchCountRow)
batchCountBox.Size = UDim2.new(0,58,0,22); batchCountBox.Position = UDim2.new(1,-66,0.5,-11)
batchCountBox.BackgroundColor3 = C.BG_INPUT; batchCountBox.BorderSizePixel = 0
batchCountBox.Font = Enum.Font.GothamBold; batchCountBox.TextSize = 12
batchCountBox.TextColor3 = C.TEXT_BRIGHT; batchCountBox.PlaceholderText = "e.g. 3"
batchCountBox.PlaceholderColor3 = C.TEXT_DIM; batchCountBox.Text = ""
batchCountBox.TextXAlignment = Enum.TextXAlignment.Center; batchCountBox.ClearTextOnFocus = false
Instance.new("UICorner", batchCountBox).CornerRadius = UDim.new(0, 5)
local bbStroke = Instance.new("UIStroke", batchCountBox)
bbStroke.Color = C.BORDER; bbStroke.Thickness = 1; bbStroke.Transparency = 0.3

batchCountBox:GetPropertyChangedSignal("Text"):Connect(function()
    local clean = batchCountBox.Text:gsub("[^%d]", "")
    if clean ~= batchCountBox.Text then batchCountBox.Text = clean end
end)

makeSep(batchTruckPage)
makeLabel(batchTruckPage, "Progress")

local batchTruckProgBar, setBatchTruckProg, resetBatchTruckProg = makeProgressBar(batchTruckPage, "Trucks")
local batchCargoProgBar, setBatchCargoProg, resetBatchCargoProg = makeProgressBar(batchTruckPage, "Missed Cargo")

makeSep(batchTruckPage)

local batchTruckRunning = false
local batchTruckThread  = nil

local _, startBatchBtn, stopBatchBtn = makeStartStop(batchTruckPage, nil, function()
    batchTruckRunning = false
    if batchTruckThread then pcall(task.cancel, batchTruckThread); batchTruckThread = nil end
    setBatchStatus("Stopped", false)
    resetBatchTruckProg(); resetBatchCargoProg()
end)

startBatchBtn.MouseButton1Click:Connect(function()
    if batchTruckRunning then setBatchStatus("Already running!", true) return end

    local gName = getBatchGiverName()
    local rName = getBatchReceiverName()
    if gName == "" or rName == "" then return end

    local wantedCount = tonumber(batchCountBox.Text)
    if not wantedCount or wantedCount < 1 then setBatchStatus("⚠  Enter a valid truck count!", false) return end
    wantedCount = math.floor(wantedCount)

    local availableTrucks = {}
    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
        if v.Name == "Owner" and tostring(v.Value) == gName and v.Parent:FindFirstChild("DriveSeat") then
            table.insert(availableTrucks, v.Parent)
        end
    end
    local actualCount = #availableTrucks
    if actualCount == 0 then setBatchStatus("⚠  No trucks found on giver's plot!", false) return end

    if wantedCount < actualCount then
        while #availableTrucks > wantedCount do table.remove(availableTrucks) end
        setBatchStatus(string.format("Clamped to %d trucks", wantedCount), false); task.wait(1.2)
    elseif wantedCount > actualCount then
        wantedCount = actualCount
        setBatchStatus(string.format("Only %d truck(s) found — teleporting all", actualCount), false); task.wait(1.2)
    end

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

    batchTruckRunning = true
    resetBatchTruckProg(); resetBatchCargoProg()
    setBatchStatus(string.format("Starting — %d truck(s) queued...", #availableTrucks), true)

    batchTruckThread = task.spawn(function()
        local RS   = game:GetService("ReplicatedStorage")
        local LP   = Players.LocalPlayer
        local Char = LP.Character or LP.CharacterAdded:Wait()

        local function isPointInside(point, boxCFrame, boxSize)
            local r = boxCFrame:PointToObjectSpace(point)
            return math.abs(r.X)<=boxSize.X/2 and math.abs(r.Y)<=boxSize.Y/2+2 and math.abs(r.Z)<=boxSize.Z/2
        end

        local allTeleportedParts = {}
        batchTruckProgBar.Visible = true; setBatchTruckProg(0, #availableTrucks)

        local trucksDone = 0
        for _, truckModel in ipairs(availableTrucks) do
            if not batchTruckRunning then break end
            if not (truckModel and truckModel.Parent) then
                trucksDone += 1; setBatchTruckProg(trucksDone, #availableTrucks); continue
            end

            setBatchStatus(string.format("Truck %d / %d...", trucksDone+1, #availableTrucks), true)

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
            for _, p in ipairs(truckModel:GetDescendants()) do if p:IsA("BasePart") then ignoredParts[p] = true end end
            for _, p in ipairs(Char:GetDescendants())       do if p:IsA("BasePart") then ignoredParts[p] = true end end

            for _, part in ipairs(workspace:GetDescendants()) do
                if not batchTruckRunning then break end
                if part:IsA("BasePart") and not ignoredParts[part] then
                    if part.Name == "Main" or part.Name == "WoodSection" then
                        if part:FindFirstChild("Weld") and part.Weld.Part1 and part.Weld.Part1.Parent ~= part.Parent then continue end
                        task.spawn(function()
                            if isPointInside(part.Position, mCF, mSz) then
                                TeleportThisTruck()
                                local PCF  = part.CFrame
                                local nP   = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                                local tOff = CFrame.new(nP) * PCF.Rotation
                                part.CFrame = tOff; task.wait(0.3)
                                table.insert(allTeleportedParts, {Instance=part, OldPos=part.Position, TargetCFrame=tOff})
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
            task.wait(0.1); SitPart:Destroy(); TeleportThisTruck(); DidTruckTeleport = false; task.wait(0.1)
            if DoorHinge then for i=1,10 do RS.Interaction.RemoteProxy:FireServer(DoorHinge) end end

            trucksDone += 1; setBatchTruckProg(trucksDone, #availableTrucks)
            task.wait(0.3)
        end

        task.wait(2)
        local missed = {}
        for _, data in ipairs(allTeleportedParts) do
            if data.Instance and data.Instance.Parent then
                if (data.Instance.Position - data.TargetCFrame.Position).Magnitude > 8 then
                    if (data.Instance.Position - GiveBaseOrigin.Position).Magnitude < 500 then
                        table.insert(missed, data)
                    end
                end
            end
        end

        local batchRunRef = function() return batchTruckRunning end
        if #missed > 0 then
            batchCargoProgBar.Visible = true
            retryCargo(Char, missed, GiveBaseOrigin, RS, batchRunRef,
                function(d,t) setBatchCargoProg(d,t) end,
                function(msg,act) setBatchStatus(msg,act) end, 25)
        else
            setBatchStatus(string.format("✓ %d truck(s) teleported!", trucksDone), false)
        end

        task.wait(1)
        batchTruckRunning = false
        batchTruckThread  = nil
        task.delay(2.1, function()
            resetBatchTruckProg()
            resetBatchCargoProg()
        end)
    end)
end)

table.insert(VH.cleanupTasks, function()
    batchTruckRunning = false
    if batchTruckThread then pcall(task.cancel, batchTruckThread); batchTruckThread = nil end
end)

print("[VanillaHub] Vanilla2 loaded — black/grey/white theme")
