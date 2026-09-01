-- ==============================================================================
-- ANIMULA UI LIBRARY — FURINA OCEAN THEME (GENSHIN IMPACT)
-- ==============================================================================
-- Pure Roblox Lua UI Engine with 100% Orion Library API Compatibility
-- Theme: Fontaine Hydro Blue (#38bdf8 / #1e3a8a / #0b1324) + Glass Glow Borders
-- Safe for all executors (gethui / CoreGui / PlayerGui auto-fallback)
-- ==============================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Executor-safe GUI Parent
local function GetGuiParent()
    local ok, gui = pcall(function()
        if gethui then return gethui() end
        if syn and syn.protect_gui then
            local g = Instance.new("Folder")
            syn.protect_gui(g)
            g.Parent = CoreGui
            return g
        end
        return CoreGui
    end)
    if ok and gui then return gui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- ==============================================================================
-- Color Palette & Theme Definitions (Furina Fontaine Theme)
-- ==============================================================================
local Theme = {
    Accent       = Color3.fromRGB(56, 189, 248),   -- Biru Furina Hydro (#38bdf8)
    AccentDark   = Color3.fromRGB(14, 116, 144),   -- Deep Hydro Accent
    AccentGlow   = Color3.fromRGB(125, 211, 252),  -- Bright Fontaine Sparkle
    Background   = Color3.fromRGB(11, 19, 36),     -- Deep Fontaine Royal Navy
    SidebarBg    = Color3.fromRGB(8, 14, 28),      -- Darker Sidebar Navy
    CardBg       = Color3.fromRGB(18, 30, 56),     -- Container Card Background
    CardHover    = Color3.fromRGB(26, 44, 82),     -- Card Hover State
    CardStroke   = Color3.fromRGB(56, 189, 248),   -- Border Stroke (translucent)
    TextPrimary  = Color3.fromRGB(248, 250, 252),  -- Crisp White
    TextMuted    = Color3.fromRGB(148, 163, 184),  -- Soft Silver/Cyan-Gray
    TextDark     = Color3.fromRGB(100, 116, 139),  -- Dark Gray
    Success      = Color3.fromRGB(52, 211, 153),   -- Emerald Success
    Danger       = Color3.fromRGB(244, 63, 94),    -- Crimson Danger
}

local Animula = {
    _Theme = Theme,
    _Windows = {},
    _Notifications = {},
    _Flags = {},
    _ConfigFolder = "AnimulaConfig",
    _SaveConfig = false,
}

-- Utility: Smooth Tween Helper
local function Tween(instance, properties, duration, style, direction)
    style = style or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    duration = duration or 0.25
    local tweenInfo = TweenInfo.new(duration, style, direction)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Utility: Drag Controller
local function EnableDragging(dragHandle, mainFrame)
    local dragging = false
    local dragInput, dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Tween(mainFrame, {
                Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            }, 0.08, Enum.EasingStyle.Linear)
        end
    end)
end

-- ==============================================================================
-- Notification System
-- ==============================================================================
local NotificationGui = nil
local NotificationContainer = nil

local function EnsureNotificationGui()
    if NotificationGui and NotificationGui.Parent then return end
    NotificationGui = Instance.new("ScreenGui")
    NotificationGui.Name = "AnimulaNotifications"
    NotificationGui.ResetOnSpawn = false
    NotificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    NotificationGui.Parent = GetGuiParent()

    NotificationContainer = Instance.new("Frame")
    NotificationContainer.Name = "Container"
    NotificationContainer.Size = UDim2.new(0, 320, 1, -40)
    NotificationContainer.Position = UDim2.new(1, -340, 0, 20)
    NotificationContainer.BackgroundTransparency = 1
    NotificationContainer.Parent = NotificationGui

    local layout = Instance.new("UIListLayout")
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = NotificationContainer
end

function Animula:MakeNotification(config)
    config = config or {}
    local title = config.Title or config.Name or "Animula Notification"
    local content = config.Content or config.Text or ""
    local duration = tonumber(config.Time or config.Duration) or 4
    local iconId = config.Image or config.Icon or "rbxassetid://4483345998"

    EnsureNotificationGui()

    local card = Instance.new("Frame")
    card.Name = "NotificationCard"
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Theme.Background
    card.BackgroundTransparency = 0.08
    card.BorderSizePixel = 0
    card.ClipsDescendants = true
    card.Position = UDim2.new(1, 350, 0, 0)
    card.Parent = NotificationContainer

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Theme.Accent
    cardStroke.Transparency = 0.4
    cardStroke.Thickness = 1.2
    cardStroke.Parent = card

    local cardPadding = Instance.new("UIPadding")
    cardPadding.PaddingTop = UDim.new(0, 12)
    cardPadding.PaddingBottom = UDim.new(0, 14)
    cardPadding.PaddingLeft = UDim.new(0, 14)
    cardPadding.PaddingRight = UDim.new(0, 14)
    cardPadding.Parent = card

    -- Header (Icon + Title)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 22)
    header.BackgroundTransparency = 1
    header.Parent = card

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 20, 0, 20)
    icon.Position = UDim2.new(0, 0, 0, 1)
    icon.BackgroundTransparency = 1
    icon.Image = iconId
    icon.ImageColor3 = Theme.Accent
    icon.Parent = header

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -28, 1, 0)
    titleLabel.Position = UDim2.new(0, 26, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Theme.TextPrimary
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header

    -- Content
    local contentLabel = Instance.new("TextLabel")
    contentLabel.Size = UDim2.new(1, 0, 0, 0)
    contentLabel.Position = UDim2.new(0, 0, 0, 26)
    contentLabel.AutomaticSize = Enum.AutomaticSize.Y
    contentLabel.BackgroundTransparency = 1
    contentLabel.Text = content
    contentLabel.TextColor3 = Theme.TextMuted
    contentLabel.Font = Enum.Font.GothamMedium
    contentLabel.TextSize = 12
    contentLabel.TextWrapped = true
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
    contentLabel.Parent = card

    -- Progress Bar (Timer)
    local progressBarBg = Instance.new("Frame")
    progressBarBg.Size = UDim2.new(1, 0, 0, 3)
    progressBarBg.Position = UDim2.new(0, 0, 1, 10)
    progressBarBg.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
    progressBarBg.BorderSizePixel = 0
    progressBarBg.Parent = card

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 1, 0)
    progressBar.BackgroundColor3 = Theme.Accent
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBarBg

    local pbCorner = Instance.new("UICorner")
    pbCorner.CornerRadius = UDim.new(0, 2)
    pbCorner.Parent = progressBar

    -- Slide in
    card.Position = UDim2.new(1, 350, 0, 0)
    Tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.35, Enum.EasingStyle.Back)
    Tween(progressBar, { Size = UDim2.new(0, 0, 1, 0) }, duration, Enum.EasingStyle.Linear)

    -- Auto dismiss
    task.delay(duration, function()
        if card and card.Parent then
            local tw = Tween(card, { Position = UDim2.new(1, 350, 0, 0), BackgroundTransparency = 1 }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            tw.Completed:Connect(function()
                card:Destroy()
            end)
        end
    end)
end

-- ==============================================================================
-- Main Window Factory (Animula:MakeWindow)
-- ==============================================================================
function Animula:MakeWindow(config)
    config = config or {}
    local windowTitle = config.Name or "Animula Hub"
    local saveConfig = config.SaveConfig or false
    local configFolder = config.ConfigFolder or "AnimulaHub"
    local hidePremium = config.HidePremium or false
    local icon = config.Icon or "rbxassetid://4483345998"
    local closeCallback = config.CloseCallback or function() end

    Animula._SaveConfig = saveConfig
    Animula._ConfigFolder = configFolder

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AnimulaOcean_" .. tostring(math.random(1000, 9999))
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = GetGuiParent()

    -- Main Outer Frame
    local Main = Instance.new("Frame")
    Main.Name = "MainFrame"
    Main.Size = UDim2.new(0, 680, 0, 440)
    Main.Position = UDim2.new(0.5, -340, 0.5, -220)
    Main.BackgroundColor3 = Theme.Background
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = Main

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Theme.Accent
    MainStroke.Transparency = 0.5
    MainStroke.Thickness = 1.5
    MainStroke.Parent = Main

    -- Subtle Hydro Gradient on Background
    local MainGrad = Instance.new("UIGradient")
    MainGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 26, 48)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 14, 28))
    })
    MainGrad.Rotation = 45
    MainGrad.Parent = Main

    -- Topbar Header
    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Size = UDim2.new(1, 0, 0, 48)
    Topbar.BackgroundColor3 = Theme.SidebarBg
    Topbar.BorderSizePixel = 0
    Topbar.Parent = Main

    local TopbarStroke = Instance.new("UIStroke")
    TopbarStroke.Color = Theme.Accent
    TopbarStroke.Transparency = 0.8
    TopbarStroke.Thickness = 1
    TopbarStroke.Parent = Topbar

    local LogoIcon = Instance.new("ImageLabel")
    LogoIcon.Name = "Logo"
    LogoIcon.Size = UDim2.new(0, 24, 0, 24)
    LogoIcon.Position = UDim2.new(0, 16, 0.5, -12)
    LogoIcon.BackgroundTransparency = 1
    LogoIcon.Image = icon
    LogoIcon.ImageColor3 = Theme.Accent
    LogoIcon.Parent = Topbar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(0, 300, 1, 0)
    TitleLabel.Position = UDim2.new(0, 48, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = windowTitle
    TitleLabel.TextColor3 = Theme.TextPrimary
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Topbar

    local SubtitleBadge = Instance.new("TextLabel")
    SubtitleBadge.Name = "Badge"
    SubtitleBadge.Size = UDim2.new(0, 60, 0, 20)
    SubtitleBadge.Position = UDim2.new(0, 48 + TitleLabel.TextBounds.X + 10, 0.5, -10)
    SubtitleBadge.BackgroundColor3 = Color3.fromRGB(14, 116, 144)
    SubtitleBadge.BackgroundTransparency = 0.3
    SubtitleBadge.Text = "OCEAN"
    SubtitleBadge.TextColor3 = Theme.AccentGlow
    SubtitleBadge.Font = Enum.Font.GothamBold
    SubtitleBadge.TextSize = 10
    SubtitleBadge.Parent = Topbar

    local BadgeCorner = Instance.new("UICorner")
    BadgeCorner.CornerRadius = UDim.new(0, 4)
    BadgeCorner.Parent = SubtitleBadge

    -- Window Controls (Minimize & Close)
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseButton"
    CloseBtn.Size = UDim2.new(0, 32, 0, 32)
    CloseBtn.Position = UDim2.new(1, -40, 0.5, -16)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
    CloseBtn.BackgroundTransparency = 0.6
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Theme.TextMuted
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 13
    CloseBtn.Parent = Topbar

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseBtn

    CloseBtn.MouseEnter:Connect(function()
        Tween(CloseBtn, { BackgroundColor3 = Theme.Danger, TextColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.1 }, 0.15)
    end)
    CloseBtn.MouseLeave:Connect(function()
        Tween(CloseBtn, { BackgroundColor3 = Color3.fromRGB(30, 41, 59), TextColor3 = Theme.TextMuted, BackgroundTransparency = 0.6 }, 0.15)
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        pcall(closeCallback)
        Tween(Main, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1 }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In).Completed:Connect(function()
            ScreenGui:Destroy()
        end)
    end)

    local MinBtn = Instance.new("TextButton")
    MinBtn.Name = "MinButton"
    MinBtn.Size = UDim2.new(0, 32, 0, 32)
    MinBtn.Position = UDim2.new(1, -78, 0.5, -16)
    MinBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
    MinBtn.BackgroundTransparency = 0.6
    MinBtn.Text = "—"
    MinBtn.TextColor3 = Theme.TextMuted
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 12
    MinBtn.Parent = Topbar

    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 6)
    MinCorner.Parent = MinBtn

    local isMinimized = false
    MinBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            Tween(Main, { Size = UDim2.new(0, 680, 0, 48) }, 0.25)
        else
            Tween(Main, { Size = UDim2.new(0, 680, 0, 440) }, 0.25)
        end
    end)

    EnableDragging(Topbar, Main)

    -- Sidebar (Tabs Navigation)
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 180, 1, -48)
    Sidebar.Position = UDim2.new(0, 0, 0, 48)
    Sidebar.BackgroundColor3 = Theme.SidebarBg
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = Main

    local SidebarStroke = Instance.new("UIStroke")
    SidebarStroke.Color = Theme.Accent
    SidebarStroke.Transparency = 0.85
    SidebarStroke.Thickness = 1
    SidebarStroke.Parent = Sidebar

    local TabScroll = Instance.new("ScrollingFrame")
    TabScroll.Name = "TabScroll"
    TabScroll.Size = UDim2.new(1, 0, 1, 0)
    TabScroll.BackgroundTransparency = 1
    TabScroll.ScrollBarThickness = 2
    TabScroll.ScrollBarImageColor3 = Theme.Accent
    TabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabScroll.Parent = Sidebar

    local TabList = Instance.new("UIListLayout")
    TabList.Padding = UDim.new(0, 6)
    TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Parent = TabScroll

    local TabPadding = Instance.new("UIPadding")
    TabPadding.PaddingTop = UDim.new(0, 12)
    TabPadding.PaddingBottom = UDim.new(0, 12)
    TabPadding.PaddingLeft = UDim.new(0, 8)
    TabPadding.PaddingRight = UDim.new(0, 8)
    TabPadding.Parent = TabScroll

    -- Content Viewport (Tab Pages Container)
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -180, 1, -48)
    ContentArea.Position = UDim2.new(0, 180, 0, 48)
    ContentArea.BackgroundTransparency = 1
    ContentArea.ClipsDescendants = true
    ContentArea.Parent = Main

    local WindowObj = {
        _ScreenGui = ScreenGui,
        _Main = Main,
        _Tabs = {},
        _CurrentTab = nil,
    }

    -- Tab Constructor (Window:MakeTab)
    function WindowObj:MakeTab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Name or "Tab"
        local tabIcon = tabConfig.Icon or "rbxassetid://4483345998"

        -- Tab Button in Sidebar
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = "TabBtn_" .. tabName
        TabBtn.Size = UDim2.new(1, 0, 0, 38)
        TabBtn.BackgroundColor3 = Color3.fromRGB(15, 26, 48)
        TabBtn.BackgroundTransparency = 0.8
        TabBtn.Text = ""
        TabBtn.AutoButtonColor = false
        TabBtn.Parent = TabScroll

        local TabBtnCorner = Instance.new("UICorner")
        TabBtnCorner.CornerRadius = UDim.new(0, 8)
        TabBtnCorner.Parent = TabBtn

        local TabBtnStroke = Instance.new("UIStroke")
        TabBtnStroke.Color = Theme.Accent
        TabBtnStroke.Transparency = 1
        TabBtnStroke.Thickness = 1
        TabBtnStroke.Parent = TabBtn

        local TabBtnIcon = Instance.new("ImageLabel")
        TabBtnIcon.Name = "Icon"
        TabBtnIcon.Size = UDim2.new(0, 18, 0, 18)
        TabBtnIcon.Position = UDim2.new(0, 12, 0.5, -9)
        TabBtnIcon.BackgroundTransparency = 1
        TabBtnIcon.Image = tabIcon
        TabBtnIcon.ImageColor3 = Theme.TextMuted
        TabBtnIcon.Parent = TabBtn

        local TabBtnTitle = Instance.new("TextLabel")
        TabBtnTitle.Name = "Title"
        TabBtnTitle.Size = UDim2.new(1, -40, 1, 0)
        TabBtnTitle.Position = UDim2.new(0, 36, 0, 0)
        TabBtnTitle.BackgroundTransparency = 1
        TabBtnTitle.Text = tabName
        TabBtnTitle.TextColor3 = Theme.TextMuted
        TabBtnTitle.Font = Enum.Font.GothamMedium
        TabBtnTitle.TextSize = 13
        TabBtnTitle.TextXAlignment = Enum.TextXAlignment.Left
        TabBtnTitle.Parent = TabBtn

        -- Indicator bar on the left of active tab
        local Indicator = Instance.new("Frame")
        Indicator.Name = "Indicator"
        Indicator.Size = UDim2.new(0, 3, 0, 18)
        Indicator.Position = UDim2.new(0, 2, 0.5, -9)
        Indicator.BackgroundColor3 = Theme.Accent
        Indicator.BackgroundTransparency = 1
        Indicator.BorderSizePixel = 0
        Indicator.Parent = TabBtn

        local IndCorner = Instance.new("UICorner")
        IndCorner.CornerRadius = UDim.new(0, 2)
        IndCorner.Parent = Indicator

        -- Page Container (Scrolling list of controls)
        local Page = Instance.new("ScrollingFrame")
        Page.Name = "Page_" .. tabName
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = Theme.Accent
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.Visible = false
        Page.Parent = ContentArea

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Parent = Page

        local PagePadding = Instance.new("UIPadding")
        PagePadding.PaddingTop = UDim.new(0, 14)
        PagePadding.PaddingBottom = UDim.new(0, 16)
        PagePadding.PaddingLeft = UDim.new(0, 14)
        PagePadding.PaddingRight = UDim.new(0, 14)
        PagePadding.Parent = Page

        local TabObj = {
            _Page = Page,
            _Button = TabBtn,
            _Name = tabName,
        }

        local function ActivateTab()
            for _, otherTab in ipairs(WindowObj._Tabs) do
                otherTab._Page.Visible = false
                Tween(otherTab._Button, { BackgroundTransparency = 0.8, BackgroundColor3 = Color3.fromRGB(15, 26, 48) }, 0.15)
                Tween(otherTab._Button.Title, { TextColor3 = Theme.TextMuted }, 0.15)
                Tween(otherTab._Button.Icon, { ImageColor3 = Theme.TextMuted }, 0.15)
                Tween(otherTab._Button.Indicator, { BackgroundTransparency = 1 }, 0.15)
                Tween(otherTab._Button.UIStroke, { Transparency = 1 }, 0.15)
            end

            Page.Visible = true
            WindowObj._CurrentTab = TabObj
            Tween(TabBtn, { BackgroundTransparency = 0.15, BackgroundColor3 = Color3.fromRGB(24, 40, 76) }, 0.2)
            Tween(TabBtnTitle, { TextColor3 = Theme.TextPrimary }, 0.2)
            Tween(TabBtnIcon, { ImageColor3 = Theme.Accent }, 0.2)
            Tween(Indicator, { BackgroundTransparency = 0 }, 0.2)
            Tween(TabBtnStroke, { Transparency = 0.4 }, 0.2)
        end

        TabBtn.MouseButton1Click:Connect(ActivateTab)

        if #WindowObj._Tabs == 0 then
            ActivateTab()
        end

        table.insert(WindowObj._Tabs, TabObj)

        -- Control Elements Factory (Attached to Tab & Section)
        local function CreateElementsFactory(container)
            local Elements = {}

            -- SECTION HEADER
            function Elements:AddSection(secConfig)
                secConfig = secConfig or {}
                local secName = secConfig.Name or "Section"

                local secFrame = Instance.new("Frame")
                secFrame.Name = "Section_" .. secName
                secFrame.Size = UDim2.new(1, 0, 0, 28)
                secFrame.BackgroundTransparency = 1
                secFrame.Parent = container

                local secTitle = Instance.new("TextLabel")
                secTitle.Size = UDim2.new(1, 0, 1, 0)
                secTitle.BackgroundTransparency = 1
                secTitle.Text = string.upper(secName)
                secTitle.TextColor3 = Theme.Accent
                secTitle.Font = Enum.Font.GothamBold
                secTitle.TextSize = 11
                secTitle.TextXAlignment = Enum.TextXAlignment.Left
                secTitle.Parent = secFrame

                local secLine = Instance.new("Frame")
                secLine.Size = UDim2.new(1, 0, 0, 1)
                secLine.Position = UDim2.new(0, 0, 1, -2)
                secLine.BackgroundColor3 = Theme.Accent
                secLine.BackgroundTransparency = 0.65
                secLine.BorderSizePixel = 0
                secLine.Parent = secFrame

                local SecObj = CreateElementsFactory(container)
                return SecObj
            end

            -- BUTTON
            function Elements:AddButton(btnConfig)
                btnConfig = btnConfig or {}
                local bName = btnConfig.Name or "Button"
                local callback = btnConfig.Callback or function() end

                local btnFrame = Instance.new("Frame")
                btnFrame.Name = "Button_" .. bName
                btnFrame.Size = UDim2.new(1, 0, 0, 38)
                btnFrame.BackgroundColor3 = Theme.CardBg
                btnFrame.Parent = container

                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 8)
                btnCorner.Parent = btnFrame

                local btnStroke = Instance.new("UIStroke")
                btnStroke.Color = Theme.CardStroke
                btnStroke.Transparency = 0.8
                btnStroke.Thickness = 1
                btnStroke.Parent = btnFrame

                local clickArea = Instance.new("TextButton")
                clickArea.Size = UDim2.new(1, 0, 1, 0)
                clickArea.BackgroundTransparency = 1
                clickArea.Text = ""
                clickArea.Parent = btnFrame

                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, -40, 1, 0)
                title.Position = UDim2.new(0, 14, 0, 0)
                title.BackgroundTransparency = 1
                title.Text = bName
                title.TextColor3 = Theme.TextPrimary
                title.Font = Enum.Font.GothamMedium
                title.TextSize = 13
                title.TextXAlignment = Enum.TextXAlignment.Left
                title.Parent = btnFrame

                local actionIcon = Instance.new("ImageLabel")
                actionIcon.Size = UDim2.new(0, 16, 0, 16)
                actionIcon.Position = UDim2.new(1, -28, 0.5, -8)
                actionIcon.BackgroundTransparency = 1
                actionIcon.Image = "rbxassetid://4483345998"
                actionIcon.ImageColor3 = Theme.Accent
                actionIcon.Parent = btnFrame

                clickArea.MouseEnter:Connect(function()
                    Tween(btnFrame, { BackgroundColor3 = Theme.CardHover }, 0.15)
                    Tween(btnStroke, { Transparency = 0.4 }, 0.15)
                end)
                clickArea.MouseLeave:Connect(function()
                    Tween(btnFrame, { BackgroundColor3 = Theme.CardBg }, 0.15)
                    Tween(btnStroke, { Transparency = 0.8 }, 0.15)
                end)
                clickArea.MouseButton1Click:Connect(function()
                    Tween(btnFrame, { BackgroundColor3 = Color3.fromRGB(36, 60, 110) }, 0.08).Completed:Connect(function()
                        Tween(btnFrame, { BackgroundColor3 = Theme.CardHover }, 0.15)
                    end)
                    pcall(callback)
                end)
            end

            -- TOGGLE
            function Elements:AddToggle(toggleConfig)
                toggleConfig = toggleConfig or {}
                local tName = toggleConfig.Name or "Toggle"
                local default = toggleConfig.Default or false
                local callback = toggleConfig.Callback or function() end
                local flag = toggleConfig.Flag
                local state = default

                local tFrame = Instance.new("Frame")
                tFrame.Name = "Toggle_" .. tName
                tFrame.Size = UDim2.new(1, 0, 0, 38)
                tFrame.BackgroundColor3 = Theme.CardBg
                tFrame.Parent = container

                local tCorner = Instance.new("UICorner")
                tCorner.CornerRadius = UDim.new(0, 8)
                tCorner.Parent = tFrame

                local tStroke = Instance.new("UIStroke")
                tStroke.Color = Theme.CardStroke
                tStroke.Transparency = 0.8
                tStroke.Thickness = 1
                tStroke.Parent = tFrame

                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, -60, 1, 0)
                title.Position = UDim2.new(0, 14, 0, 0)
                title.BackgroundTransparency = 1
                title.Text = tName
                title.TextColor3 = Theme.TextPrimary
                title.Font = Enum.Font.GothamMedium
                title.TextSize = 13
                title.TextXAlignment = Enum.TextXAlignment.Left
                title.Parent = tFrame

                local switchBg = Instance.new("Frame")
                switchBg.Size = UDim2.new(0, 38, 0, 20)
                switchBg.Position = UDim2.new(1, -48, 0.5, -10)
                switchBg.BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(30, 41, 59)
                switchBg.Parent = tFrame

                local swCorner = Instance.new("UICorner")
                swCorner.CornerRadius = UDim.new(1, 0)
                swCorner.Parent = switchBg

                local circle = Instance.new("Frame")
                circle.Size = UDim2.new(0, 14, 0, 14)
                circle.Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
                circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                circle.Parent = switchBg

                local cCorner = Instance.new("UICorner")
                cCorner.CornerRadius = UDim.new(1, 0)
                cCorner.Parent = circle

                local clickBtn = Instance.new("TextButton")
                clickBtn.Size = UDim2.new(1, 0, 1, 0)
                clickBtn.BackgroundTransparency = 1
                clickBtn.Text = ""
                clickBtn.Parent = tFrame

                local function UpdateState(val)
                    state = val
                    if flag then Animula._Flags[flag] = state end
                    if state then
                        Tween(switchBg, { BackgroundColor3 = Theme.Accent }, 0.2)
                        Tween(circle, { Position = UDim2.new(1, -17, 0.5, -7) }, 0.2)
                    else
                        Tween(switchBg, { BackgroundColor3 = Color3.fromRGB(30, 41, 59) }, 0.2)
                        Tween(circle, { Position = UDim2.new(0, 3, 0.5, -7) }, 0.2)
                    end
                    pcall(callback, state)
                end

                clickBtn.MouseButton1Click:Connect(function()
                    UpdateState(not state)
                end)

                clickBtn.MouseEnter:Connect(function()
                    Tween(tFrame, { BackgroundColor3 = Theme.CardHover }, 0.15)
                end)
                clickBtn.MouseLeave:Connect(function()
                    Tween(tFrame, { BackgroundColor3 = Theme.CardBg }, 0.15)
                end)

                if default then
                    pcall(callback, state)
                end

                return {
                    Set = function(_, val) UpdateState(val) end,
                    Value = state
                }
            end

            -- SLIDER
            function Elements:AddSlider(sliderConfig)
                sliderConfig = sliderConfig or {}
                local sName = sliderConfig.Name or "Slider"
                local min = sliderConfig.Min or 0
                local max = sliderConfig.Max or 100
                local default = sliderConfig.Default or min
                local inc = sliderConfig.Increment or 1
                local valueName = sliderConfig.ValueName or ""
                local callback = sliderConfig.Callback or function() end
                local flag = sliderConfig.Flag
                local currentVal = default

                local sFrame = Instance.new("Frame")
                sFrame.Name = "Slider_" .. sName
                sFrame.Size = UDim2.new(1, 0, 0, 52)
                sFrame.BackgroundColor3 = Theme.CardBg
                sFrame.Parent = container

                local sCorner = Instance.new("UICorner")
                sCorner.CornerRadius = UDim.new(0, 8)
                sCorner.Parent = sFrame

                local sStroke = Instance.new("UIStroke")
                sStroke.Color = Theme.CardStroke
                sStroke.Transparency = 0.8
                sStroke.Thickness = 1
                sStroke.Parent = sFrame

                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(0.6, 0, 0, 20)
                title.Position = UDim2.new(0, 14, 0, 8)
                title.BackgroundTransparency = 1
                title.Text = sName
                title.TextColor3 = Theme.TextPrimary
                title.Font = Enum.Font.GothamMedium
                title.TextSize = 13
                title.TextXAlignment = Enum.TextXAlignment.Left
                title.Parent = sFrame

                local valLabel = Instance.new("TextLabel")
                valLabel.Size = UDim2.new(0.35, 0, 0, 20)
                valLabel.Position = UDim2.new(0.65, -14, 0, 8)
                valLabel.BackgroundTransparency = 1
                valLabel.Text = tostring(currentVal) .. (valueName ~= "" and (" " .. valueName) or "")
                valLabel.TextColor3 = Theme.Accent
                valLabel.Font = Enum.Font.GothamBold
                valLabel.TextSize = 12
                valLabel.TextXAlignment = Enum.TextXAlignment.Right
                valLabel.Parent = sFrame

                local barBg = Instance.new("Frame")
                barBg.Size = UDim2.new(1, -28, 0, 6)
                barBg.Position = UDim2.new(0, 14, 0, 34)
                barBg.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
                barBg.Parent = sFrame

                local barBgCorner = Instance.new("UICorner")
                barBgCorner.CornerRadius = UDim.new(1, 0)
                barBgCorner.Parent = barBg

                local fill = Instance.new("Frame")
                local pct = math.clamp((currentVal - min) / (max - min), 0, 1)
                fill.Size = UDim2.new(pct, 0, 1, 0)
                fill.BackgroundColor3 = Theme.Accent
                fill.Parent = barBg

                local fillCorner = Instance.new("UICorner")
                fillCorner.CornerRadius = UDim.new(1, 0)
                fillCorner.Parent = fill

                local isDragging = false

                local function SetValue(val)
                    val = math.clamp(val, min, max)
                    val = math.floor((val - min) / inc + 0.5) * inc + min
                    currentVal = val
                    if flag then Animula._Flags[flag] = currentVal end

                    local newPct = math.clamp((currentVal - min) / (max - min), 0, 1)
                    Tween(fill, { Size = UDim2.new(newPct, 0, 1, 0) }, 0.08)
                    valLabel.Text = tostring(currentVal) .. (valueName ~= "" and (" " .. valueName) or "")
                    pcall(callback, currentVal)
                end

                local sliderBtn = Instance.new("TextButton")
                sliderBtn.Size = UDim2.new(1, 0, 1, 0)
                sliderBtn.BackgroundTransparency = 1
                sliderBtn.Text = ""
                sliderBtn.Parent = barBg

                sliderBtn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDragging = true
                        local relativeX = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
                        SetValue(min + ((max - min) * relativeX))
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDragging = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        local relativeX = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
                        SetValue(min + ((max - min) * relativeX))
                    end
                end)

                return {
                    Set = function(_, v) SetValue(v) end,
                    Value = currentVal
                }
            end

            -- DROPDOWN
            function Elements:AddDropdown(ddConfig)
                ddConfig = ddConfig or {}
                local dName = ddConfig.Name or "Dropdown"
                local options = ddConfig.Options or {}
                local default = ddConfig.Default or (options[1] or "")
                local callback = ddConfig.Callback or function() end
                local flag = ddConfig.Flag
                local isOpen = false
                local selected = default

                local dFrame = Instance.new("Frame")
                dFrame.Name = "Dropdown_" .. dName
                dFrame.Size = UDim2.new(1, 0, 0, 38)
                dFrame.BackgroundColor3 = Theme.CardBg
                dFrame.ClipsDescendants = true
                dFrame.Parent = container

                local dCorner = Instance.new("UICorner")
                dCorner.CornerRadius = UDim.new(0, 8)
                dCorner.Parent = dFrame

                local dStroke = Instance.new("UIStroke")
                dStroke.Color = Theme.CardStroke
                dStroke.Transparency = 0.8
                dStroke.Thickness = 1
                dStroke.Parent = dFrame

                local headerBtn = Instance.new("TextButton")
                headerBtn.Size = UDim2.new(1, 0, 0, 38)
                headerBtn.BackgroundTransparency = 1
                headerBtn.Text = ""
                headerBtn.Parent = dFrame

                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(0.45, 0, 0, 38)
                title.Position = UDim2.new(0, 14, 0, 0)
                title.BackgroundTransparency = 1
                title.Text = dName
                title.TextColor3 = Theme.TextPrimary
                title.Font = Enum.Font.GothamMedium
                title.TextSize = 13
                title.TextXAlignment = Enum.TextXAlignment.Left
                title.Parent = headerBtn

                local selectedLabel = Instance.new("TextLabel")
                selectedLabel.Size = UDim2.new(0.45, -34, 0, 38)
                selectedLabel.Position = UDim2.new(0.5, 0, 0, 0)
                selectedLabel.BackgroundTransparency = 1
                selectedLabel.Text = tostring(selected)
                selectedLabel.TextColor3 = Theme.Accent
                selectedLabel.Font = Enum.Font.GothamBold
                selectedLabel.TextSize = 12
                selectedLabel.TextXAlignment = Enum.TextXAlignment.Right
                selectedLabel.Parent = headerBtn

                local arrow = Instance.new("TextLabel")
                arrow.Size = UDim2.new(0, 20, 0, 38)
                arrow.Position = UDim2.new(1, -28, 0, 0)
                arrow.BackgroundTransparency = 1
                arrow.Text = "▼"
                arrow.TextColor3 = Theme.TextMuted
                arrow.Font = Enum.Font.GothamBold
                arrow.TextSize = 10
                arrow.Parent = headerBtn

                local optionsScroll = Instance.new("ScrollingFrame")
                optionsScroll.Size = UDim2.new(1, -20, 0, 120)
                optionsScroll.Position = UDim2.new(0, 10, 0, 42)
                optionsScroll.BackgroundTransparency = 1
                optionsScroll.ScrollBarThickness = 2
                optionsScroll.ScrollBarImageColor3 = Theme.Accent
                optionsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                optionsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                optionsScroll.Parent = dFrame

                local optList = Instance.new("UIListLayout")
                optList.Padding = UDim.new(0, 4)
                optList.SortOrder = Enum.SortOrder.LayoutOrder
                optList.Parent = optionsScroll

                local function PopulateOptions(newOptions)
                    for _, child in ipairs(optionsScroll:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end

                    for _, optName in ipairs(newOptions) do
                        local optBtn = Instance.new("TextButton")
                        optBtn.Size = UDim2.new(1, 0, 0, 28)
                        optBtn.BackgroundColor3 = Color3.fromRGB(24, 40, 76)
                        optBtn.BackgroundTransparency = 0.5
                        optBtn.Text = tostring(optName)
                        optBtn.TextColor3 = (optName == selected) and Theme.Accent or Theme.TextMuted
                        optBtn.Font = Enum.Font.GothamMedium
                        optBtn.TextSize = 12
                        optBtn.Parent = optionsScroll

                        local optCorner = Instance.new("UICorner")
                        optCorner.CornerRadius = UDim.new(0, 6)
                        optCorner.Parent = optBtn

                        optBtn.MouseButton1Click:Connect(function()
                            selected = optName
                            selectedLabel.Text = tostring(selected)
                            if flag then Animula._Flags[flag] = selected end
                            isOpen = false
                            arrow.Text = "▼"
                            Tween(dFrame, { Size = UDim2.new(1, 0, 0, 38) }, 0.2)
                            pcall(callback, selected)
                        end)
                    end
                end

                PopulateOptions(options)

                local function ToggleOpen()
                    isOpen = not isOpen
                    if isOpen then
                        arrow.Text = "▲"
                        local targetHeight = math.min(170, 46 + (#options * 32))
                        Tween(dFrame, { Size = UDim2.new(1, 0, 0, targetHeight) }, 0.25)
                    else
                        arrow.Text = "▼"
                        Tween(dFrame, { Size = UDim2.new(1, 0, 0, 38) }, 0.2)
                    end
                end

                headerBtn.MouseButton1Click:Connect(ToggleOpen)

                return {
                    Set = function(_, val)
                        selected = val
                        selectedLabel.Text = tostring(selected)
                        if flag then Animula._Flags[flag] = selected end
                        pcall(callback, selected)
                    end,
                    Refresh = function(_, newOptions, autoSelectFirst)
                        options = newOptions or {}
                        PopulateOptions(options)
                        if autoSelectFirst and options[1] then
                            selected = options[1]
                            selectedLabel.Text = tostring(selected)
                            pcall(callback, selected)
                        end
                    end
                }
            end

            -- TEXTBOX
            function Elements:AddTextbox(tbConfig)
                tbConfig = tbConfig or {}
                local tbName = tbConfig.Name or "Textbox"
                local default = tbConfig.Default or ""
                local placeholder = tbConfig.PlaceholderText or "Type here..."
                local clearOnFocus = tbConfig.TextDisappear or false
                local callback = tbConfig.Callback or function() end

                local tbFrame = Instance.new("Frame")
                tbFrame.Name = "Textbox_" .. tbName
                tbFrame.Size = UDim2.new(1, 0, 0, 38)
                tbFrame.BackgroundColor3 = Theme.CardBg
                tbFrame.Parent = container

                local tbCorner = Instance.new("UICorner")
                tbCorner.CornerRadius = UDim.new(0, 8)
                tbCorner.Parent = tbFrame

                local tbStroke = Instance.new("UIStroke")
                tbStroke.Color = Theme.CardStroke
                tbStroke.Transparency = 0.8
                tbStroke.Thickness = 1
                tbStroke.Parent = tbFrame

                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(0.5, 0, 1, 0)
                title.Position = UDim2.new(0, 14, 0, 0)
                title.BackgroundTransparency = 1
                title.Text = tbName
                title.TextColor3 = Theme.TextPrimary
                title.Font = Enum.Font.GothamMedium
                title.TextSize = 13
                title.TextXAlignment = Enum.TextXAlignment.Left
                title.Parent = tbFrame

                local boxInput = Instance.new("TextBox")
                boxInput.Size = UDim2.new(0.45, 0, 0, 24)
                boxInput.Position = UDim2.new(0.55, -14, 0.5, -12)
                boxInput.BackgroundColor3 = Color3.fromRGB(11, 19, 36)
                boxInput.Text = default
                boxInput.PlaceholderText = placeholder
                boxInput.TextColor3 = Theme.TextPrimary
                boxInput.PlaceholderColor3 = Theme.TextDark
                boxInput.Font = Enum.Font.GothamMedium
                boxInput.TextSize = 12
                boxInput.ClearTextOnFocus = clearOnFocus
                boxInput.Parent = tbFrame

                local boxCorner = Instance.new("UICorner")
                boxCorner.CornerRadius = UDim.new(0, 6)
                boxCorner.Parent = boxInput

                local boxStroke = Instance.new("UIStroke")
                boxStroke.Color = Theme.Accent
                boxStroke.Transparency = 0.8
                boxStroke.Thickness = 1
                boxStroke.Parent = boxInput

                boxInput.Focused:Connect(function()
                    Tween(boxStroke, { Transparency = 0.2 }, 0.15)
                end)
                boxInput.FocusLost:Connect(function()
                    Tween(boxStroke, { Transparency = 0.8 }, 0.15)
                    pcall(callback, boxInput.Text)
                end)

                return {
                    Set = function(_, text)
                        boxInput.Text = tostring(text)
                        pcall(callback, boxInput.Text)
                    end
                }
            end

            -- PARAGRAPH
            function Elements:AddParagraph(param1, param2)
                local pTitle, pContent
                if type(param1) == "table" then
                    pTitle = param1.Title or param1.Name or "Paragraph"
                    pContent = param1.Content or param1.Text or ""
                else
                    pTitle = tostring(param1 or "Paragraph")
                    pContent = tostring(param2 or "")
                end

                local pFrame = Instance.new("Frame")
                pFrame.Name = "Paragraph"
                pFrame.Size = UDim2.new(1, 0, 0, 0)
                pFrame.AutomaticSize = Enum.AutomaticSize.Y
                pFrame.BackgroundColor3 = Theme.CardBg
                pFrame.Parent = container

                local pCorner = Instance.new("UICorner")
                pCorner.CornerRadius = UDim.new(0, 8)
                pCorner.Parent = pFrame

                local pStroke = Instance.new("UIStroke")
                pStroke.Color = Theme.CardStroke
                pStroke.Transparency = 0.85
                pStroke.Thickness = 1
                pStroke.Parent = pFrame

                local pPadding = Instance.new("UIPadding")
                pPadding.PaddingTop = UDim.new(0, 10)
                pPadding.PaddingBottom = UDim.new(0, 12)
                pPadding.PaddingLeft = UDim.new(0, 14)
                pPadding.PaddingRight = UDim.new(0, 14)
                pPadding.Parent = pFrame

                local titleLabel = Instance.new("TextLabel")
                titleLabel.Size = UDim2.new(1, 0, 0, 18)
                titleLabel.BackgroundTransparency = 1
                titleLabel.Text = pTitle
                titleLabel.TextColor3 = Theme.Accent
                titleLabel.Font = Enum.Font.GothamBold
                titleLabel.TextSize = 13
                titleLabel.TextXAlignment = Enum.TextXAlignment.Left
                titleLabel.Parent = pFrame

                local contentLabel = Instance.new("TextLabel")
                contentLabel.Size = UDim2.new(1, 0, 0, 0)
                contentLabel.Position = UDim2.new(0, 0, 0, 20)
                contentLabel.AutomaticSize = Enum.AutomaticSize.Y
                contentLabel.BackgroundTransparency = 1
                contentLabel.Text = pContent
                contentLabel.TextColor3 = Theme.TextMuted
                contentLabel.Font = Enum.Font.GothamMedium
                contentLabel.TextSize = 12
                contentLabel.TextWrapped = true
                contentLabel.TextXAlignment = Enum.TextXAlignment.Left
                contentLabel.Parent = pFrame

                return {
                    Set = function(_, newTitle, newContent)
                        titleLabel.Text = tostring(newTitle)
                        contentLabel.Text = tostring(newContent)
                    end
                }
            end

            -- LABEL
            function Elements:AddLabel(text)
                local lFrame = Instance.new("Frame")
                lFrame.Name = "Label"
                lFrame.Size = UDim2.new(1, 0, 0, 28)
                lFrame.BackgroundTransparency = 1
                lFrame.Parent = container

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.Text = tostring(text)
                label.TextColor3 = Theme.TextMuted
                label.Font = Enum.Font.GothamMedium
                label.TextSize = 12
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = lFrame

                return {
                    Set = function(_, newText) label.Text = tostring(newText) end
                }
            end

            -- COLORPICKER
            function Elements:AddColorpicker(cpConfig)
                cpConfig = cpConfig or {}
                local cpName = cpConfig.Name or "Colorpicker"
                local defaultColor = cpConfig.Default or Color3.fromRGB(56, 189, 248)
                local callback = cpConfig.Callback or function() end
                local currentColor = defaultColor

                local cpFrame = Instance.new("Frame")
                cpFrame.Name = "Colorpicker_" .. cpName
                cpFrame.Size = UDim2.new(1, 0, 0, 38)
                cpFrame.BackgroundColor3 = Theme.CardBg
                cpFrame.Parent = container

                local cpCorner = Instance.new("UICorner")
                cpCorner.CornerRadius = UDim.new(0, 8)
                cpCorner.Parent = cpFrame

                local cpStroke = Instance.new("UIStroke")
                cpStroke.Color = Theme.CardStroke
                cpStroke.Transparency = 0.8
                cpStroke.Thickness = 1
                cpStroke.Parent = cpFrame

                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, -60, 1, 0)
                title.Position = UDim2.new(0, 14, 0, 0)
                title.BackgroundTransparency = 1
                title.Text = cpName
                title.TextColor3 = Theme.TextPrimary
                title.Font = Enum.Font.GothamMedium
                title.TextSize = 13
                title.TextXAlignment = Enum.TextXAlignment.Left
                title.Parent = cpFrame

                local colorPreview = Instance.new("Frame")
                colorPreview.Size = UDim2.new(0, 30, 0, 20)
                colorPreview.Position = UDim2.new(1, -44, 0.5, -10)
                colorPreview.BackgroundColor3 = currentColor
                colorPreview.Parent = cpFrame

                local prevCorner = Instance.new("UICorner")
                prevCorner.CornerRadius = UDim.new(0, 4)
                prevCorner.Parent = colorPreview

                return {
                    Set = function(_, color)
                        currentColor = color
                        colorPreview.BackgroundColor3 = currentColor
                        pcall(callback, currentColor)
                    end,
                    Value = currentColor
                }
            end

            -- KEYBIND
            function Elements:AddBind(bindConfig)
                bindConfig = bindConfig or {}
                local bName = bindConfig.Name or "Keybind"
                local defaultKey = bindConfig.Default or Enum.KeyCode.RightControl
                local callback = bindConfig.Callback or function() end
                local currentKey = defaultKey
                local isListening = false

                local bFrame = Instance.new("Frame")
                bFrame.Name = "Bind_" .. bName
                bFrame.Size = UDim2.new(1, 0, 0, 38)
                bFrame.BackgroundColor3 = Theme.CardBg
                bFrame.Parent = container

                local bCorner = Instance.new("UICorner")
                bCorner.CornerRadius = UDim.new(0, 8)
                bCorner.Parent = bFrame

                local bStroke = Instance.new("UIStroke")
                bStroke.Color = Theme.CardStroke
                bStroke.Transparency = 0.8
                bStroke.Thickness = 1
                bStroke.Parent = bFrame

                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(0.6, 0, 1, 0)
                title.Position = UDim2.new(0, 14, 0, 0)
                title.BackgroundTransparency = 1
                title.Text = bName
                title.TextColor3 = Theme.TextPrimary
                title.Font = Enum.Font.GothamMedium
                title.TextSize = 13
                title.TextXAlignment = Enum.TextXAlignment.Left
                title.Parent = bFrame

                local bindBtn = Instance.new("TextButton")
                bindBtn.Size = UDim2.new(0.35, 0, 0, 24)
                bindBtn.Position = UDim2.new(0.65, -14, 0.5, -12)
                bindBtn.BackgroundColor3 = Color3.fromRGB(11, 19, 36)
                bindBtn.Text = currentKey.Name
                bindBtn.TextColor3 = Theme.Accent
                bindBtn.Font = Enum.Font.GothamBold
                bindBtn.TextSize = 12
                bindBtn.Parent = bFrame

                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 6)
                btnCorner.Parent = bindBtn

                bindBtn.MouseButton1Click:Connect(function()
                    isListening = true
                    bindBtn.Text = "..."
                end)

                UserInputService.InputBegan:Connect(function(input, gpe)
                    if isListening and not gpe and input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode
                        bindBtn.Text = currentKey.Name
                        isListening = false
                    elseif not isListening and not gpe and input.KeyCode == currentKey then
                        pcall(callback)
                    end
                end)

                return {
                    Set = function(_, key)
                        currentKey = key
                        bindBtn.Text = currentKey.Name
                    end
                }
            end

            return Elements
        end

        local TabElements = CreateElementsFactory(Page)
        for k, v in pairs(TabElements) do
            TabObj[k] = v
        end

        return TabObj
    end

    table.insert(Animula._Windows, WindowObj)
    return WindowObj
end

-- ==============================================================================
-- Library Lifecycle & Config Management
-- ==============================================================================
function Animula:Init()
    for _, win in ipairs(Animula._Windows) do
        if win._Main then
            win._Main.Size = UDim2.new(0, 680, 0, 440)
            win._Main.BackgroundTransparency = 0
            Tween(win._Main, { Position = UDim2.new(0.5, -340, 0.5, -220) }, 0.35, Enum.EasingStyle.Back)
        end
    end
end

function Animula:Destroy()
    for _, win in ipairs(Animula._Windows) do
        if win._ScreenGui and win._ScreenGui.Parent then
            win._ScreenGui:Destroy()
        end
    end
    if NotificationGui and NotificationGui.Parent then
        NotificationGui:Destroy()
    end
    Animula._Windows = {}
end

function Animula:SaveConfig()
    if not writefile then return end
    pcall(function()
        local folder = Animula._ConfigFolder or "AnimulaHub"
        if makefolder and not isfolder(folder) then
            makefolder(folder)
        end
        local path = folder .. "/config.json"
        local encoded = HttpService:JSONEncode(Animula._Flags)
        writefile(path, encoded)
        Animula:MakeNotification({
            Name = "Config Saved",
            Content = "Settings saved to " .. path,
            Time = 3
        })
    end)
end

return Animula
