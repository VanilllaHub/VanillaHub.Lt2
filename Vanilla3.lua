-- ════════════════════════════════════════════════════
-- VANILLA3 — Wood Tab + Settings Tab (FIXED & IMPROVED)
-- Full WoodHub logic integrated into VanillaHub theme
-- Tree selector uses same dropdown style as player selector
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

-- Global abort and position variables
getgenv().treeCut      = getgenv().treeCut      or false
getgenv().treestop     = getgenv().treestop     or false
getgenv().doneend      = getgenv().doneend      or true
getgenv().shouldAbort  = getgenv().shouldAbort  or false
getgenv().savedPosition = nil

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
    SUCCESS    = Color3.fromRGB(80,  200, 80),
    DANGER     = Color3.fromRGB(200, 80,  80),
    WARNING    = Color3.fromRGB(200, 160, 80),
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

local function sectionLabel(parent, text, icon)
    local w = Instance.new("Frame", parent)
    w.Size = UDim2.new(1, 0, 0, 32)
    w.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", w)
    lbl.Size = UDim2.new(1, -4, 1, 0)
    lbl.Position = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextColor3 = C.TEXT_DIM
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = (icon and icon .. " " or "") .. string.upper(text)
    return w
end

local function sepLine(parent)
    local s = Instance.new("Frame", parent)
    s.Size = UDim2.new(1, 0, 0, 1)
    s.BackgroundColor3 = C.SEP
    s.BorderSizePixel = 0
    return s
end

-- Modern action button with gradient effect
local function makeBtn(parent, text, cb, colorType)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = colorType == "danger" and C.DANGER or (colorType == "success" and C.SUCCESS or C.CARD)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextColor3 = C.TEXT
    btn.Text = text
    btn.AutoButtonColor = false
    corner(btn, 8)
    stroke(btn, C.BORDER, 1, 0.5)
    local pad = Instance.new("UIPadding", btn)
    pad.PaddingLeft = UDim.new(0, 12)
    
    local originalColor = btn.BackgroundColor3
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = colorType == "danger" and Color3.fromRGB(180, 70, 70) or (colorType == "success" and Color3.fromRGB(70, 180, 70) or C.BTN_HV)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = originalColor}):Play()
    end)
    if cb then btn.MouseButton1Click:Connect(function() task.spawn(cb) end) end
    return btn
end

-- Modern toggle switch
local SW_OFF      = Color3.fromRGB(55, 55, 55)
local SW_ON       = Color3.fromRGB(230, 230, 230)
local SW_KNOB_OFF = Color3.fromRGB(160, 160, 160)
local SW_KNOB_ON  = Color3.fromRGB(30, 30, 30)

local function makeToggle(parent, text, default, cb, description)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 48)
    frame.BackgroundColor3 = C.CARD
    frame.BorderSizePixel = 0
    corner(frame, 8)
    stroke(frame, C.BORDER, 1, 0.5)
    
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -54, 0, 20)
    lbl.Position = UDim2.new(0, 12, 0, 8)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextColor3 = C.TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    if description then
        local descLbl = Instance.new("TextLabel", frame)
        descLbl.Size = UDim2.new(1, -54, 0, 16)
        descLbl.Position = UDim2.new(0, 12, 0, 28)
        descLbl.BackgroundTransparency = 1
        descLbl.Text = description
        descLbl.Font = Enum.Font.Gotham
        descLbl.TextSize = 10
        descLbl.TextColor3 = C.TEXT_DIM
        descLbl.TextXAlignment = Enum.TextXAlignment.Left
    end
    
    local track = Instance.new("Frame", frame)
    track.Size = UDim2.new(0, 44, 0, 24)
    track.Position = UDim2.new(1, -56, 0.5, -12)
    track.BackgroundColor3 = default and SW_ON or SW_OFF
    track.BorderSizePixel = 0
    corner(track, 12)
    
    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, default and 24 or 3, 0.5, -9)
    knob.BackgroundColor3 = default and SW_KNOB_ON or SW_KNOB_OFF
    knob.BorderSizePixel = 0
    corner(knob, 9)
    
    local toggled = default or false
    local clickBtn = Instance.new("TextButton", frame)
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.ZIndex = 5
    
    clickBtn.MouseButton1Click:Connect(function()
        toggled = not toggled
        TweenService:Create(track, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            BackgroundColor3 = toggled and SW_ON or SW_OFF
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, toggled and 24 or 3, 0.5, -9),
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
            Position = UDim2.new(0, toggled and 24 or 3, 0.5, -9),
            BackgroundColor3 = toggled and SW_KNOB_ON or SW_KNOB_OFF
        }):Play()
    end
end

