-- ════════════════════════════════════════════════════
-- VANILLA3 — FULL REWRITE (Aggressive Bypass Edition)
-- Complete rewrite of tree cutting + log dragging
-- ════════════════════════════════════════════════════

if not _G.VH then
    warn("[VanillaHub] Vanilla3: _G.VH not found. Execute Vanilla1 first.")
    return
end

local TweenService     = _G.VH.TweenService
local Players          = _G.VH.Players
local UserInputService = _G.VH.UserInputService
local RunService       = _G.VH.RunService
local player           = _G.VH.player
local cleanupTasks     = _G.VH.cleanupTasks
local pages            = _G.VH.pages
local tabs             = _G.VH.tabs
local BTN_COLOR        = _G.VH.BTN_COLOR        -- grey (set in Vanilla1)
local BTN_HOVER        = _G.VH.BTN_HOVER
local THEME_TEXT       = _G.VH.THEME_TEXT or Color3.fromRGB(220, 220, 220)
local switchTab        = _G.VH.switchTab
local toggleGUI        = _G.VH.toggleGUI
local stopFly          = _G.VH.stopFly
local startFly         = _G.VH.startFly
local flyKeyBtn        = _G.VH.flyKeyBtn

-- ── Key state getters/setters ───────────────────────
local function getWaitingForFlyKey()   return _G.VH and _G.VH.waitingForFlyKey end
local function setWaitingForFlyKey(v)  if _G.VH then _G.VH.waitingForFlyKey = v end end
local function getWaitingForKeyGUI()   return _G.VH and _G.VH.waitingForKeyGUI end
local function setWaitingForKeyGUI(v)  if _G.VH then _G.VH.waitingForKeyGUI = v end end
local function getCurrentFlyKey()      return _G.VH and _G.VH.currentFlyKey or Enum.KeyCode.Q end
local function setCurrentFlyKey(v)     if _G.VH then _G.VH.currentFlyKey = v end end
local function getCurrentToggleKey()   return _G.VH and _G.VH.currentToggleKey or Enum.KeyCode.LeftAlt end
local function setCurrentToggleKey(v)  if _G.VH then _G.VH.currentToggleKey = v end end
local function getFlyToggleEnabled()   return _G.VH and _G.VH.flyToggleEnabled end
local function getIsFlyEnabled()       return _G.VH and _G.VH.isFlyEnabled end

-- ════════════════════════════════════════════════════
-- THEME  (Black / Grey / White only)
-- ════════════════════════════════════════════════════

local C = {
    -- backgrounds (black inner panels)
    BG         = Color3.fromRGB(10,  10,  10 ),
    CARD       = Color3.fromRGB(10,  10,  10),   -- black panel
    ROW        = Color3.fromRGB(30,  30,  30 ),

    -- borders / separators (grey)
    BORDER     = Color3.fromRGB(55,  55,  55 ),
    BORDER_DIM = Color3.fromRGB(40,  40,  40 ),

    -- text
    TEXT       = Color3.fromRGB(210, 210, 210),
    TEXT_MID   = Color3.fromRGB(150, 150, 150),
    TEXT_DIM   = Color3.fromRGB(90,  90,  90 ),

    -- accents (grey / white only)
    ACCENT     = Color3.fromRGB(200, 200, 200),
    ACCENT_DIM = Color3.fromRGB(120, 120, 120),
    GLOW       = Color3.fromRGB(80,  80,  80 ),

    -- buttons (grey)
    BTN        = Color3.fromRGB(14,  14,  14),   -- black button bg
    BTN_HV     = Color3.fromRGB(32,  32,  32),   -- dark grey hover
}

-- ════════════════════════════════════════════════════
-- SHARED UI HELPER
-- ════════════════════════════════════════════════════

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
end

-- ════════════════════════════════════════════════════
-- WOOD TAB — COMING SOON CARD
-- ════════════════════════════════════════════════════

local woodPage = pages["WoodTab"]

-- Outer card  (black inner panel)
local csOuter = Instance.new("Frame", woodPage)
csOuter.Size             = UDim2.new(1, -12, 0, 200)
csOuter.BackgroundColor3 = C.BG
csOuter.BorderSizePixel  = 0
corner(csOuter, 12)

local csBorderStroke = Instance.new("UIStroke", csOuter)
csBorderStroke.Color        = C.BORDER_DIM
csBorderStroke.Thickness    = 1.5
csBorderStroke.Transparency = 0

