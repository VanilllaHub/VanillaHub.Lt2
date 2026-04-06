if not _G.VH then
    warn("[VanillaHub] Vanilla14 (WireArtTab): _G.VH not found. Execute Vanilla1 first.")
    return
end

local VH           = _G.VH
local TweenService = VH.TweenService
local pages        = VH.pages
local THEME_TEXT   = VH.THEME_TEXT
local SW_ON        = VH.SW_ON
local SW_OFF       = VH.SW_OFF
local SW_KNOB_ON   = VH.SW_KNOB_ON
local SW_KNOB_OFF  = VH.SW_KNOB_OFF

local wh = pages["WireArtTab"]
if not wh then
    warn("[VanillaHub] Vanilla14: 'WireArtTab' page not found. Check Vanilla1 tab name.")
    return
end

-- Test switch
local row = Instance.new("Frame", wh)
row.Size = UDim2.new(1, 0, 0, 36)
row.BackgroundTransparency = 1

local lbl = Instance.new("TextLabel", row)
lbl.Size = UDim2.new(1, -60, 1, 0)
lbl.Position = UDim2.new(0, 10, 0, 0)
lbl.BackgroundTransparency = 1
lbl.Font = Enum.Font.GothamSemibold
lbl.TextSize = 13
lbl.TextColor3 = THEME_TEXT
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.Text = "Test Switch"

local swTrack = Instance.new("Frame", row)
swTrack.Size = UDim2.new(0, 40, 0, 22)
swTrack.Position = UDim2.new(1, -50, 0.5, -11)
swTrack.BackgroundColor3 = SW_OFF
swTrack.BorderSizePixel = 0
Instance.new("UICorner", swTrack).CornerRadius = UDim.new(0, 11)

local swKnob = Instance.new("Frame", swTrack)
swKnob.Size = UDim2.new(0, 16, 0, 16)
swKnob.Position = UDim2.new(0, 3, 0.5, -8)
swKnob.BackgroundColor3 = SW_KNOB_OFF
swKnob.BorderSizePixel = 0
Instance.new("UICorner", swKnob).CornerRadius = UDim.new(0, 8)

local swBtn = Instance.new("TextButton", swTrack)
swBtn.Size = UDim2.new(1, 0, 1, 0)
swBtn.BackgroundTransparency = 1
swBtn.Text = ""

local swState = false
swBtn.MouseButton1Click:Connect(function()
    swState = not swState
    TweenService:Create(swTrack, TweenInfo.new(0.15), {BackgroundColor3 = swState and SW_ON or SW_OFF}):Play()
    TweenService:Create(swKnob,  TweenInfo.new(0.15), {
        Position = swState and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = swState and SW_KNOB_ON or SW_KNOB_OFF
    }):Play()
    lbl.Text = swState and "Test Switch  ✓  (tab is working!)" or "Test Switch"
end)

print("[VanillaHub] Vanilla14 loaded — WireArtTab test switch ready.")
