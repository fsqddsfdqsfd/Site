-- GitanX UI Library
-- Version 1.0.0
-- Author: You
-- Description: Modern Roblox UI library similar to Rayfield, with themes, tabs, controls, notifications, config saving.

local GitanX = {}

-- Utility
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local function protectGUI(gui)
    if syn and syn.protect_gui then
        syn.protect_gui(gui)
    elseif gethui then
        gui.Parent = gethui()
        return
    end
    gui.Parent = game:GetService("CoreGui")
end

local function safePCall(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        warn("[GitanX] Callback error:", err)
    end
end

local function deepCopy(tbl)
    local t = {}
    for k,v in pairs(tbl) do
        t[k] = type(v) == "table" and deepCopy(v) or v
    end
    return t
end

-- Theme system
local Themes = {
    Default = {
        Text = Color3.fromRGB(240,240,240),
        Background = Color3.fromRGB(20,20,24),
        Accent = Color3.fromRGB(95,135,255),
        Accent2 = Color3.fromRGB(60,95,220),
        Section = Color3.fromRGB(30,30,36),
        Button = Color3.fromRGB(35,35,42),
        ToggleOn = Color3.fromRGB(95,200,120),
        ToggleOff = Color3.fromRGB(100,100,110),
        SliderBg = Color3.fromRGB(40,40,50),
        SliderFill = Color3.fromRGB(95,135,255),
        DropdownBg = Color3.fromRGB(35,35,42),
        Notification = Color3.fromRGB(25,25,30),
        Border = Color3.fromRGB(50,50,60),
        Shadow = Color3.fromRGB(0,0,0),
    },
    Ocean = {
        Text = Color3.fromRGB(235,245,255),
        Background = Color3.fromRGB(18,24,32),
        Accent = Color3.fromRGB(60,160,220),
        Accent2 = Color3.fromRGB(40,120,180),
        Section = Color3.fromRGB(24,30,38),
        Button = Color3.fromRGB(28,36,46),
        ToggleOn = Color3.fromRGB(70,190,210),
        ToggleOff = Color3.fromRGB(95,110,130),
        SliderBg = Color3.fromRGB(30,40,52),
        SliderFill = Color3.fromRGB(60,160,220),
        DropdownBg = Color3.fromRGB(28,36,46),
        Notification = Color3.fromRGB(22,28,36),
        Border = Color3.fromRGB(45,60,80),
        Shadow = Color3.fromRGB(0,0,0),
    },
    Amethyst = {
        Text = Color3.fromRGB(245,240,255),
        Background = Color3.fromRGB(24,22,30),
        Accent = Color3.fromRGB(155,100,230),
        Accent2 = Color3.fromRGB(120,80,200),
        Section = Color3.fromRGB(28,26,36),
        Button = Color3.fromRGB(32,30,40),
        ToggleOn = Color3.fromRGB(180,120,240),
        ToggleOff = Color3.fromRGB(110,100,120),
        SliderBg = Color3.fromRGB(36,34,44),
        SliderFill = Color3.fromRGB(155,100,230),
        DropdownBg = Color3.fromRGB(32,30,40),
        Notification = Color3.fromRGB(26,24,34),
        Border = Color3.fromRGB(60,50,80),
        Shadow = Color3.fromRGB(0,0,0),
    },
    Light = {
        Text = Color3.fromRGB(24,24,28),
        Background = Color3.fromRGB(245,245,250),
        Accent = Color3.fromRGB(60,120,255),
        Accent2 = Color3.fromRGB(40,90,220),
        Section = Color3.fromRGB(230,230,240),
        Button = Color3.fromRGB(235,235,245),
        ToggleOn = Color3.fromRGB(60,175,95),
        ToggleOff = Color3.fromRGB(160,160,170),
        SliderBg = Color3.fromRGB(220,220,230),
        SliderFill = Color3.fromRGB(60,120,255),
        DropdownBg = Color3.fromRGB(235,235,245),
        Notification = Color3.fromRGB(230,230,240),
        Border = Color3.fromRGB(200,200,210),
        Shadow = Color3.fromRGB(0,0,0),
    },
}

local function applyThemeTo(instance, theme, props)
    for k,v in pairs(props) do
        if theme[k] and instance[v] ~= nil then
            instance[v] = theme[k]
        end
    end
end

-- Lucide-like icons (simple glyphs via Text)
local Icons = {
    Tabs = "⏷",
    Button = "⯈",
    ToggleOn = "⦿",
    ToggleOff = "⦾",
    Slider = "⎯",
    Dropdown = "▾",
    Key = "⌨",
    Info = "ℹ",
    Success = "✔",
    Warning = "⚠",
    Error = "✖",
}

-- Config
local function ensureFolder(path)
    local ok, err = pcall(function()
        if isfolder then
            if not isfolder(path) then makefolder(path) end
        end
    end)
    if not ok then
        warn("[GitanX] Config folder not created:", err)
    end
end

local function writeFile(path, data)
    local ok, err = pcall(function()
        if writefile then writefile(path, data) end
    end)
    if not ok then
        warn("[GitanX] writefile failed:", err)
    end
end

local function readFile(path)
    local ok, result = pcall(function()
        if readfile and isfile and isfile(path) then return readfile(path) end
        return nil
    end)
    if ok then return result end
    return nil
end

-- Core GUI creation
local function createScreenGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = "GitanXUI"
    gui.ResetOnSpawn = false
    protectGUI(gui)
    return gui
end

local function createRound(frame, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = frame
    return corner
end

local function createStroke(frame, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 1
    stroke.Color = color or Color3.new(1,1,1)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = frame
    return stroke
end

local function tween(i, t, p)
    return TweenService:Create(i, TweenInfo.new(t or 0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), p or {})
end

-- Library state
GitanX.__index = GitanX

function GitanX:CreateWindow(opts)
    local options = opts or {}
    local name = options.Name or "GitanX"
    local loadingTitle = options.LoadingTitle or "Loading..."
    local loadingSubtitle = options.LoadingSubtitle or "Powered by GitanX"
    local config = options.ConfigurationSaving or { Enabled = false }
    local themeName = (options.Theme and Themes[options.Theme]) and options.Theme or "Default"

    self._themeName = themeName
    self._theme = Themes[themeName]
    self._configEnabled = config.Enabled or false
    self._configFolder = config.FolderName or "GitanXConfig"
    self._configFile = config.FileName or "Config.gx"
    self._saveMap = {} -- controlID -> value
    self._controls = {} -- refs
    self._tabs = {}

    local gui = createScreenGui()

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 620, 0, 420)
    main.Position = UDim2.new(0.5, -310, 0.45, -210)
    main.BackgroundColor3 = self._theme.Background
    main.BorderSizePixel = 0
    main.Parent = gui
    createRound(main, 12)
    createStroke(main, self._theme.Border, 1)

    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Image = "rbxassetid://976220798"
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(20,20,280,280)
    shadow.Size = UDim2.new(1, 24, 1, 24)
    shadow.Position = UDim2.new(0, -12, 0, -12)
    shadow.BackgroundTransparency = 1
    shadow.ImageColor3 = self._theme.Shadow
    shadow.ImageTransparency = 0.9
    shadow.Parent = main

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, -20, 0, 56)
    header.Position = UDim2.new(0, 10, 0, 10)
    header.BackgroundColor3 = self._theme.Section
    header.BorderSizePixel = 0
    header.Parent = main
    createRound(header, 10)
    createStroke(header, self._theme.Border, 1)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 28)
    title.Position = UDim2.new(0, 10, 0, 6)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = self._theme.Text
    title.Text = name
    title.BackgroundTransparency = 1
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -20, 0, 20)
    subtitle.Position = UDim2.new(0, 10, 0, 30)
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 14
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.TextColor3 = self._theme.Text
    subtitle.TextTransparency = 0.2
    subtitle.Text = loadingSubtitle
    subtitle.BackgroundTransparency = 1
    subtitle.Parent = header

    local tabbar = Instance.new("Frame")
    tabbar.Name = "TabBar"
    tabbar.Size = UDim2.new(0, 180, 1, -76)
    tabbar.Position = UDim2.new(0, 10, 0, 66)
    tabbar.BackgroundColor3 = self._theme.Section
    tabbar.BorderSizePixel = 0
    tabbar.Parent = main
    createRound(tabbar, 10)
    createStroke(tabbar, self._theme.Border, 1)

    local tabList = Instance.new("UIListLayout")
    tabList.FillDirection = Enum.FillDirection.Vertical
    tabList.Padding = UDim.new(0,8)
    tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabList.VerticalAlignment = Enum.VerticalAlignment.Top
    tabList.Parent = tabbar

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -210, 1, -76)
    content.Position = UDim2.new(0, 200, 0, 66)
    content.BackgroundColor3 = self._theme.Section
    content.BorderSizePixel = 0
    content.Parent = main
    createRound(content, 10)
    createStroke(content, self._theme.Border, 1)

    local pages = Instance.new("Folder")
    pages.Name = "Pages"
    pages.Parent = content

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -20, 0, 20)
    info.Position = UDim2.new(0, 10, 0, 10)
    info.Font = Enum.Font.Gotham
    info.TextSize = 14
    info.TextXAlignment = Enum.TextXAlignment.Right
    info.TextColor3 = self._theme.Text
    info.TextTransparency = 0.2
    info.Text = loadingTitle
    info.BackgroundTransparency = 1
    info.Parent = content

    self._gui = gui
    self._main = main
    self._header = header
    self._tabbar = tabbar
    self._content = content
    self._pages = pages

    -- Dragging
    local dragging = false
    local dragInput, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Config load
    if self._configEnabled then
        ensureFolder(self._configFolder)
        local raw = readFile(self._configFolder.."/"..self._configFile)
        if raw then
            local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok and type(data) == "table" then
                self._saveMap = data
            end
        end
    end

    -- API
    local windowAPI = {}

    function windowAPI:CreateTab(tabName, iconId)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, -16, 0, 36)
        tabBtn.Text = (iconId and "") or (Icons.Tabs.."  ") .. (tabName or "Tab")
        tabBtn.TextColor3 = GitanX._theme.Text
        tabBtn.BackgroundColor3 = GitanX._theme.Button
        tabBtn.Font = Enum.Font.Gotham
        tabBtn.TextSize = 14
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = GitanX._tabbar
        createRound(tabBtn, 8)
        createStroke(tabBtn, GitanX._theme.Border, 1)

        local page = Instance.new("ScrollingFrame")
        page.Name = tabName or "Tab"
        page.Size = UDim2.new(1, -20, 1, -40)
        page.Position = UDim2.new(0, 10, 0, 30)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarImageColor3 = GitanX._theme.Accent2
        page.ScrollBarThickness = 6
        page.Visible = #GitanX._tabs == 0
        page.Parent = GitanX._pages

        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 12)
        list.FillDirection = Enum.FillDirection.Vertical
        list.HorizontalAlignment = Enum.HorizontalAlignment.Left
        list.VerticalAlignment = Enum.VerticalAlignment.Top
        list.Parent = page

        local tabInfo = { Button = tabBtn, Page = page, Sections = {} }
        table.insert(GitanX._tabs, tabInfo)

        tabBtn.MouseEnter:Connect(function()
            tween(tabBtn, 0.1, {BackgroundColor3 = GitanX._theme.Section}):Play()
        end)
        tabBtn.MouseLeave:Connect(function()
            tween(tabBtn, 0.1, {BackgroundColor3 = GitanX._theme.Button}):Play()
        end)
        tabBtn.MouseButton1Click:Connect(function()
            for _,t in ipairs(GitanX._tabs) do
                t.Page.Visible = false
            end
            page.Visible = true
        end)

        local tabAPI = {}

        function tabAPI:CreateSection(titleText)
            local section = Instance.new("Frame")
            section.Name = "Section"
            section.Size = UDim2.new(1, -10, 0, 44)
            section.BackgroundColor3 = GitanX._theme.Section
            section.BorderSizePixel = 0
            section.Parent = page
            createRound(section, 8)
            createStroke(section, GitanX._theme.Border, 1)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -20, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.Text = titleText or "Section"
            label.Font = Enum.Font.GothamSemibold
            label.TextSize = 14
            label.TextColor3 = GitanX._theme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.BackgroundTransparency = 1
            label.Parent = section

            local sectionAPI = {}
            sectionAPI._parent = page

            function sectionAPI:AddSpacer(height)
                local sp = Instance.new("Frame")
                sp.Size = UDim2.new(1, -10, 0, height or 10)
                sp.BackgroundTransparency = 1
                sp.Parent = page
                return sp
            end

            -- Controls
            function sectionAPI:CreateButton(opts)
                local o = opts or {}
                local frame = Instance.new("TextButton")
                frame.Size = UDim2.new(1, -10, 0, 40)
                frame.Text = Icons.Button.."  "..(o.Name or "Button")
                frame.Font = Enum.Font.Gotham
                frame.TextSize = 14
                frame.TextColor3 = GitanX._theme.Text
                frame.AutoButtonColor = false
                frame.BackgroundColor3 = GitanX._theme.Button
                frame.Parent = page
                createRound(frame, 8)
                createStroke(frame, GitanX._theme.Border, 1)

                frame.MouseEnter:Connect(function()
                    tween(frame, 0.1, {BackgroundColor3 = GitanX._theme.Section}):Play()
                end)
                frame.MouseLeave:Connect(function()
                    tween(frame, 0.1, {BackgroundColor3 = GitanX._theme.Button}):Play()
                end)
                frame.MouseButton1Click:Connect(function()
                    if o.Callback then safePCall(o.Callback) end
                end)

                return {
                    SetText = function(_, txt) frame.Text = Icons.Button.."  "..txt end
                }
            end

            function sectionAPI:CreateToggle(opts)
                local o = opts or {}
                local id = o.Id or ("Toggle_"..HttpService:GenerateGUID(false))
                local current = (GitanX._saveMap[id] ~= nil) and GitanX._saveMap[id] or (o.CurrentValue or false)

                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, -10, 0, 40)
                frame.BackgroundColor3 = GitanX._theme.Button
                frame.Parent = page
                createRound(frame, 8)
                createStroke(frame, GitanX._theme.Border, 1)

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, -60, 1, 0)
                label.Position = UDim2.new(0, 10, 0, 0)
                label.Text = (o.Name or "Toggle")
                label.Font = Enum.Font.Gotham
                label.TextSize = 14
                label.TextColor3 = GitanX._theme.Text
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.BackgroundTransparency = 1
                label.Parent = frame

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0, 38, 0, 24)
                btn.Position = UDim2.new(1, -48, 0.5, -12)
                btn.Text = current and Icons.ToggleOn or Icons.ToggleOff
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 18
                btn.TextColor3 = current and GitanX._theme.ToggleOn or GitanX._theme.ToggleOff
                btn.AutoButtonColor = false
                btn.BackgroundColor3 = GitanX._theme.Section
                btn.Parent = frame
                createRound(btn, 12)
                createStroke(btn, GitanX._theme.Border, 1)

                local function setState(val)
                    current = val
                    btn.TextColor3 = val and GitanX._theme.ToggleOn or GitanX._theme.ToggleOff
                    btn.Text = val and Icons.ToggleOn or Icons.ToggleOff
                    if GitanX._configEnabled then
                        GitanX._saveMap[id] = val
                    end
                    if o.Callback then safePCall(o.Callback, val) end
                end

                btn.MouseButton1Click:Connect(function()
                    setState(not current)
                end)

                return {
                    Set = function(_, v) setState(v) end,
                    Get = function() return current end
                }
            end

            function sectionAPI:CreateSlider(opts)
                local o = opts or {}
                local id = o.Id or ("Slider_"..HttpService:GenerateGUID(false))
                local min, max = (o.Range or {0,100})[1], (o.Range or {0,100})[2]
                local inc = o.Increment or 1
                local current = (GitanX._saveMap[id] ~= nil) and GitanX._saveMap[id] or (o.CurrentValue or min)

                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, -10, 0, 56)
                frame.BackgroundColor3 = GitanX._theme.Button
                frame.Parent = page
                createRound(frame, 8)
                createStroke(frame, GitanX._theme.Border, 1)

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, -20, 0, 20)
                label.Position = UDim2.new(0, 10, 0, 6)
                label.Text = (o.Name or "Slider").." ("..tostring(current)..")"
                label.Font = Enum.Font.Gotham
                label.TextSize = 14
                label.TextColor3 = GitanX._theme.Text
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.BackgroundTransparency = 1
                label.Parent = frame

                local bar = Instance.new("Frame")
                bar.Size = UDim2.new(1, -20, 0, 10)
                bar.Position = UDim2.new(0, 10, 0, 34)
                bar.BackgroundColor3 = GitanX._theme.SliderBg
                bar.BorderSizePixel = 0
                bar.Parent = frame
                createRound(bar, 6)

                local fill = Instance.new("Frame")
                local fillPercent = (current - min) / (max - min)
                fill.Size = UDim2.new(fillPercent, 0, 1, 0)
                fill.Position = UDim2.new(0, 0, 0, 0)
                fill.BackgroundColor3 = GitanX._theme.SliderFill
                fill.BorderSizePixel = 0
                fill.Parent = bar
                createRound(fill, 6)

                local dragging = false

                local function setValue(val)
                    val = math.clamp(val, min, max)
                    val = math.floor(val / inc + 0.5) * inc
                    current = val
                    local pct = (val - min) / (max - min)
                    tween(fill, 0.08, {Size = UDim2.new(pct, 0, 1, 0)}):Play()
                    label.Text = (o.Name or "Slider").." ("..tostring(current)..")"
                    if GitanX._configEnabled then
                        GitanX._saveMap[id] = current
                    end
                    if o.Callback then safePCall(o.Callback, current) end
                end

                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        local rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
                        setValue(min + rel * (max - min))
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
                        setValue(min + rel * (max - min))
                    end
                end)
                bar.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)

                return {
                    Set = function(_, v) setValue(v) end,
                    Get = function() return current end,
                }
            end

            function sectionAPI:CreateDropdown(opts)
                local o = opts or {}
                local id = o.Id or ("Dropdown_"..HttpService:GenerateGUID(false))
                local options = o.Options or {"Option A","Option B"}
                local current = GitanX._saveMap[id] or o.CurrentOption or options[1]

                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, -10, 0, 40)
                frame.BackgroundColor3 = GitanX._theme.Button
                frame.Parent = page
                createRound(frame, 8)
                createStroke(frame, GitanX._theme.Border, 1)

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, -50, 1, 0)
                label.Position = UDim2.new(0, 10, 0, 0)
                label.Text = (o.Name or "Dropdown")..": "..tostring(current)
                label.Font = Enum.Font.Gotham
                label.TextSize = 14
                label.TextColor3 = GitanX._theme.Text
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.BackgroundTransparency = 1
                label.Parent = frame

                local openBtn = Instance.new("TextButton")
                openBtn.Size = UDim2.new(0, 30, 0, 24)
                openBtn.Position = UDim2.new(1, -40, 0.5, -12)
                openBtn.Text = Icons.Dropdown
                openBtn.Font = Enum.Font.Gotham
                openBtn.TextSize = 18
                openBtn.TextColor3 = GitanX._theme.Text
                openBtn.AutoButtonColor = false
                openBtn.BackgroundColor3 = GitanX._theme.Section
                openBtn.Parent = frame
                createRound(openBtn, 12)
                createStroke(openBtn, GitanX._theme.Border, 1)

                local listFrame = Instance.new("Frame")
                listFrame.Size = UDim2.new(1, -20, 0, 0)
                listFrame.Position = UDim2.new(0, 10, 1, 6)
                listFrame.BackgroundColor3 = GitanX._theme.DropdownBg
                listFrame.BorderSizePixel = 0
                listFrame.Visible = false
                listFrame.Parent = frame
                createRound(listFrame, 8)
                createStroke(listFrame, GitanX._theme.Border, 1)

                local listLayout = Instance.new("UIListLayout")
                listLayout.Padding = UDim.new(0,6)
                listLayout.Parent = listFrame

                local function refreshOptions()
                    for _,child in ipairs(listFrame:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for _,opt in ipairs(options) do
                        local btn = Instance.new("TextButton")
                        btn.Size = UDim2.new(1, -10, 0, 30)
                        btn.Text = tostring(opt)
                        btn.Font = Enum.Font.Gotham
                        btn.TextSize = 14
                        btn.TextColor3 = GitanX._theme.Text
                        btn.AutoButtonColor = false
                        btn.BackgroundColor3 = GitanX._theme.Button
                        btn.Parent = listFrame
                        createRound(btn, 8)
                        createStroke(btn, GitanX._theme.Border, 1)

                        btn.MouseButton1Click:Connect(function()
                            current = opt
                            label.Text = (o.Name or "Dropdown")..": "..tostring(current)
                            listFrame.Visible = false
                            tween(listFrame, 0.1, {Size = UDim2.new(1, -20, 0, 0)}):Play()
                            if GitanX._configEnabled then
                                GitanX._saveMap[id] = current
                            end
                            if o.Callback then safePCall(o.Callback, current) end
                        end)
                    end
                    local total = #options * 36
                    listFrame.Size = UDim2.new(1, -20, 0, total)
                end
                refreshOptions()

                openBtn.MouseButton1Click:Connect(function()
                    local targetSize = listFrame.Visible and UDim2.new(1, -20, 0, 0) or UDim2.new(1, -20, 0, (#options * 36))
                    listFrame.Visible = not listFrame.Visible
                    tween(listFrame, 0.12, {Size = targetSize}):Play()
                end)

                return {
                    SetOptions = function(_, newOptions)
                        options = newOptions
                        refreshOptions()
                    end,
                    Set = function(_, value)
                        current = value
                        label.Text = (o.Name or "Dropdown")..": "..tostring(current)
                        if GitanX._configEnabled then GitanX._saveMap[id] = current end
                        if o.Callback then safePCall(o.Callback, current) end
                    end,
                    Get = function() return current end
                }
            end

            function sectionAPI:CreateKeybind(opts)
                local o = opts or {}
                local id = o.Id or ("Keybind_"..HttpService:GenerateGUID(false))
                local current = GitanX._saveMap[id] or o.CurrentKey or Enum.KeyCode.P

                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, -10, 0, 40)
                frame.BackgroundColor3 = GitanX._theme.Button
                frame.Parent = page
                createRound(frame, 8)
                createStroke(frame, GitanX._theme.Border, 1)

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, -120, 1, 0)
                label.Position = UDim2.new(0, 10, 0, 0)
                label.Text = (o.Name or "Keybind")..": "..tostring(current.Name or current)
                label.Font = Enum.Font.Gotham
                label.TextSize = 14
                label.TextColor3 = GitanX._theme.Text
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.BackgroundTransparency = 1
                label.Parent = frame

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0, 100, 0, 24)
                btn.Position = UDim2.new(1, -110, 0.5, -12)
                btn.Text = Icons.Key.."  Set key"
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 14
                btn.TextColor3 = GitanX._theme.Text
                btn.AutoButtonColor = false
                btn.BackgroundColor3 = GitanX._theme.Section
                btn.Parent = frame
                createRound(btn, 12)
                createStroke(btn, GitanX._theme.Border, 1)

                local listening = false
                btn.MouseButton1Click:Connect(function()
                    listening = true
                    btn.Text = Icons.Key.."  Press a key..."
                end)

                UserInputService.InputBegan:Connect(function(input, gpe)
                    if gpe then return end
                    if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        current = input.KeyCode
                        label.Text = (o.Name or "Keybind")..": "..tostring(current.Name or current)
                        btn.Text = Icons.Key.."  Set key"
                        listening = false
                        if GitanX._configEnabled then
                            GitanX._saveMap[id] = current.Name
                        end
                    end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        local keyName = input.KeyCode.Name
                        local saved = GitanX._configEnabled and GitanX._saveMap[id]
                        local match = (saved and keyName == saved) or (current and keyName == current.Name)
                        if match and o.Callback then
                            safePCall(o.Callback)
                        end
                    end
                end)

                return {
                    Set = function(_, keycode)
                        current = keycode
                        label.Text = (o.Name or "Keybind")..": "..tostring(current.Name or current)
                        if GitanX._configEnabled then GitanX._saveMap[id] = current.Name end
                    end,
                    Get = function() return current end
                }
            end

            return sectionAPI
        end

        return tabAPI
    end

    function windowAPI:Notify(opts)
        local o = opts or {}
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 280, 0, 60)
        frame.Position = UDim2.new(1, -300, 0, 76)
        frame.BackgroundColor3 = GitanX._theme.Notification
        frame.BorderSizePixel = 0
        frame.Parent = GitanX._main
        createRound(frame, 10)
        createStroke(frame, GitanX._theme.Border, 1)

        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 24, 0, 24)
        icon.Position = UDim2.new(0, 8, 0, 8)
        icon.BackgroundTransparency = 1
        icon.Font = Enum.Font.GothamBold
        icon.TextSize = 18
        icon.TextColor3 = GitanX._theme.Text
        local kind = (o.Type or "Info")
        icon.Text = kind == "Success" and Icons.Success or kind == "Warning" and Icons.Warning or kind == "Error" and Icons.Error or Icons.Info
        icon.Parent = frame

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -44, 0, 20)
        title.Position = UDim2.new(0, 40, 0, 6)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.TextSize = 14
        title.TextColor3 = GitanX._theme.Text
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = o.Title or "Notification"
        title.Parent = frame

        local content = Instance.new("TextLabel")
        content.Size = UDim2.new(1, -44, 0, 20)
        content.Position = UDim2.new(0, 40, 0, 28)
        content.BackgroundTransparency = 1
        content.Font = Enum.Font.Gotham
        content.TextSize = 13
        content.TextColor3 = GitanX._theme.Text
        content.TextTransparency = 0.15
        content.TextXAlignment = Enum.TextXAlignment.Left
        content.Text = o.Content or ""
        content.Parent = frame

        frame.AnchorPoint = Vector2.new(1,0)
        frame.Position = UDim2.new(1, -10, 0, 76)
        frame.Visible = true
        frame.BackgroundTransparency = 1
        tween(frame, 0.12, {BackgroundTransparency = 0}):Play()

        task.delay(o.Duration or 4, function()
            tween(frame, 0.15, {BackgroundTransparency = 1}):Play()
            task.wait(0.18)
            frame:Destroy()
        end)
    end

    function windowAPI:ChangeTheme(themeKey)
        if Themes[themeKey] then
            GitanX._themeName = themeKey
            GitanX._theme = Themes[themeKey]
            -- Basic recolor (new instances will follow theme).
            -- For simplicity, we won’t live-repaint every child here.
            windowAPI:Notify({ Title = "Theme", Content = "Changed to "..themeKey, Type = "Success", Duration = 2 })
        else
            windowAPI:Notify({ Title = "Theme", Content = "Unknown theme: "..tostring(themeKey), Type = "Error", Duration = 3 })
        end
    end

    function windowAPI:ApplyCustomTheme(themeTable)
        if type(themeTable) == "table" then
            GitanX._themeName = "Custom"
            GitanX._theme = themeTable
            windowAPI:Notify({ Title = "Theme", Content = "Custom theme applied", Type = "Success", Duration = 2 })
        end
    end

    function windowAPI:SaveConfiguration()
        if not GitanX._configEnabled then return end
        ensureFolder(GitanX._configFolder)
        local ok, json = pcall(function() return HttpService:JSONEncode(GitanX._saveMap) end)
        if ok then
            writeFile(GitanX._configFolder.."/"..GitanX._configFile, json)
            windowAPI:Notify({ Title = "Config", Content = "Configuration saved", Type = "Success", Duration = 2 })
        else
            windowAPI:Notify({ Title = "Config", Content = "Save failed", Type = "Error", Duration = 3 })
        end
    end

    function windowAPI:GetTheme()
        return GitanX._themeName, deepCopy(GitanX._theme)
    end

    return windowAPI
end

-- Public constructor
function GitanX.new()
    local self = setmetatable({}, GitanX)
    return self
end

-- Simple load helper for direct use
function GitanX:Init(opts)
    return self:CreateWindow(opts or {})
end

return GitanX
s
