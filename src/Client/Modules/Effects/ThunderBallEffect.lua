-- Services
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts

-- Packages
local Packages: Folder = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

-- Assets
local Assets = ReplicatedStorage.Assets
local vfx = Assets.VFX.ThunderBall
local MonstersFolder = workspace:WaitForChild("Monsters")
local NPCFolder = workspace:WaitForChild("NPCs")

-- Modules
local Modules = StarterPlayerScripts.Modules
local Utility = Modules.Utility
local HitBox = require(Utility.HitBox)

local player = Players.LocalPlayer

local effectDuration = 1.5
local effectForce = 80
local speed = 1

-- consts
local DETECTION_DISTANCE = 4

local effectName = "GalickGunEffect"

return function(source, potentialTarget)
	local character = source
	local rootPart = character:WaitForChild("HumanoidRootPart")
	local effect = vfx:Clone()
	local connection = nil
	local effectUsed = false
	local overlapParams = OverlapParams.new()
	local data = {}
	data["AbilityName"] = "GalickGun"

	effect.CFrame = (rootPart.CFrame + rootPart.CFrame.LookVector * 6)
	effect.Parent = character
	task.wait(0.2)

	if
		source == player.Character
		or (source:GetAttribute("IsNPC") and Players:GetPlayerFromCharacter(potentialTarget) == player)
	then
		local WhiteList = {}
		for _, monster in pairs(MonstersFolder:GetChildren()) do
			if monster ~= character then
				table.insert(WhiteList, monster)
			end
		end
		for _, npc in pairs(NPCFolder:GetChildren()) do
			if npc ~= character then
				table.insert(WhiteList, npc)
			end
		end

		overlapParams.FilterType = Enum.RaycastFilterType.Whitelist
		overlapParams.MaxParts = 10

		if source:GetAttribute("IsNPC") then
			overlapParams.FilterDescendantsInstances = { potentialTarget }
		else
			overlapParams.FilterDescendantsInstances = WhiteList
		end

		task.delay(effectDuration, function()
			if not source:GetAttribute("IsNPC") then
				Knit.GetController("AbilityController"):AbilityEnded()
			end
		end)
	end

	local function onStepped(time, deltaTime)
		if effect and not effectUsed then
			effect.CFrame = (effect.CFrame + effect.CFrame.LookVector * speed)
			if
				source == player.Character
				or (source:GetAttribute("IsNPC") and Players:GetPlayerFromCharacter(potentialTarget) == player)
			then
				local parts = workspace:GetPartBoundsInRadius(effect.Position, DETECTION_DISTANCE, overlapParams)
				if #parts > 1 then
					effectUsed = true
					local model = parts[1]:FindFirstAncestorOfClass("Model")
					effect:Destroy()
					Knit.GetService("AbilityService").AddEffect:Fire(source, model, "ToonBlast")
					Knit.GetService("AbilityService").AddEffect:Fire(source, model, "Knockback", data)
				end
			end
		else
			connection:Disconnect()
		end
	end

	connection = RunService.Stepped:Connect(onStepped)
	task.delay(effectDuration, function()
		connection:Disconnect()
	end)
	Debris:AddItem(effect, effectDuration)
end
