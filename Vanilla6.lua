-- ════════════════════════════════════════════════════
-- VANILLA6 — FULL REWRITE (Aggressive Bypass Edition)
-- AutoBuy + Slot Tab
-- ════════════════════════════════════════════════════

if not _G.VH then
    warn("[VanillaHub] Vanilla6: _G.VH not found. Load Vanilla1 first.")
    return
end

local VH         = _G.VH
local TS         = VH.TweenService
local Players    = VH.Players
local RS         = game:GetService("ReplicatedStorage")
local UIS        = VH.UserInputService
local RunService = VH.RunService
local LP         = Players.LocalPlayer

local THEME_TEXT = VH.THEME_TEXT  -- near-white (set in Vanilla1)
local BTN_COLOR  = VH.BTN_COLOR   -- grey (set in Vanilla1)
local BTN_HOVER  = VH.BTN_HOVER   -- lighter grey
local pages      = VH.pages

-- ════════════════════════════════════════════════════
-- THEME  (Black / Grey / White only)
-- ════════════════════════════════════════════════════
local C = {
    BG         = Color3.fromRGB(10,  10,  10 ),
    CARD       = Color3.fromRGB(20,  20,  20 ),
    ROW        = Color3.fromRGB(28,  28,  28 ),
    INPUT      = Color3.fromRGB(30,  30,  30 ),
    TRACK      = Color3.fromRGB(38,  38,  38 ),
    BORDER     = Color3.fromRGB(55,  55,  55 ),
    BORDER_DIM = Color3.fromRGB(40,  40,  40 ),
    TEXT       = Color3.fromRGB(210, 210, 210),
    TEXT_MID   = Color3.fromRGB(150, 150, 150),
    TEXT_DIM   = Color3.fromRGB(90,  90,  90 ),
    BTN        = Color3.fromRGB(70,  70,  70 ),
    BTN_HV     = Color3.fromRGB(100, 100, 100),
    FILL       = Color3.fromRGB(255, 255, 255),   -- white bar
    FILL_MID   = Color3.fromRGB(200, 200, 200),   -- mid-white fill
    SW_ON      = Color3.fromRGB(220, 220, 220),
    SW_OFF     = Color3.fromRGB(50,  50,  50 ),
    KNOB_ON    = Color3.fromRGB(30,  30,  30 ),
    KNOB_OFF   = Color3.fromRGB(160, 160, 160),
    DOT_IDLE   = Color3.fromRGB(70,  70,  70 ),
    DOT_ACT    = Color3.fromRGB(200, 200, 200),
    GLOW       = Color3.fromRGB(75,  75,  75 ),
}

-- ════════════════════════════════════════════════════
-- UI HELPERS
-- ════════════════════════════════════════════════════
local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
end

local function sectionLabel(page, text)
    local lbl = Instance.new("TextLabel", page)
    lbl.Size               = UDim2.new(1, -12, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 11
    lbl.TextColor3         = C.TEXT_DIM
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 4)
end

local function sep(page)
    local s = Instance.new("Frame", page)
    s.Size             = UDim2.new(1, -12, 0, 1)
    s.BackgroundColor3 = C.BORDER
    s.BorderSizePixel  = 0
end

-- Grey button
local function makeButton(page, text, cb)
    local btn = Instance.new("TextButton", page)
    btn.Size             = UDim2.new(1, -12, 0, 34)
    btn.BackgroundColor3 = C.BTN
    btn.BorderSizePixel  = 0
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.TextColor3       = C.TEXT
    btn.Text             = text
    btn.AutoButtonColor  = false
    corner(btn, 6)
    btn.MouseEnter:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN_HV}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN}):Play()
    end)
    btn.MouseButton1Click:Connect(function() task.spawn(cb) end)
    return btn
end

