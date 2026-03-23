-- ════════════════════════════════════════════════════
-- VANILLA3 — Wood Tab + Settings Tab
-- Full WoodHub logic integrated into VanillaHub theme
-- COMPLETE REWRITE - Fixed all wood cutting and selling
-- ════════════════════════════════════════════════════

if not _G.VH then
    warn("[VanillaHub] Vanilla3: _G.VH not found. Execute Vanilla1 first.")
    return
end

local TweenService      = _G.VH.TweenService
local Players           = _G.VH.Players
local UserInputService  = _G.VH.UserInputService
local RunService        = _G.VH.RunService
local player            = _G.VH.player
local cleanupTasks      = _G.VH.cleanupTasks
local pages             = _G.VH.pages
local tabs              = _G.VH.tabs
local BTN_COLOR         = _G.VH.BTN_COLOR
local BTN_HOVER         = _G.VH.BTN_HOVER
local THEME_TEXT        = _G.VH.THEME_TEXT or Color3.fromRGB(220, 220, 220)
local SEP_COLOR         = _G.VH.SEP_COLOR
local SECTION_TEXT      = _G.VH.SECTION_TEXT
local switchTab         = _G.VH.switchTab
local toggleGUI         = _G.VH.toggleGUI
local stopFly           = _G.VH.stopFly
local startFly          = _G.VH.startFly
local flyKeyBtn         = _G.VH.flyKeyBtn

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ── Key state getters/setters ────────────────────────────────────────────────
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
-- THEME
-- ════════════════════════════════════════════════════
local C = {
    BG         = Color3.fromRGB(10,  10,  10),
    CARD       = Color3.fromRGB(14,  14,  14),
    ROW        = Color3.fromRGB(20,  20,  20),
    BORDER     = Color3.fromRGB(55,  55,  55),
    BORDER_DIM = Color3.fromRGB(40,  40,  40),
    TEXT       = Color3.fromRGB(210, 210, 210),
    TEXT_MID   = Color3.fromRGB(150, 150, 150),
    TEXT_DIM   = Color3.fromRGB(90,  90,  90),
    ACCENT     = Color3.fromRGB(200, 200, 200),
    ACCENT_DIM = Color3.fromRGB(120, 120, 120),
    BTN        = Color3.fromRGB(14,  14,  14),
    BTN_HV     = Color3.fromRGB(32,  32,  32),
    SEP        = Color3.fromRGB(40,  40,  40),
}

-- ════════════════════════════════════════════════════
-- SHARED UI HELPERS
-- ════════════════════════════════════════════════════
local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
end

local function stroke(p, col, thick, trans)
    local s = Instance.new("UIStroke", p)
    s.Color = col or C.BORDER
    s.Thickness = thick or 1
    s.Transparency = trans or 0.4
    return s
end

local function sectionLabel(parent, text)
    local w = Instance.new("Frame", parent)
    w.Size = UDim2.new(1, 0, 0, 22)
    w.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", w)
    lbl.Size = UDim2.new(1, -4, 1, 0)
    lbl.Position = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextColor3 = C.TEXT_DIM
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "  " .. string.upper(text)
    return w
end

local function sepLine(parent)
    local s = Instance.new("Frame", parent)
    s.Size = UDim2.new(1, 0, 0, 1)
    s.BackgroundColor3 = C.SEP
    s.BorderSizePixel = 0
    return s
end

local function makeBtn(parent, text, cb)
    local btn = Instance.new("TextButton", parent)
    btn.Size             = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = C.CARD
    btn.BorderSizePixel  = 0
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.TextColor3       = C.TEXT
    btn.Text             = text
    btn.AutoButtonColor  = false
    corner(btn, 8)
    stroke(btn, C.BORDER, 1, 0.5)
    local pad = Instance.new("UIPadding", btn)
    pad.PaddingLeft = UDim.new(0, 12)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = C.BTN_HV}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = C.CARD}):Play()
    end)
    if cb then btn.MouseButton1Click:Connect(function() task.spawn(cb) end) end
    return btn
end