-- Modern slider
local function makeSlider(parent, text, minV, maxV, defV, cb, suffix)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 70)
    frame.BackgroundColor3 = C.CARD
    frame.BorderSizePixel = 0
    corner(frame, 8)
    stroke(frame, C.BORDER, 1, 0.5)
    
    local topRow = Instance.new("Frame", frame)
    topRow.Size = UDim2.new(1, -16, 0, 28)
    topRow.Position = UDim2.new(0, 8, 0, 8)
    topRow.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", topRow)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextColor3 = C.TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = text
    
    local valLbl = Instance.new("TextLabel", topRow)
    valLbl.Size = UDim2.new(0.4, 0, 1, 0)
    valLbl.Position = UDim2.new(0.6, 0, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 13
    valLbl.TextColor3 = C.ACCENT_DIM
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Text = tostring(defV) .. (suffix or "")
    
    local track = Instance.new("Frame", frame)
    track.Size = UDim2.new(1, -16, 0, 6)
    track.Position = UDim2.new(0, 8, 0, 46)
    track.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    track.BorderSizePixel = 0
    corner(track, 3)
    
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((defV-minV)/(maxV-minV), 0, 1, 0)
    fill.BackgroundColor3 = C.ACCENT_DIM
    fill.BorderSizePixel = 0
    corner(fill, 3)
    
    local knob = Instance.new("TextButton", track)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((defV-minV)/(maxV-minV), 0, 0.5, 0)
    knob.BackgroundColor3 = C.ACCENT
    knob.Text = ""
    knob.BorderSizePixel = 0
    corner(knob, 8)
    
    local ds = false
    local function upd(absX)
        local r = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.floor(minV + r * (maxV - minV) + 0.5)
        fill.Size = UDim2.new(r, 0, 1, 0)
        knob.Position = UDim2.new(r, 0, 0.5, 0)
        valLbl.Text = tostring(v) .. (suffix or "")
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

-- Status indicator
local function makeStatusIndicator(parent, text, defaultColor)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 36)
    frame.BackgroundColor3 = C.CARD
    frame.BorderSizePixel = 0
    corner(frame, 8)
    stroke(frame, C.BORDER, 1, 0.5)
    
    local indicator = Instance.new("Frame", frame)
    indicator.Size = UDim2.new(0, 10, 0, 10)
    indicator.Position = UDim2.new(0, 12, 0.5, -5)
    indicator.BackgroundColor3 = defaultColor or C.ACCENT
    indicator.BorderSizePixel = 0
    corner(indicator, 5)
    
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -32, 1, 0)
    lbl.Position = UDim2.new(0, 28, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = C.TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    return frame, indicator
end

-- ════════════════════════════════════════════════════
-- AXE / TREE LOGIC (from WoodHub)
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

local function table_foreach(t, cb)
    for i = 1, #t do cb(i, t[i]) end
end

local function getTools()
    pcall(function() player.Character.Humanoid:UnequipTools() end)
    local tools = {}
    table_foreach(player.Backpack:GetChildren(), function(_, v)
        if v.Name ~= "BlueprintTool" and v.Name ~= "Delete" and v.Name ~= "Undo" then
            tools[#tools+1] = v
        end
    end)
    return tools
end

local function hasSingleAxe()
    local tools = getTools()
    local axes = {}
    for _, v in ipairs(tools) do
        if v:FindFirstChild("ToolName") then
            table.insert(axes, v)
        end
    end
    if #axes == 0 then
        warn("[VanillaHub] No axe found in backpack.")
        return false
    end
    if #axes > 1 then
        warn("[VanillaHub] More than 1 axe in inventory (" .. #axes .. "). Remove extras before bringing a tree.")
        return false
    end
    return true
end

local function getToolStats(toolName)
    if typeof(toolName) ~= "string" then
        toolName = toolName.ToolName.Value
    end
    return require(ReplicatedStorage.AxeClasses["AxeClass_"..toolName]).new()
end

local function getBestAxe(treeClass)
    local tools = getTools()
    if #tools == 0 then
        warn("[VanillaHub] Need an axe in your backpack!")
        return false, nil
    end
    local toolStats = {}
    local tool
    for _, v in next, tools do
        if treeClass == "LoneCave" and v:FindFirstChild("ToolName") and v.ToolName.Value == "EndTimesAxe" then
            tool = v; break
        end
        local ok, axeStats = pcall(getToolStats, v)
        if ok and axeStats then
            if axeStats.SpecialTrees and axeStats.SpecialTrees[treeClass] then
                for i, sv in next, axeStats.SpecialTrees[treeClass] do axeStats[i] = sv end
            end
            table.insert(toolStats, {tool=v, damage = axeStats.Damage or 1})
        end
    end
    if not tool and treeClass == "LoneCave" then
        warn("[VanillaHub] Need EndTimes Axe for LoneCave!")
        return false, nil
    end
    table.sort(toolStats, function(a,b) return a.damage > b.damage end)
    local bestTool = tool or (toolStats[1] and toolStats[1].tool)
    if not bestTool then
        bestTool = tools[1]
    end
    return true, bestTool
end

local function cutPart(event, section, height, tool, treeClass)
    local damage, cooldown
    local ok, axeStats = pcall(getToolStats, tool)
    if ok and axeStats then
        if axeStats.SpecialTrees and axeStats.SpecialTrees[treeClass] then
            for i, v in next, axeStats.SpecialTrees[treeClass] do axeStats[i] = v end
        end
        damage   = axeStats.Damage
        cooldown = axeStats.SwingCooldown
    else
        local toolName = ""
        if typeof(tool) == "Instance" then
            toolName = (tool:FindFirstChild("ToolName") and tool.ToolName.Value) or tool.Name
        end
        damage   = HitPoints[toolName] or 1
        cooldown = 0.25837870788574
    end
    ReplicatedStorage.Interaction.RemoteProxy:FireServer(event, {
        tool         = tool,
        faceVector   = Vector3.new(-1,0,0),
        height       = height or 0.3,
        sectionId    = section or 1,
        hitPoints    = damage,
        cooldown     = cooldown,
        cuttingClass = "Axe",
    })
end

local function ChopTree(CutEvent, ID, Height)
    local equipped = player.Character:FindFirstChild("Tool")
    if not equipped then return end
    ReplicatedStorage.Interaction.RemoteProxy:FireServer(CutEvent, {
        tool         = equipped,
        faceVector   = Vector3.new(1,0,0),
        height       = Height,
        sectionId    = ID,
        hitPoints    = HitPoints[equipped.ToolName.Value] or 1,
        cooldown     = 0.25837870788574,
        cuttingClass = "Axe",
    })
end

local function isnetworkowner(Part)
    return Part.ReceiveAge == 0
end

local function DragModel(model, targetCFrame)
    local dest = typeof(targetCFrame) == "CFrame" and targetCFrame or CFrame.new(targetCFrame)
    local prim = model.PrimaryPart
    if not prim then
        prim = model:FindFirstChild("WoodSection")
        if prim then model.PrimaryPart = prim end
    end
    if not prim then return end
    ReplicatedStorage.Interaction.ClientIsDragging:FireServer(model)
    model:SetPrimaryPartCFrame(dest)
end

local treeClasses = {}
local treeRegions = {}

task.spawn(function()
    while task.wait(1) do
        for _, v in next, workspace:GetChildren() do
            if v.Name == "TreeRegion" then
                treeRegions[v] = treeRegions[v] or {}
                for _, v2 in next, v:GetChildren() do
                    if v2:FindFirstChild("TreeClass") then
                        if not table.find(treeClasses, v2.TreeClass.Value) then
                            table.insert(treeClasses, v2.TreeClass.Value)
                        end
                        if not table.find(treeRegions[v], v2.TreeClass.Value) then
                            table.insert(treeRegions[v], v2.TreeClass.Value)
                        end
                    end
                end
            end
        end
    end
end)

local function getBiggestTree(treeClass)
    local trees = {}
    for region, classes in next, treeRegions do
        if table.find(classes, treeClass) then
            for _, v2 in next, region:GetChildren() do
                if v2:IsA("Model") and v2:FindFirstChild("Owner") then
                    local ownerOk = v2.Owner.Value == nil or v2.Owner.Value == player
                    if v2:FindFirstChild("TreeClass") and v2.TreeClass.Value == treeClass and ownerOk then
                        local totalMass, treeTrunk = 0, nil
                        for _, v3 in next, v2:GetChildren() do
                            if v3:IsA("BasePart") then
                                if v3:FindFirstChild("ID") and v3.ID.Value == 1 then treeTrunk = v3 end
                                totalMass = totalMass + v3:GetMass()
                            end
                        end
                        table.insert(trees, {tree=v2, trunk=treeTrunk, mass=totalMass})
                    end
                end
            end
        end
    end
    table.sort(trees, function(a,b) return a.mass > b.mass end)
    return trees[1] or nil
end

local function treeListener(treeClass, callback)
    local conn
    conn = workspace.LogModels.ChildAdded:Connect(function(child)
        pcall(function()
            local owner = child:WaitForChild("Owner", 5)
            if owner and owner.Value == player and child.TreeClass.Value == treeClass then
                conn:Disconnect()
                callback(child)
            end
        end)
    end)
end

local function calculateHitsForEndPart(part)
    return math.round((math.sqrt(part.Size.X * part.Size.Z)^2 * 8e7) / 1e7)
end

local function DropTools()
    for _, v in pairs(player.Backpack:GetChildren()) do
        if v.Name == "Tool" then
            ReplicatedStorage.Interaction.ClientInteracted:FireServer(
                v, "Drop tool",
                player.Character.Head.CFrame * CFrame.new(0,4,-4)
            )
            task.wait(0.5)
        end
    end
end

local function GetToolsfix()
    for _, a in pairs(workspace.PlayerModels:GetDescendants()) do
        if a.Name == "Model" and a:FindFirstChild("Owner") then
            if a:FindFirstChild("ToolName") and a.ToolName.Value == "EndTimesAxe" then
                ReplicatedStorage.Interaction.ClientInteracted:FireServer(a, "Pick up tool")
            end
        end
    end
end

local function GetLava()
    local children = workspace:FindFirstChild("Region_Volcano") and workspace.Region_Volcano:GetChildren() or {}
    for i = 1, #children do
        local lava = children[i]
        if lava:FindFirstChild("Lava") then return lava end
    end
end

local function GodMode(targetCFrame)
    local LavaPart = GetLava()
    if not LavaPart then return end
    player.Character.HumanoidRootPart.CFrame = CFrame.new(-1439.45, 433.4, 1317.61)
    repeat task.wait(1)
        pcall(function() firetouchinterest(player.Character.HumanoidRootPart, LavaPart.Lava, 0) end)
    until player.Character.HumanoidRootPart:FindFirstChild("LavaFire")
    player.Character.HumanoidRootPart.LavaFire:Destroy()
    task.wait(1)
    local Clone = player.Character.Torso:Clone()
    Clone.Name = "HumanoidRootPart"
    Clone.Transparency = 1
    Clone.Parent = player.Character
    player.Character.HumanoidRootPart.CFrame = targetCFrame
    Clone.CFrame = targetCFrame
end

-- FIXED bringTree function with position memory and abort functionality
local function bringTree(treeClass, godmodeval, skipPositionSave)
    getgenv().treestop     = true
    getgenv().treeCut      = false
    getgenv().shouldAbort  = false
    
    player.Character.Humanoid.BreakJointsOnDeath = false
    
    if not skipPositionSave and not getgenv().savedPosition then
        getgenv().savedPosition = player.Character.HumanoidRootPart.CFrame
    end
    
    local oldPosition = getgenv().savedPosition or player.Character.HumanoidRootPart.CFrame

    local success, axe = getBestAxe(treeClass)
    if not success or not axe then 
        getgenv().treestop = false
        return 
    end

    player.Character.Humanoid:EquipTool(axe)
    task.wait(0.4)

    local tree = getBiggestTree(treeClass)
    if not tree then 
        warn("[VanillaHub] No "..treeClass.." tree found!")
        getgenv().treestop = false
        return 
    end
    if not tree.trunk then 
        warn("[VanillaHub] Tree trunk not found!")
        getgenv().treestop = false
        return 
    end
    if not (tree.trunk.Size.X >= 1 and tree.trunk.Size.Y >= 2 and tree.trunk.Size.Z >= 1) then
        warn("[VanillaHub] Tree too small, skipping.")
        getgenv().treestop = false
        return
    end

    if godmodeval then
        workspace.Camera.CameraType = Enum.CameraType.Fixed
        GodMode(tree.trunk.CFrame)
        workspace.Camera.CameraType = Enum.CameraType.Custom
        player.Character.HumanoidRootPart.CFrame = tree.trunk.CFrame
    end

    task.wait(0.5)

    treeListener(treeClass, function(log)
        log.PrimaryPart = log:FindFirstChild("WoodSection")
        getgenv().treeCut = true
        for i = 1, 100 do
            if getgenv().shouldAbort then break end
            DragModel(log, oldPosition)
            task.wait()
        end
    end)

    task.wait(0.15)

    task.spawn(function()
        repeat
            if getgenv().shouldAbort or not getgenv().treestop then break end
            player.Character.HumanoidRootPart.CFrame = tree.trunk.CFrame
            task.wait()
        until getgenv().treeCut
    end)

    task.wait()

    if treeClass == "LoneCave" and godmodeval then
        local numHits = calculateHitsForEndPart(tree.trunk) - 1
        for i = 1, numHits do
            if getgenv().shouldAbort then break end
            cutPart(tree.tree.CutEvent, 1, 0.3, axe, treeClass)
            task.wait(1)
        end
        getgenv().treeCut  = false
        getgenv().treestop = false
        
        if not getgenv().shouldAbort then
            DropTools()
            task.wait(0.3)
            workspace[player.Name].HumanoidRootPart.CFrame = CFrame.new(-1675, 261, 1284)
            task.wait(0.5)
            pcall(function()
                repeat task.wait() until player.Character.Humanoid.Health == 100
            end)
            task.wait(0.3)
            GetToolsfix()
            task.wait(0.5)
            if not getgenv().shouldAbort then
                bringTree("LoneCave", false, true)
            end
        end
    else
        repeat
            if getgenv().shouldAbort or not getgenv().treestop then break end
            cutPart(tree.tree.CutEvent, 1, 0.3, axe, treeClass)
            task.wait()
        until getgenv().treeCut
    end

    if treeClass == "LoneCave" then
        task.wait(1)
        if not getgenv().shouldAbort then
            player.Character.HumanoidRootPart.CFrame = oldPosition
        end
        getgenv().doneend  = true
        getgenv().treeCut  = false
        getgenv().treestop = false
    else
        task.wait(1)
        getgenv().treeCut = false
        if not getgenv().shouldAbort then
            player.Character.HumanoidRootPart.CFrame = oldPosition
        end
    end
end

local function BringAllLogs()
    local OldPos = player.Character.HumanoidRootPart.CFrame
    local count  = 0
    for _, v in next, workspace.LogModels:GetChildren() do
        if v:FindFirstChild("Owner") and v.Owner.Value == player then
            local ws = v:FindFirstChild("WoodSection")
            if ws then
                player.Character.HumanoidRootPart.CFrame = CFrame.new(ws.CFrame.p)
                if not v.PrimaryPart then v.PrimaryPart = ws end
                for i = 1, 50 do
                    ReplicatedStorage.Interaction.ClientIsDragging:FireServer(v)
                    v:SetPrimaryPartCFrame(OldPos)
                    task.wait()
                end
                count += 1
            end
        end
        task.wait()
    end
    player.Character.HumanoidRootPart.CFrame = OldPos
end

local function SellAllLogs()
    local OldPos     = player.Character.HumanoidRootPart.CFrame
    local sellCFrame = CFrame.new(314, -0.5, 86.822)
    local count      = 0
    for _, v in next, workspace.LogModels:GetChildren() do
        if v:FindFirstChild("Owner") and v.Owner.Value == player then
            local ws = v:FindFirstChild("WoodSection")
            if ws then
                player.Character.HumanoidRootPart.CFrame = CFrame.new(ws.CFrame.p)
                task.wait(0.3)
                if not v.PrimaryPart then v.PrimaryPart = ws end
                task.spawn(function()
                    for i = 1, 50 do
                        ReplicatedStorage.Interaction.ClientIsDragging:FireServer(v)
                        v:SetPrimaryPartCFrame(sellCFrame)
                        task.wait()
                    end
                end)
                count += 1
            end
        end
        task.wait()
    end
    player.Character.HumanoidRootPart.CFrame = OldPos
end

local ModWoodSawmill = nil

local function SelectSawmill(Type, onSelected)
    local Mouse = player:GetMouse()
    local conn
    conn = Mouse.Button1Down:Connect(function()
        local Target = Mouse.Target
        if not Target then return end
        Target = Target.Parent
        local Sawmill =
            (Target:FindFirstChild("Settings") and Target.Settings:FindFirstChild("DimZ")) or
            (Target.Parent:FindFirstChild("Settings") and Target.Parent.Settings:FindFirstChild("DimZ"))
        if Sawmill then
            ModWoodSawmill = Sawmill.Parent.Parent
            conn:Disconnect()
            if onSelected then onSelected() end
        end
    end)
end

local function ModSawmill()
    ModWoodSawmill = nil
    SelectSawmill("mod", function()
        local Conveyors   = ModWoodSawmill.Conveyor.Model:GetChildren()
        local Orientation = ModWoodSawmill.Main.Orientation.Y
        local Conveyor
        for i = (ModWoodSawmill.ItemName.Value:match("Sawmill4L") and #Conveyors-1) or #Conveyors, #Conveyors do
            Conveyor = Conveyors[i]; break
        end
        local Offset = 0.4
        for i = 1, 4 do
            Offset += 0.2
            ReplicatedStorage.PlaceStructure.ClientPlacedBlueprint:FireServer(
                "Floor2",
                CFrame.new(
                    Conveyor.CFrame.p + Vector3.new(
                        (Orientation == 0 and -Offset)   or (Orientation == 180 and Offset) or 0,
                        1.5,
                        (Orientation == -90 and -Offset) or (Orientation == 90  and Offset) or 0
                    )
                ) * CFrame.Angles(
                    math.rad(((Orientation==180 or Orientation==0) and 90) or 45),
                    math.rad(((Orientation==180 or Orientation==0) and 0)  or 90),
                    math.rad(((Orientation==180 or Orientation==0) and 90) or 45)
                ),
                player
            )
            task.wait(1.5)
        end
        ModWoodSawmill = nil
    end)
end

-- FIXED ModWood function
local function ModWood()
    local worked        = false
    local treelimbblist = {}
    local childbranch, parentbranch, firstpart

    SelectSawmill("mod wood", function()
        local Mouse = player:GetMouse()
        local modConn
        modConn = Mouse.Button1Down:Connect(function()
            local Clicked = Mouse.Target
            if Clicked and Clicked.Parent:FindFirstAncestor("LogModels") then
                if Clicked.Parent:FindFirstChild("Owner") and Clicked.Parent.Owner.Value == player then
                    for _, v in pairs(Clicked.Parent:GetDescendants()) do
                        if v.Name == "ChildIDs" and #v:GetChildren() == 0 then
                            table.insert(treelimbblist, v.Parent.ID.Value)
                        end
                    end
                    if #treelimbblist > 0 then
                        table.sort(treelimbblist)
                        for _, v in pairs(Clicked.Parent:GetDescendants()) do
                            if v.Name == "ChildIDs" then
                                for _, v2 in pairs(v:GetChildren()) do
                                    if v2.Value == treelimbblist[#treelimbblist] then
                                        parentbranch = v2.Parent.Parent
                                        Instance.new("Highlight", parentbranch)
                                    end
                                end
                            elseif v.Name == "ID" and v.Value == treelimbblist[#treelimbblist] then
                                local hl = Instance.new("Highlight", v.Parent)
                                hl.FillColor = Color3.new(0,1,0)
                                childbranch = v.Parent
                            end
                        end
                    end
                end
            end
        end)

        task.spawn(function()
            repeat task.wait(0.5) until childbranch or not modConn
            if not childbranch then 
                modConn:Disconnect()
                return 
            end
            modConn:Disconnect()

            local oldpos   = player.Character.HumanoidRootPart.CFrame
            local LavaPart = GetLava()
            firstpart      = childbranch.Parent:FindFirstChild("WoodSection")

            if not firstpart then return end
            
            player.Character.HumanoidRootPart.CFrame = firstpart.CFrame
            task.wait(0.2)

            repeat task.wait()
                if not parentbranch then break end
                while parentbranch and not isnetworkowner(parentbranch) do
                    ReplicatedStorage.Interaction.ClientIsDragging:FireServer(parentbranch.Parent)
                    task.wait()
                end
                if parentbranch then
                    ReplicatedStorage.Interaction.ClientIsDragging:FireServer(parentbranch.Parent)
                    parentbranch:PivotTo(CFrame.new(-1425, 489, 1244))
                    if LavaPart then
                        pcall(function()
                            firetouchinterest(parentbranch, LavaPart.Lava, 0)
                            firetouchinterest(parentbranch, LavaPart.Lava, 1)
                        end)
                    end
                end
            until not parentbranch or parentbranch:FindFirstChild("LavaFire")

            if parentbranch and parentbranch:FindFirstChild("LavaFire") then
                parentbranch:FindFirstChild("LavaFire"):Destroy()
            end
            pcall(function() if parentbranch then parentbranch:FindFirstChild("BodyAngularVelocity"):Destroy() end end)
            pcall(function() if parentbranch then parentbranch:FindFirstChild("BodyVelocity"):Destroy() end end)

            player.Character.HumanoidRootPart.CFrame = oldpos
            ModWoodSawmill = nil
        end)
    end)
end

local function DismemberTree()
    local OldPos        = player.Character.HumanoidRootPart.CFrame
    local LogChopped    = false
    local TreeToJointCut= nil

    local Mouse = player:GetMouse()

    local branchConn = workspace.LogModels.ChildAdded:Connect(function(v)
        if v:WaitForChild("Owner",5) and v.Owner.Value == player then
            if v:WaitForChild("WoodSection",5) then LogChopped = true end
        end
    end)

    local clickConn
    clickConn = Mouse.Button1Up:Connect(function()
        local Clicked = Mouse.Target
        if Clicked and Clicked.Parent:FindFirstAncestor("LogModels") then
            if Clicked.Parent:FindFirstChild("Owner") and Clicked.Parent.Owner.Value == player then
                TreeToJointCut = Clicked.Parent
            end
        end
    end)

    task.spawn(function()
        repeat task.wait() until TreeToJointCut
        clickConn:Disconnect()

        for _, v in next, TreeToJointCut:GetChildren() do
            if v.Name == "WoodSection" then
                if v:FindFirstChild("ID") and v.ID.Value ~= 1 then
                    player.Character.HumanoidRootPart.CFrame = CFrame.new(v.CFrame.p)
                    local ce = TreeToJointCut:FindFirstChild("CutEvent")
                    repeat
                        if ce then ChopTree(ce, v.ID.Value, 0) end
                        task.wait()
                    until LogChopped == true
                    LogChopped = false
                    task.wait(1)
                end
            end
        end
        branchConn:Disconnect()
        player.Character.HumanoidRootPart.CFrame = OldPos
    end)
end

local UnitCutter      = false
local PlankReAdded    = nil
local UnitCutterClick = nil

local function OneUnitCutter(val)
    UnitCutter = val
    local Mouse = player:GetMouse()
    if not val then
        if PlankReAdded    then PlankReAdded:Disconnect()    end
        if UnitCutterClick then UnitCutterClick:Disconnect() end
        return
    end
    local SelTree = nil
    PlankReAdded = workspace.PlayerModels.ChildAdded:Connect(function(v)
        if v:WaitForChild("TreeClass",5) and v:WaitForChild("WoodSection",5) then
            SelTree = v; task.wait()
        end
    end)
    UnitCutterClick = Mouse.Button1Up:Connect(function()
        local Clicked = Mouse.Target
        if not (player.Backpack:FindFirstChild("Tool") or player.Character:FindFirstChild("Tool")) then return end
        if Clicked and Clicked.Name == "WoodSection" then
            SelTree = Clicked.Parent
            player.Character:MoveTo(Clicked.Position + Vector3.new(0,3,-3))
            repeat
                if not UnitCutter then break end
                local ce = SelTree.CutEvent
                local tc = SelTree.TreeClass
                if ce and tc then ChopTree(ce, 1, 1) end
                local ws = SelTree:FindFirstChild("WoodSection")
                if ws then player.Character:MoveTo(ws.Position + Vector3.new(0,3,-3)) end
                task.wait()
            until SelTree.WoodSection.Size.X <= 1.88
                  and SelTree.WoodSection.Size.Y <= 1.88
                  and SelTree.WoodSection.Size.Z <= 1.88
        end
    end)
end

local function ViewEndTree(val)
    for _, v in pairs(workspace:GetChildren()) do
        if v.Name == "TreeRegion" then
            for _, v2 in pairs(v:GetChildren()) do
                if v2:FindFirstChild("Owner") and v2.Owner.Value == nil then
                    if v2:FindFirstChild("TreeClass") and v2.TreeClass.Value == "LoneCave" then
                        workspace.Camera.CameraSubject = val
                            and v2:FindFirstChild("WoodSection")
                            or  player.Character.Humanoid
                    end
                end
            end
        end
    end
end

-- ════════════════════════════════════════════════════
-- IMPROVED WOOD TAB UI
-- ════════════════════════════════════════════════════

local woodPage = pages["WoodTab"]

-- Clear any existing children
for _, child in ipairs(woodPage:GetChildren()) do
    if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
        child:Destroy()
    end
end

-- Add main layout
local mainLayout = Instance.new("UIListLayout", woodPage)
mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
mainLayout.Padding = UDim.new(0, 8)

local mainPadding = Instance.new("UIPadding", woodPage)
mainPadding.PaddingTop = UDim.new(0, 8)
mainPadding.PaddingBottom = UDim.new(0, 8)
mainPadding.PaddingLeft = UDim.new(0, 8)
mainPadding.PaddingRight = UDim.new(0, 8)

-- ── TREE SELECTOR SECTION ────────────────────────────────────────────────────

local TREE_LIST = {
    "Generic","Walnut","Cherry","SnowGlow","Oak","Birch","Koa","Fir",
    "Volcano","GreenSwampy","CaveCrawler","Palm","GoldSwampy","Frost",
    "Spooky","SpookyNeon","LoneCave",
}

local selectedTree    = "Generic"
local treeDropIsOpen  = false

local TD_HEADER_H = 48
local TD_ITEM_H   = 38
local TD_MAX_SHOW = 8

sectionLabel(woodPage, "Tree Selection", "🌲")

local treeCard = Instance.new("Frame", woodPage)
treeCard.Size = UDim2.new(1, 0, 0, 0)
treeCard.BackgroundColor3 = C.CARD
treeCard.BorderSizePixel = 0
treeCard.LayoutOrder = 1
corner(treeCard, 12)
stroke(treeCard, C.BORDER, 1, 0.4)

local treeDropOuter = Instance.new("Frame", treeCard)
treeDropOuter.Size = UDim2.new(1, -16, 0, TD_HEADER_H)
treeDropOuter.Position = UDim2.new(0, 8, 0, 8)
treeDropOuter.BackgroundColor3 = C.ROW
treeDropOuter.BorderSizePixel = 0
treeDropOuter.ClipsDescendants = true
corner(treeDropOuter, 10)
stroke(treeDropOuter, C.BORDER_DIM, 1, 0.3)

local treeDropHeader = Instance.new("Frame", treeDropOuter)
treeDropHeader.Size = UDim2.new(1, 0, 0, TD_HEADER_H)
treeDropHeader.BackgroundTransparency = 1

local treeIcon = Instance.new("TextLabel", treeDropHeader)
treeIcon.Size = UDim2.new(0, 32, 1, 0)
treeIcon.Position = UDim2.new(0, 8, 0, 0)
treeIcon.BackgroundTransparency = 1
treeIcon.Text = "🌳"
treeIcon.Font = Enum.Font.GothamBold
treeIcon.TextSize = 18
treeIcon.TextColor3 = C.TEXT

local treeSelFrame = Instance.new("Frame", treeDropHeader)
treeSelFrame.Size = UDim2.new(1, -100, 0, 34)
treeSelFrame.Position = UDim2.new(0, 48, 0.5, -17)
treeSelFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
treeSelFrame.BorderSizePixel = 0
corner(treeSelFrame, 8)
stroke(treeSelFrame, C.BORDER, 1, 0.35)

local treeSelLbl = Instance.new("TextLabel", treeSelFrame)
treeSelLbl.Size = UDim2.new(1, -40, 1, 0)
treeSelLbl.Position = UDim2.new(0, 12, 0, 0)
treeSelLbl.BackgroundTransparency = 1
treeSelLbl.Text = "Generic"
treeSelLbl.Font = Enum.Font.GothamSemibold
treeSelLbl.TextSize = 13
treeSelLbl.TextColor3 = C.TEXT
treeSelLbl.TextXAlignment = Enum.TextXAlignment.Left
treeSelLbl.TextTruncate = Enum.TextTruncate.AtEnd

local treeArrowLbl = Instance.new("TextLabel", treeSelFrame)
treeArrowLbl.Size = UDim2.new(0, 28, 1, 0)
treeArrowLbl.Position = UDim2.new(1, -32, 0, 0)
treeArrowLbl.BackgroundTransparency = 1
treeArrowLbl.Text = "▼"
treeArrowLbl.Font = Enum.Font.GothamBold
treeArrowLbl.TextSize = 12
treeArrowLbl.TextColor3 = C.TEXT_MID
treeArrowLbl.TextXAlignment = Enum.TextXAlignment.Center

local treeHeaderBtn = Instance.new("TextButton", treeSelFrame)
treeHeaderBtn.Size = UDim2.new(1, 0, 1, 0)
treeHeaderBtn.BackgroundTransparency = 1
treeHeaderBtn.Text = ""
treeHeaderBtn.AutoButtonColor = false
treeHeaderBtn.ZIndex = 5

local treeDropDivider = Instance.new("Frame", treeDropOuter)
treeDropDivider.Size = UDim2.new(1, -14, 0, 1)
treeDropDivider.Position = UDim2.new(0, 7, 0, TD_HEADER_H)
treeDropDivider.BackgroundColor3 = C.BORDER
treeDropDivider.BorderSizePixel = 0
treeDropDivider.Visible = false

local treeListScroll = Instance.new("ScrollingFrame", treeDropOuter)
treeListScroll.Position = UDim2.new(0, 0, 0, TD_HEADER_H + 2)
treeListScroll.Size = UDim2.new(1, 0, 0, 0)
treeListScroll.BackgroundTransparency = 1
treeListScroll.BorderSizePixel = 0
treeListScroll.ScrollBarThickness = 3
treeListScroll.ScrollBarImageColor3 = C.BORDER
treeListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
treeListScroll.ClipsDescendants = true

local treeListLayout = Instance.new("UIListLayout", treeListScroll)
treeListLayout.SortOrder = Enum.SortOrder.LayoutOrder
treeListLayout.Padding = UDim.new(0, 4)
treeListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    treeListScroll.CanvasSize = UDim2.new(0, 0, 0, treeListLayout.AbsoluteContentSize.Y + 8)
end)
local treeListPad = Instance.new("UIPadding", treeListScroll)
treeListPad.PaddingTop = UDim.new(0, 4)
treeListPad.PaddingBottom = UDim.new(0, 4)
treeListPad.PaddingLeft = UDim.new(0, 6)
treeListPad.PaddingRight = UDim.new(0, 6)

local function treeCloseList()
    treeDropIsOpen = false
    TweenService:Create(treeArrowLbl, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
    TweenService:Create(treeDropOuter, TweenInfo.new(0.20, Enum.EasingStyle.Quint), {Size = UDim2.new(1, -16, 0, TD_HEADER_H)}):Play()
    TweenService:Create(treeListScroll, TweenInfo.new(0.20, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, 0)}):Play()
    treeDropDivider.Visible = false
    treeCard.Size = UDim2.new(1, 0, 0, TD_HEADER_H + 16)
end

local function treeBuildList()
    for _, c in ipairs(treeListScroll:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
    end
    for i, treeName in ipairs(TREE_LIST) do
        local row = Instance.new("Frame", treeListScroll)
        row.Size = UDim2.new(1, 0, 0, TD_ITEM_H)
        row.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        corner(row, 7)
        
        local rowLbl = Instance.new("TextLabel", row)
        rowLbl.Size = UDim2.new(1, -16, 1, 0)
        rowLbl.Position = UDim2.new(0, 12, 0, 0)
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
        rowBtn.AutoButtonColor = false
        rowBtn.ZIndex = 5
        
        rowBtn.MouseEnter:Connect(function()
            TweenService:Create(row, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(34,34,34)}):Play()
        end)
        rowBtn.MouseLeave:Connect(function()
            TweenService:Create(row, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(20,20,20)}):Play()
        end)
        rowBtn.MouseButton1Click:Connect(function()
            selectedTree = treeName
            treeSelLbl.Text = treeName
            treeCloseList()
        end)
    end
end

local function treeOpenList()
    treeDropIsOpen = true
    treeBuildList()
    local listH = math.min(#TREE_LIST, TD_MAX_SHOW) * (TD_ITEM_H + 4) + 10
    treeDropDivider.Visible = true
    TweenService:Create(treeArrowLbl, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {Rotation = 180}):Play()
    TweenService:Create(treeDropOuter, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1, -16, 0, TD_HEADER_H + 2 + listH)}):Play()
    TweenService:Create(treeListScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, listH)}):Play()
    treeCard.Size = UDim2.new(1, 0, 0, TD_HEADER_H + 2 + listH + 16)
end

treeHeaderBtn.MouseButton1Click:Connect(function()
    if treeDropIsOpen then treeCloseList() else treeOpenList() end
end)

treeCard.Size = UDim2.new(1, 0, 0, TD_HEADER_H + 16)

-- Amount slider
sectionLabel(woodPage, "Amount", "🔢")
makeSlider(woodPage, "Trees to bring", 1, 50, 1, function(v) treeAmount = v end, "x")

local treeAmount = 1

-- ── STATUS INDICATOR ─────────────────────────────────────────────────────────
sectionLabel(woodPage, "Status", "📊")
local statusFrame, statusIndicator = makeStatusIndicator(woodPage, "Idle - Ready to chop", C.ACCENT_DIM)

-- ── ACTION BUTTONS ──────────────────────────────────────────────────────────
sectionLabel(woodPage, "Actions", "⚡")

local actionGrid = Instance.new("Frame", woodPage)
actionGrid.Size = UDim2.new(1, 0, 0, 90)
actionGrid.BackgroundTransparency = 1
actionGrid.LayoutOrder = 4

local gridLayout = Instance.new("UIGridLayout", actionGrid)
gridLayout.CellSize = UDim2.new(0.5, -6, 0, 38)
gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
gridLayout.FillDirection = Enum.FillDirection.Horizontal
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local bringBtn = Instance.new("TextButton", actionGrid)
bringBtn.Size = UDim2.new(1, 0, 1, 0)
bringBtn.BackgroundColor3 = C.SUCCESS
bringBtn.BorderSizePixel = 0
bringBtn.Font = Enum.Font.GothamSemibold
bringBtn.TextSize = 14
bringBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
bringBtn.Text = "🌲 BRING TREE"
bringBtn.AutoButtonColor = false
corner(bringBtn, 10)
stroke(bringBtn, C.BORDER, 1, 0.5)

local abortBtn = Instance.new("TextButton", actionGrid)
abortBtn.Size = UDim2.new(1, 0, 1, 0)
abortBtn.BackgroundColor3 = C.DANGER
abortBtn.BorderSizePixel = 0
abortBtn.Font = Enum.Font.GothamSemibold
abortBtn.TextSize = 14
abortBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
abortBtn.Text = "⛔ ABORT"
abortBtn.AutoButtonColor = false
corner(abortBtn, 10)
stroke(abortBtn, C.BORDER, 1, 0.5)

bringBtn.MouseEnter:Connect(function()
    TweenService:Create(bringBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(100, 220, 100)}):Play()
end)
bringBtn.MouseLeave:Connect(function()
    TweenService:Create(bringBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.SUCCESS}):Play()