-- Toggle: dark grey OFF / white ON
local function makeToggle(page, text, default, cb)
    local frame = Instance.new("Frame", page)
    frame.Size             = UDim2.new(1, -12, 0, 32)
    frame.BackgroundColor3 = C.CARD
    frame.BorderSizePixel  = 0
    corner(frame, 6)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size               = UDim2.new(1, -52, 1, 0)
    lbl.Position           = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamSemibold
    lbl.TextSize           = 13
    lbl.TextColor3         = C.TEXT
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = text
    local tb = Instance.new("TextButton", frame)
    tb.Size             = UDim2.new(0, 34, 0, 18)
    tb.Position         = UDim2.new(1, -44, 0.5, -9)
    tb.BackgroundColor3 = default and C.SW_ON or C.SW_OFF
    tb.Text             = ""
    tb.BorderSizePixel  = 0
    tb.AutoButtonColor  = false
    corner(tb, 9)
    local knob = Instance.new("Frame", tb)
    knob.Size             = UDim2.new(0, 14, 0, 14)
    knob.Position         = UDim2.new(0, default and 18 or 2, 0.5, -7)
    knob.BackgroundColor3 = default and C.KNOB_ON or C.KNOB_OFF
    knob.BorderSizePixel  = 0
    corner(knob, 7)
    local state = default
    local function setState(v)
        state = v
        TS:Create(tb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            BackgroundColor3 = v and C.SW_ON or C.SW_OFF
        }):Play()
        TS:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position         = UDim2.new(0, v and 18 or 2, 0.5, -7),
            BackgroundColor3 = v and C.KNOB_ON or C.KNOB_OFF
        }):Play()
        cb(v)
    end
    setState(default)
    tb.MouseButton1Click:Connect(function() setState(not state) end)
    return {Set = setState, Get = function() return state end}
end