-- Grid lines horizontal
for row = 0, 3 do
    local g = Instance.new("Frame", csOuter)
    g.Size             = UDim2.new(1, 0, 0, 1)
    g.Position         = UDim2.new(0, 0, 0, 22 + row * 46)
    g.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    g.BorderSizePixel  = 0
    g.ZIndex           = 1
end

-- Grid lines vertical
for col = 0, 5 do
    local g = Instance.new("Frame", csOuter)
    g.Size             = UDim2.new(0, 1, 1, 0)
    g.Position         = UDim2.new(0, 28 + col * 44, 0, 0)
    g.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    g.BorderSizePixel  = 0
    g.ZIndex           = 1
end

-- Glow blob (grey instead of purple)
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
lockCircle.BorderSizePixel  = 0
lockCircle.ZIndex           = 3
corner(lockCircle, 23)

local lockStroke = Instance.new("UIStroke", lockCircle)
lockStroke.Color     = C.ACCENT_DIM
lockStroke.Thickness = 1.5

local lockIcon = Instance.new("TextLabel", lockCircle)
lockIcon.Size                   = UDim2.new(1, -6, 1, -6)
lockIcon.Position               = UDim2.new(0, 3, 0, 3)
lockIcon.BackgroundTransparency = 1
lockIcon.Text                   = "🪵"
lockIcon.Font                   = Enum.Font.Legacy
lockIcon.TextScaled             = true
lockIcon.TextXAlignment         = Enum.TextXAlignment.Center
lockIcon.TextYAlignment         = Enum.TextYAlignment.Center
lockIcon.ZIndex                 = 4

-- Title
local csTitleLbl = Instance.new("TextLabel", csOuter)
csTitleLbl.Size                   = UDim2.new(1, -16, 0, 24)
csTitleLbl.Position               = UDim2.new(0, 8, 0, 78)
csTitleLbl.BackgroundTransparency = 1
csTitleLbl.Font                   = Enum.Font.GothamBold
csTitleLbl.TextSize               = 17
csTitleLbl.TextColor3             = C.ACCENT      -- near-white
csTitleLbl.TextXAlignment         = Enum.TextXAlignment.Center
csTitleLbl.Text                   = "COMING SOON"
csTitleLbl.ZIndex                 = 5

-- Accent line (grey)
local accentLine = Instance.new("Frame", csOuter)
accentLine.Size             = UDim2.new(0, 56, 0, 2)
accentLine.AnchorPoint      = Vector2.new(0.5, 0)
accentLine.Position         = UDim2.new(0.5, 0, 0, 105)
accentLine.BackgroundColor3 = C.ACCENT_DIM
accentLine.BorderSizePixel  = 0
accentLine.ZIndex           = 5
corner(accentLine, 1)

-- Subtitle
local csSubLbl = Instance.new("TextLabel", csOuter)
csSubLbl.Size                   = UDim2.new(1, -20, 0, 14)
csSubLbl.Position               = UDim2.new(0, 10, 0, 112)
csSubLbl.BackgroundTransparency = 1
csSubLbl.Font                   = Enum.Font.GothamSemibold
csSubLbl.TextSize               = 10
csSubLbl.TextColor3             = C.TEXT_DIM
csSubLbl.TextXAlignment         = Enum.TextXAlignment.Center
csSubLbl.Text                   = "WOOD TAB  —  UNDER DEVELOPMENT"
csSubLbl.ZIndex                 = 5

-- Description
local csDescLbl = Instance.new("TextLabel", csOuter)
csDescLbl.Size                   = UDim2.new(1, -24, 0, 36)
csDescLbl.Position               = UDim2.new(0, 12, 0, 130)
csDescLbl.BackgroundTransparency = 1
csDescLbl.Font                   = Enum.Font.Gotham
csDescLbl.TextSize               = 10
csDescLbl.TextColor3             = C.TEXT_DIM
csDescLbl.TextXAlignment         = Enum.TextXAlignment.Center
csDescLbl.TextWrapped            = true
csDescLbl.Text                   = "Being rebuilt with improved tree cutting,\nsmarter log dragging & reliable sell logic."
csDescLbl.ZIndex                 = 5