end)

abortBtn.MouseEnter:Connect(function()
    TweenService:Create(abortBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(220, 100, 100)}):Play()
end)
abortBtn.MouseLeave:Connect(function()
    TweenService:Create(abortBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.DANGER}):Play()
end)

bringBtn.MouseButton1Click:Connect(function()
    if not selectedTree or selectedTree == "" then
        warn("[VanillaHub] Select a tree first!")
        return
    end
    if not hasSingleAxe() then return end
    
    getgenv().shouldAbort = false
    getgenv().savedPosition = nil
    
    statusIndicator.BackgroundColor3 = C.WARNING
    statusFrame:FindFirstChildOfClass("TextLabel").Text = "🌲 Bringing " .. treeAmount .. "x " .. selectedTree .. " trees..."
    
    task.spawn(function()
        if selectedTree == "LoneCave" then
            bringTree(selectedTree, true, false)
        else
            for i = 1, treeAmount do
                if getgenv().shouldAbort then break end
                statusFrame:FindFirstChildOfClass("TextLabel").Text = "🌲 Bringing tree " .. i .. "/" .. treeAmount
                task.wait(0.5)
                bringTree(selectedTree, false, false)
            end
        end
        getgenv().savedPosition = nil
        statusIndicator.BackgroundColor3 = C.ACCENT_DIM
        statusFrame:FindFirstChildOfClass("TextLabel").Text = "Idle - Ready to chop"
        if getgenv().shouldAbort then
            statusFrame:FindFirstChildOfClass("TextLabel").Text = "Aborted - Ready to chop"
        end
    end)
end)

