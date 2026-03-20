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
    BTN_PAUSE    = Color3.fromRGB(40,  36,  14),
    BTN_PAUSE_HV = Color3.fromRGB(60,  54,  20),
    DOT_IDLE     = Color3.fromRGB(70,  70,  70 ),
    DOT_ACTIVE   = Color3.fromRGB(200, 200, 200),
    DOT_PAUSED   = Color3.fromRGB(180, 160, 50 ),
    PROG_TRACK   = Color3.fromRGB(30,  30,  30 ),
    PROG_FILL    = Color3.fromRGB(255, 255, 255),
    PROG_DONE    = Color3.fromRGB(255, 255, 255),
    TAB_ACTIVE   = Color3.fromRGB(38,  38,  38),
    TAB_IDLE     = Color3.fromRGB(12,  12,  12),
    TAB_HOVER    = Color3.fromRGB(28,  28,  28),
}

-- ════════════════════════════════════════════════════════════════════════════════
-- SHARED SPEED SETTING  (mirrors Item Tab tpItemSpeed)
-- ════════════════════════════════════════════════════════════════════════════════

local tpItemSpeed = 0.3   -- default 0.3 s; updated by the slider

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
    local btnStr_btn = Instance.new("UIStroke", btn)
    btnStr_btn.Color        = Color3.fromRGB(55, 55, 55)
    btnStr_btn.Thickness    = 1
    btnStr_btn.Transparency = 0
    applyHover(btn, color, hoverColor)
    if callback then btn.MouseButton1Click:Connect(callback) end
    return btn
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

    -- state: "idle" | "active" | "paused"
    local function setStatus(msg, state)
        lbl.Text = msg
        local dotColor = C.DOT_IDLE
        if state == "active" then
            dotColor = C.DOT_ACTIVE
        elseif state == "paused" then
            dotColor = C.DOT_PAUSED
        end
        TweenService:Create(dot, TweenInfo.new(0.18), {BackgroundColor3 = dotColor}):Play()
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

-- ════════════════════════════════════════════════════════════════════════════════
-- PAUSE-AWARE START / STOP / PAUSE ROW
-- Creates a three-button row: [▶ Start | ⏸ Pause | ■ Stop]
-- startCb  – called when Start is clicked (only if not already running)
-- pauseCb  – called with (isPaused bool) when Pause/Resume is clicked
-- stopCb   – called when Stop is clicked
-- Returns: row, startBtn, pauseBtn, stopBtn
-- ════════════════════════════════════════════════════════════════════════════════

local function makeStartPauseStop(parent, startCb, pauseCb, stopCb)
    local row = Instance.new("Frame", parent)
    row.Size             = UDim2.new(1, -12, 0, 34)
    row.BackgroundTransparency = 1
    row.BorderSizePixel  = 0

    local rl = Instance.new("UIListLayout", row)
    rl.FillDirection = Enum.FillDirection.Horizontal
    rl.SortOrder     = Enum.SortOrder.LayoutOrder
    rl.Padding       = UDim.new(0, 4)

    local function makeCell(text, base, hover, cb, order, widthScale)
        local btn = Instance.new("TextButton", row)
        btn.Size             = UDim2.new(widthScale or 0.333, -3, 1, 0)
        btn.BackgroundColor3 = base
        btn.BorderSizePixel  = 0
        btn.Font             = Enum.Font.GothamBold
        btn.TextSize         = 12
        btn.TextColor3       = C.TEXT_BRIGHT
        btn.Text             = text
        btn.AutoButtonColor  = false
        btn.LayoutOrder      = order
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        local s = Instance.new("UIStroke", btn)
        s.Color = Color3.fromRGB(55, 55, 55); s.Thickness = 1; s.Transparency = 0
        applyHover(btn, base, hover)
        if cb then btn.MouseButton1Click:Connect(cb) end
        return btn
    end

    local startBtn = makeCell("▶  Start", C.BTN_START, C.BTN_START_HV, startCb,  1, 0.36)
    local pauseBtn = makeCell("⏸  Pause", C.BTN_PAUSE, C.BTN_PAUSE_HV, nil,      2, 0.30)
    local stopBtn  = makeCell("■  Stop",  C.BTN_STOP,  C.BTN_STOP_HV,  stopCb,   3, 0.34)

    local _paused = false
    pauseBtn.MouseButton1Click:Connect(function()
        _paused = not _paused
        if _paused then
            pauseBtn.Text = "▶  Resume"
            TweenService:Create(pauseBtn, TweenInfo.new(0.14), {BackgroundColor3 = Color3.fromRGB(55,50,14)}):Play()
        else
            pauseBtn.Text = "⏸  Pause"
            TweenService:Create(pauseBtn, TweenInfo.new(0.14), {BackgroundColor3 = C.BTN_PAUSE}):Play()
        end
        if pauseCb then pauseCb(_paused) end
    end)

    local function resetPauseBtn()
        _paused = false
        pauseBtn.Text = "⏸  Pause"
        TweenService:Create(pauseBtn, TweenInfo.new(0.14), {BackgroundColor3 = C.BTN_PAUSE}):Play()
    end

    return row, startBtn, pauseBtn, stopBtn, resetPauseBtn
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
-- PAUSE HELPER
-- Wraps a runningRef + pausedRef into a single "wait if paused, bail if stopped"
-- call that can be inserted at every yield point.
-- ════════════════════════════════════════════════════════════════════════════════

local function waitWhilePaused(runningRef, pausedRef)
    -- Returns false when we should abort (stopped), true to continue.
    while pausedRef() do
        if not runningRef() then return false end
        task.wait(0.1)
    end
    return runningRef()
end

