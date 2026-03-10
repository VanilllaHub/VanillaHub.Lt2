-- ════════════════════════════════════════════════════
-- VANILLAHUB v1.1.0 | LT2
-- ════════════════════════════════════════════════════

-- ── DESTROY OLD GUI + cleanup ────────────────────────
if type(_G.VanillaHubCleanup) == "function" then
    pcall(_G.VanillaHubCleanup)
    _G.VanillaHubCleanup = nil
end
for _, name in pairs({"VanillaHub", "VanillaHubWarning"}) do
    if game.CoreGui:FindFirstChild(name) then
        game.CoreGui[name]:Destroy()
    end
end
if _G.VH then
    if _G.VH.butter and _G.VH.butter.running then
        _G.VH.butter.running = false
        if _G.VH.butter.thread then pcall(task.cancel, _G.VH.butter.thread) end
        _G.VH.butter.thread = nil
    end
    _G.VH = nil
end
if workspace:FindFirstChild("VanillaHubTpCircle") then
    workspace.VanillaHubTpCircle:Destroy()
end

-- ── GAME CHECK ───────────────────────────────────────
if game.PlaceId ~= 13822889 then
    task.spawn(function()
        task.wait(0.4)
        local warnGui = Instance.new("ScreenGui")
        warnGui.Name = "VanillaHubWarning"; warnGui.Parent = game.CoreGui; warnGui.ResetOnSpawn = false
        local frame = Instance.new("Frame", warnGui)
        frame.Size = UDim2.new(0,400,0,220); frame.Position = UDim2.new(0.5,-200,0.5,-110)
        frame.BackgroundColor3 = Color3.fromRGB(12,12,12); frame.BackgroundTransparency = 0.25; frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0,16)
        local uiStroke = Instance.new("UIStroke", frame)
        uiStroke.Color = Color3.fromRGB(190,50,50); uiStroke.Thickness = 1.5; uiStroke.Transparency = 0.45
        local icon = Instance.new("TextLabel", frame)
        icon.Size = UDim2.new(0,48,0,48); icon.Position = UDim2.new(0,24,0,24)
        icon.BackgroundTransparency = 1; icon.Font = Enum.Font.GothamBlack
        icon.TextSize = 42; icon.TextColor3 = Color3.fromRGB(255,90,90); icon.Text = "!"
        local msg = Instance.new("TextLabel", frame)
        msg.Size = UDim2.new(1,-100,0,120); msg.Position = UDim2.new(0,90,0,30)
        msg.BackgroundTransparency = 1; msg.Font = Enum.Font.GothamSemibold; msg.TextSize = 15
        msg.TextColor3 = Color3.fromRGB(220,220,220); msg.TextXAlignment = Enum.TextXAlignment.Left
        msg.TextYAlignment = Enum.TextYAlignment.Top; msg.TextWrapped = true
        msg.Text = "VanillaHub is made exclusively for Lumber Tycoon 2 (Place ID: 13822889).\n\nPlease join Lumber Tycoon 2 and re-execute the script there."
        local okBtn = Instance.new("TextButton", frame)
        okBtn.Size = UDim2.new(0,160,0,50); okBtn.Position = UDim2.new(0.5,-80,1,-70)
        okBtn.BackgroundColor3 = Color3.fromRGB(190,50,50); okBtn.BorderSizePixel = 0
        okBtn.Font = Enum.Font.GothamBold; okBtn.TextSize = 17
        okBtn.TextColor3 = Color3.fromRGB(255,255,255); okBtn.Text = "I Understand"
        Instance.new("UICorner", okBtn).CornerRadius = UDim.new(0,12)
        local TS2 = game:GetService("TweenService")
        frame.BackgroundTransparency = 1; msg.TextTransparency = 1; icon.TextTransparency = 1
        okBtn.BackgroundTransparency = 1; okBtn.TextTransparency = 1
        TS2:Create(frame, TweenInfo.new(0.75,Enum.EasingStyle.Quint), {BackgroundTransparency=0.25}):Play()
        TS2:Create(msg,   TweenInfo.new(0.85,Enum.EasingStyle.Quint), {TextTransparency=0}):Play()
        TS2:Create(icon,  TweenInfo.new(0.85,Enum.EasingStyle.Quint), {TextTransparency=0}):Play()
        TS2:Create(okBtn, TweenInfo.new(0.95,Enum.EasingStyle.Quint), {BackgroundTransparency=0,TextTransparency=0}):Play()
        okBtn.MouseButton1Click:Connect(function()
            local ot = TS2:Create(frame, TweenInfo.new(0.8,Enum.EasingStyle.Quint), {BackgroundTransparency=1})
            ot:Play()
            TS2:Create(msg,   TweenInfo.new(0.8), {TextTransparency=1}):Play()
            TS2:Create(icon,  TweenInfo.new(0.8), {TextTransparency=1}):Play()
            TS2:Create(okBtn, TweenInfo.new(0.8), {BackgroundTransparency=1,TextTransparency=1}):Play()
            ot.Completed:Connect(function() if warnGui and warnGui.Parent then warnGui:Destroy() end end)
        end)
    end)
    return
end

-- ════════════════════════════════════════════════════
-- SERVICES & PLAYER
-- ════════════════════════════════════════════════════
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TeleportService   = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats             = game:GetService("Stats")
local player            = Players.LocalPlayer
local mouse             = player:GetMouse()

-- ════════════════════════════════════════════════════
-- THEME  (clean black & grey — no purple)
-- ════════════════════════════════════════════════════
local C = {
    bg        = Color3.fromRGB(14,14,16),
    sidebar   = Color3.fromRGB(10,10,12),
    topbar    = Color3.fromRGB(12,12,14),
    card      = Color3.fromRGB(22,22,26),
    cardHov   = Color3.fromRGB(32,32,38),
    btn       = Color3.fromRGB(30,30,36),
    btnHov    = Color3.fromRGB(48,48,56),
    tabActive = Color3.fromRGB(48,48,58),
    tabHov    = Color3.fromRGB(26,26,32),
    tabInact  = Color3.fromRGB(15,15,18),
    sep       = Color3.fromRGB(30,30,38),
    border    = Color3.fromRGB(40,40,50),
    text      = Color3.fromRGB(215,215,220),
    textDim   = Color3.fromRGB(120,120,135),
    textHint  = Color3.fromRGB(75,75,90),
    accent    = Color3.fromRGB(80,80,100),
    knob      = Color3.fromRGB(195,195,205),
    toggleOn  = Color3.fromRGB(65,165,85),
    toggleOff = Color3.fromRGB(38,38,50),
    red       = Color3.fromRGB(175,48,48),
    redHov    = Color3.fromRGB(205,62,62),
    green     = Color3.fromRGB(55,155,75),
}

-- ════════════════════════════════════════════════════
-- EXECUTOR DETECTION
-- Probes executor-specific globals
-- ════════════════════════════════════════════════════
local function detectExecutor()
    -- Safe global probe: rawget never throws, returns nil for missing globals
    local function g(n) return rawget(_G, n) end

    -- Generic name APIs first (most reliable)
    if g("getexecutorname") then
        local ok, name = pcall(g("getexecutorname"))
        if ok and type(name) == "string" and #name > 0 then return name end
    end
    if g("identifyexecutor") then
        local ok, name = pcall(g("identifyexecutor"))
        if ok and type(name) == "string" and #name > 0 then return name end
    end

    -- Named executor globals
    local s = g("syn")
    if type(s) == "table" and s.request then return "Synapse X" end
    if g("KRNL_LOADED")   then return "Krnl" end
    if g("IS_SIRHURT_V3") then return "SirHurt" end
    if g("SENTINEL_V2")   then return "Sentinel" end
    if g("pebc_execute")  then return "ProtoSmasher" end
    if g("elysian")       then return "Elysian" end
    if type(g("fluxus")) == "table" then return "Fluxus" end
    if type(g("Oxygen"))  == "table" then return "Oxygen U" end

    -- Executor-injected Drawing API present but name unknown
    if g("Drawing") then return "Unknown Executor" end
    return "Unknown"
end

