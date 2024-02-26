-- Services
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Packages: Folder = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

-- Assets
local Assets = ReplicatedStorage.Assets
local DashTrails = Assets.DashTrails

local player = Players.LocalPlayer

local dashTime = 0.1
local dashForce = 80
local dashCooldown = 1.5

local isDashing = false
local isNPCDashing = false
local abilityName = "Dash"

function OnDashEvent(character)
	-- setting trail attachments

	local dasherRootPart = character.HumanoidRootPart

	local attachment1 = Instance.new("Attachment")
	attachment1.Position = Vector3.new(1.32, 1.33, 0.31)
	attachment1.Parent = dasherRootPart
	Debris:AddItem(attachment1, 0.5)

	local attachment2 = Instance.new("Attachment")
	attachment2.Position = Vector3.new(1.32, 0.48, 0.31)
	attachment2.Parent = dasherRootPart
	Debris:AddItem(attachment2, 0.5)

	local topRightTrail = DashTrails.DashTrail1:Clone()
	topRightTrail.Attachment0 = attachment1
	topRightTrail.Attachment1 = attachment2
	topRightTrail.Parent = dasherRootPart
	Debris:AddItem(topRightTrail, 0.5)

	local attachment3 = Instance.new("Attachment")
	attachment3.Position = Vector3.new(-1.32, 1.33, 0.31)
	attachment3.Parent = dasherRootPart
	Debris:AddItem(attachment3, 0.5)

	local attachment4 = Instance.new("Attachment")
	attachment4.Position = Vector3.new(-1.32, 0.48, 0.31)
	attachment4.Parent = dasherRootPart
	Debris:AddItem(attachment4, 0.5)

	local topLeftTrail = DashTrails.DashTrail2:Clone()
	topLeftTrail.Attachment0 = attachment3
	topLeftTrail.Attachment1 = attachment4
	topLeftTrail.Parent = dasherRootPart
	Debris:AddItem(topLeftTrail, 0.5)

	local attachment5 = Instance.new("Attachment")
	attachment5.Position = Vector3.new(-0.95, -1.36, 1.4)
	attachment5.Parent = dasherRootPart
	Debris:AddItem(attachment5, 0.50)

	local attachment6 = Instance.new("Attachment")
	attachment6.Position = Vector3.new(-0.95, -2.22, 1.4)
	attachment6.Parent = dasherRootPart
	Debris:AddItem(attachment6, 0.50)

	local bottomLeftTrail = DashTrails.DashTrail3:Clone()
	bottomLeftTrail.Attachment0 = attachment5
	bottomLeftTrail.Attachment1 = attachment6
	bottomLeftTrail.Parent = dasherRootPart
	Debris:AddItem(bottomLeftTrail, 0.5)

	local attachment7 = Instance.new("Attachment")
	attachment7.Position = Vector3.new(0.95, -1.36, 1.4)
	attachment7.Parent = dasherRootPart
	Debris:AddItem(attachment7, 0.5)

	local attachment8 = Instance.new("Attachment")
	attachment8.Position = Vector3.new(0.95, -2.22, 1.4)
	attachment8.Parent = dasherRootPart
	Debris:AddItem(attachment8, 0.5)

	local bottomRightTrail = DashTrails.DashTrail4:Clone()
	bottomRightTrail.Attachment0 = attachment7
	bottomRightTrail.Attachment1 = attachment8
	bottomRightTrail.Parent = dasherRootPart
	Debris:AddItem(bottomRightTrail, 0.5)
end

function CalculateModelMass(model)
	local mass = 0

	for i, v in pairs(model:GetDescendants()) do
		if v:IsA("Part") or v:IsA("BasePart") then
			mass += v:GetMass()
		end
	end

	return mass
end

return function(npcModel)
	local character = if npcModel then npcModel else player.Character

	Knit.GetService("AbilityService").AddEffect:Fire(character, nil, "DashHit")

	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")
	local characterMass = CalculateModelMass(character)

	local projectedVector = rootPart.CFrame:VectorToObjectSpace(game.Workspace.CurrentCamera.CFrame.LookVector)
		* Vector3.new(1, 0, 1)
	local angle = math.atan2(projectedVector.Z, projectedVector.X)
	angle = math.deg(angle)

	local goalVector = rootPart.CFrame.LookVector.Unit

	task.spawn(function()
		OnDashEvent(character)
	end)

	local antiGravity = Instance.new("BodyForce")
	antiGravity.Force = Vector3.new(0, characterMass * workspace.Gravity, 0)
	antiGravity.Name = "AntiGravity"
	antiGravity.Archivable = false
	antiGravity.Parent = rootPart

	task.spawn(function()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

		local connection = humanoid.StateChanged:Connect(function(old, new)
			if new == Enum.HumanoidStateType.FallingDown then
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end)

		task.wait(0.23)

		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		connection:Disconnect()
	end)

	task.spawn(function()
		local start = tick()

		while tick() - start < dashTime do
			rootPart.AssemblyLinearVelocity = goalVector * dashForce

			RunService.Heartbeat:Wait()
		end

		rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

		if antiGravity then
			antiGravity:Destroy()
		end
	end)
	if not npcModel then
		task.spawn(function()
			Knit.GetController("AbilityController"):StartCooldown(abilityName, dashCooldown)
		end)
	end
end
