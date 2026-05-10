--[[
    ╔══════════════════════════════════════════════╗
    ║       Lumo Administration System v1.0        ║
    ║       Client-side personal admin panel       ║
    ║       Press ; or Insert to open bar          ║
    ╚══════════════════════════════════════════════╝

    USAGE (executor):
        local LumoAdmin = loadstring(game:HttpGet("RAW_URL"))()

    ADDING COMMANDS AFTER LOAD:
        LumoAdmin.AddCommand("mycommand", {
            Description = "Does something cool",
            Aliases     = {"mc", "mycmd"},
            Usage       = "mycommand <arg>",
            Execute     = function(args)
                LumoAdmin.Notify({ Title = "My Command", Message = args[1], Type = "Success" })
            end
        })
]]

-- ═══════════════════════════════════════════
--  CORE MODULE
-- ═══════════════════════════════════════════

local LumoAdmin   = {}
LumoAdmin._VERSION = "1.0.0"
LumoAdmin._NAME    = "Lumo Administration System"
LumoAdmin.Commands = {}
LumoAdmin.Settings = {
    OpenKey            = Enum.KeyCode.Semicolon,
    AltOpenKey         = Enum.KeyCode.Insert,
    CommandHistorySize = 50,
    Theme              = "Dark",
}

-- ── Services ────────────────────────────────
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local Stats            = game:GetService("Stats")
local TeleportService  = game:GetService("TeleportService")
local Lighting         = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ── State ────────────────────────────────────
local commandHistory = {}
local historyIndex   = 0

-- ═══════════════════════════════════════════
--  THEME
-- ═══════════════════════════════════════════

local Themes = {
    Dark = {
        Background  = Color3.fromRGB(13, 13, 18),
        Secondary   = Color3.fromRGB(21, 21, 30),
        Tertiary    = Color3.fromRGB(30, 30, 42),
        Accent      = Color3.fromRGB(110, 130, 255),
        AccentDim   = Color3.fromRGB(65, 80, 190),
        Text        = Color3.fromRGB(225, 225, 235),
        TextDim     = Color3.fromRGB(130, 130, 155),
        Border      = Color3.fromRGB(38, 38, 55),
        Success     = Color3.fromRGB(72, 199, 116),
        Error       = Color3.fromRGB(215, 75, 75),
        Warning     = Color3.fromRGB(215, 175, 55),
        Info        = Color3.fromRGB(72, 155, 215),
    },
}

local function T()
    return Themes[LumoAdmin.Settings.Theme] or Themes.Dark
end

-- ═══════════════════════════════════════════
--  ROOT GUI
-- ═══════════════════════════════════════════

-- Destroy any previous instance (for re-execution)
local existingGui = PlayerGui:FindFirstChild("LumoAdmin")
if existingGui then existingGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name              = "LumoAdmin"
ScreenGui.ResetOnSpawn      = false
ScreenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder      = 999
ScreenGui.IgnoreGuiInset    = true
ScreenGui.Parent            = PlayerGui

-- ── Utility: UICorner ───────────────────────
local function Corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

-- ── Utility: UIStroke ───────────────────────
local function Stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color        = color or T().Border
    s.Thickness    = thickness or 1
    s.Transparency = transparency or 0
    s.Parent       = parent
    return s
end

-- ── Utility: ListLayout ─────────────────────
local function ListLayout(parent, padding, alignment)
    local l = Instance.new("UIListLayout")
    l.SortOrder          = Enum.SortOrder.LayoutOrder
    l.Padding            = UDim.new(0, padding or 4)
    l.VerticalAlignment  = alignment or Enum.VerticalAlignment.Top
    l.Parent             = parent
    return l
end

