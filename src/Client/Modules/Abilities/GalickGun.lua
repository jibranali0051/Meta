-- Services
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Packages: Folder = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local player = Players.LocalPlayer

local abilityCooldown = 2

local abilityName = "GalickGun"

return function(npcModel)
	if npcModel then
		Knit.GetService("AbilityService").AddEffect:Fire(npcModel, player.Character, "GalickGunEffect")
	else
		Knit.GetService("AbilityService").AddEffect:Fire(player.Character, nil, "GalickGunEffect")

		task.spawn(function()
			Knit.GetController("AbilityController"):StartCooldown(abilityName, abilityCooldown)
		end)
	end
end
