-- ════════════════════════════════════════════════════
-- AUTOBUY TAB
-- ════════════════════════════════════════════════════

local ab = pages["AutoBuyTab"]
local RS = game:GetService("ReplicatedStorage")

-- ── State ─────────────────────────────────────────────
local AB_aborted   = false
local AB_buying    = false
local AB_amount    = 10
local AB_openBox   = false
local AB_item      = nil
local AB_statusLbl = nil
local AB_progLbl   = nil

-- ── Counters ──────────────────────────────────────────
local AB_Counters = {
    { name="WoodRUs",          pos=Vector3.new(267.90,  5.20,   67.43),  char="Thom",        id=9,  preSeq=nil                },
    { name="BobsShack",        pos=Vector3.new(260.36,  10.40, -2551.25),char="Bob",          id=12, preSeq=nil                },
    { name="FineArt",          pos=Vector3.new(5237.58,-164.00,  739.66), char="Timothy",     id=13, preSeq=nil                },
    { name="FancyFurnishings", pos=Vector3.new(477.62,   5.60, -1721.34),char="Corey",        id=10, preSeq=nil                },
    { name="LinksLogic",       pos=Vector3.new(4595.43,  9.40,  -785.02),char="Lincoln",      id=14, preSeq=nil                },
    { name="BoxedCars",        pos=Vector3.new(528.04,   5.60, -1460.43),char="Jenny",        id=11, preSeq="SetChattingValue1" },
}

-- ── Status helpers ────────────────────────────────────
local function setStatus(msg, active)
    if AB_statusLbl and AB_statusLbl.Parent then
        AB_statusLbl.Text       = msg
        AB_statusLbl.TextColor3 = active and Color3.fromRGB(100, 210, 100) or SECTION_TEXT
    end
end

local function setProgress(cur, total)
    if AB_progLbl and AB_progLbl.Parent then
        if cur and total then
            AB_progLbl.Text    = string.format("%d / %d", cur, total)
            AB_progLbl.Visible = true
        else
            AB_progLbl.Visible = false
        end
    end
end

-- ── Item discovery ────────────────────────────────────
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

local function grabItems()
    local list, seen = {}, {}
    pcall(function()
        for _, store in next, workspace.Stores:GetChildren() do
            if store.Name ~= "ShopItems" then continue end
            for _, item in next, store:GetChildren() do
                local bin = item:FindFirstChild("BoxItemName")
                local typ = item:FindFirstChild("Type")
                if bin and typ and typ.Value ~= "Blueprint" and not seen[bin.Value] then
                    seen[bin.Value] = true
                    table.insert(list, bin.Value .. " — $" .. getPrice(bin.Value))
                end
            end
        end
        table.sort(list)
    end)
    return list
end

local function grabBlueprints()
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

local function watchNames()
    pcall(function()
        for _, store in next, workspace.Stores:GetChildren() do
            if store.Name ~= "ShopItems" then continue end
            store.ChildAdded:Connect(function(child)
                local bin = child:WaitForChild("BoxItemName", 5)
                if bin then child.Name = bin.Value end
            end)
            for _, item in next, store:GetChildren() do
                local bin   = item:FindFirstChild("BoxItemName")
                local owner = item:FindFirstChild("Owner")
                if bin and owner and owner.Value == nil then item.Name = bin.Value end
            end
        end
    end)
end
pcall(watchNames)

