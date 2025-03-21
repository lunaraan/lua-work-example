local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shop = require(ReplicatedStorage:WaitForChild("Modules").Shop)
local Multipliers = require(ReplicatedStorage:WaitForChild("Modules").Multipliers)
local AreasConfig = require(ServerScriptService:WaitForChild("Configs").AreasConfig)
local Profiles = require(ServerScriptService:WaitForChild("DatastoreScripts").Profiles)

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

remoteEvents.CollectableEvents.GainStats.OnServerEvent:Connect(function(player, collectable)
    -- In case the player is cheating we won't give them their stats
    local profile = Profiles.GetProfile(player)
    local collectableHealth = collectable:GetAttribute("Health")
    if collectableHealth > 0 or not profile then return end

    local pileType = collectable:GetAttribute("PileType")
    local collectableType = collectable:GetAttribute("CollectableType")
    local area = collectable:GetAttribute("Area")
    local collectableGains = AreasConfig[area].CollectableGains[pileType]

    if collectableGains == nil then
        warn("No collectable type gain for type \"" .. pileType .. "\"")
        return
    end

    local gain = math.random(collectableGains.Min, collectableGains.Max)
    local hasX2CandyCanes = (collectableType == "CandyCanes" and Shop.DoesUserOwnPass(player, Shop.PassIds.X2CandyCanes))
    local hasX2Snowflakes = (collectableType == "Snowflakes" and Shop.DoesUserOwnPass(player, Shop.PassIds.X2Snowflakes))
    local multiplier = if hasX2CandyCanes or hasX2Snowflakes then 2 else 1

    if collectableType == "CandyCanes" then
        multiplier += Multipliers.GetCandyCanesMultiplier(player)
    else
        multiplier += Multipliers.GetSnowflakesMultiplier(player)
    end

    profile.Data[collectableType] += math.round(gain * multiplier)
    profile.Data["Total" .. collectableType] += math.round(gain * multiplier)
    Profiles:UpdateStats(player)
end)
