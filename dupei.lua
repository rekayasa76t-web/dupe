-- NXROT COLLECT ONLY
-- Fitur yang tersisa:
-- 1. Auto Collect Crystal
-- 2. Auto Collect Rune
-- 3. Reset Character

local __NXROTEnv = (type(getgenv)=="function" and getgenv()) or _G
if __NXROTEnv.__NXROTCollectOnlyActive then return end
__NXROTEnv.__NXROTCollectOnlyActive = true

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local DEV_MODE = (rawget(_G, "__dhub_dev") ~= nil) or false

local function resolveGuiRoot()
    local ok, h = pcall(function() return gethui() end)
    if ok and typeof(h) == "Instance" then return h end
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if pg then return pg end
    return LocalPlayer:WaitForChild("PlayerGui", 10) or CoreGui
end

local GuiRoot = resolveGuiRoot()

local function Notify(text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "NXROT",
            Text = tostring(text),
            Duration = duration or 3
        })
    end)
end

local function validateStartupKey()
    if DEV_MODE then return true end
    local env = (type(getgenv)=="function" and getgenv()) or _G
    local key = nil
    pcall(function() key = env.key end)
    if key == nil then pcall(function() key = _G.key end) end
    key = tostring(key or ""):match("^%s*(.-)%s*$") or ""
    return key == "NXROT"
end

if not validateStartupKey() then
    Notify("Wrong Key", 2)
    task.wait(1)
    pcall(function() LocalPlayer:Kick("NXROT | Wrong Key") end)
    return
end

local function Corner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius or 6)
end

local function Stroke(parent, color, thickness)
    local s = Instance.new("UIStroke", parent)
    s.Color = color
    s.Thickness = thickness or 1
    return s
end

local function MakeDraggable(frame, handle)
    local drag, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            drag = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    drag = false
                end
            end)
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if drag and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function MakeSection(C, parent, text)
    local label = Instance.new("TextLabel", parent)
    label.Size = UDim2.new(1,0,0,20)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = C.TEXT_2
    label.Text = text:upper()
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
end

local function MakeToggle(C, parent, label, defaultState)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,0,0,42)
    row.BackgroundColor3 = C.SURFACE
    Corner(row, 6)
    local rowStroke = Stroke(row, C.BORDER)

    local accent = Instance.new("Frame", row)
    accent.Size = UDim2.new(0,2,0,18)
    accent.Position = UDim2.new(0,0,0.5,-9)
    accent.BackgroundColor3 = C.BORDER
    Corner(accent, 1)

    local labelText = Instance.new("TextLabel", row)
    labelText.Size = UDim2.new(1,-70,1,0)
    labelText.Position = UDim2.new(0,14,0,0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.TextColor3 = C.TEXT_2
    labelText.Font = Enum.Font.GothamMedium
    labelText.TextSize = 12
    labelText.TextXAlignment = Enum.TextXAlignment.Left

    local pill = Instance.new("Frame", row)
    pill.Size = UDim2.new(0,38,0,20)
    pill.Position = UDim2.new(1,-50,0.5,-10)
    pill.BackgroundColor3 = C.DIVIDER
    Corner(pill, 10)

    local dot = Instance.new("Frame", pill)
    dot.Size = UDim2.new(0,14,0,14)
    dot.Position = UDim2.new(0,3,0.5,-7)
    dot.BackgroundColor3 = C.TEXT_3
    Corner(dot, 7)

    local button = Instance.new("TextButton", row)
    button.Size = UDim2.new(1,0,1,0)
    button.BackgroundTransparency = 1
    button.Text = ""

    local function setState(on, tween)
        local pos = on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)
        local bg = on and C.ELEVATED or C.SURFACE
        local pillBg = on and C.ACCENT_D or C.DIVIDER
        local textColor = on and C.TEXT_1 or C.TEXT_2

        row.BackgroundColor3 = bg
        rowStroke.Color = on and C.ACCENT_D or C.BORDER
        labelText.TextColor3 = textColor
        accent.BackgroundColor3 = on and C.ACCENT or C.BORDER

        if tween then
            TweenService:Create(pill,TweenInfo.new(0.2),{BackgroundColor3=pillBg}):Play()
            TweenService:Create(dot,TweenInfo.new(0.2),{
                Position=pos,
                BackgroundColor3=on and C.ACCENT or C.TEXT_3
            }):Play()
        else
            pill.BackgroundColor3 = pillBg
            dot.Position = pos
            dot.BackgroundColor3 = on and C.ACCENT or C.TEXT_3
        end
    end

    setState(defaultState == true, false)
    return button, setState
