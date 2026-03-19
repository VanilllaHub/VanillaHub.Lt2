-- ════════════════════════════════════════════════════
-- VANILLA4 — AutoBuy Tab  (replaces Sorter)
-- Execute AFTER Vanilla1, Vanilla2, Vanilla3
-- ════════════════════════════════════════════════════

if not _G.VH then
    warn("[VanillaHub] Vanilla4: _G.VH not found. Execute Vanilla1 first.")
    return
end

local TweenService     = _G.VH.TweenService
local UserInputService = _G.VH.UserInputService
local RunService       = _G.VH.RunService
local player           = _G.VH.player
local cleanupTasks     = _G.VH.cleanupTasks
local pages            = _G.VH.pages

local RS = game:GetService("ReplicatedStorage")

-- ════════════════════════════════════════════════════
-- THEME  (mirrors Vanilla1 — Black / Grey / White)
-- ════════════════════════════════════════════════════
local C = {
    BG          = Color3.fromRGB(10,  10,  10),
    CARD        = Color3.fromRGB(16,  16,  16),
    BTN         = Color3.fromRGB(14,  14,  14),
    BTN_HV      = Color3.fromRGB(32,  32,  32),
    BORDER      = Color3.fromRGB(55,  55,  55),
    SEP         = Color3.fromRGB(40,  40,  40),
    TEXT        = Color3.fromRGB(210, 210, 210),
    TEXT_MID    = Color3.fromRGB(150, 150, 150),
    TEXT_DIM    = Color3.fromRGB(90,  90,  90),
    ACTIVE_TXT  = Color3.fromRGB(200, 200, 200),
    SW_ON       = Color3.fromRGB(220, 220, 220),
    SW_OFF      = Color3.fromRGB(50,  50,  50),
    SW_KNOB_ON  = Color3.fromRGB(30,  30,  30),
    SW_KNOB_OFF = Color3.fromRGB(160, 160, 160),
}

local autoBuyPage = pages["AutoBuyTab"]
if not autoBuyPage then
    warn("[VanillaHub] Vanilla4: AutoBuyTab page not found.")
    return
end

-- ════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════
local AB_aborted   = false
local AB_buying    = false
local AB_amount    = 10
local AB_openBox   = false
local AB_item      = nil
local AB_statusLbl = nil
local AB_progLbl   = nil
local AB_buyBtn    = nil
local dropOpen     = false

-- ════════════════════════════════════════════════════
-- STORE COUNTER REGISTRY
-- ════════════════════════════════════════════════════
local AB_Counters = {
    { name="WoodRUs",          pos=Vector3.new(267.90,  5.20,   67.43),   char="Thom",        id=9,  preSeq=nil                },
    { name="BobsShack",        pos=Vector3.new(260.36,  10.40, -2551.25), char="Bob",          id=12, preSeq=nil                },
    { name="FineArt",          pos=Vector3.new(5237.58,-164.00,  739.66), char="Timothy",      id=13, preSeq=nil                },
    { name="FancyFurnishings", pos=Vector3.new(477.62,   5.60, -1721.34), char="Corey",        id=10, preSeq=nil                },
    { name="LinksLogic",       pos=Vector3.new(4595.43,  9.40,  -785.02), char="Lincoln",      id=14, preSeq=nil                },
    { name="BoxedCars",        pos=Vector3.new(528.04,   5.60, -1460.43), char="Jenny",        id=11, preSeq="SetChattingValue1" },
}

local AB_Services = {
    { label="Toll Bridge",    char="Seranok",     id=7,  wConfirm=0.85, wEnd=0.45              },
    { label="Ferry Ticket",   char="Hoover",      id=15, wConfirm=0.85, wEnd=0.45              },
    { label="Power of Ease",  char="Strange Man", id=6,  wConfirm=0.85, wEnd=0.45, wFinal=true },
}

-- ════════════════════════════════════════════════════
-- HELPERS
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

local function isnetworkowner(part)
    local ok, res = pcall(function() return part.ReceiveAge end)
    return ok and res == 0
