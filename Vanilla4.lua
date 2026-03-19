-- ════════════════════════════════════════════════════
-- VANILLA4 — AutoBuy Tab
-- Execute AFTER Vanilla1, Vanilla2, Vanilla3
-- Dialog & counter logic sourced from Butterhub leaked src
-- ════════════════════════════════════════════════════

if not _G.VH then
    warn("[VanillaHub] Vanilla4: _G.VH not found. Execute Vanilla1 first.")
    return
end

local TweenService     = _G.VH.TweenService
local player           = _G.VH.player
local cleanupTasks     = _G.VH.cleanupTasks
local pages            = _G.VH.pages

local RS = game:GetService("ReplicatedStorage")

-- ════════════════════════════════════════════════════
-- THEME
-- ════════════════════════════════════════════════════
local C = {
    CARD        = Color3.fromRGB(16,  16,  16),
    BTN         = Color3.fromRGB(14,  14,  14),
    BTN_HV      = Color3.fromRGB(32,  32,  32),
    BG_ROW      = Color3.fromRGB(22,  22,  22),
    BG_INPUT    = Color3.fromRGB(32,  32,  32),
    BORDER      = Color3.fromRGB(55,  55,  55),
    BORDER_FOC  = Color3.fromRGB(100, 100, 100),
    TEXT        = Color3.fromRGB(210, 210, 210),
    TEXT_MID    = Color3.fromRGB(155, 155, 155),
    TEXT_DIM    = Color3.fromRGB(90,  90,  90),
    TEXT_WHITE  = Color3.fromRGB(240, 240, 240),
}

local autoBuyPage = pages["AutoBuyTab"]
if not autoBuyPage then
    warn("[VanillaHub] Vanilla4: AutoBuyTab page not found.")
    return
end

-- ════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════
local AB_aborted     = false
local AB_buying      = false
local AB_amount      = 10
local AB_item        = nil
local AB_isBlueprint = false
local AB_statusLbl   = nil
local AB_progLbl     = nil
local AB_startBtn    = nil
local AB_stopBtn     = nil

-- ════════════════════════════════════════════════════
-- SHOP ID MAP  (from Butterhub source — counter parent name → dialog ID)
-- ════════════════════════════════════════════════════
local ShopIDS = {
    ["WoodRUs"]       = 7,
    ["FurnitureStore"] = 8,
    ["FineArt"]       = 11,
    ["CarStore"]      = 9,
    ["LogicStore"]    = 12,
    ["ShackShop"]     = 10,
}

local AB_Services = {
    { label="Toll Bridge",   char="Seranok",     id=7,  wConfirm=0.85, wEnd=0.45              },
    { label="Ferry Ticket",  char="Hoover",      id=15, wConfirm=0.85, wEnd=0.45              },
    { label="Power of Ease", char="Strange Man", id=6,  wConfirm=0.85, wEnd=0.45, wFinal=true },
}

-- ════════════════════════════════════════════════════
-- CORE HELPERS  (from Butterhub)
-- ════════════════════════════════════════════════════
local function tw(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.18, Enum.EasingStyle.Quint), props):Play()
end

local function setStatus(msg, active)
    if AB_statusLbl and AB_statusLbl.Parent then
        AB_statusLbl.Text       = msg
        AB_statusLbl.TextColor3 = active and C.TEXT or C.TEXT_DIM
    end
end

local function setProgress(cur, total)
    if AB_progLbl and AB_progLbl.Parent then
        if cur and total then
            AB_progLbl.Text    = cur .. " / " .. total
            AB_progLbl.Visible = true
        else
            AB_progLbl.Visible = false
        end
    end
end

local function refreshActionButtons()
    if AB_startBtn and AB_startBtn.Parent then
        local canStart = AB_item ~= nil and not AB_buying
        AB_startBtn.TextColor3       = canStart and C.TEXT   or C.TEXT_DIM
        AB_startBtn.BackgroundColor3 = canStart and C.BTN_HV or C.BTN
    end
    if AB_stopBtn and AB_stopBtn.Parent then
        AB_stopBtn.TextColor3       = AB_buying and C.TEXT   or C.TEXT_DIM
        AB_stopBtn.BackgroundColor3 = AB_buying and C.BG_ROW or C.BTN
    end
end

local function isnetworkowner(part)
    local ok, res = pcall(function() return part.ReceiveAge end)
    return ok and res == 0
end

-- Rename shop items so WaitForChild works correctly (Butterhub: UpdateNames)
local function updateNames()
    pcall(function()
        for _, store in next, workspace.Stores:GetChildren() do
            if store.Name == "ShopItems" then
                store.ChildAdded:Connect(function(child)
                    pcall(function()
                        child.Name = child:WaitForChild("BoxItemName", 5).Value
                    end)
                end)
                for _, item in next, store:GetChildren() do
                    pcall(function()
                        local own = item:FindFirstChild("Owner")
                        local bin = item:FindFirstChild("BoxItemName")
                        if own and own.Value == nil and bin then
                            item.Name = bin.Value
                        end
                    end)
                end
            end
        end
    end)