-- ════════════════════════════════════════════════════════════════════════════════
-- TELEPORT CORE  (pause-aware, lag-resilient — never gives up due to lag)
-- ════════════════════════════════════════════════════════════════════════════════

local MAX_ITEM_TRIES = 12   -- increased from 8; no hard timeout, just retries

local function seekNetOwn(char, part, RS, runningRef, pausedRef)
    if not (part and part.Parent) then return end
    if (char.HumanoidRootPart.Position - part.Position).Magnitude > 25 then
        char.HumanoidRootPart.CFrame = part.CFrame
        task.wait(0.04)
    end
    for _ = 1, 15 do
        if not waitWhilePaused(runningRef, pausedRef) then return end
        task.wait(0.015)
        RS.Interaction.ClientIsDragging:FireServer(part.Parent)
    end
end

local function sendItemPart(char, part, Offset, RS, runningRef, pausedRef)
    -- Retry indefinitely until success or explicitly stopped – lag won't abort us.
    local attempt = 0
    while true do
        attempt += 1
        if not (part and part.Parent) then return false end
        if not waitWhilePaused(runningRef, pausedRef) then return false end

        if (char.HumanoidRootPart.Position - part.Position).Magnitude > 25 then
            char.HumanoidRootPart.CFrame = part.CFrame
            task.wait(0.04)
        end
        seekNetOwn(char, part, RS, runningRef, pausedRef)
        if not waitWhilePaused(runningRef, pausedRef) then return false end

        local deadline = tick() + 0.25
        repeat
            part.CFrame = Offset
            task.wait()
        until tick() >= deadline

        if not (part and part.Parent) then return false end
        if (part.Position - Offset.Position).Magnitude <= 8 then return true end

        -- Still not there?  Wait a little longer each retry (backoff), but keep going.
        task.wait(math.min(0.15 * attempt, 1.5))

        -- After MAX_ITEM_TRIES hard failures we give up on *this specific part*
        -- but we never abort the whole session.
        if attempt >= MAX_ITEM_TRIES then return false end
    end
end