end

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
                    local p = getPrice(bin.Value)
                    table.insert(list, bin.Value .. (p > 0 and ("  —  $" .. p) or ""))
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

-- ════════════════════════════════════════════════════
-- BUY LOOP
-- ════════════════════════════════════════════════════
local function AB_buy(itemName, amount, openBox, isBatch)
    if not itemName then setStatus("No item selected", false); return end
    if not isBatch then
        AB_aborted = false; AB_buying = true
        setProgress(0, amount)
    end

    local PlayerChatted  = RS:FindFirstChild("PlayerChatted",   true)
    local SetChattingVal = RS:FindFirstChild("SetChattingValue", true)
    local Dragging       = RS.Interaction and RS.Interaction:FindFirstChild("ClientIsDragging")

    local char = player.Character
    if not (char and char:FindFirstChild("HumanoidRootPart")) then
        if not isBatch then AB_buying = false end
        return
    end
    local origin = char.HumanoidRootPart.CFrame

    local function findItem()
        for _, store in next, workspace.Stores:GetChildren() do
            if store.Name ~= "ShopItems" then continue end
            for _, v in next, store:GetChildren() do
                local box   = v:FindFirstChild("BoxItemName")
                local owner = v:FindFirstChild("Owner")
                if box and box.Value == itemName then
                    if not owner or owner.Value == nil or owner.Value == "" then
                        return v
                    end
                end
            end
        end
        return nil
    end

    local function waitForItem(timeout)
        local deadline = tick() + (timeout or 20)
        local found    = findItem()
        while not found and tick() < deadline do
            task.wait(0.07)
            found = findItem()
        end
        return found
    end

    for i = 1, amount do
        if AB_aborted then break end

        setStatus("Waiting for " .. itemName .. "…", true)
        local item = waitForItem(20)
        if not item then
            setStatus("'" .. itemName .. "' not found — timed out", false); break
        end

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

        setStatus("Buying " .. itemName .. "…", true)
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then break end

        hrp.CFrame = main.CFrame + Vector3.new(5, 0, 5)
        task.wait(0.05)

        for _ = 1, 12 do
            if Dragging then Dragging:FireServer(item) end
            main.CFrame = counterCFrame + Vector3.new(0, main.Size.Y, 0.5)
            task.wait(0.016)
        end

        hrp.CFrame = counterCFrame + Vector3.new(5, 0, 5)
        task.wait(0.05)

        local c    = closestCounter
        local args = { Character=c.char, Name=c.char, ID=c.id, Dialog="Dialog" }

        if c.preSeq == "SetChattingValue1" then
            SetChattingVal:InvokeServer(1); task.wait(0.05)
        end

        PlayerChatted:InvokeServer(args, "Initiate")
        task.wait(0.05)
        SetChattingVal:InvokeServer(2)
        task.wait(0.85)

        PlayerChatted:InvokeServer(args, "ConfirmPurchase")
        task.wait(0.05)
        SetChattingVal:InvokeServer(2)
        task.wait(0.45)

        PlayerChatted:InvokeServer(args, "EndChat")
        task.wait(0.05)
        SetChattingVal:InvokeServer(0)

        if c.preSeq == "SetChattingValue1" then
            task.wait(0.05); SetChattingVal:InvokeServer(1)
        end

        -- Return item to origin
        local returnStart = tick()
        local returned    = false
        repeat
            if tick() - returnStart > 6 then task.wait(0.2); break end
            pcall(function()
                local h2 = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if not h2 then return end
                h2.CFrame = main.CFrame + Vector3.new(5, 0, 5)
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

        local h3 = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if h3 then h3.CFrame = origin + Vector3.new(5, 1, 0) end
        task.wait(0.2)

        if not isBatch then
            setProgress(i, amount)
            setStatus("Bought " .. i .. " / " .. amount, true)
        end
    end

    if not isBatch then
        AB_buying = false
        setProgress(nil)
        setStatus(AB_aborted and "Aborted." or "Done!", false)
        -- reset buy button
        if AB_buyBtn and AB_buyBtn.Parent then
            AB_buyBtn.Text = "Purchase Selected"
            tw(AB_buyBtn, { BackgroundColor3 = C.BTN })
        end
    end
end

-- ════════════════════════════════════════════════════
-- UI WIDGET HELPERS
-- ════════════════════════════════════════════════════

-- Section label (matches Vanilla1 style)
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

-- Standard grey button
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

    btn.MouseEnter:Connect(function()
        tw(btn, { BackgroundColor3 = C.BTN_HV })
    end)
    btn.MouseLeave:Connect(function()
        tw(btn, { BackgroundColor3 = C.BTN })
    end)
    if cb then btn.MouseButton1Click:Connect(cb) end
    return btn
end

-- Toggle switch
local function mkToggle(text, default, cb)
    local fr = Instance.new("Frame", autoBuyPage)
    fr.Size             = UDim2.new(1, -12, 0, 34)
    fr.BackgroundColor3 = C.CARD
    fr.BorderSizePixel  = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", fr)
    lbl.Size               = UDim2.new(1, -54, 1, 0)
    lbl.Position           = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = text
    lbl.Font               = Enum.Font.GothamSemibold
    lbl.TextSize           = 13
    lbl.TextColor3         = C.TEXT
    lbl.TextXAlignment     = Enum.TextXAlignment.Left

    local tb = Instance.new("TextButton", fr)
    tb.Size             = UDim2.new(0, 34, 0, 18)
    tb.Position         = UDim2.new(1, -44, 0.5, -9)
    tb.BackgroundColor3 = default and C.SW_ON or C.SW_OFF
    tb.Text             = ""
    tb.AutoButtonColor  = false
    tb.BorderSizePixel  = 0
    Instance.new("UICorner", tb).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame", tb)
    dot.Size             = UDim2.new(0, 14, 0, 14)
    dot.Position         = UDim2.new(0, default and 18 or 2, 0.5, -7)
    dot.BackgroundColor3 = default and C.SW_KNOB_ON or C.SW_KNOB_OFF
    dot.BorderSizePixel  = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local on = default
    if cb then cb(on) end
    tb.MouseButton1Click:Connect(function()
        on = not on
        tw(tb,  { BackgroundColor3 = on and C.SW_ON or C.SW_OFF })
        tw(dot, {
            Position         = UDim2.new(0, on and 18 or 2, 0.5, -7),
            BackgroundColor3 = on and C.SW_KNOB_ON or C.SW_KNOB_OFF
        })
        if cb then cb(on) end
    end)
    return fr
end

-- Number stepper (+/−)
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

    local minusBtn = makeArrow(-122, "−")
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
-- DROPDOWN  (item selector)
-- ════════════════════════════════════════════════════
mkSep()
mkLabel("Store Items")

-- Wrapper frame so it participates in the UIListLayout
local dropWrapper = Instance.new("Frame", autoBuyPage)
dropWrapper.Size               = UDim2.new(1, -12, 0, 36)
dropWrapper.BackgroundTransparency = 1

local dropBtn = Instance.new("TextButton", dropWrapper)
dropBtn.Size             = UDim2.new(1, 0, 1, 0)
dropBtn.BackgroundColor3 = C.CARD
dropBtn.BorderSizePixel  = 0
dropBtn.Text             = ""
dropBtn.AutoButtonColor  = false
Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0, 6)
local dbStroke = Instance.new("UIStroke", dropBtn)
dbStroke.Color = C.BORDER; dbStroke.Thickness = 1; dbStroke.Transparency = 0.3