abortBtn.MouseButton1Click:Connect(function()
    getgenv().treestop = false
    getgenv().shouldAbort = true
    statusIndicator.BackgroundColor3 = C.DANGER
    statusFrame:FindFirstChildOfClass("TextLabel").Text = "⚠️ Aborting operations..."
    task.delay(2, function()
        if not getgenv().treeCut and not getgenv().treestop then
            statusIndicator.BackgroundColor3 = C.ACCENT_DIM
            statusFrame:FindFirstChildOfClass("TextLabel").Text = "Idle - Ready to chop"
        end
    end)
end)

-- ── LOGS SECTION ─────────────────────────────────────────────────────────────
sectionLabel(woodPage, "Logs", "📦")

local logsGrid = Instance.new("Frame", woodPage)
logsGrid.Size = UDim2.new(1, 0, 0, 90)
logsGrid.BackgroundTransparency = 1
logsGrid.LayoutOrder = 5

local logsGridLayout = Instance.new("UIGridLayout", logsGrid)
logsGridLayout.CellSize = UDim2.new(0.5, -6, 0, 38)
logsGridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
logsGridLayout.FillDirection = Enum.FillDirection.Horizontal

local bringLogsBtn = Instance.new("TextButton", logsGrid)
bringLogsBtn.Size = UDim2.new(1, 0, 1, 0)
bringLogsBtn.BackgroundColor3 = C.CARD
bringLogsBtn.BorderSizePixel = 0
bringLogsBtn.Font = Enum.Font.GothamSemibold
bringLogsBtn.TextSize = 13
bringLogsBtn.TextColor3 = C.TEXT
bringLogsBtn.Text = "📦 Bring All Logs"
bringLogsBtn.AutoButtonColor = false
corner(bringLogsBtn, 10)
stroke(bringLogsBtn, C.BORDER, 1, 0.5)