-- ── Utility: Padding ────────────────────────
local function Pad(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft   = UDim.new(0, left   or 0)
    p.PaddingRight  = UDim.new(0, right  or 0)
    p.Parent        = parent
    return p
end

-- ── Utility: Label ──────────────────────────
local function Label(parent, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font                   = props.Font        or Enum.Font.Gotham
    l.TextSize               = props.TextSize    or 13
    l.TextColor3             = props.TextColor3  or T().Text
    l.TextXAlignment         = props.Align       or Enum.TextXAlignment.Left
    l.TextWrapped            = props.Wrap        or false
    l.RichText               = props.RichText    or false
    l.Text                   = props.Text        or ""
    l.Size                   = props.Size        or UDim2.new(1, 0, 0, 20)
    l.Position               = props.Position    or UDim2.new(0, 0, 0, 0)
    l.LayoutOrder            = props.LayoutOrder or 0
    l.AutomaticSize          = props.AutoSize    or Enum.AutomaticSize.None
    l.Parent                 = parent
    return l
end

-- ═══════════════════════════════════════════
--  MAKE DRAGGABLE
-- ═══════════════════════════════════════════

function LumoAdmin.MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging  = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            startPos  = frame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement or
           inp.UserInputType == Enum.UserInputType.Touch then
            local delta = inp.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ═══════════════════════════════════════════
--  NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════

local NotifHolder = Instance.new("Frame")
NotifHolder.Name                = "NotifHolder"
NotifHolder.Size                = UDim2.new(0, 300, 1, -20)
NotifHolder.Position            = UDim2.new(1, -308, 0, 10)
NotifHolder.BackgroundTransparency = 1
NotifHolder.Parent              = ScreenGui

local notifListLayout = ListLayout(NotifHolder, 6)
notifListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifHolder.CanvasSize = UDim2.new(0,0,0,0)

local notifCount = 0

--[[
    LumoAdmin.Notify(options)

    options = {
        Title    : string  — Notification title
        Message  : string  — Body text
        Type     : string  — "Info" | "Success" | "Warning" | "Error"
        Duration : number  — Seconds before auto-dismiss (default 4)
    }

    Returns the container Frame.
]]
function LumoAdmin.Notify(options)
    options = options or {}
    local theme    = T()
    local title    = options.Title    or "Lumo Admin"
    local message  = options.Message  or ""
    local ntype    = options.Type     or "Info"
    local duration = options.Duration or 4

    local typeColor = ({
        Info    = theme.Info,
        Success = theme.Success,
        Warning = theme.Warning,
        Error   = theme.Error,
    })[ntype] or theme.Info

    notifCount = notifCount + 1

    -- Wrapper (for layout)
    local wrapper = Instance.new("Frame")
    wrapper.Name                = "Notif_" .. notifCount
    wrapper.Size                = UDim2.new(1, 0, 0, 0)
    wrapper.AutomaticSize       = Enum.AutomaticSize.Y
    wrapper.BackgroundTransparency = 1
    wrapper.LayoutOrder         = notifCount
    wrapper.ClipsDescendants    = false
    wrapper.Parent              = NotifHolder

    -- Card
    local card = Instance.new("Frame")
    card.Size             = UDim2.new(1, -4, 0, 0)
    card.AutomaticSize    = Enum.AutomaticSize.Y
    card.Position         = UDim2.new(0, 2, 0, 0)
    card.BackgroundColor3 = theme.Secondary
    card.BorderSizePixel  = 0
    card.Parent           = wrapper
    Corner(card, 10)
    Stroke(card, theme.Border, 1, 0.3)

    -- Accent side bar
    local accent = Instance.new("Frame")
    accent.Size             = UDim2.new(0, 3, 1, 0)
    accent.BackgroundColor3 = typeColor
    accent.BorderSizePixel  = 0
    accent.ZIndex           = 2
    accent.Parent           = card
    Corner(accent, 4)

    -- Content area
    local content = Instance.new("Frame")
    content.Size              = UDim2.new(1, -14, 0, 0)
    content.AutomaticSize     = Enum.AutomaticSize.Y
    content.Position          = UDim2.new(0, 12, 0, 0)
    content.BackgroundTransparency = 1
    content.Parent            = card
    Pad(content, 10, 10, 2, 6)
    ListLayout(content, 3)

    Label(content, {
        Text        = title,
        Font        = Enum.Font.GothamBold,
        TextSize    = 13,
        TextColor3  = theme.Text,
        Size        = UDim2.new(1, 0, 0, 18),
        LayoutOrder = 1,
    })
    Label(content, {
        Text        = message,
        TextSize    = 12,
        TextColor3  = theme.TextDim,
        Size        = UDim2.new(1, 0, 0, 0),
        AutoSize    = Enum.AutomaticSize.Y,
        Wrap        = true,
        LayoutOrder = 2,
    })

    -- Progress bar
    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(1, 0, 0, 2)
    bar.Position         = UDim2.new(0, 0, 1, -2)
    bar.BackgroundColor3 = typeColor
    bar.BorderSizePixel  = 0
    bar.ZIndex           = 3
    bar.Parent           = card

    -- Slide in from right
    card.Position = UDim2.new(1, 10, 0, 0)
    TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 2, 0, 0)
    }):Play()

    -- Progress shrink
    TweenService:Create(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 2)
    }):Play()

    -- Dismiss after duration
    task.delay(duration, function()
        TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 10, 0, 0)
        }):Play()
        task.delay(0.3, function()
            if wrapper and wrapper.Parent then wrapper:Destroy() end
        end)
    end)

    return wrapper
end

-- ═══════════════════════════════════════════
--  COMMAND BAR
-- ═══════════════════════════════════════════

local barOpen = false

-- Container
local Bar = Instance.new("Frame")
Bar.Name             = "CommandBar"
Bar.Size             = UDim2.new(0, 520, 0, 38)
Bar.AnchorPoint      = Vector2.new(0.5, 0)
Bar.Position         = UDim2.new(0.5, 0, 0, -60)   -- hidden off-screen
Bar.BackgroundColor3 = T().Background
Bar.BorderSizePixel  = 0
Bar.ClipsDescendants = false
Bar.Parent           = ScreenGui
Corner(Bar, 10)
Stroke(Bar, T().Accent, 1.5, 0.45)

-- ">" prompt symbol
local BarPrompt = Instance.new("TextLabel")
BarPrompt.Size                = UDim2.new(0, 28, 1, 0)
BarPrompt.Position            = UDim2.new(0, 8, 0, 0)
BarPrompt.BackgroundTransparency = 1
BarPrompt.Text                = ">"
BarPrompt.TextColor3          = T().Accent
BarPrompt.TextSize            = 17
BarPrompt.Font                = Enum.Font.GothamBold
BarPrompt.Parent              = Bar

-- Input box
local BarInput = Instance.new("TextBox")
BarInput.Size               = UDim2.new(1, -44, 1, 0)
BarInput.Position           = UDim2.new(0, 36, 0, 0)
BarInput.BackgroundTransparency = 1
BarInput.Text               = ""
BarInput.PlaceholderText    = "Type a command…   (Tab = autocomplete, ↑↓ = history)"
BarInput.PlaceholderColor3  = T().TextDim
BarInput.TextColor3         = T().Text
BarInput.TextSize           = 14
BarInput.Font               = Enum.Font.Gotham
BarInput.TextXAlignment     = Enum.TextXAlignment.Left
BarInput.ClearTextOnFocus   = false
BarInput.Parent             = Bar

-- ── Autocomplete dropdown ────────────────────
local ACFrame = Instance.new("Frame")
ACFrame.Name             = "Autocomplete"
ACFrame.Size             = UDim2.new(1, 0, 0, 0)
ACFrame.Position         = UDim2.new(0, 0, 1, 6)
ACFrame.BackgroundColor3 = T().Secondary
ACFrame.BorderSizePixel  = 0
ACFrame.ClipsDescendants = true
ACFrame.Visible          = false
ACFrame.Parent           = Bar
Corner(ACFrame, 8)
Stroke(ACFrame, T().Border, 1)

local acList = ListLayout(ACFrame, 0)
Pad(ACFrame, 4, 4, 0, 0)

