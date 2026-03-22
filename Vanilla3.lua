-- ════════════════════════════════════════════════════
-- VANILLA3 — FULL REWRITE
-- Requires Vanilla1 (_G.VH) to be loaded first.
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
local BTN_COLOR        = _G.VH.BTN_COLOR
local BTN_HOVER        = _G.VH.BTN_HOVER
local THEME_TEXT       = _G.VH.THEME_TEXT or Color3.fromRGB(220, 220, 220)
local switchTab        = _G.VH.switchTab
local toggleGUI        = _G.VH.toggleGUI
local stopFly          = _G.VH.stopFly
local startFly         = _G.VH.startFly
local flyKeyBtn        = _G.VH.flyKeyBtn

local function getWaitingForFlyKey()   return _G.VH and _G.VH.waitingForFlyKey end
local function setWaitingForFlyKey(v)  if _G.VH then _G.VH.waitingForFlyKey = v end end
local function getWaitingForKeyGUI()   return _G.VH and _G.VH.waitingForKeyGUI end
local function setWaitingForKeyGUI(v)  if _G.VH then _G.VH.waitingForKeyGUI = v end end
local function getCurrentFlyKey()      return _G.VH and _G.VH.currentFlyKey or Enum.KeyCode.Q end
local function setCurrentFlyKey(v)     if _G.VH then _G.VH.currentFlyKey = v end end
local function getCurrentToggleKey()   return _G.VH and _G.VH.currentToggleKey or Enum.KeyCode.LeftAlt end
local function setCurrentToggleKey(v)  if _G.VH then _G.VH.currentToggleKey = v end end
local function getFlyToggleEnabled()   return _G.VH and _G.VH.flyToggleEnabled end
local function getIsFlyEnabled()       return _G.VH and _G.VH.isFlyActive end

local C = {
    BG         = Color3.fromRGB(10,  10,  10),
    CARD       = Color3.fromRGB(10,  10,  10),
    ROW        = Color3.fromRGB(30,  30,  30),
    BORDER     = Color3.fromRGB(55,  55,  55),
    BORDER_DIM = Color3.fromRGB(40,  40,  40),
    TEXT       = Color3.fromRGB(210, 210, 210),
    TEXT_MID   = Color3.fromRGB(150, 150, 150),
    TEXT_DIM   = Color3.fromRGB(90,  90,  90),
    ACCENT     = Color3.fromRGB(200, 200, 200),
    ACCENT_DIM = Color3.fromRGB(120, 120, 120),
    GLOW       = Color3.fromRGB(80,  80,  80),
    BTN        = Color3.fromRGB(14,  14,  14),
    BTN_HV     = Color3.fromRGB(32,  32,  32),
}

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
end

-- ════════════════════════════════════════════════════
-- WOOD TAB — COMING SOON CARD
-- ════════════════════════════════════════════════════
local woodPage = pages["WoodTab"]

local csOuter = Instance.new("Frame", woodPage)
csOuter.Size             = UDim2.new(1, -12, 0, 200)
csOuter.BackgroundColor3 = C.BG
csOuter.BorderSizePixel  = 0
corner(csOuter, 12)
local csBorderStroke = Instance.new("UIStroke", csOuter)
csBorderStroke.Color        = C.BORDER_DIM
csBorderStroke.Thickness    = 1.5
csBorderStroke.Transparency = 0

for row = 0, 3 do
    local g = Instance.new("Frame", csOuter)
    g.Size = UDim2.new(1, 0, 0, 1); g.Position = UDim2.new(0, 0, 0, 22 + row * 46)
    g.BackgroundColor3 = Color3.fromRGB(28, 28, 28); g.BorderSizePixel = 0; g.ZIndex = 1
end
for col = 0, 5 do
    local g = Instance.new("Frame", csOuter)
    g.Size = UDim2.new(0, 1, 1, 0); g.Position = UDim2.new(0, 28 + col * 44, 0, 0)
    g.BackgroundColor3 = Color3.fromRGB(28, 28, 28); g.BorderSizePixel = 0; g.ZIndex = 1
end

local glowBlob = Instance.new("Frame", csOuter)
glowBlob.Size = UDim2.new(0, 80, 0, 80); glowBlob.AnchorPoint = Vector2.new(0.5, 0)
glowBlob.Position = UDim2.new(0.5, 0, 0, 16); glowBlob.BackgroundColor3 = C.GLOW
glowBlob.BorderSizePixel = 0; glowBlob.BackgroundTransparency = 0.68; glowBlob.ZIndex = 2
corner(glowBlob, 40)

