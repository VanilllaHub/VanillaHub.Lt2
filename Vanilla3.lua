-- ════════════════════════════════════════════════════
-- VANILLA3 — Wood Tab + Settings Tab
-- Full WoodHub logic integrated into VanillaHub theme
-- COMPLETE VERSION - ALL features working
-- FIXED: 1x1 Auto Cutter - Cuts ALL sections continuously
-- FIXED: Abort teleports back to start position
-- FIXED: Click Sell / Sell All → instant lay-flat at new position
-- FIXED: Options toggles are mutually exclusive (radio-style)
-- FIXED: Bring/Sell All Logs → Abort button + return to start
-- FIXED: LoneCave cutting — loops all WoodSections, faceVector(1,0,0), equips axe properly
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
    CARD2      = Color3.fromRGB(18,  18,  18),
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
    SEP        = Color3.fromRGB(35,  35,  35),
    GREEN      = Color3.fromRGB(60,  180,  80),
    RED        = Color3.fromRGB(200,  60,  60),
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
    w.Size = UDim2.new(1, 0, 0, 24)
    w.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", w)
    lbl.Size              = UDim2.new(1, -4, 1, 0)
    lbl.Position          = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font              = Enum.Font.GothamBold
    lbl.TextSize          = 10
    lbl.TextColor3        = C.TEXT_MID
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.Text              = string.upper(text)
    return w
end

local function sepLine(parent)
    local s = Instance.new("Frame", parent)
    s.Size             = UDim2.new(1, 0, 0, 1)
    s.BackgroundColor3 = C.SEP
    s.BorderSizePixel  = 0
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

local function makeBtnPair(parent, leftText, rightText, leftCb, rightCb, rightRed)
    local row = Instance.new("Frame", parent)
    row.Size                  = UDim2.new(1, 0, 0, 34)
    row.BackgroundTransparency = 1

    local function half(xPos, text, cb, red)
        local btn = Instance.new("TextButton", row)
        btn.Size             = UDim2.new(0.5, -3, 1, 0)
        btn.Position         = UDim2.new(xPos, xPos == 0 and 0 or 6, 0, 0)
        btn.BackgroundColor3 = C.CARD
        btn.BorderSizePixel  = 0
        btn.Font             = Enum.Font.GothamSemibold
        btn.TextSize         = 12
        btn.TextColor3       = red and C.RED or C.TEXT
        btn.Text             = text
        btn.AutoButtonColor  = false
        corner(btn, 8)
        stroke(btn, red and C.RED or C.BORDER, 1, red and 0.3 or 0.5)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = C.BTN_HV}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = C.CARD}):Play()
        end)
        if cb then btn.MouseButton1Click:Connect(function() task.spawn(cb) end) end
        return btn
    end

    local leftBtn  = half(0,   leftText,  leftCb,  false)
    local rightBtn = half(0.5, rightText, rightCb, rightRed)
    return row, leftBtn, rightBtn
end

local SW_OFF      = Color3.fromRGB(55, 55, 55)
local SW_ON       = Color3.fromRGB(230, 230, 230)
local SW_KNOB_OFF = Color3.fromRGB(160, 160, 160)
local SW_KNOB_ON  = Color3.fromRGB(30, 30, 30)

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

-- ── cutPart: used for normal trees ──────────────────────────────────────────
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

-- ── ChopTree: matches the 1x1 cutter style (faceVector 1,0,0) ───────────────
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

    -- Search inside TreeRegion folders (normal trees)
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

    -- Also search workspace directly (LoneCave and other special trees live here)
    for _, v2 in next, workspace:GetChildren() do
        if v2:IsA("Model") and v2:FindFirstChild("Owner") and v2:FindFirstChild("TreeClass") then
            local ownerOk = v2.Owner.Value == nil or v2.Owner.Value == player
            if v2.TreeClass.Value == treeClass and ownerOk then
                local alreadyAdded = false
                for _, t in ipairs(trees) do
                    if t.tree == v2 then alreadyAdded = true; break end
                end
                if not alreadyAdded then
                    local totalMass, treeTrunk = 0, nil
                    local biggestSize = 0

                    for _, v3 in next, v2:GetChildren() do
                        if v3:IsA("BasePart") then
                            -- Try ID=1 first
                            if v3:FindFirstChild("ID") and v3.ID.Value == 1 then
                                treeTrunk = v3
                            end
                            -- Also track biggest WoodSection as fallback
                            if v3.Name == "WoodSection" then
                                local sz = v3.Size.Magnitude
                                if sz > biggestSize then
                                    biggestSize = sz
                                    if not treeTrunk then treeTrunk = v3 end
                                end
                            end
                            totalMass = totalMass + v3:GetMass()
                        end
                    end

                    -- Final fallback: any WoodSection
                    if not treeTrunk then
                        treeTrunk = v2:FindFirstChildWhichIsA("BasePart")
                    end

                    table.insert(trees, {tree=v2, trunk=treeTrunk, mass=totalMass})
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