-- Status pill (dark grey outer / grey border)
local statusPill = Instance.new("Frame", csOuter)
statusPill.Size             = UDim2.new(0, 148, 0, 20)
statusPill.AnchorPoint      = Vector2.new(0.5, 0)
statusPill.Position         = UDim2.new(0.5, 0, 0, 172)
statusPill.BackgroundColor3 = C.CARD
statusPill.BorderSizePixel  = 0
statusPill.ZIndex           = 5
corner(statusPill, 10)

local pillStroke = Instance.new("UIStroke", statusPill)
pillStroke.Color        = C.BORDER_DIM
pillStroke.Thickness    = 1
pillStroke.Transparency = 0.4

-- Pulse dot (white)
local pulseDot = Instance.new("Frame", statusPill)
pulseDot.Size             = UDim2.new(0, 6, 0, 6)
pulseDot.Position         = UDim2.new(0, 10, 0.5, -3)
pulseDot.BackgroundColor3 = C.ACCENT
pulseDot.BorderSizePixel  = 0
pulseDot.ZIndex           = 6
corner(pulseDot, 3)

local pillLbl = Instance.new("TextLabel", statusPill)
pillLbl.Size                   = UDim2.new(1, -24, 1, 0)
pillLbl.Position               = UDim2.new(0, 22, 0, 0)
pillLbl.BackgroundTransparency = 1
pillLbl.Font                   = Enum.Font.GothamSemibold
pillLbl.TextSize               = 10
pillLbl.TextColor3             = C.TEXT_MID
pillLbl.TextXAlignment         = Enum.TextXAlignment.Left
pillLbl.Text                   = "In Development  •  v0.0"
pillLbl.ZIndex                 = 6

-- ── Animations ───────────────────────────────────────────────────────────────

-- Pulse dot: white fades in/out
task.spawn(function()
    while true do
        TweenService:Create(pulseDot, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            BackgroundTransparency = 0.75
        }):Play()
        task.wait(0.9)
        TweenService:Create(pulseDot, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            BackgroundTransparency = 0
        }):Play()
        task.wait(0.9)
    end
end)

-- Border stroke: cycles through grey shades only
task.spawn(function()
    local cols = {
        Color3.fromRGB(60,  60,  60 ),
        Color3.fromRGB(85,  85,  85 ),
        Color3.fromRGB(45,  45,  45 ),
        Color3.fromRGB(75,  75,  75 ),
    }
    local i = 1
    while true do
        local nx = i % #cols + 1
        TweenService:Create(csBorderStroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Color = cols[nx]
        }):Play()
        i = nx
        task.wait(2)
    end
end)

-- Floating bob animation (lock circle)
task.spawn(function()
    while true do
        TweenService:Create(lockCircle, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Position = UDim2.new(0.5, 0, 0, 18)
        }):Play()
        task.wait(1.4)
        TweenService:Create(lockCircle, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Position = UDim2.new(0.5, 0, 0, 26)
        }):Play()
        task.wait(1.4)
    end
end)

-- Glow blob bob
task.spawn(function()
    while true do
        TweenService:Create(glowBlob, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Position = UDim2.new(0.5, 0, 0, 12)
        }):Play()
        task.wait(1.4)
        TweenService:Create(glowBlob, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Position = UDim2.new(0.5, 0, 0, 20)
        }):Play()
        task.wait(1.4)
    end
end)

-- ════════════════════════════════════════════════════
-- SETTINGS TAB
-- ════════════════════════════════════════════════════

local keybindButtonGUI
local settingsPage = pages["SettingsTab"]

-- Settings card (black inner panel)
local kbFrame = Instance.new("Frame", settingsPage)
kbFrame.Size             = UDim2.new(1, 0, 0, 70)
kbFrame.BackgroundColor3 = C.CARD
kbFrame.BorderSizePixel  = 0
corner(kbFrame, 10)
local kbStroke = Instance.new("UIStroke", kbFrame)
kbStroke.Color = C.BORDER; kbStroke.Thickness = 1; kbStroke.Transparency = 0.4

local kbTitle = Instance.new("TextLabel", kbFrame)
kbTitle.Size               = UDim2.new(1, -20, 0, 28)
kbTitle.Position           = UDim2.new(0, 10, 0, 8)
kbTitle.BackgroundTransparency = 1
kbTitle.Font               = Enum.Font.GothamBold
kbTitle.TextSize           = 15
kbTitle.TextColor3         = C.TEXT
kbTitle.TextXAlignment     = Enum.TextXAlignment.Left
kbTitle.Text               = "GUI Toggle Keybind"