end

local function MakeButton(C, parent, label)
    local row = Instance.new("TextButton", parent)
    row.Size = UDim2.new(1,0,0,36)
    row.BackgroundColor3 = C.SURFACE
    row.Text = ""
    row.AutoButtonColor = false
    Corner(row, 6)
    Stroke(row, C.BORDER)

    local accent = Instance.new("Frame", row)
    accent.Size = UDim2.new(0,2,0,18)
    accent.Position = UDim2.new(0,0,0.5,-9)
    accent.BackgroundColor3 = C.BORDER
    Corner(accent, 1)

    local text = Instance.new("TextLabel", row)
    text.Size = UDim2.new(1,-20,1,0)
    text.Position = UDim2.new(0,14,0,0)
    text.BackgroundTransparency = 1
    text.Text = label
    text.TextColor3 = C.TEXT_1
    text.Font = Enum.Font.GothamMedium
    text.TextSize = 12
    text.TextXAlignment = Enum.TextXAlignment.Left

    return row
end

local function MakePage(UI, name)
    local page = Instance.new("ScrollingFrame", UI.ContentArea)
    page.Name = name
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = UI.C.DIVIDER
    page.Visible = false

    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0,8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local padding = Instance.new("UIPadding", page)
    padding.PaddingTop = UDim.new(0,15)
    padding.PaddingBottom = UDim.new(0,15)
    padding.PaddingLeft = UDim.new(0,15)
    padding.PaddingRight = UDim.new(0,15)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+30)
    end)

    UI.Pages[name] = page
    return page
end

