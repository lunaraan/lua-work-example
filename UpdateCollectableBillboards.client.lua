local FormatNumberAlt = require(game:GetService("ReplicatedStorage").Modules.FormatNumberAlt)

local areas: Folder = workspace:WaitForChild("Areas")

local function UpdateProgressBillboard(collectable: MeshPart, billboard: BillboardGui)
    local collectableHealth: number = collectable:GetAttribute("Health")
    local maxHealth: number = collectable:GetAttribute("MaxHealth")

    local progress: Frame = billboard:FindFirstChild("Progress") :: Frame
    local progressXScale: number = collectableHealth / maxHealth
    local progressYScale: number = progress.Size.Y.Scale

    progress:TweenSize(UDim2.fromScale(progressXScale, progressYScale), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.125, true)
end

local function UpdateHealthBillboard(collectable: MeshPart, billboard: BillboardGui)
    local collectableHealth: number = collectable:GetAttribute("Health")

    local healthText: TextLabel = billboard:FindFirstChild("HealthText") :: TextLabel
    healthText.Text = tostring(FormatNumberAlt.FormatStandard(collectableHealth))
end

local function ChildAdded(collectable: Instance)
    local healthChangedConnection: RBXScriptConnection = nil
    
    local healthBillboardAttachment: Attachment = collectable:WaitForChild("HealthBillboardAttachment") :: Attachment
    local progressBillboardAttachment: Attachment = collectable:WaitForChild("ProgressBillboardAttachment") :: Attachment

    UpdateHealthBillboard(collectable :: MeshPart, healthBillboardAttachment:WaitForChild("BillboardGui") :: BillboardGui)

    healthChangedConnection = collectable:GetAttributeChangedSignal("Health"):Connect(function()
        UpdateProgressBillboard(collectable :: MeshPart, progressBillboardAttachment:WaitForChild("BillboardGui") :: BillboardGui)
        UpdateHealthBillboard(collectable :: MeshPart, healthBillboardAttachment:WaitForChild("BillboardGui") :: BillboardGui)
    end)

    collectable.Destroying:Connect(function()
        healthChangedConnection:Disconnect()
    end)
end

for _, area in areas:GetChildren() do
    local collectables: Folder = area:WaitForChild("Collectables")
    collectables.ChildAdded:Connect(function(collectable: Instance)
        task.spawn(ChildAdded, collectable)
    end) 
end