-- Keybind button (grey)
keybindButtonGUI = Instance.new("TextButton", kbFrame)
keybindButtonGUI.Size             = UDim2.new(0, 200, 0, 28)
keybindButtonGUI.Position         = UDim2.new(0, 10, 0, 36)
keybindButtonGUI.BackgroundColor3 = C.BTN
keybindButtonGUI.BorderSizePixel  = 0
keybindButtonGUI.Font             = Enum.Font.Gotham
keybindButtonGUI.TextSize         = 14
keybindButtonGUI.TextColor3       = C.TEXT
keybindButtonGUI.AutoButtonColor  = false
keybindButtonGUI.Text             = "Toggle Key: " .. getCurrentToggleKey().Name
corner(keybindButtonGUI, 8)

keybindButtonGUI.MouseButton1Click:Connect(function()
    if getWaitingForKeyGUI() then return end
    keybindButtonGUI.Text = "Press any key..."
    setWaitingForKeyGUI(true)
end)
keybindButtonGUI.MouseEnter:Connect(function()
    TweenService:Create(keybindButtonGUI, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN_HV}):Play()
end)
keybindButtonGUI.MouseLeave:Connect(function()
    TweenService:Create(keybindButtonGUI, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN}):Play()
end)

-- ════════════════════════════════════════════════════
-- ════════════════════════════════════════════════════
-- SEARCH TAB
-- ════════════════════════════════════════════════════

local searchPage = pages["SearchTab"]

-- ── Search input bar
local searchInputFrame = Instance.new("Frame", searchPage)
searchInputFrame.Size             = UDim2.new(1, 0, 0, 38)
searchInputFrame.BackgroundColor3 = C.CARD
searchInputFrame.BorderSizePixel  = 0
corner(searchInputFrame, 8)
local searchInputStroke = Instance.new("UIStroke", searchInputFrame)
searchInputStroke.Color        = C.BORDER
searchInputStroke.Thickness    = 1
searchInputStroke.Transparency = 0.3

local searchInput = Instance.new("TextBox", searchInputFrame)
searchInput.Size               = UDim2.new(1, -14, 1, 0)
searchInput.Position           = UDim2.new(0, 10, 0, 0)
searchInput.BackgroundTransparency = 1
searchInput.PlaceholderText    = "Search features and tabs..."
searchInput.Text               = ""
searchInput.Font               = Enum.Font.GothamSemibold
searchInput.TextSize           = 13
searchInput.TextColor3         = C.TEXT
searchInput.PlaceholderColor3  = C.TEXT_DIM
searchInput.TextXAlignment     = Enum.TextXAlignment.Left
searchInput.ClearTextOnFocus   = false

-- ── Results container (scrolls inside the page)
local resultsHolder = Instance.new("Frame", searchPage)
resultsHolder.Size             = UDim2.new(1, 0, 0, 0)
resultsHolder.BackgroundTransparency = 1
resultsHolder.AutomaticSize   = Enum.AutomaticSize.Y

local resultsLayout = Instance.new("UIListLayout", resultsHolder)
resultsLayout.SortOrder = Enum.SortOrder.LayoutOrder
resultsLayout.Padding   = UDim.new(0, 4)

-- ── Section header helper
local function mkResultHeader(text)
    local f = Instance.new("Frame", resultsHolder)
    f.Size             = UDim2.new(1, 0, 0, 18)
    f.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", f)
    lbl.Size               = UDim2.new(1, -6, 1, 0)
    lbl.Position           = UDim2.new(0, 6, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 10
    lbl.TextColor3         = C.TEXT_DIM
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = string.upper(text)
    return f
end

-- ── Tab result row
local function mkTabRow(name, tabKey)
    local row = Instance.new("TextButton", resultsHolder)
    row.Size             = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
    row.BorderSizePixel  = 0
    row.Text             = ""
    row.AutoButtonColor  = false
    corner(row, 7)
    local stroke = Instance.new("UIStroke", row)
    stroke.Color = C.BORDER; stroke.Thickness = 1; stroke.Transparency = 0.5

    local nameLbl = Instance.new("TextLabel", row)
    nameLbl.Size               = UDim2.new(1, -80, 1, 0)
    nameLbl.Position           = UDim2.new(0, 12, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font               = Enum.Font.GothamSemibold
    nameLbl.TextSize           = 13
    nameLbl.TextColor3         = C.TEXT
    nameLbl.TextXAlignment     = Enum.TextXAlignment.Left
    nameLbl.TextTruncate       = Enum.TextTruncate.AtEnd
    nameLbl.Text               = name .. " Tab"

    local tagLbl = Instance.new("TextLabel", row)
    tagLbl.Size               = UDim2.new(0, 68, 0, 20)
    tagLbl.Position           = UDim2.new(1, -74, 0.5, -10)
    tagLbl.BackgroundColor3   = Color3.fromRGB(30, 30, 30)
    tagLbl.BorderSizePixel    = 0
    tagLbl.Font               = Enum.Font.Gotham
    tagLbl.TextSize           = 10
    tagLbl.TextColor3         = C.TEXT_DIM
    tagLbl.TextXAlignment     = Enum.TextXAlignment.Center
    tagLbl.Text               = "TAB"
    corner(tagLbl, 4)

    row.MouseEnter:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(26, 26, 26)}):Play()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(14, 14, 14)}):Play()
    end)
    row.MouseButton1Click:Connect(function() switchTab(tabKey) end)
    return row
