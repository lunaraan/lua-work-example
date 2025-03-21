local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ClientTween = require(ServerScriptService:WaitForChild("Modules").ClientTween)
local AreasConfig = require(ServerScriptService:WaitForChild("Configs").AreasConfig)

local areasFolder = workspace:WaitForChild("Areas")

local function ChooseCollectable(area)
    local isSnowflake = if math.random(1, 3) == 2 then true else false
    local collectableType = if isSnowflake then "Snowflakes" else "CandyCanes"

    local collectables = ReplicatedStorage.Collectables[collectableType]:GetChildren()
    local collectable = collectables[math.random(1, #collectables)]:Clone()
    local pileType = collectable.Name

    local collectableHealths = AreasConfig[area.Name].CollectableHealths[pileType]
    local health = collectableHealths[math.random(1, #collectableHealths)]

    collectable:SetAttribute("Area", area.Name)
    collectable:SetAttribute("CollectableType", collectableType)
    collectable:SetAttribute("Health", health)
    collectable:SetAttribute("MaxHealth", health)
    collectable:SetAttribute("PileType", pileType)
    collectable.Name = "Collectable" -- This is so hackers can not damage a specific collectable

    return collectable
end

local function CanUsePosition(position, size)
    local partsInBounds = workspace:GetPartBoundsInBox(position, size)
    for _, part in partsInBounds do
        if part.Name == "Collectable" then
            return false
        end
    end
    return true
end

local function ChoosePosition(collectableSpawnArea, collectable)
    local random = Random.new()

    -- Get the total area of the spawn area
    local minX = collectableSpawnArea.Position.X + (collectableSpawnArea.Size.X / 2)
    local maxX = collectableSpawnArea.Position.X - (collectableSpawnArea.Size.X / 2)

    local minZ = collectableSpawnArea.Position.Z + (collectableSpawnArea.Size.Z / 2)
    local maxZ = collectableSpawnArea.Position.Z - (collectableSpawnArea.Size.Z / 2)

    local positionX = random:NextNumber(minX, maxX)
    local positionZ = random:NextNumber(minZ, maxZ)

    local position = CFrame.new(positionX, collectable.Position.Y, positionZ)
    return position
end

local function SpawnCollectables(area)
    local MAX_COLLECTABLES_IN_AREA = 60
    local collectables = #area.Collectables:GetChildren()
    if collectables >= MAX_COLLECTABLES_IN_AREA then return end

    local random = Random.new()
    local collectablesToSpawn = math.random(15, 40)
    local collectableSpawnArea = area.CollectableSpawnArea

    for i = 1, collectablesToSpawn do
        task.spawn(function()
            local collectable = ChooseCollectable(area)

            local yRotation = random:NextNumber(-360, 360)
            local rotation = CFrame.Angles(0, math.rad(yRotation), 0)
            local chosenCframe = ChoosePosition(collectableSpawnArea, collectable)
            local collectableSize = collectable.Size

            while not CanUsePosition(chosenCframe, collectableSize) do
                chosenCframe = ChoosePosition(collectableSpawnArea, collectable)
                task.wait()
            end

            chosenCframe *= rotation

            local tweenUp = ClientTween.New(collectable, TweenInfo.new(1.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
                CFrame = chosenCframe
            })
            local tweenDown = ClientTween.New(collectable, TweenInfo.new(0, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                CFrame = chosenCframe + Vector3.new(0, 50, 0)
            })

            collectable.Transparency = 1
            collectable.Parent = area.Collectables
            collectable.CFrame = chosenCframe
            task.wait()
            tweenDown:Play():Await()
            collectable.Transparency = 0
            tweenUp:Play()
        end)
        task.wait(random:NextNumber(0.02, 0.2))
    end
end

task.wait(10)
while true do
    for _, area in areasFolder:GetChildren() do
        task.spawn(SpawnCollectables, area)
    end
    task.wait(math.random(20, 40))
end