end
updateNames()

-- Find the ShopItems folder that contains a given item name (Butterhub: ItemPath)
local function itemPath(itemName)
    for _, store in next, workspace.Stores:GetChildren() do
        if store.Name == "ShopItems" then
            for _, item in next, store:GetChildren() do
                local own = item:FindFirstChild("Owner")
                local bin = item:FindFirstChild("BoxItemName")
                if own and own.Value == nil and bin and bin.Value == itemName then
                    return store   -- return the ShopItems folder
                end
            end
        end
    end
    return nil
end

-- Find nearest counter part to an item's Main (Butterhub: GetCounter, 200-stud radius)
local function getCounter(mainPart)
    local best, bestDist = nil, math.huge
    for _, store in next, workspace.Stores:GetChildren() do
        if store.Name:lower() ~= "shopitems" then
            for _, child in next, store:GetChildren() do
                if child.Name:lower() == "counter" and child:IsA("BasePart") then
                    local d = (mainPart.CFrame.p - child.CFrame.p).Magnitude
                    if d <= 200 and d < bestDist then
                        bestDist = d
                        best     = child
                    end
                end
            end
        end
    end
    return best
end

-- Fire the purchase dialog (Butterhub: Pay — uses NPCDialog.PlayerChatted, not PlayerChatted)
-- counterParentName is the store folder name (e.g. "WoodRUs", "ShackShop")
local function pay(counterParentName)
    local id = ShopIDS[counterParentName]
    if not id then return end
    local NPCDialog = RS:FindFirstChild("NPCDialog")
    if not NPCDialog then return end
    local PC = NPCDialog:FindFirstChild("PlayerChatted")
    if not PC then return end
    PC:InvokeServer(
        { ["ID"]=id, ["Character"]="name", ["Name"]="name", ["Dialog"]="Dialog" },
        "ConfirmPurchase"
    )
end

-- ════════════════════════════════════════════════════
-- ITEM DATA
-- ════════════════════════════════════════════════════
local function getPrice(itemName)
    local price = 0
    pcall(function()
        for _, v in next, RS:WaitForChild("ClientItemInfo", 5):GetDescendants() do
            if v.Name == itemName and v:FindFirstChild("Price") then
                price = v.Price.Value; break
            end
        end
    end)
    return price
end

local function grabAllItems()
    local list, seen = {}, {}
    pcall(function()
        for _, store in next, workspace.Stores:GetChildren() do
            if store.Name ~= "ShopItems" then continue end
            for _, item in next, store:GetChildren() do
                local bin = item:FindFirstChild("BoxItemName")
                local typ = item:FindFirstChild("Type")
                if bin and not seen[bin.Value] then
                    seen[bin.Value] = true
                    table.insert(list, {
                        name        = bin.Value,
                        price       = getPrice(bin.Value),
                        isBlueprint = typ and typ.Value == "Blueprint",
                    })
                end
            end
        end
        table.sort(list, function(a, b) return a.name < b.name end)
    end)
    return list
end

local function grabBlueprintNames()
    local list, seen = {}, {}
    pcall(function()
        for _, store in next, workspace.Stores:GetChildren() do
            if store.Name ~= "ShopItems" then continue end
            for _, item in next, store:GetChildren() do
                local bin = item:FindFirstChild("BoxItemName")
                local typ = item:FindFirstChild("Type")
                if bin and typ and typ.Value == "Blueprint" and not seen[bin.Value] then
                    seen[bin.Value] = true
                    table.insert(list, bin.Value)
                end
            end
        end
    end)
    return list
end

-- ════════════════════════════════════════════════════
-- OPEN BOX HELPER
-- ════════════════════════════════════════════════════
local function openBoxFor(item)
    -- item is the Model in ShopItems
    pcall(function()
        RS.Interaction.ClientInteracted:FireServer(item, "Open box")
    end)
end