-- ════════════════════════════════════════════════════
-- BUY LOOP
-- ════════════════════════════════════════════════════
local function AB_buy(itemName, amount, openBox, isBatch)
    if not itemName then setStatus("No item selected", false); return end
    if not isBatch then
        AB_aborted = false
        AB_buying  = true
        setProgress(0, amount)
    end

    local PlayerChatted  = RS:FindFirstChild("PlayerChatted",    true)
    local SetChattingVal = RS:FindFirstChild("SetChattingValue", true)
    local Dragging       = RS.Interaction and RS.Interaction:FindFirstChild("ClientIsDragging")
    local origin         = player.Character.HumanoidRootPart.CFrame

    local function findItem()
        for _, store in next, workspace.Stores:GetChildren() do
            if store.Name ~= "ShopItems" then continue end
            for _, v in next, store:GetChildren() do
                local box   = v:FindFirstChild("BoxItemName")
                local owner = v:FindFirstChild("Owner")
                if box and box.Value == itemName then
                    if not owner or owner.Value == nil or owner.Value == "" then return v end
                end
            end
        end
        return nil
    end

    local function waitForItem(timeout)
        local deadline = tick() + (timeout or 20)
        local found    = findItem()
        while not found and tick() < deadline do
            task.wait(0.07); found = findItem()
        end
        return found
    end

    for i = 1, amount do
        if AB_aborted then break end

        setStatus(string.format("Waiting for %s…", itemName), true)
        local item = waitForItem(20)
        if not item then setStatus(string.format("'%s' not found — timed out", itemName), false); break end

        local main = item:FindFirstChild("Main")
        if not main then setStatus("Missing Main part", false); break end

        local counterPart = item.Parent:FindFirstChild("counter")
        if not counterPart then
            local bestDist = math.huge
            for _, store in next, workspace.Stores:GetChildren() do
                for _, child in next, store:GetChildren() do
                    if child.Name:lower() == "counter" and child:IsA("BasePart") then
                        local d = (child.Position - main.Position).Magnitude
                        if d < bestDist then bestDist = d; counterPart = child end
                    end
                end
            end
        end

        local refPos = counterPart and counterPart.Position or main.Position
        local closestCounter, closestDist = nil, math.huge
        for _, c in ipairs(AB_Counters) do
            local d = (refPos - c.pos).Magnitude
            if d < closestDist then closestDist = d; closestCounter = c end
        end
        if not closestCounter then setStatus("No counter found", false); break end

        local counterCFrame = counterPart and counterPart.CFrame or CFrame.new(closestCounter.pos)

        setStatus(string.format("Buying %s…", itemName), true)
        player.Character.HumanoidRootPart.CFrame = main.CFrame + Vector3.new(5, 0, 5)
        task.wait(0.05)

        for _ = 1, 12 do
            if Dragging then Dragging:FireServer(item) end
            main.CFrame = counterCFrame + Vector3.new(0, main.Size.Y, 0.5)
            task.wait(0.016)
        end

        player.Character.HumanoidRootPart.CFrame = counterCFrame + Vector3.new(5, 0, 5)
        task.wait(0.05)

        local c    = closestCounter
        local args = { Character=c.char, Name=c.char, ID=c.id, Dialog="Dialog" }

        if c.preSeq == "SetChattingValue1" then
            SetChattingVal:InvokeServer(1); task.wait(0.05)
        end

        PlayerChatted:InvokeServer(args, "Initiate")
        task.wait(0.05); SetChattingVal:InvokeServer(2); task.wait(0.85)

        PlayerChatted:InvokeServer(args, "ConfirmPurchase")
        task.wait(0.05); SetChattingVal:InvokeServer(2); task.wait(0.45)

        PlayerChatted:InvokeServer(args, "EndChat")
        task.wait(0.05); SetChattingVal:InvokeServer(0)

        if c.preSeq == "SetChattingValue1" then
            task.wait(0.05); SetChattingVal:InvokeServer(1)
        end

        local returnStart = tick()
        local returned    = false
        repeat
            if tick() - returnStart > 6 then task.wait(0.2); break end
            pcall(function()
                player.Character.HumanoidRootPart.CFrame = main.CFrame + Vector3.new(5, 0, 5)
                if Dragging then Dragging:FireServer(item) end
                task.wait(0.016)
                if isnetworkowner(main) then
                    if Dragging then Dragging:FireServer(item) end
                    main.CFrame = origin
                    returned    = true
                end
            end)
            task.wait(0.05)
        until returned

        player.Character.HumanoidRootPart.CFrame = origin + Vector3.new(5, 1, 0)
        task.wait(0.2)

        if not isBatch then
            setProgress(i, amount)
            setStatus(string.format("Bought %d / %d  ✔", i, amount), true)
        end
    end

    if not isBatch then
        AB_buying = false
        setProgress(nil)
        setStatus(AB_aborted and "Aborted" or "Done!", false)
    end
end

-- ════════════════════════════════════════════════════
-- AB UI HELPERS  (scoped to ab page)
-- ════════════════════════════════════════════════════
local function abSection(text)
    local w = Instance.new("Frame", ab)
    w.Size                   = UDim2.new(1, 0, 0, 22)
    w.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", w)
    lbl.Size                   = UDim2.new(1, -4, 1, 0)
    lbl.Position               = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextSize               = 10
    lbl.TextColor3             = SECTION_TEXT
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.Text                   = "  " .. string.upper(text)
end