-- ════════════════════════════════════════════════════
-- SERVER REGION (latency heuristic)
-- ════════════════════════════════════════════════════
local function detectRegion(pingMs)
    if not pingMs then
        local ok, p = pcall(function()
            return math.round(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        if ok then pingMs = p else return "Unknown" end
    end
    if pingMs < 35  then return "Europe (EU)"
    elseif pingMs < 70  then return "US East"
    elseif pingMs < 110 then return "US West"
    elseif pingMs < 160 then return "South America"
    elseif pingMs < 220 then return "Asia / Oceania"
    else return "High Latency" end
end

-- ════════════════════════════════════════════════════
-- CLEANUP REGISTRY
-- All connections go through registerConn so onExit
-- disconnects everything reliably.
-- ════════════════════════════════════════════════════
local cleanupTasks = {}
local activeConns  = {}

local function registerConn(conn)
    table.insert(activeConns, conn)
    return conn
end

local function onExit()
    -- Disconnect every tracked connection
    for _, conn in ipairs(activeConns) do pcall(function() conn:Disconnect() end) end
    activeConns = {}
    -- Run custom cleanup tasks (stopFly, noclip reset, etc.)
    for _, fn in ipairs(cleanupTasks) do pcall(fn) end
    cleanupTasks = {}
    -- Restore character state
    pcall(function()
        local char = player.Character; if not char then return end
        local hum  = char:FindFirstChild("Humanoid")
        local hrp  = char:FindFirstChild("HumanoidRootPart")
        if hum then hum.PlatformStand=false; hum.WalkSpeed=16; hum.JumpPower=50 end
        if hrp then
            for _, obj in ipairs(hrp:GetChildren()) do
                if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") then pcall(function() obj:Destroy() end) end
            end
        end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide=true end) end
        end
    end)
    -- Remove workspace artifacts
    pcall(function()
        if workspace:FindFirstChild("VanillaHubTpCircle") then workspace.VanillaHubTpCircle:Destroy() end
    end)
    pcall(function()
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name == "WalkWaterPlane" then obj:Destroy() end
        end
    end)
    _G.VH = nil
    _G.VanillaHubCleanup = nil
end

_G.VanillaHubCleanup = onExit

-- ════════════════════════════════════════════════════
-- GUI SCAFFOLD
-- ════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name = "VanillaHub"; gui.Parent = game.CoreGui; gui.ResetOnSpawn = false
table.insert(cleanupTasks, function()
    if gui and gui.Parent then gui:Destroy() end
end)

local W, H = 535, 355

-- wrapper: transparent, used only for sizing / positioning
local wrapper = Instance.new("Frame", gui)
wrapper.Size = UDim2.new(0,0,0,0)
wrapper.Position = UDim2.new(0.5,-W/2,0.5,-H/2)
wrapper.BackgroundTransparency = 1
wrapper.BorderSizePixel = 0
wrapper.ClipsDescendants = false

-- main: visible window
local main = Instance.new("Frame", wrapper)
main.Size = UDim2.new(0,0,0,0)
main.BackgroundColor3 = C.bg
main.BackgroundTransparency = 1
main.BorderSizePixel = 0
main.ClipsDescendants = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0,12)
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = C.border; mainStroke.Thickness = 1; mainStroke.Transparency = 0.6

-- Open animation
TweenService:Create(wrapper, TweenInfo.new(0.6,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
    {Size=UDim2.new(0,W,0,H)}):Play()
TweenService:Create(main, TweenInfo.new(0.6,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
    {Size=UDim2.new(0,W,0,H), BackgroundTransparency=0}):Play()

-- ── TOP BAR ──────────────────────────────────────────
local topBar = Instance.new("Frame", main)
topBar.Size = UDim2.new(1,0,0,38)
topBar.BackgroundColor3 = C.topbar; topBar.BorderSizePixel = 0; topBar.ZIndex = 4

local topSep = Instance.new("Frame", topBar)
topSep.Size = UDim2.new(1,0,0,1); topSep.Position = UDim2.new(0,0,1,-1)
topSep.BackgroundColor3 = C.sep; topSep.BorderSizePixel = 0; topSep.ZIndex = 5

local hubIcon = Instance.new("ImageLabel", topBar)
hubIcon.Size = UDim2.new(0,24,0,24); hubIcon.Position = UDim2.new(0,8,0.5,-12)
hubIcon.BackgroundTransparency = 1; hubIcon.ScaleType = Enum.ScaleType.Fit; hubIcon.ZIndex = 6
hubIcon.Image = "rbxassetid://97128823316544"
Instance.new("UICorner", hubIcon).CornerRadius = UDim.new(0,5)

local titleLbl = Instance.new("TextLabel", topBar)
titleLbl.Size = UDim2.new(1,-80,1,0); titleLbl.Position = UDim2.new(0,40,0,0)
titleLbl.BackgroundTransparency = 1; titleLbl.Text = "VanillaHub v1.1.0 | LT2"
titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 15
titleLbl.TextColor3 = C.text; titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.ZIndex = 5

local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0,28,0,28); closeBtn.Position = UDim2.new(1,-35,0.5,-14)
closeBtn.BackgroundColor3 = C.red; closeBtn.Text = "×"
closeBtn.Font = Enum.Font.Gotham; closeBtn.TextSize = 20
closeBtn.TextColor3 = Color3.fromRGB(255,255,255); closeBtn.BorderSizePixel = 0; closeBtn.ZIndex = 5
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,7)
closeBtn.MouseEnter:Connect(function() TweenService:Create(closeBtn,TweenInfo.new(0.15),{BackgroundColor3=C.redHov}):Play() end)
closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn,TweenInfo.new(0.15),{BackgroundColor3=C.red}):Play() end)

-- Confirm close dialog
local function showConfirmClose()
    if main:FindFirstChild("ConfirmOverlay") then return end
    local overlay = Instance.new("Frame", main)
    overlay.Name="ConfirmOverlay"; overlay.Size=UDim2.new(1,0,1,0)
    overlay.BackgroundColor3=Color3.fromRGB(0,0,0); overlay.BackgroundTransparency=0.5; overlay.ZIndex=9
    local dialog = Instance.new("Frame", main)
    dialog.Name="ConfirmDialog"; dialog.Size=UDim2.new(0,330,0,160)
    dialog.Position=UDim2.new(0.5,-165,0.5,-80)
    dialog.BackgroundColor3=Color3.fromRGB(18,18,22); dialog.BorderSizePixel=0; dialog.ZIndex=10
    Instance.new("UICorner",dialog).CornerRadius=UDim.new(0,12)
    Instance.new("UIStroke",dialog).Color=C.border
    local dtitle=Instance.new("TextLabel",dialog)
    dtitle.Size=UDim2.new(1,0,0,36); dtitle.BackgroundTransparency=1
    dtitle.Font=Enum.Font.GothamBold; dtitle.TextSize=17
    dtitle.TextColor3=C.text; dtitle.Text="Close VanillaHub?"; dtitle.ZIndex=11
    local dmsg=Instance.new("TextLabel",dialog)
    dmsg.Size=UDim2.new(1,-28,0,48); dmsg.Position=UDim2.new(0,14,0,36)
    dmsg.BackgroundTransparency=1; dmsg.Font=Enum.Font.Gotham; dmsg.TextSize=13
    dmsg.TextColor3=C.textDim; dmsg.TextWrapped=true
    dmsg.Text="All running features will stop. You'll need to re-execute to use VanillaHub again."
    dmsg.TextYAlignment=Enum.TextYAlignment.Top; dmsg.ZIndex=11
    local cancelB=Instance.new("TextButton",dialog)
    cancelB.Size=UDim2.new(0,130,0,38); cancelB.Position=UDim2.new(0.5,-142,1,-52)
    cancelB.BackgroundColor3=C.btn; cancelB.Text="Cancel"
    cancelB.Font=Enum.Font.GothamSemibold; cancelB.TextSize=13
    cancelB.TextColor3=C.text; cancelB.ZIndex=11; cancelB.BorderSizePixel=0
    Instance.new("UICorner",cancelB).CornerRadius=UDim.new(0,8)
    local confirmB=Instance.new("TextButton",dialog)
    confirmB.Size=UDim2.new(0,130,0,38); confirmB.Position=UDim2.new(0.5,12,1,-52)
    confirmB.BackgroundColor3=C.red; confirmB.Text="Close"
    confirmB.Font=Enum.Font.GothamSemibold; confirmB.TextSize=13
    confirmB.TextColor3=Color3.fromRGB(255,255,255); confirmB.ZIndex=11; confirmB.BorderSizePixel=0
    Instance.new("UICorner",confirmB).CornerRadius=UDim.new(0,8)
    for _,b in {cancelB,confirmB} do
        b.MouseEnter:Connect(function()
            TweenService:Create(b,TweenInfo.new(0.15),
                {BackgroundColor3=(b==confirmB) and C.redHov or C.cardHov}):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b,TweenInfo.new(0.15),
                {BackgroundColor3=(b==confirmB) and C.red or C.btn}):Play()
        end)
    end
    cancelB.MouseButton1Click:Connect(function() overlay:Destroy(); dialog:Destroy() end)
    confirmB.MouseButton1Click:Connect(function()
        overlay:Destroy(); dialog:Destroy()
        onExit()
        local t=TweenService:Create(main,TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
            {Size=UDim2.new(0,0,0,0),BackgroundTransparency=1})
        TweenService:Create(wrapper,TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
            {Size=UDim2.new(0,0,0,0)}):Play()
        t:Play(); t.Completed:Connect(function() if gui and gui.Parent then gui:Destroy() end end)
    end)
end
closeBtn.MouseButton1Click:Connect(showConfirmClose)

-- Drag
local dragging,dragStart,startPos=false,nil,nil
topBar.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true; dragStart=input.Position; startPos=wrapper.Position
    end
end)
registerConn(UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
        local d=input.Position-dragStart
        wrapper.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,
                                   startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
end))
registerConn(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end))

-- ── SIDEBAR ──────────────────────────────────────────
local side = Instance.new("ScrollingFrame", main)
side.Size=UDim2.new(0,150,1,-38); side.Position=UDim2.new(0,0,0,38)
side.BackgroundColor3=C.sidebar; side.BorderSizePixel=0
side.ScrollBarThickness=3; side.ScrollBarImageColor3=C.border
side.CanvasSize=UDim2.new(0,0,0,0)
local sidePad=Instance.new("UIPadding",side)
sidePad.PaddingTop=UDim.new(0,8); sidePad.PaddingBottom=UDim.new(0,8)
sidePad.PaddingLeft=UDim.new(0,6); sidePad.PaddingRight=UDim.new(0,6)
local sideLayout=Instance.new("UIListLayout",side)
sideLayout.Padding=UDim.new(0,4); sideLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center
sideLayout.SortOrder=Enum.SortOrder.LayoutOrder
sideLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    side.CanvasSize=UDim2.new(0,0,0,sideLayout.AbsoluteContentSize.Y+16)
end)