local dropLbl = Instance.new("TextLabel", dropBtn)
dropLbl.Size               = UDim2.new(1, -36, 1, 0)
dropLbl.Position           = UDim2.new(0, 10, 0, 0)
dropLbl.BackgroundTransparency = 1
dropLbl.Font               = Enum.Font.GothamSemibold
dropLbl.TextSize           = 13
dropLbl.TextColor3         = C.TEXT_DIM
dropLbl.TextXAlignment     = Enum.TextXAlignment.Left
dropLbl.TextTruncate       = Enum.TextTruncate.AtEnd
dropLbl.Text               = "Select item…"

local dropArrow = Instance.new("TextLabel", dropBtn)
dropArrow.Size               = UDim2.new(0, 22, 0, 22)
dropArrow.Position           = UDim2.new(1, -28, 0.5, -11)
dropArrow.BackgroundTransparency = 1
dropArrow.Font               = Enum.Font.GothamBold
dropArrow.TextSize           = 11
dropArrow.TextColor3         = C.TEXT_DIM
dropArrow.Text               = "▾"

-- The floating list is parented to CoreGui so it floats above everything
local coreGui    = game:GetService("CoreGui")
local vhGui      = coreGui:FindFirstChild("VanillaHub") or coreGui

local dropList   = Instance.new("Frame", vhGui)
dropList.BackgroundColor3 = C.CARD
dropList.BorderSizePixel  = 0
dropList.Visible          = false
dropList.ZIndex           = 50
Instance.new("UICorner", dropList).CornerRadius = UDim.new(0, 8)
local dlStroke = Instance.new("UIStroke", dropList)
dlStroke.Color = C.BORDER; dlStroke.Thickness = 1; dlStroke.Transparency = 0.2

