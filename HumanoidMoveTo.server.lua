local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

remoteEvents.CollectableEvents.HumanoidMoveTo.OnServerEvent:Connect(function(player: Player, collectable: MeshPart)
    local character: Model? = player.Character
    if character then
        local humanoid: Humanoid = character:FindFirstChild("Humanoid") :: Humanoid

        local finalPosition: Vector3 = collectable.Position
        humanoid:MoveTo(finalPosition)
    else
        warn("No character")
    end
end)