-- Slider: white bar + white value text
local function makeSlider(page, text, min, max, default, cb)
    local frame = Instance.new("Frame", page)
    frame.Size             = UDim2.new(1, -12, 0, 52)
    frame.BackgroundColor3 = C.CARD
    frame.BorderSizePixel  = 0
    corner(frame, 6)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size               = UDim2.new(0.6, 0, 0, 22)
    lbl.Position           = UDim2.new(0, 8, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3         = C.TEXT
    lbl.TextXAlignment     = Enum.TextXAlignment.Left; lbl.Text = text
    local valLbl = Instance.new("TextLabel", frame)
    valLbl.Size            = UDim2.new(0.4, 0, 0, 22)
    valLbl.Position        = UDim2.new(0.6, -8, 0, 6)
    valLbl.BackgroundTransparency = 1
    valLbl.Font            = Enum.Font.GothamBold; valLbl.TextSize = 13
    valLbl.TextColor3      = C.FILL                                 -- white text
    valLbl.TextXAlignment  = Enum.TextXAlignment.Right
    valLbl.Text            = tostring(default)
    local track = Instance.new("Frame", frame)
    track.Size             = UDim2.new(1, -16, 0, 6)
    track.Position         = UDim2.new(0, 8, 0, 36)
    track.BackgroundColor3 = C.TRACK; track.BorderSizePixel = 0
    corner(track, 3)
    local fill = Instance.new("Frame", track)
    fill.Size             = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = C.FILL                                  -- white bar
    fill.BorderSizePixel  = 0
    corner(fill, 3)
    local knob = Instance.new("TextButton", track)
    knob.Size             = UDim2.new(0, 16, 0, 16)
    knob.AnchorPoint      = Vector2.new(0.5, 0.5)
    knob.Position         = UDim2.new((default-min)/(max-min), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Text             = ""; knob.BorderSizePixel = 0
    knob.AutoButtonColor  = false
    corner(knob, 8)
    local dragging = false
    local function update(absX)
        local ratio = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val   = math.round(min + ratio*(max-min))
        fill.Size     = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, 0, 0.5, 0)
        valLbl.Text   = tostring(val)
        cb(val)
    end
    knob.MouseButton1Down:Connect(function() dragging = true end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=true; update(i.Position.X) end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i.Position.X) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

-- Status bar (grey dot + grey text)
local function makeStatus(page, initText)
    local f = Instance.new("Frame", page)
    f.Size             = UDim2.new(1, -12, 0, 28)
    f.BackgroundColor3 = C.CARD; f.BorderSizePixel = 0
    corner(f, 6)
    local stroke = Instance.new("UIStroke", f)
    stroke.Color = C.BORDER; stroke.Thickness = 1; stroke.Transparency = 0.4
    local dot = Instance.new("Frame", f)
    dot.Size             = UDim2.new(0, 7, 0, 7)
    dot.Position         = UDim2.new(0, 10, 0.5, -3)
    dot.BackgroundColor3 = C.DOT_IDLE; dot.BorderSizePixel = 0
    corner(dot, 4)
    local lb = Instance.new("TextLabel", f)
    lb.Size               = UDim2.new(1, -26, 1, 0)
    lb.Position           = UDim2.new(0, 22, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Font               = Enum.Font.Gotham; lb.TextSize = 12
    lb.TextColor3         = C.TEXT_MID
    lb.TextXAlignment     = Enum.TextXAlignment.Left; lb.Text = initText
    return {
        SetActive = function(on, msg)
            dot.BackgroundColor3 = on and C.DOT_ACT or C.DOT_IDLE
            if msg then lb.Text = msg end
        end
    }
end

-- Progress bar (white bar + white text)
local function makeProgress(page)
    local bg = Instance.new("Frame", page)
    bg.Size             = UDim2.new(1, -12, 0, 40)
    bg.BackgroundColor3 = C.CARD; bg.BorderSizePixel = 0
    corner(bg, 6)
    local stroke = Instance.new("UIStroke", bg)
    stroke.Color = C.BORDER; stroke.Thickness = 1; stroke.Transparency = 0.4
    local lb = Instance.new("TextLabel", bg)
    lb.Size               = UDim2.new(1, -12, 0, 16)
    lb.Position           = UDim2.new(0, 6, 0, 4)
    lb.BackgroundTransparency = 1
    lb.Font               = Enum.Font.GothamSemibold; lb.TextSize = 11
    lb.TextColor3         = C.FILL                                  -- white text
    lb.TextXAlignment     = Enum.TextXAlignment.Left; lb.Text = ""
    local track = Instance.new("Frame", bg)
    track.Size             = UDim2.new(1, -12, 0, 10)
    track.Position         = UDim2.new(0, 6, 0, 24)
    track.BackgroundColor3 = C.TRACK; track.BorderSizePixel = 0
    corner(track, 5)
    local fill = Instance.new("Frame", track)
    fill.Size             = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = C.FILL                                  -- white bar
    fill.BorderSizePixel  = 0
    corner(fill, 5)
    return {
        Set = function(cur, tot, msg)
            local pct = tot > 0 and cur/tot or 0
            TS:Create(fill, TweenInfo.new(0.18), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
            lb.Text = msg or (cur .. " / " .. tot)
        end,
        Reset = function() fill.Size = UDim2.new(0, 0, 1, 0); lb.Text = "" end,
    }
end

-- Dropdown (grey palette)
local function makeFancyDropdown(page, labelText, getOptions, cb)
    local selected = ""
    local isOpen   = false
    local ITEM_H   = 34; local MAX_SHOW = 5; local HEADER_H = 40
    local outer = Instance.new("Frame", page)
    outer.Size             = UDim2.new(1, -12, 0, HEADER_H)
    outer.BackgroundColor3 = C.ROW; outer.BorderSizePixel = 0
    outer.ClipsDescendants = true; corner(outer, 8)
    local outerStroke = Instance.new("UIStroke", outer)
    outerStroke.Color = C.BORDER; outerStroke.Thickness = 1; outerStroke.Transparency = 0.4
    local header = Instance.new("Frame", outer)
    header.Size = UDim2.new(1, 0, 0, HEADER_H); header.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", header)
    lbl.Size = UDim2.new(0, 80, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = labelText
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12; lbl.TextColor3 = C.TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local selFrame = Instance.new("Frame", header)
    selFrame.Size = UDim2.new(1, -96, 0, 28); selFrame.Position = UDim2.new(0, 90, 0.5, -14)
    selFrame.BackgroundColor3 = C.INPUT; selFrame.BorderSizePixel = 0; corner(selFrame, 6)
    local sfStroke = Instance.new("UIStroke", selFrame)
    sfStroke.Color = C.BORDER; sfStroke.Thickness = 1; sfStroke.Transparency = 0.3
    local selLbl = Instance.new("TextLabel", selFrame)
    selLbl.Size = UDim2.new(1, -36, 1, 0); selLbl.Position = UDim2.new(0, 10, 0, 0)
    selLbl.BackgroundTransparency = 1; selLbl.Text = "Select..."
    selLbl.Font = Enum.Font.GothamSemibold; selLbl.TextSize = 12
    selLbl.TextColor3 = C.TEXT_DIM; selLbl.TextXAlignment = Enum.TextXAlignment.Left
    selLbl.TextTruncate = Enum.TextTruncate.AtEnd
    local arrowLbl = Instance.new("TextLabel", selFrame)
    arrowLbl.Size = UDim2.new(0, 22, 1, 0); arrowLbl.Position = UDim2.new(1, -24, 0, 0)
    arrowLbl.BackgroundTransparency = 1; arrowLbl.Text = "▾"
    arrowLbl.Font = Enum.Font.GothamBold; arrowLbl.TextSize = 14
    arrowLbl.TextColor3 = C.TEXT_MID; arrowLbl.TextXAlignment = Enum.TextXAlignment.Center
    local headerBtn = Instance.new("TextButton", selFrame)
    headerBtn.Size = UDim2.new(1, 0, 1, 0); headerBtn.BackgroundTransparency = 1
    headerBtn.Text = ""; headerBtn.AutoButtonColor = false; headerBtn.ZIndex = 5
    local divider = Instance.new("Frame", outer)
    divider.Size = UDim2.new(1, -16, 0, 1); divider.Position = UDim2.new(0, 8, 0, HEADER_H)
    divider.BackgroundColor3 = C.BORDER; divider.BorderSizePixel = 0; divider.Visible = false
    local listScroll = Instance.new("ScrollingFrame", outer)
    listScroll.Position = UDim2.new(0, 0, 0, HEADER_H + 2); listScroll.Size = UDim2.new(1, 0, 0, 0)
    listScroll.BackgroundTransparency = 1; listScroll.BorderSizePixel = 0
    listScroll.ScrollBarThickness = 3; listScroll.ScrollBarImageColor3 = C.BORDER
    listScroll.CanvasSize = UDim2.new(0, 0, 0, 0); listScroll.ClipsDescendants = true
    local listLayout = Instance.new("UIListLayout", listScroll)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder; listLayout.Padding = UDim.new(0, 3)
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 6)
    end)
    local lp2 = Instance.new("UIPadding", listScroll)
    lp2.PaddingTop = UDim.new(0, 4); lp2.PaddingBottom = UDim.new(0, 4)
    lp2.PaddingLeft = UDim.new(0, 6); lp2.PaddingRight = UDim.new(0, 6)
    local function setSelected(name)
        selected = name; selLbl.Text = name; selLbl.TextColor3 = C.TEXT
        arrowLbl.TextColor3 = C.TEXT_MID
        outerStroke.Color = C.BORDER; cb(name)
    end
    local function buildList()
        for _, c in ipairs(listScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        local opts = getOptions()
        for _, opt in ipairs(opts) do
            local item = Instance.new("TextButton", listScroll)
            item.Size = UDim2.new(1, 0, 0, ITEM_H); item.BackgroundColor3 = C.ROW
            item.Text = ""; item.BorderSizePixel = 0; item.AutoButtonColor = false; corner(item, 6)
            local iLbl = Instance.new("TextLabel", item)
            iLbl.Size = UDim2.new(1, -16, 1, 0); iLbl.Position = UDim2.new(0, 10, 0, 0)
            iLbl.BackgroundTransparency = 1; iLbl.Text = opt
            iLbl.Font = Enum.Font.GothamSemibold; iLbl.TextSize = 12
            iLbl.TextColor3 = C.TEXT; iLbl.TextXAlignment = Enum.TextXAlignment.Left
            iLbl.TextTruncate = Enum.TextTruncate.AtEnd
            item.MouseEnter:Connect(function()
                TS:Create(item, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(45,45,45)}):Play()
            end)
            item.MouseLeave:Connect(function()
                TS:Create(item, TweenInfo.new(0.1), {BackgroundColor3 = C.ROW}):Play()
            end)
            item.MouseButton1Click:Connect(function()
                setSelected(opt); isOpen = false
                TS:Create(arrowLbl, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
                TS:Create(outer, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,-12,0,HEADER_H)}):Play()
                TS:Create(listScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,0)}):Play()
                divider.Visible = false
            end)
        end
        return #opts
    end
    local function openList()
        isOpen = true; local count = buildList()
        local listH = math.min(count, MAX_SHOW) * (ITEM_H + 3) + 8; divider.Visible = true
        TS:Create(arrowLbl, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation = 180}):Play()
        TS:Create(outer, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(1,-12,0,HEADER_H+2+listH)}):Play()
        TS:Create(listScroll, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,listH)}):Play()
    end
    local function closeList()
        isOpen = false
        TS:Create(arrowLbl, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
        TS:Create(outer, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,-12,0,HEADER_H)}):Play()
        TS:Create(listScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,0)}):Play()
        divider.Visible = false
    end
    headerBtn.MouseButton1Click:Connect(function() if isOpen then closeList() else openList() end end)
    headerBtn.MouseEnter:Connect(function()
        TS:Create(selFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(42,42,42)}):Play()
    end)
    headerBtn.MouseLeave:Connect(function()
        TS:Create(selFrame, TweenInfo.new(0.12), {BackgroundColor3 = C.INPUT}):Play()
    end)
    return {
        GetSelected = function() return selected end,
        Refresh = function()
            if isOpen then
                local count = buildList()
                local listH = math.min(count, MAX_SHOW) * (ITEM_H + 3) + 8
                outer.Size      = UDim2.new(1, -12, 0, HEADER_H + 2 + listH)
                listScroll.Size = UDim2.new(1, 0, 0, listH)
            end
        end
    }