getgenv().treeCut  = getgenv().treeCut  or false
getgenv().treestop = getgenv().treestop or false
getgenv().doneend  = getgenv().doneend  or true
getgenv().startPosition = nil

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

-- ════════════════════════════════════════════════════
-- LONECAVE CUTTING (matches 1x1 cutter style)
-- Loops all WoodSections, uses faceVector(1,0,0) via ChopTree
-- ════════════════════════════════════════════════════
local function cutLoneCave(treeModel, axe, onFelled)
    -- Equip the axe via Character (ChopTree reads from Character:FindFirstChild("Tool"))
    player.Character.Humanoid:EquipTool(axe)
    task.wait(0.4)

    local ce = treeModel:FindFirstChild("CutEvent")
    if not ce then
        warn("[VanillaHub] LoneCave: no CutEvent found on tree model!")
        return
    end

    -- Collect all WoodSections
    local sections = {}
    for _, v in ipairs(treeModel:GetChildren()) do
        if v:IsA("BasePart") and v.Name == "WoodSection" then
            table.insert(sections, v)
        end
    end

    if #sections == 0 then
        warn("[VanillaHub] LoneCave: no WoodSections found!")
        return
    end

    print("[VanillaHub] LoneCave: found " .. #sections .. " sections, cutting...")

    -- Cut every section continuously until the tree fells (treeCut becomes true)
    local sectionIndex = 1
    repeat
        if not getgenv().treestop then break end

        local ws = sections[sectionIndex]
        -- Teleport next to the section
        if ws and ws.Parent then
            player.Character.HumanoidRootPart.CFrame =
                CFrame.new(ws.Position + Vector3.new(0, 2, -3))
            -- Use ChopTree style: sectionId = index, height = 1
            ChopTree(ce, sectionIndex, 1)
        end

        -- Advance through sections round-robin so all get hit
        sectionIndex = (sectionIndex % #sections) + 1
        task.wait()

    until getgenv().treeCut or not getgenv().treestop

    if onFelled then onFelled() end
end

local function bringTree(treeClass, returnCFrame, isFirstTree)
    getgenv().treestop = true
    getgenv().treeCut  = false

    if isFirstTree then
        getgenv().startPosition = returnCFrame or player.Character.HumanoidRootPart.CFrame
    end

    player.Character.Humanoid.BreakJointsOnDeath = false

    local success, axe = getBestAxe(treeClass)
    if not success or not axe then return false end

    -- For non-LoneCave trees equip via getTools path, LoneCave handled inside cutLoneCave
    if treeClass ~= "LoneCave" then
        player.Character.Humanoid:EquipTool(axe)
        task.wait(0.4)
    end

    local tree = getBiggestTree(treeClass)
    if not tree then warn("[VanillaHub] No "..treeClass.." tree found!"); return false end
    if not tree.trunk then warn("[VanillaHub] Tree trunk not found!"); return false end
    if treeClass ~= "LoneCave" and not (tree.trunk.Size.X >= 1 and tree.trunk.Size.Y >= 2 and tree.trunk.Size.Z >= 1) then
        warn("[VanillaHub] Tree too small, skipping.")
        return false
    end

    local destCFrame = returnCFrame or player.Character.HumanoidRootPart.CFrame

    task.wait(0.5)

    if not getgenv().treestop then
        if isFirstTree and getgenv().startPosition then
            player.Character.HumanoidRootPart.CFrame = getgenv().startPosition
        end
        return false
    end

    -- Listen for the felled log arriving in LogModels
    treeListener(treeClass, function(log)
        log.PrimaryPart = log:FindFirstChild("WoodSection")
        getgenv().treeCut = true
        for i = 1, 100 do
            if not getgenv().treestop then break end
            DragModel(log, destCFrame)
            task.wait()
        end
    end)

    task.wait(0.15)

    if treeClass == "LoneCave" then
        -- ── LoneCave: use ChopTree-style cutting across all sections ──
        cutLoneCave(tree.tree, axe, function()
            -- onFelled callback (treeCut flag already set by treeListener)
        end)

        -- Wait for treeCut or abort
        local timeout = 0
        repeat
            task.wait()
            timeout += task.wait()
        until getgenv().treeCut or not getgenv().treestop or timeout > 60

    else
        -- ── Normal trees: teleport to trunk + cutPart loop ──
        task.spawn(function()
            repeat
                if not getgenv().treestop then break end
                player.Character.HumanoidRootPart.CFrame = tree.trunk.CFrame
                task.wait()
            until getgenv().treeCut or not getgenv().treestop
        end)

        task.wait()

        repeat
            if not getgenv().treestop then break end
            cutPart(tree.tree.CutEvent, 1, 0.3, axe, treeClass)
            task.wait()
        until getgenv().treeCut or not getgenv().treestop
    end

    task.wait(1)
    getgenv().treeCut = false
    return true
end

-- ════════════════════════════════════════════════════
-- SELL POSITION + LAY-FLAT ROTATION
-- ════════════════════════════════════════════════════
local SELL_POS = Vector3.new(315.01, -0.40, 84.32)
local SELL_CF  = CFrame.new(SELL_POS) * CFrame.Angles(0, 0, math.rad(45))

-- ════════════════════════════════════════════════════
-- BRING ALL LOGS / SELL ALL LOGS  (with Abort support)
-- ════════════════════════════════════════════════════

local bringLogsRunning = false
local sellLogsRunning  = false
local logsAbort        = false
local logsStartPos     = nil

local function BringAllLogs(onDone)
    local OldPos  = logsStartPos or player.Character.HumanoidRootPart.CFrame
    local destCF  = OldPos
    local dragger = ReplicatedStorage:FindFirstChild("Interaction")
                    and ReplicatedStorage.Interaction:FindFirstChild("ClientIsDragging")
    local count   = 0

    for _, v in next, workspace.LogModels:GetChildren() do
        if logsAbort then break end
        if v:FindFirstChild("Owner") and v.Owner.Value == player then
            local ws = v:FindFirstChild("WoodSection")
            if ws then
                player.Character.HumanoidRootPart.CFrame = CFrame.new(ws.CFrame.p)
                task.wait(0.15)
                if not v.PrimaryPart then v.PrimaryPart = ws end
                local timeout = 0
                while not isnetworkowner(ws) and timeout < 2 do
                    if dragger then dragger:FireServer(v) end
                    task.wait(0.05)
                    timeout += 0.05
                end
                if dragger then dragger:FireServer(v) end
                v:SetPrimaryPartCFrame(destCF)
                count = count + 1
            end
        end
        task.wait(0.1)
    end

    pcall(function()
        player.Character.HumanoidRootPart.CFrame = OldPos
    end)
    print("[VanillaHub] Brought " .. count .. " logs.")
    if onDone then onDone() end
end

local function SellAllLogs(onDone)
    local OldPos  = logsStartPos or player.Character.HumanoidRootPart.CFrame
    local dragger = ReplicatedStorage:FindFirstChild("Interaction")
                    and ReplicatedStorage.Interaction:FindFirstChild("ClientIsDragging")
    local count   = 0

    for _, v in next, workspace.LogModels:GetChildren() do
        if logsAbort then break end
        if v:FindFirstChild("Owner") and v.Owner.Value == player then
            local ws = v:FindFirstChild("WoodSection")
            if ws then
                player.Character.HumanoidRootPart.CFrame = CFrame.new(ws.CFrame.p)
                task.wait(0.15)
                if not v.PrimaryPart then v.PrimaryPart = ws end
                local timeout = 0
                while not isnetworkowner(ws) and timeout < 2 do
                    if dragger then dragger:FireServer(v) end
                    task.wait(0.05)
                    timeout += 0.05
                end
                if dragger then dragger:FireServer(v) end
                v:SetPrimaryPartCFrame(SELL_CF)
                count = count + 1
            end
        end
        task.wait(0.1)
    end

    pcall(function()
        player.Character.HumanoidRootPart.CFrame = OldPos
    end)
    print("[VanillaHub] Sent " .. count .. " logs to the sell point.")
    if onDone then onDone() end
end

-- ════════════════════════════════════════════════════
-- 1x1 AUTO CUTTER
-- ════════════════════════════════════════════════════

local UnitCutter      = false
local cutterRunning   = false
local SelTree         = nil
local PlankReAdded    = nil
local UnitCutterClick = nil

local function PlrHasTool()
    return player.Backpack:FindFirstChildWhichIsA("Tool") ~= nil
        or player.Character:FindFirstChildWhichIsA("Tool") ~= nil
end

local function OneUnitCutter(enabled)
    UnitCutter = enabled

    if PlankReAdded    then pcall(function() PlankReAdded:Disconnect()    end); PlankReAdded    = nil end
    if UnitCutterClick then pcall(function() UnitCutterClick:Disconnect() end); UnitCutterClick = nil end

    if not enabled then
        cutterRunning = false
        SelTree       = nil
        print("[VanillaHub] 1x1 cutter disabled")
        return
    end

    print("[VanillaHub] 1x1 cutter enabled — click a WoodSection to start")

    PlankReAdded = workspace.PlayerModels.ChildAdded:Connect(function(v)
        if v:WaitForChild("WoodSection", 3) then
            if v:FindFirstChild("Owner") and v.Owner.Value == player then
                SelTree = v
            end
        end
    end)

    local Mouse = player:GetMouse()

    UnitCutterClick = Mouse.Button1Up:Connect(function()
        if not UnitCutter then return end
        if cutterRunning  then
            print("[VanillaHub] Already cutting! Toggle off then on to pick a new log.")
            return
        end

        local clicked = Mouse.Target
        if not clicked then return end

        local logModel = clicked.Parent
        while logModel and not (logModel:FindFirstChild("WoodSection") and logModel:FindFirstChild("Owner")) do
            logModel = logModel.Parent
        end
        if not logModel then return end

        local ownerVal = logModel:FindFirstChild("Owner")
        if not ownerVal or ownerVal.Value ~= player then
            print("[VanillaHub] That log isn't yours!")
            return
        end
        if not PlrHasTool() then
            print("[VanillaHub] Equip an axe first!")
            return
        end

        SelTree = logModel
        local savedPos = player.Character.HumanoidRootPart.CFrame
        cutterRunning  = true
        local swings   = 0

        task.spawn(function()
            local function findBestAxe()
                local candidates = {}
                for _, v in ipairs(player.Backpack:GetChildren()) do
                    if v:FindFirstChild("ToolName") then
                        local dmg = HitPoints[v.ToolName.Value] or 0
                        table.insert(candidates, {tool = v, dmg = dmg})
                    end
                end
                local equipped = player.Character:FindFirstChildWhichIsA("Tool")
                if equipped and equipped:FindFirstChild("ToolName") then
                    local dmg = HitPoints[equipped.ToolName.Value] or 0
                    table.insert(candidates, {tool = equipped, dmg = dmg})
                end
                if #candidates == 0 then return nil end
                table.sort(candidates, function(a, b) return a.dmg > b.dmg end)
                return candidates[1].tool
            end

            local axe = findBestAxe()
            if axe then
                if player.Character:FindFirstChildWhichIsA("Tool") ~= axe then
                    player.Character.Humanoid:EquipTool(axe)
                    task.wait(0.35)
                end
            else
                warn("[VanillaHub] No axe found — equip one and try again")
                cutterRunning = false
                SelTree = nil
                return
            end

            repeat
                if not UnitCutter then break end
                if not SelTree or not SelTree.Parent then break end

                local ws = SelTree:FindFirstChild("WoodSection")
                if not ws then break end

                player.Character:MoveTo(ws.Position + Vector3.new(0, 3, -3))

                local ce = SelTree:FindFirstChild("CutEvent")
                if ce then
                    ChopTree(ce, 1, 1)
                end

                swings += 1
                task.wait()

            until not UnitCutter
                or not SelTree
                or not SelTree.Parent
                or not SelTree:FindFirstChild("WoodSection")
                or (
                    SelTree.WoodSection.Size.X <= 2.5
                    and SelTree.WoodSection.Size.Y <= 2.5
                    and SelTree.WoodSection.Size.Z <= 2.5
                )

            pcall(function()
                player.Character.HumanoidRootPart.CFrame = savedPos
            end)

            print("[VanillaHub] Done! " .. swings .. " swings.")
            cutterRunning = false
            SelTree       = nil
        end)
    end)
end

-- Sawmill helpers
local ModWoodSawmill = nil

local function SelectSawmill(onSelected)
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
    SelectSawmill(function()
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

local function ModWood()
    print("[VanillaHub] ModWood: click your sawmill first.")
    SelectSawmill(function()
        print("[VanillaHub] ModWood: sawmill selected. Now click the wood piece to cut.")
        local Mouse = player:GetMouse()
        local modConn
        modConn = Mouse.Button1Down:Connect(function()
            local Clicked = Mouse.Target
            if Clicked and Clicked.Parent:FindFirstAncestor("LogModels") then
                if Clicked.Parent:FindFirstChild("Owner") and Clicked.Parent.Owner.Value == player then
                    modConn:Disconnect()
                    print("[VanillaHub] ModWood: processing...")
                end
            end
        end)
    end)
end

local function DismemberTree()
    local OldPos        = player.Character.HumanoidRootPart.CFrame
    local LogChopped    = false
    local TreeToJointCut= nil
    local Mouse         = player:GetMouse()

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
-- CLICK SELL (instant lay-flat)
-- ════════════════════════════════════════════════════

local clickSellEnabled  = false
local clickSellConn     = nil
local clickSellCooldown = false

local function doClickSell(logModel)
    local ws = logModel:FindFirstChild("WoodSection")
    if not ws then return end

    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local dragger = ReplicatedStorage:FindFirstChild("Interaction")
                    and ReplicatedStorage.Interaction:FindFirstChild("ClientIsDragging")

    local oldPos = hrp.CFrame

    hrp.CFrame = CFrame.new(ws.CFrame.p) * CFrame.new(4, 0, 0)
    task.wait(0.15)

    if not logModel.PrimaryPart then logModel.PrimaryPart = ws end

    local timeout = 0
    while not isnetworkowner(ws) and timeout < 3 do
        if dragger then dragger:FireServer(logModel) end
        task.wait(0.05)
        timeout += 0.05
    end
    if dragger then dragger:FireServer(logModel) end

    logModel:SetPrimaryPartCFrame(SELL_CF)

    task.wait(0.05)
    hrp.CFrame = oldPos
end

local function enableClickSell(val)
    clickSellEnabled = val

    if clickSellConn then
        pcall(function() clickSellConn:Disconnect() end)
        clickSellConn = nil
    end

    if not val then
        print("[VanillaHub] Click Sell disabled")
        return
    end

    print("[VanillaHub] Click Sell enabled — click a log to sell it instantly")

    local Mouse = player:GetMouse()

    clickSellConn = Mouse.Button1Up:Connect(function()
        if not clickSellEnabled then return end
        if clickSellCooldown    then return end

        local clicked = Mouse.Target
        if not clicked then return end

        local logModel = clicked.Parent
        while logModel and not (logModel:FindFirstChild("WoodSection") and logModel:FindFirstChild("Owner")) do
            logModel = logModel.Parent
        end
        if not logModel then return end

        local ownerVal = logModel:FindFirstChild("Owner")
        if not ownerVal or ownerVal.Value ~= player then
            print("[VanillaHub] That log isn't yours!")
            return
        end

        clickSellCooldown = true
        task.spawn(function()
            doClickSell(logModel)
            task.wait(0.8)
            clickSellCooldown = false
        end)
    end)
end

table.insert(cleanupTasks, function()
    enableClickSell(false)
end)

-- ════════════════════════════════════════════════════
-- WOOD TAB — CLEAN LAYOUT
-- ════════════════════════════════════════════════════

local woodPage = pages["WoodTab"]

for _, child in ipairs(woodPage:GetChildren()) do
    if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
        child:Destroy()
    end
end

-- ── 1. TREE SELECTOR ────────────────────────────────
local TREE_LIST = {
    "Generic","Walnut","Cherry","SnowGlow","Oak","Birch","Koa","Fir",
    "Volcano","GreenSwampy","CaveCrawler","Palm","GoldSwampy","Frost",
    "Spooky","SpookyNeon","LoneCave",
}

local selectedTree   = "Generic"
local treeDropIsOpen = false
local TD_HEADER_H    = 42
local TD_ITEM_H      = 34
local TD_MAX_SHOW    = 6

sectionLabel(woodPage, "Tree Selection")

local treeDropOuter = Instance.new("Frame", woodPage)
treeDropOuter.Size             = UDim2.new(1, 0, 0, TD_HEADER_H)
treeDropOuter.BackgroundColor3 = C.CARD
treeDropOuter.BorderSizePixel  = 0
treeDropOuter.ClipsDescendants = true
corner(treeDropOuter, 9)

local treeDropHeader = Instance.new("Frame", treeDropOuter)
treeDropHeader.Size                  = UDim2.new(1, 0, 0, TD_HEADER_H)
treeDropHeader.BackgroundTransparency = 1

local treeDropLbl = Instance.new("TextLabel", treeDropHeader)
treeDropLbl.Size               = UDim2.new(0, 70, 1, 0)
treeDropLbl.Position           = UDim2.new(0, 12, 0, 0)
treeDropLbl.BackgroundTransparency = 1
treeDropLbl.Text               = "Tree"
treeDropLbl.Font               = Enum.Font.GothamBold
treeDropLbl.TextSize           = 12
treeDropLbl.TextColor3         = C.TEXT
treeDropLbl.TextXAlignment     = Enum.TextXAlignment.Left

local treeSelFrame = Instance.new("Frame", treeDropHeader)
treeSelFrame.Size             = UDim2.new(1, -88, 0, 28)
treeSelFrame.Position         = UDim2.new(0, 80, 0.5, -14)
treeSelFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
treeSelFrame.BorderSizePixel  = 0
corner(treeSelFrame, 7)

local treeSelLbl = Instance.new("TextLabel", treeSelFrame)
treeSelLbl.Size              = UDim2.new(1, -32, 1, 0)
treeSelLbl.Position          = UDim2.new(0, 10, 0, 0)
treeSelLbl.BackgroundTransparency = 1
treeSelLbl.Text              = "Generic"
treeSelLbl.Font              = Enum.Font.GothamSemibold
treeSelLbl.TextSize          = 12
treeSelLbl.TextColor3        = C.TEXT
treeSelLbl.TextXAlignment    = Enum.TextXAlignment.Left

local treeArrowLbl = Instance.new("TextLabel", treeSelFrame)
treeArrowLbl.Size              = UDim2.new(0, 22, 1, 0)
treeArrowLbl.Position          = UDim2.new(1, -24, 0, 0)
treeArrowLbl.BackgroundTransparency = 1
treeArrowLbl.Text              = "v"
treeArrowLbl.Font              = Enum.Font.GothamBold
treeArrowLbl.TextSize          = 11
treeArrowLbl.TextColor3        = C.TEXT_MID

local treeHeaderBtn = Instance.new("TextButton", treeSelFrame)
treeHeaderBtn.Size              = UDim2.new(1, 0, 1, 0)
treeHeaderBtn.BackgroundTransparency = 1
treeHeaderBtn.Text              = ""

local treeDropDivider = Instance.new("Frame", treeDropOuter)
treeDropDivider.Size             = UDim2.new(1, -14, 0, 1)
treeDropDivider.Position         = UDim2.new(0, 7, 0, TD_HEADER_H)
treeDropDivider.BackgroundColor3 = C.BORDER
treeDropDivider.BorderSizePixel  = 0
treeDropDivider.Visible          = false

local treeListScroll = Instance.new("ScrollingFrame", treeDropOuter)
treeListScroll.Position               = UDim2.new(0, 0, 0, TD_HEADER_H + 2)
treeListScroll.Size                   = UDim2.new(1, 0, 0, 0)
treeListScroll.BackgroundTransparency = 1
treeListScroll.BorderSizePixel        = 0
treeListScroll.ScrollBarThickness     = 3
treeListScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
treeListScroll.ClipsDescendants       = true

local treeListLayout = Instance.new("UIListLayout", treeListScroll)
treeListLayout.SortOrder = Enum.SortOrder.LayoutOrder
treeListLayout.Padding   = UDim.new(0, 3)
treeListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    treeListScroll.CanvasSize = UDim2.new(0, 0, 0, treeListLayout.AbsoluteContentSize.Y + 8)
end)

local function treeCloseList()
    treeDropIsOpen = false
    TweenService:Create(treeArrowLbl,   TweenInfo.new(0.18, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
    TweenService:Create(treeDropOuter,  TweenInfo.new(0.20, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, TD_HEADER_H)}):Play()
    TweenService:Create(treeListScroll, TweenInfo.new(0.20, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, 0)}):Play()
    treeDropDivider.Visible = false
end

local function treeBuildList()
    for _, c in ipairs(treeListScroll:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
    end
    for i, treeName in ipairs(TREE_LIST) do
        local row = Instance.new("Frame", treeListScroll)
        row.Size             = UDim2.new(1, 0, 0, TD_ITEM_H)
        row.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        row.BorderSizePixel  = 0
        row.LayoutOrder      = i
        corner(row, 7)
        local rowLbl = Instance.new("TextLabel", row)
        rowLbl.Size               = UDim2.new(1, -16, 1, 0)
        rowLbl.Position           = UDim2.new(0, 12, 0, 0)
        rowLbl.BackgroundTransparency = 1
        rowLbl.Text               = treeName
        rowLbl.Font               = Enum.Font.GothamSemibold
        rowLbl.TextSize           = 12
        rowLbl.TextColor3         = treeName == selectedTree and C.ACCENT or C.TEXT
        rowLbl.TextXAlignment     = Enum.TextXAlignment.Left
        local rowBtn = Instance.new("TextButton", row)
        rowBtn.Size               = UDim2.new(1, 0, 1, 0)
        rowBtn.BackgroundTransparency = 1
        rowBtn.Text               = ""
        rowBtn.AutoButtonColor    = false
        rowBtn.MouseButton1Click:Connect(function()
            selectedTree    = treeName
            treeSelLbl.Text = treeName
            treeCloseList()
        end)
    end
end

local function treeOpenList()
    treeDropIsOpen = true
    treeBuildList()
    local listH = math.min(#TREE_LIST, TD_MAX_SHOW) * (TD_ITEM_H + 3) + 10
    treeDropDivider.Visible = true
    TweenService:Create(treeArrowLbl,   TweenInfo.new(0.18, Enum.EasingStyle.Quint), {Rotation = 180}):Play()
    TweenService:Create(treeDropOuter,  TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, TD_HEADER_H + 2 + listH)}):Play()
    TweenService:Create(treeListScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, listH)}):Play()