local sideSepLine=Instance.new("Frame",main)
sideSepLine.Size=UDim2.new(0,1,1,-38); sideSepLine.Position=UDim2.new(0,150,0,38)
sideSepLine.BackgroundColor3=C.sep; sideSepLine.BorderSizePixel=0; sideSepLine.ZIndex=3

-- ── CONTENT AREA ─────────────────────────────────────
local content=Instance.new("Frame",main)
content.Size=UDim2.new(1,-151,1,-38); content.Position=UDim2.new(0,151,0,38)
content.BackgroundColor3=C.bg; content.BorderSizePixel=0

-- ── WELCOME TOAST ────────────────────────────────────
task.spawn(function()
    task.wait(0.85)
    if not (gui and gui.Parent) then return end
    local wf=Instance.new("Frame",gui)
    wf.Size=UDim2.new(0,350,0,76); wf.Position=UDim2.new(0.5,-175,1,-98)
    wf.BackgroundColor3=Color3.fromRGB(18,18,22); wf.BackgroundTransparency=1; wf.BorderSizePixel=0
    Instance.new("UICorner",wf).CornerRadius=UDim.new(0,12)
    local ws=Instance.new("UIStroke",wf); ws.Color=C.border; ws.Thickness=1; ws.Transparency=0.4
    local pfp=Instance.new("ImageLabel",wf)
    pfp.Size=UDim2.new(0,52,0,52); pfp.Position=UDim2.new(0,14,0.5,-26)
    pfp.BackgroundTransparency=1; pfp.ImageTransparency=1
    pfp.Image=Players:GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)
    Instance.new("UICorner",pfp).CornerRadius=UDim.new(1,0)
    local wt=Instance.new("TextLabel",wf)
    wt.Size=UDim2.new(1,-82,1,-12); wt.Position=UDim2.new(0,78,0,6)
    wt.BackgroundTransparency=1; wt.Font=Enum.Font.GothamSemibold; wt.TextSize=15
    wt.TextColor3=C.text; wt.TextXAlignment=Enum.TextXAlignment.Left
    wt.TextYAlignment=Enum.TextYAlignment.Center; wt.TextWrapped=true; wt.TextTransparency=1
    wt.Text="Welcome back, "..player.DisplayName.."!"
    TweenService:Create(wf,  TweenInfo.new(0.6,Enum.EasingStyle.Quint),{BackgroundTransparency=0.22}):Play()
    TweenService:Create(wt,  TweenInfo.new(0.6,Enum.EasingStyle.Quint),{TextTransparency=0}):Play()
    TweenService:Create(pfp, TweenInfo.new(0.6,Enum.EasingStyle.Quint),{ImageTransparency=0}):Play()
    task.delay(6, function()
        if not (wf and wf.Parent) then return end
        local ot=TweenService:Create(wf,TweenInfo.new(1,Enum.EasingStyle.Quint),{BackgroundTransparency=1})
        ot:Play()
        TweenService:Create(wt,  TweenInfo.new(1),{TextTransparency=1}):Play()
        TweenService:Create(pfp, TweenInfo.new(1),{ImageTransparency=1}):Play()
        ot.Completed:Connect(function() if wf and wf.Parent then wf:Destroy() end end)
    end)
end)

-- ════════════════════════════════════════════════════
-- TABS
-- ════════════════════════════════════════════════════
local tabNames={"Home","Player","World","Teleport","Wood","Slot","Dupe","Item","Sorter","AutoBuy","Pixel Art","Build","Vehicle","Search","Settings"}
local pages={}

for _,name in ipairs(tabNames) do
    local page=Instance.new("ScrollingFrame",content)
    page.Name=name.."Tab"; page.Size=UDim2.new(1,0,1,0)
    page.BackgroundTransparency=1; page.BorderSizePixel=0
    page.ScrollBarThickness=4; page.ScrollBarImageColor3=C.border
    page.Visible=false; page.CanvasSize=UDim2.new(0,0,0,0)
    local list=Instance.new("UIListLayout",page)
    list.Padding=UDim.new(0,9); list.HorizontalAlignment=Enum.HorizontalAlignment.Center
    list.SortOrder=Enum.SortOrder.LayoutOrder
    local pad=Instance.new("UIPadding",page)
    pad.PaddingTop=UDim.new(0,13); pad.PaddingBottom=UDim.new(0,13)
    pad.PaddingLeft=UDim.new(0,11); pad.PaddingRight=UDim.new(0,11)
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize=UDim2.new(0,0,0,list.AbsoluteContentSize.Y+26)
    end)
    pages[name.."Tab"]=page
end

local activeTabBtn=nil
local function switchTab(targetName)
    for _,page in pairs(pages) do page.Visible=(page.Name==targetName) end
    if activeTabBtn then
        TweenService:Create(activeTabBtn,TweenInfo.new(0.2),
            {BackgroundColor3=C.tabInact,TextColor3=C.textDim}):Play()
    end
    local btn=side:FindFirstChild(targetName:gsub("Tab",""))
    if btn then
        activeTabBtn=btn
        TweenService:Create(btn,TweenInfo.new(0.2),
            {BackgroundColor3=C.tabActive,TextColor3=C.text}):Play()
    end
end

for _,name in ipairs(tabNames) do
    local btn=Instance.new("TextButton",side)
    btn.Name=name; btn.Size=UDim2.new(1,0,0,34)
    btn.BackgroundColor3=C.tabInact; btn.BorderSizePixel=0
    btn.Text=name; btn.Font=Enum.Font.GothamSemibold; btn.TextSize=13
    btn.TextColor3=C.textDim; btn.TextXAlignment=Enum.TextXAlignment.Left
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,7)
    Instance.new("UIPadding",btn).PaddingLeft=UDim.new(0,11)
    btn.MouseEnter:Connect(function()
        if activeTabBtn~=btn then
            TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=C.tabHov,TextColor3=C.text}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeTabBtn~=btn then
            TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=C.tabInact,TextColor3=C.textDim}):Play()
        end
    end)
    btn.MouseButton1Click:Connect(function() switchTab(name.."Tab") end)
end

switchTab("HomeTab")

-- ════════════════════════════════════════════════════
-- GUI TOGGLE (ALT) — wrapper shrinks too so no ghost bg
-- ════════════════════════════════════════════════════
local currentToggleKey=Enum.KeyCode.LeftAlt
local guiOpen=true
local isAnimatingGUI=false

local function toggleGUI()
    if isAnimatingGUI then return end
    guiOpen=not guiOpen; isAnimatingGUI=true
    if guiOpen then
        main.Visible=true; main.Size=UDim2.new(0,0,0,0); main.BackgroundTransparency=1
        wrapper.Size=UDim2.new(0,0,0,0)
        local t=TweenService:Create(main,TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
            {Size=UDim2.new(0,W,0,H),BackgroundTransparency=0})
        TweenService:Create(wrapper,TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
            {Size=UDim2.new(0,W,0,H)}):Play()
        t:Play(); t.Completed:Connect(function() isAnimatingGUI=false end)
    else
        local t=TweenService:Create(main,TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
            {Size=UDim2.new(0,0,0,0),BackgroundTransparency=1})
        TweenService:Create(wrapper,TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
            {Size=UDim2.new(0,0,0,0)}):Play()
        t:Play(); t.Completed:Connect(function() main.Visible=false; isAnimatingGUI=false end)
    end
end

-- ════════════════════════════════════════════════════
-- SHARED UI COMPONENT BUILDERS
-- ════════════════════════════════════════════════════
local function makeSectionLabel(parent, text)
    local w=Instance.new("Frame",parent)
    w.Size=UDim2.new(1,0,0,22); w.BackgroundTransparency=1
    local lbl=Instance.new("TextLabel",w)
    lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=10
    lbl.TextColor3=C.textDim; lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Text="  "..string.upper(text)
end

local function makeSep(parent)
    local sep=Instance.new("Frame",parent)
    sep.Size=UDim2.new(1,0,0,1)
    sep.BackgroundColor3=C.sep; sep.BorderSizePixel=0
end

local function makeButton(parent, text, cb)
    local btn=Instance.new("TextButton",parent)
    btn.Size=UDim2.new(1,0,0,34); btn.BackgroundColor3=C.btn; btn.BorderSizePixel=0
    btn.Text=text; btn.Font=Enum.Font.GothamSemibold; btn.TextSize=13; btn.TextColor3=C.text
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)
    btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=C.btnHov}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=C.btn}):Play() end)
    if cb then btn.MouseButton1Click:Connect(cb) end
    return btn
end