local function makeToggle(parent, text, default, cb)
    local frame = Instance.new("Frame", parent)
    frame.Size             = UDim2.new(1, 0, 0, 36)
    frame.BackgroundColor3 = C.CARD
    frame.BorderSizePixel  = 0
    corner(frame, 8)
    stroke(frame, C.BORDER, 1, 0.5)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size              = UDim2.new(1, -54, 1, 0)
    lbl.Position          = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text              = text
    lbl.Font              = Enum.Font.GothamSemibold
    lbl.TextSize          = 13
    lbl.TextColor3        = C.TEXT
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    local track = Instance.new("Frame", frame)
    track.Size             = UDim2.new(0, 36, 0, 20)
    track.Position         = UDim2.new(1, -46, 0.5, -10)
    track.BackgroundColor3 = default and SW_ON or SW_OFF
    track.BorderSizePixel  = 0
    corner(track, 10)
    local knob = Instance.new("Frame", track)
    knob.Size             = UDim2.new(0, 14, 0, 14)
    knob.Position         = UDim2.new(0, default and 20 or 2, 0.5, -7)
    knob.BackgroundColor3 = default and SW_KNOB_ON or SW_KNOB_OFF
    knob.BorderSizePixel  = 0
    corner(knob, 7)
    local toggled = default or false
    local clickBtn = Instance.new("TextButton", frame)
    clickBtn.Size              = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text              = ""
    clickBtn.ZIndex            = 5
    clickBtn.MouseButton1Click:Connect(function()
        toggled = not toggled
        TweenService:Create(track, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            BackgroundColor3 = toggled and SW_ON or SW_OFF
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, toggled and 20 or 2, 0.5, -7),
            BackgroundColor3 = toggled and SW_KNOB_ON or SW_KNOB_OFF
        }):Play()
        if cb then task.spawn(cb, toggled) end
    end)
    return frame, function(v)
        toggled = v
        TweenService:Create(track, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            BackgroundColor3 = toggled and SW_ON or SW_OFF
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, toggled and 20 or 2, 0.5, -7),
            BackgroundColor3 = toggled and SW_KNOB_ON or SW_KNOB_OFF
        }):Play()
    end
end

local SW_OFF      = Color3.fromRGB(55, 55, 55)
local SW_ON       = Color3.fromRGB(230, 230, 230)
local SW_KNOB_OFF = Color3.fromRGB(160, 160, 160)
local SW_KNOB_ON  = Color3.fromRGB(30, 30, 30)