local function MakeNavButton(UI, name)
    local btn = Instance.new("TextButton", UI.TabContainer)
    btn.Size = UDim2.new(1,-16,0,36)
    btn.BackgroundColor3 = UI.C.SURFACE
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    Corner(btn, 6)

    local indicator = Instance.new("Frame", btn)
    indicator.Size = UDim2.new(0,3,0,18)
    indicator.Position = UDim2.new(0,0,0.5,-9)
    indicator.BackgroundColor3 = UI.C.ACCENT
    indicator.BorderSizePixel = 0
    indicator.BackgroundTransparency = 1
    Corner(indicator, 2)

    local label = Instance.new("TextLabel", btn)
    label.Size = UDim2.new(1,-16,1,0)
    label.Position = UDim2.new(0,12,0,0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = UI.C.TEXT_2
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left

    btn.MouseButton1Click:Connect(function()
        for n,page in pairs(UI.Pages) do page.Visible = (n == name) end
        for n,data in pairs(UI.NavButtons) do
            local active = (n == name)
            data.Indicator.BackgroundTransparency = active and 0 or 1
            data.Label.TextColor3 = active and UI.C.TEXT_1 or UI.C.TEXT_2
            data.Btn.BackgroundColor3 = active and UI.C.ELEVATED or UI.C.SURFACE
        end
    end)

    UI.NavButtons[name] = {
        Btn = btn,
        Indicator = indicator,
        Label = label
    }
end

local function InitializeUI()
    local C = {
        BASE=Color3.fromRGB(13,8,32),
        SURFACE=Color3.fromRGB(22,14,46),
        ELEVATED=Color3.fromRGB(33,22,66),
        BORDER=Color3.fromRGB(74,45,128),
        DIVIDER=Color3.fromRGB(30,18,58),
        TEXT_1=Color3.fromRGB(237,232,255),
        TEXT_2=Color3.fromRGB(184,159,232),
        TEXT_3=Color3.fromRGB(112,85,168),
        ACCENT=Color3.fromRGB(0,170,255),
        ACCENT_D=Color3.fromRGB(0,105,190),
        DANGER=Color3.fromRGB(196,94,138)
    }

    local MainSG = Instance.new("ScreenGui", GuiRoot)
    MainSG.Name = "NXROT_CollectOnly"
    MainSG.ResetOnSpawn = false

    local UI = {
        C=C,
        MainSG=MainSG,
        Pages={},
        NavButtons={}
    }

    local root = Instance.new("Frame", MainSG)
    root.Size = UDim2.new(0,520,0,400)
    root.Position = UDim2.new(0.5,-260,0.5,-200)
    root.BackgroundTransparency = 1

    local minimized = Instance.new("TextButton", root)
    minimized.Size = UDim2.new(0,52,0,52)
    minimized.BackgroundColor3 = C.SURFACE
    minimized.BorderSizePixel = 0
    minimized.Text = "▯"
    minimized.TextColor3 = C.ACCENT
    minimized.Font = Enum.Font.GothamBold
    minimized.TextSize = 32
    minimized.Visible = false
    minimized.AutoButtonColor = false
    Corner(minimized,10)
    Stroke(minimized,C.BORDER)
    MakeDraggable(root,minimized)

    local win = Instance.new("Frame", root)
    win.Size = UDim2.new(1,0,1,0)
    win.BackgroundColor3 = C.BASE
    win.ClipsDescendants = true
    Corner(win,8)
    Stroke(win,C.BORDER)

    local header = Instance.new("Frame", win)
    header.Size = UDim2.new(1,0,0,45)
    header.BackgroundColor3 = C.SURFACE
    Corner(header,8)

    local icon = Instance.new("ImageLabel", header)
    icon.Size = UDim2.new(0,30,0,30)
    icon.Position = UDim2.new(0,8,0.5,-15)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://90635907660208"
    Corner(icon,8)

    local title = Instance.new("TextLabel", header)
    title.Size = UDim2.new(1,-100,1,0)
    title.Position = UDim2.new(0,46,0,0)
    title.BackgroundTransparency = 1
    title.Text = "NXROT: COLLECT ONLY"
    title.TextColor3 = C.TEXT_1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    MakeDraggable(root,header)

    local minBtn = Instance.new("TextButton", header)
    minBtn.Size = UDim2.new(0,24,0,24)
    minBtn.Position = UDim2.new(1,-34,0.5,-12)
    minBtn.BackgroundColor3 = C.SURFACE
    minBtn.BorderSizePixel = 0
    minBtn.Text = "—"
    minBtn.TextColor3 = C.TEXT_2
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 14
    minBtn.AutoButtonColor = false
    Corner(minBtn,4)

    minBtn.MouseButton1Click:Connect(function()
        win.Visible = false
        minimized.Visible = true
        root.Size = UDim2.new(0,52,0,52)
    end)

    minimized.MouseButton1Click:Connect(function()
        win.Visible = true
        minimized.Visible = false
        root.Size = UDim2.new(0,520,0,400)
    end)

    local body = Instance.new("Frame", win)
    body.Size = UDim2.new(1,0,1,-45)
    body.Position = UDim2.new(0,0,0,45)
    body.BackgroundTransparency = 1

    local sidebar = Instance.new("Frame", body)
    sidebar.Size = UDim2.new(0,80,1,0)
    sidebar.BackgroundColor3 = C.SURFACE
    sidebar.BorderSizePixel = 0

    local tabs = Instance.new("ScrollingFrame", sidebar)
    tabs.Size = UDim2.new(1,0,1,0)
    tabs.BackgroundTransparency = 1
    tabs.BorderSizePixel = 0
    tabs.ScrollBarThickness = 2

    local tabLayout = Instance.new("UIListLayout", tabs)
    tabLayout.Padding = UDim.new(0,5)
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Instance.new("UIPadding",tabs).PaddingTop = UDim.new(0,10)

    local content = Instance.new("Frame", body)
    content.Size = UDim2.new(1,-80,1,0)
    content.Position = UDim2.new(0,80,0,0)
    content.BackgroundTransparency = 1

    UI.ContentArea = content
    UI.TabContainer = tabs

    MakeNavButton(UI,"Collect")
    local page = MakePage(UI,"Collect")

    MakeSection(C,page,"Auto Collect")

    -- Auto Collect Crystal
    local autoCrystal = false
    local crystalBusy = false
    local collectRadius = 100

    local CrystalBtn,CrystalSet = MakeToggle(C,page,"Auto Collect Crystal",false)
    CrystalBtn.MouseButton1Click:Connect(function()
        autoCrystal = not autoCrystal
        CrystalSet(autoCrystal,true)
    end)

    local function crystalRarityAllowed(child)
        return true
    end

    local function isCrystal(child)
        if not child or not child:IsA("BasePart") then return false end
        return child:GetAttribute("Value") ~= nil
            and (child:GetAttribute("CrystalName") ~= nil
            or child:GetAttribute("Tier") ~= nil)
    end

    local function pickupCrystal(part)
        local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        local hold = remotes and remotes:FindFirstChild("CrystalHoldComplete")

        if hold then
            pcall(function() hold:FireServer(part) end)
        end

        local prompt = part:FindFirstChildWhichIsA("ProximityPrompt",true)
        if prompt then
            pcall(function()
                prompt.HoldDuration = 0
                prompt.RequiresLineOfSight = false
                prompt.Enabled = true
                prompt.MaxActivationDistance = 9999
            end)

            if typeof(fireproximityprompt)=="function" then
                pcall(function() fireproximityprompt(prompt,1) end)
                pcall(function() fireproximityprompt(prompt,0) end)
            else
                pcall(function()
                    prompt:InputHoldBegin()
                    prompt:InputHoldEnd()
                end)
            end
        end

        local detector = part:FindFirstChildWhichIsA("ClickDetector",true)
        if detector and typeof(fireclickdetector)=="function" then
            pcall(function() fireclickdetector(detector,0) end)
        end
    end

    task.spawn(function()
        while task.wait(0.25) do
            if not autoCrystal or crystalBusy then continue end
            crystalBusy = true

            pcall(function()
                local char = LocalPlayer.Character
                local rootPart = char and char:FindFirstChild("HumanoidRootPart")
                if not rootPart then return end

                local containers = {workspace}
                local dropped = workspace:FindFirstChild("DroppedCrystals")
                    or workspace:FindFirstChild("Crystals")
                if dropped then table.insert(containers,dropped) end

                local things = workspace:FindFirstChild("Things")
                if things then
                    local dc = things:FindFirstChild("DroppedCrystals")
                        or things:FindFirstChild("Crystals")
                    if dc then table.insert(containers,dc) end
                end

                for _,container in ipairs(containers) do
                    for _,child in ipairs(container:GetChildren()) do
                        if not autoCrystal then break end
                        if not isCrystal(child) then continue end
                        if child:GetAttribute("Collected") == true then continue end
                        if not crystalRarityAllowed(child) then continue end

                        local distance = (child.Position-rootPart.Position).Magnitude
                        if distance > collectRadius then continue end

                        rootPart.CFrame = CFrame.new(child.Position + Vector3.new(0,3,0))
                        task.wait(0.05)
                        pickupCrystal(child)
                        task.wait(0.1)
                    end
                end
            end)

            crystalBusy = false
        end
    end)

    -- Auto Collect Rune
    local autoRune = false
    local runeBusy = false

    local RuneBtn,RuneSet = MakeToggle(C,page,"Auto Collect Rune",false)
    RuneBtn.MouseButton1Click:Connect(function()
        autoRune = not autoRune
        RuneSet(autoRune,true)
    end)

    local function isRuneObject(inst)
        if not inst then return false end
        if inst:GetAttribute("RuneId") ~= nil
        or inst:GetAttribute("RuneName") ~= nil
        or inst:GetAttribute("IsRune") == true then
            return true
        end
        return inst.Name:find(" Rune",1,true) ~= nil
    end

    local function runePart(inst)
        if inst:IsA("BasePart") then return inst end
        if inst:IsA("Model") then
            return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart",true)
        end
        return nil
    end

    local function findRunePrompt(inst,part)
        local prompt = inst:FindFirstChildOfClass("ProximityPrompt")
        if not prompt then prompt=inst:FindFirstChildWhichIsA("ProximityPrompt",true) end
        if not prompt and part and part~=inst then
            prompt=part:FindFirstChildWhichIsA("ProximityPrompt",true)
        end
        return prompt
    end

    local function collectRunePrompt(prompt)
        if not prompt or not prompt.Parent then return false end

        local old = {
            hold=prompt.HoldDuration,
            sight=prompt.RequiresLineOfSight,
            enabled=prompt.Enabled,
            range=prompt.MaxActivationDistance
        }

        pcall(function()
            prompt.HoldDuration=0
            prompt.RequiresLineOfSight=false
            prompt.Enabled=true
            prompt.MaxActivationDistance=1000
        end)

        local ok=false
        if typeof(fireproximityprompt)=="function" then
            ok=pcall(fireproximityprompt,prompt)
        end
        if not ok then
            ok=pcall(function()
                prompt:InputHoldBegin()
                prompt:InputHoldEnd()
            end)
        end

        task.delay(0.25,function()
            if prompt and prompt.Parent then
                pcall(function()
                    prompt.HoldDuration=old.hold
                    prompt.RequiresLineOfSight=old.sight
                    prompt.Enabled=old.enabled
                    prompt.MaxActivationDistance=old.range
                end)
            end
        end)

        return ok
    end

    local function collectNearbyRunes(radius)
        local char=LocalPlayer.Character
        local rootPart=char and char:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        local seen={}
        local folder=workspace:FindFirstChild("DroppedRunes")
        local candidates=folder and folder:GetChildren() or {}

        for _,part in ipairs(workspace:GetPartBoundsInRadius(rootPart.Position,radius)) do
            candidates[#candidates+1]=part
        end

        for _,obj in ipairs(candidates) do
            local owner=obj
            if not isRuneObject(owner) and owner.Parent and isRuneObject(owner.Parent) then
                owner=owner.Parent
            end

            if not seen[owner] then
                local part=runePart(owner) or (obj:IsA("BasePart") and obj)
                if part and (part.Position-rootPart.Position).Magnitude<=radius then
                    local prompt=findRunePrompt(owner,part)
                    if prompt then collectRunePrompt(prompt) end
                end
                seen[owner]=true
            end
        end
    end

    task.spawn(function()
        while task.wait(0.15) do
            if autoRune and not runeBusy then
                runeBusy=true
                pcall(collectNearbyRunes,90)
                runeBusy=false
            end
        end
    end)

    -- Reset Character
    MakeSection(C,page,"Character")

    local resetBtn=MakeButton(C,page,"⟳ Reset Character")
    resetBtn.MouseButton1Click:Connect(function()
        local char=LocalPlayer.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum.Health=0 end) end
    end)

    UI.Pages["Collect"].Visible=true
    UI.NavButtons["Collect"].Indicator.BackgroundTransparency=0
    UI.NavButtons["Collect"].Label.TextColor3=C.TEXT_1
    UI.NavButtons["Collect"].Btn.BackgroundColor3=C.ELEVATED
end

InitializeUI()