-- ════════════════════════════════════════════════════
-- BUY LOOP  (logic from Butterhub AutoBuy)
-- ════════════════════════════════════════════════════
local function AB_buy(itemName, amount, isBlueprint, isBatch)
    if not itemName then setStatus("No item selected.", false); return end
    if not isBatch then
        AB_aborted = false; AB_buying = true
        setProgress(0, amount)
        refreshActionButtons()
    end

    local Dragging = RS.Interaction and RS.Interaction:FindFirstChild("ClientIsDragging")

    local char = player.Character
    if not (char and char:FindFirstChild("HumanoidRootPart")) then
        if not isBatch then AB_buying = false; refreshActionButtons() end
        return
    end
    local OldPos = char.HumanoidRootPart.CFrame

    -- find which ShopItems folder holds this item
    local path = itemPath(itemName)
    if not path then
        setStatus("Item not found in any store.", false)
        if not isBatch then AB_buying = false; refreshActionButtons() end
        return
    end

    for i = 1, amount do
        if AB_aborted then break end

        setStatus("Waiting for " .. itemName .. "...", true)

        -- WaitForChild with timeout (Butterhub uses WaitForChild on the ShopItems folder)
        local item = nil
        local deadline = tick() + 20
        repeat
            if AB_aborted then break end
            pcall(function() item = path:FindFirstChild(itemName) end)
            if not item then task.wait(0.1) end
        until item or tick() > deadline

        if not item then
            setStatus("'" .. itemName .. "' not found - timed out.", false); break
        end
        if AB_aborted then break end

        local main = item:FindFirstChild("Main")
        if not main then setStatus("Missing Main part.", false); break end

        local counter = getCounter(main)
        if not counter then setStatus("No counter found near item.", false); break end

        local counterParentName = counter.Parent.Name

        -- Step 1: TP to item, grab it (Butterhub: TP + drag until owner set)
        setStatus("Buying " .. itemName .. "...", true)
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then break end

        hrp.CFrame = main.CFrame + Vector3.new(5, 0, 5)

        -- Wait until we own it
        local ownDeadline = tick() + 8
        repeat
            if AB_aborted then break end
            pcall(function() if Dragging then Dragging:FireServer(item) end end)
            task.wait(0.016)
        until (item:FindFirstChild("Owner") and item.Owner.Value ~= nil) or tick() > ownDeadline

        if AB_aborted then break end
        if item:FindFirstChild("Owner") and item.Owner.Value ~= player then break end

        -- Wait for network ownership
        local netDeadline = tick() + 8
        repeat
            if AB_aborted then break end
            pcall(function() if Dragging then Dragging:FireServer(item) end end)
            task.wait(0.016)
        until isnetworkowner(main) or tick() > netDeadline

        -- Step 2: Move item to counter
        pcall(function()
            if Dragging then Dragging:FireServer(item) end
            main.CFrame = counter.CFrame + Vector3.new(0, main.Size.Y, 0.5)
        end)
        task.wait(0.05)

        -- Step 3: TP player to counter
        hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = counter.CFrame + Vector3.new(5, 0, 5)
        end
        task.wait(0.05)

        -- Step 4: Pay loop until item leaves ShopItems (Butterhub pattern)
        local payDeadline = tick() + 10
        repeat
            if AB_aborted then break end
            pcall(function() if Dragging then Dragging:FireServer(item) end end)
            pay(counterParentName)
            task.wait(0.016)
        until item.Parent ~= path or tick() > payDeadline

        if AB_aborted then break end

        -- Step 5: Reclaim item, move to OldPos
        pcall(function()
            local reclaimDeadline = tick() + 6
            repeat
                if Dragging then Dragging:FireServer(item) end
                task.wait(0.016)
            until isnetworkowner(main) or tick() > reclaimDeadline
            if Dragging then Dragging:FireServer(item) end
            main.CFrame = OldPos
        end)
        task.wait(0.05)

        -- Step 6: Return player
        hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = OldPos + Vector3.new(5, 1, 0) end

        -- Step 7: Open box for blueprints
        if isBlueprint then
            task.wait(0.2)
            pcall(function() openBoxFor(item) end)
        end

        task.wait(0.1)

        if not isBatch then
            setProgress(i, amount)
            setStatus("Bought " .. i .. " / " .. amount, true)
        end
    end

    if not isBatch then
        AB_buying = false
        setProgress(nil)
        setStatus(AB_aborted and "Stopped." or "Done!", false)
        refreshActionButtons()
    end
end

-- ════════════════════════════════════════════════════
-- UI HELPERS
-- ════════════════════════════════════════════════════
local function mkLabel(text)
    local lbl = Instance.new("TextLabel", autoBuyPage)
    lbl.Size               = UDim2.new(1, -12, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 10
    lbl.TextColor3         = C.TEXT_DIM
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = "  " .. string.upper(text)
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 4)
end

local function mkSep()
    local s = Instance.new("Frame", autoBuyPage)
    s.Size             = UDim2.new(1, -12, 0, 1)
    s.BackgroundColor3 = C.BORDER
    s.BorderSizePixel  = 0
end

local function mkBtn(text, cb)
    local btn = Instance.new("TextButton", autoBuyPage)
    btn.Size             = UDim2.new(1, -12, 0, 34)
    btn.BackgroundColor3 = C.BTN
    btn.Text             = text
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.TextColor3       = C.TEXT
    btn.BorderSizePixel  = 0
    btn.AutoButtonColor  = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = C.BORDER; stroke.Thickness = 1; stroke.Transparency = 0
    btn.MouseEnter:Connect(function() tw(btn, { BackgroundColor3 = C.BTN_HV }) end)
    btn.MouseLeave:Connect(function() tw(btn, { BackgroundColor3 = C.BTN   }) end)
    if cb then btn.MouseButton1Click:Connect(cb) end
    return btn