local function makeToggle(parent, text, default, cb)
    local frame=Instance.new("Frame",parent)
    frame.Size=UDim2.new(1,0,0,36); frame.BackgroundColor3=C.card; frame.BorderSizePixel=0
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,8)
    local lbl=Instance.new("TextLabel",frame)
    lbl.Size=UDim2.new(1,-54,1,0); lbl.Position=UDim2.new(0,12,0,0); lbl.BackgroundTransparency=1
    lbl.Text=text; lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=13
    lbl.TextColor3=C.text; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local tb=Instance.new("TextButton",frame)
    tb.Size=UDim2.new(0,36,0,20); tb.Position=UDim2.new(1,-46,0.5,-10)
    tb.BackgroundColor3=default and C.toggleOn or C.toggleOff; tb.Text=""; tb.BorderSizePixel=0
    Instance.new("UICorner",tb).CornerRadius=UDim.new(1,0)
    local circle=Instance.new("Frame",tb)
    circle.Size=UDim2.new(0,14,0,14); circle.Position=UDim2.new(0,default and 20 or 2,0.5,-7)
    circle.BackgroundColor3=Color3.fromRGB(255,255,255); circle.BorderSizePixel=0
    Instance.new("UICorner",circle).CornerRadius=UDim.new(1,0)
    local toggled=default
    if cb then cb(toggled) end
    tb.MouseButton1Click:Connect(function()
        toggled=not toggled
        TweenService:Create(tb,TweenInfo.new(0.2,Enum.EasingStyle.Quint),
            {BackgroundColor3=toggled and C.toggleOn or C.toggleOff}):Play()
        TweenService:Create(circle,TweenInfo.new(0.2,Enum.EasingStyle.Quint),
            {Position=UDim2.new(0,toggled and 20 or 2,0.5,-7)}):Play()
        if cb then cb(toggled) end
    end)
    return frame
end

local function makeSlider(parent, text, minV, maxV, defV, cb)
    local frame=Instance.new("Frame",parent)
    frame.Size=UDim2.new(1,0,0,54); frame.BackgroundColor3=C.card; frame.BorderSizePixel=0
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,8)
    local topRow=Instance.new("Frame",frame)
    topRow.Size=UDim2.new(1,-16,0,22); topRow.Position=UDim2.new(0,8,0,7); topRow.BackgroundTransparency=1
    local lbl=Instance.new("TextLabel",topRow)
    lbl.Size=UDim2.new(0.72,0,1,0); lbl.BackgroundTransparency=1
    lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=13
    lbl.TextColor3=C.text; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=text
    local valLbl=Instance.new("TextLabel",topRow)
    valLbl.Size=UDim2.new(0.28,0,1,0); valLbl.Position=UDim2.new(0.72,0,0,0); valLbl.BackgroundTransparency=1
    valLbl.Font=Enum.Font.GothamBold; valLbl.TextSize=13
    valLbl.TextColor3=C.textDim; valLbl.TextXAlignment=Enum.TextXAlignment.Right; valLbl.Text=tostring(defV)
    local track=Instance.new("Frame",frame)
    track.Size=UDim2.new(1,-16,0,5); track.Position=UDim2.new(0,8,0,38)
    track.BackgroundColor3=C.sep; track.BorderSizePixel=0
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new((defV-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3=C.accent; fill.BorderSizePixel=0
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("TextButton",track)
    knob.Size=UDim2.new(0,14,0,14); knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new((defV-minV)/(maxV-minV),0,0.5,0)
    knob.BackgroundColor3=C.knob; knob.Text=""; knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local ds=false
    local function upd(absX)
        local r=math.clamp((absX-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local v=math.round(minV+r*(maxV-minV))
        fill.Size=UDim2.new(r,0,1,0); knob.Position=UDim2.new(r,0,0.5,0); valLbl.Text=tostring(v)
        if cb then cb(v) end
    end
    knob.MouseButton1Down:Connect(function() ds=true end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then ds=true; upd(i.Position.X) end
    end)
    registerConn(UserInputService.InputChanged:Connect(function(i)
        if ds and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end
    end))
    registerConn(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then ds=false end
    end))
end

-- 3-button mode row (Normal / Random / Group)
local function makeModeRow(parent, modes, default, onSelect)
    local row=Instance.new("Frame",parent)
    row.Size=UDim2.new(1,0,0,34); row.BackgroundTransparency=1
    local btns={}
    local function updateActive(active)
        for _,mb in ipairs(btns) do
            local isA=mb.Text==active
            TweenService:Create(mb,TweenInfo.new(0.2),{
                BackgroundColor3=isA and C.tabActive or C.btn,
                TextColor3=isA and C.text or C.textDim,
            }):Play()
        end
    end
    for i,mName in ipairs(modes) do
        local xs=1/#modes
        local mb=Instance.new("TextButton",row)
        mb.Size=UDim2.new(xs,-3,1,0); mb.Position=UDim2.new(xs*(i-1),(i==1 and 0 or 2),0,0)
        mb.BackgroundColor3=C.btn; mb.BorderSizePixel=0
        mb.Font=Enum.Font.GothamSemibold; mb.TextSize=12
        mb.TextColor3=C.textDim; mb.Text=mName
        Instance.new("UICorner",mb).CornerRadius=UDim.new(0,7)
        table.insert(btns,mb)
        mb.MouseButton1Click:Connect(function()
            onSelect(string.lower(mName)); updateActive(mName)
        end)
    end
    updateActive(default)
    return row
end

-- ════════════════════════════════════════════════════
-- HOME TAB
-- ════════════════════════════════════════════════════
local homePage=pages["HomeTab"]

-- Greeting bubble
local bubbleRow=Instance.new("Frame",homePage)
bubbleRow.Size=UDim2.new(1,0,0,92); bubbleRow.BackgroundTransparency=1

local bIcon=Instance.new("ImageLabel",bubbleRow)
bIcon.Size=UDim2.new(0,48,0,48); bIcon.Position=UDim2.new(0,4,0.5,-24)
bIcon.BackgroundColor3=Color3.fromRGB(18,18,20); bIcon.BorderSizePixel=0
bIcon.ScaleType=Enum.ScaleType.Fit; bIcon.Image="rbxassetid://97128823316544"
Instance.new("UICorner",bIcon).CornerRadius=UDim.new(1,0)
local biStr=Instance.new("UIStroke",bIcon); biStr.Color=C.border; biStr.Thickness=1.5; biStr.Transparency=0.45

local bTail=Instance.new("Frame",bubbleRow)
bTail.Size=UDim2.new(0,11,0,11); bTail.Position=UDim2.new(0,57,0.5,-5)
bTail.Rotation=45; bTail.BackgroundColor3=Color3.fromRGB(22,22,26); bTail.BorderSizePixel=0; bTail.ZIndex=1

local bBody=Instance.new("Frame",bubbleRow)
bBody.Size=UDim2.new(1,-66,0,78); bBody.Position=UDim2.new(0,63,0.5,-39)
bBody.BackgroundColor3=Color3.fromRGB(22,22,26); bBody.BorderSizePixel=0; bBody.ZIndex=2
Instance.new("UICorner",bBody).CornerRadius=UDim.new(0,11)
local bbStr=Instance.new("UIStroke",bBody); bbStr.Color=C.border; bbStr.Thickness=1; bbStr.Transparency=0.55
local bbG=Instance.new("TextLabel",bBody)
bbG.Size=UDim2.new(1,-14,0,26); bbG.Position=UDim2.new(0,10,0,10)
bbG.BackgroundTransparency=1; bbG.Font=Enum.Font.GothamBold; bbG.TextSize=15
bbG.TextColor3=C.text; bbG.TextXAlignment=Enum.TextXAlignment.Left
bbG.Text="Hey "..player.DisplayName.."!"; bbG.ZIndex=3
local bbM=Instance.new("TextLabel",bBody)
bbM.Size=UDim2.new(1,-14,0,30); bbM.Position=UDim2.new(0,10,0,34)
bbM.BackgroundTransparency=1; bbM.Font=Enum.Font.Gotham; bbM.TextSize=12
bbM.TextColor3=C.textDim; bbM.TextXAlignment=Enum.TextXAlignment.Left
bbM.TextYAlignment=Enum.TextYAlignment.Top; bbM.TextWrapped=true
bbM.Text="Welcome to VanillaHub v1.1.0 | LT2"; bbM.ZIndex=3

-- Stats grid
local statsContainer=Instance.new("Frame",homePage)
statsContainer.Size=UDim2.new(1,0,0,0); statsContainer.BackgroundTransparency=1
statsContainer.AutomaticSize=Enum.AutomaticSize.Y
local gridLayout=Instance.new("UIGridLayout",statsContainer)
gridLayout.CellSize=UDim2.new(0,142,0,40); gridLayout.CellPadding=UDim2.new(0,8,0,8)
gridLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center; gridLayout.SortOrder=Enum.SortOrder.LayoutOrder

local function makeStatBox(text,col)
    local box=Instance.new("Frame",statsContainer)
    box.BackgroundColor3=C.card; box.BorderSizePixel=0
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,8)
    local lbl=Instance.new("TextLabel",box)
    lbl.Size=UDim2.new(1,-8,1,-4); lbl.Position=UDim2.new(0,4,0,2)
    lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.Gotham; lbl.TextSize=12
    lbl.TextColor3=col or C.text; lbl.Text=text; lbl.TextWrapped=true; lbl.TextXAlignment=Enum.TextXAlignment.Center
    return lbl
end

local pingLabel   = makeStatBox("Ping: …")
local lagLabel    = makeStatBox("Lag: —", C.textDim)
local regionLabel = makeStatBox("Region: …", C.textDim)
makeStatBox("Age: "..player.AccountAge.."d")
local execLabel   = makeStatBox("Executor: …", C.textDim)

-- Rejoin
local rejoinBtn=Instance.new("TextButton",statsContainer)
rejoinBtn.Size=UDim2.new(0,142,0,40); rejoinBtn.BackgroundColor3=C.btn; rejoinBtn.BorderSizePixel=0
rejoinBtn.Font=Enum.Font.Gotham; rejoinBtn.TextSize=13; rejoinBtn.TextColor3=C.text; rejoinBtn.Text="Rejoin"
Instance.new("UICorner",rejoinBtn).CornerRadius=UDim.new(0,8)
rejoinBtn.MouseEnter:Connect(function() TweenService:Create(rejoinBtn,TweenInfo.new(0.15),{BackgroundColor3=C.btnHov}):Play() end)
rejoinBtn.MouseLeave:Connect(function() TweenService:Create(rejoinBtn,TweenInfo.new(0.15),{BackgroundColor3=C.btn}):Play() end)
rejoinBtn.MouseButton1Click:Connect(function() pcall(function() TeleportService:Teleport(game.PlaceId,player) end) end)

-- Executor detection (deferred so executor globals are settled)
task.spawn(function()
    task.wait(0.5)
    local name=detectExecutor()
    execLabel.Text="Exec: "..name
end)

-- Region detection (deferred)
task.spawn(function()
    task.wait(2)
    regionLabel.Text="Region: "..detectRegion()
end)

-- Ping updater every heartbeat
local lastPing=0
registerConn(RunService.Heartbeat:Connect(function()
    local ok,p=pcall(function()
        return math.round(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
    end)
    if ok then lastPing=p; pingLabel.Text="Ping: "..p.." ms" else pingLabel.Text="Ping: N/A" end
end))

-- Lag + region refreshed every 5 seconds
task.spawn(function()
    local tick5=0
    while gui and gui.Parent do
        task.wait(5)
        if not (gui and gui.Parent) then break end
        local ok,p=pcall(function()
            return math.round(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        if ok then
            local lag=p>250
            lagLabel.Text=lag and "Lag: YES ⚠" or "Lag: No"
            lagLabel.TextColor3=lag and Color3.fromRGB(215,75,75) or Color3.fromRGB(75,185,95)
        end
        tick5=tick5+5
        if tick5>=30 then
            tick5=0
            task.spawn(function() regionLabel.Text="Region: "..detectRegion() end)
        end
    end
end)

-- ════════════════════════════════════════════════════
-- TELEPORT TAB
-- ════════════════════════════════════════════════════
local teleportPage=pages["TeleportTab"]
local tpHdr=Instance.new("TextLabel",teleportPage)
tpHdr.Size=UDim2.new(1,0,0,22); tpHdr.BackgroundTransparency=1
tpHdr.Font=Enum.Font.GothamBold; tpHdr.TextSize=10; tpHdr.TextColor3=C.textDim
tpHdr.TextXAlignment=Enum.TextXAlignment.Left; tpHdr.Text="  QUICK TELEPORT"

local locations={
    {name="Spawn",x=172,y=3,z=74},{name="The Den",x=323,y=41.8,z=1930},
    {name="LightHouse",x=1464.8,y=355.25,z=3257.2},{name="Safari",x=111.85,y=11,z=-998.8},
    {name="Bridge",x=112.31,y=11,z=-782.36},{name="Bob's Shack",x=260,y=8.4,z=-2542},
    {name="EndTimesCave",x=113,y=-213,z=-951},{name="The Swamp",x=-1209,y=132.32,z=-801},
    {name="The Cabin",x=1244,y=63.6,z=2306},{name="Volcano",x=-1585,y=622.8,z=1140},
    {name="Boxed Cars",x=509,y=3.2,z=-1463},{name="Tiaga Peak",x=1560,y=410.32,z=3274},
    {name="Land Store",x=258,y=3.2,z=-99},{name="Link's Logic",x=4605,y=3,z=-727},
    {name="Palm Island",x=2549,y=-5.9,z=-42},{name="Palm Island 2",x=1960,y=-5.9,z=-1501},
    {name="Palm Island 3",x=4344,y=-5.9,z=-1813},{name="Fine Art Shop",x=5207,y=-166.2,z=719},
    {name="SnowGlow Biome",x=-1086.85,y=-5.9,z=-945.32},{name="Cave",x=3581,y=-179.54,z=430},
    {name="Shrine Of Sight",x=-1600,y=195.4,z=919},{name="Fancy Furnishings",x=491,y=3.2,z=-1720},
    {name="Docks",x=1114,y=-1.2,z=-197},{name="Strange Man",x=1061,y=16.8,z=1131},
    {name="Wood Dropoff",x=323.41,y=-2.8,z=134.73},{name="Snow Biome",x=889.96,y=59.8,z=1195.55},
    {name="Wood RU's",x=265,y=3.2,z=57},{name="Green Box",x=-1668.05,y=349.6,z=1475.39},
    {name="Cherry Meadow",x=220.9,y=59.8,z=1305.8},{name="Bird Cave",x=4813.1,y=17.7,z=-978.8},
}
for _,loc in ipairs(locations) do
    local btn=Instance.new("TextButton",teleportPage)
    btn.Size=UDim2.new(1,0,0,34); btn.BackgroundColor3=C.btn; btn.BorderSizePixel=0
    btn.Font=Enum.Font.GothamSemibold; btn.TextSize=13; btn.TextColor3=C.text; btn.Text=loc.name
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)
    btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=C.btnHov,TextColor3=Color3.fromRGB(255,255,255)}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=C.btn,TextColor3=C.text}):Play() end)
    btn.MouseButton1Click:Connect(function()
        local char=player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame=CFrame.new(loc.x,loc.y+3,loc.z)
        end
    end)
