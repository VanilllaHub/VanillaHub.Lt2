-- ════════════════════════════════════════════════════════════════════════════════
-- VANILLA DUPE — Standalone v3
-- Fully self-contained. No _G.VH dependency.
-- Sub-tabs: Base Dupe | Single Truck | Batch Truck
-- ════════════════════════════════════════════════════════════════════════════════

local TweenService = game:GetService("TweenService")
local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")
local LP           = Players.LocalPlayer

-- ── THEME ─────────────────────────────────────────────────────────────────────
local C = {
    bg0      = Color3.fromRGB(12, 12, 16),   -- deepest bg
    bg1      = Color3.fromRGB(18, 18, 24),   -- panel bg
    bg2      = Color3.fromRGB(24, 24, 32),   -- element bg
    bg3      = Color3.fromRGB(30, 30, 42),   -- hover/input bg
    border   = Color3.fromRGB(42, 42, 60),   -- subtle border
    accent   = Color3.fromRGB(48, 48, 68),   -- active tab / selected
    text     = Color3.fromRGB(220, 218, 230),-- primary text
    textDim  = Color3.fromRGB(110, 108, 130),-- secondary text
    textMid  = Color3.fromRGB(160, 158, 180),-- mid text
    good     = Color3.fromRGB(72, 200, 110), -- success dot
    idle     = Color3.fromRGB(60, 58, 80),   -- idle dot
    btn      = Color3.fromRGB(32, 32, 44),   -- button base
    btnHov   = Color3.fromRGB(44, 44, 60),   -- button hover
    btnAct   = Color3.fromRGB(38, 38, 54),   -- button active
    tabLine  = Color3.fromRGB(70, 68, 100),  -- active tab underline
    progFill = Color3.fromRGB(90, 88, 140),  -- progress fill
    progBg   = Color3.fromRGB(22, 22, 32),   -- progress track
}

-- ── TWEEN HELPERS ─────────────────────────────────────────────────────────────
local function tw(obj, props, t, style, dir)
    return TweenService:Create(obj,
        TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
        props)
end
local function twPlay(obj, props, t, style, dir)
    tw(obj, props, t, style, dir):Play()
end

-- ════════════════════════════════════════════════════════════════════════════════
-- DESTROY PREVIOUS INSTANCE
-- ════════════════════════════════════════════════════════════════════════════════
if LP.PlayerGui:FindFirstChild("VanillaDupe") then
    LP.PlayerGui.VanillaDupe:Destroy()
end

-- ════════════════════════════════════════════════════════════════════════════════
-- SCREEN GUI + MAIN FRAME
-- ════════════════════════════════════════════════════════════════════════════════
local ScreenGui       = Instance.new("ScreenGui")
ScreenGui.Name        = "VanillaDupe"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent      = LP.PlayerGui

local Main            = Instance.new("Frame", ScreenGui)
Main.Name             = "Main"
Main.Size             = UDim2.new(0, 360, 0, 640)
Main.Position         = UDim2.new(0.5, -180, 0.5, -320)
Main.BackgroundColor3 = C.bg0
Main.BorderSizePixel  = 0
Main.Active           = true
Main.Draggable        = true
Main.ClipsDescendants = false
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Color       = C.border
mainStroke.Thickness   = 1
mainStroke.Transparency = 0.2

-- ── TITLE BAR ─────────────────────────────────────────────────────────────────
local TitleBar        = Instance.new("Frame", Main)
TitleBar.Size         = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = C.bg1
TitleBar.BorderSizePixel  = 0
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

-- cover the bottom rounded corners of the title bar
local TitleCover      = Instance.new("Frame", TitleBar)
TitleCover.Size       = UDim2.new(1, 0, 0, 10)
TitleCover.Position   = UDim2.new(0, 0, 1, -10)
TitleCover.BackgroundColor3 = C.bg1
TitleCover.BorderSizePixel  = 0

local TitleAccentLine = Instance.new("Frame", TitleBar)
TitleAccentLine.Size  = UDim2.new(1, 0, 0, 1)
TitleAccentLine.Position = UDim2.new(0, 0, 1, -1)
TitleAccentLine.BackgroundColor3 = C.border
TitleAccentLine.BorderSizePixel  = 0

-- Dot + label
local TitleDot        = Instance.new("Frame", TitleBar)
TitleDot.Size         = UDim2.new(0, 6, 0, 6)
TitleDot.Position     = UDim2.new(0, 14, 0.5, -3)
TitleDot.BackgroundColor3 = C.textDim
TitleDot.BorderSizePixel  = 0
Instance.new("UICorner", TitleDot).CornerRadius = UDim.new(1, 0)

local TitleLbl        = Instance.new("TextLabel", TitleBar)
TitleLbl.Size         = UDim2.new(1, -100, 1, 0)
TitleLbl.Position     = UDim2.new(0, 26, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Font         = Enum.Font.GothamBold
TitleLbl.TextSize     = 13
TitleLbl.TextColor3   = C.text
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.Text         = "Vanilla  ·  Dupe"

-- Minimise / Close
local function makeTitleBtn(xOffset, label, bgColor)
    local b = Instance.new("TextButton", TitleBar)
    b.Size   = UDim2.new(0, 24, 0, 24)
    b.Position = UDim2.new(1, xOffset, 0.5, -12)
    b.BackgroundColor3 = bgColor
    b.BorderSizePixel  = 0
    b.Font   = Enum.Font.GothamBold
    b.TextSize = 12
    b.TextColor3 = C.textMid
    b.Text   = label
    b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    return b
end
local MinBtn   = makeTitleBtn(-56, "–", C.bg2)
local CloseBtn = makeTitleBtn(-28, "✕", C.bg2)

local minimised = false
MinBtn.MouseButton1Click:Connect(function()
    minimised = not minimised
    MinBtn.Text = minimised and "+" or "–"
    twPlay(Main, { Size = minimised
        and UDim2.new(0, 360, 0, 40)
        or  UDim2.new(0, 360, 0, 640) }, 0.25, Enum.EasingStyle.Quint)
end)
CloseBtn.MouseButton1Click:Connect(function()
    twPlay(Main, { Size = UDim2.new(0, 360, 0, 0),
        Position = UDim2.new(0.5, -180, 0.5, 0) }, 0.2, Enum.EasingStyle.Quint)
    task.delay(0.22, function() ScreenGui:Destroy() end)
end)

-- ── SUB-TAB BAR ───────────────────────────────────────────────────────────────
local TabRow = Instance.new("Frame", Main)
TabRow.Size  = UDim2.new(1, -20, 0, 32)
TabRow.Position = UDim2.new(0, 10, 0, 46)
TabRow.BackgroundColor3 = C.bg1
TabRow.BorderSizePixel  = 0
Instance.new("UICorner", TabRow).CornerRadius = UDim.new(0, 7)
local tabRowStroke = Instance.new("UIStroke", TabRow)
tabRowStroke.Color = C.border
tabRowStroke.Thickness = 1
tabRowStroke.Transparency = 0.4

-- ── SCROLL CONTENT AREA ───────────────────────────────────────────────────────
local ContentScroll = Instance.new("ScrollingFrame", Main)
ContentScroll.Name  = "Content"
ContentScroll.Size  = UDim2.new(1, 0, 1, -86)
ContentScroll.Position = UDim2.new(0, 0, 0, 84)
ContentScroll.BackgroundTransparency = 1
ContentScroll.BorderSizePixel = 0
ContentScroll.ScrollBarThickness = 3
ContentScroll.ScrollBarImageColor3 = C.accent
ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentScroll.ClipsDescendants = true

-- ════════════════════════════════════════════════════════════════════════════════
-- SHARED UI HELPERS
-- ════════════════════════════════════════════════════════════════════════════════

-- Creates a scrollable page frame (children placed under ContentScroll)
local function makePage()
    local page = Instance.new("Frame", ContentScroll)
    page.Size  = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.Visible = false
    local layout = Instance.new("UIListLayout", page)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0, 5)
    local pad = Instance.new("UIPadding", page)
    pad.PaddingTop    = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 12)
    pad.PaddingLeft   = UDim.new(0, 10)
    pad.PaddingRight  = UDim.new(0, 10)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        -- Update ContentScroll canvas when the active page height changes
        if page.Visible then
            ContentScroll.CanvasSize = UDim2.new(0, 0, 0,
                layout.AbsoluteContentSize.Y + 20)
        end
    end)
    return page