end

treeHeaderBtn.MouseButton1Click:Connect(function()
    if treeDropIsOpen then treeCloseList() else treeOpenList() end
end)

-- Amount slider
local treeAmount = 1
makeSlider(woodPage, "Amount", 1, 50, 1, function(v) treeAmount = v end)

-- Bring Tree / Abort toggle button
local bringTreeActive = false
local bringTreeBtn = makeBtn(woodPage, "Bring Tree", nil)

bringTreeBtn.MouseButton1Click:Connect(function()
    if bringTreeActive then
        bringTreeActive = false
        getgenv().treestop = false
        getgenv().treeCut  = false
        if getgenv().startPosition then
            pcall(function()
                player.Character.HumanoidRootPart.CFrame = getgenv().startPosition
            end)
            getgenv().startPosition = nil
        end
        bringTreeBtn.Text = "Bring Tree"
        print("[VanillaHub] Aborted.")
    else
        if not selectedTree or selectedTree == "" then
            warn("[VanillaHub] Select a tree first!") return
        end
        if not hasSingleAxe() then return end
        bringTreeActive = true
        bringTreeBtn.Text = "Abort"
        task.spawn(function()
            local homeCFrame = player.Character.HumanoidRootPart.CFrame
            getgenv().treestop      = true
            getgenv().startPosition = homeCFrame
            if selectedTree == "LoneCave" then
                bringTree(selectedTree, homeCFrame, true)
            else
                for i = 1, treeAmount do
                    if not getgenv().treestop then break end
                    bringTree(selectedTree, homeCFrame, i == 1)
                    if i < treeAmount then task.wait(0.8) end
                end
            end
            if getgenv().treestop and getgenv().startPosition then
                player.Character.HumanoidRootPart.CFrame = getgenv().startPosition
            end
            getgenv().treestop      = false
            getgenv().startPosition = nil
            bringTreeActive   = false
            bringTreeBtn.Text = "Bring Tree"
        end)
    end
end)