end

-- ════════════════════════════════════════════════════
-- AUTOBUY TAB — COMING SOON / UNDER DEVELOPMENT SCREEN
-- ════════════════════════════════════════════════════

local ab = pages["AutoBuyTab"]

-- ── Card container (black inner panel) ─────────────────────────────────────
local csOuter = Instance.new("Frame", ab)
csOuter.Size             = UDim2.new(1, -12, 0, 200)
csOuter.BackgroundColor3 = C.BG
csOuter.BorderSizePixel  = 0
corner(csOuter, 12)

local csBorderStroke = Instance.new("UIStroke", csOuter)
csBorderStroke.Color        = C.BORDER_DIM
csBorderStroke.Thickness    = 1.5
csBorderStroke.Transparency = 0

-- Subtle grid lines
for row = 0, 3 do
    local g = Instance.new("Frame", csOuter)
    g.Size             = UDim2.new(1, 0, 0, 1)
    g.Position         = UDim2.new(0, 0, 0, 22 + row * 46)
    g.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    g.BorderSizePixel  = 0; g.ZIndex = 1
end
for col = 0, 5 do
    local g = Instance.new("Frame", csOuter)
    g.Size             = UDim2.new(0, 1, 1, 0)
    g.Position         = UDim2.new(0, 28 + col * 44, 0, 0)
    g.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    g.BorderSizePixel  = 0; g.ZIndex = 1
