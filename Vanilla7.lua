-- PATCHED makeFancyDropdown for Vanilla6 and Vanilla7
-- Replace the existing makeFancyDropdown function with this version


local function makeFancyDropdown(page, labelText, getOptions, cb)
    local selected = ""
    local isOpen   = false
    local ITEM_H   = 34; local MAX_SHOW = 5; local HEADER_H = 40
    local outer = Instance.new("Frame", page)
    outer.Size             = UDim2.new(1, -12, 0, HEADER_H)
    outer.BackgroundColor3 = C.ROW; outer.BorderSizePixel = 0
    outer.ClipsDescendants = true; corner(outer, 8)
    local outerStroke = Instance.new("UIStroke", outer)
    outerStroke.Color = C.BORDER; outerStroke.Thickness = 1; outerStroke.Transparency = 0.4
    local header = Instance.new("Frame", outer)
    header.Size = UDim2.new(1, 0, 0, HEADER_H); header.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", header)
    lbl.Size = UDim2.new(0, 80, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = labelText
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12; lbl.TextColor3 = C.TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local selFrame = Instance.new("Frame", header)
    selFrame.Size = UDim2.new(1, -96, 0, 28); selFrame.Position = UDim2.new(0, 90, 0.5, -14)
    selFrame.BackgroundColor3 = C.INPUT; selFrame.BorderSizePixel = 0; corner(selFrame, 6)
    local sfStroke = Instance.new("UIStroke", selFrame)
    sfStroke.Color = C.BORDER; sfStroke.Thickness = 1; sfStroke.Transparency = 0.3
    local selLbl = Instance.new("TextLabel", selFrame)
    selLbl.Size = UDim2.new(1, -36, 1, 0); selLbl.Position = UDim2.new(0, 10, 0, 0)
    selLbl.BackgroundTransparency = 1; selLbl.Text = "Select..."
    selLbl.Font = Enum.Font.GothamSemibold; selLbl.TextSize = 12
    selLbl.TextColor3 = C.TEXT_DIM; selLbl.TextXAlignment = Enum.TextXAlignment.Left
    selLbl.TextTruncate = Enum.TextTruncate.AtEnd
    -- PATCHED: ▲ with Rotation=180 = pointing down (closed state)
    local arrowLbl = Instance.new("TextLabel", selFrame)
    arrowLbl.Size = UDim2.new(0, 22, 1, 0); arrowLbl.Position = UDim2.new(1, -24, 0, 0)
    arrowLbl.BackgroundTransparency = 1; arrowLbl.Text = "▲"
    arrowLbl.Rotation = 180  -- closed: points down
    arrowLbl.Font = Enum.Font.GothamBold; arrowLbl.TextSize = 14
    arrowLbl.TextColor3 = C.TEXT_MID; arrowLbl.TextXAlignment = Enum.TextXAlignment.Center
    local headerBtn = Instance.new("TextButton", selFrame)
    headerBtn.Size = UDim2.new(1, 0, 1, 0); headerBtn.BackgroundTransparency = 1
    headerBtn.Text = ""; headerBtn.AutoButtonColor = false; headerBtn.ZIndex = 5
    local divider = Instance.new("Frame", outer)
    divider.Size = UDim2.new(1, -16, 0, 1); divider.Position = UDim2.new(0, 8, 0, HEADER_H)
    divider.BackgroundColor3 = C.BORDER; divider.BorderSizePixel = 0; divider.Visible = false
    local listScroll = Instance.new("ScrollingFrame", outer)
    listScroll.Position = UDim2.new(0, 0, 0, HEADER_H + 2); listScroll.Size = UDim2.new(1, 0, 0, 0)
    listScroll.BackgroundTransparency = 1; listScroll.BorderSizePixel = 0
    listScroll.ScrollBarThickness = 3; listScroll.ScrollBarImageColor3 = C.BORDER
    listScroll.CanvasSize = UDim2.new(0, 0, 0, 0); listScroll.ClipsDescendants = true
    local listLayout = Instance.new("UIListLayout", listScroll)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder; listLayout.Padding = UDim.new(0, 3)
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 6)
    end)
    local lp2 = Instance.new("UIPadding", listScroll)
    lp2.PaddingTop = UDim.new(0, 4); lp2.PaddingBottom = UDim.new(0, 4)
    lp2.PaddingLeft = UDim.new(0, 6); lp2.PaddingRight = UDim.new(0, 6)
    local function setSelected(name)
        selected = name; selLbl.Text = name; selLbl.TextColor3 = C.TEXT
        arrowLbl.TextColor3 = C.TEXT_MID; outerStroke.Color = C.BORDER; cb(name)
    end
    local function buildList()
        for _, c in ipairs(listScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        local opts = getOptions()
        for _, opt in ipairs(opts) do
            local item = Instance.new("TextButton", listScroll)
            item.Size = UDim2.new(1, 0, 0, ITEM_H); item.BackgroundColor3 = C.ROW
            item.Text = ""; item.BorderSizePixel = 0; item.AutoButtonColor = false; corner(item, 6)
            local iLbl = Instance.new("TextLabel", item)
            iLbl.Size = UDim2.new(1, -16, 1, 0); iLbl.Position = UDim2.new(0, 10, 0, 0)
            iLbl.BackgroundTransparency = 1; iLbl.Text = opt
            iLbl.Font = Enum.Font.GothamSemibold; iLbl.TextSize = 12
            iLbl.TextColor3 = C.TEXT; iLbl.TextXAlignment = Enum.TextXAlignment.Left
            iLbl.TextTruncate = Enum.TextTruncate.AtEnd
            item.MouseEnter:Connect(function()
                TS:Create(item, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(45,45,45)}):Play()
            end)
            item.MouseLeave:Connect(function()
                TS:Create(item, TweenInfo.new(0.1), {BackgroundColor3 = C.ROW}):Play()
            end)
            item.MouseButton1Click:Connect(function()
                setSelected(opt); isOpen = false
                -- PATCHED: close = ▲ pointing down = Rotation 180
                TS:Create(arrowLbl, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation = 180}):Play()
                TS:Create(outer, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,-12,0,HEADER_H)}):Play()
                TS:Create(listScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,0)}):Play()
                divider.Visible = false
            end)
        end
        return #opts
    end
    local function openList()
        isOpen = true; local count = buildList()
        local listH = math.min(count, MAX_SHOW) * (ITEM_H + 3) + 8; divider.Visible = true
        -- PATCHED: open = ▲ pointing up = Rotation 0
        TS:Create(arrowLbl, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
        TS:Create(outer, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(1,-12,0,HEADER_H+2+listH)}):Play()
        TS:Create(listScroll, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,listH)}):Play()
    end
    local function closeList()
        isOpen = false
        -- PATCHED: close = ▲ pointing down = Rotation 180
        TS:Create(arrowLbl, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation = 180}):Play()
        TS:Create(outer, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,-12,0,HEADER_H)}):Play()
        TS:Create(listScroll, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,0)}):Play()
        divider.Visible = false
    end
    headerBtn.MouseButton1Click:Connect(function() if isOpen then closeList() else openList() end end)
    headerBtn.MouseEnter:Connect(function()
        TS:Create(selFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(42,42,42)}):Play()
    end)
    headerBtn.MouseLeave:Connect(function()
        TS:Create(selFrame, TweenInfo.new(0.12), {BackgroundColor3 = C.INPUT}):Play()
    end)
    return {
        GetSelected = function() return selected end,
        Refresh = function()
            if isOpen then
                local count = buildList()
                local listH = math.min(count, MAX_SHOW) * (ITEM_H + 3) + 8
                outer.Size      = UDim2.new(1, -12, 0, HEADER_H + 2 + listH)
                listScroll.Size = UDim2.new(1, 0, 0, listH)
            end
        end
    }
end