end

local function mkNumberInput(text, minV, maxV, defV, cb)
    local fr = Instance.new("Frame", autoBuyPage)
    fr.Size             = UDim2.new(1, -12, 0, 40)
    fr.BackgroundColor3 = C.CARD
    fr.BorderSizePixel  = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", fr)
    lbl.Size               = UDim2.new(1, -130, 1, 0)
    lbl.Position           = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = text
    lbl.Font               = Enum.Font.GothamSemibold
    lbl.TextSize           = 13
    lbl.TextColor3         = C.TEXT
    lbl.TextXAlignment     = Enum.TextXAlignment.Left

    local function makeArrow(xOff, label)
        local b = Instance.new("TextButton", fr)
        b.Size             = UDim2.new(0, 28, 0, 28)
        b.Position         = UDim2.new(1, xOff, 0.5, -14)
        b.BackgroundColor3 = C.BTN
        b.Text             = label
        b.Font             = Enum.Font.GothamBold
        b.TextSize         = 16
        b.TextColor3       = C.TEXT
        b.BorderSizePixel  = 0
        b.AutoButtonColor  = false
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        local s = Instance.new("UIStroke", b)
        s.Color = C.BORDER; s.Thickness = 1; s.Transparency = 0
        b.MouseEnter:Connect(function() tw(b, { BackgroundColor3 = C.BTN_HV }) end)
        b.MouseLeave:Connect(function() tw(b, { BackgroundColor3 = C.BTN   }) end)
        return b
    end

    local minusBtn = makeArrow(-122, "-")
    local plusBtn  = makeArrow(-30,  "+")

    local box = Instance.new("TextBox", fr)
    box.Size             = UDim2.new(0, 56, 0, 28)
    box.Position         = UDim2.new(1, -90, 0.5, -14)
    box.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    box.BorderSizePixel  = 0
    box.Font             = Enum.Font.GothamBold
    box.TextSize         = 14
    box.TextColor3       = C.TEXT
    box.Text             = tostring(defV)
    box.ClearTextOnFocus = false
    box.TextXAlignment   = Enum.TextXAlignment.Center
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    local bs = Instance.new("UIStroke", box)
    bs.Color = C.BORDER; bs.Thickness = 1; bs.Transparency = 0.4

    local curVal = defV
    local function applyVal(v)
        curVal   = math.clamp(math.floor(tonumber(v) or minV), minV, maxV)
        box.Text = tostring(curVal)
        if cb then cb(curVal) end
    end
    minusBtn.MouseButton1Click:Connect(function() applyVal(curVal - 1) end)
    plusBtn.MouseButton1Click:Connect(function()  applyVal(curVal + 1) end)
    box.FocusLost:Connect(function() applyVal(box.Text) end)
    box:GetPropertyChangedSignal("Text"):Connect(function()
        local clean = box.Text:gsub("[^%d]", "")
        if clean ~= box.Text then box.Text = clean end
    end)
end

-- ════════════════════════════════════════════════════
-- STATUS BAR
-- ════════════════════════════════════════════════════
local statusCard = Instance.new("Frame", autoBuyPage)
statusCard.Size             = UDim2.new(1, -12, 0, 38)
statusCard.BackgroundColor3 = C.CARD
statusCard.BorderSizePixel  = 0
Instance.new("UICorner", statusCard).CornerRadius = UDim.new(0, 6)
local scStroke = Instance.new("UIStroke", statusCard)
scStroke.Color = C.BORDER; scStroke.Thickness = 1; scStroke.Transparency = 0.3

local statusLbl = Instance.new("TextLabel", statusCard)
statusLbl.Size               = UDim2.new(1, -80, 1, 0)
statusLbl.Position           = UDim2.new(0, 10, 0, 0)
statusLbl.BackgroundTransparency = 1
statusLbl.Font               = Enum.Font.GothamSemibold
statusLbl.TextSize           = 12
statusLbl.TextColor3         = C.TEXT_DIM
statusLbl.TextXAlignment     = Enum.TextXAlignment.Left
statusLbl.Text               = "Select an item to get started."
AB_statusLbl                 = statusLbl

local progLbl = Instance.new("TextLabel", statusCard)
progLbl.Size               = UDim2.new(0, 68, 1, 0)
progLbl.Position           = UDim2.new(1, -72, 0, 0)
progLbl.BackgroundTransparency = 1
progLbl.Font               = Enum.Font.GothamBold
progLbl.TextSize           = 12
progLbl.TextColor3         = C.TEXT
progLbl.TextXAlignment     = Enum.TextXAlignment.Right
progLbl.Visible            = false
AB_progLbl                 = progLbl