end

-- Glow blob (grey)
local glowBlob = Instance.new("Frame", csOuter)
glowBlob.Size                   = UDim2.new(0, 80, 0, 80)
glowBlob.AnchorPoint            = Vector2.new(0.5, 0)
glowBlob.Position               = UDim2.new(0.5, 0, 0, 16)
glowBlob.BackgroundColor3       = C.GLOW
glowBlob.BorderSizePixel        = 0
glowBlob.BackgroundTransparency = 0.68
glowBlob.ZIndex                 = 2
corner(glowBlob, 40)

-- Floating circle
local lockCircle = Instance.new("Frame", csOuter)
lockCircle.Size             = UDim2.new(0, 46, 0, 46)
lockCircle.AnchorPoint      = Vector2.new(0.5, 0)
lockCircle.Position         = UDim2.new(0.5, 0, 0, 22)
lockCircle.BackgroundColor3 = C.CARD
lockCircle.BorderSizePixel  = 0; lockCircle.ZIndex = 3
corner(lockCircle, 23)
local lockStroke = Instance.new("UIStroke", lockCircle)
lockStroke.Color = C.BORDER; lockStroke.Thickness = 1.5

local lockIcon = Instance.new("TextLabel", lockCircle)
lockIcon.Size               = UDim2.new(1, 0, 1, 0)
lockIcon.BackgroundTransparency = 1
lockIcon.Text               = "🛒"
lockIcon.Font               = Enum.Font.GothamBold; lockIcon.TextSize = 20
lockIcon.TextXAlignment     = Enum.TextXAlignment.Center
lockIcon.TextYAlignment     = Enum.TextYAlignment.Center
lockIcon.ZIndex             = 4

-- Title (near-white)
local csTitleLbl = Instance.new("TextLabel", csOuter)
csTitleLbl.Size               = UDim2.new(1, -16, 0, 24)
csTitleLbl.Position           = UDim2.new(0, 8, 0, 78)
csTitleLbl.BackgroundTransparency = 1
csTitleLbl.Font               = Enum.Font.GothamBold; csTitleLbl.TextSize = 17
csTitleLbl.TextColor3         = Color3.fromRGB(200, 200, 200)
csTitleLbl.TextXAlignment     = Enum.TextXAlignment.Center
csTitleLbl.Text               = "COMING SOON"; csTitleLbl.ZIndex = 5

-- Accent line (grey)
local accentLine = Instance.new("Frame", csOuter)
accentLine.Size             = UDim2.new(0, 56, 0, 2)
accentLine.AnchorPoint      = Vector2.new(0.5, 0)
accentLine.Position         = UDim2.new(0.5, 0, 0, 105)
accentLine.BackgroundColor3 = C.BORDER; accentLine.BorderSizePixel = 0
accentLine.ZIndex           = 5; corner(accentLine, 1)

-- Sub-label
local csSubLbl = Instance.new("TextLabel", csOuter)
csSubLbl.Size               = UDim2.new(1, -20, 0, 14)
csSubLbl.Position           = UDim2.new(0, 10, 0, 112)
csSubLbl.BackgroundTransparency = 1
csSubLbl.Font               = Enum.Font.GothamSemibold; csSubLbl.TextSize = 10
csSubLbl.TextColor3         = C.TEXT_DIM
csSubLbl.TextXAlignment     = Enum.TextXAlignment.Center
csSubLbl.Text               = "AUTO BUY  —  UNDER DEVELOPMENT"; csSubLbl.ZIndex = 5