end

-- ════════════════════════════════════════════════════
-- SHARED ITEM / DUPE TELEPORT STATE
-- ════════════════════════════════════════════════════
local tpCircle    = nil
local tpItemSpeed = 0.3

local function isnetworkowner(part) return part.ReceiveAge==0 end

local function selectPart(part)
    if not (part and part.Parent) then return end
    if part:FindFirstChild("Selection") then return end
    local sb=Instance.new("SelectionBox",part)
    sb.Name="Selection"; sb.Adornee=part; sb.SurfaceTransparency=0.5; sb.LineThickness=0.09
    sb.SurfaceColor3=Color3.fromRGB(0,0,0); sb.Color3=Color3.fromRGB(0,172,240)
end

local function deselectPart(part)
    if not part then return end
    local s=part:FindFirstChild("Selection"); if s then s:Destroy() end
end

local function deselectAll()
    for _,v in pairs(workspace.PlayerModels:GetChildren()) do
        if v:FindFirstChild("Main") and v.Main:FindFirstChild("Selection") then v.Main.Selection:Destroy() end
        if v:FindFirstChild("WoodSection") and v.WoodSection:FindFirstChild("Selection") then v.WoodSection.Selection:Destroy() end
    end
end
table.insert(cleanupTasks, deselectAll)

local function getSelectedParts()
    local parts={}
    for _,v in next,workspace.PlayerModels:GetDescendants() do
        if v.Name=="Selection" then
            local part=v.Parent
            if part and part.Parent then table.insert(parts,part) end
        end
    end
    return parts
end

local function getItemTypeName(part)
    local m=part.Parent; if not m then return "?" end
    local iv=m:FindFirstChild("ItemName")
    return iv and iv.Value or m.Name
end

local function shuffleNoConsecutive(t)
    for i=#t,2,-1 do local j=math.random(i); t[i],t[j]=t[j],t[i] end
    for i=2,#t do
        if getItemTypeName(t[i])==getItemTypeName(t[i-1]) then
            for j=i+1,#t do
                if getItemTypeName(t[j])~=getItemTypeName(t[i-1]) then
                    t[i],t[j]=t[j],t[i]; break
                end
            end
        end
    end
    return t
end

local function sortByGroup(t)
    table.sort(t,function(a,b) return getItemTypeName(a)<getItemTypeName(b) end); return t
end

-- Core teleport runner — takes a prebuilt list, a stop flag table {v=bool}, and callback
local function runItemTeleport(parts, destCF, stopFlag, onDone)
    local OldPos=player.Character
        and player.Character:FindFirstChild("HumanoidRootPart")
        and player.Character.HumanoidRootPart.CFrame
    task.spawn(function()
        for _,part in ipairs(parts) do
            if stopFlag.v then break end
            if not (part and part.Parent) then continue end
            local char=player.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame=CFrame.new(part.CFrame.p)*CFrame.new(5,0,0) end
            task.wait(tpItemSpeed)
            if stopFlag.v then break end
            pcall(function()
                if not part.Parent.PrimaryPart then part.Parent.PrimaryPart=part end
                local dragger=ReplicatedStorage:FindFirstChild("Interaction")
                    and ReplicatedStorage.Interaction:FindFirstChild("ClientIsDragging")
                local timeout=0
                while not isnetworkowner(part) and timeout<3 do
                    if dragger then dragger:FireServer(part.Parent) end
                    task.wait(0.05); timeout=timeout+0.05
                end
                if dragger then dragger:FireServer(part.Parent) end
                part:PivotTo(destCF)
            end)
            task.wait(tpItemSpeed)
        end
        if OldPos and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame=OldPos
        end
        if onDone then onDone() end
    end)