local sellLogsBtn = Instance.new("TextButton", logsGrid)
sellLogsBtn.Size = UDim2.new(1, 0, 1, 0)
sellLogsBtn.BackgroundColor3 = C.CARD
sellLogsBtn.BorderSizePixel = 0
sellLogsBtn.Font = Enum.Font.GothamSemibold
sellLogsBtn.TextSize = 13
sellLogsBtn.TextColor3 = C.TEXT
sellLogsBtn.Text = "💰 Sell All Logs"
sellLogsBtn.AutoButtonColor = false
corner(sellLogsBtn, 10)
stroke(sellLogsBtn, C.BORDER, 1, 0.5)

bringLogsBtn.MouseEnter:Connect(function() TweenService:Create(bringLogsBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.BTN_HV}):Play() end)
bringLogsBtn.MouseLeave:Connect(function() TweenService:Create(bringLogsBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.CARD}):Play() end)
sellLogsBtn.MouseEnter:Connect(function() TweenService:Create(sellLogsBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.BTN_HV}):Play() end)
sellLogsBtn.MouseLeave:Connect(function() TweenService:Create(sellLogsBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.CARD}):Play() end)

bringLogsBtn.MouseButton1Click:Connect(function() task.spawn(BringAllLogs) end)
sellLogsBtn.MouseButton1Click:Connect(function() task.spawn(SellAllLogs) end)