-- Description
local csDescLbl = Instance.new("TextLabel", csOuter)
csDescLbl.Size               = UDim2.new(1, -24, 0, 36)
csDescLbl.Position           = UDim2.new(0, 12, 0, 130)
csDescLbl.BackgroundTransparency = 1
csDescLbl.Font               = Enum.Font.Gotham; csDescLbl.TextSize = 10
csDescLbl.TextColor3         = C.TEXT_DIM
csDescLbl.TextXAlignment     = Enum.TextXAlignment.Center
csDescLbl.TextWrapped        = true
csDescLbl.Text               = "Being rebuilt with improved bypass logic, smarter counter detection & network ownership handling."
csDescLbl.ZIndex             = 5

-- Status pill (dark card + grey border)
local statusPill = Instance.new("Frame", csOuter)
statusPill.Size             = UDim2.new(0, 148, 0, 20)
statusPill.AnchorPoint      = Vector2.new(0.5, 0)
statusPill.Position         = UDim2.new(0.5, 0, 0, 172)
statusPill.BackgroundColor3 = C.CARD; statusPill.BorderSizePixel = 0
statusPill.ZIndex           = 5; corner(statusPill, 10)
local pillStroke = Instance.new("UIStroke", statusPill)
pillStroke.Color = C.BORDER; pillStroke.Thickness = 1; pillStroke.Transparency = 0.4

-- Pulse dot (white)
local pulseDot = Instance.new("Frame", statusPill)
pulseDot.Size             = UDim2.new(0, 6, 0, 6)
pulseDot.Position         = UDim2.new(0, 10, 0.5, -3)
pulseDot.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
pulseDot.BorderSizePixel  = 0; pulseDot.ZIndex = 6; corner(pulseDot, 3)

local pillLbl = Instance.new("TextLabel", statusPill)
pillLbl.Size               = UDim2.new(1, -24, 1, 0)
pillLbl.Position           = UDim2.new(0, 22, 0, 0)
pillLbl.BackgroundTransparency = 1
pillLbl.Font               = Enum.Font.GothamSemibold; pillLbl.TextSize = 10
pillLbl.TextColor3         = C.TEXT_MID
pillLbl.TextXAlignment     = Enum.TextXAlignment.Left
pillLbl.Text               = "In Development  •  v0.0"; pillLbl.ZIndex = 6

-- ── Animations ───────────────────────────────────────────────────────────────
task.spawn(function()
    while true do
        TS:Create(pulseDot, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {BackgroundTransparency = 0.75}):Play()
        task.wait(0.9)
        TS:Create(pulseDot, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {BackgroundTransparency = 0}):Play()
        task.wait(0.9)
    end
end)

-- Border cycles through grey shades only
task.spawn(function()
    local cols = {
        Color3.fromRGB(60,  60,  60),
        Color3.fromRGB(85,  85,  85),
        Color3.fromRGB(45,  45,  45),
        Color3.fromRGB(75,  75,  75),
    }
    local i = 1
    while true do
        local nx = i % #cols + 1
        TS:Create(csBorderStroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Color = cols[nx]}):Play()
        i = nx; task.wait(2)
    end
end)

task.spawn(function()
    while true do
        TS:Create(lockCircle, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Position = UDim2.new(0.5,0,0,18)}):Play()
        task.wait(1.4)
        TS:Create(lockCircle, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Position = UDim2.new(0.5,0,0,26)}):Play()
        task.wait(1.4)
    end
end)

task.spawn(function()
    while true do
        TS:Create(glowBlob, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Position = UDim2.new(0.5,0,0,12)}):Play()
        task.wait(1.4)
        TS:Create(glowBlob, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Position = UDim2.new(0.5,0,0,20)}):Play()
        task.wait(1.4)
    end
end)

-- ════════════════════════════════════════════════════
-- SLOT TAB
-- ════════════════════════════════════════════════════

local sl = pages["SlotTab"]

local slotNum    = 1
local landToTake = nil
local landHL     = nil

local function freeLand()
    for _, v in ipairs(workspace.Properties:GetChildren()) do
        if v:FindFirstChild("Owner") and v.Owner.Value == nil then
            pcall(function()
                RS.PropertyPurchasing.ClientPurchasedProperty:FireServer(v, v.OriginSquare.Position)
                LP.Character.HumanoidRootPart.CFrame = v.OriginSquare.CFrame + Vector3.new(0,2,0)
            end)
            break
        end
    end
end