local function abSep()
    local s = Instance.new("Frame", ab)
    s.Size             = UDim2.new(1, 0, 0, 1)
    s.BackgroundColor3 = SEP_COLOR
    s.BorderSizePixel  = 0
end

local function abBtn(text, bgCol, hovCol, cb)
    bgCol  = bgCol  or BTN_COLOR
    hovCol = hovCol or BTN_HOVER
    local btn = Instance.new("TextButton", ab)
    btn.Size             = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = bgCol
    btn.Text             = text
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.TextColor3       = THEME_TEXT
    btn.BorderSizePixel  = 0
    btn.AutoButtonColor  = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", btn)
    s.Color = Color3.fromRGB(55,55,55); s.Thickness = 1; s.Transparency = 0
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = hovCol}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = bgCol}):Play()  end)
    if cb then btn.MouseButton1Click:Connect(function() task.spawn(cb) end) end
    return btn
end

local function abNumberInput(text, minV, maxV, defV, cb)
    local frame = Instance.new("Frame", ab)
    frame.Size             = UDim2.new(1, 0, 0, 42)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel  = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size                   = UDim2.new(1, -130, 1, 0)
    lbl.Position               = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = text
    lbl.Font                   = Enum.Font.GothamSemibold
    lbl.TextSize               = 13
    lbl.TextColor3             = THEME_TEXT
    lbl.TextXAlignment         = Enum.TextXAlignment.Left

    local function makeArrow(xPos, label)
        local btn = Instance.new("TextButton", frame)
        btn.Size             = UDim2.new(0, 28, 0, 28)
        btn.Position         = UDim2.new(1, xPos, 0.5, -14)
        btn.BackgroundColor3 = BTN_COLOR
        btn.Text             = label
        btn.Font             = Enum.Font.GothamBold
        btn.TextSize         = 16
        btn.TextColor3       = THEME_TEXT
        btn.BorderSizePixel  = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_HOVER}):Play() end)
        btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BTN_COLOR}):Play() end)
        return btn
    end

    local minusBtn = makeArrow(-122, "−")
    local plusBtn  = makeArrow(-30,  "+")

    local box = Instance.new("TextBox", frame)
    box.Size                 = UDim2.new(0, 56, 0, 28)
    box.Position             = UDim2.new(1, -90, 0.5, -14)
    box.BackgroundColor3     = Color3.fromRGB(22, 22, 22)
    box.BorderSizePixel      = 0
    box.Font                 = Enum.Font.GothamBold
    box.TextSize             = 14
    box.TextColor3           = THEME_TEXT
    box.Text                 = tostring(defV)
    box.ClearTextOnFocus     = false
    box.TextXAlignment       = Enum.TextXAlignment.Center
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    local bStroke = Instance.new("UIStroke", box)
    bStroke.Color = Color3.fromRGB(55,55,55); bStroke.Thickness = 1; bStroke.Transparency = 0.5

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

-- ── Status bar ────────────────────────────────────────
local statusFrame = Instance.new("Frame", ab)
statusFrame.Size             = UDim2.new(1, 0, 0, 32)
statusFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
statusFrame.BorderSizePixel  = 0
Instance.new("UICorner", statusFrame).CornerRadius = UDim.new(0, 8)
local sfStroke = Instance.new("UIStroke", statusFrame)
sfStroke.Color = Color3.fromRGB(55,55,55); sfStroke.Thickness = 1; sfStroke.Transparency = 0.4

local statusLbl = Instance.new("TextLabel", statusFrame)
statusLbl.Size                   = UDim2.new(1, -70, 1, 0)
statusLbl.Position               = UDim2.new(0, 10, 0, 0)
statusLbl.BackgroundTransparency = 1
statusLbl.Font                   = Enum.Font.GothamSemibold
statusLbl.TextSize               = 12
statusLbl.TextColor3             = SECTION_TEXT
statusLbl.TextXAlignment         = Enum.TextXAlignment.Left
statusLbl.Text                   = "Ready"
AB_statusLbl                     = statusLbl

