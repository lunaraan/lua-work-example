local Debris = game:GetService("Debris")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Profiles = require(ServerScriptService:WaitForChild("DatastoreScripts").Profiles)

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

remoteEvents.CollectableEvents.DamageCollectable.OnServerEvent:Connect(function(player, collectable)
    local profile = Profiles.GetProfile(player)
    if not profile then return end

    local collectableHealth = collectable:GetAttribute("Health")
    local damage = profile.Data.GingerbreadData.Damage
    local newHealth = collectableHealth - damage

    collectable:SetAttribute("Health", newHealth)

    if newHealth <= 0 then
        Debris:AddItem(collectable, 1)
    end
end)
