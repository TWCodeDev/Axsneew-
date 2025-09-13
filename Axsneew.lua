-- AXS by Rlyy — stable build (Bring + Kill Aura)
-- Uses Fluent from releases (no 404)

-- UI Loader (keep first)
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
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "swords" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- Services / refs
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local ToolDamageObject = RemoteEvents:WaitForChild("ToolDamageObject")

----------------------------------------------------------------
-- Bring helpers (simple & reliable: teleport PrimaryPart to you)
----------------------------------------------------------------
local function tpModelToPlayer(model, offset)
    if not model or not model.Parent then return end
    local pp = model.PrimaryPart
                or model:FindFirstChild("Main")
                or (function()
                    for _, d in ipairs(model:GetDescendants()) do
                        if d:IsA("BasePart") then return d end
                    end
                end)()
    if not pp then return end
    pp.CFrame = HRP.CFrame + (offset or Vector3.new(0, 2, 0))
end

-- Bring EXACT name (teleports every matching model)
local function bringItem(name)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == name then
            tpModelToPlayer(obj, Vector3.new( math.random(-3,3), 2, math.random(-3,3) ))
        end
    end
end

-- Bring ALL from a list of names
local function bringAll(list)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and table.find(list, obj.Name) then
            tpModelToPlayer(obj, Vector3.new( math.random(-5,5), 2, math.random(-5,5) ))
        end
    end
end

--------------------------------------------------
-- Kill Aura (remote-based, the version that works)
--------------------------------------------------
local KillAuraEnabled = false
local AuraDistance = 200

local function chooseWeapon()
    -- Prefer inventory tools you actually use; expand if needed
    local inv = LocalPlayer:WaitForChild("Inventory")
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
                                -- UID style that worked: random leading + _ + userid
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

----------------
-- Main UI
----------------
Tabs.Main:AddSection("Bring (single)")

Tabs.Main:AddButton({ Title = "Bring Log",            Description = "Pulls Log(s) to you",            Callback = function() bringItem("Log") end })
Tabs.Main:AddButton({ Title = "Bring Coal",           Description = "Pulls Coal to you",              Callback = function() bringItem("Coal") end })
Tabs.Main:AddButton({ Title = "Bring Carrot",         Description = "Pulls Carrot to you",            Callback = function() bringItem("Carrot") end })
Tabs.Main:AddButton({ Title = "Bring Rifle",          Description = "Pulls Rifle to you",             Callback = function() bringItem("Rifle") end })
Tabs.Main:AddButton({ Title = "Bring Rifle Ammo",     Description = "Pulls Rifle Ammo to you",        Callback = function() bringItem("Rifle Ammo") end })
Tabs.Main:AddButton({ Title = "Bring Fuel Canister",  Description = "Pulls Fuel Canister to you",     Callback = function() bringItem("Fuel Canister") end })

Tabs.Main:AddSection("Bring (bulk)")

Tabs.Main:AddButton({
    Title = "Bring ALL (Logs/Coal/Carrots/Canisters/Ammo/Rifles)",
    Description = "Teleports all listed items to you",
    Callback = function()
        bringAll({
            "Log","Coal","Carrot","Fuel Canister",
            "Rifle","Rifle Ammo"
        })
    end
})

----------------
-- Combat UI
----------------
Tabs.Combat:AddSection("Kill Aura")

Tabs.Combat:AddToggle("KillAuraToggle", {
    Title = "Enable Kill Aura",
    Description = "Attacks nearby mobs using your weapon",
    Default = false,
    Callback = function(state)
        KillAuraEnabled = state
        if state then
            killAuraLoop()
        end
    end
})

Tabs.Combat:AddSlider("AuraDistance", {
    Title = "Kill Aura Range",
    Description = "Distance in studs",
    Default = 200,
    Min = 25,
    Max = 1000,
    Rounding = 0,
    Callback = function(val)
        AuraDistance = val
    end
})

-- Optional toast
Fluent:Notify({
    Title = "AXS Loaded",
    Content = "Bring + Kill Aura are ready.",
    Duration = 4
})