local progLbl = Instance.new("TextLabel", statusFrame)
progLbl.Size                   = UDim2.new(0, 60, 1, 0)
progLbl.Position               = UDim2.new(1, -64, 0, 0)
progLbl.BackgroundTransparency = 1
progLbl.Font                   = Enum.Font.GothamBold
progLbl.TextSize               = 12
progLbl.TextColor3             = SECTION_TEXT
progLbl.TextXAlignment         = Enum.TextXAlignment.Right
progLbl.Visible                = false
AB_progLbl                     = progLbl

-- ── Item dropdown ─────────────────────────────────────
abSection("Store Items")

local dropOuter = Instance.new("Frame", ab)
dropOuter.Size             = UDim2.new(1, 0, 0, 36)
dropOuter.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
dropOuter.BorderSizePixel  = 0
Instance.new("UICorner", dropOuter).CornerRadius = UDim.new(0, 8)
local doStroke = Instance.new("UIStroke", dropOuter)
doStroke.Color = Color3.fromRGB(55,55,55); doStroke.Thickness = 1; doStroke.Transparency = 0.4

local dropLbl = Instance.new("TextLabel", dropOuter)
dropLbl.Size                   = UDim2.new(1, -36, 1, 0)
dropLbl.Position               = UDim2.new(0, 12, 0, 0)
dropLbl.BackgroundTransparency = 1
dropLbl.Font                   = Enum.Font.GothamSemibold
dropLbl.TextSize               = 13
dropLbl.TextColor3             = SECTION_TEXT
dropLbl.TextXAlignment         = Enum.TextXAlignment.Left
dropLbl.TextTruncate           = Enum.TextTruncate.AtEnd
dropLbl.Text                   = "Select item…"

local dropArrow = Instance.new("TextLabel", dropOuter)
dropArrow.Size                   = UDim2.new(0, 22, 0, 22)
dropArrow.Position               = UDim2.new(1, -28, 0.5, -11)
dropArrow.BackgroundTransparency = 1
dropArrow.Font                   = Enum.Font.GothamBold
dropArrow.TextSize               = 12
dropArrow.TextColor3             = SECTION_TEXT
dropArrow.Text                   = "▾"

-- The list expands inside the same ab scroll container by resizing dropOuter
local dropListFrame = Instance.new("Frame", dropOuter)
dropListFrame.Position         = UDim2.new(0, 0, 0, 36)
dropListFrame.Size             = UDim2.new(1, 0, 0, 0)
dropListFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
dropListFrame.BorderSizePixel  = 0
dropListFrame.ClipsDescendants = true

local dropScroll = Instance.new("ScrollingFrame", dropListFrame)
dropScroll.Size                   = UDim2.new(1, -6, 1, -6)
dropScroll.Position               = UDim2.new(0, 3, 0, 3)
dropScroll.BackgroundTransparency = 1
dropScroll.BorderSizePixel        = 0
dropScroll.ScrollBarThickness     = 3
dropScroll.ScrollBarImageColor3   = Color3.fromRGB(55,55,55)
dropScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)

local dLayout = Instance.new("UIListLayout", dropScroll)
dLayout.Padding   = UDim.new(0, 3)
dLayout.SortOrder = Enum.SortOrder.LayoutOrder
dLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    dropScroll.CanvasSize = UDim2.new(0, 0, 0, dLayout.AbsoluteContentSize.Y + 6)
end)

local dropOpen    = false
local ITEM_H      = 30
local MAX_VISIBLE = 5

local function closeItemDrop()
    dropOpen = false
    TweenService:Create(dropArrow, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
    TweenService:Create(dropOuter, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, 36)}):Play()
    TweenService:Create(dropListFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, 0)}):Play()
end

