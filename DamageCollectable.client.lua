local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local SoundManager = require(ReplicatedStorage:WaitForChild("Modules").SoundManager)

local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local gainStats = remoteEvents.CollectableEvents.GainStats
local damageCollectable = remoteEvents.CollectableEvents.DamageCollectable
local humanoidMoveTo = remoteEvents.CollectableEvents.HumanoidMoveTo

local isDestroyingCollectable = Instance.new("BoolValue")
local collectableDamaging = nil

local moveToFinished = nil

local areas = workspace:WaitForChild("Areas")

local function PlaySound(isCollectableBroken)
	local soundEffects = SoundService.SoundEffects
	local sound = nil
	if isCollectableBroken then
		sound = soundEffects.BreakCollectable
	else
		sound = soundEffects.DamageCollectable
	end
	SoundManager:Play(sound, true)
end

local function EmitParticles(collectable, particleEmitCount)
	local collectableType: string = collectable:GetAttribute("CollectableType")

	local particlesFolder = ReplicatedStorage:FindFirstChild("Particles")
	local particles = particlesFolder:FindFirstChild(collectableType .. "Particle")
	local attachment = collectable:FindFirstChild("Attachment")

	if not particles then
		warn("Particle \"" .. collectableType .. "Particle not found")
		return
	end

	particles = particles:Clone()
	particles.Parent = attachment
	particles:Emit(particleEmitCount)
end

local function GetPickUpAnimation()
	local animations = ReplicatedStorage:WaitForChild("Animations")
	local pickUpCollectableAnimation: Animation = animations:FindFirstChild("PickUpCollectable")

	local animator = humanoid:FindFirstChild("Animator")
	local animation = animator:LoadAnimation(pickUpCollectableAnimation)

	return animation
end

local function ShowCollectableBillboards(collectable)
    for _, billboard in collectable:GetDescendants() do
        if billboard:IsA("BillboardGui") then
            billboard.Enabled = true
        end
    end
end

local function HideCollectableBillboards(collectable)
    for _, billboard in collectable:GetDescendants() do
        if billboard:IsA("BillboardGui") then
            billboard.Enabled = false
        end
    end
end

-- Damaging functions
local damageConnection = nil

local function FinishCollectable(collectable)
	local collectableGrow = TweenService:Create(collectable, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = collectable.Size * 1.4,
	})
	local collectableShrink = TweenService:Create(collectable, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
		Size = Vector3.new(0, 0, 0),
	})
	
	gainStats:FireServer(collectable)
	
	-- Visual stuff
	EmitParticles(collectable, 400)
	HideCollectableBillboards(collectable)

	collectableGrow:Play()
	collectableGrow.Completed:Wait()
	--task.wait(0.2)
	collectableShrink:Play()
	
	-- We delete any* children for things like boxes and safes
	for _, child in collectable:GetChildren() do
		if child:IsA("Attachment") then continue end
		child:Destroy()
	end
	
	damageConnection:Disconnect()
end

local function DamageCollectable(collectable: MeshPart): ()
    local DAMAGE_DELAY = 1
    local animation = GetPickUpAnimation()
	local damageDebounce = false
	
	local function DealDamage()
		if damageDebounce or not damageConnection.Connected then
			return
		end

		damageDebounce = true

		local collectableHealth = collectable:GetAttribute("Health")

		-- you wont get any stats if you try modifying this value lmao
		local damage = player.PlayerStats.GingerbreadData.Damage.Value
		local newHealth = collectableHealth - damage

		local PARTICLE_EMIT_DELAY_SECONDS = 0.15

		animation:Play()
		task.wait(PARTICLE_EMIT_DELAY_SECONDS)
		EmitParticles(collectable, 200)
		damageCollectable:FireServer(collectable)

		if newHealth <= 0 then
			FinishCollectable(collectable)
			PlaySound(true)
			return
		end

		PlaySound(false)
		task.wait(DAMAGE_DELAY)
		damageDebounce = false
	end

    damageConnection = collectable:GetAttributeChangedSignal("Health"):Connect(function()
        task.wait(DAMAGE_DELAY)
        if damageConnection.Connected then
			DealDamage()
        end
	end)
	
	-- When the player stops damaging a collectable we disconnect the damage connection
    isDestroyingCollectable:GetPropertyChangedSignal("Value"):Connect(function()
        damageConnection:Disconnect()
    end)
	DealDamage()
end

local function OnPlayerMoveDisable()
	humanoid:GetPropertyChangedSignal("MoveDirection"):Once(function()
		isDestroyingCollectable.Value = false
		collectableDamaging = nil
	end)
end
local function MoveToFinished(collectable)
    isDestroyingCollectable.Value = true
    moveToFinished:Disconnect()
    DamageCollectable(collectable)
end

local function OnCollectableSpawn(collectable)
    local detector: ClickDetector = collectable:WaitForChild("ClickDetector") :: ClickDetector
    local detectClickConnection: RBXScriptConnection = nil

    detectClickConnection = detector.MouseClick:Connect(function()
        if collectableDamaging == collectable then return end
        
        ShowCollectableBillboards(collectable)
        collectableDamaging = collectable
        isDestroyingCollectable.Value = false -- Setting it to false so that they'll stop destroying anything

        -- Make sure multiple connections won't be made
        if moveToFinished then moveToFinished:Disconnect() end

		moveToFinished = humanoid.MoveToFinished:Connect(function(reached)
			if not reached then
				humanoidMoveTo:FireServer(collectable)
				return
			end
			moveToFinished:Disconnect()
            MoveToFinished(collectable)
        end)

        humanoidMoveTo:FireServer(collectable)
        OnPlayerMoveDisable()
    end)

	collectable.Destroying:Connect(function()
        detectClickConnection:Disconnect()
    end)
end

for _, area in areas:GetChildren() do
    local collectables = area:WaitForChild("Collectables")

    -- Any collectables that the server puts inside before the client loads won't be detected in ChildAdded
    for _, collectable in collectables:GetChildren() do
		task.spawn(OnCollectableSpawn, collectable)
    end

    collectables.ChildAdded:Connect(function(collectable)
		OnCollectableSpawn(collectable)
    end)
end