end

-- ── Feature result row
local function mkFeatureRow(fname, ftab)
    local row = Instance.new("TextButton", resultsHolder)
    row.Size             = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    row.BorderSizePixel  = 0
    row.Text             = ""
    row.AutoButtonColor  = false
    corner(row, 7)
    local stroke = Instance.new("UIStroke", row)
    stroke.Color = C.BORDER; stroke.Thickness = 1; stroke.Transparency = 0.55

    local nameLbl = Instance.new("TextLabel", row)
    nameLbl.Size               = UDim2.new(1, -10, 0, 22)
    nameLbl.Position           = UDim2.new(0, 12, 0, 4)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font               = Enum.Font.GothamSemibold
    nameLbl.TextSize           = 13
    nameLbl.TextColor3         = C.TEXT
    nameLbl.TextXAlignment     = Enum.TextXAlignment.Left
    nameLbl.TextTruncate       = Enum.TextTruncate.AtEnd
    nameLbl.Text               = fname

    local subLbl = Instance.new("TextLabel", row)
    subLbl.Size               = UDim2.new(1, -10, 0, 14)
    subLbl.Position           = UDim2.new(0, 12, 0, 24)
    subLbl.BackgroundTransparency = 1
    subLbl.Font               = Enum.Font.Gotham
    subLbl.TextSize           = 10
    subLbl.TextColor3         = C.TEXT_DIM
    subLbl.TextXAlignment     = Enum.TextXAlignment.Left
    subLbl.Text               = ftab:gsub("Tab", "") .. " Tab"

    row.MouseEnter:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(24, 24, 24)}):Play()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(12, 12, 12)}):Play()
    end)
    row.MouseButton1Click:Connect(function() switchTab(ftab) end)
    return row
end

-- ── Separator
local function mkResultSep()
    local s = Instance.new("Frame", resultsHolder)
    s.Size             = UDim2.new(1, 0, 0, 1)
    s.BackgroundColor3 = C.BORDER
    s.BorderSizePixel  = 0
    return s
end