local function populateItemDrop(items)
    for _, c in ipairs(dropScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    for _, it in ipairs(items) do
        local ib = Instance.new("TextButton", dropScroll)
        ib.Size             = UDim2.new(1, 0, 0, ITEM_H)
        ib.BackgroundColor3 = BTN_COLOR
        ib.BorderSizePixel  = 0
        ib.Text             = it
        ib.Font             = Enum.Font.GothamSemibold
        ib.TextSize         = 12
        ib.TextColor3       = THEME_TEXT
        ib.TextXAlignment   = Enum.TextXAlignment.Left
        ib.AutoButtonColor  = false
        ib.TextTruncate     = Enum.TextTruncate.AtEnd
        Instance.new("UICorner", ib).CornerRadius = UDim.new(0, 6)
        local p = Instance.new("UIPadding", ib); p.PaddingLeft = UDim.new(0, 8)
        ib.MouseEnter:Connect(function() TweenService:Create(ib, TweenInfo.new(0.1), {BackgroundColor3 = BTN_HOVER}):Play() end)
        ib.MouseLeave:Connect(function() TweenService:Create(ib, TweenInfo.new(0.1), {BackgroundColor3 = BTN_COLOR}):Play() end)
        ib.MouseButton1Click:Connect(function()
            AB_item      = string.split(it, " — ")[1]
            dropLbl.Text = it
            dropLbl.TextColor3 = THEME_TEXT
            setStatus("Selected: " .. AB_item, false)
            closeItemDrop()
        end)
    end
end

local function openItemDrop()
    dropOpen = true
    local cnt  = 0
    for _, c in ipairs(dropScroll:GetChildren()) do if c:IsA("TextButton") then cnt += 1 end end
    local listH = math.min(cnt, MAX_VISIBLE) * (ITEM_H + 3) + 8
    TweenService:Create(dropArrow, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation = 180}):Play()
    TweenService:Create(dropOuter, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, 36 + listH)}):Play()
    TweenService:Create(dropListFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, listH)}):Play()
end

local dropHeaderBtn = Instance.new("TextButton", dropOuter)
dropHeaderBtn.Size             = UDim2.new(1, 0, 0, 36)
dropHeaderBtn.BackgroundTransparency = 1
dropHeaderBtn.Text             = ""
dropHeaderBtn.AutoButtonColor  = false
dropHeaderBtn.ZIndex           = 5
dropHeaderBtn.MouseButton1Click:Connect(function()
    if dropOpen then closeItemDrop() else openItemDrop() end
end)

task.spawn(function() task.wait(0.5); populateItemDrop(grabItems()) end)

abBtn("↺  Refresh Store Items", BTN_COLOR, BTN_HOVER, function()
    local items = grabItems()
    populateItemDrop(items)
    setStatus("Found " .. #items .. " item(s)", false)
end)

-- ── Options ───────────────────────────────────────────
abSep()
abSection("Options")
abNumberInput("Amount to buy", 1, 9999, AB_amount, function(v) AB_amount = v end)

-- Open Box toggle
local obFrame = Instance.new("Frame", ab)
obFrame.Size             = UDim2.new(1, 0, 0, 36)
obFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
obFrame.BorderSizePixel  = 0
Instance.new("UICorner", obFrame).CornerRadius = UDim.new(0, 8)
local obLbl = Instance.new("TextLabel", obFrame)
obLbl.Size                   = UDim2.new(1, -54, 1, 0)
obLbl.Position               = UDim2.new(0, 12, 0, 0)
obLbl.BackgroundTransparency = 1
obLbl.Text                   = "Open box after purchase"
obLbl.Font                   = Enum.Font.GothamSemibold
obLbl.TextSize               = 13
obLbl.TextColor3             = THEME_TEXT
obLbl.TextXAlignment         = Enum.TextXAlignment.Left
local obTb = Instance.new("TextButton", obFrame)
obTb.Size             = UDim2.new(0, 36, 0, 20)
obTb.Position         = UDim2.new(1, -46, 0.5, -10)
obTb.BackgroundColor3 = SW_OFF
obTb.Text             = ""; obTb.BorderSizePixel = 0; obTb.AutoButtonColor = false
Instance.new("UICorner", obTb).CornerRadius = UDim.new(1, 0)
local obCircle = Instance.new("Frame", obTb)
obCircle.Size             = UDim2.new(0, 14, 0, 14)
obCircle.Position         = UDim2.new(0, 2, 0.5, -7)
obCircle.BackgroundColor3 = SW_KNOB_OFF
obCircle.BorderSizePixel  = 0
Instance.new("UICorner", obCircle).CornerRadius = UDim.new(1, 0)
obTb.MouseButton1Click:Connect(function()
    AB_openBox = not AB_openBox
    TweenService:Create(obTb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = AB_openBox and SW_ON or SW_OFF}):Play()
    TweenService:Create(obCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
        Position         = UDim2.new(0, AB_openBox and 20 or 2, 0.5, -7),
        BackgroundColor3 = AB_openBox and SW_KNOB_ON or SW_KNOB_OFF
    }):Play()
end)

-- ── Actions ───────────────────────────────────────────
abSep()
abSection("Actions")