-- ── SAWMILL SECTION ─────────────────────────────────────────────────────────
sectionLabel(woodPage, "Sawmill", "⚙️")

local sawmillGrid = Instance.new("Frame", woodPage)
sawmillGrid.Size = UDim2.new(1, 0, 0, 90)
sawmillGrid.BackgroundTransparency = 1
sawmillGrid.LayoutOrder = 6

local sawmillGridLayout = Instance.new("UIGridLayout", sawmillGrid)
sawmillGridLayout.CellSize = UDim2.new(0.5, -6, 0, 38)
sawmillGridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
sawmillGridLayout.FillDirection = Enum.FillDirection.Horizontal

local modSawmillBtn = Instance.new("TextButton", sawmillGrid)
modSawmillBtn.Size = UDim2.new(1, 0, 1, 0)
modSawmillBtn.BackgroundColor3 = C.CARD
modSawmillBtn.BorderSizePixel = 0
modSawmillBtn.Font = Enum.Font.GothamSemibold
modSawmillBtn.TextSize = 13
modSawmillBtn.TextColor3 = C.TEXT
modSawmillBtn.Text = "🔧 Mod Sawmill"
modSawmillBtn.AutoButtonColor = false
corner(modSawmillBtn, 10)
stroke(modSawmillBtn, C.BORDER, 1, 0.5)

