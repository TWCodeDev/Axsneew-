-- AXS by Rlyy — Bring per-item (One / All) + Kill Aura
-- Fluent from releases (stable)
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Window
local Window = Fluent:CreateWindow({
    Title = "AXS by Rlyy",
    SubTitle = "Bring + Kill Aura",
    TabWidth = 160,
    Size = UDim2.fromOffset(560, 420),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Tabs
local Tabs = {
    Main    = Window:AddTab({ Title = "Main",    Icon = "home" }),
    Combat  = Window:AddTab({ Title = "Combat",  Icon = "swords" }),
    Settings= Window:AddTab({ Title = "Settings",Icon = "settings" })
}

-- Services / refs
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local ToolDamageObject = RemoteEvents:WaitForChild("ToolDamageObject")

-- Helpers
local function getPrimary(model)
    if not model or not model.Parent then return nil end
    if model.PrimaryPart then return model.PrimaryPart end
    local main = model:FindFirstChild("Main")
    if main and main:IsA("BasePart") then return main end
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then return d end
    end
    return nil
end

local function tpModelToPlayer(model, offset)
    local pp = getPrimary(model)
    if not pp then return end
    pp.CFrame = HRP.CFrame + (offset or Vector3.new(0, 2, 0))
end

-- Bring ONE nearest model by exact name
local function bringOne(name)
    local nearest, bestDist
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == name then
            local pp = getPrimary(obj)
            if pp then
                local dist = (pp.Position - HRP.Position).Magnitude
                if not bestDist or dist < bestDist then
                    bestDist = dist
                    nearest = obj
                end
            end
        end
    end
    if nearest then
        tpModelToPlayer(nearest, Vector3.new(0, 2, 0))
    end
end

-- Bring ALL models by exact name
local function bringAllOf(name)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == name then
            tpModelToPlayer(obj, Vector3.new(math.random(-5,5), 2, math.random(-5,5)))
        end
    end
end

-- Kill Aura (remote-based)
local KillAuraEnabled = false
local AuraDistance = 200

local function chooseWeapon()
    local inv = LocalPlayer:FindFirstChild("Inventory")
    if not inv then return nil end
    return inv:FindFirstChild("Spear")
        or inv:FindFirstChild("Old Axe")
        or inv:FindFirstChild("Good Axe")
        or inv:FindFirstChild("Strong Axe")
        or inv:FindFirstChild("Chainsaw")
end

local function killAuraLoop()
    task.spawn(function()
        while KillAuraEnabled do
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local weapon = chooseWeapon()
            if hrp and weapon then
                local charsFolder = workspace:FindFirstChild("Characters")
                if charsFolder then
                    for _, mob in ipairs(charsFolder:GetChildren()) do
                        if mob:IsA("Model") and mob.PrimaryPart then
                            local d = (mob.PrimaryPart.Position - hrp.Position).Magnitude
                            if d <= AuraDistance then
                                local uid = tostring(math.random(1,999)) .. "_" .. tostring(LocalPlayer.UserId)
                                ToolDamageObject:InvokeServer(mob, weapon, uid, hrp.CFrame)
                            end
                        end
                    end
                end
            end
            task.wait(0.15)
        end
    end)
end

-- UI — Bring (One)
Tabs.Main:AddSection("Bring (one)")
Tabs.Main:AddButton({ Title = "Bring Log",           Callback = function() bringOne("Log") end })
Tabs.Main:AddButton({ Title = "Bring Coal",          Callback = function() bringOne("Coal") end })
Tabs.Main:AddButton({ Title = "Bring Carrot",        Callback = function() bringOne("Carrot") end })
Tabs.Main:AddButton({ Title = "Bring Rifle",         Callback = function() bringOne("Rifle") end })
Tabs.Main:AddButton({ Title = "Bring Rifle Ammo",    Callback = function() bringOne("Rifle Ammo") end })

-- UI — Bring (All)
Tabs.Main:AddSection("Bring (all)")
Tabs.Main:AddButton({ Title = "Bring Log (ALL)",        Callback = function() bringAllOf("Log") end })
Tabs.Main:AddButton({ Title = "Bring Coal (ALL)",       Callback = function() bringAllOf("Coal") end })
Tabs.Main:AddButton({ Title = "Bring Carrot (ALL)",     Callback = function() bringAllOf("Carrot") end })
Tabs.Main:AddButton({ Title = "Bring Rifle (ALL)",      Callback = function() bringAllOf("Rifle") end })
Tabs.Main:AddButton({ Title = "Bring Rifle Ammo (ALL)", Callback = function() bringAllOf("Rifle Ammo") end })

-- UI — Combat
Tabs.Combat:AddSection("Kill Aura")
Tabs.Combat:AddToggle("KillAuraToggle", {
    Title = "Enable Kill Aura",
    Default = false,
    Callback = function(state)
        KillAuraEnabled = state
        if state then killAuraLoop() end
    end
})

Tabs.Combat:AddSlider("AuraDistance", {
    Title = "Kill Aura Range",
    Description = "Distance in studs",
    Default = 200,
    Min = 25,
    Max = 1000,
    Rounding = 0,
    Callback = function(val) AuraDistance = val end
})

Fluent:Notify({
    Title = "AXS Loaded",
    Content = "Per-item Bring (One/All) + Kill Aura ready.",
    Duration = 4
})