-- ── Feature list
local allFeatures = {
    {"Fly",                  "PlayerTab"}, {"Noclip",              "PlayerTab"},
    {"InfJump",              "PlayerTab"}, {"Walkspeed",           "PlayerTab"},
    {"Jump Power",           "PlayerTab"}, {"Fly Speed",           "PlayerTab"},
    {"Fly Key",              "PlayerTab"}, {"Headlight",           "PlayerTab"},
    {"Hard Dragger",         "PlayerTab"}, {"BTools",              "PlayerTab"},
    {"Teleport Locations",   "TeleportTab"},{"To Player",          "TeleportTab"},
    {"To Base",              "TeleportTab"},{"Spawn",              "TeleportTab"},
    {"Wood Dropoff",         "TeleportTab"},{"Land Store",         "TeleportTab"},
    {"Teleport Selected",    "ItemTab"},   {"Group Selection",     "ItemTab"},
    {"Click Selection",      "ItemTab"},   {"Lasso Tool",          "ItemTab"},
    {"Deselect All",         "ItemTab"},   {"Set Destination",     "ItemTab"},
    {"GUI Keybind",          "SettingsTab"},{"Ping",               "HomeTab"},
    {"Rejoin",               "HomeTab"},   {"Server Hop",          "HomeTab"},
    {"Always Day",           "WorldTab"},  {"Always Night",        "WorldTab"},
    {"Remove Fog",           "WorldTab"},  {"Walk On Water",       "WorldTab"},
    {"Remove Water",         "WorldTab"},  {"Shadows",             "WorldTab"},
    {"Auto Buy",             "AutoBuyTab"},{"Buy Blueprints",      "AutoBuyTab"},
    {"Buy RukiryAxe",        "AutoBuyTab"},{"Services",            "AutoBuyTab"},
    {"Load Base",            "SlotTab"},   {"Force Save",          "SlotTab"},
    {"Free Land",            "SlotTab"},   {"Max Land",            "SlotTab"},
    {"Click To Expand Land", "SlotTab"},   {"Take Land",           "SlotTab"},
    {"Base Dupe",            "DupeTab"},   {"Single Truck",        "DupeTab"},
    {"Batch Trucks",         "DupeTab"},   {"Grid Size",           "Pixel ArtTab"},
    {"Rotation Step",        "Pixel ArtTab"},{"Follow Mouse",      "Pixel ArtTab"},
    {"Snap to Grid",         "Pixel ArtTab"},{"Center on Plot",    "Pixel ArtTab"},
    {"Remove Pixel Art",     "Pixel ArtTab"},{"Vehicle Spawner",   "VehicleTab"},
}

-- ── Update function
local function updateSearchResults(query)
    -- Clear all result children (keep layout)
    for _, child in ipairs(resultsHolder:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then
            child:Destroy()
        end
    end

    local lq = string.lower(query or "")

    -- Show tabs section
    local tabMatches = {}
    for _, name in ipairs(tabs) do
        if lq == "" or string.find(string.lower(name), lq, 1, true) then
            table.insert(tabMatches, name)
        end
    end

    if #tabMatches > 0 then
        mkResultHeader("Tabs")
        for _, name in ipairs(tabMatches) do
            mkTabRow(name, name .. "Tab")
        end
    end

    -- Show features section (only when searching)
    if lq ~= "" then
        local featMatches = {}
        local seen = {}
        for _, entry in ipairs(allFeatures) do
            local fname, ftab = entry[1], entry[2]
            if string.find(string.lower(fname), lq, 1, true) and not seen[fname] then
                seen[fname] = true
                table.insert(featMatches, {fname, ftab})
            end
        end
        if #featMatches > 0 then
            if #tabMatches > 0 then mkResultSep() end
            mkResultHeader("Features")
            for _, entry in ipairs(featMatches) do
                mkFeatureRow(entry[1], entry[2])
            end
        end
    end
end

searchInput:GetPropertyChangedSignal("Text"):Connect(function()
    updateSearchResults(searchInput.Text)
end)
task.delay(0.1, function() updateSearchResults("") end)


-- UNIFIED INPUT HANDLER
-- ════════════════════════════════════════════════════

local inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if not _G.VH then return end

    if getWaitingForKeyGUI() then
        setWaitingForKeyGUI(false)
        setCurrentToggleKey(input.KeyCode)
        if keybindButtonGUI and keybindButtonGUI.Parent then
            keybindButtonGUI.Text = "Toggle Key: " .. getCurrentToggleKey().Name
            -- Flash grey (no green) to confirm
            TweenService:Create(keybindButtonGUI,
                TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 1, true),
                {BackgroundColor3 = Color3.fromRGB(130, 130, 130)}):Play()
        end
        return
    end

    if getWaitingForFlyKey() then
        setWaitingForFlyKey(false)
        setCurrentFlyKey(input.KeyCode)
        if flyKeyBtn and flyKeyBtn.Parent then
            flyKeyBtn.Text             = input.KeyCode.Name
            flyKeyBtn.BackgroundColor3 = BTN_COLOR
        end
        return
    end

    if input.KeyCode == getCurrentToggleKey() then toggleGUI(); return end

    if input.KeyCode == getCurrentFlyKey() and getFlyToggleEnabled() then
        if getIsFlyEnabled() then stopFly() else startFly() end
    end
end)

-- ════════════════════════════════════════════════════
-- CLEANUP
-- ════════════════════════════════════════════════════

table.insert(cleanupTasks, function()
    if inputConn then inputConn:Disconnect(); inputConn = nil end
end)

_G.VH.keybindButtonGUI = keybindButtonGUI
print("[VanillaHub] Vanilla3 loaded — black/grey/white theme")