-- ── Options (mutually exclusive toggles) ────────────────────────────────────
sepLine(woodPage)
sectionLabel(woodPage, "Options")

local optionSetters = {}

local function disableAllOptions(except)
    for name, setter in pairs(optionSetters) do
        if name ~= except then
            setter(false)
        end
    end
end

local _, setClickSell = makeToggle(woodPage, "Click Sell", false, function(val)
    if val then disableAllOptions("clickSell") end
    enableClickSell(val)
end)
optionSetters["clickSell"] = function(v)
    setClickSell(v)
    enableClickSell(v)
end

local _, set1x1 = makeToggle(woodPage, "1x1 Cutter", false, function(val)
    if val then disableAllOptions("1x1") end
    OneUnitCutter(val)
end)
optionSetters["1x1"] = function(v)
    set1x1(v)
    OneUnitCutter(v)
end

local _, setViewLone = makeToggle(woodPage, "View LoneCave Tree", false, function(val)
    if val then disableAllOptions("viewLone") end
    ViewEndTree(val)
end)
optionSetters["viewLone"] = function(v)
    setViewLone(v)
    ViewEndTree(v)
end

-- ── Logs (Bring All / Sell All with Abort + return to start) ─────────────────
sepLine(woodPage)
sectionLabel(woodPage, "Logs")