local function makeSlider(parent, text, minV, maxV, defV, cb)
    local frame = Instance.new("Frame", parent)
    frame.Size             = UDim2.new(1, 0, 0, 54)
    frame.BackgroundColor3 = C.CARD
    frame.BorderSizePixel  = 0
    corner(frame, 8)
    stroke(frame, C.BORDER, 1, 0.5)
    local topRow = Instance.new("Frame", frame)
    topRow.Size = UDim2.new(1, -16, 0, 22)
    topRow.Position = UDim2.new(0, 8, 0, 7)
    topRow.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", topRow)
    lbl.Size = UDim2.new(0.72, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextColor3 = C.TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = text
    local valLbl = Instance.new("TextLabel", topRow)
    valLbl.Size = UDim2.new(0.28, 0, 1, 0)
    valLbl.Position = UDim2.new(0.72, 0, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 13
    valLbl.TextColor3 = C.ACCENT_DIM
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Text = tostring(defV)
    local track = Instance.new("Frame", frame)
    track.Size             = UDim2.new(1, -16, 0, 5)
    track.Position         = UDim2.new(0, 8, 0, 38)
    track.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    track.BorderSizePixel  = 0
    corner(track, 3)
    local fill = Instance.new("Frame", track)
    fill.Size             = UDim2.new((defV-minV)/(maxV-minV), 0, 1, 0)
    fill.BackgroundColor3 = C.ACCENT_DIM
    fill.BorderSizePixel  = 0
    corner(fill, 3)
    local knob = Instance.new("TextButton", track)
    knob.Size             = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint      = Vector2.new(0.5, 0.5)
    knob.Position         = UDim2.new((defV-minV)/(maxV-minV), 0, 0.5, 0)
    knob.BackgroundColor3 = C.ACCENT
    knob.Text             = ""
    knob.BorderSizePixel  = 0
    corner(knob, 7)
    local ds = false
    local function upd(absX)
        local r = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.round(minV + r * (maxV - minV))
        fill.Size = UDim2.new(r, 0, 1, 0)
        knob.Position = UDim2.new(r, 0, 0.5, 0)
        valLbl.Text = tostring(v)
        if cb then cb(v) end
    end
    knob.MouseButton1Down:Connect(function() ds = true end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then ds = true; upd(i.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if ds and i.UserInputType == Enum.UserInputType.MouseMovement then upd(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then ds = false end
    end)
    return frame
end

-- ════════════════════════════════════════════════════
-- AXE / TREE LOGIC
-- ════════════════════════════════════════════════════

local HitPoints = {
    Beesaxe         = 1.4,
    AxeAmber        = 3.39,
    ManyAxe         = 10.2,
    BasicHatchet    = 0.2,
    Axe1            = 0.55,
    Axe2            = 0.93,
    AxeAlphaTesters = 1.5,
    Rukiryaxe       = 1.68,
    Axe3            = 1.45,
    AxeBetaTesters  = 1.45,
    FireAxe         = 0.6,
    SilverAxe       = 1.6,
    EndTimesAxe     = 1.58,
    AxeChicken      = 0.9,
    CandyCaneAxe    = 0,
    AxeTwitter      = 1.65,
}

local function getTools()
    pcall(function() player.Character.Humanoid:UnequipTools() end)
    local tools = {}
    for _, v in pairs(player.Backpack:GetChildren()) do
        if v.Name ~= "BlueprintTool" and v.Name ~= "Delete" and v.Name ~= "Undo" then
            table.insert(tools, v)
        end
    end
    return tools
end

local function getBestAxe()
    local tools = getTools()
    local bestAxe = nil
    local bestDamage = 0
    
    for _, tool in pairs(tools) do
        if tool:FindFirstChild("ToolName") then
            local damage = HitPoints[tool.ToolName.Value] or 1
            if damage > bestDamage then
                bestDamage = damage
                bestAxe = tool
            end
        end
    end
    
    return bestAxe
end

local function ChopTree(CutEvent, ID, Height, tool)
    local equipped = tool or player.Character:FindFirstChild("Tool")
    if not equipped then return end
    ReplicatedStorage.Interaction.RemoteProxy:FireServer(CutEvent, {
        tool         = equipped,
        faceVector   = Vector3.new(1,0,0),
        height       = Height or 0.3,
        sectionId    = ID or 1,
        hitPoints    = HitPoints[equipped.ToolName.Value] or 1,
        cooldown     = 0.25837870788574,
        cuttingClass = "Axe",
    })
end

local function DragModel(model, targetCFrame)
    if not model or not model.Parent then return end
    local prim = model.PrimaryPart or model:FindFirstChild("WoodSection")
    if not prim then return end
    model.PrimaryPart = prim
    ReplicatedStorage.Interaction.ClientIsDragging:FireServer(model)
    model:SetPrimaryPartCFrame(targetCFrame)
end

local function GetLava()
    local volcano = workspace:FindFirstChild("Region_Volcano")
    if volcano then
        for _, child in pairs(volcano:GetChildren()) do
            if child:FindFirstChild("Lava") then
                return child
            end
        end
    end
    return nil
end

-- ════════════════════════════════════════════════════
-- AUTO LOG CUTTER - Full auto follow and cut
-- ════════════════════════════════════════════════════

local autoCutterActive = false
local autoCutterThread = nil
local sellPosition = CFrame.new(314.76, -0.40, 87.29)

local function CutLogSection(logModel, sectionId, tool)
    local cutEvent = logModel:FindFirstChild("CutEvent")
    if not cutEvent then return false end
    
    ChopTree(cutEvent, sectionId, 0.3, tool)
    return true
end

local function GetNextSection(logModel, currentSectionId)
    for _, child in pairs(logModel:GetChildren()) do
        if child:IsA("BasePart") and child:FindFirstChild("ID") and child.ID.Value == currentSectionId + 1 then
            return child
        end
    end
    return nil
end

local function AutoCutLog(logModel, tool)
    if not logModel or not logModel.Parent then return false end
    
    local sections = {}
    for _, child in pairs(logModel:GetChildren()) do
        if child:IsA("BasePart") and child:FindFirstChild("ID") then
            table.insert(sections, {part = child, id = child.ID.Value})
        end
    end
    
    table.sort(sections, function(a,b) return a.id < b.id end)
    
    if #sections == 0 then return false end
    
    for _, section in ipairs(sections) do
        if not autoCutterActive then return false end
        
        local cutPosition = section.part.CFrame * CFrame.new(0, 3, -5)
        player.Character.HumanoidRootPart.CFrame = cutPosition
        task.wait(0.2)
        
        if player.Character:FindFirstChild("Tool") ~= tool then
            player.Character.Humanoid:EquipTool(tool)
            task.wait(0.3)
        end
        
        local cutEvent = logModel:FindFirstChild("CutEvent")
        if cutEvent then
            ChopTree(cutEvent, section.id, 0.3, tool)
            task.wait(0.5)
        end
    end
    
    return true
end

local function BringLogToPosition(logModel, targetCFrame)
    if not logModel or not logModel.Parent then return end
    
    local ws = logModel:FindFirstChild("WoodSection")
    if ws then
        logModel.PrimaryPart = ws
    end
    
    for i = 1, 30 do
        if not autoCutterActive then break end
        DragModel(logModel, targetCFrame)
        task.wait(0.05)
    end
end

local function StartAutoCutter()
    if autoCutterActive then return end
    
    print("[VanillaHub] Auto cutter enabled - Click on a log to start")
    autoCutterActive = true
    
    local mouse = player:GetMouse()
    local clickConn
    
    clickConn = mouse.Button1Up:Connect(function()
        local clicked = mouse.Target
        if not clicked or not autoCutterActive then return end
        
        local logModel = clicked.Parent
        while logModel and not logModel:FindFirstChild("WoodSection") do
            logModel = logModel.Parent
        end
        
        if logModel and logModel:FindFirstChild("WoodSection") and logModel:FindFirstChild("Owner") then
            local owner = logModel.Owner.Value
            if owner == player then
                clickConn:Disconnect()
                
                autoCutterThread = task.spawn(function()
                    local tool = getBestAxe()
                    if not tool then
                        print("[VanillaHub] No axe found!")
                        autoCutterActive = false
                        return
                    end
                    
                    print("[VanillaHub] Starting to cut log...")
                    
                    player.Character.Humanoid:EquipTool(tool)
                    task.wait(0.3)
                    
                    local success = AutoCutLog(logModel, tool)
                    
                    if success and autoCutterActive then
                        print("[VanillaHub] Log cut complete, bringing to sell position...")
                        
                        task.wait(1)
                        
                        for _, log in pairs(workspace.LogModels:GetChildren()) do
                            if log:FindFirstChild("Owner") and log.Owner.Value == player then
                                if log:FindFirstChild("WoodSection") then
                                    BringLogToPosition(log, sellPosition)
                                    task.wait(0.2)
                                end
                            end
                        end
                        
                        print("[VanillaHub] All logs brought to sell position")
                    end
                    
                    autoCutterActive = false
                    autoCutterThread = nil
                end)
            end
        end
    end)
    
    task.spawn(function()
        while autoCutterActive do
            task.wait(1)
        end
        clickConn:Disconnect()
    end)
end

local function StopAutoCutter()
    autoCutterActive = false
    if autoCutterThread then
        task.cancel(autoCutterThread)
        autoCutterThread = nil
    end
    print("[VanillaHub] Auto cutter disabled")
end

-- ════════════════════════════════════════════════════
-- TREE BRINGING SYSTEM
-- ════════════════════════════════════════════════════

local treeBringActive = false
local treeBringThread = nil

local treeRegions = {}
local treeClasses = {
    "Generic","Walnut","Cherry","SnowGlow","Oak","Birch","Koa","Fir",
    "Volcano","GreenSwampy","CaveCrawler","Palm","GoldSwampy","Frost",
    "Spooky","SpookyNeon","LoneCave",
}

task.spawn(function()
    while task.wait(5) do
        for _, v in pairs(workspace:GetChildren()) do
            if v.Name == "TreeRegion" then
                treeRegions[v] = {}
                for _, child in pairs(v:GetChildren()) do
                    if child:FindFirstChild("TreeClass") then
                        table.insert(treeRegions[v], child.TreeClass.Value)
                    end
                end
            end
        end
    end
end)

local function GetBiggestTree(treeClass)
    local bestTree = nil
    local bestMass = 0
    
    for region, classes in pairs(treeRegions) do
        if table.find(classes, treeClass) then
            for _, child in pairs(region:GetChildren()) do
                if child:IsA("Model") and child:FindFirstChild("TreeClass") and child.TreeClass.Value == treeClass then
                    local owner = child:FindFirstChild("Owner")
                    if owner and (owner.Value == nil or owner.Value == player) then
                        local totalMass = 0
                        local trunk = nil
                        for _, part in pairs(child:GetChildren()) do
                            if part:IsA("BasePart") then
                                totalMass = totalMass + part:GetMass()
                                if part:FindFirstChild("ID") and part.ID.Value == 1 then
                                    trunk = part
                                end
                            end
                        end
                        if totalMass > bestMass then
                            bestMass = totalMass
                            bestTree = {model = child, trunk = trunk, mass = totalMass}
                        end
                    end
                end
            end
        end
    end
    
    return bestTree
end

local function BringTreeToPosition(treeClass, targetCFrame, useGodMode)
    local axe = getBestAxe()
    if not axe then
        print("[VanillaHub] No axe found!")
        return false
    end
    
    if treeClass == "LoneCave" then
        local hasEndTimes = false
        for _, tool in pairs(getTools()) do
            if tool:FindFirstChild("ToolName") and tool.ToolName.Value == "EndTimesAxe" then
                hasEndTimes = true
                axe = tool
                break
            end
        end
        if not hasEndTimes then
            print("[VanillaHub] Need EndTimes Axe for LoneCave!")
            return false
        end
    end
    
    local tree = GetBiggestTree(treeClass)
    if not tree then
        print("[VanillaHub] No "..treeClass.." tree found!")
        return false
    end
    
    if not tree.trunk then
        print("[VanillaHub] Tree trunk not found!")
        return false
    end
    
    player.Character.Humanoid:EquipTool(axe)
    task.wait(0.3)
    
    if useGodMode and treeClass == "LoneCave" then
        local lavaPart = GetLava()
        if lavaPart then
            player.Character.HumanoidRootPart.CFrame = CFrame.new(-1439.45, 433.4, 1317.61)
            task.wait(0.3)
            
            repeat task.wait(0.5)
                pcall(function() 
                    firetouchinterest(player.Character.HumanoidRootPart, lavaPart.Lava, 0)
                end)
            until player.Character.HumanoidRootPart:FindFirstChild("LavaFire") or not treeBringActive
            
            if player.Character.HumanoidRootPart:FindFirstChild("LavaFire") then
                player.Character.HumanoidRootPart.LavaFire:Destroy()
            end
        end
    end
    
    player.Character.HumanoidRootPart.CFrame = tree.trunk.CFrame
    task.wait(0.3)
    
    local cutEvent = tree.model:FindFirstChild("CutEvent")
    if not cutEvent then
        print("[VanillaHub] No CutEvent found!")
        return false
    end
    
    local logDropped = false
    local logConnection
    
    logConnection = workspace.LogModels.ChildAdded:Connect(function(log)
        if log:FindFirstChild("Owner") and log.Owner.Value == player then
            if log:FindFirstChild("TreeClass") and log.TreeClass.Value == treeClass then
                logDropped = true
            end
        end
    end)
    
    repeat
        ChopTree(cutEvent, 1, 0.3, axe)
        task.wait(0.3)
    until logDropped or not treeBringActive
    
    logConnection:Disconnect()
    
    if not treeBringActive then return false end
    
    task.wait(0.5)
    
    for _, log in pairs(workspace.LogModels:GetChildren()) do
        if log:FindFirstChild("Owner") and log.Owner.Value == player then
            if log:FindFirstChild("TreeClass") and log.TreeClass.Value == treeClass then
                local ws = log:FindFirstChild("WoodSection")
                if ws then
                    log.PrimaryPart = ws
                    for i = 1, 40 do
                        if not treeBringActive then break end
                        DragModel(log, targetCFrame)
                        task.wait(0.05)
                    end
                end
                break
            end
        end
    end
    
    return true
end

local function StartTreeBringer(treeType, amount, targetPos)
    if treeBringActive then
        print("[VanillaHub] Already bringing trees!")
        return
    end
    
    treeBringActive = true
    
    treeBringThread = task.spawn(function()
        local homeCFrame = player.Character.HumanoidRootPart.CFrame
        local useGodMode = (treeType == "LoneCave")
        
        for i = 1, amount do
            if not treeBringActive then break end
            
            print("[VanillaHub] Bringing tree " .. i .. "/" .. amount .. " (" .. treeType .. ")")
            
            local success = BringTreeToPosition(treeType, targetPos, useGodMode)
            
            if not success then
                print("[VanillaHub] Failed to bring tree " .. i)
                break
            end
            
            if i < amount then
                task.wait(1)
            end
        end
        
        if treeBringActive then
            player.Character.HumanoidRootPart.CFrame = homeCFrame
        end
        
        treeBringActive = false
        treeBringThread = nil
        print("[VanillaHub] Tree bringing complete!")
    end)
end

local function StopTreeBringer()
    treeBringActive = false
    if treeBringThread then
        task.cancel(treeBringThread)
        treeBringThread = nil
    end
    print("[VanillaHub] Tree bringing stopped")
end

-- ════════════════════════════════════════════════════
-- LOG MANAGEMENT
-- ════════════════════════════════════════════════════

local function BringAllLogsToPosition(targetCFrame)
    local playerPos = player.Character.HumanoidRootPart.CFrame
    
    for _, log in pairs(workspace.LogModels:GetChildren()) do
        if log:FindFirstChild("Owner") and log.Owner.Value == player then
            local ws = log:FindFirstChild("WoodSection")
            if ws then
                player.Character.HumanoidRootPart.CFrame = CFrame.new(ws.Position)
                task.wait(0.2)
                
                log.PrimaryPart = ws
                for i = 1, 30 do
                    DragModel(log, targetCFrame)
                    task.wait(0.05)
                end
            end
        end
        task.wait(0.1)
    end
    
    player.Character.HumanoidRootPart.CFrame = playerPos
    print("[VanillaHub] All logs brought to position!")
end

local function SellAllLogs()
    local sellPos = CFrame.new(314.76, -0.40, 87.29)
    BringAllLogsToPosition(sellPos)
    print("[VanillaHub] Logs are now at sell position!")
end

-- ════════════════════════════════════════════════════
-- WOOD TAB UI
-- ════════════════════════════════════════════════════

local woodPage = pages["WoodTab"]

for _, child in ipairs(woodPage:GetChildren()) do
    if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
        child:Destroy()
    end
end

-- Tree selector dropdown
local selectedTree = "Generic"
local treeDropIsOpen = false

sectionLabel(woodPage, "Tree Selection")

local treeDropOuter = Instance.new("Frame", woodPage)
treeDropOuter.Size = UDim2.new(1, 0, 0, 42)
treeDropOuter.BackgroundColor3 = C.CARD
treeDropOuter.BorderSizePixel = 0
treeDropOuter.ClipsDescendants = true
corner(treeDropOuter, 9)

local treeDropHeader = Instance.new("Frame", treeDropOuter)
treeDropHeader.Size = UDim2.new(1, 0, 0, 42)
treeDropHeader.BackgroundTransparency = 1

local treeDropLbl = Instance.new("TextLabel", treeDropHeader)
treeDropLbl.Size = UDim2.new(0, 70, 1, 0)
treeDropLbl.Position = UDim2.new(0, 12, 0, 0)
treeDropLbl.BackgroundTransparency = 1
treeDropLbl.Text = "Tree"
treeDropLbl.Font = Enum.Font.GothamBold
treeDropLbl.TextSize = 12
treeDropLbl.TextColor3 = C.TEXT
treeDropLbl.TextXAlignment = Enum.TextXAlignment.Left

local treeSelFrame = Instance.new("Frame", treeDropHeader)
treeSelFrame.Size = UDim2.new(1, -88, 0, 28)
treeSelFrame.Position = UDim2.new(0, 80, 0.5, -14)
treeSelFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
treeSelFrame.BorderSizePixel = 0
corner(treeSelFrame, 7)

local treeSelLbl = Instance.new("TextLabel", treeSelFrame)
treeSelLbl.Size = UDim2.new(1, -32, 1, 0)
treeSelLbl.Position = UDim2.new(0, 10, 0, 0)
treeSelLbl.BackgroundTransparency = 1
treeSelLbl.Text = "Generic"
treeSelLbl.Font = Enum.Font.GothamSemibold
treeSelLbl.TextSize = 12
treeSelLbl.TextColor3 = C.TEXT
treeSelLbl.TextXAlignment = Enum.TextXAlignment.Left

local treeArrowLbl = Instance.new("TextLabel", treeSelFrame)
treeArrowLbl.Size = UDim2.new(0, 22, 1, 0)
treeArrowLbl.Position = UDim2.new(1, -24, 0, 0)
treeArrowLbl.BackgroundTransparency = 1
treeArrowLbl.Text = "v"
treeArrowLbl.Font = Enum.Font.GothamBold
treeArrowLbl.TextSize = 11
treeArrowLbl.TextColor3 = C.TEXT_MID

local treeHeaderBtn = Instance.new("TextButton", treeSelFrame)
treeHeaderBtn.Size = UDim2.new(1, 0, 1, 0)
treeHeaderBtn.BackgroundTransparency = 1
treeHeaderBtn.Text = ""

local treeListScroll = Instance.new("ScrollingFrame", treeDropOuter)
treeListScroll.Position = UDim2.new(0, 0, 0, 44)
treeListScroll.Size = UDim2.new(1, 0, 0, 0)
treeListScroll.BackgroundTransparency = 1
treeListScroll.BorderSizePixel = 0
treeListScroll.ScrollBarThickness = 3
treeListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
treeListScroll.Visible = false

local treeListLayout = Instance.new("UIListLayout", treeListScroll)
treeListLayout.SortOrder = Enum.SortOrder.LayoutOrder
treeListLayout.Padding = UDim.new(0, 3)
treeListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    treeListScroll.CanvasSize = UDim2.new(0, 0, 0, treeListLayout.AbsoluteContentSize.Y + 8)
end)

local function BuildTreeList()
    for _, child in pairs(treeListScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    for i, treeName in ipairs(treeClasses) do
        local row = Instance.new("Frame", treeListScroll)
        row.Size = UDim2.new(1, -12, 0, 34)
        row.Position = UDim2.new(0, 6, 0, 0)
        row.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        corner(row, 7)
        
        local rowLbl = Instance.new("TextLabel", row)
        rowLbl.Size = UDim2.new(1, -12, 1, 0)
        rowLbl.Position = UDim2.new(0, 10, 0, 0)
        rowLbl.BackgroundTransparency = 1
        rowLbl.Text = treeName
        rowLbl.Font = Enum.Font.GothamSemibold
        rowLbl.TextSize = 12
        rowLbl.TextColor3 = treeName == selectedTree and C.ACCENT or C.TEXT
        rowLbl.TextXAlignment = Enum.TextXAlignment.Left
        
        local rowBtn = Instance.new("TextButton", row)
        rowBtn.Size = UDim2.new(1, 0, 1, 0)
        rowBtn.BackgroundTransparency = 1
        rowBtn.Text = ""
        
        rowBtn.MouseButton1Click:Connect(function()
            selectedTree = treeName
            treeSelLbl.Text = treeName
            treeCloseList()
        end)
    end
end

local function treeOpenList()
    treeDropIsOpen = true
    BuildTreeList()
    treeListScroll.Visible = true
    local listH = math.min(#treeClasses, 6) * 37 + 8
    TweenService:Create(treeArrowLbl, TweenInfo.new(0.18), {Rotation = 180}):Play()
    TweenService:Create(treeDropOuter, TweenInfo.new(0.22), {Size = UDim2.new(1, 0, 0, 42 + listH)}):Play()
    TweenService:Create(treeListScroll, TweenInfo.new(0.22), {Size = UDim2.new(1, 0, 0, listH)}):Play()
end

local function treeCloseList()
    treeDropIsOpen = false
    treeListScroll.Visible = false
    TweenService:Create(treeArrowLbl, TweenInfo.new(0.18), {Rotation = 0}):Play()
    TweenService:Create(treeDropOuter, TweenInfo.new(0.22), {Size = UDim2.new(1, 0, 0, 42)}):Play()
    TweenService:Create(treeListScroll, TweenInfo.new(0.22), {Size = UDim2.new(1, 0, 0, 0)}):Play()
end

treeHeaderBtn.MouseButton1Click:Connect(function()
    if treeDropIsOpen then treeCloseList() else treeOpenList() end
end)

local treeAmount = 1
makeSlider(woodPage, "Amount", 1, 50, 1, function(v) treeAmount = v end)

sepLine(woodPage)
sectionLabel(woodPage, "Actions")

-- Bring Tree button
local bringBtn = makeBtn(woodPage, "Bring Tree", function()
    if not selectedTree then
        warn("[VanillaHub] Select a tree first!")
        return
    end
    
    local targetPos = player.Character.HumanoidRootPart.CFrame
    StartTreeBringer(selectedTree, treeAmount, targetPos)
end)

-- Abort button
local abortBtn = makeBtn(woodPage, "Abort", function()
    StopTreeBringer()
    StopAutoCutter()
end)

sepLine(woodPage)
sectionLabel(woodPage, "Logs")

-- Bring All Logs button
makeBtn(woodPage, "Bring All Logs", function()
    local targetPos = player.Character.HumanoidRootPart.CFrame
    BringAllLogsToPosition(targetPos)
end)

-- Sell All Logs button
makeBtn(woodPage, "Sell All Logs", SellAllLogs)

sepLine(woodPage)
sectionLabel(woodPage, "Auto Cutter")

-- Auto Cutter toggle
makeToggle(woodPage, "Auto Cut Logs (Click on log)", false, function(val)
    if val then
        StartAutoCutter()
    else
        StopAutoCutter()
    end
end)

-- ════════════════════════════════════════════════════
-- SETTINGS TAB
-- ════════════════════════════════════════════════════

local keybindButtonGUI
local settingsPage = pages["SettingsTab"]

local kbFrame = Instance.new("Frame", settingsPage)
kbFrame.Size = UDim2.new(1, 0, 0, 70)
kbFrame.BackgroundColor3 = C.CARD
kbFrame.BorderSizePixel = 0
corner(kbFrame, 10)

local kbTitle = Instance.new("TextLabel", kbFrame)
kbTitle.Size = UDim2.new(1, -20, 0, 28)
kbTitle.Position = UDim2.new(0, 10, 0, 8)
kbTitle.BackgroundTransparency = 1
kbTitle.Font = Enum.Font.GothamBold
kbTitle.TextSize = 15
kbTitle.TextColor3 = C.TEXT
kbTitle.TextXAlignment = Enum.TextXAlignment.Left
kbTitle.Text = "GUI Toggle Keybind"

keybindButtonGUI = Instance.new("TextButton", kbFrame)
keybindButtonGUI.Size = UDim2.new(0, 200, 0, 28)
keybindButtonGUI.Position = UDim2.new(0, 10, 0, 36)
keybindButtonGUI.BackgroundColor3 = C.BTN
keybindButtonGUI.BorderSizePixel = 0
keybindButtonGUI.Font = Enum.Font.Gotham
keybindButtonGUI.TextSize = 14
keybindButtonGUI.TextColor3 = C.TEXT
keybindButtonGUI.AutoButtonColor = false
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
                {BackgroundColor3 = Color3.fromRGB(100, 100, 100)}):Play()
        end
        return
    end

    if getWaitingForFlyKey() then
        setWaitingForFlyKey(false)
        setCurrentFlyKey(input.KeyCode)
        if flyKeyBtn and flyKeyBtn.Parent then
            flyKeyBtn.Text = input.KeyCode.Name
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
    StopTreeBringer()
    StopAutoCutter()
end)

_G.VH.keybindButtonGUI = keybindButtonGUI

print("[VanillaHub] Vanilla3 loaded — Complete rewrite with working wood cutting!")