-- ════════════════════════════════════════════════════
-- ITEM DROPDOWN
-- ════════════════════════════════════════════════════
mkSep()
mkLabel("Item")

local ITEM_H   = 30
local MAX_SHOW = 6
local HEADER_H = 38

local dropIsOpen   = false
local dropSelected = ""
local dropItems    = {}

local dropOuter = Instance.new("Frame", autoBuyPage)
dropOuter.Size             = UDim2.new(1, -12, 0, HEADER_H)
dropOuter.BackgroundColor3 = C.BG_ROW
dropOuter.BorderSizePixel  = 0
dropOuter.ClipsDescendants = true
Instance.new("UICorner", dropOuter).CornerRadius = UDim.new(0, 7)
local dropOuterStroke = Instance.new("UIStroke", dropOuter)
dropOuterStroke.Color        = C.BORDER
dropOuterStroke.Thickness    = 1
dropOuterStroke.Transparency = 0.3

local dropHeader = Instance.new("Frame", dropOuter)
dropHeader.Size                   = UDim2.new(1, 0, 0, HEADER_H)
dropHeader.BackgroundTransparency = 1

local dropLabelLeft = Instance.new("TextLabel", dropHeader)
dropLabelLeft.Size               = UDim2.new(0, 50, 1, 0)
dropLabelLeft.Position           = UDim2.new(0, 10, 0, 0)
dropLabelLeft.BackgroundTransparency = 1
dropLabelLeft.Text               = "Item"
dropLabelLeft.Font               = Enum.Font.GothamBold
dropLabelLeft.TextSize           = 11
dropLabelLeft.TextColor3         = C.TEXT_DIM
dropLabelLeft.TextXAlignment     = Enum.TextXAlignment.Left

local selFrame = Instance.new("Frame", dropHeader)
selFrame.Size             = UDim2.new(1, -66, 0, 26)
selFrame.Position         = UDim2.new(0, 58, 0.5, -13)
selFrame.BackgroundColor3 = C.BG_INPUT
selFrame.BorderSizePixel  = 0
Instance.new("UICorner", selFrame).CornerRadius = UDim.new(0, 5)
local selStroke = Instance.new("UIStroke", selFrame)
selStroke.Color        = C.BORDER
selStroke.Thickness    = 1
selStroke.Transparency = 0.3

local selLbl = Instance.new("TextLabel", selFrame)
selLbl.Size               = UDim2.new(1, -30, 1, 0)
selLbl.Position           = UDim2.new(0, 8, 0, 0)
selLbl.BackgroundTransparency = 1
selLbl.Text               = "Select item..."
selLbl.Font               = Enum.Font.GothamSemibold
selLbl.TextSize           = 11
selLbl.TextColor3         = C.TEXT_DIM
selLbl.TextXAlignment     = Enum.TextXAlignment.Left
selLbl.TextTruncate       = Enum.TextTruncate.AtEnd

local arrowLbl = Instance.new("TextLabel", selFrame)
arrowLbl.Size               = UDim2.new(0, 20, 1, 0)
arrowLbl.Position           = UDim2.new(1, -22, 0, 0)
arrowLbl.BackgroundTransparency = 1
arrowLbl.Text               = "v"
arrowLbl.Font               = Enum.Font.GothamBold
arrowLbl.TextSize           = 11
arrowLbl.TextColor3         = C.TEXT_DIM
arrowLbl.TextXAlignment     = Enum.TextXAlignment.Center

local headerBtn = Instance.new("TextButton", selFrame)
headerBtn.Size               = UDim2.new(1, 0, 1, 0)
headerBtn.BackgroundTransparency = 1
headerBtn.Text               = ""
headerBtn.AutoButtonColor    = false
headerBtn.ZIndex             = 5

local divider = Instance.new("Frame", dropOuter)
divider.Size             = UDim2.new(1, -14, 0, 1)
divider.Position         = UDim2.new(0, 7, 0, HEADER_H)
divider.BackgroundColor3 = C.BORDER
divider.BorderSizePixel  = 0
divider.Visible          = false

local listScroll = Instance.new("ScrollingFrame", dropOuter)
listScroll.Position               = UDim2.new(0, 0, 0, HEADER_H + 2)
listScroll.Size                   = UDim2.new(1, 0, 0, 0)
listScroll.BackgroundTransparency = 1
listScroll.BorderSizePixel        = 0
listScroll.ScrollBarThickness     = 3
listScroll.ScrollBarImageColor3   = C.BORDER_FOC
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

local function applySelection(entry)
    dropSelected   = entry.name
    AB_item        = entry.name
    AB_isBlueprint = entry.isBlueprint
    local priceStr = entry.price > 0 and ("   $" .. entry.price) or ""
    selLbl.Text       = entry.name .. priceStr
    selLbl.TextColor3 = C.TEXT_WHITE
    arrowLbl.TextColor3   = C.TEXT_MID
    dropOuterStroke.Color = C.BORDER_FOC
    refreshActionButtons()