local function ClearACItems()
    for _, c in ipairs(ACFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
end

local function ShowAutocomplete(text)
    ClearACItems()
    if text == "" then ACFrame.Visible = false return end

    local lower   = text:lower()
    local matches = {}

    for name, cmd in pairs(LumoAdmin.Commands) do
        if name:sub(1, #lower) == lower then
            table.insert(matches, { name = name, cmd = cmd })
        end
        if cmd.Aliases then
            for _, alias in ipairs(cmd.Aliases) do
                if alias:lower():sub(1, #lower) == lower then
                    -- only add if not already from name
                    local already = false
                    for _, m in ipairs(matches) do if m.name == name then already = true break end end
                    if not already then table.insert(matches, { name = name, cmd = cmd, matched = alias }) end
                    break
                end
            end
        end
    end

    table.sort(matches, function(a, b) return a.name < b.name end)

    local max = math.min(#matches, 7)
    if max == 0 then ACFrame.Visible = false return end

    local rowH = 30
    ACFrame.Size    = UDim2.new(1, 0, 0, max * rowH + 8)
    ACFrame.Visible = true

    for i = 1, max do
        local m   = matches[i]
        local row = Instance.new("TextButton")
        row.Size                = UDim2.new(1, 0, 0, rowH)
        row.BackgroundTransparency = 1
        row.Text                = ""
        row.LayoutOrder         = i
        row.Parent              = ACFrame

        -- command name
        local nl = Label(row, {
            Text       = m.matched and (m.name .. "  <font color='#888888'>alias: " .. m.matched .. "</font>") or m.name,
            Font       = Enum.Font.GothamBold,
            TextSize   = 12,
            TextColor3 = T().Accent,
            Size       = UDim2.new(0.55, -10, 1, 0),
            Position   = UDim2.new(0, 10, 0, 0),
            RichText   = true,
        })

        -- description
        Label(row, {
            Text       = m.cmd.Description or "",
            TextSize   = 11,
            TextColor3 = T().TextDim,
            Size       = UDim2.new(0.45, -10, 1, 0),
            Position   = UDim2.new(0.55, 0, 0, 0),
            Align      = Enum.TextXAlignment.Right,
        })

        row.MouseEnter:Connect(function()
            TweenService:Create(row, TweenInfo.new(0.1), { BackgroundTransparency = 0.8 }):Play()
            row.BackgroundColor3 = T().Accent
        end)
        row.MouseLeave:Connect(function()
            TweenService:Create(row, TweenInfo.new(0.1), { BackgroundTransparency = 1 }):Play()
        end)
        row.MouseButton1Click:Connect(function()
            BarInput.Text = m.name .. " "
            ACFrame.Visible = false
            BarInput:CaptureFocus()
            BarInput.CursorPosition = #BarInput.Text + 1
        end)
    end
end

-- Update autocomplete as user types
BarInput:GetPropertyChangedSignal("Text"):Connect(function()
    local t = BarInput.Text
    local word = t:match("^(%S*)$")   -- only show while typing first word (no space yet)
    if word then
        ShowAutocomplete(word)
    else
        ACFrame.Visible = false
    end
end)

-- ── Open / Close ─────────────────────────────
local function OpenBar()
    barOpen        = true
    BarInput.Text  = ""
    ACFrame.Visible = false
    TweenService:Create(Bar, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0, 14)
    }):Play()
    task.delay(0.05, function() BarInput:CaptureFocus() end)
end

local function CloseBar()
    barOpen = false
    ACFrame.Visible = false
    BarInput:ReleaseFocus()
    TweenService:Create(Bar, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, 0, 0, -60)
    }):Play()
end

-- ═══════════════════════════════════════════
--  COMMAND PARSING & EXECUTION
-- ═══════════════════════════════════════════

local function ParseArgs(input)
    local args = {}
    -- support quoted strings: "hello world"
    for token in input:gmatch('[^%s"]+|"[^"]*"') do
        table.insert(args, token:gsub('^"(.*)"$', "%1"))
    end
    if #args == 0 then
        for token in input:gmatch("%S+") do table.insert(args, token) end
    end
    return args
end

local function RunCommand(raw)
    raw = raw:match("^%s*(.-)%s*$")
    if raw == "" then return end

    -- history
    if commandHistory[1] ~= raw then
        table.insert(commandHistory, 1, raw)
        if #commandHistory > LumoAdmin.Settings.CommandHistorySize then
            table.remove(commandHistory)
        end
    end
    historyIndex = 0

    local args    = ParseArgs(raw)
    local cmdKey  = args[1]:lower()
    table.remove(args, 1)

    -- resolve command (name or alias)
    local found = nil
    for name, def in pairs(LumoAdmin.Commands) do
        if name == cmdKey then found = def break end
        if def.Aliases then
            for _, alias in ipairs(def.Aliases) do
                if alias:lower() == cmdKey then found = def break end
            end
        end
        if found then break end
    end

    if found then
        local ok, err = pcall(found.Execute, args)
        if not ok then
            LumoAdmin.Notify({ Title = "Runtime Error", Message = tostring(err), Type = "Error", Duration = 6 })
        end
    else
        LumoAdmin.Notify({
            Title   = "Unknown Command",
            Message = "'" .. cmdKey .. "' not found. Type 'cmds' to browse commands.",
            Type    = "Warning",
        })
    end
end

-- Focus lost = submit or close
BarInput.FocusLost:Connect(function(entered)
    if entered then
        local text = BarInput.Text
        CloseBar()
        RunCommand(text)
    else
        CloseBar()
    end
end)