end

-- Lasso overlay
local Camera=workspace.CurrentCamera
local lassoFrame=Instance.new("Frame",gui)
lassoFrame.Name="VHLassoRect"; lassoFrame.BackgroundColor3=Color3.fromRGB(80,130,200)
lassoFrame.BackgroundTransparency=0.84; lassoFrame.BorderSizePixel=0
lassoFrame.Visible=false; lassoFrame.ZIndex=20
local lassoStroke=Instance.new("UIStroke",lassoFrame)
lassoStroke.Color=Color3.fromRGB(120,170,255); lassoStroke.Thickness=1.5

local function is_in_frame(sp,frame)
    local x1,y1=frame.AbsolutePosition.X,frame.AbsolutePosition.Y
    local x2,y2=x1+frame.AbsoluteSize.X,y1+frame.AbsoluteSize.Y
    return sp.X>=math.min(x1,x2) and sp.X<=math.max(x1,x2)
       and sp.Y>=math.min(y1,y2) and sp.Y<=math.max(y1,y2)
end

-- ════════════════════════════════════════════════════
-- ITEM TAB
-- ════════════════════════════════════════════════════
local itemPage=pages["ItemTab"]
do local l=itemPage:FindFirstChildOfClass("UIListLayout"); if l then l.Padding=UDim.new(0,8) end end

local clickSelectEnabled=false
local lassoEnabled=false
local groupSelectEnabled=false
local itemTpMode="normal"
local itemTpActive=false
local itemStopFlag={v=false}
local sellTpActive=false
local sellStopFlag={v=false}

local function trySelect(target)
    if not target then return end
    local function doToggle(part)
        if part:FindFirstChild("Selection") then deselectPart(part) else selectPart(part) end
    end
    local par=target.Parent; if not (par and par:FindFirstChild("Owner")) then return end
    if par:FindFirstChild("Main") and (target==par.Main or target:IsDescendantOf(par.Main)) then doToggle(par.Main); return end
    if par:FindFirstChild("WoodSection") and (target==par.WoodSection or target:IsDescendantOf(par.WoodSection)) then doToggle(par.WoodSection); return end
    local model=target:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChild("Owner") then
        if model:FindFirstChild("Main") then doToggle(model.Main)
        elseif model:FindFirstChild("WoodSection") then doToggle(model.WoodSection) end
    end
end

local function tryGroupSelect(target)
    if not target then return end
    local model=target.Parent
    if not (model and model:FindFirstChild("Owner")) then model=target:FindFirstAncestorOfClass("Model") end
    if not (model and model:FindFirstChild("Owner")) then return end
    local iv=model:FindFirstChild("ItemName"); local groupName=iv and iv.Value or model.Name
    for _,v in pairs(workspace.PlayerModels:GetChildren()) do
        if v:FindFirstChild("Owner") then
            local viv=v:FindFirstChild("ItemName"); local vName=viv and viv.Value or v.Name
            if vName==groupName then
                if v:FindFirstChild("Main") then selectPart(v.Main) end
                if v:FindFirstChild("WoodSection") then selectPart(v.WoodSection) end
            end
        end
    end
end

-- Lasso input
registerConn(UserInputService.InputBegan:Connect(function(input)
    if not lassoEnabled then return end
    if input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    lassoFrame.Visible=true
    local startX,startY=mouse.X,mouse.Y
    lassoFrame.Position=UDim2.new(0,startX,0,startY); lassoFrame.Size=UDim2.new(0,0,0,0)
    while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
        RunService.RenderStepped:Wait()
        local dx=mouse.X-startX; local dy=mouse.Y-startY
        lassoFrame.Position=UDim2.new(0,math.min(startX,mouse.X),0,math.min(startY,mouse.Y))
        lassoFrame.Size=UDim2.new(0,math.abs(dx),0,math.abs(dy))
        for _,v in pairs(workspace.PlayerModels:GetChildren()) do
            if v:FindFirstChild("Main") then
                local sp,vis=Camera:WorldToScreenPoint(v.Main.CFrame.p)
                if vis and is_in_frame(sp,lassoFrame) then selectPart(v.Main) end
            end
            if v:FindFirstChild("WoodSection") then
                local sp,vis=Camera:WorldToScreenPoint(v.WoodSection.CFrame.p)
                if vis and is_in_frame(sp,lassoFrame) then selectPart(v.WoodSection) end
            end
        end
    end
    lassoFrame.Visible=false
end))

registerConn(mouse.Button1Up:Connect(function()
    if lassoEnabled then return end
    if clickSelectEnabled then trySelect(mouse.Target)
    elseif groupSelectEnabled then tryGroupSelect(mouse.Target) end
end))

-- LAYOUT
makeSectionLabel(itemPage,"Selection Mode")
makeToggle(itemPage,"Click Select",false,function(v) clickSelectEnabled=v; if v then lassoEnabled=false; groupSelectEnabled=false end end)
makeToggle(itemPage,"Lasso Tool",false,function(v) lassoEnabled=v; if v then clickSelectEnabled=false; groupSelectEnabled=false end end)
makeToggle(itemPage,"Group Select",false,function(v) groupSelectEnabled=v; if v then clickSelectEnabled=false; lassoEnabled=false end end)

makeSep(itemPage)
makeSectionLabel(itemPage,"Teleport Mode")
makeModeRow(itemPage,{"Normal","Random","Group"},"Normal",function(mode) itemTpMode=mode end)

local iModeHint=Instance.new("TextLabel",itemPage)
iModeHint.Size=UDim2.new(1,0,0,28); iModeHint.BackgroundColor3=C.card; iModeHint.BorderSizePixel=0
iModeHint.Font=Enum.Font.Gotham; iModeHint.TextSize=11; iModeHint.TextColor3=C.textHint
iModeHint.TextWrapped=true; iModeHint.TextXAlignment=Enum.TextXAlignment.Left
iModeHint.Text="  Normal: in order  |  Random: shuffled, no same-type consecutive  |  Group: by type"
Instance.new("UICorner",iModeHint).CornerRadius=UDim.new(0,8)
Instance.new("UIPadding",iModeHint).PaddingLeft=UDim.new(0,4)

makeSep(itemPage)
makeSectionLabel(itemPage,"Teleport Destination")

local iDestRow=Instance.new("Frame",itemPage)
iDestRow.Size=UDim2.new(1,0,0,34); iDestRow.BackgroundTransparency=1
local iSetDestBtn=Instance.new("TextButton",iDestRow)
iSetDestBtn.Size=UDim2.new(0.5,-4,1,0); iSetDestBtn.BackgroundColor3=C.btn; iSetDestBtn.BorderSizePixel=0
iSetDestBtn.Font=Enum.Font.GothamSemibold; iSetDestBtn.TextSize=12; iSetDestBtn.TextColor3=C.text; iSetDestBtn.Text="Set Destination"
Instance.new("UICorner",iSetDestBtn).CornerRadius=UDim.new(0,8)
local iRemDestBtn=Instance.new("TextButton",iDestRow)
iRemDestBtn.Size=UDim2.new(0.5,-4,1,0); iRemDestBtn.Position=UDim2.new(0.5,4,0,0)
iRemDestBtn.BackgroundColor3=C.btn; iRemDestBtn.BorderSizePixel=0
iRemDestBtn.Font=Enum.Font.GothamSemibold; iRemDestBtn.TextSize=12; iRemDestBtn.TextColor3=C.text; iRemDestBtn.Text="Remove"
Instance.new("UICorner",iRemDestBtn).CornerRadius=UDim.new(0,8)
for _,b in {iSetDestBtn,iRemDestBtn} do
    b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=C.btnHov}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=C.btn}):Play() end)
end
iSetDestBtn.MouseButton1Click:Connect(function()
    if tpCircle then tpCircle:Destroy() end
    tpCircle=Instance.new("Part"); tpCircle.Name="VanillaHubTpCircle"; tpCircle.Shape=Enum.PartType.Ball
    tpCircle.Size=Vector3.new(3,3,3); tpCircle.Material=Enum.Material.SmoothPlastic
    tpCircle.Color=Color3.fromRGB(105,105,115); tpCircle.Anchored=true; tpCircle.CanCollide=false
    local char=player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then tpCircle.Position=char.HumanoidRootPart.Position end
    tpCircle.Parent=workspace
end)
iRemDestBtn.MouseButton1Click:Connect(function()
    if tpCircle then tpCircle:Destroy(); tpCircle=nil end
end)
table.insert(cleanupTasks,function() if tpCircle and tpCircle.Parent then tpCircle:Destroy(); tpCircle=nil end end)

makeSep(itemPage)
makeSectionLabel(itemPage,"Teleport Speed")
makeSlider(itemPage,"Delay per item (×0.1s)",1,20,3,function(v) tpItemSpeed=v/10 end)

makeSep(itemPage)
makeSectionLabel(itemPage,"Actions")