local modWoodBtn = Instance.new("TextButton", sawmillGrid)
modWoodBtn.Size = UDim2.new(1, 0, 1, 0)
modWoodBtn.BackgroundColor3 = C.CARD
modWoodBtn.BorderSizePixel = 0
modWoodBtn.Font = Enum.Font.GothamSemibold
modWoodBtn.TextSize = 13
modWoodBtn.TextColor3 = C.TEXT
modWoodBtn.Text = "🪵 Mod Wood"
modWoodBtn.AutoButtonColor = false
corner(modWoodBtn, 10)
stroke(modWoodBtn, C.BORDER, 1, 0.5)

modSawmillBtn.MouseEnter:Connect(function() TweenService:Create(modSawmillBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.BTN_HV}):Play() end)
modSawmillBtn.MouseLeave:Connect(function() TweenService:Create(modSawmillBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.CARD}):Play() end)
modWoodBtn.MouseEnter:Connect(function() TweenService:Create(modWoodBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.BTN_HV}):Play() end)
modWoodBtn.MouseLeave:Connect(function() TweenService:Create(modWoodBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.CARD}):Play() end)

modSawmillBtn.MouseButton1Click:Connect(function() ModSawmill() end)
modWoodBtn.MouseButton1Click:Connect(function() ModWood() end)

-- ── ADVANCED SECTION ────────────────────────────────────────────────────────
sectionLabel(woodPage, "Advanced", "🔧")

local advancedGrid = Instance.new("Frame", woodPage)
advancedGrid.Size = UDim2.new(1, 0, 0, 90)
advancedGrid.BackgroundTransparency = 1
advancedGrid.LayoutOrder = 7

local advancedGridLayout = Instance.new("UIGridLayout", advancedGrid)
advancedGridLayout.CellSize = UDim2.new(0.5, -6, 0, 38)
advancedGridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
advancedGridLayout.FillDirection = Enum.FillDirection.Horizontal

local dismemberBtn = Instance.new("TextButton", advancedGrid)
dismemberBtn.Size = UDim2.new(1, 0, 1, 0)
dismemberBtn.BackgroundColor3 = C.CARD
dismemberBtn.BorderSizePixel = 0
dismemberBtn.Font = Enum.Font.GothamSemibold
dismemberBtn.TextSize = 13
dismemberBtn.TextColor3 = C.TEXT
dismemberBtn.Text = "🔪 Dismember Tree"
dismemberBtn.AutoButtonColor = false
corner(dismemberBtn, 10)
stroke(dismemberBtn, C.BORDER, 1, 0.5)

