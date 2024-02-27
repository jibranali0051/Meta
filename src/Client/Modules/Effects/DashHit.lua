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
local vfx = Assets.VFX.DashHit
local NPCFolder = workspace:WaitForChild("NPCs")

-- Modules
local Modules = StarterPlayerScripts.Modules
local Utility = Modules.Utility
local HitBox = require(Utility.HitBox)

local player = Players.LocalPlayer

local effectDuration = 0.2
local effectForce = 60
local damage = 10

local effectName = "DashHit"

return function(source, potentialTarget)
	local character = source
	local rootPart = character:WaitForChild("HumanoidRootPart")
	local effect = vfx:Clone()
	local connection = nil
	local isHitting = false
	effect.Position = rootPart.CFrame.Position + rootPart.CFrame.LookVector * 5
	effect.Parent = character

	if
		source == player.Character
		or (source:GetAttribute("IsNPC") and Players:GetPlayerFromCharacter(potentialTarget) == player)
	then
		local alreadyHit = {}
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
		for _, player in pairs(Players:GetPlayers()) do
			if player.Character ~= character then
				table.insert(WhiteList, player.Character)
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
					data["AbilityName"] = "Dash"

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
			effect.Position = rootPart.CFrame.Position + rootPart.CFrame.LookVector * 5
		else
			connection:Disconnect()
		end
	end

	connection = RunService.Stepped:Connect(onStepped)
	Debris:AddItem(effect, effectDuration)
	task.delay(effectDuration, function()
		connection:Disconnect()
	end)
end