local logsRow, bringAllBtn, sellAllBtn = makeBtnPair(woodPage,
    "Bring All Logs", "Sell All Logs",
    nil, nil
)

local function resetLogBtns()
    bringLogsRunning = false
    sellLogsRunning  = false
    logsAbort        = false
    bringAllBtn.Text = "Bring All Logs"
    sellAllBtn.Text  = "Sell All Logs"
end

bringAllBtn.MouseButton1Click:Connect(function()
    if bringLogsRunning then
        logsAbort = true
        print("[VanillaHub] Bring All Logs aborted.")
        return
    end
    if sellLogsRunning then return end

    logsStartPos     = player.Character.HumanoidRootPart.CFrame
    bringLogsRunning = true
    logsAbort        = false
    bringAllBtn.Text = "Abort"

    task.spawn(function()
        BringAllLogs(function()
            resetLogBtns()
        end)
    end)
end)

sellAllBtn.MouseButton1Click:Connect(function()
    if sellLogsRunning then
        logsAbort = true
        print("[VanillaHub] Sell All Logs aborted.")
        return
    end
    if bringLogsRunning then return end

    logsStartPos    = player.Character.HumanoidRootPart.CFrame
    sellLogsRunning = true
    logsAbort       = false
    sellAllBtn.Text = "Abort"

    task.spawn(function()
        SellAllLogs(function()
            resetLogBtns()
        end)
    end)
end)