local function maxLand()
    for _, d in ipairs(workspace.Properties:GetChildren()) do
        if d:FindFirstChild("Owner") and d:FindFirstChild("OriginSquare") and d.Owner.Value == LP then
            local p = d.OriginSquare.Position
            local offsets = {
                Vector3.new(40,0,0),  Vector3.new(-40,0,0),
                Vector3.new(0,0,40),  Vector3.new(0,0,-40),
                Vector3.new(40,0,40), Vector3.new(40,0,-40),
                Vector3.new(-40,0,40),Vector3.new(-40,0,-40),
                Vector3.new(80,0,0),  Vector3.new(-80,0,0),
                Vector3.new(0,0,80),  Vector3.new(0,0,-80),
                Vector3.new(80,0,80), Vector3.new(80,0,-80),
                Vector3.new(-80,0,80),Vector3.new(-80,0,-80),
                Vector3.new(40,0,80), Vector3.new(-40,0,80),
                Vector3.new(80,0,40), Vector3.new(80,0,-40),
                Vector3.new(-80,0,40),Vector3.new(-80,0,-40),
                Vector3.new(40,0,-80),Vector3.new(-40,0,-80),
            }
            for _, off in ipairs(offsets) do
                pcall(function()
                    RS.PropertyPurchasing.ClientExpandedProperty:FireServer(d, CFrame.new(p+off))
                end)
            end
        end
    end
end

local function loadSlot(slot)
    pcall(function()
        if not RS.LoadSaveRequests.ClientMayLoad:InvokeServer(LP) then
            repeat task.wait() until RS.LoadSaveRequests.ClientMayLoad:InvokeServer(LP)
        end
        RS.LoadSaveRequests.RequestLoad:InvokeServer(slot, LP)
    end)
end

local function showSavePopup()
    local CoreGui = game:GetService("CoreGui")
    local existing = CoreGui:FindFirstChild("VH_SavePopup")
    if existing then existing:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "VH_SavePopup"; sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(sg) end end)
    sg.Parent = CoreGui

    local frame = Instance.new("Frame", sg)
    frame.Size       = UDim2.new(0, 240, 0, 48)
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.Position   = UDim2.new(0.5, 0, 0, -60)
    frame.BackgroundColor3 = C.CARD; frame.BorderSizePixel = 0
    corner(frame, 10)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = C.BORDER; stroke.Thickness = 1.5

    local icon = Instance.new("TextLabel", frame)
    icon.Size = UDim2.new(0, 36, 1, 0); icon.Position = UDim2.new(0, 8, 0, 0)
    icon.BackgroundTransparency = 1; icon.Font = Enum.Font.GothamBold
    icon.TextSize = 20; icon.TextColor3 = C.TEXT; icon.Text = "💾"

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -52, 1, 0); lbl.Position = UDim2.new(0, 48, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14; lbl.TextColor3 = C.TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = "Saved Successfully!"

    TS:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0, 18)
    }):Play()
    task.delay(2.5, function()
        TS:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, 0, -60)
        }):Play()
        task.wait(0.35)
        pcall(function() sg:Destroy() end)
    end)
end

