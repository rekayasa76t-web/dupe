-- =====================================
-- NXROT MAM V1
-- BASE UI SYSTEM
-- =====================================


-- SERVICES
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer


-- =====================================
-- DATA
-- =====================================

local crystalOptions = {}
local runeOptions = {}

local selectedCrystals = {}
local selectedRunes = {}

-- AUTO COLLECT DATA

local collectEnabled = false

local collectRadius = 100

local collectDelay = 0.5

local selectedRarities = {
    Common = true
}

local collectedCount = 0



-- =====================================
-- AUTO COLLECT SYSTEM
-- =====================================


local function rarityAllowed(obj)

    local rarity = obj:GetAttribute("Rarity")

    if rarity and selectedRarities[rarity] then
        return true
    end

    return false

end



local function fireCrystalPickup(obj)

    local prompt = obj:FindFirstChildOfClass("ProximityPrompt")

    if prompt then

        fireproximityprompt(prompt)

        collectedCount += 1

    end

end



local function collectLoop()

    while task.wait(collectDelay) do


        if collectEnabled then


            local char = LocalPlayer.Character

            local root = char and char:FindFirstChild("HumanoidRootPart")


            if root then


                for _,obj in ipairs(workspace:GetDescendants()) do


                    if obj:IsA("BasePart") then


                        if rarityAllowed(obj) then


                            local distance =
                            (root.Position - obj.Position).Magnitude


                            if distance <= collectRadius then

                                fireCrystalPickup(obj)

                            end


                        end


                    end


                end


            end


        end


    end


end


task.spawn(collectLoop)

-- =====================================
-- CREATE UI
-- =====================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "nxrot mam v1"
ScreenGui.Parent = game.CoreGui


local Main = Instance.new("Frame")
Main.Parent = ScreenGui
Main.Size = UDim2.new(0,500,0,350)
Main.Position = UDim2.new(0.5,-250,0.5,-175)
Main.BackgroundColor3 = Color3.fromRGB(30,30,30)


-- TITLE

local Title = Instance.new("TextLabel")
Title.Parent = Main
Title.Size = UDim2.new(1,0,0,40)
Title.Text = "nxrot mam v1"
Title.TextColor3 = Color3.new(1,1,1)
Title.BackgroundTransparency = 1
Title.TextSize = 20



-- =====================================
-- SIDEBAR
-- =====================================

local Sidebar = Instance.new("Frame")
Sidebar.Parent = Main
Sidebar.Position = UDim2.new(0,0,0,40)
Sidebar.Size = UDim2.new(0,120,1,-40)
Sidebar.BackgroundColor3 = Color3.fromRGB(40,40,40)



-- CONTENT

local Content = Instance.new("Frame")
Content.Parent = Main
Content.Position = UDim2.new(0,120,0,40)
Content.Size = UDim2.new(1,-120,1,-40)
Content.BackgroundTransparency = 1



-- =====================================
-- PAGE SYSTEM
-- =====================================

local Pages = {}


local function CreatePage(name)

    local page = Instance.new("Frame")
    page.Parent = Content
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.Visible = false

    Pages[name] = page

end



local function SwitchPage(name)

    for _,page in pairs(Pages) do
        page.Visible = false
    end

    if Pages[name] then
        Pages[name].Visible = true
    end

end



-- =====================================
-- TAB BUTTON
-- =====================================

local function CreateTab(name)

    local btn = Instance.new("TextButton")

    btn.Parent = Sidebar
    btn.Size = UDim2.new(1,0,0,40)
    btn.Text = name
    btn.TextColor3 = Color3.new(1,1,1)
    btn.BackgroundColor3 = Color3.fromRGB(60,60,60)


    btn.MouseButton1Click:Connect(function()
        SwitchPage(name)
    end)

end



-- =====================================
-- CREATE TABS
-- =====================================

CreatePage("Dupe")
CreatePage("Scan Tas")


CreateTab("Dupe")
CreateTab("Scan Tas")



-- DEFAULT PAGE

SwitchPage("Dupe")