local dropScroll = Instance.new("ScrollingFrame", dropList)
dropScroll.BackgroundTransparency = 1
dropScroll.BorderSizePixel        = 0
dropScroll.ScrollBarThickness     = 3
dropScroll.ScrollBarImageColor3   = Color3.fromRGB(70, 70, 70)
dropScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
dropScroll.ZIndex                 = 51

local dLayout = Instance.new("UIListLayout", dropScroll)
dLayout.Padding   = UDim.new(0, 3)
dLayout.SortOrder = Enum.SortOrder.LayoutOrder
dLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    dropScroll.CanvasSize = UDim2.new(0, 0, 0, dLayout.AbsoluteContentSize.Y)
end)

local dPad = Instance.new("UIPadding", dropScroll)
dPad.PaddingTop    = UDim.new(0, 4); dPad.PaddingBottom = UDim.new(0, 4)
dPad.PaddingLeft   = UDim.new(0, 4); dPad.PaddingRight  = UDim.new(0, 4)

local function closeDropdown()
    dropOpen         = false
    dropList.Visible = false
    tw(dropArrow, { Rotation = 0 })
end

local function openDropdown()
    local ap  = dropBtn.AbsolutePosition
    local as  = dropBtn.AbsoluteSize
    local cnt = 0
    for _, c in ipairs(dropScroll:GetChildren()) do
        if c:IsA("TextButton") then cnt += 1 end
    end
    cnt = math.min(cnt, 8)
    dropScroll.Size     = UDim2.new(1, -4, 1, -4)
    dropScroll.Position = UDim2.new(0, 2, 0, 2)
    dropList.Size       = UDim2.new(0, as.X, 0, cnt * 30 + 10)
    dropList.Position   = UDim2.new(0, ap.X, 0, ap.Y + as.Y + 4)
    dropList.Visible    = true
    dropOpen            = true
    tw(dropArrow, { Rotation = 180 })
end

local function populateDropdown(items)
    for _, c in ipairs(dropScroll:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
    end
    for _, it in ipairs(items) do
        local ib = Instance.new("TextButton", dropScroll)
        ib.Size             = UDim2.new(1, 0, 0, 28)
        ib.BackgroundColor3 = C.BTN
        ib.BorderSizePixel  = 0
        ib.Text             = it
        ib.Font             = Enum.Font.GothamSemibold
        ib.TextSize         = 12
        ib.TextColor3       = C.TEXT
        ib.TextXAlignment   = Enum.TextXAlignment.Left
        ib.AutoButtonColor  = false
        ib.ZIndex           = 52
        ib.TextTruncate     = Enum.TextTruncate.AtEnd
        local p = Instance.new("UIPadding", ib)
        p.PaddingLeft = UDim.new(0, 8)
        Instance.new("UICorner", ib).CornerRadius = UDim.new(0, 5)
        ib.MouseEnter:Connect(function() tw(ib, { BackgroundColor3 = C.BTN_HV }) end)
        ib.MouseLeave:Connect(function() tw(ib, { BackgroundColor3 = C.BTN   }) end)
        ib.MouseButton1Click:Connect(function()
            AB_item          = string.split(it, "  —  ")[1]
            dropLbl.Text     = it
            dropLbl.TextColor3 = C.TEXT
            setStatus("Selected: " .. AB_item, false)
            closeDropdown()
        end)
    end
end

dropBtn.MouseButton1Click:Connect(function()
    if dropOpen then closeDropdown() else openDropdown() end
end)

-- Close dropdown when clicking elsewhere
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and dropOpen then
        -- small delay so the dropBtn click fires first
        task.wait(0.02)
        if dropOpen then closeDropdown() end
    end
end)