local lockCircle = Instance.new("Frame", csOuter)
lockCircle.Size = UDim2.new(0, 46, 0, 46); lockCircle.AnchorPoint = Vector2.new(0.5, 0)
lockCircle.Position = UDim2.new(0.5, 0, 0, 22); lockCircle.BackgroundColor3 = C.CARD
lockCircle.BorderSizePixel = 0; lockCircle.ZIndex = 3
corner(lockCircle, 23)
local lockStroke = Instance.new("UIStroke", lockCircle)
lockStroke.Color = C.ACCENT_DIM; lockStroke.Thickness = 1.5

local lockIcon = Instance.new("TextLabel", lockCircle)
lockIcon.Size = UDim2.new(1, -6, 1, -6); lockIcon.Position = UDim2.new(0, 3, 0, 3)
lockIcon.BackgroundTransparency = 1; lockIcon.Text = "Wood"
lockIcon.Font = Enum.Font.GothamBold; lockIcon.TextScaled = true
lockIcon.TextXAlignment = Enum.TextXAlignment.Center; lockIcon.TextYAlignment = Enum.TextYAlignment.Center
lockIcon.ZIndex = 4; lockIcon.TextColor3 = C.TEXT_DIM

local csTitleLbl = Instance.new("TextLabel", csOuter)
csTitleLbl.Size = UDim2.new(1, -16, 0, 24); csTitleLbl.Position = UDim2.new(0, 8, 0, 78)
csTitleLbl.BackgroundTransparency = 1; csTitleLbl.Font = Enum.Font.GothamBold; csTitleLbl.TextSize = 17
csTitleLbl.TextColor3 = C.ACCENT; csTitleLbl.TextXAlignment = Enum.TextXAlignment.Center
csTitleLbl.Text = "COMING SOON"; csTitleLbl.ZIndex = 5

local accentLine = Instance.new("Frame", csOuter)
accentLine.Size = UDim2.new(0, 56, 0, 2); accentLine.AnchorPoint = Vector2.new(0.5, 0)
accentLine.Position = UDim2.new(0.5, 0, 0, 105); accentLine.BackgroundColor3 = C.ACCENT_DIM
accentLine.BorderSizePixel = 0; accentLine.ZIndex = 5; corner(accentLine, 1)

local csSubLbl = Instance.new("TextLabel", csOuter)
csSubLbl.Size = UDim2.new(1, -20, 0, 14); csSubLbl.Position = UDim2.new(0, 10, 0, 112)
csSubLbl.BackgroundTransparency = 1; csSubLbl.Font = Enum.Font.GothamSemibold; csSubLbl.TextSize = 10
csSubLbl.TextColor3 = C.TEXT_DIM; csSubLbl.TextXAlignment = Enum.TextXAlignment.Center
csSubLbl.Text = "WOOD TAB  —  UNDER DEVELOPMENT"; csSubLbl.ZIndex = 5

local csDescLbl = Instance.new("TextLabel", csOuter)
csDescLbl.Size = UDim2.new(1, -24, 0, 36); csDescLbl.Position = UDim2.new(0, 12, 0, 130)
csDescLbl.BackgroundTransparency = 1; csDescLbl.Font = Enum.Font.Gotham; csDescLbl.TextSize = 10
csDescLbl.TextColor3 = C.TEXT_DIM; csDescLbl.TextXAlignment = Enum.TextXAlignment.Center
csDescLbl.TextWrapped = true
csDescLbl.Text = "Being rebuilt with improved tree cutting,\nsmarter log dragging & reliable sell logic."
csDescLbl.ZIndex = 5

local statusPill = Instance.new("Frame", csOuter)
statusPill.Size = UDim2.new(0, 148, 0, 20); statusPill.AnchorPoint = Vector2.new(0.5, 0)
statusPill.Position = UDim2.new(0.5, 0, 0, 172); statusPill.BackgroundColor3 = C.CARD
statusPill.BorderSizePixel = 0; statusPill.ZIndex = 5; corner(statusPill, 10)
local pillStroke = Instance.new("UIStroke", statusPill)
pillStroke.Color = C.BORDER_DIM; pillStroke.Thickness = 1; pillStroke.Transparency = 0.4