-- Teleport Selected (with stop)
local itemTpBtn=makeButton(itemPage,"Teleport Selected")
itemTpBtn.MouseButton1Click:Connect(function()
    if itemTpActive then itemStopFlag.v=true; return end
    if not tpCircle then return end
    local parts=getSelectedParts(); if #parts==0 then return end
    if itemTpMode=="random" then shuffleNoConsecutive(parts)
    elseif itemTpMode=="group" then sortByGroup(parts) end
    itemTpActive=true; itemStopFlag={v=false}
    itemTpBtn.Text="Stop Teleporting"
    TweenService:Create(itemTpBtn,TweenInfo.new(0.2),{BackgroundColor3=C.red}):Play()
    runItemTeleport(parts,tpCircle.CFrame,itemStopFlag,function()
        itemTpActive=false; itemTpBtn.Text="Teleport Selected"
        TweenService:Create(itemTpBtn,TweenInfo.new(0.2),{BackgroundColor3=C.btn}):Play()
    end)
end)

-- Sell Selected (with stop)
local sellBtn=makeButton(itemPage,"Sell Selected (Dropoff)")
sellBtn.MouseButton1Click:Connect(function()
    if sellTpActive then sellStopFlag.v=true; return end
    local parts=getSelectedParts(); if #parts==0 then return end
    if itemTpMode=="random" then shuffleNoConsecutive(parts)
    elseif itemTpMode=="group" then sortByGroup(parts) end
    sellTpActive=true; sellStopFlag={v=false}
    sellBtn.Text="Stop Selling"
    TweenService:Create(sellBtn,TweenInfo.new(0.2),{BackgroundColor3=C.red}):Play()
    runItemTeleport(parts,CFrame.new(314.776,-1.593,87.807),sellStopFlag,function()
        sellTpActive=false; sellBtn.Text="Sell Selected (Dropoff)"
        TweenService:Create(sellBtn,TweenInfo.new(0.2),{BackgroundColor3=C.btn}):Play()
    end)
end)

makeButton(itemPage,"Deselect All",function() deselectAll() end)

-- ════════════════════════════════════════════════════
-- DUPE TAB
-- Shares tpCircle, tpItemSpeed, teleport helpers
-- ════════════════════════════════════════════════════
local dupePage=pages["DupeTab"]
do local l=dupePage:FindFirstChildOfClass("UIListLayout"); if l then l.Padding=UDim.new(0,8) end end

local dupeTpMode="normal"
local dupeTpActive=false
local dupeStopFlag={v=false}

makeSectionLabel(dupePage,"Teleport Mode")
makeModeRow(dupePage,{"Normal","Random","Group"},"Normal",function(mode) dupeTpMode=mode end)

local dModeHint=Instance.new("TextLabel",dupePage)
dModeHint.Size=UDim2.new(1,0,0,28); dModeHint.BackgroundColor3=C.card; dModeHint.BorderSizePixel=0
dModeHint.Font=Enum.Font.Gotham; dModeHint.TextSize=11; dModeHint.TextColor3=C.textHint
dModeHint.TextWrapped=true; dModeHint.TextXAlignment=Enum.TextXAlignment.Left
dModeHint.Text="  Normal: in order  |  Random: shuffled, no same-type consecutive  |  Group: by type"
Instance.new("UICorner",dModeHint).CornerRadius=UDim.new(0,8)
Instance.new("UIPadding",dModeHint).PaddingLeft=UDim.new(0,4)

makeSep(dupePage)
makeSectionLabel(dupePage,"Destination")

local dDestRow=Instance.new("Frame",dupePage)
dDestRow.Size=UDim2.new(1,0,0,34); dDestRow.BackgroundTransparency=1
local dSetBtn=Instance.new("TextButton",dDestRow)
dSetBtn.Size=UDim2.new(0.5,-4,1,0); dSetBtn.BackgroundColor3=C.btn; dSetBtn.BorderSizePixel=0
dSetBtn.Font=Enum.Font.GothamSemibold; dSetBtn.TextSize=12; dSetBtn.TextColor3=C.text; dSetBtn.Text="Set Destination"
Instance.new("UICorner",dSetBtn).CornerRadius=UDim.new(0,8)
local dRemBtn=Instance.new("TextButton",dDestRow)
dRemBtn.Size=UDim2.new(0.5,-4,1,0); dRemBtn.Position=UDim2.new(0.5,4,0,0)
dRemBtn.BackgroundColor3=C.btn; dRemBtn.BorderSizePixel=0
dRemBtn.Font=Enum.Font.GothamSemibold; dRemBtn.TextSize=12; dRemBtn.TextColor3=C.text; dRemBtn.Text="Remove"
Instance.new("UICorner",dRemBtn).CornerRadius=UDim.new(0,8)
for _,b in {dSetBtn,dRemBtn} do
    b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=C.btnHov}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=C.btn}):Play() end)
end
dSetBtn.MouseButton1Click:Connect(function()
    if tpCircle then tpCircle:Destroy() end
    tpCircle=Instance.new("Part"); tpCircle.Name="VanillaHubTpCircle"; tpCircle.Shape=Enum.PartType.Ball
    tpCircle.Size=Vector3.new(3,3,3); tpCircle.Material=Enum.Material.SmoothPlastic
    tpCircle.Color=Color3.fromRGB(105,105,115); tpCircle.Anchored=true; tpCircle.CanCollide=false
    local char=player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then tpCircle.Position=char.HumanoidRootPart.Position end
    tpCircle.Parent=workspace
end)
dRemBtn.MouseButton1Click:Connect(function()
    if tpCircle then tpCircle:Destroy(); tpCircle=nil end
end)

makeSep(dupePage)
makeSectionLabel(dupePage,"Actions")

local dupeTpBtn=makeButton(dupePage,"Teleport Selected")
dupeTpBtn.MouseButton1Click:Connect(function()
    if dupeTpActive then dupeStopFlag.v=true; return end
    if not tpCircle then return end
    local parts=getSelectedParts(); if #parts==0 then return end
    if dupeTpMode=="random" then shuffleNoConsecutive(parts)
    elseif dupeTpMode=="group" then sortByGroup(parts) end
    dupeTpActive=true; dupeStopFlag={v=false}
    dupeTpBtn.Text="Stop Teleporting"
    TweenService:Create(dupeTpBtn,TweenInfo.new(0.2),{BackgroundColor3=C.red}):Play()
    runItemTeleport(parts,tpCircle.CFrame,dupeStopFlag,function()
        dupeTpActive=false; dupeTpBtn.Text="Teleport Selected"
        TweenService:Create(dupeTpBtn,TweenInfo.new(0.2),{BackgroundColor3=C.btn}):Play()
    end)
end)

makeButton(dupePage,"Deselect All",function() deselectAll() end)

-- ════════════════════════════════════════════════════
-- PLAYER TAB
-- ════════════════════════════════════════════════════
local playerPage=pages["PlayerTab"]

local savedWalkSpeed=16
local savedJumpPower=50

-- Keep stats applied continuously
registerConn(RunService.Heartbeat:Connect(function()
    local char=player.Character; if not char then return end
    local hum=char:FindFirstChild("Humanoid"); if not hum then return end
    if hum.WalkSpeed~=savedWalkSpeed then hum.WalkSpeed=savedWalkSpeed end
    if hum.JumpPower ~=savedJumpPower  then hum.JumpPower =savedJumpPower  end
end))
table.insert(cleanupTasks,function()
    local char=player.Character
    if char then local hum=char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed=16; hum.JumpPower=50 end end
end)

-- ── FLY SYSTEM ────────────────────────────────────────
-- All fly variables declared BEFORE any UI or callbacks reference them
local flySpeed     = 100
local flyEnabled   = true    -- master switch (ON by default)
local isFlyEnabled = false   -- currently flying?
local flyBV, flyBG, flyConn
local currentFlyKey = Enum.KeyCode.Q

local function stopFly()
    isFlyEnabled = false
    if flyConn then
        pcall(function() flyConn:Disconnect() end)
        -- Remove from activeConns so we don't accumulate dead connections
        for i = #activeConns, 1, -1 do
            if activeConns[i] == flyConn then table.remove(activeConns, i) end
        end
        flyConn = nil
    end
    if flyBV and flyBV.Parent then flyBV:Destroy(); flyBV=nil end
    if flyBG and flyBG.Parent then flyBG:Destroy(); flyBG=nil end
    local char=player.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.PlatformStand=false end
end

local function startFly()
    if not flyEnabled then return end   -- hard gate: does nothing when switch is OFF
    stopFly()
    local char=player.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart")
    local hum =char:FindFirstChild("Humanoid")
    if not (root and hum) then return end
    isFlyEnabled=true
    hum.PlatformStand=true
    flyBV=Instance.new("BodyVelocity",root)
    flyBV.MaxForce=Vector3.new(1e5,1e5,1e5); flyBV.Velocity=Vector3.zero
    flyBG=Instance.new("BodyGyro",root)
    flyBG.MaxTorque=Vector3.new(1e5,1e5,1e5); flyBG.P=1e4; flyBG.D=100
    -- Register via registerConn so onExit always disconnects it
    flyConn = registerConn(RunService.Heartbeat:Connect(function()
        if not isFlyEnabled then return end  -- bail if stopped
        if not (flyBV and flyBV.Parent and flyBG and flyBG.Parent) then return end
        local ch=player.Character
        local h=ch and ch:FindFirstChild("Humanoid")
        local r=ch and ch:FindFirstChild("HumanoidRootPart")
        if not (h and r) then return end
        local cf=workspace.CurrentCamera.CFrame
        local dir=Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W)         then dir=dir+cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)         then dir=dir-cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)         then dir=dir-cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)         then dir=dir+cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir=dir+Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir=dir-Vector3.new(0,1,0) end
        h.PlatformStand=true
        flyBV.MaxForce=Vector3.new(1e5,1e5,1e5)
        flyBV.Velocity=dir.Magnitude>0 and dir.Unit*flySpeed or Vector3.zero
        flyBG.CFrame=cf
    end))