-- Initial populate
task.spawn(function()
    task.wait(0.8)
    populateDropdown(grabItems())
end)

-- Refresh button
mkBtn("↺  Refresh Store Items", function()
    local items = grabItems()
    populateDropdown(items)
    setStatus("Found " .. #items .. " item(s)", false)
end)

-- ════════════════════════════════════════════════════
-- OPTIONS
-- ════════════════════════════════════════════════════
mkSep()
mkLabel("Options")

mkNumberInput("Amount to buy", 1, 9999, AB_amount, function(v) AB_amount = v end)

mkToggle("Open box after purchase", false, function(v)
    AB_openBox = v
end)

-- ════════════════════════════════════════════════════
-- ACTIONS
-- ════════════════════════════════════════════════════
mkSep()
mkLabel("Actions")

-- Primary buy button (styled slightly brighter when active)
local buyBtn = Instance.new("TextButton", autoBuyPage)
buyBtn.Size             = UDim2.new(1, -12, 0, 36)
buyBtn.BackgroundColor3 = C.BTN
buyBtn.Text             = "Purchase Selected"
buyBtn.Font             = Enum.Font.GothamBold
buyBtn.TextSize         = 14
buyBtn.TextColor3       = C.TEXT
buyBtn.BorderSizePixel  = 0
buyBtn.AutoButtonColor  = false
Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 6)
local buyStroke = Instance.new("UIStroke", buyBtn)
buyStroke.Color = C.BORDER; buyStroke.Thickness = 1; buyStroke.Transparency = 0
AB_buyBtn = buyBtn

buyBtn.MouseEnter:Connect(function()
    if not AB_buying then tw(buyBtn, { BackgroundColor3 = C.BTN_HV }) end
end)
buyBtn.MouseLeave:Connect(function()
    if not AB_buying then tw(buyBtn, { BackgroundColor3 = C.BTN }) end
end)