end

local function clearSelection()
    dropSelected   = ""
    AB_item        = nil
    AB_isBlueprint = false
    selLbl.Text       = "Select item..."
    selLbl.TextColor3 = C.TEXT_DIM
    arrowLbl.TextColor3   = C.TEXT_DIM
    dropOuterStroke.Color = C.BORDER
    refreshActionButtons()
end

local function closeList()
    dropIsOpen = false
    tw(arrowLbl,   { Rotation = 0 })
    tw(dropOuter,  { Size = UDim2.new(1, -12, 0, HEADER_H) })
    tw(listScroll, { Size = UDim2.new(1, 0, 0, 0) })
    divider.Visible = false
end

local function buildList()
    for _, child in ipairs(listScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
    end
    for i, entry in ipairs(dropItems) do
        local isSel = entry.name == dropSelected
        local row = Instance.new("Frame", listScroll)
        row.Size             = UDim2.new(1, 0, 0, ITEM_H)
        row.BackgroundColor3 = isSel and Color3.fromRGB(50, 50, 50) or C.BG_ROW
        row.BorderSizePixel  = 0
        row.LayoutOrder      = i
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)

        local nameLbl = Instance.new("TextLabel", row)
        nameLbl.Size               = UDim2.new(1, -70, 1, 0)
        nameLbl.Position           = UDim2.new(0, 10, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text               = entry.name
        nameLbl.Font               = Enum.Font.GothamSemibold
        nameLbl.TextSize           = 11
        nameLbl.TextColor3         = C.TEXT_WHITE
        nameLbl.TextXAlignment     = Enum.TextXAlignment.Left
        nameLbl.TextTruncate       = Enum.TextTruncate.AtEnd

        if entry.price > 0 then
            local priceLbl = Instance.new("TextLabel", row)
            priceLbl.Size               = UDim2.new(0, 60, 1, 0)
            priceLbl.Position           = UDim2.new(1, -64, 0, 0)
            priceLbl.BackgroundTransparency = 1
            priceLbl.Text               = "$" .. entry.price
            priceLbl.Font               = Enum.Font.Gotham
            priceLbl.TextSize           = 11
            priceLbl.TextColor3         = C.TEXT_WHITE
            priceLbl.TextXAlignment     = Enum.TextXAlignment.Right
        end

        local rowBtn = Instance.new("TextButton", row)
        rowBtn.Size               = UDim2.new(1, 0, 1, 0)
        rowBtn.BackgroundTransparency = 1
        rowBtn.Text               = ""
        rowBtn.AutoButtonColor    = false
        rowBtn.ZIndex             = 5
        rowBtn.MouseEnter:Connect(function()
            if entry.name ~= dropSelected then
                tw(row, { BackgroundColor3 = Color3.fromRGB(36, 36, 36) })
            end
        end)
        rowBtn.MouseLeave:Connect(function()
            if entry.name ~= dropSelected then
                tw(row, { BackgroundColor3 = C.BG_ROW })
            end
        end)
        rowBtn.MouseButton1Click:Connect(function()
            if entry.name == dropSelected then clearSelection() else applySelection(entry) end
            buildList()
            task.delay(0.04, closeList)
        end)
    end
end

local function openList()
    dropIsOpen = true
    dropItems  = grabAllItems()
    buildList()
    local count  = #dropItems
    local listH  = math.min(count, MAX_SHOW) * (ITEM_H + 2) + 8
    local totalH = HEADER_H + 2 + listH
    divider.Visible = true
    tw(arrowLbl,   { Rotation = 180 })
    tw(dropOuter,  { Size = UDim2.new(1, -12, 0, totalH) })
    tw(listScroll, { Size = UDim2.new(1, 0, 0, listH) })
end

headerBtn.MouseButton1Click:Connect(function()
    if dropIsOpen then closeList() else openList() end
end)
headerBtn.MouseEnter:Connect(function()
    tw(selFrame, { BackgroundColor3 = Color3.fromRGB(40, 40, 40) })
end)
headerBtn.MouseLeave:Connect(function()
    tw(selFrame, { BackgroundColor3 = C.BG_INPUT })
end)

task.spawn(function()
    task.wait(0.8)
    dropItems = grabAllItems()
end)

-- ════════════════════════════════════════════════════
-- OPTIONS
-- ════════════════════════════════════════════════════
mkSep()
mkLabel("Options")
mkNumberInput("Amount to buy", 1, 9999, AB_amount, function(v) AB_amount = v end)

-- ════════════════════════════════════════════════════
-- START / STOP
-- ════════════════════════════════════════════════════
mkSep()
mkLabel("Actions")

local actionRow = Instance.new("Frame", autoBuyPage)
actionRow.Size               = UDim2.new(1, -12, 0, 36)
actionRow.BackgroundTransparency = 1

local startBtn = Instance.new("TextButton", actionRow)
startBtn.Size             = UDim2.new(0.5, -4, 1, 0)
startBtn.Position         = UDim2.new(0, 0, 0, 0)
startBtn.BackgroundColor3 = C.BTN
startBtn.Text             = "Start"
startBtn.Font             = Enum.Font.GothamBold
startBtn.TextSize         = 13
startBtn.TextColor3       = C.TEXT_DIM
startBtn.BorderSizePixel  = 0
startBtn.AutoButtonColor  = false
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 6)
local startStroke = Instance.new("UIStroke", startBtn)
startStroke.Color = C.BORDER; startStroke.Thickness = 1; startStroke.Transparency = 0

