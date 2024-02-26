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
local vfx = Assets.VFX.GalickGun
local MonstersFolder = workspace:WaitForChild("Monsters")
local NPCFolder = workspace:WaitForChild("NPCs")

-- Modules
local Modules = StarterPlayerScripts.Modules
local Utility = Modules.Utility
local HitBox = require(Utility.HitBox)

local player = Players.LocalPlayer

local effectDuration = 1.2
local effectForce = 80

local effectName = "GalickGunEffect"

return function(source, potentialTarget)
	local character = source
	local rootPart = character:WaitForChild("HumanoidRootPart")
	local effect = vfx:Clone()
	local connection = nil
	local isHitting = false
	effect.CFrame = (rootPart.CFrame + rootPart.CFrame.LookVector * 6) * CFrame.Angles(0, math.rad(90), 0)
	effect.Parent = character
	rootPart.Anchored = true
	character.Humanoid.WalkSpeed = 0

	local function EnableEffects(part)
		for _, particleEffect in pairs(part:GetChildren()) do
			if particleEffect:IsA("ParticleEmitter") then
				particleEffect.Enabled = true
				task.wait(0.01)
			end
			if particleEffect:IsA("Beam") then
				particleEffect.Enabled = true
			end
		end
	end

	EnableEffects(effect.Start)
	task.wait(0.4)
	EnableEffects(effect.Beams)
	task.delay(0.1, function()
		EnableEffects(effect.End)
	end)

	print(source:GetAttribute("IsNPC"))
	print(potentialTarget)

	if
		source == player.Character
		or (source:GetAttribute("IsNPC") and potentialTarget == player.Character)
	then
		local projectileData = {}

		projectileData["Start"] = rootPart.Position
		projectileData["Direction"] = rootPart.CFrame.LookVector
		projectileData["Velocity"] = effectForce
		projectileData["Lifetime"] = effectDuration
		projectileData["Iterations"] = 1
		projectileData["Visualize"] = false
		projectileData["Points"] =
			HitBox:GetSquarePoints(CFrame.new((rootPart.CFrame * CFrame.new(0, 1, 1)).p, effect.CFrame.p), 5, 5)

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
		projectileData["WhiteList"] = WhiteList
		projectileData["Callback"] = function(result)
			if result.Instance and result.Instance.Parent then
				local enemyHumanoid = result.Instance:FindFirstAncestorOfClass("Model"):FindFirstChild("Humanoid")
				local enemyRootPart =
					result.Instance:FindFirstAncestorOfClass("Model"):FindFirstChild("HumanoidRootPart")
				if not enemyHumanoid or not enemyRootPart then
					return
				end
				local enemyCharacter = enemyHumanoid.Parent
				if not enemyCharacter then
					return
				end

				if enemyRootPart and enemyHumanoid then
					local data = {}
					data["AbilityName"] = "GalickGun"

					Knit.GetService("AbilityService").AddEffect:Fire(source, enemyCharacter, "Knockback", data)
				end
			end
		end

		HitBox:CastProjectileHitbox(projectileData)

		task.delay(effectDuration, function()
			if not source:GetAttribute("IsNPC") then
				Knit.GetController("AbilityController"):AbilityEnded()
			end
		end)
	end

	local function onStepped(time, deltaTime)
		if effect then
			effect.CFrame = (rootPart.CFrame + rootPart.CFrame.LookVector * 6) * CFrame.Angles(0, math.rad(90), 0)
		else
			connection:Disconnect()
		end
	end

	connection = RunService.Stepped:Connect(onStepped)
	task.delay(effectDuration, function()
		rootPart.Anchored = false
		character.Humanoid.WalkSpeed = 16
	end)
	Debris:AddItem(effect, effectDuration)
	task.delay(effectDuration, function()
		connection:Disconnect()
	end)
end