buyBtn.MouseButton1Click:Connect(function()
    if AB_buying then
        AB_aborted   = true
        buyBtn.Text  = "Purchase Selected"
        tw(buyBtn, { BackgroundColor3 = C.BTN })
        return
    end
    task.spawn(function()
        buyBtn.Text = "⏹  Click to Abort"
        tw(buyBtn, { BackgroundColor3 = Color3.fromRGB(38, 38, 38) })
        AB_buy(AB_item, AB_amount, AB_openBox, false)
        -- reset handled inside AB_buy
    end)
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
        local bps  = grabBlueprints()
        if #bps == 0 then
            setStatus("No blueprints found in stores", false)
            AB_buying = false; return
        end
        for i, bp in ipairs(bps) do
            if AB_aborted then break end
            setStatus("[" .. i .. "/" .. #bps .. "]  " .. bp, true)
            AB_buy(bp, 1, true, true)
        end
        AB_buying = false
        setStatus(AB_aborted and "Aborted." or ("Done — " .. #bps .. " blueprints"), false)
    end)
end)

mkBtn("Buy RukiryAxe  ($7,400)", function()
    if AB_buying then return end
    task.spawn(function()
        AB_buying = true

        local char   = player.Character
        local hrp    = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then AB_buying = false; return end
        local origin = hrp.CFrame

        local Dragging           = RS.Interaction and RS.Interaction:FindFirstChild("ClientIsDragging")
        local ClientInteracted   = RS:FindFirstChild("ClientInteracted",         true)
        local ClientGetUserPerms = RS:FindFirstChild("ClientGetUserPermissions", true)
        local playerName         = player.Name

        local function gentleTeleport(item, destPos)
            local m = item:FindFirstChild("Main")
            if not m then return end
            local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if h then h.CFrame = CFrame.new(m.CFrame.p) + Vector3.new(5, 0, 0) end
            task.wait(0.1)
            pcall(function()
                if not item.PrimaryPart then item.PrimaryPart = m end
                local t = 0
                while not isnetworkowner(m) and t < 3 do
                    if Dragging then Dragging:FireServer(item) end
                    task.wait(0.05); t += 0.05
                end
                if Dragging then Dragging:FireServer(item) end
                m:PivotTo(CFrame.new(destPos)); task.wait(0.05)
            end)
        end

        local function openAndTeleport(itemName, destPos)
            local box = RS:FindFirstChild("Box Purchased by " .. playerName, true)
                     or workspace:FindFirstChild("Box Purchased by " .. playerName, true)
            if not box then
                for _, v in next, workspace:GetDescendants() do
                    local iv    = v:FindFirstChild("ItemName")
                    local owner = v:FindFirstChild("Owner")
                    if iv and iv.Value == itemName and owner and owner.Value == player then
                        box = v; break
                    end
                end
            end
            if not box then return end
            local uid = tostring(player.UserId)
            if ClientGetUserPerms then
                ClientGetUserPerms:InvokeServer(uid, "Interact")
                ClientGetUserPerms:InvokeServer(uid, "MoveStructure")
                ClientGetUserPerms:InvokeServer(uid, "Destroy")
                task.wait(0.017)
                ClientGetUserPerms:InvokeServer(uid, "Grab")
            end
            task.wait(0.004)
            if ClientInteracted then ClientInteracted:FireServer(box, "Open box") end
            task.wait(0.3)
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
                if (iv and iv.Value == "Rukiryaxe") or (tn and tn.Value == "Rukiryaxe") then
                    axe = v; break
                end
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
            task.delay(30, function()
                if conn.Connected then conn:Disconnect() end; sig:Fire()
            end)
            sig.Event:Wait(); sig:Destroy()
        end

        if axe then
            setStatus("Picking up RukiryAxe…", true)
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
                    RS:FindFirstChild("Model", true) or workspace:FindFirstChild("Model", true),
                    "Pick up tool"
                )
            end
            task.wait(0.211)
            local ConfirmIdentity = RS:FindFirstChild("ConfirmIdentity", true)
            if ConfirmIdentity then
                ConfirmIdentity:InvokeServer(
                    RS:FindFirstChild("Tool", true) or workspace:FindFirstChild("Tool", true),
                    "Rukiryaxe"
                )
            end
            task.wait(0.243)
            local TestPing = RS:FindFirstChild("TestPing", true)
            if TestPing then TestPing:InvokeServer() end
            task.wait(0.5)
            local h2 = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if h2 then h2.CFrame = origin end
            setStatus("RukiryAxe obtained!", false)
        else
            setStatus("RukiryAxe didn't appear in time.", false)
        end

        AB_buying = false
    end)
end)

-- ════════════════════════════════════════════════════
-- SERVICES  (pay-at-counter shortcuts)
-- ════════════════════════════════════════════════════
mkSep()
mkLabel("Services  (pay at counter)")

local function mkSvcBtn(svc)
    local btn = mkBtn(svc.label, nil)   -- mkBtn already parents to autoBuyPage
    btn.TextColor3 = C.TEXT_MID
    btn.MouseButton1Click:Connect(function()
        task.spawn(function()
            local PC  = RS:FindFirstChild("PlayerChatted",    true)
            local SCV = RS:FindFirstChild("SetChattingValue", true)
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

for _, svc in ipairs(AB_Services) do
    mkSvcBtn(svc)
end

-- ════════════════════════════════════════════════════
-- CLEANUP
-- ════════════════════════════════════════════════════
table.insert(cleanupTasks, function()
    AB_aborted = true; AB_buying = false
    if dropList and dropList.Parent then dropList:Destroy() end
end)

print("[VanillaHub] Vanilla4 (AutoBuy) loaded — black/grey/white theme")