local stopBtn = Instance.new("TextButton", actionRow)
stopBtn.Size             = UDim2.new(0.5, -4, 1, 0)
stopBtn.Position         = UDim2.new(0.5, 4, 0, 0)
stopBtn.BackgroundColor3 = C.BTN
stopBtn.Text             = "Stop"
stopBtn.Font             = Enum.Font.GothamBold
stopBtn.TextSize         = 13
stopBtn.TextColor3       = C.TEXT_DIM
stopBtn.BorderSizePixel  = 0
stopBtn.AutoButtonColor  = false
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 6)
local stopStroke = Instance.new("UIStroke", stopBtn)
stopStroke.Color = C.BORDER; stopStroke.Thickness = 1; stopStroke.Transparency = 0

AB_startBtn = startBtn
AB_stopBtn  = stopBtn
refreshActionButtons()

startBtn.MouseButton1Click:Connect(function()
    if AB_buying or not AB_item then return end
    task.spawn(function()
        AB_buy(AB_item, AB_amount, AB_isBlueprint, false)
    end)
end)

stopBtn.MouseButton1Click:Connect(function()
    if not AB_buying then return end
    AB_aborted = true
    setStatus("Stopping...", true)
end)

-- ════════════════════════════════════════════════════
-- SPECIAL
-- ════════════════════════════════════════════════════
mkSep()
mkLabel("Special")