local function retryCargo(char, missedList, GiveBaseOrigin, RS, runningRef, pausedRef, setProgFn, statusFn, MAX_TRIES)
    MAX_TRIES = MAX_TRIES or 30
    if #missedList == 0 then return end
    local missedTotal = #missedList
    local attempt     = 0
    local itemsDone   = 0
    if setProgFn then setProgFn(0, missedTotal) end

    while #missedList > 0 and attempt < MAX_TRIES do
        if not waitWhilePaused(runningRef, pausedRef) then break end
        attempt += 1

        if statusFn then
            statusFn(string.format("Retry %d/%d — %d left...", attempt, MAX_TRIES, #missedList), "active")
        end

        for _, data in ipairs(missedList) do
            if not waitWhilePaused(runningRef, pausedRef) then break end
            local item = data.Instance
            if not (item and item.Parent) then continue end
            sendItemPart(char, item, data.TargetCFrame, RS, runningRef, pausedRef)
            itemsDone += 1
            if setProgFn then setProgFn(itemsDone, missedTotal) end
            task.wait(tpItemSpeed * 0.5)   -- half-speed between retried parts
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
            statusFn("✓ All items teleported!", "idle")
        else
            statusFn(string.format("Done — %d part(s) couldn't be moved", #missedList), "idle")
        end
    end
end

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
-- SPEED SLIDER  (shared across all three sub-tabs, placed on Base Dupe page)
-- ════════════════════════════════════════════════════════════════════════════════

makeLabel(baseDupePage, "Teleport Speed")

local speedSliderFrame = Instance.new("Frame", baseDupePage)
speedSliderFrame.Size             = UDim2.new(1, -12, 0, 54)
speedSliderFrame.BackgroundColor3 = C.BG_ROW
speedSliderFrame.BorderSizePixel  = 0
Instance.new("UICorner", speedSliderFrame).CornerRadius = UDim.new(0, 8)
local ssStroke = Instance.new("UIStroke", speedSliderFrame)
ssStroke.Color = C.BORDER; ssStroke.Thickness = 1; ssStroke.Transparency = 0.4

local ssTopRow = Instance.new("Frame", speedSliderFrame)
ssTopRow.Size                 = UDim2.new(1, -16, 0, 22)
ssTopRow.Position             = UDim2.new(0, 8, 0, 7)
ssTopRow.BackgroundTransparency = 1

local ssLbl = Instance.new("TextLabel", ssTopRow)
ssLbl.Size               = UDim2.new(0.72, 0, 1, 0)
ssLbl.BackgroundTransparency = 1
ssLbl.Font               = Enum.Font.GothamSemibold
ssLbl.TextSize           = 13
ssLbl.TextColor3         = C.TEXT_BRIGHT
ssLbl.TextXAlignment     = Enum.TextXAlignment.Left
ssLbl.Text               = "Delay (per item)"

local ssValLbl = Instance.new("TextLabel", ssTopRow)
ssValLbl.Size               = UDim2.new(0.28, 0, 1, 0)
ssValLbl.Position           = UDim2.new(0.72, 0, 0, 0)
ssValLbl.BackgroundTransparency = 1
ssValLbl.Font               = Enum.Font.GothamBold
ssValLbl.TextSize           = 13
ssValLbl.TextColor3         = C.TEXT_WHITE
ssValLbl.TextXAlignment     = Enum.TextXAlignment.Right
ssValLbl.Text               = "0.30 s"

local ssTrack = Instance.new("Frame", speedSliderFrame)
ssTrack.Size             = UDim2.new(1, -16, 0, 5)
ssTrack.Position         = UDim2.new(0, 8, 0, 38)
ssTrack.BackgroundColor3 = C.PROG_TRACK
ssTrack.BorderSizePixel  = 0
Instance.new("UICorner", ssTrack).CornerRadius = UDim.new(1, 0)

-- range: 1–20 maps to 0.1 s – 2.0 s (steps of 0.1 s)
local SS_MIN, SS_MAX, SS_DEF = 1, 20, 3   -- default = 3 → 0.30 s

local ssFill = Instance.new("Frame", ssTrack)
ssFill.Size             = UDim2.new((SS_DEF - SS_MIN) / (SS_MAX - SS_MIN), 0, 1, 0)
ssFill.BackgroundColor3 = C.PROG_FILL
ssFill.BorderSizePixel  = 0
Instance.new("UICorner", ssFill).CornerRadius = UDim.new(1, 0)

local ssKnob = Instance.new("TextButton", ssTrack)
ssKnob.Size             = UDim2.new(0, 14, 0, 14)
ssKnob.AnchorPoint      = Vector2.new(0.5, 0.5)
ssKnob.Position         = UDim2.new((SS_DEF - SS_MIN) / (SS_MAX - SS_MIN), 0, 0.5, 0)
ssKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ssKnob.Text             = ""
ssKnob.BorderSizePixel  = 0
Instance.new("UICorner", ssKnob).CornerRadius = UDim.new(1, 0)

local ssDragging = false
local function ssUpdate(absX)
    local r = math.clamp((absX - ssTrack.AbsolutePosition.X) / ssTrack.AbsoluteSize.X, 0, 1)
    local v = math.round(SS_MIN + r * (SS_MAX - SS_MIN))
    ssFill.Size       = UDim2.new(r, 0, 1, 0)
    ssKnob.Position   = UDim2.new(r, 0, 0.5, 0)
    tpItemSpeed       = v / 10
    ssValLbl.Text     = string.format("%.2f s", tpItemSpeed)
end
ssKnob.MouseButton1Down:Connect(function() ssDragging = true end)
ssTrack.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then ssDragging = true; ssUpdate(i.Position.X) end
end)
local UIS_SS = game:GetService("UserInputService")
UIS_SS.InputChanged:Connect(function(i)
    if ssDragging and i.UserInputType == Enum.UserInputType.MouseMovement then ssUpdate(i.Position.X) end
end)
UIS_SS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then ssDragging = false end
end)

makeSep(baseDupePage)

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
local butterPaused  = false
local butterThread  = nil

local function resetAllProgress()
    resetProgStructures()
    resetProgFurniture()
    resetProgTrucks()
    resetProgGifs()
    resetProgWood()
end

local butterRunningRef = function() return butterRunning end
local butterPausedRef  = function() return butterPaused  end

local _, startButterBtn, pauseButterBtn, stopButterBtn, resetButterPauseBtn =
    makeStartPauseStop(
        baseDupePage,
        nil,   -- start callback wired below
        function(isPaused)
            butterPaused = isPaused
            if isPaused then
                setStatus("⏸  Paused", "paused")
            else
                setStatus("▶  Resuming...", "active")
            end
        end,
        function()
            butterRunning = false; butterPaused = false
            VH.butter.running = false
            if butterThread then pcall(task.cancel, butterThread); butterThread = nil end
            VH.butter.thread = nil
            resetButterPauseBtn()
            setStatus("Stopped", "idle")
            resetAllProgress()
        end
    )

startButterBtn.MouseButton1Click:Connect(function()
    if butterRunning then setStatus("Already running!", "active") return end

    local giverName    = getGiverName()
    local receiverName = getReceiverName()
    if giverName == "" or receiverName == "" then return end

    butterRunning = true; butterPaused = false
    VH.butter.running = true
    setStatus("Finding bases...", "active")
    resetAllProgress()
    resetButterPauseBtn()

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
            setStatus("⚠  Couldn't find bases!", "idle")
            butterRunning = false; VH.butter.running = false; butterThread = nil; VH.butter.thread = nil
            return
        end

        local giveOriginCF = GiveBaseOrigin.CFrame
        local recvOriginCF = ReceiverBaseOrigin.CFrame

        local function getItemWorldCF(p)
            if p:FindFirstChild("MainCFrame") then return p.MainCFrame.Value
            elseif p:FindFirstChild("Main")   then return p.Main.CFrame
            else
                local part = p:FindFirstChildOfClass("Part") or p:FindFirstChildOfClass("WedgePart")
                return part and part.CFrame or nil
            end
        end

        -- ── STRUCTURES ──────────────────────────────────────────────────────
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
                setStatus("Sending structures...", "active")
                local done = 0
                pcall(function()
                    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                        if not waitWhilePaused(butterRunningRef, butterPausedRef) then break end
                        if v.Name == "Owner" and tostring(v.Value) == giverName then
                            local p = v.Parent
                            if isStructure(p) then
                                local PCF = getItemWorldCF(p)
                                if not PCF then continue end
                                local DA  = p:FindFirstChild("BlueprintWoodClass") and p.BlueprintWoodClass.Value or nil
                                local Off = recvOriginCF:ToWorldSpace(giveOriginCF:ToObjectSpace(PCF))
                                repeat
                                    if not waitWhilePaused(butterRunningRef, butterPausedRef) then break end
                                    task.wait()
                                    pcall(function()
                                        RS.PlaceStructure.ClientPlacedStructure:FireServer(p.ItemName.Value, Off, LP, DA, p, true)
                                    end)
                                until not p.Parent
                                done += 1; setProgStructures(done, total)
                                task.wait(tpItemSpeed)
                            end
                        end
                    end
                end)
                setProgStructures(total, total)
            end
        end

        -- ── FURNITURE ───────────────────────────────────────────────────────
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
                setStatus("Sending furnitures...", "active")
                local done = 0
                pcall(function()
                    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                        if not waitWhilePaused(butterRunningRef, butterPausedRef) then break end
                        if v.Name == "Owner" and tostring(v.Value) == giverName then
                            local p = v.Parent
                            if isFurniture(p) then
                                local PCF = getItemWorldCF(p)
                                if not PCF then continue end
                                local DA  = p:FindFirstChild("BlueprintWoodClass") and p.BlueprintWoodClass.Value or nil
                                local Off = recvOriginCF:ToWorldSpace(giveOriginCF:ToObjectSpace(PCF))
                                repeat
                                    if not waitWhilePaused(butterRunningRef, butterPausedRef) then break end
                                    task.wait()
                                    pcall(function()
                                        RS.PlaceStructure.ClientPlacedStructure:FireServer(p.ItemName.Value, Off, LP, DA, p, true)
                                    end)
                                until not p.Parent
                                done += 1; setProgFurniture(done, total)
                                task.wait(tpItemSpeed)
                            end
                        end
                    end
                end)
                setProgFurniture(total, total)
            end
        end

        -- ── TRUCKS + CARGO ──────────────────────────────────────────────────
        if getTrucks() and butterRunning then
            local teleportedParts = {}

            -- Snapshot the full truck list up-front so we never miss one.
            local truckModels = {}
            for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                if v.Name == "Owner" and tostring(v.Value) == giverName
                    and v.Parent:FindFirstChild("DriveSeat") then
                    table.insert(truckModels, v.Parent)
                end
            end
            local truckCount = #truckModels

            if truckCount > 0 then
                progTrucks.Visible = true
                setProgTrucks(0, truckCount)

                local function isPointInside(point, boxCF, boxSz)
                    local ok, r = pcall(function() return boxCF:PointToObjectSpace(point) end)
                    if not ok then return false end
                    return math.abs(r.X) <= boxSz.X / 2
                        and math.abs(r.Y) <= boxSz.Y / 2 + 2
                        and math.abs(r.Z) <= boxSz.Z / 2
                end

                for truckIdx, truckModel in ipairs(truckModels) do
                    -- ── Pause check at every truck boundary ──────────────────
                    if not waitWhilePaused(butterRunningRef, butterPausedRef) then break end

                    -- Guard: truck may have despawned while we were handling another one.
                    if not (truckModel and truckModel.Parent) then
                        setProgTrucks(truckIdx, truckCount); continue
                    end

                    setStatus(string.format("Truck %d / %d — sitting...", truckIdx, truckCount), "active")

                    local ignoredParts     = {}
                    local DidTruckTeleport = false

                    local function TeleportTruck()
                        if DidTruckTeleport then return end
                        local hum  = Char and Char:FindFirstChildOfClass("Humanoid")
                        local seat = hum and hum.SeatPart
                        if not seat then return end
                        local mainPart = seat.Parent:FindFirstChild("Main")
                        if not mainPart then return end
                        local TCF  = mainPart.CFrame
                        local nPos = TCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                        pcall(function()
                            seat.Parent:SetPrimaryPartCFrame(CFrame.new(nPos) * TCF.Rotation)
                        end)
                        DidTruckTeleport = true
                    end

                    -- ── Sit — retry indefinitely until seated or stopped ─────
                    -- We never bail out just because the server is lagging.
                    local seated = false
                    while not seated do
                        if not waitWhilePaused(butterRunningRef, butterPausedRef) then break end
                        if not (truckModel and truckModel.Parent) then break end

                        pcall(function() truckModel.DriveSeat:Sit(Char.Humanoid) end)

                        -- Wait up to 2 s for the seat to register, checking every 0.06 s.
                        local deadline = tick() + 2
                        while tick() < deadline do
                            task.wait(0.06)
                            if Char.Humanoid and Char.Humanoid.SeatPart then
                                seated = true; break
                            end
                        end

                        if not seated then
                            -- Server lag or brief desync – give it a moment then retry silently.
                            task.wait(0.3)
                        end
                    end

                    if not seated then
                        -- Could not sit even after unlimited retries (truck likely gone).
                        -- Fall back to raw-offset so we still move the truck body.
                        setStatus(string.format("Truck %d / %d — no seat, raw offset...", truckIdx, truckCount), "active")
                        pcall(function()
                            local mainPart = truckModel:FindFirstChild("Main")
                            if mainPart then
                                local TCF  = mainPart.CFrame
                                local nPos = TCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                                truckModel:SetPrimaryPartCFrame(CFrame.new(nPos) * TCF.Rotation)
                            end
                        end)
                        setProgTrucks(truckIdx, truckCount)
                        task.wait(tpItemSpeed)
                        continue
                    end

                    setStatus(string.format("Truck %d / %d — scanning cargo...", truckIdx, truckCount), "active")

                    local mCF, mSz = truckModel:GetBoundingBox()
                    for _, p in ipairs(truckModel:GetDescendants()) do
                        if p:IsA("BasePart") then ignoredParts[p] = true end
                    end
                    for _, p in ipairs(Char:GetDescendants()) do
                        if p:IsA("BasePart") then ignoredParts[p] = true end
                    end

                    -- Scan cargo; each candidate is handled in its own task so
                    -- a slow part cannot block the others.
                    for _, part in ipairs(workspace:GetDescendants()) do
                        if not butterRunning then break end
                        if part:IsA("BasePart") and not ignoredParts[part] then
                            if part.Name == "Main" or part.Name == "WoodSection" then
                                local weld = part:FindFirstChild("Weld")
                                if weld and weld.Part1 and weld.Part1.Parent ~= part.Parent then continue end
                                task.spawn(function()
                                    if isPointInside(part.Position, mCF, mSz) then
                                        TeleportTruck()
                                        local PCF  = part.CFrame
                                        local nP   = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                                        local tOff = CFrame.new(nP) * PCF.Rotation
                                        pcall(function() part.CFrame = tOff end)
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

                    -- Wait for spawned cargo threads (time-capped; lag can't stall us)
                    local cargoDeadline = tick() + 3
                    repeat task.wait(0.05) until tick() >= cargoDeadline

                    local SitPart = Char.Humanoid and Char.Humanoid.SeatPart
                    local DoorHinge = SitPart
                        and SitPart.Parent:FindFirstChild("PaintParts")
                        and SitPart.Parent.PaintParts:FindFirstChild("DoorLeft")
                        and SitPart.Parent.PaintParts.DoorLeft:FindFirstChild("ButtonRemote_Hinge")

                    -- Exit seat
                    pcall(function() Char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
                    task.wait(0.1)
                    TeleportTruck()
                    if SitPart and SitPart.Parent then pcall(function() SitPart:Destroy() end) end
                    DidTruckTeleport = false
                    task.wait(0.1)
                    if DoorHinge then
                        for _ = 1, 10 do pcall(function() RS.Interaction.RemoteProxy:FireServer(DoorHinge) end) end
                    end

                    setProgTrucks(truckIdx, truckCount)
                    task.wait(tpItemSpeed)
                end

                -- ── Retry pass for ALL missed cargo after every truck is done ─
                if not waitWhilePaused(butterRunningRef, butterPausedRef) then
                    -- stopped while waiting; skip retry
                else
                    setStatus("Waiting for cargo to settle...", "active")
                    task.wait(2.5)

                    local missed = {}
                    for _, data in ipairs(teleportedParts) do
                        if data.Instance and data.Instance.Parent then
                            local dist = (data.Instance.Position - data.TargetCFrame.Position).Magnitude
                            if dist > 8 then
                                if (data.Instance.Position - GiveBaseOrigin.Position).Magnitude < 500 then
                                    table.insert(missed, data)
                                end
                            end
                        end
                    end

                    if #missed > 0 then
                        progTrucks.Visible = true
                        setStatus(string.format("Retrying %d missed cargo piece(s)...", #missed), "active")
                        retryCargo(
                            Char, missed, GiveBaseOrigin, RS,
                            butterRunningRef, butterPausedRef,
                            function(d, t) setProgTrucks(d, t) end,
                            function(msg, state) setStatus(msg, state) end,
                            30
                        )
                        task.wait(1)
                    else
                        setProgTrucks(truckCount, truckCount)
                    end
                end
            end
        end

        -- ── GIFT / ITEMS / BOXES ─────────────────────────────────────────────
        if getGifs() and butterRunning then
            local items = {}
            for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                if not waitWhilePaused(butterRunningRef, butterPausedRef) then break end
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
                            PCF = part and part.CFrame or nil
                        end
                        if not part then
                            part = p:FindFirstChildOfClass("BasePart")
                                or p:FindFirstChildWhichIsA("BasePart", true)
                            PCF = part and part.CFrame or nil
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

                progGifs.Visible = true
                setProgGifs(0, total)
                setStatus(string.format("Sending %d gift/item(s)...", total), "active")

                for _, entry in ipairs(items) do
                    if not waitWhilePaused(butterRunningRef, butterPausedRef) then break end
                    local part   = entry.part
                    local Offset = entry.offset

                    if not (part and part.Parent) then
                        done += 1; setProgGifs(done, total); continue
                    end

                    local ok = sendItemPart(Char, part, Offset, RS, butterRunningRef, butterPausedRef)
                    if not ok and (part and part.Parent) then
                        if (part.Position - Offset.Position).Magnitude > 8 then
                            table.insert(missed, {Instance = part, TargetCFrame = Offset})
                        end
                    end

                    done += 1; setProgGifs(done, total)
                    task.wait(tpItemSpeed)
                end

                if #missed > 0 and butterRunning then
                    progGifs.Visible = true
                    setStatus(string.format("Gift retry — %d item(s) missed...", #missed), "active")
                    retryCargo(Char, missed, GiveBaseOrigin, RS,
                        butterRunningRef, butterPausedRef,
                        function(d, t) setProgGifs(d, t) end,
                        function(msg, state) setStatus(msg, state) end, 30)
                    task.wait(1)
                else
                    setProgGifs(total, total)
                end
            end
        end

        -- ── WOOD ─────────────────────────────────────────────────────────────
        if getWood() and butterRunning then
            local items = {}
            for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                if not waitWhilePaused(butterRunningRef, butterPausedRef) then break end
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

                progWood.Visible = true
                setProgWood(0, total)
                setStatus(string.format("Sending %d wood piece(s)...", total), "active")

                for _, entry in ipairs(items) do
                    if not waitWhilePaused(butterRunningRef, butterPausedRef) then break end
                    local part   = entry.part
                    local Offset = entry.offset

                    if not (part and part.Parent) then
                        done += 1; setProgWood(done, total); continue
                    end

                    local ok = sendItemPart(Char, part, Offset, RS, butterRunningRef, butterPausedRef)
                    if not ok and (part and part.Parent) then
                        if (part.Position - Offset.Position).Magnitude > 8 then
                            table.insert(missed, {Instance = part, TargetCFrame = Offset})
                        end
                    end

                    done += 1; setProgWood(done, total)
                    task.wait(tpItemSpeed)
                end

                if #missed > 0 and butterRunning then
                    progWood.Visible = true
                    setStatus(string.format("Wood retry — %d piece(s) missed...", #missed), "active")
                    retryCargo(Char, missed, GiveBaseOrigin, RS,
                        butterRunningRef, butterPausedRef,
                        function(d, t) setProgWood(d, t) end,
                        function(msg, state) setStatus(msg, state) end, 30)
                    task.wait(1)
                else
                    setProgWood(total, total)
                end
            end
        end

        if butterRunning then setStatus("✓ All done!", "idle") end
        butterRunning = false; butterPaused = false
        VH.butter.running = false
        butterThread = nil; VH.butter.thread = nil
        resetButterPauseBtn()
        task.delay(2.1, resetAllProgress)
    end)
end)

table.insert(VH.cleanupTasks, function()
    butterRunning = false; butterPaused = false
    VH.butter.running = false
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
local singleTruckPaused  = false
local singleTruckThread  = nil

local singleRunRef  = function() return singleTruckRunning end
local singlePauRef  = function() return singleTruckPaused  end

local _, startSingleBtn, pauseSingleBtn, stopSingleBtn, resetSinglePauseBtn =
    makeStartPauseStop(
        singleTruckPage,
        nil,
        function(isPaused)
            singleTruckPaused = isPaused
            if isPaused then
                setTruckStatus("⏸  Paused", "paused")
            else
                setTruckStatus("▶  Resuming...", "active")
            end
        end,
        function()
            singleTruckRunning = false; singleTruckPaused = false
            if singleTruckThread then pcall(task.cancel, singleTruckThread); singleTruckThread = nil end
            resetSinglePauseBtn()
            setTruckStatus("Stopped", "idle")
            resetTruckProg()
        end
    )

startSingleBtn.MouseButton1Click:Connect(function()
    if singleTruckRunning then setTruckStatus("Already running!", "active") return end

    local LP   = Players.LocalPlayer
    local Char = LP.Character
    if not Char then setTruckStatus("No character found!", "idle") return end
    local hum = Char:FindFirstChildOfClass("Humanoid")
    if not (hum and hum.SeatPart) then setTruckStatus("Not sitting in a truck!", "idle") return end
    local truckModel = hum.SeatPart.Parent
    if not truckModel:FindFirstChild("DriveSeat") then setTruckStatus("Seat is not a DriveSeat!", "idle") return end

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
    if not GiveBaseOrigin     then setTruckStatus("Giver base not found!",    "idle") return end
    if not ReceiverBaseOrigin then setTruckStatus("Receiver base not found!", "idle") return end

    singleTruckRunning = true; singleTruckPaused = false
    resetTruckProg()
    setTruckStatus("Sending truck...", "active")
    resetSinglePauseBtn()

    singleTruckThread = task.spawn(function()
        local RS = game:GetService("ReplicatedStorage")

        local function isPointInside(point, boxCFrame, boxSize)
            local ok, r = pcall(function() return boxCFrame:PointToObjectSpace(point) end)
            if not ok then return false end
            return math.abs(r.X)<=boxSize.X/2 and math.abs(r.Y)<=boxSize.Y/2+2 and math.abs(r.Z)<=boxSize.Z/2
        end

        local teleportedParts  = {}
        local ignoredParts     = {}
        local DidTruckTeleport = false

        local function TeleportTruck()
            if DidTruckTeleport then return end
            local hum  = Char and Char:FindFirstChildOfClass("Humanoid")
            local seat = hum and hum.SeatPart
            if not seat then return end
            local mainPart = seat.Parent:FindFirstChild("Main")
            if not mainPart then return end
            local TCF  = mainPart.CFrame
            local nPos = TCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
            pcall(function()
                seat.Parent:SetPrimaryPartCFrame(CFrame.new(nPos) * TCF.Rotation)
            end)
            DidTruckTeleport = true
        end

        truckProgBar.Visible = true; setTruckProg(0, 1)

        -- Sit — retry indefinitely, never abort due to lag
        local seated = false
        while not seated do
            if not waitWhilePaused(singleRunRef, singlePauRef) then break end
            pcall(function() truckModel.DriveSeat:Sit(Char.Humanoid) end)
            local deadline = tick() + 2
            while tick() < deadline do
                task.wait(0.06)
                if Char.Humanoid and Char.Humanoid.SeatPart then
                    seated = true; break
                end
            end
            if not seated then task.wait(0.3) end
        end

        if not seated then
            setTruckStatus("Couldn't sit in truck!", "idle")
            singleTruckRunning = false; singleTruckThread = nil
            task.delay(2.1, resetTruckProg)
            return
        end

        local mCF, mSz = truckModel:GetBoundingBox()
        for _, p in ipairs(truckModel:GetDescendants()) do if p:IsA("BasePart") then ignoredParts[p] = true end end
        for _, p in ipairs(Char:GetDescendants())       do if p:IsA("BasePart") then ignoredParts[p] = true end end

        for _, part in ipairs(workspace:GetDescendants()) do
            if not singleTruckRunning then break end
            if part:IsA("BasePart") and not ignoredParts[part] then
                if part.Name == "Main" or part.Name == "WoodSection" then
                    local weld = part:FindFirstChild("Weld")
                    if weld and weld.Part1 and weld.Part1.Parent ~= part.Parent then continue end
                    task.spawn(function()
                        if isPointInside(part.Position, mCF, mSz) then
                            TeleportTruck()
                            local PCF  = part.CFrame
                            local nP   = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                            local tOff = CFrame.new(nP) * PCF.Rotation
                            pcall(function() part.CFrame = tOff end)
                            task.wait(0.3)
                            table.insert(teleportedParts, {Instance=part, OldPos=part.Position, TargetCFrame=tOff})
                        end
                    end)
                end
            end
        end

        local cargoDeadline = tick() + 3
        repeat task.wait(0.05) until tick() >= cargoDeadline

        local SitPart = Char.Humanoid and Char.Humanoid.SeatPart
        local DoorHinge = SitPart
            and SitPart.Parent:FindFirstChild("PaintParts")
            and SitPart.Parent.PaintParts:FindFirstChild("DoorLeft")
            and SitPart.Parent.PaintParts.DoorLeft:FindFirstChild("ButtonRemote_Hinge")

        pcall(function() Char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
        task.wait(0.1)
        TeleportTruck()
        if SitPart and SitPart.Parent then pcall(function() SitPart:Destroy() end) end
        DidTruckTeleport = false
        task.wait(0.1)
        if DoorHinge then
            for _ = 1, 10 do pcall(function() RS.Interaction.RemoteProxy:FireServer(DoorHinge) end) end
        end
        setTruckProg(1, 1)
        task.wait(2.5)

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
            truckProgBar.Visible = true
            retryCargo(Char, missed, GiveBaseOrigin, RS,
                singleRunRef, singlePauRef,
                function(d,t) setTruckProg(d,t) end,
                function(msg,state) setTruckStatus(msg,state) end, 30)
        else
            setTruckStatus("✓ Truck teleported!", "idle")
        end

        task.wait(1)
        singleTruckRunning = false; singleTruckPaused = false
        singleTruckThread  = nil
        resetSinglePauseBtn()
        task.delay(2.1, resetTruckProg)
    end)
end)

table.insert(VH.cleanupTasks, function()
    singleTruckRunning = false; singleTruckPaused = false
    if singleTruckThread then pcall(task.cancel, singleTruckThread); singleTruckThread = nil end
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
local batchTruckPaused  = false
local batchTruckThread  = nil

local batchRunRef = function() return batchTruckRunning end
local batchPauRef = function() return batchTruckPaused  end

local _, startBatchBtn, pauseBatchBtn, stopBatchBtn, resetBatchPauseBtn =
    makeStartPauseStop(
        batchTruckPage,
        nil,
        function(isPaused)
            batchTruckPaused = isPaused
            if isPaused then
                setBatchStatus("⏸  Paused", "paused")
            else
                setBatchStatus("▶  Resuming...", "active")
            end
        end,
        function()
            batchTruckRunning = false; batchTruckPaused = false
            if batchTruckThread then pcall(task.cancel, batchTruckThread); batchTruckThread = nil end
            resetBatchPauseBtn()
            setBatchStatus("Stopped", "idle")
            resetBatchTruckProg(); resetBatchCargoProg()
        end
    )

startBatchBtn.MouseButton1Click:Connect(function()
    if batchTruckRunning then setBatchStatus("Already running!", "active") return end

    local gName = getBatchGiverName()
    local rName = getBatchReceiverName()
    if gName == "" or rName == "" then return end

    local wantedCount = tonumber(batchCountBox.Text)
    if not wantedCount or wantedCount < 1 then setBatchStatus("⚠  Enter a valid truck count!", "idle") return end
    wantedCount = math.floor(wantedCount)

    local availableTrucks = {}
    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
        if v.Name == "Owner" and tostring(v.Value) == gName and v.Parent:FindFirstChild("DriveSeat") then
            table.insert(availableTrucks, v.Parent)
        end
    end
    local actualCount = #availableTrucks
    if actualCount == 0 then setBatchStatus("⚠  No trucks found on giver's plot!", "idle") return end

    if wantedCount < actualCount then
        while #availableTrucks > wantedCount do table.remove(availableTrucks) end
        setBatchStatus(string.format("Clamped to %d trucks", wantedCount), "idle"); task.wait(1.2)
    elseif wantedCount > actualCount then
        wantedCount = actualCount
        setBatchStatus(string.format("Only %d truck(s) found — teleporting all", actualCount), "idle"); task.wait(1.2)
    end

    local GiveBaseOrigin, ReceiverBaseOrigin
    for _, v in pairs(workspace.Properties:GetDescendants()) do
        if v.Name == "Owner" then
            local val = tostring(v.Value)
            if val == gName then GiveBaseOrigin     = v.Parent:FindFirstChild("OriginSquare") end
            if val == rName then ReceiverBaseOrigin = v.Parent:FindFirstChild("OriginSquare") end
        end
    end
    if not GiveBaseOrigin     then setBatchStatus("Giver base not found!",    "idle") return end
    if not ReceiverBaseOrigin then setBatchStatus("Receiver base not found!", "idle") return end

    batchTruckRunning = true; batchTruckPaused = false
    resetBatchTruckProg(); resetBatchCargoProg()
    setBatchStatus(string.format("Starting — %d truck(s) queued...", #availableTrucks), "active")
    resetBatchPauseBtn()

    batchTruckThread = task.spawn(function()
        local RS   = game:GetService("ReplicatedStorage")
        local LP   = Players.LocalPlayer
        local Char = LP.Character or LP.CharacterAdded:Wait()

        local function isPointInside(point, boxCFrame, boxSize)
            local ok, r = pcall(function() return boxCFrame:PointToObjectSpace(point) end)
            if not ok then return false end
            return math.abs(r.X)<=boxSize.X/2 and math.abs(r.Y)<=boxSize.Y/2+2 and math.abs(r.Z)<=boxSize.Z/2
        end

        local allTeleportedParts = {}
        batchTruckProgBar.Visible = true; setBatchTruckProg(0, #availableTrucks)

        local trucksDone = 0
        for _, truckModel in ipairs(availableTrucks) do
            -- Pause check at every truck boundary
            if not waitWhilePaused(batchRunRef, batchPauRef) then break end

            if not (truckModel and truckModel.Parent) then
                trucksDone += 1; setBatchTruckProg(trucksDone, #availableTrucks); continue
            end

            setBatchStatus(string.format("Truck %d / %d — sitting...", trucksDone+1, #availableTrucks), "active")

            local ignoredParts     = {}
            local DidTruckTeleport = false

            local function TeleportThisTruck()
                if DidTruckTeleport then return end
                local hum  = Char and Char:FindFirstChildOfClass("Humanoid")
                local seat = hum and hum.SeatPart
                if not seat then return end
                local mainPart = seat.Parent:FindFirstChild("Main")
                if not mainPart then return end
                local TCF  = mainPart.CFrame
                local nPos = TCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                pcall(function()
                    seat.Parent:SetPrimaryPartCFrame(CFrame.new(nPos) * TCF.Rotation)
                end)
                DidTruckTeleport = true
            end

            -- Sit — retry indefinitely, never abort due to lag
            local seated = false
            while not seated do
                if not waitWhilePaused(batchRunRef, batchPauRef) then break end
                if not (truckModel and truckModel.Parent) then break end
                pcall(function() truckModel.DriveSeat:Sit(Char.Humanoid) end)
                local deadline = tick() + 2
                while tick() < deadline do
                    task.wait(0.06)
                    if Char.Humanoid and Char.Humanoid.SeatPart then
                        seated = true; break
                    end
                end
                if not seated then task.wait(0.3) end
            end

            if not seated then
                -- Fall back to raw-offset; keep going with remaining trucks.
                setBatchStatus(string.format("Truck %d / %d — no seat, raw offset...", trucksDone+1, #availableTrucks), "active")
                pcall(function()
                    local mainPart = truckModel:FindFirstChild("Main")
                    if mainPart then
                        local TCF  = mainPart.CFrame
                        local nPos = TCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                        truckModel:SetPrimaryPartCFrame(CFrame.new(nPos) * TCF.Rotation)
                    end
                end)
                trucksDone += 1; setBatchTruckProg(trucksDone, #availableTrucks)
                task.wait(tpItemSpeed)
                continue
            end

            setBatchStatus(string.format("Truck %d / %d — scanning cargo...", trucksDone+1, #availableTrucks), "active")

            local mCF, mSz = truckModel:GetBoundingBox()
            for _, p in ipairs(truckModel:GetDescendants()) do if p:IsA("BasePart") then ignoredParts[p] = true end end
            for _, p in ipairs(Char:GetDescendants())       do if p:IsA("BasePart") then ignoredParts[p] = true end end

            for _, part in ipairs(workspace:GetDescendants()) do
                if not batchTruckRunning then break end
                if part:IsA("BasePart") and not ignoredParts[part] then
                    if part.Name == "Main" or part.Name == "WoodSection" then
                        local weld = part:FindFirstChild("Weld")
                        if weld and weld.Part1 and weld.Part1.Parent ~= part.Parent then continue end
                        task.spawn(function()
                            if isPointInside(part.Position, mCF, mSz) then
                                TeleportThisTruck()
                                local PCF  = part.CFrame
                                local nP   = PCF.Position - GiveBaseOrigin.Position + ReceiverBaseOrigin.Position
                                local tOff = CFrame.new(nP) * PCF.Rotation
                                pcall(function() part.CFrame = tOff end)
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

            local cargoDeadline = tick() + 3
            repeat task.wait(0.05) until tick() >= cargoDeadline

            local SitPart = Char.Humanoid and Char.Humanoid.SeatPart
            local DoorHinge = SitPart
                and SitPart.Parent:FindFirstChild("PaintParts")
                and SitPart.Parent.PaintParts:FindFirstChild("DoorLeft")
                and SitPart.Parent.PaintParts.DoorLeft:FindFirstChild("ButtonRemote_Hinge")

            pcall(function() Char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
            task.wait(0.1)
            TeleportThisTruck()
            if SitPart and SitPart.Parent then pcall(function() SitPart:Destroy() end) end
            DidTruckTeleport = false
            task.wait(0.1)
            if DoorHinge then
                for _ = 1, 10 do pcall(function() RS.Interaction.RemoteProxy:FireServer(DoorHinge) end) end
            end

            trucksDone += 1; setBatchTruckProg(trucksDone, #availableTrucks)
            task.wait(tpItemSpeed)
        end

        -- ── Unified retry pass for ALL missed cargo across every batch truck ─
        if waitWhilePaused(batchRunRef, batchPauRef) then
            setBatchStatus("Waiting for cargo to settle...", "active")
            task.wait(2.5)

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

            if #missed > 0 then
                batchCargoProgBar.Visible = true
                retryCargo(Char, missed, GiveBaseOrigin, RS,
                    batchRunRef, batchPauRef,
                    function(d,t) setBatchCargoProg(d,t) end,
                    function(msg,state) setBatchStatus(msg,state) end, 30)
            else
                setBatchStatus(string.format("✓ %d truck(s) teleported!", trucksDone), "idle")
            end
        end

        task.wait(1)
        batchTruckRunning = false; batchTruckPaused = false
        batchTruckThread  = nil
        resetBatchPauseBtn()
        task.delay(2.1, function()
            resetBatchTruckProg()
            resetBatchCargoProg()
        end)
    end)
end)

table.insert(VH.cleanupTasks, function()
    batchTruckRunning = false; batchTruckPaused = false
    if batchTruckThread then pcall(task.cancel, batchTruckThread); batchTruckThread = nil end
end)

print("[VanillaHub] Vanilla2 loaded — black/grey/white theme · pause/resume · lag-resilient trucks")