-- ── Key input ────────────────────────────────
UserInputService.InputBegan:Connect(function(inp, gpe)
    -- Toggle bar
    if not gpe then
        if inp.KeyCode == LumoAdmin.Settings.OpenKey or inp.KeyCode == LumoAdmin.Settings.AltOpenKey then
            if barOpen then CloseBar() else OpenBar() end
            return
        end
    end

    if not barOpen then return end

    if inp.KeyCode == Enum.KeyCode.Escape then
        CloseBar()

    elseif inp.KeyCode == Enum.KeyCode.Up then
        if #commandHistory > 0 then
            historyIndex = math.min(historyIndex + 1, #commandHistory)
            BarInput.Text = commandHistory[historyIndex]
            task.defer(function() BarInput.CursorPosition = #BarInput.Text + 1 end)
        end

    elseif inp.KeyCode == Enum.KeyCode.Down then
        if historyIndex > 1 then
            historyIndex = historyIndex - 1
            BarInput.Text = commandHistory[historyIndex]
        else
            historyIndex  = 0
            BarInput.Text = ""
        end

    elseif inp.KeyCode == Enum.KeyCode.Tab then
        local word = BarInput.Text:match("^(%S*)$")
        if word then
            local hits = {}
            for name in pairs(LumoAdmin.Commands) do
                if name:sub(1, #word) == word:lower() then table.insert(hits, name) end
            end
            if #hits == 1 then
                BarInput.Text = hits[1] .. " "
                ACFrame.Visible = false
                task.defer(function() BarInput.CursorPosition = #BarInput.Text + 1 end)
            end
        end
    end
end)

-- ═══════════════════════════════════════════
--  ADD COMMAND API
-- ═══════════════════════════════════════════

--[[
    LumoAdmin.AddCommand(name, definition)

    name:       string — primary command name (lowercase recommended)
    definition: {
        Description : string
        Aliases     : table<string>
        Usage       : string          — shown in cmds list (e.g. "ws <speed>")
        Execute     : function(args)  — args is a table of string tokens
    }
]]
function LumoAdmin.AddCommand(name, def)
    assert(type(name) == "string",   "AddCommand: name must be a string")
    assert(type(def)  == "table",    "AddCommand: definition must be a table")
    assert(type(def.Execute) == "function", "AddCommand: Execute must be a function")
    LumoAdmin.Commands[name:lower()] = def
end

-- ═══════════════════════════════════════════
--  CREATE WINDOW HELPER
-- ═══════════════════════════════════════════

--[[
    LumoAdmin.CreateWindow(options)  → WindowHandle

    options = {
        Title    : string
        Size     : UDim2  (default 400×300)
        Position : UDim2  (default screen center)
    }

    WindowHandle = {
        Window  : Frame      — the root frame
        Content : Frame      — inner content area (use this to add children)
        Close   : function() — programmatically close / animate out
    }
]]
function LumoAdmin.CreateWindow(options)
    options = options or {}
    local theme    = T()
    local title    = options.Title    or "Lumo"
    local targetSz = options.Size     or UDim2.new(0, 400, 0, 320)
    local pos      = options.Position or UDim2.new(0.5, 0, 0.5, 0)

    local win = Instance.new("Frame")
    win.Name             = title:gsub("[%s%p]", "") .. "Win"
    win.Size             = UDim2.new(targetSz.X.Scale, targetSz.X.Offset, 0, 0)
    win.AnchorPoint      = Vector2.new(0.5, 0.5)
    win.Position         = pos
    win.BackgroundColor3 = theme.Background
    win.BorderSizePixel  = 0
    win.ClipsDescendants = true
    win.Parent           = ScreenGui
    Corner(win, 12)
    Stroke(win, theme.Border, 1)

    -- Title bar
    local tb = Instance.new("Frame")
    tb.Size             = UDim2.new(1, 0, 0, 44)
    tb.BackgroundColor3 = theme.Secondary
    tb.BorderSizePixel  = 0
    tb.Parent           = win
    Corner(tb, 12)

    -- Cover bottom-round of title bar
    local tbf = Instance.new("Frame")
    tbf.Size             = UDim2.new(1, 0, 0.5, 0)
    tbf.Position         = UDim2.new(0, 0, 0.5, 0)
    tbf.BackgroundColor3 = theme.Secondary
    tbf.BorderSizePixel  = 0
    tbf.Parent           = tb

    Label(tb, {
        Text       = title,
        Font       = Enum.Font.GothamBold,
        TextSize   = 14,
        TextColor3 = theme.Text,
        Size       = UDim2.new(1, -52, 1, 0),
        Position   = UDim2.new(0, 16, 0, 0),
    })

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size             = UDim2.new(0, 28, 0, 28)
    closeBtn.Position         = UDim2.new(1, -36, 0.5, -14)
    closeBtn.BackgroundColor3 = theme.Error
    closeBtn.BorderSizePixel  = 0
    closeBtn.Text             = "✕"
    closeBtn.TextColor3       = Color3.new(1, 1, 1)
    closeBtn.TextSize         = 12
    closeBtn.Font             = Enum.Font.GothamBold
    closeBtn.Parent           = tb
    Corner(closeBtn, 6)

    -- Content
    local content = Instance.new("Frame")
    content.Name                = "Content"
    content.Size                = UDim2.new(1, -24, 1, -56)
    content.Position            = UDim2.new(0, 12, 0, 52)
    content.BackgroundTransparency = 1
    content.Parent              = win

    LumoAdmin.MakeDraggable(win, tb)

    -- Animate open
    TweenService:Create(win, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = targetSz
    }):Play()

    local function doClose()
        TweenService:Create(win, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Size = UDim2.new(targetSz.X.Scale, targetSz.X.Offset, 0, 0)
        }):Play()
        task.delay(0.22, function() if win and win.Parent then win:Destroy() end end)
    end

    closeBtn.MouseButton1Click:Connect(doClose)

    return { Window = win, Content = content, Close = doClose }
end

-- ═══════════════════════════════════════════
--  FEATURE SUBSYSTEMS
-- ═══════════════════════════════════════════

-- ── Fly ──────────────────────────────────────
local flyActive      = false
local flySpeed       = 60
local flyConns       = {}

local function StopFly()
    if not flyActive then return end
    flyActive = false
    for _, c in ipairs(flyConns) do c:Disconnect() end
    flyConns = {}
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            local bv = root:FindFirstChildOfClass("BodyVelocity")
            local bg = root:FindFirstChildOfClass("BodyGyro")
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
        end
    end
    LumoAdmin.Notify({ Title = "Fly", Message = "Fly disabled.", Type = "Info", Duration = 2 })
end

local function StartFly()
    if flyActive then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then
        LumoAdmin.Notify({ Title = "Fly", Message = "No character found.", Type = "Error" })
        return
    end
    flyActive            = true
    hum.PlatformStand    = true

    local bv           = Instance.new("BodyVelocity")
    bv.Velocity        = Vector3.zero
    bv.MaxForce        = Vector3.new(1e5, 1e5, 1e5)
    bv.Parent          = root

    local bg           = Instance.new("BodyGyro")
    bg.MaxTorque       = Vector3.new(1e5, 1e5, 1e5)
    bg.P               = 1e4
    bg.D               = 100
    bg.Parent          = root

    table.insert(flyConns, RunService.Heartbeat:Connect(function()
        if not flyActive or not root or not root.Parent then return end
        local cam = workspace.CurrentCamera
        local vel = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then vel += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vel -= Vector3.yAxis end
        bv.Velocity  = vel.Magnitude > 0 and vel.Unit * flySpeed or Vector3.zero
        bg.CFrame    = cam.CFrame
    end))

    -- Re-init if character respawns
    table.insert(flyConns, LocalPlayer.CharacterAdded:Connect(function()
        StopFly()
    end))

    LumoAdmin.Notify({ Title = "Fly", Message = "Fly enabled. WASD + Space/Shift to move.", Type = "Success" })
end

-- ── Noclip ───────────────────────────────────
local noclipActive = false
local noclipConn

local function StopNoclip()
    if not noclipActive then return end
    noclipActive = false
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    local char = LocalPlayer.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end
    LumoAdmin.Notify({ Title = "Noclip", Message = "Noclip disabled.", Type = "Info", Duration = 2 })
end

local function StartNoclip()
    if noclipActive then return end
    noclipActive = true
    noclipConn   = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end)
    LumoAdmin.Notify({ Title = "Noclip", Message = "Noclip enabled.", Type = "Success", Duration = 2 })
end

-- ── Freecam ──────────────────────────────────
local fcActive      = false
local fcConns       = {}
local fcPart
local fcOrigSubject
local fcOrigCamType

local function StopFreecam()
    if not fcActive then return end
    fcActive = false
    for _, c in ipairs(fcConns) do c:Disconnect() end
    fcConns = {}
    if fcPart then fcPart:Destroy() fcPart = nil end
    local cam      = workspace.CurrentCamera
    cam.CameraType = fcOrigCamType or Enum.CameraType.Custom
    LumoAdmin.Notify({ Title = "Freecam", Message = "Freecam disabled.", Type = "Info", Duration = 2 })
end

local function StartFreecam()
    if fcActive then return end
    fcActive       = true
    local cam      = workspace.CurrentCamera
    fcOrigCamType  = cam.CameraType
    cam.CameraType = Enum.CameraType.Scriptable

    fcPart              = Instance.new("Part")
    fcPart.Anchored     = true
    fcPart.CanCollide   = false
    fcPart.Transparency = 1
    fcPart.Size         = Vector3.one
    fcPart.CFrame       = cam.CFrame
    fcPart.Parent       = workspace

    local speed = 50
    table.insert(fcConns, RunService.RenderStepped:Connect(function(dt)
        if not fcActive then return end
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
        if dir.Magnitude > 0 then
            fcPart.CFrame += dir.Unit * speed * dt
        end
        cam.CFrame = fcPart.CFrame
    end))

    LumoAdmin.Notify({ Title = "Freecam", Message = "Freecam on. WASD + Space/Shift to fly.", Type = "Success" })
end

-- ── View/Unview ──────────────────────────────
local viewOrigSubject = nil

local function ViewPlayer(target)
    local cam  = workspace.CurrentCamera
    local char = target.Character
    if not char then
        LumoAdmin.Notify({ Title = "View", Message = target.Name .. " has no character.", Type = "Error" })
        return
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if not viewOrigSubject then viewOrigSubject = cam.CameraSubject end
    cam.CameraSubject = hum
    LumoAdmin.Notify({ Title = "View", Message = "Spectating " .. target.Name, Type = "Info" })
end

local function UnviewPlayer()
    local cam = workspace.CurrentCamera
    if viewOrigSubject and viewOrigSubject.Parent then
        cam.CameraSubject = viewOrigSubject
    else
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then cam.CameraSubject = hum end
    end
    viewOrigSubject = nil
    LumoAdmin.Notify({ Title = "View", Message = "Returned to own camera.", Type = "Info" })
end

-- ── Player resolver ──────────────────────────
local function FindPlayer(query)
    query = query:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(query, 1, true) or p.DisplayName:lower():find(query, 1, true) then
            return p
        end
    end
    return nil
end

-- ═══════════════════════════════════════════
--  COMMANDS GUI
-- ═══════════════════════════════════════════

local function OpenCommandsGui()
    local theme = T()
    local existing = ScreenGui:FindFirstChild("CommandsGuiWin")
    if existing then existing:Destroy() end

    local handle = LumoAdmin.CreateWindow({ Title = "Lumo Admin — Commands", Size = UDim2.new(0, 500, 0, 540) })
    handle.Window.Name = "CommandsGuiWin"

    local content = handle.Content

    -- Search bar
    local searchWrap = Instance.new("Frame")
    searchWrap.Size             = UDim2.new(1, 0, 0, 34)
    searchWrap.BackgroundColor3 = theme.Secondary
    searchWrap.BorderSizePixel  = 0
    searchWrap.LayoutOrder      = 0
    searchWrap.Parent           = content
    Corner(searchWrap, 8)
    Stroke(searchWrap, theme.Border)

    Label(searchWrap, {
        Text       = "🔍",
        TextSize   = 14,
        TextColor3 = theme.TextDim,
        Size       = UDim2.new(0, 32, 1, 0),
        Align      = Enum.TextXAlignment.Center,
    })

    local searchBox = Instance.new("TextBox")
    searchBox.Size               = UDim2.new(1, -36, 1, 0)
    searchBox.Position           = UDim2.new(0, 32, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText    = "Search commands…"
    searchBox.PlaceholderColor3  = theme.TextDim
    searchBox.TextColor3         = theme.Text
    searchBox.TextSize           = 13
    searchBox.Font               = Enum.Font.Gotham
    searchBox.TextXAlignment     = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus   = false
    searchBox.Parent             = searchWrap

    -- Scroll list
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size                  = UDim2.new(1, 0, 1, -42)
    scroll.Position              = UDim2.new(0, 0, 0, 42)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel       = 0
    scroll.ScrollBarThickness    = 4
    scroll.ScrollBarImageColor3  = theme.Accent
    scroll.CanvasSize            = UDim2.new()
    scroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    scroll.Parent                = content
    ListLayout(scroll, 4)

    local function Populate(filter)
        for _, c in ipairs(scroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end

        local fl = (filter or ""):lower()

        -- Gather and sort
        local entries = {}
        for name, def in pairs(LumoAdmin.Commands) do
            local aliases = def.Aliases and table.concat(def.Aliases, " / ") or ""
            local display = #aliases > 0 and (name .. "  /  " .. aliases) or name
            if fl == ""
              or name:find(fl, 1, true)
              or aliases:lower():find(fl, 1, true)
              or (def.Description or ""):lower():find(fl, 1, true) then
                table.insert(entries, { name = name, def = def, display = display })
            end
        end
        table.sort(entries, function(a, b) return a.name < b.name end)

        for i, e in ipairs(entries) do
            local row = Instance.new("Frame")
            row.Name             = e.name
            row.Size             = UDim2.new(1, 0, 0, 56)
            row.BackgroundColor3 = theme.Secondary
            row.BorderSizePixel  = 0
            row.LayoutOrder      = i
            row.Parent           = scroll
            Corner(row, 8)

            -- Accent left bar
            local ab = Instance.new("Frame")
            ab.Size             = UDim2.new(0, 3, 0.6, 0)
            ab.Position         = UDim2.new(0, 0, 0.2, 0)
            ab.BackgroundColor3 = theme.Accent
            ab.BorderSizePixel  = 0
            ab.Parent           = row
            Corner(ab, 4)

            Label(row, {
                Text       = e.display,
                Font       = Enum.Font.GothamBold,
                TextSize   = 13,
                TextColor3 = theme.Accent,
                Size       = UDim2.new(1, -16, 0, 22),
                Position   = UDim2.new(0, 12, 0, 6),
            })

            Label(row, {
                Text       = e.def.Description or "No description.",
                TextSize   = 11,
                TextColor3 = theme.TextDim,
                Size       = UDim2.new(0.7, -16, 0, 18),
                Position   = UDim2.new(0, 12, 0, 28),
            })

            if e.def.Usage then
                Label(row, {
                    Text       = e.def.Usage,
                    Font       = Enum.Font.Code,
                    TextSize   = 10,
                    TextColor3 = theme.TextDim,
                    Size       = UDim2.new(0.3, -12, 0, 18),
                    Position   = UDim2.new(0.7, 0, 0, 28),
                    Align      = Enum.TextXAlignment.Right,
                })
            end
        end

        if #entries == 0 then
            Label(scroll, {
                Text       = "No commands match '" .. filter .. "'",
                TextSize   = 13,
                TextColor3 = theme.TextDim,
                Size       = UDim2.new(1, 0, 0, 32),
                Align      = Enum.TextXAlignment.Center,
            })
        end
    end

    Populate("")
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        Populate(searchBox.Text)
    end)
end

-- ═══════════════════════════════════════════
--  SETTINGS GUI
-- ═══════════════════════════════════════════

local function OpenSettingsGui()
    local theme    = T()
    local existing = ScreenGui:FindFirstChild("SettingsGuiWin")
    if existing then existing:Destroy() end

    local handle = LumoAdmin.CreateWindow({ Title = "Lumo Admin — Settings", Size = UDim2.new(0, 420, 0, 320) })
    handle.Window.Name = "SettingsGuiWin"
    local content = handle.Content
    ListLayout(content, 8)

    -- Section label helper
    local function SectionLabel(text, order)
        local l = Label(content, {
            Text       = text,
            Font       = Enum.Font.GothamBold,
            TextSize   = 11,
            TextColor3 = theme.TextDim,
            Size       = UDim2.new(1, 0, 0, 16),
            LayoutOrder = order,
        })
        return l
    end

    -- Row helper
    local function Row(order)
        local r = Instance.new("Frame")
        r.Size             = UDim2.new(1, 0, 0, 46)
        r.BackgroundColor3 = theme.Secondary
        r.BorderSizePixel  = 0
        r.LayoutOrder      = order
        r.Parent           = content
        Corner(r, 8)
        return r
    end

    -- Keybind row
    local function KeybindRow(labelText, currentKey, order, onChange)
        local r = Row(order)
        Label(r, {
            Text       = labelText,
            TextSize   = 13,
            TextColor3 = theme.Text,
            Size       = UDim2.new(0.6, -12, 1, 0),
            Position   = UDim2.new(0, 12, 0, 0),
        })

        local kb = Instance.new("TextButton")
        kb.Size             = UDim2.new(0, 120, 0, 30)
        kb.Position         = UDim2.new(1, -128, 0.5, -15)
        kb.BackgroundColor3 = theme.Background
        kb.BorderSizePixel  = 0
        kb.Text             = currentKey.Name
        kb.TextColor3       = theme.Accent
        kb.TextSize         = 12
        kb.Font             = Enum.Font.GothamBold
        kb.Parent           = r
        Corner(kb, 6)
        Stroke(kb, theme.Border)

        local listening = false
        kb.MouseButton1Click:Connect(function()
            if listening then return end
            listening      = true
            kb.Text        = "Press a key…"
            kb.TextColor3  = theme.Warning
            local conn
            conn = UserInputService.InputBegan:Connect(function(inp)
                if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
                conn:Disconnect()
                listening     = false
                kb.Text       = inp.KeyCode.Name
                kb.TextColor3 = theme.Accent
                onChange(inp.KeyCode)
            end)
        end)
        return r
    end

    SectionLabel("KEYBINDS", 1)
    KeybindRow("Open Command Bar",  LumoAdmin.Settings.OpenKey,    2, function(k) LumoAdmin.Settings.OpenKey    = k end)
    KeybindRow("Alt Open Key",      LumoAdmin.Settings.AltOpenKey, 3, function(k) LumoAdmin.Settings.AltOpenKey = k end)

    SectionLabel("GENERAL", 4)

    local histRow = Row(5)
    Label(histRow, {
        Text       = "Command History Size",
        TextSize   = 13,
        TextColor3 = theme.Text,
        Size       = UDim2.new(0.6, -12, 1, 0),
        Position   = UDim2.new(0, 12, 0, 0),
    })
    local histTB = Instance.new("TextBox")
    histTB.Size             = UDim2.new(0, 60, 0, 30)
    histTB.Position         = UDim2.new(1, -68, 0.5, -15)
    histTB.BackgroundColor3 = theme.Background
    histTB.BorderSizePixel  = 0
    histTB.Text             = tostring(LumoAdmin.Settings.CommandHistorySize)
    histTB.TextColor3       = theme.Accent
    histTB.TextSize         = 13
    histTB.Font             = Enum.Font.GothamBold
    histTB.TextXAlignment   = Enum.TextXAlignment.Center
    histTB.Parent           = histRow
    Corner(histTB, 6)
    Stroke(histTB, theme.Border)

    histTB.FocusLost:Connect(function()
        local v = tonumber(histTB.Text)
        if v and v >= 5 then
            LumoAdmin.Settings.CommandHistorySize = math.floor(v)
        else
            histTB.Text = tostring(LumoAdmin.Settings.CommandHistorySize)
        end
    end)

    -- Version footer
    Label(content, {
        Text       = "Lumo Administration System  ·  v" .. LumoAdmin._VERSION .. "  ·  client-side only",
        TextSize   = 10,
        TextColor3 = theme.TextDim,
        Size       = UDim2.new(1, 0, 0, 16),
        Align      = Enum.TextXAlignment.Center,
        LayoutOrder = 99,
    })
end

-- ═══════════════════════════════════════════
--  BUILT-IN COMMANDS
-- ═══════════════════════════════════════════

LumoAdmin.AddCommand("cmds", {
    Description = "Browse all available commands with search",
    Aliases     = { "commands", "help" },
    Usage       = "cmds",
    Execute     = function() OpenCommandsGui() end,
})

LumoAdmin.AddCommand("settings", {
    Description = "Open the settings / keybind panel",
    Aliases     = { "config", "options" },
    Usage       = "settings",
    Execute     = function() OpenSettingsGui() end,
})

LumoAdmin.AddCommand("fly", {
    Description = "Toggle fly mode (WASD + Space/Shift)",
    Aliases     = { "unfly" },
    Usage       = "fly [speed]",
    Execute     = function(args)
        if args[1] then flySpeed = tonumber(args[1]) or flySpeed end
        if flyActive then StopFly() else StartFly() end
    end,
})

LumoAdmin.AddCommand("noclip", {
    Description = "Toggle no-collision through walls",
    Aliases     = { "clip", "nc" },
    Usage       = "noclip",
    Execute     = function()
        if noclipActive then StopNoclip() else StartNoclip() end
    end,
})

LumoAdmin.AddCommand("to", {
    Description = "Teleport to a player",
    Aliases     = { "goto", "tp" },
    Usage       = "to <player>",
    Execute     = function(args)
        if not args[1] then
            LumoAdmin.Notify({ Title = "to", Message = "Usage: to <player>", Type = "Warning" }) return
        end
        local target = FindPlayer(args[1])
        if not target then
            LumoAdmin.Notify({ Title = "to", Message = "Player '" .. args[1] .. "' not found.", Type = "Error" }) return
        end
        local char       = LocalPlayer.Character
        local targetChar = target.Character
        local root       = char       and char:FindFirstChild("HumanoidRootPart")
        local tRoot      = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        if root and tRoot then
            root.CFrame = tRoot.CFrame + Vector3.new(3, 0, 0)
            LumoAdmin.Notify({ Title = "Teleport", Message = "→ " .. target.Name, Type = "Success" })
        else
            LumoAdmin.Notify({ Title = "Teleport", Message = "Character missing.", Type = "Error" })
        end
    end,
})

LumoAdmin.AddCommand("sit", {
    Description = "Make your character sit",
    Aliases     = {},
    Usage       = "sit",
    Execute     = function()
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Sit = true end
    end,
})

LumoAdmin.AddCommand("jump", {
    Description = "Make your character jump",
    Aliases     = {},
    Usage       = "jump",
    Execute     = function()
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Jump = true end
    end,
})

LumoAdmin.AddCommand("ws", {
    Description = "Get or set walk speed",
    Aliases     = { "walkspeed", "speed" },
    Usage       = "ws [speed]",
    Execute     = function(args)
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local v = tonumber(args[1])
        if v then
            hum.WalkSpeed = v
            LumoAdmin.Notify({ Title = "WalkSpeed", Message = "Set to " .. v, Type = "Success" })
        else
            LumoAdmin.Notify({ Title = "WalkSpeed", Message = "Current: " .. hum.WalkSpeed, Type = "Info" })
        end
    end,
})

LumoAdmin.AddCommand("jp", {
    Description = "Get or set jump power",
    Aliases     = { "jumppower" },
    Usage       = "jp [power]",
    Execute     = function(args)
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local v = tonumber(args[1])
        if v then
            hum.JumpPower = v
            LumoAdmin.Notify({ Title = "JumpPower", Message = "Set to " .. v, Type = "Success" })
        else
            LumoAdmin.Notify({ Title = "JumpPower", Message = "Current: " .. hum.JumpPower, Type = "Info" })
        end
    end,
})

LumoAdmin.AddCommand("rejoin", {
    Description = "Rejoin the current game",
    Aliases     = { "rj" },
    Usage       = "rejoin",
    Execute     = function()
        LumoAdmin.Notify({ Title = "Rejoin", Message = "Rejoining in 1s…", Type = "Info", Duration = 2 })
        task.delay(1, function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
    end,
})

LumoAdmin.AddCommand("ping", {
    Description = "Show your current ping in ms",
    Aliases     = {},
    Usage       = "ping",
    Execute     = function()
        local ok, ping = pcall(function()
            return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        if ok then
            LumoAdmin.Notify({ Title = "Ping", Message = ping .. " ms", Type = "Info" })
        else
            LumoAdmin.Notify({ Title = "Ping", Message = "Unable to read ping.", Type = "Warning" })
        end
    end,
})

LumoAdmin.AddCommand("freecam", {
    Description = "Toggle free-flying spectator camera",
    Aliases     = { "fc", "spectate" },
    Usage       = "freecam",
    Execute     = function()
        if fcActive then StopFreecam() else StartFreecam() end
    end,
})

LumoAdmin.AddCommand("view", {
    Description = "Follow another player's camera",
    Aliases     = { "watch" },
    Usage       = "view <player>",
    Execute     = function(args)
        if not args[1] then
            LumoAdmin.Notify({ Title = "View", Message = "Usage: view <player>", Type = "Warning" }) return
        end
        local p = FindPlayer(args[1])
        if p then ViewPlayer(p)
        else LumoAdmin.Notify({ Title = "View", Message = "Player not found.", Type = "Error" }) end
    end,
})

LumoAdmin.AddCommand("unview", {
    Description = "Stop spectating and return to own camera",
    Aliases     = { "unwatch", "unspectate" },
    Usage       = "unview",
    Execute     = function() UnviewPlayer() end,
})

LumoAdmin.AddCommand("players", {
    Description = "List all players currently in the server",
    Aliases     = { "playerlist", "plist", "who" },
    Usage       = "players",
    Execute     = function()
        local handle = LumoAdmin.CreateWindow({ Title = "Players in Server", Size = UDim2.new(0, 300, 0, 220) })
        local c      = handle.Content
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size                  = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel       = 0
        scroll.ScrollBarThickness    = 4
        scroll.ScrollBarImageColor3  = T().Accent
        scroll.CanvasSize            = UDim2.new()
        scroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
        scroll.Parent                = c
        ListLayout(scroll, 4)

        local list = Players:GetPlayers()
        table.sort(list, function(a, b) return a.Name < b.Name end)

        for i, p in ipairs(list) do
            local row = Instance.new("Frame")
            row.Size             = UDim2.new(1, 0, 0, 28)
            row.BackgroundColor3 = T().Secondary
            row.BorderSizePixel  = 0
            row.LayoutOrder      = i
            row.Parent           = scroll
            Corner(row, 6)

            Label(row, {
                Text       = (p == LocalPlayer and "★ " or "  ") .. p.Name,
                TextSize   = 12,
                TextColor3 = p == LocalPlayer and T().Accent or T().Text,
                Font       = p == LocalPlayer and Enum.Font.GothamBold or Enum.Font.Gotham,
                Size       = UDim2.new(1, -8, 1, 0),
                Position   = UDim2.new(0, 8, 0, 0),
            })
        end
    end,
})

LumoAdmin.AddCommand("pos", {
    Description = "Show your current world position",
    Aliases     = { "position", "coords", "xyz" },
    Usage       = "pos",
    Execute     = function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then LumoAdmin.Notify({ Title = "Pos", Message = "No character.", Type = "Error" }) return end
        local p = root.Position
        LumoAdmin.Notify({
            Title   = "Position",
            Message = string.format("X: %.1f   Y: %.1f   Z: %.1f", p.X, p.Y, p.Z),
            Type    = "Info",
        })
    end,
})

LumoAdmin.AddCommand("time", {
    Description = "Show game clock and local time",
    Aliases     = { "clock" },
    Usage       = "time",
    Execute     = function()
        local ct  = Lighting.ClockTime
        local h   = math.floor(ct)
        local m   = math.floor((ct - h) * 60)
        local loc = os.date("%H:%M:%S")
        LumoAdmin.Notify({
            Title   = "Time",
            Message = string.format("Game: %02d:%02d   Local: %s", h, m, loc),
            Type    = "Info",
        })
    end,
})

LumoAdmin.AddCommand("gravity", {
    Description = "Get or set workspace gravity",
    Aliases     = { "grav" },
    Usage       = "gravity [value]",
    Execute     = function(args)
        local v = tonumber(args[1])
        if v then
            workspace.Gravity = v
            LumoAdmin.Notify({ Title = "Gravity", Message = "Set to " .. v, Type = "Success" })
        else
            LumoAdmin.Notify({ Title = "Gravity", Message = "Current: " .. workspace.Gravity, Type = "Info" })
        end
    end,
})

LumoAdmin.AddCommand("fov", {
    Description = "Get or set camera field of view (1–120)",
    Aliases     = {},
    Usage       = "fov [value]",
    Execute     = function(args)
        local cam = workspace.CurrentCamera
        local v   = tonumber(args[1])
        if v then
            cam.FieldOfView = math.clamp(v, 1, 120)
            LumoAdmin.Notify({ Title = "FOV", Message = "Set to " .. cam.FieldOfView, Type = "Success" })
        else
            LumoAdmin.Notify({ Title = "FOV", Message = "Current: " .. cam.FieldOfView, Type = "Info" })
        end
    end,
})

LumoAdmin.AddCommand("char", {
    Description = "Reset / respawn your character",
    Aliases     = { "reset", "respawn" },
    Usage       = "char",
    Execute     = function()
        LocalPlayer:LoadCharacter()
        LumoAdmin.Notify({ Title = "Character", Message = "Respawned.", Type = "Info" })
    end,
})

LumoAdmin.AddCommand("invisible", {
    Description = "Toggle local character invisibility",
    Aliases     = { "invis", "vis" },
    Usage       = "invisible",
    Execute     = function()
        local char = LocalPlayer.Character
        if not char then return end
        local isInvis = char:GetAttribute("LumoInvis")
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                p.LocalTransparencyModifier = isInvis and 0 or 1
            end
        end
        char:SetAttribute("LumoInvis", not isInvis)
        LumoAdmin.Notify({
            Title   = "Invisible",
            Message = isInvis and "Visible again." or "Now invisible (local only).",
            Type    = "Info",
        })
    end,
})

LumoAdmin.AddCommand("hitbox", {
    Description = "Expand a player's hitbox (local)",
    Aliases     = { "hb" },
    Usage       = "hitbox <player> [size]",
    Execute     = function(args)
        local target = FindPlayer(args[1] or "")
        if not target then LumoAdmin.Notify({ Title = "Hitbox", Message = "Player not found.", Type = "Error" }) return end
        local char = target.Character
        if not char then return end
        local sz = tonumber(args[2]) or 10
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.Size = Vector3.new(sz, sz, sz)
            LumoAdmin.Notify({ Title = "Hitbox", Message = target.Name .. " → size " .. sz, Type = "Success" })
        end
    end,
})

LumoAdmin.AddCommand("version", {
    Description = "Show Lumo Admin version info",
    Aliases     = { "ver", "about", "info" },
    Usage       = "version",
    Execute     = function()
        LumoAdmin.Notify({
            Title    = LumoAdmin._NAME,
            Message  = "Version " .. LumoAdmin._VERSION .. "  ·  Client-side only",
            Type     = "Info",
            Duration = 5,
        })
    end,
})

-- ═══════════════════════════════════════════
--  STARTUP
-- ═══════════════════════════════════════════

task.delay(0.6, function()
    LumoAdmin.Notify({
        Title    = "Lumo Admin  v" .. LumoAdmin._VERSION,
        Message  = "Loaded. Press [ ; ] or [ Insert ] to open the command bar.",
        Type     = "Success",
        Duration = 5,
    })
end)

return LumoAdmin