local pulseDot = Instance.new("Frame", statusPill)
pulseDot.Size = UDim2.new(0, 6, 0, 6); pulseDot.Position = UDim2.new(0, 10, 0.5, -3)
pulseDot.BackgroundColor3 = C.ACCENT; pulseDot.BorderSizePixel = 0; pulseDot.ZIndex = 6
corner(pulseDot, 3)

local pillLbl = Instance.new("TextLabel", statusPill)
pillLbl.Size = UDim2.new(1, -24, 1, 0); pillLbl.Position = UDim2.new(0, 22, 0, 0)
pillLbl.BackgroundTransparency = 1; pillLbl.Font = Enum.Font.GothamSemibold; pillLbl.TextSize = 10
pillLbl.TextColor3 = C.TEXT_MID; pillLbl.TextXAlignment = Enum.TextXAlignment.Left
pillLbl.Text = "In Development  -  v0.0"; pillLbl.ZIndex = 6

task.spawn(function()
    while true do
        TweenService:Create(pulseDot, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {BackgroundTransparency = 0.75}):Play()
        task.wait(0.9)
        TweenService:Create(pulseDot, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {BackgroundTransparency = 0}):Play()
        task.wait(0.9)
    end
end)

task.spawn(function()
    local cols = {Color3.fromRGB(60,60,60),Color3.fromRGB(85,85,85),Color3.fromRGB(45,45,45),Color3.fromRGB(75,75,75)}
    local i = 1
    while true do
        local nx = i % #cols + 1
        TweenService:Create(csBorderStroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Color = cols[nx]}):Play()
        i = nx; task.wait(2)
    end
end)

task.spawn(function()
    while true do
        TweenService:Create(lockCircle, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Position = UDim2.new(0.5, 0, 0, 18)}):Play()
        task.wait(1.4)
        TweenService:Create(lockCircle, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Position = UDim2.new(0.5, 0, 0, 26)}):Play()
        task.wait(1.4)
    end
end)

task.spawn(function()
    while true do
        TweenService:Create(glowBlob, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Position = UDim2.new(0.5, 0, 0, 12)}):Play()
        task.wait(1.4)
        TweenService:Create(glowBlob, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Position = UDim2.new(0.5, 0, 0, 20)}):Play()
        task.wait(1.4)
    end
end)

-- ════════════════════════════════════════════════════
-- SETTINGS TAB
-- ════════════════════════════════════════════════════
local keybindButtonGUI
local settingsPage = pages["SettingsTab"]

local kbFrame = Instance.new("Frame", settingsPage)
kbFrame.Size = UDim2.new(1, 0, 0, 70); kbFrame.BackgroundColor3 = C.CARD; kbFrame.BorderSizePixel = 0
corner(kbFrame, 10)
local kbStroke = Instance.new("UIStroke", kbFrame)
kbStroke.Color = C.BORDER; kbStroke.Thickness = 1; kbStroke.Transparency = 0.4

local kbTitle = Instance.new("TextLabel", kbFrame)
kbTitle.Size = UDim2.new(1, -20, 0, 28); kbTitle.Position = UDim2.new(0, 10, 0, 8)
kbTitle.BackgroundTransparency = 1; kbTitle.Font = Enum.Font.GothamBold; kbTitle.TextSize = 15
kbTitle.TextColor3 = C.TEXT; kbTitle.TextXAlignment = Enum.TextXAlignment.Left
kbTitle.Text = "GUI Toggle Keybind"

keybindButtonGUI = Instance.new("TextButton", kbFrame)
keybindButtonGUI.Size = UDim2.new(0, 200, 0, 28); keybindButtonGUI.Position = UDim2.new(0, 10, 0, 36)
keybindButtonGUI.BackgroundColor3 = C.BTN; keybindButtonGUI.BorderSizePixel = 0
keybindButtonGUI.Font = Enum.Font.Gotham; keybindButtonGUI.TextSize = 14
keybindButtonGUI.TextColor3 = C.TEXT; keybindButtonGUI.AutoButtonColor = false
keybindButtonGUI.Text = "Toggle Key: " .. getCurrentToggleKey().Name
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

table.insert(cleanupTasks, function()
    if inputConn then inputConn:Disconnect(); inputConn = nil end
end)

_G.VH.keybindButtonGUI = keybindButtonGUI
print("[VanillaHub] Vanilla3 loaded — black/grey/white theme")