local emptyBtn = Instance.new("TextButton", advancedGrid)
emptyBtn.Size = UDim2.new(1, 0, 1, 0)
emptyBtn.BackgroundColor3 = C.CARD
emptyBtn.BorderSizePixel = 0
emptyBtn.Font = Enum.Font.GothamSemibold
emptyBtn.TextSize = 13
emptyBtn.TextColor3 = C.TEXT
emptyBtn.Text = ""
emptyBtn.AutoButtonColor = false
corner(emptyBtn, 10)
stroke(emptyBtn, C.BORDER, 1, 0.5)
emptyBtn.Visible = false

dismemberBtn.MouseEnter:Connect(function() TweenService:Create(dismemberBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.BTN_HV}):Play() end)
dismemberBtn.MouseLeave:Connect(function() TweenService:Create(dismemberBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.CARD}):Play() end)
dismemberBtn.MouseButton1Click:Connect(function() DismemberTree() end)

-- ── TOGGLE OPTIONS ──────────────────────────────────────────────────────────
sectionLabel(woodPage, "Options", "⚙️")

makeToggle(woodPage, "Cut Plank 1x1", false, function(val) OneUnitCutter(val) end, "Auto-cut planks to 1x1 size")
makeToggle(woodPage, "View LoneCave Tree", false, function(val) ViewEndTree(val) end, "Camera focus on LoneCave tree")

-- ── TOOLS SECTION ───────────────────────────────────────────────────────────
sectionLabel(woodPage, "Tools", "🛠️")

local toolsGrid = Instance.new("Frame", woodPage)
toolsGrid.Size = UDim2.new(1, 0, 0, 90)
toolsGrid.BackgroundTransparency = 1
toolsGrid.LayoutOrder = 9

local toolsGridLayout = Instance.new("UIGridLayout", toolsGrid)
toolsGridLayout.CellSize = UDim2.new(0.5, -6, 0, 38)
toolsGridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
toolsGridLayout.FillDirection = Enum.FillDirection.Horizontal

local getToolsBtn = Instance.new("TextButton", toolsGrid)
getToolsBtn.Size = UDim2.new(1, 0, 1, 0)
getToolsBtn.BackgroundColor3 = C.CARD
getToolsBtn.BorderSizePixel = 0
getToolsBtn.Font = Enum.Font.GothamSemibold
getToolsBtn.TextSize = 13
getToolsBtn.TextColor3 = C.TEXT
getToolsBtn.Text = "🔧 Get Tools Fix"
getToolsBtn.AutoButtonColor = false
corner(getToolsBtn, 10)
stroke(getToolsBtn, C.BORDER, 1, 0.5)

local dropToolsBtn = Instance.new("TextButton", toolsGrid)
dropToolsBtn.Size = UDim2.new(1, 0, 1, 0)
dropToolsBtn.BackgroundColor3 = C.CARD
dropToolsBtn.BorderSizePixel = 0
dropToolsBtn.Font = Enum.Font.GothamSemibold
dropToolsBtn.TextSize = 13
dropToolsBtn.TextColor3 = C.TEXT
dropToolsBtn.Text = "📤 Drop All Tools"
dropToolsBtn.AutoButtonColor = false
corner(dropToolsBtn, 10)
stroke(dropToolsBtn, C.BORDER, 1, 0.5)

getToolsBtn.MouseEnter:Connect(function() TweenService:Create(getToolsBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.BTN_HV}):Play() end)
getToolsBtn.MouseLeave:Connect(function() TweenService:Create(getToolsBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.CARD}):Play() end)
dropToolsBtn.MouseEnter:Connect(function() TweenService:Create(dropToolsBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.BTN_HV}):Play() end)
dropToolsBtn.MouseLeave:Connect(function() TweenService:Create(dropToolsBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.CARD}):Play() end)

getToolsBtn.MouseButton1Click:Connect(function() GetToolsfix() end)
dropToolsBtn.MouseButton1Click:Connect(function() task.spawn(DropTools) end)

-- ════════════════════════════════════════════════════
-- SETTINGS TAB
-- ════════════════════════════════════════════════════

local keybindButtonGUI
local settingsPage = pages["SettingsTab"]

-- Clear settings page
for _, child in ipairs(settingsPage:GetChildren()) do
    if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
        child:Destroy()
    end
end

local settingsLayout = Instance.new("UIListLayout", settingsPage)
settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
settingsLayout.Padding = UDim.new(0, 8)

local settingsPadding = Instance.new("UIPadding", settingsPage)
settingsPadding.PaddingTop = UDim.new(0, 8)
settingsPadding.PaddingBottom = UDim.new(0, 8)
settingsPadding.PaddingLeft = UDim.new(0, 8)
settingsPadding.PaddingRight = UDim.new(0, 8)

sectionLabel(settingsPage, "Keybinds", "⌨️")

local kbFrame = Instance.new("Frame", settingsPage)
kbFrame.Size = UDim2.new(1, 0, 0, 80)
kbFrame.BackgroundColor3 = C.CARD
kbFrame.BorderSizePixel = 0
kbFrame.LayoutOrder = 1
corner(kbFrame, 12)
stroke(kbFrame, C.BORDER, 1, 0.4)

local kbTitle = Instance.new("TextLabel", kbFrame)
kbTitle.Size = UDim2.new(1, -20, 0, 28)
kbTitle.Position = UDim2.new(0, 12, 0, 12)
kbTitle.BackgroundTransparency = 1
kbTitle.Font = Enum.Font.GothamBold
kbTitle.TextSize = 14
kbTitle.TextColor3 = C.TEXT
kbTitle.TextXAlignment = Enum.TextXAlignment.Left
kbTitle.Text = "GUI Toggle Keybind"

keybindButtonGUI = Instance.new("TextButton", kbFrame)
keybindButtonGUI.Size = UDim2.new(0, 220, 0, 36)
keybindButtonGUI.Position = UDim2.new(0, 12, 0, 44)
keybindButtonGUI.BackgroundColor3 = C.BTN
keybindButtonGUI.BorderSizePixel = 0
keybindButtonGUI.Font = Enum.Font.GothamSemibold
keybindButtonGUI.TextSize = 14
keybindButtonGUI.TextColor3 = C.TEXT
keybindButtonGUI.AutoButtonColor = false
keybindButtonGUI.Text = "Toggle Key: " .. getCurrentToggleKey().Name
corner(keybindButtonGUI, 8)
stroke(keybindButtonGUI, C.BORDER, 1, 0.3)

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
    if UnitCutterClick then UnitCutterClick:Disconnect(); UnitCutterClick = nil end
    if PlankReAdded    then PlankReAdded:Disconnect();    PlankReAdded    = nil end
    getgenv().treestop = false
    getgenv().shouldAbort = false
end)

_G.VH.keybindButtonGUI = keybindButtonGUI

print("[VanillaHub] Vanilla3 loaded — Wood tab ready with improved layout and fixes!")