local function forceSave()
    local slot = LP:FindFirstChild("CurrentSaveSlot") and LP.CurrentSaveSlot.Value
    if not slot or slot == -1 then print("[VH] No slot currently loaded!"); return end
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then print("[VH] No character found!"); return end
    local originCF = hrp.CFrame
    local plotCF   = nil
    for _, v in ipairs(workspace.Properties:GetChildren()) do
        if v:FindFirstChild("Owner") and v.Owner.Value == LP and v:FindFirstChild("OriginSquare") then
            plotCF = v.OriginSquare.CFrame; break
        end
    end
    if not plotCF then
        pcall(function() RS.LoadSaveRequests.RequestSave:InvokeServer(slot, LP) end)
        showSavePopup(); return
    end
    local vehicleOriginalCFrames = {}
    for _, v in ipairs(workspace.PlayerModels:GetChildren()) do
        if v:FindFirstChild("Owner") and v.Owner.Value == LP then
            local typeVal = v:FindFirstChild("Type")
            if typeVal and typeVal.Value == "Vehicle" then
                local root = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
                if root then
                    vehicleOriginalCFrames[v] = root.CFrame
                    hrp.CFrame = root.CFrame * CFrame.new(5, 1, 0); task.wait(0.1)
                    local t = tick()
                    repeat
                        pcall(function()
                            RS.Interaction.ClientIsDragging:FireServer(v)
                            RS.Interaction.ClientIsDragging:FireServer(v)
                            RS.Interaction.ClientIsDragging:FireServer(v)
                        end)
                        task.wait(0.03)
                    until (tick() - t > 2) or (root.ReceiveAge == 0)
                    local idx = 0
                    for _ in pairs(vehicleOriginalCFrames) do idx = idx + 1 end
                    local offset = Vector3.new((idx - 1) * 8, 2, 0)
                    pcall(function()
                        RS.Interaction.ClientIsDragging:FireServer(v)
                        if v.PrimaryPart then v:SetPrimaryPartCFrame(plotCF + offset)
                        else root.CFrame = plotCF + offset end
                    end)
                    for _ = 1, 10 do
                        pcall(function()
                            RS.Interaction.ClientIsDragging:FireServer(v)
                            if v.PrimaryPart then v:SetPrimaryPartCFrame(plotCF + offset)
                            else root.CFrame = plotCF + offset end
                        end)
                        task.wait(0.05)
                    end
                end
            end
        end
    end
    hrp.CFrame = plotCF + Vector3.new(0, 3, 0); task.wait(0.2)
    pcall(function() RS.LoadSaveRequests.RequestSave:InvokeServer(slot, LP) end)
    task.wait(0.5)
    pcall(function() RS.LoadSaveRequests.RequestSave:InvokeServer(slot, LP) end)
    task.wait(0.3)
    for v, originalCF in pairs(vehicleOriginalCFrames) do
        local root = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
        if root and v.Parent then
            pcall(function()
                RS.Interaction.ClientIsDragging:FireServer(v)
                if v.PrimaryPart then v:SetPrimaryPartCFrame(originalCF)
                else root.CFrame = originalCF end
            end)
            task.wait(0.05)
        end
    end
    hrp.CFrame = originCF
    print("[VH] Force saved slot " .. tostring(slot))
    showSavePopup()
end

local function sellSoldSign()
    for _, v in ipairs(workspace.PlayerModels:GetChildren()) do
        if v:FindFirstChild("Owner") and v.Owner.Value == LP
           and v:FindFirstChild("ItemName") and v.ItemName.Value == "PropertySoldSign" then
            pcall(function()
                LP.Character.HumanoidRootPart.CFrame = CFrame.new(v.Main.CFrame.p) + Vector3.new(0,0,2)
                RS.Interaction.ClientInteracted:FireServer(v, "Take down sold sign")
                for _ = 1, 30 do
                    RS.Interaction.ClientIsDragging:FireServer(v)
                    v.Main.CFrame = CFrame.new(314.54, -0.5, 86.823)
                    task.wait()
                end
            end)
        end
    end
end

sectionLabel(sl, "Fast Load")
makeSlider(sl, "Slot Number", 1, 6, 1, function(v) slotNum = v end)
makeButton(sl, "Load Base",  function() loadSlot(slotNum) end)
makeButton(sl, "Force Save", function() forceSave() end)

sep(sl)
sectionLabel(sl, "Land Management")
makeButton(sl, "Free Land",  freeLand)
makeButton(sl, "Max Land",   maxLand)
makeButton(sl, "Sell Sign",  sellSoldSign)

sep(sl)
sectionLabel(sl, "Land Claim")

local landPlotOptions = {"1","2","3","4","5","6","7","8","9"}
makeFancyDropdown(sl, "Plot", function() return landPlotOptions end, function(val)
    if landHL then pcall(function() landHL:Destroy() end) end
    landToTake = tonumber(val)
    local props = workspace.Properties:GetChildren()
    if props[landToTake] and props[landToTake]:FindFirstChild("OriginSquare") then
        landHL = Instance.new("Highlight")
        landHL.FillColor        = Color3.fromRGB(180, 180, 180)  -- grey highlight
        landHL.FillTransparency = 0.5
        landHL.Parent           = props[landToTake].OriginSquare
    end
end)

makeButton(sl, "Take Selected Land", function()
    if not landToTake then return end
    local props = workspace.Properties:GetChildren()
    if props[landToTake] then
        local land = props[landToTake]
        pcall(function()
            RS.PropertyPurchasing.ClientPurchasedProperty:FireServer(land, land.OriginSquare.Position)
            LP.Character.HumanoidRootPart.CFrame = land.OriginSquare.CFrame + Vector3.new(0,2,0)
        end)
        if landHL then pcall(function() landHL:Destroy() end); landHL = nil end
    end
end)

-- ════════════════════════════════════════════════════
-- CLEANUP
-- ════════════════════════════════════════════════════
table.insert(VH.cleanupTasks, function()
    if landHL then pcall(function() landHL:Destroy() end) end
end)

print("[VanillaHub] Vanilla6 loaded — black/grey/white theme")
