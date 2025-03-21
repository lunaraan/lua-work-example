local areas = workspace:WaitForChild("Areas")

local function CreateHighlight(collectable)
	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 0.15
	highlight.FillColor = Color3.fromRGB(255, 255, 255)
	highlight.OutlineColor = Color3.fromRGB(21, 21, 21)
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	
	return highlight
end

local function OnCollectableSpawn(collectable)
	local clickDetector = collectable:WaitForChild("ClickDetector")
	local hoverEnterConnection, hoverLeaveConnection
	
	hoverEnterConnection = clickDetector.MouseHoverEnter:Connect(function()
		local highlight = CreateHighlight()
		highlight.Parent = collectable
	end)
	hoverLeaveConnection = clickDetector.MouseHoverLeave:Connect(function()
		local highlight = collectable:FindFirstChild("Highlight")
		if highlight then
			highlight:Destroy()
		end
	end)

	collectable.Destroying:Connect(function()
		hoverEnterConnection:Disconnect()
		hoverLeaveConnection:Disconnect()
	end)
end

for _, area in areas:GetChildren() do
	local collectables = area:WaitForChild("Collectables")

	-- Any collectables that the server puts inside before the client loads won't be detected in ChildAdded
	for _, collectable in collectables:GetChildren() do
		task.spawn(OnCollectableSpawn, collectable)
	end

	collectables.ChildAdded:Connect(OnCollectableSpawn)
end