end

local function makeLabel(parent, text)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size  = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Font  = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextColor3 = C.textDim
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text  = "  " .. string.upper(text)
    return lbl
end

local function makeSep(parent)
    local f = Instance.new("Frame", parent)
    f.Size   = UDim2.new(1, 0, 0, 1)
    f.BackgroundColor3 = C.border
    f.BorderSizePixel  = 0
    return f
end

-- Standard grey button — matches the rest of the UI
local function makeBtn(parent, text, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size  = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = C.btn
    btn.BorderSizePixel  = 0
    btn.Font  = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextColor3 = C.text
    btn.Text  = text
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local bs = Instance.new("UIStroke", btn)
    bs.Color = C.border; bs.Thickness = 1; bs.Transparency = 0.3

    btn.MouseEnter:Connect(function()
        twPlay(btn, { BackgroundColor3 = C.btnHov }, 0.12)
    end)
    btn.MouseLeave:Connect(function()
        twPlay(btn, { BackgroundColor3 = C.btn }, 0.12)
    end)
    btn.MouseButton1Down:Connect(function()
        twPlay(btn, { BackgroundColor3 = C.btnAct }, 0.08)
    end)
    btn.MouseButton1Up:Connect(function()
        twPlay(btn, { BackgroundColor3 = C.btnHov }, 0.08)
    end)
    if callback then btn.MouseButton1Click:Connect(callback) end
    return btn
end

local function makeToggle(parent, text, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size  = UDim2.new(1, 0, 0, 34)
    frame.BackgroundColor3 = C.bg2
    frame.BorderSizePixel  = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 7)
    local fs = Instance.new("UIStroke", frame)
    fs.Color = C.border; fs.Thickness = 1; fs.Transparency = 0.3

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size  = UDim2.new(1, -54, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font  = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextColor3 = C.text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text  = text

    local trackOff = Color3.fromRGB(36, 36, 50)
    local trackOn  = Color3.fromRGB(70, 130, 80)

    local tb = Instance.new("TextButton", frame)
    tb.Size  = UDim2.new(0, 36, 0, 20)
    tb.Position = UDim2.new(1, -46, 0.5, -10)
    tb.BackgroundColor3 = default and trackOn or trackOff
    tb.Text  = ""; tb.BorderSizePixel = 0; tb.AutoButtonColor = false
    Instance.new("UICorner", tb).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", tb)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, default and 18 or 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(235, 235, 245)
    knob.BorderSizePixel  = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = default
    if callback then callback(state) end
    tb.MouseButton1Click:Connect(function()
        state = not state
        twPlay(tb,   { BackgroundColor3 = state and trackOn or trackOff }, 0.18, Enum.EasingStyle.Quint)
        twPlay(knob, { Position = UDim2.new(0, state and 18 or 2, 0.5, -8) }, 0.18, Enum.EasingStyle.Quint)
        if callback then callback(state) end
    end)
    return frame, function() return state end
end

local function makeStatusBar(parent, defaultText)
    local bar = Instance.new("Frame", parent)
    bar.Size  = UDim2.new(1, 0, 0, 28)
    bar.BackgroundColor3 = C.bg1
    bar.BorderSizePixel  = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 7)
    local bs = Instance.new("UIStroke", bar)
    bs.Color = C.border; bs.Thickness = 1; bs.Transparency = 0.3

    local dot = Instance.new("Frame", bar)
    dot.Size  = UDim2.new(0, 7, 0, 7)
    dot.Position = UDim2.new(0, 11, 0.5, -3.5)
    dot.BackgroundColor3 = C.idle
    dot.BorderSizePixel  = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local lbl = Instance.new("TextLabel", bar)
    lbl.Size  = UDim2.new(1, -28, 1, 0)
    lbl.Position = UDim2.new(0, 26, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font  = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = C.textMid
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text  = defaultText or "Ready"
    lbl.TextTruncate = Enum.TextTruncate.AtEnd

    local function setStatus(msg, active)
        lbl.Text = msg
        twPlay(dot, { BackgroundColor3 = active and C.good or C.idle }, 0.2)
    end
    return bar, setStatus
end

local function makeProgressBar(parent, labelText)
    local wrap = Instance.new("Frame", parent)
    wrap.Size  = UDim2.new(1, 0, 0, 46)
    wrap.BackgroundColor3 = C.bg1
    wrap.BorderSizePixel  = 0
    wrap.Visible = false
    Instance.new("UICorner", wrap).CornerRadius = UDim.new(0, 7)
    local ws = Instance.new("UIStroke", wrap)
    ws.Color = C.border; ws.Thickness = 1; ws.Transparency = 0.3

    local topRow = Instance.new("Frame", wrap)
    topRow.Size  = UDim2.new(1, -14, 0, 18)
    topRow.Position = UDim2.new(0, 7, 0, 6)
    topRow.BackgroundTransparency = 1

    local nameLbl = Instance.new("TextLabel", topRow)
    nameLbl.Size  = UDim2.new(0.6, 0, 1, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font  = Enum.Font.GothamSemibold
    nameLbl.TextSize = 11
    nameLbl.TextColor3 = C.textMid
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.Text  = labelText

    local cntLbl = Instance.new("TextLabel", topRow)
    cntLbl.Size  = UDim2.new(0.4, 0, 1, 0)
    cntLbl.Position = UDim2.new(0.6, 0, 0, 0)
    cntLbl.BackgroundTransparency = 1
    cntLbl.Font  = Enum.Font.GothamBold
    cntLbl.TextSize = 11
    cntLbl.TextColor3 = C.text
    cntLbl.TextXAlignment = Enum.TextXAlignment.Right
    cntLbl.Text  = "0 / 0"

    local track = Instance.new("Frame", wrap)
    track.Size  = UDim2.new(1, -14, 0, 8)
    track.Position = UDim2.new(0, 7, 0, 30)
    track.BackgroundColor3 = C.progBg
    track.BorderSizePixel  = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", track)
    fill.Size  = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = C.progFill
    fill.BorderSizePixel  = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local function setProgress(done, total)
        local pct = math.clamp(done / math.max(total, 1), 0, 1)
        cntLbl.Text = done .. " / " .. total
        twPlay(fill, { Size = UDim2.new(pct, 0, 1, 0) }, 0.22, Enum.EasingStyle.Quad)
    end
    local function reset()
        fill.Size = UDim2.new(0, 0, 1, 0)
        cntLbl.Text = "0 / 0"
        wrap.Visible = false
    end
    return wrap, setProgress, reset
end

-- ── PLAYER DROPDOWN ───────────────────────────────────────────────────────────
local function makePlayerDropdown(labelText, parent)
    local selected = ""
    local isOpen   = false
    local ITEM_H   = 34
    local MAX_SHOW = 5
    local HDR_H    = 40

    local outer = Instance.new("Frame", parent)
    outer.Size  = UDim2.new(1, 0, 0, HDR_H)
    outer.BackgroundColor3 = C.bg2
    outer.BorderSizePixel  = 0
    outer.ClipsDescendants = true
    Instance.new("UICorner", outer).CornerRadius = UDim.new(0, 7)
    local outerStroke = Instance.new("UIStroke", outer)
    outerStroke.Color = C.border; outerStroke.Thickness = 1; outerStroke.Transparency = 0.3

    local header = Instance.new("Frame", outer)
    header.Size = UDim2.new(1, 0, 0, HDR_H)
    header.BackgroundTransparency = 1

    local tagLbl = Instance.new("TextLabel", header)
    tagLbl.Size  = UDim2.new(0, 68, 1, 0)
    tagLbl.Position = UDim2.new(0, 10, 0, 0)
    tagLbl.BackgroundTransparency = 1
    tagLbl.Font  = Enum.Font.GothamBold
    tagLbl.TextSize = 11
    tagLbl.TextColor3 = C.textDim
    tagLbl.TextXAlignment = Enum.TextXAlignment.Left
    tagLbl.Text  = labelText

    local selFrame = Instance.new("Frame", header)
    selFrame.Size  = UDim2.new(1, -84, 0, 28)
    selFrame.Position = UDim2.new(0, 76, 0.5, -14)
    selFrame.BackgroundColor3 = C.bg3
    selFrame.BorderSizePixel  = 0
    Instance.new("UICorner", selFrame).CornerRadius = UDim.new(0, 6)
    local selStroke = Instance.new("UIStroke", selFrame)
    selStroke.Color = C.border; selStroke.Thickness = 1; selStroke.Transparency = 0.3

    local avatar = Instance.new("ImageLabel", selFrame)
    avatar.Size  = UDim2.new(0, 20, 0, 20)
    avatar.Position = UDim2.new(0, 5, 0.5, -10)
    avatar.BackgroundColor3 = C.accent
    avatar.BorderSizePixel  = 0
    avatar.Image  = ""
    avatar.ScaleType = Enum.ScaleType.Crop
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

    local selLbl = Instance.new("TextLabel", selFrame)
    selLbl.Size  = UDim2.new(1, -56, 1, 0)
    selLbl.Position = UDim2.new(0, 30, 0, 0)
    selLbl.BackgroundTransparency = 1
    selLbl.Font  = Enum.Font.GothamSemibold
    selLbl.TextSize = 12
    selLbl.TextColor3 = C.textDim
    selLbl.TextXAlignment = Enum.TextXAlignment.Left
    selLbl.TextTruncate = Enum.TextTruncate.AtEnd
    selLbl.Text  = "Select player…"

    local arrow = Instance.new("TextLabel", selFrame)
    arrow.Size   = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -22, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Font   = Enum.Font.GothamBold
    arrow.TextSize = 12
    arrow.TextColor3 = C.textDim
    arrow.TextXAlignment = Enum.TextXAlignment.Center
    arrow.Text   = "▾"

    local hitBtn = Instance.new("TextButton", selFrame)
    hitBtn.Size  = UDim2.new(1, 0, 1, 0)
    hitBtn.BackgroundTransparency = 1
    hitBtn.Text  = ""
    hitBtn.ZIndex = 5

    local divider = Instance.new("Frame", outer)
    divider.Size  = UDim2.new(1, -12, 0, 1)
    divider.Position = UDim2.new(0, 6, 0, HDR_H)
    divider.BackgroundColor3 = C.border
    divider.BorderSizePixel  = 0
    divider.Visible = false

    local listScroll = Instance.new("ScrollingFrame", outer)
    listScroll.Position = UDim2.new(0, 0, 0, HDR_H + 2)
    listScroll.Size  = UDim2.new(1, 0, 0, 0)
    listScroll.BackgroundTransparency = 1
    listScroll.BorderSizePixel = 0
    listScroll.ScrollBarThickness = 3
    listScroll.ScrollBarImageColor3 = C.accent
    listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    listScroll.ClipsDescendants = true

    local listLayout = Instance.new("UIListLayout", listScroll)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding   = UDim.new(0, 3)
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 6)
    end)
    local lp = Instance.new("UIPadding", listScroll)
    lp.PaddingTop = UDim.new(0, 4); lp.PaddingBottom = UDim.new(0, 4)
    lp.PaddingLeft = UDim.new(0, 5); lp.PaddingRight = UDim.new(0, 5)

    local function setSelected(name, userId)
        selected = name
        selLbl.Text = name
        selLbl.TextColor3 = C.text
        outerStroke.Color = C.textDim
        if userId then
            pcall(function()
                avatar.Image = Players:GetUserThumbnailAsync(userId,
                    Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            end)
        end
    end
    local function clearSelected()
        selected = ""
        selLbl.Text = "Select player…"
        selLbl.TextColor3 = C.textDim
        avatar.Image = ""
        outerStroke.Color = C.border
    end

    local function closeList()
        isOpen = false
        twPlay(arrow,      { Rotation = 0   }, 0.2, Enum.EasingStyle.Quint)
        twPlay(outer,      { Size = UDim2.new(1, 0, 0, HDR_H) }, 0.2, Enum.EasingStyle.Quint)
        twPlay(listScroll, { Size = UDim2.new(1, 0, 0, 0) },     0.2, Enum.EasingStyle.Quint)
        divider.Visible = false
    end

    local function buildList()
        for _, c in ipairs(listScroll:GetChildren()) do
            if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
        end
        local plist = Players:GetPlayers()
        table.sort(plist, function(a, b) return a.Name < b.Name end)
        for i, plr in ipairs(plist) do
            local isSel = (plr.Name == selected)
            local row = Instance.new("Frame", listScroll)
            row.Size = UDim2.new(1, 0, 0, ITEM_H)
            row.BackgroundColor3 = isSel and C.accent or C.bg2
            row.BorderSizePixel  = 0
            row.LayoutOrder      = i
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

            local av2 = Instance.new("ImageLabel", row)
            av2.Size = UDim2.new(0, 22, 0, 22)
            av2.Position = UDim2.new(0, 7, 0.5, -11)
            av2.BackgroundColor3 = C.bg3
            av2.BorderSizePixel  = 0
            av2.ScaleType = Enum.ScaleType.Crop
            Instance.new("UICorner", av2).CornerRadius = UDim.new(1, 0)
            task.spawn(function()
                pcall(function()
                    av2.Image = Players:GetUserThumbnailAsync(plr.UserId,
                        Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                end)
            end)

            local nLbl = Instance.new("TextLabel", row)
            nLbl.Size = UDim2.new(1, -60, 1, 0)
            nLbl.Position = UDim2.new(0, 34, 0, 0)
            nLbl.BackgroundTransparency = 1
            nLbl.Font = Enum.Font.GothamSemibold
            nLbl.TextSize = 12
            nLbl.TextColor3 = isSel and C.text or C.textMid
            nLbl.TextXAlignment = Enum.TextXAlignment.Left
            nLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nLbl.Text = plr.Name

            if isSel then
                local chk = Instance.new("TextLabel", row)
                chk.Size = UDim2.new(0, 22, 1, 0)
                chk.Position = UDim2.new(1, -26, 0, 0)
                chk.BackgroundTransparency = 1
                chk.Font = Enum.Font.GothamBold
                chk.TextSize = 13
                chk.TextColor3 = C.text
                chk.TextXAlignment = Enum.TextXAlignment.Center
                chk.Text = "✓"
            end

            local rowBtn = Instance.new("TextButton", row)
            rowBtn.Size  = UDim2.new(1, 0, 1, 0)
            rowBtn.BackgroundTransparency = 1
            rowBtn.Text  = ""; rowBtn.ZIndex = 5
            rowBtn.MouseEnter:Connect(function()
                if plr.Name ~= selected then
                    twPlay(row, { BackgroundColor3 = C.bg3 }, 0.1)
                end
            end)
            rowBtn.MouseLeave:Connect(function()
                if plr.Name ~= selected then
                    twPlay(row, { BackgroundColor3 = C.bg2 }, 0.1)
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
        local cnt  = #Players:GetPlayers()
        local listH = math.min(cnt, MAX_SHOW) * (ITEM_H + 3) + 8
        divider.Visible = true
        twPlay(arrow,      { Rotation = 180 }, 0.2, Enum.EasingStyle.Quint)
        twPlay(outer,      { Size = UDim2.new(1, 0, 0, HDR_H + 2 + listH) }, 0.22, Enum.EasingStyle.Quint)
        twPlay(listScroll, { Size = UDim2.new(1, 0, 0, listH) }, 0.22, Enum.EasingStyle.Quint)
    end

    hitBtn.MouseButton1Click:Connect(function()
        if isOpen then closeList() else openList() end
    end)
    hitBtn.MouseEnter:Connect(function()
        twPlay(selFrame, { BackgroundColor3 = C.bg3 }, 0.1)
    end)
    hitBtn.MouseLeave:Connect(function()
        twPlay(selFrame, { BackgroundColor3 = C.bg3 }, 0.1)
    end)

    Players.PlayerAdded:Connect(function()
        if isOpen then buildList() end
    end)
    Players.PlayerRemoving:Connect(function(leaving)
        if leaving.Name == selected then clearSelected() end
        if isOpen then buildList() end
    end)

    return outer, function() return selected end
end

-- ════════════════════════════════════════════════════════════════════════════════
-- TAB SYSTEM
-- ════════════════════════════════════════════════════════════════════════════════
local TABS      = { "Base Dupe", "Single Truck", "Batch Trucks" }
local tabBtns   = {}
local tabPages  = {}
local activeTab = 1

local tabLayout = Instance.new("UIListLayout", TabRow)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder     = Enum.SortOrder.LayoutOrder
tabLayout.Padding       = UDim.new(0, 2)
Instance.new("UIPadding", TabRow).PaddingLeft  = UDim.new(0, 3)
Instance.new("UIPadding", TabRow).PaddingRight = UDim.new(0, 3)

-- Pages
for i = 1, #TABS do
    tabPages[i] = makePage()
end

local function switchTab(idx)
    if idx == activeTab then return end
    activeTab = idx
    for i, pg in ipairs(tabPages) do
        pg.Visible = (i == idx)
        if i == idx then
            local layout = pg:FindFirstChildOfClass("UIListLayout")
            if layout then
                ContentScroll.CanvasSize = UDim2.new(0, 0, 0,
                    layout.AbsoluteContentSize.Y + 20)
            end
        end
    end
    ContentScroll.CanvasPosition = Vector2.new(0, 0)
    for i, btn in ipairs(tabBtns) do
        local active = (i == idx)
        twPlay(btn, { BackgroundColor3 = active and C.accent or Color3.new(0,0,0) }, 0.15)
        btn.TextColor3 = active and C.text or C.textDim
        btn.BackgroundTransparency = active and 0 or 1
    end
end

for i, name in ipairs(TABS) do
    local btn = Instance.new("TextButton", TabRow)
    btn.Size  = UDim2.new(1/#TABS, -3, 1, -6)
    btn.Position = UDim2.new(0, 0, 0, 3)
    btn.BackgroundColor3 = i == 1 and C.accent or Color3.new(0,0,0)
    btn.BackgroundTransparency = i == 1 and 0 or 1
    btn.BorderSizePixel = 0
    btn.Font  = Enum.Font.GothamSemibold
    btn.TextSize = 11
    btn.TextColor3 = i == 1 and C.text or C.textDim
    btn.Text  = name
    btn.AutoButtonColor = false
    btn.LayoutOrder = i
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    btn.MouseButton1Click:Connect(function() switchTab(i) end)
    tabBtns[i] = btn
end

-- Show first page
tabPages[1].Visible = true

-- ════════════════════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS (shared across all tabs)
-- ════════════════════════════════════════════════════════════════════════════════

-- Get a character, waiting for it if needed
local function getChar()
    return LP.Character or LP.CharacterAdded:Wait()
end

-- Find bases by player name
local function findBases(giverName, receiverName)
    local gBase, rBase
    for _, v in pairs(workspace.Properties:GetDescendants()) do
        if v.Name == "Owner" then
            local val = tostring(v.Value)
            if val == giverName    then gBase = v.Parent:FindFirstChild("OriginSquare") end
            if val == receiverName then rBase = v.Parent:FindFirstChild("OriginSquare") end
        end
    end
    return gBase, rBase
end

-- Is a 3D point inside an OBB?
local function isPointInside(point, boxCFrame, boxSize)
    local r = boxCFrame:PointToObjectSpace(point)
    return math.abs(r.X) <= boxSize.X / 2
       and math.abs(r.Y) <= boxSize.Y / 2 + 2
       and math.abs(r.Z) <= boxSize.Z / 2
end

-- Get the canonical world CFrame of an item (pivot → Main → any Part)
local function getItemWorldCF(p)
    if p:FindFirstChild("MainCFrame") then return p.MainCFrame.Value end
    if p:FindFirstChild("Main")       then return p.Main.CFrame end
    local part = p:FindFirstChildOfClass("Part") or p:FindFirstChildOfClass("WedgePart")
    return part and part.CFrame or nil
end

-- Count items matching a filter in workspace.PlayerModels owned by giverName
local function countItems(giverName, typeCheck)
    local n = 0
    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
        if v.Name == "Owner" and tostring(v.Value) == giverName and typeCheck(v.Parent) then
            n += 1
        end
    end
    return n
end

-- Is an item a structure (includes glass panels that use TreeClass = "Structure")?
local function isStructure(p)
    if p:FindFirstChild("Type") and tostring(p.Type.Value) == "Structure" then return true end
    if p:FindFirstChild("TreeClass") and tostring(p.TreeClass.Value) == "Structure" then return true end
    return false
end

-- Claim network ownership of a part (fast: 15 × 0.02 s = 0.3 s)
local function claimNetOwn(Char, part)
    if not part or not part.Parent then return end
    if (Char.HumanoidRootPart.Position - part.Position).Magnitude > 25 then
        Char.HumanoidRootPart.CFrame = part.CFrame
        task.wait(0.04)
    end
    for _ = 1, 15 do
        task.wait(0.02)
        pcall(function() RS.Interaction.ClientIsDragging:FireServer(part.Parent) end)
    end
end

-- Move a single draggable item to Offset, retrying up to MAX_TRIES if it snaps back.
local MAX_ITEM_TRIES = 8
local function sendItem(Char, running, part, Offset)
    if not running() then return false end
    for _ = 1, MAX_ITEM_TRIES do
        if not (part and part.Parent) then return false end
        if not running() then return false end
        claimNetOwn(Char, part)
        local deadline = tick() + 0.35
        repeat part.CFrame = Offset; task.wait() until tick() >= deadline
        task.wait(0.08)
        if not (part and part.Parent) then return false end
        if (part.Position - Offset.Position).Magnitude <= 8 then return true end
        task.wait(0.25)
    end
    return false
end

-- ════════════════════════════════════════════════════════════════════════════════
-- PAGE 1 — BASE DUPE (Butter Leak)
-- ════════════════════════════════════════════════════════════════════════════════
local P1 = tabPages[1]

makeLabel(P1, "Players")
local _, getGiverName    = makePlayerDropdown("Giver",    P1)
local _, getReceiverName = makePlayerDropdown("Receiver", P1)

makeSep(P1)
makeLabel(P1, "What to Transfer")
local _, getStructures = makeToggle(P1, "Structures",     false)
local _, getFurniture  = makeToggle(P1, "Furniture",      false)
local _, getTrucks     = makeToggle(P1, "Trucks + Cargo", false)
local _, getGifts      = makeToggle(P1, "Gifts / Items",  false)
local _, getWood       = makeToggle(P1, "Wood",           false)

makeSep(P1)
makeLabel(P1, "Progress")
local progS,  setProgS,  resetProgS  = makeProgressBar(P1, "Structures")
local progF,  setProgF,  resetProgF  = makeProgressBar(P1, "Furniture")
local progT,  setProgT,  resetProgT  = makeProgressBar(P1, "Trucks + Cargo")
local progG,  setProgG,  resetProgG  = makeProgressBar(P1, "Gifts / Items")
local progW,  setProgW,  resetProgW  = makeProgressBar(P1, "Wood")

makeSep(P1)
local _, setStatusB = makeStatusBar(P1, "Ready")

local startBtnB = makeBtn(P1, "▶  Start", nil)
local stopBtnB  = makeBtn(P1, "■  Stop",  nil)

-- ── Logic ─────────────────────────────────────────────────────────────────────
local butterRunning = false
local butterThread  = nil

local function resetButter()
    resetProgS(); resetProgF(); resetProgT(); resetProgG(); resetProgW()
end

stopBtnB.MouseButton1Click:Connect(function()
    butterRunning = false
    if butterThread then pcall(task.cancel, butterThread); butterThread = nil end
    setStatusB("Stopped", false)
    resetButter()
end)

startBtnB.MouseButton1Click:Connect(function()
    if butterRunning then setStatusB("Already running!", true) return end
    local giverName    = getGiverName()
    local receiverName = getReceiverName()
    if giverName == "" or receiverName == "" then
        setStatusB("⚠  Select both players!", false) return
    end

    butterRunning = true
    setStatusB("Finding bases…", true)
    resetButter()

    butterThread = task.spawn(function()
        local Char = getChar()
        local giveOrigin, recvOrigin = findBases(giverName, receiverName)

        if not (giveOrigin and recvOrigin) then
            setStatusB("⚠  Couldn't find bases!", false)
            butterRunning = false; butterThread = nil; return
        end

        local giveOriginCF = giveOrigin.CFrame
        local recvOriginCF = recvOrigin.CFrame

        local function running() return butterRunning end

        -- ── STRUCTURES (incl. glass panels) ───────────────────────────────
        if getStructures() and butterRunning then
            local total = countItems(giverName, function(p)
                return isStructure(p) and (p:FindFirstChild("MainCFrame")
                    or p:FindFirstChild("Main") or p:FindFirstChildOfClass("Part")
                    or p:FindFirstChildOfClass("WedgePart"))
            end)
            if total > 0 then
                progS.Visible = true; setProgS(0, total)
                setStatusB("Sending structures…", true)
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
                                        RS.PlaceStructure.ClientPlacedStructure:FireServer(
                                            p.ItemName.Value, Off, LP, DA, p, true)
                                    end)
                                until not p.Parent
                                done += 1; setProgS(done, total)
                            end
                        end
                    end
                end)
                setProgS(total, total)
            end
        end

        -- ── FURNITURE ─────────────────────────────────────────────────────
        if getFurniture() and butterRunning then
            local total = countItems(giverName, function(p)
                return p:FindFirstChild("Type") and tostring(p.Type.Value) == "Furniture"
                    and (p:FindFirstChild("MainCFrame") or p:FindFirstChild("Main")
                         or p:FindFirstChildOfClass("Part"))
            end)
            if total > 0 then
                progF.Visible = true; setProgF(0, total)
                setStatusB("Sending furniture…", true)
                local done = 0
                pcall(function()
                    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                        if not butterRunning then break end
                        if v.Name == "Owner" and tostring(v.Value) == giverName then
                            local p = v.Parent
                            if p:FindFirstChild("Type") and tostring(p.Type.Value) == "Furniture" then
                                local PCF = getItemWorldCF(p)
                                if not PCF then continue end
                                local DA  = p:FindFirstChild("BlueprintWoodClass") and p.BlueprintWoodClass.Value or nil
                                local Off = recvOriginCF:ToWorldSpace(giveOriginCF:ToObjectSpace(PCF))
                                repeat task.wait()
                                    pcall(function()
                                        RS.PlaceStructure.ClientPlacedStructure:FireServer(
                                            p.ItemName.Value, Off, LP, DA, p, true)
                                    end)
                                until not p.Parent
                                done += 1; setProgF(done, total)
                            end
                        end
                    end
                end)
                setProgF(total, total)
            end
        end

        -- ── TRUCKS + CARGO ────────────────────────────────────────────────
        -- Seats are visited one at a time, every 2 s.
        -- Before moving on, missed cargo around the current seat is checked.
        if getTrucks() and butterRunning then
            local teleportedParts = {}
            local ignoredParts    = {}

            local truckList = {}
            for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                if v.Name == "Owner" and tostring(v.Value) == giverName
                    and v.Parent:FindFirstChild("DriveSeat") then
                    table.insert(truckList, v.Parent)
                end
            end
            local truckCount = #truckList

            if truckCount > 0 then
                progT.Visible = true; setProgT(0, truckCount)
                setStatusB("Sending trucks…", true)
                local truckDone = 0

                for _, truckModel in ipairs(truckList) do
                    if not butterRunning then break end
                    if not (truckModel and truckModel.Parent) then
                        truckDone += 1; setProgT(truckDone, truckCount); continue
                    end

                    local DidTeleport = false
                    local localIgnored = {}

                    local function TeleportTruck()
                        if DidTeleport then return end
                        if not Char.Humanoid.SeatPart then return end
                        local TCF  = Char.Humanoid.SeatPart.Parent:FindFirstChild("Main").CFrame
                        local nPos = TCF.Position - giveOrigin.Position + recvOrigin.Position
                        Char.Humanoid.SeatPart.Parent:SetPrimaryPartCFrame(CFrame.new(nPos) * TCF.Rotation)
                        DidTeleport = true
                    end

                    truckModel.DriveSeat:Sit(Char.Humanoid)
                    repeat task.wait() truckModel.DriveSeat:Sit(Char.Humanoid) until Char.Humanoid.SeatPart

                    local mCF, mSz = truckModel:GetBoundingBox()
                    for _, p in ipairs(truckModel:GetDescendants()) do
                        if p:IsA("BasePart") then ignoredParts[p] = true; localIgnored[p] = true end
                    end
                    for _, p in ipairs(Char:GetDescendants()) do
                        if p:IsA("BasePart") then ignoredParts[p] = true end
                    end

                    -- Scan cargo inside this truck's bounding box
                    for _, part in ipairs(workspace:GetDescendants()) do
                        if part:IsA("BasePart") and not ignoredParts[part] then
                            if part.Name == "Main" or part.Name == "WoodSection" then
                                if part:FindFirstChild("Weld") and part.Weld.Part1
                                    and part.Weld.Part1.Parent ~= part.Parent then continue end
                                task.spawn(function()
                                    if isPointInside(part.Position, mCF, mSz) then
                                        TeleportTruck()
                                        local PCF  = part.CFrame
                                        local nP   = PCF.Position - giveOrigin.Position + recvOrigin.Position
                                        local tOff = CFrame.new(nP) * PCF.Rotation
                                        part.CFrame = tOff
                                        task.wait(0.3)
                                        table.insert(teleportedParts, {
                                            Instance = part, TargetCFrame = tOff })
                                    end
                                end)
                            end
                        end
                    end

                    -- Wait for task.spawns to record, then do a quick local missed-check
                    task.wait(1)

                    local localMissed = {}
                    for _, data in ipairs(teleportedParts) do
                        if localIgnored[data.Instance] then continue end
                        if data.Instance and data.Instance.Parent then
                            if (data.Instance.Position - data.TargetCFrame.Position).Magnitude > 8 then
                                local distFromGiver = (data.Instance.Position - giveOrigin.Position).Magnitude
                                if distFromGiver < 500 then
                                    table.insert(localMissed, data)
                                end
                            end
                        end
                    end

                    -- Retry any missed cargo before switching seats
                    if #localMissed > 0 then
                        setStatusB(string.format("Checking seat %d cargo (%d missed)…",
                            truckDone + 1, #localMissed), true)
                        for _, data in ipairs(localMissed) do
                            if not butterRunning then break end
                            local item = data.Instance
                            if not (item and item.Parent) then continue end
                            local tries = 0
                            while (Char.HumanoidRootPart.Position - item.Position).Magnitude > 25 and tries < 15 do
                                Char.HumanoidRootPart.CFrame = item.CFrame; task.wait(0.1); tries += 1
                            end
                            RS.Interaction.ClientIsDragging:FireServer(item.Parent)
                            task.wait(0.5)
                            item.CFrame = data.TargetCFrame
                            task.wait(0.25)
                        end
                    end

                    -- Eject and close door
                    local SitPart = Char.Humanoid.SeatPart
                    local DoorHinge = SitPart.Parent:FindFirstChild("PaintParts")
                        and SitPart.Parent.PaintParts:FindFirstChild("DoorLeft")
                        and SitPart.Parent.PaintParts.DoorLeft:FindFirstChild("ButtonRemote_Hinge")
                    task.wait()
                    Char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.1); SitPart:Destroy(); TeleportTruck(); DidTeleport = false; task.wait(0.1)
                    if DoorHinge then
                        for _ = 1, 10 do RS.Interaction.RemoteProxy:FireServer(DoorHinge) end
                    end

                    truckDone += 1; setProgT(truckDone, truckCount)
                    -- 2-second gap between seats (as requested)
                    task.wait(2)
                end

                -- Global missed-cargo retry after all trucks processed
                task.wait(1)
                local function getMissed()
                    local missed = {}
                    for _, data in ipairs(teleportedParts) do
                        if data.Instance and data.Instance.Parent then
                            if (data.Instance.Position - data.TargetCFrame.Position).Magnitude > 8 then
                                if (data.Instance.Position - giveOrigin.Position).Magnitude < 500 then
                                    table.insert(missed, data)
                                end
                            end
                        end
                    end
                    return missed
                end

                local missedList = getMissed()
                if #missedList > 0 then
                    progT.Visible = true; setProgT(0, #missedList)
                    local missedTotal = #missedList; local attempt = 0; local done2 = 0
                    while #missedList > 0 and butterRunning and attempt < 25 do
                        attempt += 1
                        setStatusB(string.format("Cargo retry %d/25 — %d left…", attempt, #missedList), true)
                        for _, data in ipairs(missedList) do
                            if not butterRunning then break end
                            local item = data.Instance
                            if not (item and item.Parent) then continue end
                            local tries = 0
                            while (Char.HumanoidRootPart.Position - item.Position).Magnitude > 25 and tries < 15 do
                                Char.HumanoidRootPart.CFrame = item.CFrame; task.wait(0.1); tries += 1
                            end
                            RS.Interaction.ClientIsDragging:FireServer(item.Parent)
                            task.wait(0.5); item.CFrame = data.TargetCFrame; task.wait(0.25)
                            done2 += 1; setProgT(done2, missedTotal); task.wait()
                        end
                        task.wait(1); missedList = getMissed()
                        local confirmed = missedTotal - #missedList
                        if confirmed > done2 then done2 = confirmed; setProgT(done2, missedTotal) end
                    end
                    setProgT(missedTotal, missedTotal)
                    setStatusB(#missedList == 0 and "✓ Cargo done!" or
                        string.format("Gave up — %d missed", #missedList), #missedList == 0)
                    task.wait(1)
                else
                    setProgT(truckCount, truckCount)
                end
            end
        end

        -- ── GIFTS / ITEMS ─────────────────────────────────────────────────
        if getGifts() and butterRunning then
            local total = countItems(giverName, function(p)
                return p:FindFirstChildOfClass("Script") and p:FindFirstChild("DraggableItem")
                    and (p:FindFirstChild("Main") or p:FindFirstChildOfClass("Part"))
            end)
            if total > 0 then
                progG.Visible = true; setProgG(0, total)
                setStatusB("Sending gifts / items…", true)
                local done = 0; local retried = 0
                pcall(function()
                    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                        if not butterRunning then break end
                        if v.Name == "Owner" and tostring(v.Value) == giverName then
                            local p = v.Parent
                            if p:FindFirstChildOfClass("Script") and p:FindFirstChild("DraggableItem") then
                                local part = p:FindFirstChild("Main") or p:FindFirstChildOfClass("Part")
                                if not part then continue end
                                local PCF    = (p:FindFirstChild("Main") and p.Main.CFrame)
                                             or p:FindFirstChildOfClass("Part").CFrame
                                local nPos   = PCF.Position - giveOrigin.Position + recvOrigin.Position
                                local Offset = CFrame.new(nPos) * PCF.Rotation
                                local ok     = sendItem(Char, function() return butterRunning end, part, Offset)
                                if not ok then retried += 1 end
                                done += 1; setProgG(done, total)
                            end
                        end
                    end
                end)
                setProgG(total, total)
                if retried > 0 then
                    setStatusB(string.format("Gifts done (%d needed retries)", retried), true)
                    task.wait(1.5)
                end
            end
        end

        -- ── WOOD ──────────────────────────────────────────────────────────
        -- Exclude glass panels: they use TreeClass = "Structure".
        if getWood() and butterRunning then
            local total = countItems(giverName, function(p)
                return p:FindFirstChild("TreeClass")
                    and tostring(p.TreeClass.Value) ~= "Structure"
                    and (p:FindFirstChild("Main") or p:FindFirstChildOfClass("Part"))
            end)
            if total > 0 then
                progW.Visible = true; setProgW(0, total)
                setStatusB("Sending wood…", true)
                local done = 0; local retried = 0
                pcall(function()
                    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
                        if not butterRunning then break end
                        if v.Name == "Owner" and tostring(v.Value) == giverName then
                            local p = v.Parent
                            if p:FindFirstChild("TreeClass")
                                and tostring(p.TreeClass.Value) ~= "Structure" then
                                local part = p:FindFirstChild("Main") or p:FindFirstChildOfClass("Part")
                                if not part then continue end
                                local PCF    = (p:FindFirstChild("Main") and p.Main.CFrame)
                                             or p:FindFirstChildOfClass("Part").CFrame
                                local nPos   = PCF.Position - giveOrigin.Position + recvOrigin.Position
                                local Offset = CFrame.new(nPos) * PCF.Rotation
                                local ok     = sendItem(Char, function() return butterRunning end, part, Offset)
                                if not ok then retried += 1 end
                                done += 1; setProgW(done, total)
                            end
                        end
                    end
                end)
                setProgW(total, total)
                if retried > 0 then
                    setStatusB(string.format("Wood done (%d needed retries)", retried), true)
                    task.wait(1.5)
                end
            end
        end

        if butterRunning then setStatusB("✓ Done!", false) end
        butterRunning = false; butterThread = nil
    end)
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- PAGE 2 — SINGLE TRUCK TELEPORT
-- ════════════════════════════════════════════════════════════════════════════════
local P2 = tabPages[2]

makeLabel(P2, "Players")
local _, getSGiver    = makePlayerDropdown("Giver",    P2)
local _, getSReceiver = makePlayerDropdown("Receiver", P2)

makeSep(P2)
makeLabel(P2, "Progress")
local sProgBar, setSProg, resetSProg = makeProgressBar(P2, "Truck + Cargo")

local _, setStatusS = makeStatusBar(P2, "Ready — sit in a truck first")

local singleRunning = false
local singleThread  = nil

local sStopBtn = makeBtn(P2, "■  Stop", nil)
sStopBtn.Visible = false

sStopBtn.MouseButton1Click:Connect(function()
    singleRunning = false
    if singleThread then pcall(task.cancel, singleThread); singleThread = nil end
    setStatusS("Stopped", false); resetSProg()
    sStopBtn.Visible = false
end)

makeBtn(P2, "▶  Start", nil, function()
    if singleRunning then setStatusS("Already running!", true) return end
    local Char = LP.Character
    if not Char then setStatusS("No character!", false) return end
    local hum = Char:FindFirstChildOfClass("Humanoid")
    if not (hum and hum.SeatPart) then setStatusS("Not sitting in a truck!", false) return end
    local truckModel = hum.SeatPart.Parent
    if not truckModel:FindFirstChild("DriveSeat") then
        setStatusS("Not a DriveSeat!", false) return
    end
    local gName = getSGiver(); local rName = getSReceiver()
    if gName == "" or rName == "" then setStatusS("Select both players!", false) return end

    local giveOrigin, recvOrigin = findBases(gName, rName)
    if not giveOrigin     then setStatusS("Giver base not found!",    false) return end
    if not recvOrigin     then setStatusS("Receiver base not found!", false) return end

    singleRunning = true; sStopBtn.Visible = true
    resetSProg(); setStatusS("Sending truck…", true)

    singleThread = task.spawn(function()
        local teleportedParts = {}; local ignoredParts = {}; local DidTeleport = false

        local function TeleportTruck()
            if DidTeleport then return end
            if not Char.Humanoid.SeatPart then return end
            local TCF  = Char.Humanoid.SeatPart.Parent:FindFirstChild("Main").CFrame
            local nPos = TCF.Position - giveOrigin.Position + recvOrigin.Position
            Char.Humanoid.SeatPart.Parent:SetPrimaryPartCFrame(CFrame.new(nPos) * TCF.Rotation)
            DidTeleport = true
        end

        sProgBar.Visible = true; setSProg(0, 1)
        truckModel.DriveSeat:Sit(Char.Humanoid)
        repeat task.wait() truckModel.DriveSeat:Sit(Char.Humanoid) until Char.Humanoid.SeatPart

        local mCF, mSz = truckModel:GetBoundingBox()
        for _, p in ipairs(truckModel:GetDescendants()) do if p:IsA("BasePart") then ignoredParts[p] = true end end
        for _, p in ipairs(Char:GetDescendants())       do if p:IsA("BasePart") then ignoredParts[p] = true end end

        for _, part in ipairs(workspace:GetDescendants()) do
            if not singleRunning then break end
            if part:IsA("BasePart") and not ignoredParts[part] then
                if part.Name == "Main" or part.Name == "WoodSection" then
                    if part:FindFirstChild("Weld") and part.Weld.Part1
                        and part.Weld.Part1.Parent ~= part.Parent then continue end
                    task.spawn(function()
                        if isPointInside(part.Position, mCF, mSz) then
                            TeleportTruck()
                            local PCF  = part.CFrame
                            local nP   = PCF.Position - giveOrigin.Position + recvOrigin.Position
                            local tOff = CFrame.new(nP) * PCF.Rotation
                            part.CFrame = tOff; task.wait(0.3)
                            table.insert(teleportedParts, { Instance = part, TargetCFrame = tOff })
                        end
                    end)
                end
            end
        end

        local SitPart = Char.Humanoid.SeatPart
        local DoorHinge = SitPart.Parent:FindFirstChild("PaintParts")
            and SitPart.Parent.PaintParts:FindFirstChild("DoorLeft")
            and SitPart.Parent.PaintParts.DoorLeft:FindFirstChild("ButtonRemote_Hinge")
        task.wait(); Char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping); task.wait(0.1)
        SitPart:Destroy(); TeleportTruck(); DidTeleport = false; task.wait(0.1)
        if DoorHinge then for _ = 1, 10 do RS.Interaction.RemoteProxy:FireServer(DoorHinge) end end
        setSProg(1, 1)
        task.wait(2)

        local function getMissed()
            local missed = {}
            for _, data in ipairs(teleportedParts) do
                if data.Instance and data.Instance.Parent then
                    if (data.Instance.Position - data.TargetCFrame.Position).Magnitude > 8 then
                        if (data.Instance.Position - giveOrigin.Position).Magnitude < 500 then
                            table.insert(missed, data)
                        end
                    end
                end
            end
            return missed
        end

        local missedList = getMissed()
        if #missedList > 0 then
            sProgBar.Visible = true; setSProg(0, #missedList)
            local missedTotal = #missedList; local attempt = 0; local done2 = 0
            while #missedList > 0 and singleRunning and attempt < 25 do
                attempt += 1
                setStatusS(string.format("Cargo retry %d/25 — %d left…", attempt, #missedList), true)
                for _, data in ipairs(missedList) do
                    if not singleRunning then break end
                    local item = data.Instance
                    if not (item and item.Parent) then continue end
                    local tries = 0
                    while (Char.HumanoidRootPart.Position - item.Position).Magnitude > 25 and tries < 15 do
                        Char.HumanoidRootPart.CFrame = item.CFrame; task.wait(0.1); tries += 1
                    end
                    RS.Interaction.ClientIsDragging:FireServer(item.Parent)
                    task.wait(0.5); item.CFrame = data.TargetCFrame; task.wait(0.25)
                    done2 += 1; setSProg(done2, missedTotal); task.wait()
                end
                task.wait(1); missedList = getMissed()
                local confirmed = missedTotal - #missedList
                if confirmed > done2 then done2 = confirmed; setSProg(done2, missedTotal) end
            end
            setSProg(missedTotal, missedTotal)
            setStatusS(#missedList == 0 and "✓ All cargo teleported!" or
                string.format("Gave up — %d missed", #missedList), #missedList == 0)
        else
            setStatusS("✓ Truck teleported! (no cargo found)", false)
        end

        task.wait(1)
        singleRunning = false; singleThread = nil; sStopBtn.Visible = false
    end)
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- PAGE 3 — BATCH TRUCK TELEPORT
-- ════════════════════════════════════════════════════════════════════════════════
local P3 = tabPages[3]

makeLabel(P3, "Players")
local _, getBGiver    = makePlayerDropdown("Giver",    P3)
local _, getBReceiver = makePlayerDropdown("Receiver", P3)

makeSep(P3)

-- Count input row
local countRow = Instance.new("Frame", P3)
countRow.Size  = UDim2.new(1, 0, 0, 36)
countRow.BackgroundColor3 = C.bg2
countRow.BorderSizePixel  = 0
Instance.new("UICorner", countRow).CornerRadius = UDim.new(0, 7)
local crs = Instance.new("UIStroke", countRow)
crs.Color = C.border; crs.Thickness = 1; crs.Transparency = 0.3

local countLbl = Instance.new("TextLabel", countRow)
countLbl.Size  = UDim2.new(1, -80, 1, 0)
countLbl.Position = UDim2.new(0, 12, 0, 0)
countLbl.BackgroundTransparency = 1
countLbl.Font  = Enum.Font.GothamSemibold
countLbl.TextSize = 13
countLbl.TextColor3 = C.text
countLbl.TextXAlignment = Enum.TextXAlignment.Left
countLbl.Text  = "Trucks to Teleport"

local countBox = Instance.new("TextBox", countRow)
countBox.Size  = UDim2.new(0, 60, 0, 24)
countBox.Position = UDim2.new(1, -68, 0.5, -12)
countBox.BackgroundColor3 = C.bg3
countBox.BorderSizePixel  = 0
countBox.Font  = Enum.Font.GothamBold
countBox.TextSize = 13
countBox.TextColor3 = C.text
countBox.PlaceholderText = "e.g. 3"
countBox.PlaceholderColor3 = C.textDim
countBox.Text  = ""
countBox.TextXAlignment = Enum.TextXAlignment.Center
countBox.ClearTextOnFocus = false
Instance.new("UICorner", countBox).CornerRadius = UDim.new(0, 6)
local cbs = Instance.new("UIStroke", countBox)
cbs.Color = C.border; cbs.Thickness = 1; cbs.Transparency = 0.3

countBox:GetPropertyChangedSignal("Text"):Connect(function()
    local clean = countBox.Text:gsub("[^%d]", "")
    if clean ~= countBox.Text then countBox.Text = clean end
end)

makeSep(P3)
makeLabel(P3, "Progress")
local bTruckProg, setBTruckProg, resetBTruckProg = makeProgressBar(P3, "Trucks")
local bCargoProg, setBCargoProg, resetBCargoProg = makeProgressBar(P3, "Missed Cargo")

local _, setStatusBatch = makeStatusBar(P3, "Ready — enter a truck count")

local batchRunning = false
local batchThread  = nil

local bStopBtn = makeBtn(P3, "■  Stop Batch", nil)
bStopBtn.Visible = false

bStopBtn.MouseButton1Click:Connect(function()
    batchRunning = false
    if batchThread then pcall(task.cancel, batchThread); batchThread = nil end
    setStatusBatch("Stopped", false)
    resetBTruckProg(); resetBCargoProg()
    bStopBtn.Visible = false
end)

makeBtn(P3, "▶  Start Batch", nil, function()
    if batchRunning then setStatusBatch("Already running!", true) return end
    local gName = getBGiver(); local rName = getBReceiver()
    if gName == "" or rName == "" then setStatusBatch("Select both players!", false) return end

    local wantedCount = tonumber(countBox.Text)
    if not wantedCount or wantedCount < 1 then
        setStatusBatch("⚠  Enter a valid count!", false) return
    end
    wantedCount = math.floor(wantedCount)

    local availableTrucks = {}
    for _, v in pairs(workspace.PlayerModels:GetDescendants()) do
        if v.Name == "Owner" and tostring(v.Value) == gName
            and v.Parent:FindFirstChild("DriveSeat") then
            table.insert(availableTrucks, v.Parent)
        end
    end
    local actualCount = #availableTrucks
    if actualCount == 0 then setStatusBatch("⚠  No trucks on giver's plot!", false) return end

    if wantedCount < actualCount then
        setStatusBatch(string.format("Teleporting %d of %d trucks…", wantedCount, actualCount), false)
        while #availableTrucks > wantedCount do table.remove(availableTrucks) end
        task.wait(2)
    elseif wantedCount > actualCount then
        setStatusBatch(string.format("Only %d found — teleporting all", actualCount), false)
        wantedCount = actualCount; task.wait(2)
    end

    local giveOrigin, recvOrigin = findBases(gName, rName)
    if not giveOrigin then setStatusBatch("Giver base not found!",    false) return end
    if not recvOrigin then setStatusBatch("Receiver base not found!", false) return end

    batchRunning = true; bStopBtn.Visible = true
    resetBTruckProg(); resetBCargoProg()
    setStatusBatch(string.format("Starting — %d truck(s) queued…", #availableTrucks), true)

    batchThread = task.spawn(function()
        local Char = getChar()
        local allTeleportedParts = {}

        bTruckProg.Visible = true; setBTruckProg(0, #availableTrucks)
        local trucksDone = 0

        for _, truckModel in ipairs(availableTrucks) do
            if not batchRunning then break end
            if not (truckModel and truckModel.Parent) then
                trucksDone += 1; setBTruckProg(trucksDone, #availableTrucks); continue
            end

            setStatusBatch(string.format("Truck %d / %d…", trucksDone + 1, #availableTrucks), true)

            local ignoredParts = {}; local DidTeleport = false

            local function TeleportThisTruck()
                if DidTeleport then return end
                if not Char.Humanoid.SeatPart then return end
                local TCF  = Char.Humanoid.SeatPart.Parent:FindFirstChild("Main").CFrame
                local nPos = TCF.Position - giveOrigin.Position + recvOrigin.Position
                Char.Humanoid.SeatPart.Parent:SetPrimaryPartCFrame(CFrame.new(nPos) * TCF.Rotation)
                DidTeleport = true
            end

            truckModel.DriveSeat:Sit(Char.Humanoid)
            repeat task.wait() truckModel.DriveSeat:Sit(Char.Humanoid) until Char.Humanoid.SeatPart

            local mCF, mSz = truckModel:GetBoundingBox()
            for _, p in ipairs(truckModel:GetDescendants()) do if p:IsA("BasePart") then ignoredParts[p] = true end end
            for _, p in ipairs(Char:GetDescendants())       do if p:IsA("BasePart") then ignoredParts[p] = true end end

            for _, part in ipairs(workspace:GetDescendants()) do
                if not batchRunning then break end
                if part:IsA("BasePart") and not ignoredParts[part] then
                    if part.Name == "Main" or part.Name == "WoodSection" then
                        if part:FindFirstChild("Weld") and part.Weld.Part1
                            and part.Weld.Part1.Parent ~= part.Parent then continue end
                        task.spawn(function()
                            if isPointInside(part.Position, mCF, mSz) then
                                TeleportThisTruck()
                                local PCF  = part.CFrame
                                local nP   = PCF.Position - giveOrigin.Position + recvOrigin.Position
                                local tOff = CFrame.new(nP) * PCF.Rotation
                                part.CFrame = tOff; task.wait(0.3)
                                table.insert(allTeleportedParts, { Instance = part, TargetCFrame = tOff })
                            end
                        end)
                    end
                end
            end

            -- Wait, then do local missed-cargo check before moving on
            task.wait(1)
            local localMissed = {}
            for _, data in ipairs(allTeleportedParts) do
                if ignoredParts[data.Instance] then continue end
                if data.Instance and data.Instance.Parent then
                    if (data.Instance.Position - data.TargetCFrame.Position).Magnitude > 8 then
                        if (data.Instance.Position - giveOrigin.Position).Magnitude < 500 then
                            table.insert(localMissed, data)
                        end
                    end
                end
            end
            if #localMissed > 0 then
                setStatusBatch(string.format("Seat %d: checking %d missed…",
                    trucksDone + 1, #localMissed), true)
                for _, data in ipairs(localMissed) do
                    if not batchRunning then break end
                    local item = data.Instance
                    if not (item and item.Parent) then continue end
                    local tries = 0
                    while (Char.HumanoidRootPart.Position - item.Position).Magnitude > 25 and tries < 15 do
                        Char.HumanoidRootPart.CFrame = item.CFrame; task.wait(0.1); tries += 1
                    end
                    RS.Interaction.ClientIsDragging:FireServer(item.Parent)
                    task.wait(0.5); item.CFrame = data.TargetCFrame; task.wait(0.25)
                end
            end

            local SitPart = Char.Humanoid.SeatPart
            local DoorHinge = SitPart.Parent:FindFirstChild("PaintParts")
                and SitPart.Parent.PaintParts:FindFirstChild("DoorLeft")
                and SitPart.Parent.PaintParts.DoorLeft:FindFirstChild("ButtonRemote_Hinge")
            task.wait(); Char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping); task.wait(0.1)
            SitPart:Destroy(); TeleportThisTruck(); DidTeleport = false; task.wait(0.1)
            if DoorHinge then for _ = 1, 10 do RS.Interaction.RemoteProxy:FireServer(DoorHinge) end end

            trucksDone += 1; setBTruckProg(trucksDone, #availableTrucks)
            task.wait(2)   -- 2-second gap between trucks
        end

        -- Global missed-cargo pass
        task.wait(1)
        local function getMissedBatch()
            local missed = {}
            for _, data in ipairs(allTeleportedParts) do
                if data.Instance and data.Instance.Parent then
                    if (data.Instance.Position - data.TargetCFrame.Position).Magnitude > 8 then
                        if (data.Instance.Position - giveOrigin.Position).Magnitude < 500 then
                            table.insert(missed, data)
                        end
                    end
                end
            end
            return missed
        end

        local missedList = getMissedBatch()
        if #missedList > 0 then
            bCargoProg.Visible = true; setBCargoProg(0, #missedList)
            local missedTotal = #missedList; local attempt = 0; local done2 = 0
            while #missedList > 0 and batchRunning and attempt < 25 do
                attempt += 1
                setStatusBatch(string.format("Cargo retry %d/25 — %d left…", attempt, #missedList), true)
                for _, data in ipairs(missedList) do
                    if not batchRunning then break end
                    local item = data.Instance
                    if not (item and item.Parent) then continue end
                    local tries = 0
                    while (Char.HumanoidRootPart.Position - item.Position).Magnitude > 25 and tries < 15 do
                        Char.HumanoidRootPart.CFrame = item.CFrame; task.wait(0.1); tries += 1
                    end
                    RS.Interaction.ClientIsDragging:FireServer(item.Parent)
                    task.wait(0.5); item.CFrame = data.TargetCFrame; task.wait(0.25)
                    done2 += 1; setBCargoProg(done2, missedTotal); task.wait()
                end
                task.wait(1); missedList = getMissedBatch()
                local confirmed = missedTotal - #missedList
                if confirmed > done2 then done2 = confirmed; setBCargoProg(done2, missedTotal) end
            end
            setBCargoProg(missedTotal, missedTotal)
            setStatusBatch(#missedList == 0 and "✓ All trucks + cargo done!" or
                string.format("Gave up — %d missed", #missedList), #missedList == 0)
        else
            setStatusBatch(string.format("✓ %d truck(s) teleported!", trucksDone), false)
        end

        task.wait(1)
        batchRunning = false; batchThread = nil; bStopBtn.Visible = false
    end)
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- ENTRY ANIMATION
-- ════════════════════════════════════════════════════════════════════════════════
Main.Size     = UDim2.new(0, 360, 0, 0)
Main.Position = UDim2.new(0.5, -180, 0.5, 0)
Main.BackgroundTransparency = 1
twPlay(Main, {
    Size     = UDim2.new(0, 360, 0, 640),
    Position = UDim2.new(0.5, -180, 0.5, -320),
    BackgroundTransparency = 0,
}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

print("[VanillaDupe] v3 loaded.")