-- ── Tools ─────────────────────────────────────────────────────────────────────
sepLine(woodPage)
sectionLabel(woodPage, "Tools")

makeBtnPair(woodPage,
    "Get Tools Fix", "Drop All Tools",
    function() GetToolsfix()         end,
    function() task.spawn(DropTools) end
)

-- ════════════════════════════════════════════════════
-- SETTINGS TAB
-- ════════════════════════════════════════════════════

local keybindButtonGUI
local settingsPage = pages["SettingsTab"]

local kbFrame = Instance.new("Frame", settingsPage)
kbFrame.Size             = UDim2.new(1, 0, 0, 70)
kbFrame.BackgroundColor3 = C.CARD
kbFrame.BorderSizePixel  = 0
corner(kbFrame, 10)
stroke(kbFrame, C.BORDER, 1, 0.4)

local kbTitle = Instance.new("TextLabel", kbFrame)
kbTitle.Size               = UDim2.new(1, -20, 0, 28)
kbTitle.Position           = UDim2.new(0, 10, 0, 8)
kbTitle.BackgroundTransparency = 1
kbTitle.Font               = Enum.Font.GothamBold
kbTitle.TextSize           = 15
kbTitle.TextColor3         = C.TEXT
kbTitle.TextXAlignment     = Enum.TextXAlignment.Left
kbTitle.Text               = "GUI Toggle Keybind"

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
    if UnitCutter then OneUnitCutter(false) end
    if PlankReAdded    then pcall(function() PlankReAdded:Disconnect()    end); PlankReAdded    = nil end
    if UnitCutterClick then pcall(function() UnitCutterClick:Disconnect() end); UnitCutterClick = nil end
    getgenv().treestop      = false
    getgenv().treeCut       = false
    getgenv().startPosition = nil
    logsAbort = true
end)

_G.VH.keybindButtonGUI = keybindButtonGUI

print("[VanillaHub] Vanilla3 loaded!")
print("[VanillaHub] LoneCave: cuts all WoodSections using ChopTree-style (faceVector 1,0,0).")
print("[VanillaHub] Click Sell / Sell All → instant lay-flat at sell position.")
print("[VanillaHub] Abort → teleports back to start position.")
print("[VanillaHub] Options toggles are mutually exclusive.")
print("[VanillaHub] Bring/Sell All Logs → Abort mid-run + return to start.")