local GREEN     = Color3.fromRGB(30,  90,  45)
local GREEN_HOV = Color3.fromRGB(40, 120,  60)
local RED_AB    = Color3.fromRGB(110, 30,  30)
local RED_HOV   = Color3.fromRGB(150, 40,  40)

local buyBtn = abBtn("🛒  Purchase Selected", GREEN, GREEN_HOV, nil)
buyBtn.MouseButton1Click:Connect(function()
    if AB_buying then
        AB_aborted = true
        buyBtn.Text = "🛒  Purchase Selected"
        TweenService:Create(buyBtn, TweenInfo.new(0.15), {BackgroundColor3 = GREEN}):Play()
        return
    end
    task.spawn(function()
        buyBtn.Text = "⛔  Click to Abort"
        TweenService:Create(buyBtn, TweenInfo.new(0.15), {BackgroundColor3 = RED_AB}):Play()
        AB_buy(AB_item, AB_amount, AB_openBox, false)
        buyBtn.Text = "🛒  Purchase Selected"
        TweenService:Create(buyBtn, TweenInfo.new(0.15), {BackgroundColor3 = GREEN}):Play()
    end)
end)

abBtn("📋  Buy All Blueprints", BTN_COLOR, BTN_HOVER, function()
    if AB_buying then return end
    AB_buying = true; AB_aborted = false
    local bps = grabBlueprints()
    if #bps == 0 then setStatus("No blueprints found", false); AB_buying = false; return end
    for i, bp in ipairs(bps) do
        if AB_aborted then break end
        setStatus(string.format("[%d/%d]  %s", i, #bps, bp), true)
        AB_buy(bp, 1, true, true)
    end
    AB_buying = false
    setStatus(AB_aborted and "Aborted" or string.format("Done — %d blueprints", #bps), false)
end)

-- ── Special ───────────────────────────────────────────
abSep()
abSection("Special")

abBtn("🪓  Buy RukiryAxe  ($7,400)", BTN_COLOR, BTN_HOVER, function()
    if AB_buying then return end
    AB_buying = true

    local origin             = player.Character.HumanoidRootPart.CFrame
    local Dragging           = RS.Interaction and RS.Interaction:FindFirstChild("ClientIsDragging")
    local ClientInteracted   = RS:FindFirstChild("ClientInteracted",          true)
    local ClientGetUserPerms = RS:FindFirstChild("ClientGetUserPermissions",  true)
    local playerName         = player.Name

    local function gentleTeleport(item, destPos)
        local m = item:FindFirstChild("Main"); if not m then return end
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(m.CFrame.p) + Vector3.new(5, 0, 0) end
        task.wait(0.1)
        pcall(function()
            if not item.PrimaryPart then item.PrimaryPart = m end
            local t = 0
            while not isnetworkowner(m) and t < 3 do
                if Dragging then Dragging:FireServer(item) end
                task.wait(0.05); t += 0.05
            end
            if Dragging then Dragging:FireServer(item) end
            if m:IsA("BasePart") then m.Velocity = Vector3.zero; m.RotVelocity = Vector3.zero end
            m:PivotTo(CFrame.new(destPos)); task.wait(0.05)
            if m:IsA("BasePart") then m.Velocity = Vector3.zero; m.RotVelocity = Vector3.zero end
        end)
    end

    local function openAndTeleport(itemName, destPos)
        local box = RS:FindFirstChild("Box Purchased by " .. playerName, true)
                 or workspace:FindFirstChild("Box Purchased by " .. playerName, true)
        if not box then
            for _, v in next, workspace:GetDescendants() do
                local iv = v:FindFirstChild("ItemName"); local ow = v:FindFirstChild("Owner")
                if iv and iv.Value == itemName and ow and ow.Value == player then box = v; break end
            end
        end
        if not box then return end
        local uid = tostring(player.UserId)
        if ClientGetUserPerms then
            for _, perm in ipairs({"Interact","MoveStructure","Destroy","Grab"}) do
                ClientGetUserPerms:InvokeServer(uid, perm); task.wait(0.017)
            end
        end
        task.wait(0.004)
        if ClientInteracted then ClientInteracted:FireServer(box, "Open box") end
        task.wait(0.3)
        local found, deadline = nil, tick() + 10
        repeat
            task.wait(0.05)
            for _, v in next, workspace:GetDescendants() do
                local iv = v:FindFirstChild("ItemName"); local ow = v:FindFirstChild("Owner")
                if iv and iv.Value == itemName and ow and ow.Value == player then found = v; break end
            end
        until found or tick() > deadline
        if found then gentleTeleport(found, destPos) end
    end

    setStatus("Buying LightBulb…",  true); AB_buy("LightBulb",  1, false, true)
    openAndTeleport("LightBulb",  Vector3.new(322.39, 45.96, 1916.45))
    setStatus("Buying BagOfSand…",  true); AB_buy("BagOfSand",  1, false, true)
    openAndTeleport("BagOfSand",  Vector3.new(319.48, 45.96, 1914.38))
    setStatus("Buying CanOfWorms…", true); AB_buy("CanOfWorms", 1, false, true)
    openAndTeleport("CanOfWorms", Vector3.new(317.21, 45.92, 1918.07))

    setStatus("Waiting for RukiryAxe…", true)
    local axe = nil
    for _, v in next, workspace:GetDescendants() do
        if v:IsA("Model") then
            local iv = v:FindFirstChild("ItemName"); local tn = v:FindFirstChild("ToolName")
            if (iv and iv.Value == "Rukiryaxe") or (tn and tn.Value == "Rukiryaxe") then axe = v; break end
        end
    end
    if not axe then
        local sig = Instance.new("BindableEvent"); local conn
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
        setStatus("Picking up RukiryAxe…", true)
        local axeMain = axe:FindFirstChild("Main")
        if axeMain then
            player.Character.HumanoidRootPart.CFrame = axeMain.CFrame + Vector3.new(3, 0, 3)
            task.wait(0.2)
        end
        local uid = tostring(player.UserId)
        if ClientGetUserPerms then
            for _, perm in ipairs({"Interact","MoveStructure","Destroy","Grab"}) do
                ClientGetUserPerms:InvokeServer(uid, perm)
            end
        end
        task.wait(0.608)
        if ClientInteracted then
            ClientInteracted:FireServer(
                RS:FindFirstChild("Model", true) or workspace:FindFirstChild("Model", true), "Pick up tool"
            )
        end
        task.wait(0.211)
        local ConfirmIdentity = RS:FindFirstChild("ConfirmIdentity", true)
        if ConfirmIdentity then
            ConfirmIdentity:InvokeServer(
                RS:FindFirstChild("Tool", true) or workspace:FindFirstChild("Tool", true), "Rukiryaxe"
            )
        end
        task.wait(0.243)
        local TestPing = RS:FindFirstChild("TestPing", true)
        if TestPing then TestPing:InvokeServer() end
        task.wait(0.5)
        player.Character.HumanoidRootPart.CFrame = origin
        setStatus("RukiryAxe obtained!", false)
    else
        setStatus("RukiryAxe did not appear in time", false)
    end

    AB_buying = false
end)

-- ── Services ──────────────────────────────────────────
abSep()
abSection("Services  (pay at counter)")

local AB_Services = {
    { label="🌉 Toll Bridge",   char="Seranok",     id=7,  wConfirm=0.85, wEnd=0.45             },
    { label="⛴ Ferry Ticket",  char="Hoover",      id=15, wConfirm=0.85, wEnd=0.45             },
    { label="⚡ Power of Ease", char="Strange Man", id=6,  wConfirm=0.85, wEnd=0.45, wFinal=0.05},
}

for _, svc in ipairs(AB_Services) do
    abBtn(svc.label, BTN_COLOR, BTN_HOVER, function()
        local args = { Character=svc.char, Name=svc.char, ID=svc.id, Dialog="Dialog" }
        local PC   = RS:FindFirstChild("PlayerChatted",    true)
        local SCV  = RS:FindFirstChild("SetChattingValue", true)
        task.wait(0.05)
        PC:InvokeServer(args, "Initiate");       task.wait(0.05); SCV:InvokeServer(2); task.wait(svc.wConfirm)
        PC:InvokeServer(args, "ConfirmPurchase"); task.wait(0.05); SCV:InvokeServer(2); task.wait(svc.wEnd)
        PC:InvokeServer(args, "EndChat");         task.wait(0.05); SCV:InvokeServer(0)
        if svc.wFinal then task.wait(0.05); SCV:InvokeServer(1) end
        setStatus("Paid: " .. svc.label, false)
    end)
end