mkBtn("Buy All Blueprints", function()
    if AB_buying then return end
    task.spawn(function()
        AB_buying  = true
        AB_aborted = false
        refreshActionButtons()
        local bps = grabBlueprintNames()
        if #bps == 0 then
            setStatus("No blueprints found in stores.", false)
            AB_buying = false; refreshActionButtons(); return
        end
        for i, bp in ipairs(bps) do
            if AB_aborted then break end
            setStatus("[" .. i .. "/" .. #bps .. "]  " .. bp, true)
            AB_buy(bp, 1, true, true)
        end
        AB_buying = false
        setProgress(nil)
        setStatus(AB_aborted and "Stopped." or ("Done - " .. #bps .. " blueprints"), false)
        refreshActionButtons()
    end)
end)

mkBtn("Buy RukiryAxe  ($7,400)", function()
    if AB_buying then return end
    task.spawn(function()
        AB_buying  = true
        AB_aborted = false
        refreshActionButtons()

        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then AB_buying = false; refreshActionButtons(); return end
        local origin = hrp.CFrame

        local Dragging = RS.Interaction and RS.Interaction:FindFirstChild("ClientIsDragging")
        local ClientInteracted = RS:FindFirstChild("ClientInteracted", true)
        local ClientGetUserPerms = RS:FindFirstChild("ClientGetUserPermissions", true)

        local function openThenTeleport(itemName, destPos)
            local item = nil
            pcall(function()
                for _, store in next, workspace.Stores:GetChildren() do
                    if store.Name == "ShopItems" then
                        local found = store:FindFirstChild(itemName)
                        if found then item = found break end
                    end
                end
            end)
            if not item then return end
            pcall(function() openBoxFor(item) end)
            task.wait(0.3)
            if not destPos then return end
            local found, deadline = nil, tick() + 10
            repeat
                task.wait(0.05)
                for _, v in next, workspace:GetDescendants() do
                    local iv    = v:FindFirstChild("ItemName")
                    local owner = v:FindFirstChild("Owner")
                    if iv and iv.Value == itemName and owner and owner.Value == player then
                        found = v; break
                    end
                end
            until found or tick() > deadline
            if not (found and destPos) then return end
            local m = found:FindFirstChild("Main")
            if not m then return end
            local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if h then h.CFrame = CFrame.new(m.CFrame.p) + Vector3.new(5, 0, 0) end
            task.wait(0.1)
            pcall(function()
                local t = 0
                while not isnetworkowner(m) and t < 3 do
                    if Dragging then Dragging:FireServer(found) end
                    task.wait(0.05); t += 0.05
                end
                if Dragging then Dragging:FireServer(found) end
                m:PivotTo(CFrame.new(destPos)); task.wait(0.05)
            end)
        end

        setStatus("Buying LightBulb...",  true); AB_buy("LightBulb",  1, false, true)
        openThenTeleport("LightBulb",  Vector3.new(322.39, 45.96, 1916.45))
        setStatus("Buying BagOfSand...",  true); AB_buy("BagOfSand",  1, false, true)
        openThenTeleport("BagOfSand",  Vector3.new(319.48, 45.96, 1914.38))
        setStatus("Buying CanOfWorms...", true); AB_buy("CanOfWorms", 1, false, true)
        openThenTeleport("CanOfWorms", Vector3.new(317.21, 45.92, 1918.07))

        setStatus("Waiting for RukiryAxe...", true)
        local axe = nil
        for _, v in next, workspace:GetDescendants() do
            if v:IsA("Model") then
                local iv = v:FindFirstChild("ItemName"); local tn = v:FindFirstChild("ToolName")
                if (iv and iv.Value == "Rukiryaxe") or (tn and tn.Value == "Rukiryaxe") then axe = v; break end
            end
        end
        if not axe then
            local sig  = Instance.new("BindableEvent")
            local conn
            conn = workspace.DescendantAdded:Connect(function(v)
                if axe then conn:Disconnect(); return end
                local model = v:IsA("Model") and v or v.Parent
                if not (model and model:IsA("Model")) then return end
                local iv = model:FindFirstChild("ItemName"); local tn = model:FindFirstChild("ToolName")
                if (iv and iv.Value == "Rukiryaxe") or (tn and tn.Value == "Rukiryaxe") then
                    axe = model; conn:Disconnect(); sig:Fire()
                end
            end)
            task.delay(30, function() if conn.Connected then conn:Disconnect() end; sig:Fire() end)
            sig.Event:Wait(); sig:Destroy()
        end

        if axe then
            setStatus("Picking up RukiryAxe...", true)
            local axeMain = axe:FindFirstChild("Main")
            if axeMain then
                local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if h then h.CFrame = axeMain.CFrame + Vector3.new(3, 0, 3) end
                task.wait(0.2)
            end
            local uid = tostring(player.UserId)
            if ClientGetUserPerms then
                ClientGetUserPerms:InvokeServer(uid, "Interact")
                ClientGetUserPerms:InvokeServer(uid, "MoveStructure")
                ClientGetUserPerms:InvokeServer(uid, "Destroy")
                ClientGetUserPerms:InvokeServer(uid, "Grab")
            end
            task.wait(0.608)
            if ClientInteracted then
                ClientInteracted:FireServer(
                    RS:FindFirstChild("Model", true) or workspace:FindFirstChild("Model", true), "Pick up tool")
            end
            task.wait(0.211)
            local ConfirmIdentity = RS:FindFirstChild("ConfirmIdentity", true)
            if ConfirmIdentity then
                ConfirmIdentity:InvokeServer(
                    RS:FindFirstChild("Tool", true) or workspace:FindFirstChild("Tool", true), "Rukiryaxe")
            end
            task.wait(0.243)
            local TestPing = RS:FindFirstChild("TestPing", true)
            if TestPing then TestPing:InvokeServer() end
            task.wait(0.5)
            local h2 = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if h2 then h2.CFrame = origin end
            setStatus("RukiryAxe obtained.", false)
        else
            setStatus("RukiryAxe did not appear in time.", false)
        end

        AB_buying = false
        refreshActionButtons()
    end)
end)

-- ════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════
mkSep()
mkLabel("Services  (pay at counter)")

for _, svc in ipairs(AB_Services) do
    local btn = mkBtn(svc.label)
    btn.TextColor3 = C.TEXT_MID
    btn.MouseButton1Click:Connect(function()
        task.spawn(function()
            local NPCDialog = RS:FindFirstChild("NPCDialog")
            if not NPCDialog then return end
            local PC  = NPCDialog:FindFirstChild("PlayerChatted")
            local SCV = NPCDialog:FindFirstChild("SetChattingValue")
            if not (PC and SCV) then return end
            local args = { Character=svc.char, Name=svc.char, ID=svc.id, Dialog="Dialog" }
            PC:InvokeServer(args, "Initiate")
            task.wait(0.05); SCV:InvokeServer(2)
            task.wait(svc.wConfirm)
            PC:InvokeServer(args, "ConfirmPurchase")
            task.wait(0.05); SCV:InvokeServer(2)
            task.wait(svc.wEnd)
            PC:InvokeServer(args, "EndChat")
            task.wait(0.05); SCV:InvokeServer(0)
            if svc.wFinal then task.wait(0.05); SCV:InvokeServer(1) end
            setStatus("Paid: " .. svc.label, false)
        end)
    end)
end

-- ════════════════════════════════════════════════════
-- CLEANUP
-- ════════════════════════════════════════════════════
table.insert(cleanupTasks, function()
    AB_aborted = true
    AB_buying  = false
end)

print("[VanillaHub] Vanilla4 (AutoBuy) loaded.")
