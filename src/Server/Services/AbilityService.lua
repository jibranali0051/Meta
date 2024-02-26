--[[
    AbilityService.lua
    Author: Jibran Ali
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Modules = ServerStorage:WaitForChild("Modules")
local MonsterManager = require(Modules.MonsterManager)
local Knockback = require(Modules.Effects.Knockback)

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

-- Shared
local Shared = ReplicatedStorage.Shared
local MonsterData = require(Shared.MonsterData)
local AbilityData = require(Shared.AbilityData)

local AbilityService = Knit.CreateService({
	Name = "AbilityService",
	Client = {

		EffectCreated = Knit.CreateSignal(),
		AddEffect = Knit.CreateSignal(),
		XpAdded = Knit.CreateSignal(),
		NPCAbility = Knit.CreateSignal()
	},
})

function AbilityService:KnitStart()
	-- Services
	self._monsterService = Knit.GetService("MonsterService")

	self.Client.AddEffect:Connect(function(player: Player, source, target, effectName: string, effectData: table)
		self:AddEffect(player, source, target, effectName, effectData)
	end)
end

function AbilityService:AddEffect(player, source, target, effectName, effectData)
	if effectData then
		if effectData.AbilityName then
			local info = AbilityData[effectData.AbilityName]
			if info then
				if info.Damage then
					target.Humanoid:TakeDamage(info.Damage)
					self.Client.EffectCreated:FireAll(source, target, "DamageCounter", info)
				end

				if info.Xp and player.Character == source then
					self.Client.XpAdded:Fire(player, info.Xp)
				end
			end
		end
	end
	if effectName == "Knockback" and target:GetAttribute("IsNPC") then
		Knockback(source, target)
	else
		self.Client.EffectCreated:FireAll(source, target, effectName)
	end
end

function AbilityService:DamagePlayer(player, damage)
	player.Character.Humanoid:TakeDamage(damage)
	self.Client.EffectCreated:FireAll(player, player.Character, "DamageCounter", { Damage = damage })
end

function AbilityService:KnitInit() end

function AbilityService.Client:DamagePlayer(player, damage)
	self.Server:DamagePlayer(player, damage)
end
return AbilityService
