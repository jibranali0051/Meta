-- Services
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Packages: Folder = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local player = Players.LocalPlayer

local abilityCooldown = 3

local isAbilityCooldown = false
local isNPCAbilityCooldown = false
local abilityName = "ThunderBall"

return function(npcModel)
	if npcModel then
		Knit.GetService("AbilityService").AddEffect:Fire(npcModel, player.Character, "ThunderBallEffect")
	else
		Knit.GetService("AbilityService").AddEffect:Fire(player.Character, nil, "ThunderBallEffect")

		task.spawn(function()
			Knit.GetController("AbilityController"):StartCooldown(abilityName, abilityCooldown)
		end)
	end
end