end

-- Register stopFly with cleanup so it runs on exit/re-execute
table.insert(cleanupTasks, stopFly)

-- ── PLAYER TAB UI ─────────────────────────────────────

makeSectionLabel(playerPage,"Movement")
makeSlider(playerPage,"WalkSpeed",16,150,16,function(v)
    savedWalkSpeed=v; local c=player.Character
    if c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed=v end
end)
makeSlider(playerPage,"JumpPower",50,300,50,function(v)
    savedJumpPower=v; local c=player.Character
    if c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower=v end
end)
makeSlider(playerPage,"Fly Speed",100,500,100,function(v) flySpeed=v end)

-- Fly keybind row
local flyKeyRow=Instance.new("Frame",playerPage)
flyKeyRow.Size=UDim2.new(1,0,0,36); flyKeyRow.BackgroundColor3=C.card; flyKeyRow.BorderSizePixel=0
Instance.new("UICorner",flyKeyRow).CornerRadius=UDim.new(0,8)
local flyKeyLbl=Instance.new("TextLabel",flyKeyRow)
flyKeyLbl.Size=UDim2.new(0.6,0,1,0); flyKeyLbl.Position=UDim2.new(0,12,0,0)
flyKeyLbl.BackgroundTransparency=1; flyKeyLbl.Font=Enum.Font.GothamSemibold; flyKeyLbl.TextSize=13
flyKeyLbl.TextColor3=C.text; flyKeyLbl.TextXAlignment=Enum.TextXAlignment.Left; flyKeyLbl.Text="Fly Keybind"
local flyKeyBtn=Instance.new("TextButton",flyKeyRow)
flyKeyBtn.Size=UDim2.new(0,56,0,24); flyKeyBtn.Position=UDim2.new(1,-64,0.5,-12)
flyKeyBtn.BackgroundColor3=C.btn; flyKeyBtn.Font=Enum.Font.GothamSemibold
flyKeyBtn.TextSize=12; flyKeyBtn.TextColor3=C.text; flyKeyBtn.Text="Q"; flyKeyBtn.BorderSizePixel=0
Instance.new("UICorner",flyKeyBtn).CornerRadius=UDim.new(0,6)
flyKeyBtn.MouseEnter:Connect(function() TweenService:Create(flyKeyBtn,TweenInfo.new(0.15),{BackgroundColor3=C.btnHov}):Play() end)
flyKeyBtn.MouseLeave:Connect(function() TweenService:Create(flyKeyBtn,TweenInfo.new(0.15),{BackgroundColor3=C.btn}):Play() end)

local waitingForFlyKey=false
flyKeyBtn.MouseButton1Click:Connect(function()
    if waitingForFlyKey then return end
    waitingForFlyKey=true
    flyKeyBtn.Text="..."; flyKeyBtn.BackgroundColor3=C.green
end)

-- Fly ON/OFF toggle (ON by default — green, circle right)
local flyToggleRow=Instance.new("Frame",playerPage)
flyToggleRow.Size=UDim2.new(1,0,0,36); flyToggleRow.BackgroundColor3=C.card; flyToggleRow.BorderSizePixel=0
Instance.new("UICorner",flyToggleRow).CornerRadius=UDim.new(0,8)
local flyToggleLbl=Instance.new("TextLabel",flyToggleRow)
flyToggleLbl.Size=UDim2.new(1,-54,1,0); flyToggleLbl.Position=UDim2.new(0,12,0,0)
flyToggleLbl.BackgroundTransparency=1; flyToggleLbl.Font=Enum.Font.GothamSemibold; flyToggleLbl.TextSize=13
flyToggleLbl.TextColor3=C.text; flyToggleLbl.TextXAlignment=Enum.TextXAlignment.Left; flyToggleLbl.Text="Fly"
local flyToggleTb=Instance.new("TextButton",flyToggleRow)
flyToggleTb.Size=UDim2.new(0,36,0,20); flyToggleTb.Position=UDim2.new(1,-46,0.5,-10)
flyToggleTb.BackgroundColor3=C.toggleOn   -- green = ON by default
flyToggleTb.Text=""; flyToggleTb.BorderSizePixel=0
Instance.new("UICorner",flyToggleTb).CornerRadius=UDim.new(1,0)
local flyToggleCircle=Instance.new("Frame",flyToggleTb)
flyToggleCircle.Size=UDim2.new(0,14,0,14)
flyToggleCircle.Position=UDim2.new(0,20,0.5,-7)   -- right = ON
flyToggleCircle.BackgroundColor3=Color3.fromRGB(255,255,255); flyToggleCircle.BorderSizePixel=0
Instance.new("UICorner",flyToggleCircle).CornerRadius=UDim.new(1,0)
flyToggleTb.MouseButton1Click:Connect(function()
    flyEnabled=not flyEnabled
    TweenService:Create(flyToggleTb,TweenInfo.new(0.2,Enum.EasingStyle.Quint),
        {BackgroundColor3=flyEnabled and C.toggleOn or C.toggleOff}):Play()
    TweenService:Create(flyToggleCircle,TweenInfo.new(0.2,Enum.EasingStyle.Quint),
        {Position=UDim2.new(0,flyEnabled and 20 or 2,0.5,-7)}):Play()
    -- Immediately stop flight if switch toggled off while flying
    if not flyEnabled and isFlyEnabled then stopFly() end
end)

local flyHintLbl=Instance.new("TextLabel",playerPage)
flyHintLbl.Size=UDim2.new(1,0,0,24); flyHintLbl.BackgroundColor3=C.card; flyHintLbl.BorderSizePixel=0
flyHintLbl.Font=Enum.Font.Gotham; flyHintLbl.TextSize=11; flyHintLbl.TextColor3=C.textHint
flyHintLbl.TextXAlignment=Enum.TextXAlignment.Left
flyHintLbl.Text="  Press Fly Key to toggle  —  Fly switch must be ON"
Instance.new("UICorner",flyHintLbl).CornerRadius=UDim.new(0,8)
Instance.new("UIPadding",flyHintLbl).PaddingLeft=UDim.new(0,4)

makeSep(playerPage)
makeSectionLabel(playerPage,"Character")

local noclipEnabled=false; local noclipConn
makeToggle(playerPage,"Noclip",false,function(val)
    noclipEnabled=val
    if val then
        noclipConn=RunService.Stepped:Connect(function()
            if not noclipEnabled then return end
            local char=player.Character; if not char then return end
            for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
        local char=player.Character
        if char then for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end end
    end
end)
table.insert(cleanupTasks,function()
    noclipEnabled=false; if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
end)

local infJumpEnabled=false; local infJumpConn
makeToggle(playerPage,"Inf Jump",false,function(val)
    infJumpEnabled=val
    if val then
        infJumpConn=UserInputService.JumpRequest:Connect(function()
            if not infJumpEnabled then return end
            local char=player.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        if infJumpConn then infJumpConn:Disconnect(); infJumpConn=nil end
    end
end)
table.insert(cleanupTasks,function()
    infJumpEnabled=false; if infJumpConn then infJumpConn:Disconnect(); infJumpConn=nil end
end)

-- ════════════════════════════════════════════════════
-- GLOBAL KEY LISTENER
-- Uses registerConn so it's always cleaned up on exit
-- ════════════════════════════════════════════════════
registerConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- Fly rebind capture
    if waitingForFlyKey then
        if input.UserInputType==Enum.UserInputType.Keyboard then
            currentFlyKey=input.KeyCode
            flyKeyBtn.Text=input.KeyCode.Name
            flyKeyBtn.BackgroundColor3=C.btn
            waitingForFlyKey=false
        end
        return
    end

    -- GUI toggle (ALT)
    if input.KeyCode==currentToggleKey then
        toggleGUI(); return
    end

    -- Fly toggle — ONLY fires when flyEnabled is true
    if input.KeyCode==currentFlyKey and flyEnabled then
        if isFlyEnabled then stopFly() else startFly() end
        return
    end
end))

-- ════════════════════════════════════════════════════
-- SHARED GLOBALS
-- ════════════════════════════════════════════════════
_G.VH = {
    TweenService     = TweenService,
    Players          = Players,
    UserInputService = UserInputService,
    RunService       = RunService,
    TeleportService  = TeleportService,
    Stats            = Stats,
    player           = player,
    cleanupTasks     = cleanupTasks,
    activeConns      = activeConns,
    pages            = pages,
    tabNames         = tabNames,
    C                = C,
    switchTab        = switchTab,
    toggleGUI        = toggleGUI,
    stopFly          = stopFly,
    startFly         = startFly,
    butter           = {running=false,thread=nil},
    isFlyEnabled     = false,
    flyEnabled       = true,
    currentFlyKey    = Enum.KeyCode.Q,
    currentToggleKey = currentToggleKey,
    tpCircle         = nil,
}

_G.VanillaHubCleanup = onExit

print("[VanillaHub v1.1.0] Loaded — LT2")
