do
    local VH = _G.VH
    if not VH then
        warn("[WireArtTab] _G.VH not found — run Vanilla1 first.")
        return
    end

    local TweenService     = VH.TweenService
    local Players          = VH.Players
    local RunService       = VH.RunService
    local player           = VH.player
    local BTN_COLOR        = VH.BTN_COLOR
    local BTN_HOVER        = VH.BTN_HOVER
    local THEME_TEXT       = VH.THEME_TEXT
    local SEP_COLOR        = VH.SEP_COLOR
    local SECTION_TEXT     = VH.SECTION_TEXT
    local cleanupTasks     = VH.cleanupTasks
    local pages            = VH.pages

    local RS = game:GetService("ReplicatedStorage")

    local C = {
        bg       = Color3.fromRGB(8,  8,  14),
        panel    = Color3.fromRGB(14, 14, 22),
        border   = Color3.fromRGB(35, 35, 55),
        accent   = Color3.fromRGB(138, 92, 246),
        accentLo = Color3.fromRGB(76,  29, 149),
        text     = Color3.fromRGB(224, 224, 240),
        muted    = Color3.fromRGB(100, 100, 140),
        green    = Color3.fromRGB(100, 220, 120),
        red      = Color3.fromRGB(248, 100, 100),
        gold     = Color3.fromRGB(255, 200, 80),
        inputBg  = Color3.fromRGB(10,  10,  18),
    }

    local sections     = {}
    local buildRunning = false
    local buildThread  = nil
    local stopFlag     = false

    local function parseSectionTable(raw)
        local result = {}
        local stripped = raw:match("return%s*(%b{})") or raw:match("(%b{})")
        if not stripped then return result end
        local inner = stripped:sub(2, #stripped - 1)
        local pos = 1
        while pos <= #inner do
            local s = inner:find("{", pos, true)
            if not s then break end
            local d, e = 1, s + 1
            while e <= #inner and d > 0 do
                local c = inner:sub(e, e)
                if c == "{" then d = d + 1 elseif c == "}" then d = d - 1 end
                e = e + 1
            end
            local block = inner:sub(s + 1, e - 2)
            local pts = {}
            for x, y, z in block:gmatch("Vector3%.new%s*%(%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*%)") do
                local px, py, pz = tonumber(x), tonumber(y), tonumber(z)
                if px and py and pz then table.insert(pts, Vector3.new(px, py, pz)) end
            end
            if #pts == 0 then
                for line in block:gmatch("[^\n]+") do
                    local nums = {}
                    for n in line:gmatch("[%-%.%deE]+") do table.insert(nums, tonumber(n)) end
                    if #nums >= 3 and nums[1] and nums[2] and nums[3] then
                        table.insert(pts, Vector3.new(nums[1], nums[2], nums[3]))
                    end
                end
            end
            if #pts > 0 then table.insert(result, pts) end
            pos = e
        end
        return result
    end

    local function chunkByLength(pts, maxLen)
        local out = {}
        local i = 1
        while i <= #pts do
            local c = { pts[i] }
            local len, j = 0, i + 1
            while j <= #pts do
                local seg = (pts[j] - pts[j-1]).Magnitude
                if len + seg > maxLen and #c >= 2 then break end
                len = len + seg
                table.insert(c, pts[j])
                j = j + 1
            end
            table.insert(out, c)
            i = j - 1
            if j > #pts then break end
        end
        return out
    end

    local function globalCentroid(sectionList)
        local sx, sy, sz, n = 0, 0, 0, 0
        for _, pts in ipairs(sectionList) do
            for _, v in ipairs(pts) do
                sx = sx + v.X; sy = sy + v.Y; sz = sz + v.Z; n = n + 1
            end
        end
        if n == 0 then return 0, 0, 0 end
        return sx/n, sy/n, sz/n
    end

    local function applyOffsetWithCentroid(pts, cx, cy, cz, tx, ty, tz)
        local out = {}
        for _, v in ipairs(pts) do
            table.insert(out, Vector3.new(
                math.floor((v.X - cx + tx) * 10000 + 0.5) / 10000,
                math.floor((v.Y - cy + ty) * 10000 + 0.5) / 10000,
                math.floor((v.Z - cz + tz) * 10000 + 0.5) / 10000
            ))
        end
        return out
    end

    local DRAG_ITERS    = 50
    local RETURN_TIMEOUT = 10

    local function getItem(name)
        for _, store in next, workspace.Stores:GetChildren() do
            if store.Name == "ShopItems" then
                for _, v in next, store:GetChildren() do
                    local box = v:FindFirstChild("BoxItemName")
                    local own = v:FindFirstChild("Owner")
                    if box and box.Value == name and own and own.Value == nil then return v end
                end
            end
        end
        return nil
    end

    local function getCounter(main)
        local best, bd = nil, math.huge
        for _, store in next, workspace.Stores:GetChildren() do
            for _, c in next, store:GetChildren() do
                if c.Name:lower() == "counter" then
                    local d = (main.CFrame.p - c.CFrame.p).Magnitude
                    if d < bd then bd = d; best = c end
                end
            end
        end
        return best
    end

    local function buyWire(wireName, base)
        local item = getItem(wireName)
        if not item then warn("[WireBot] Item not found: " .. wireName); return false end
        local main = item:FindFirstChild("Main")
        if not main then warn("[WireBot] No Main part"); return false end
        player.Character.HumanoidRootPart.CFrame = main.CFrame + Vector3.new(5, 0, 5)
        task.wait(0.09)
        local counter = getCounter(main)
        if not counter then warn("[WireBot] No counter found"); return false end
        for _ = 1, DRAG_ITERS do
            RS.Interaction.ClientIsDragging:FireServer(item)
            main.CFrame = counter.CFrame + Vector3.new(0, main.Size.Y, 0.5)
            task.wait()
        end
        task.wait(0.08)
        player.Character.HumanoidRootPart.CFrame = counter.CFrame + Vector3.new(5, 0, 5)
        task.wait(0.08)
        local args = {Character="Lincoln", Name="Lincoln", ID=14, Dialog="Dialog"}
        RS:FindFirstChild("PlayerChatted", true):InvokeServer(args, "Initiate")
        task.wait(0.04)
        RS:FindFirstChild("PlayerChatted", true):InvokeServer(args, "ConfirmPurchase")
        task.wait(0.03)
        RS:FindFirstChild("PlayerChatted", true):InvokeServer(args, "EndChat")
        task.wait(0.04)
        mousemoveabs(762, 151)
        task.wait(0.01)
        local t0, done = tick(), false
        repeat
            if tick() - t0 > RETURN_TIMEOUT then warn("[WireBot] Return timeout"); break end
            pcall(function()
                player.Character.HumanoidRootPart.CFrame = main.CFrame + Vector3.new(5, 0, 5)
                RS.Interaction.ClientIsDragging:FireServer(item)
                task.wait()
                if isnetworkowner(main) then
                    RS.Interaction.ClientIsDragging:FireServer(item)
                    main.CFrame = CFrame.new(base.p)
                    done = true
                end
            end)
            task.wait(0.05)
        until done
        player.Character.HumanoidRootPart.CFrame = base + Vector3.new(5, 1, 0)
        return done
    end

    local function placeWire(chunkData, wireName, orderTag, permId)
        mousemoveabs(619, 84); task.wait(0.05)
        mousemoveabs(400, 149); task.wait(0.08)
        for _ = 1, 6 do
            RS:FindFirstChild("ClientGetUserPermissions", true):InvokeServer(
                permId, {[1]="PlaceStructure",[2]="MoveStructure",[3]="Destroy"}
            )
            task.wait(0.08)
        end
        task.wait(0.08)
        RS:FindFirstChild("ClientPlacedWire", true):FireServer(
            RS:FindFirstChild(wireName, true) or workspace:FindFirstChild(wireName, true),
            chunkData,
            RS:FindFirstChild(orderTag, true) or workspace:FindFirstChild(orderTag, true),
            RS:FindFirstChild("Box Purchased by " .. orderTag, true) or workspace:FindFirstChild("Box Purchased by " .. orderTag, true),
            true
        )
        task.wait(0.65)
        mousemoveabs(735, 84); task.wait(0.15)
    end

    local page = pages["Wire ArtTab"]
    if not page then warn("[WireArtTab] 'Wire Art' tab page not found in _G.VH.pages"); return end

    for _, child in ipairs(page:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end

    local function makeCard(lo)
        local f = Instance.new("Frame")
        f.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
        f.BorderSizePixel  = 0
        f.Size             = UDim2.new(1, 0, 0, 10)
        f.AutomaticSize    = Enum.AutomaticSize.Y
        f.LayoutOrder      = lo
        f.Parent           = page
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
        local stroke = Instance.new("UIStroke", f)
        stroke.Color = SEP_COLOR; stroke.Thickness = 1; stroke.Transparency = 0.35
        local pad = Instance.new("UIPadding", f)
        pad.PaddingLeft   = UDim.new(0, 10); pad.PaddingRight  = UDim.new(0, 10)
        pad.PaddingTop    = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10)
        local list = Instance.new("UIListLayout", f)
        list.Padding          = UDim.new(0, 7)
        list.FillDirection    = Enum.FillDirection.Vertical
        list.SortOrder        = Enum.SortOrder.LayoutOrder
        return f
    end

    local function sectionHeader(title, lo)
        local lbl = Instance.new("TextLabel")
        lbl.Size               = UDim2.new(1, 0, 0, 18)
        lbl.BackgroundTransparency = 1
        lbl.Font               = Enum.Font.GothamBold
        lbl.TextSize           = 10
        lbl.TextColor3         = SECTION_TEXT
        lbl.TextXAlignment     = Enum.TextXAlignment.Left
        lbl.Text               = "  " .. title:upper()
        lbl.LayoutOrder        = lo
        lbl.Parent             = page
        return lbl
    end

    local function rowLabel(parent, text, lo)
        local l = Instance.new("TextLabel")
        l.Size               = UDim2.new(1, 0, 0, 16)
        l.BackgroundTransparency = 1
        l.Font               = Enum.Font.Gotham
        l.TextSize           = 11
        l.TextColor3         = Color3.fromRGB(120, 120, 120)
        l.TextXAlignment     = Enum.TextXAlignment.Left
        l.Text               = text
        l.LayoutOrder        = lo
        l.Parent             = parent
        return l
    end

    local function makeInput(parent, placeholder, default, lo)
        local box = Instance.new("TextBox")
        box.PlaceholderText  = placeholder or ""
        box.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
        box.Text             = default or ""
        box.TextColor3       = THEME_TEXT
        box.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        box.BorderSizePixel  = 0
        box.Size             = UDim2.new(1, 0, 0, 28)
        box.Font             = Enum.Font.Code
        box.TextSize         = 12
        box.TextXAlignment   = Enum.TextXAlignment.Left
        box.ClearTextOnFocus = false
        box.LayoutOrder      = lo or 0
        box.Parent           = parent
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
        local pad = Instance.new("UIPadding", box)
        pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8)
        local s = Instance.new("UIStroke", box)
        s.Color = SEP_COLOR; s.Thickness = 1
        box.Focused:Connect(function()   s.Color = C.accent  end)
        box.FocusLost:Connect(function() s.Color = SEP_COLOR end)
        return box
    end

    local function makeMultiInput(parent, placeholder, lo)
        local box = Instance.new("TextBox")
        box.PlaceholderText  = placeholder or ""
        box.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
        box.Text             = ""
        box.TextColor3       = THEME_TEXT
        box.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        box.BorderSizePixel  = 0
        box.Size             = UDim2.new(1, 0, 0, 110)
        box.Font             = Enum.Font.Code
        box.TextSize         = 11
        box.TextXAlignment   = Enum.TextXAlignment.Left
        box.TextYAlignment   = Enum.TextYAlignment.Top
        box.ClearTextOnFocus = false
        box.MultiLine        = true
        box.TextWrapped      = true
        box.LayoutOrder      = lo or 0
        box.Parent           = parent
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
        local pad = Instance.new("UIPadding", box)
        pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8)
        pad.PaddingTop  = UDim.new(0, 6)
        local s = Instance.new("UIStroke", box)
        s.Color = SEP_COLOR; s.Thickness = 1
        box.Focused:Connect(function()   s.Color = C.accent  end)
        box.FocusLost:Connect(function() s.Color = SEP_COLOR end)
        return box
    end

    local function makeBtn(parent, text, bg, bgHov, lo)
        local btn = Instance.new("TextButton")
        btn.Text             = text
        btn.TextColor3       = THEME_TEXT
        btn.BackgroundColor3 = bg
        btn.BorderSizePixel  = 0
        btn.Size             = UDim2.new(1, 0, 0, 32)
        btn.Font             = Enum.Font.GothamBold
        btn.TextSize         = 13
        btn.AutoButtonColor  = false
        btn.LayoutOrder      = lo or 0
        btn.Parent           = parent
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = bgHov}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = bg}):Play()
        end)
        return btn
    end

    local function makeBarBg(parent, lo)
        local bg = Instance.new("Frame")
        bg.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        bg.BorderSizePixel  = 0
        bg.Size             = UDim2.new(1, 0, 0, 7)
        bg.LayoutOrder      = lo or 0
        bg.Parent           = parent
        Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
        return bg
    end

    local function makeBarFill(bg, color)
        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = color
        fill.BorderSizePixel  = 0
        fill.Size             = UDim2.new(0, 0, 1, 0)
        fill.Parent           = bg
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
        return fill
    end

    sectionHeader("Section Table Input", 1)
    local card1 = makeCard(2)

    rowLabel(card1, "Paste return { {...}, {...} } below:", 1)
    local PointsBox = makeMultiInput(card1,
        "return {\n  { Vector3.new(x,y,z), ... },\n  { Vector3.new(x,y,z), ... },\n}", 2)

    local ParseStatus = Instance.new("TextLabel")
    ParseStatus.Size               = UDim2.new(1, 0, 0, 16)
    ParseStatus.BackgroundTransparency = 1
    ParseStatus.Font               = Enum.Font.Gotham
    ParseStatus.TextSize           = 11
    ParseStatus.TextColor3         = Color3.fromRGB(110, 110, 110)
    ParseStatus.TextXAlignment     = Enum.TextXAlignment.Center
    ParseStatus.Text               = "— paste table above then parse —"
    ParseStatus.LayoutOrder        = 3
    ParseStatus.Parent             = card1

    local ParseBtn = makeBtn(card1, "Parse & Preview Sections",
        C.accentLo, C.accent, 4)

    sectionHeader("Origin / Offset (all sections)", 3)
    local card2 = makeCard(4)

    rowLabel(card2, "Build center (world X / Y / Z):", 1)

    local xyzRow = Instance.new("Frame")
    xyzRow.BackgroundTransparency = 1
    xyzRow.Size        = UDim2.new(1, 0, 0, 28)
    xyzRow.LayoutOrder = 2
    xyzRow.Parent      = card2
    local xyzLL = Instance.new("UIListLayout", xyzRow)
    xyzLL.FillDirection      = Enum.FillDirection.Horizontal
    xyzLL.Padding            = UDim.new(0, 5)
    xyzLL.VerticalAlignment  = Enum.VerticalAlignment.Center

    local function xyzField(label, default)
        local wrap = Instance.new("Frame", xyzRow)
        wrap.BackgroundTransparency = 1
        wrap.Size = UDim2.new(0.33, -4, 1, 0)
        local lbl = Instance.new("TextLabel", wrap)
        lbl.Size = UDim2.new(0, 14, 0, 14); lbl.Position = UDim2.new(0,0,0,0)
        lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 9; lbl.TextColor3 = C.accent
        lbl.TextXAlignment = Enum.TextXAlignment.Center
        lbl.Text = label
        local inp = Instance.new("TextBox", wrap)
        inp.Size = UDim2.new(1, 0, 0, 28); inp.Position = UDim2.new(0, 0, 0, 0)
        inp.BackgroundColor3 = Color3.fromRGB(10,10,10); inp.BorderSizePixel = 0
        inp.Font = Enum.Font.Code; inp.TextSize = 12; inp.TextColor3 = THEME_TEXT
        inp.Text = tostring(default); inp.ClearTextOnFocus = false
        inp.TextXAlignment = Enum.TextXAlignment.Center
        Instance.new("UICorner", inp).CornerRadius = UDim.new(0,6)
        local pad = Instance.new("UIPadding", inp)
        pad.PaddingLeft = UDim.new(0,6); pad.PaddingRight = UDim.new(0,6)
        local s = Instance.new("UIStroke", inp)
        s.Color = SEP_COLOR; s.Thickness = 1
        inp.Focused:Connect(function()   s.Color = C.accent  end)
        inp.FocusLost:Connect(function() s.Color = SEP_COLOR end)
        return inp
    end

    local OffX = xyzField("X", 0)
    local OffY = xyzField("Y", 0)
    local OffZ = xyzField("Z", 0)

    local resetOffBtn = makeBtn(card2, "⟳  Reset Offset",
        Color3.fromRGB(18,18,24), Color3.fromRGB(34,34,48), 3)
    resetOffBtn.TextColor3 = Color3.fromRGB(120,120,120)
    resetOffBtn.TextSize   = 11
    resetOffBtn.MouseButton1Click:Connect(function()
        OffX.Text = "0"; OffY.Text = "0"; OffZ.Text = "0"
    end)

    sectionHeader("Configuration", 5)
    local card3 = makeCard(6)

    rowLabel(card3, "Order Tag:", 1)
    local cfg_order = makeInput(card3, "Username", player.Name, 2)

    rowLabel(card3, "Permission ID:", 3)
    local cfg_perm  = makeInput(card3, "UserID", tostring(player.UserId), 4)

    rowLabel(card3, "Wire Asset Name:", 5)
    local cfg_wire  = makeInput(card3, "NeonWireWhite", "NeonWireWhite", 6)

    rowLabel(card3, "Batch Size (buy N → place N):", 7)
    local cfg_batch = makeInput(card3, "50", "50", 8)

    sectionHeader("Status", 7)
    local card4 = makeCard(8)

    local SectionLabel = Instance.new("TextLabel")
    SectionLabel.Size               = UDim2.new(1, 0, 0, 20)
    SectionLabel.BackgroundTransparency = 1
    SectionLabel.Font               = Enum.Font.GothamBold
    SectionLabel.TextSize           = 13
    SectionLabel.TextColor3         = Color3.fromRGB(110,110,110)
    SectionLabel.TextXAlignment     = Enum.TextXAlignment.Center
    SectionLabel.Text               = "⬤  Idle"
    SectionLabel.LayoutOrder        = 1
    SectionLabel.Parent             = card4

    local SecBar_bg   = makeBarBg(card4, 2)
    local SecBar_fill = makeBarFill(SecBar_bg, C.gold)

    local SecBarLabel = Instance.new("TextLabel")
    SecBarLabel.Size               = UDim2.new(1, 0, 0, 14)
    SecBarLabel.BackgroundTransparency = 1
    SecBarLabel.Font               = Enum.Font.Code
    SecBarLabel.TextSize           = 10
    SecBarLabel.TextColor3         = C.gold
    SecBarLabel.TextXAlignment     = Enum.TextXAlignment.Center
    SecBarLabel.Text               = ""
    SecBarLabel.LayoutOrder        = 3
    SecBarLabel.Parent             = card4

    local TotalBar_bg   = makeBarBg(card4, 4)
    local TotalBar_fill = makeBarFill(TotalBar_bg, C.accent)

    local LogLabel = Instance.new("TextLabel")
    LogLabel.Size               = UDim2.new(1, 0, 0, 28)
    LogLabel.BackgroundTransparency = 1
    LogLabel.Font               = Enum.Font.Code
    LogLabel.TextSize           = 10
    LogLabel.TextColor3         = Color3.fromRGB(110,110,110)
    LogLabel.TextXAlignment     = Enum.TextXAlignment.Center
    LogLabel.TextWrapped        = true
    LogLabel.Text               = ""
    LogLabel.LayoutOrder        = 5
    LogLabel.Parent             = card4

    local function setStatus(msg, color)
        SectionLabel.Text       = msg
        SectionLabel.TextColor3 = color or THEME_TEXT
    end

    local function setSectionProgress(secIdx, totalSec)
        local pct = totalSec > 0 and (secIdx / totalSec) or 0
        TweenService:Create(SecBar_fill, TweenInfo.new(0.3), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
        SecBarLabel.Text = totalSec > 0
            and string.format("Section %d / %d", secIdx, totalSec)
            or ""
    end

    local function setWireProgress(done, total)
        local pct = total > 0 and (done / total) or 0
        TweenService:Create(TotalBar_fill, TweenInfo.new(0.3), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
        LogLabel.Text = string.format("%d / %d wires placed (total)", done, total)
    end

    local function log(msg)
        LogLabel.Text = msg
    end

    sectionHeader("Build", 9)
    local card5 = makeCard(10)

    local InfoLabel = Instance.new("TextLabel")
    InfoLabel.Size               = UDim2.new(1, 0, 0, 28)
    InfoLabel.BackgroundTransparency = 1
    InfoLabel.Font               = Enum.Font.Code
    InfoLabel.TextSize           = 10
    InfoLabel.TextColor3         = Color3.fromRGB(110,110,110)
    InfoLabel.TextXAlignment     = Enum.TextXAlignment.Center
    InfoLabel.TextWrapped        = true
    InfoLabel.Text               = "Parse sections first, then press Build Art."
    InfoLabel.LayoutOrder        = 1
    InfoLabel.Parent             = card5

    local BuildBtn = makeBtn(card5, "▶  BUILD ART",
        Color3.fromRGB(30, 110, 60), Color3.fromRGB(50, 160, 90), 2)
    BuildBtn.TextSize = 14

    local StopBtn = makeBtn(card5, "⏹  STOP BUILD",
        Color3.fromRGB(120, 28, 28), Color3.fromRGB(190, 45, 45), 3)

    ParseBtn.MouseButton1Click:Connect(function()
        local raw = PointsBox.Text
        if raw == "" then
            ParseStatus.Text       = "⚠  No input."
            ParseStatus.TextColor3 = C.red
            return
        end

        local tx = tonumber(OffX.Text) or 0
        local ty = tonumber(OffY.Text) or 0
        local tz = tonumber(OffZ.Text) or 0

        local rawSections = parseSectionTable(raw)
        if #rawSections == 0 then
            ParseStatus.Text       = "⚠  No sections found. Check format."
            ParseStatus.TextColor3 = C.red
            return
        end

        sections = {}
        local totalWires, totalPoints = 0, 0
        local gcx, gcy, gcz = globalCentroid(rawSections)

        for i, pts in ipairs(rawSections) do
            local offPts = applyOffsetWithCentroid(pts, gcx, gcy, gcz, tx, ty, tz)
            local chunked = chunkByLength(offPts, 25)
            table.insert(sections, {
                chunks     = chunked,
                pointCount = #offPts,
                label      = "Section " .. i,
                rawPts     = offPts,
            })
            totalWires  = totalWires  + #chunked
            totalPoints = totalPoints + #offPts
        end

        ParseStatus.Text       = string.format("✅  %d sections · %d pts · %d wires", #sections, totalPoints, totalWires)
        ParseStatus.TextColor3 = C.green

        local lines = {}
        for i, sec in ipairs(sections) do
            table.insert(lines, string.format("S%d: %d pts → %d wires", i, sec.pointCount, #sec.chunks))
        end
        InfoLabel.Text = table.concat(lines, "  |  ")

        setStatus("⬤  Ready — " .. #sections .. " sections, " .. totalWires .. " wires", C.gold)
        setSectionProgress(0, #sections)
        setWireProgress(0, totalWires)

        task.spawn(function()
            local folder = workspace:FindFirstChild("WirePreview")
            if folder then folder:Destroy() end
            folder = Instance.new("Folder"); folder.Name = "WirePreview"; folder.Parent = workspace
            local sectionColors = {
                Color3.fromRGB(138, 92, 246), Color3.fromRGB(80, 200, 160),
                Color3.fromRGB(240, 160, 60),  Color3.fromRGB(220, 80, 80),
                Color3.fromRGB(80, 140, 220),  Color3.fromRGB(200, 200, 80),
            }
            for si, sec in ipairs(sections) do
                local col = sectionColors[((si-1) % #sectionColors) + 1]
                local offPts = sec.rawPts
                for i, pt in ipairs(offPts) do
                    local p = Instance.new("Part")
                    p.Size = Vector3.new(0.3,0.3,0.3); p.Shape = Enum.PartType.Ball
                    p.Material = Enum.Material.Neon; p.Color = col
                    p.CFrame = CFrame.new(pt); p.Anchored = true; p.CanCollide = false
                    p.Parent = folder
                    if i > 1 then
                        local prev = offPts[i-1]
                        local mid  = (pt + prev) / 2
                        local dist = (pt - prev).Magnitude
                        if dist > 0.1 then
                            local beam = Instance.new("Part")
                            beam.Size = Vector3.new(0.08,0.08,dist)
                            beam.CFrame = CFrame.new(mid, pt)
                            beam.Material = Enum.Material.Neon; beam.Color = col
                            beam.Anchored = true; beam.CanCollide = false
                            beam.Parent = folder
                        end
                    end
                    if i % 20 == 0 then task.wait() end
                end
            end
            log("Preview spawned — each section is a different colour.")
        end)
    end)

    BuildBtn.MouseButton1Click:Connect(function()
        if buildRunning then log("Build already running! Press Stop first."); return end
        if #sections == 0 then setStatus("⚠  Parse sections first!", C.red); return end

        local wireName  = cfg_wire.Text  ~= "" and cfg_wire.Text  or "NeonWireWhite"
        local orderTag  = cfg_order.Text ~= "" and cfg_order.Text or player.Name
        local permId    = cfg_perm.Text  ~= "" and cfg_perm.Text  or tostring(player.UserId)
        local batchSize = math.max(1, tonumber(cfg_batch.Text) or 50)

        local totalWires = 0
        for _, sec in ipairs(sections) do totalWires = totalWires + #sec.chunks end

        buildRunning = true
        stopFlag     = false

        buildThread = task.spawn(function()
            local base = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not base then
                setStatus("⚠  No character found!", C.red)
                buildRunning = false
                return
            end
            local baseCF  = base.CFrame
            local globalDone = 0

            setStatus("⬤  Building...", C.green)
            setWireProgress(0, totalWires)
            setSectionProgress(0, #sections)

            for si, sec in ipairs(sections) do
                if stopFlag then break end
                local secChunks = sec.chunks
                local secTotal  = #secChunks
                local secDone   = 0

                setStatus(string.format("⬤  Section %d / %d", si, #sections), C.gold)
                setSectionProgress(si - 1, #sections)
                log(string.format("Starting %s (%d wires)...", sec.label, secTotal))

                while secDone < secTotal and not stopFlag do
                    local bEnd  = math.min(secDone + batchSize, secTotal)
                    local bSize = bEnd - secDone

                    for i = 1, bSize do
                        if stopFlag then break end
                        local absIdx = secDone + i
                        log(string.format("[S%d] Buying wire %d/%d...", si, absIdx, secTotal))
                        setStatus(string.format("🛒  S%d · Buying %d/%d", si, absIdx, secTotal), C.gold)
                        local ok = buyWire(wireName, baseCF)
                        if not ok then log("Buy failed — retrying..."); task.wait(1) end
                        task.wait(0.2)
                    end
                    if stopFlag then break end

                    for i = 1, bSize do
                        if stopFlag then break end
                        local ci        = secDone + i
                        local chunkData = {}
                        for idx, pt in ipairs(secChunks[ci]) do chunkData[idx] = pt end

                        log(string.format("[S%d] Placing wire %d/%d...", si, ci, secTotal))
                        setStatus(string.format("🔨  S%d · Placing %d/%d", si, ci, secTotal), C.accent)
                        placeWire(chunkData, wireName, orderTag, permId)

                        globalDone = globalDone + 1
                        setWireProgress(globalDone, totalWires)
                    end

                    secDone = bEnd
                end

                if not stopFlag then
                    setSectionProgress(si, #sections)
                    log(string.format("Section %d complete.", si))
                    task.wait(0.3)
                end
            end

            if stopFlag then
                setStatus(string.format("⏹  Stopped · %d/%d wires placed", globalDone, totalWires), C.red)
                log("Build stopped by user.")
            else
                setStatus("✅  ALL DONE! " .. totalWires .. " wires placed.", C.green)
                log("Build complete.")
                setWireProgress(totalWires, totalWires)
                setSectionProgress(#sections, #sections)
            end
            buildRunning = false
        end)
    end)

    StopBtn.MouseButton1Click:Connect(function()
        if not buildRunning then log("No build is running."); return end
        stopFlag = true
        log("Stop requested — finishing current wire...")
        setStatus("⏹  Stopping...", C.red)
    end)

    table.insert(cleanupTasks, function()
        if buildThread then pcall(task.cancel, buildThread); buildThread = nil end
        buildRunning = false
        stopFlag     = true
        local folder = workspace:FindFirstChild("WirePreview")
        if folder then folder:Destroy() end
    end)

    setStatus("⬤  Idle — paste section table & parse", Color3.fromRGB(110,110,110))
    print("[VanillaHub] Wire Art tab loaded ✓")
end
