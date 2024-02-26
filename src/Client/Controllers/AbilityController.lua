--[[
    AbilityController.lua
    Author(s): Jibran

    Description: Manages Abilities
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts
local ContextActionService = game:GetService("ContextActionService")

-- Modules
local Modules = StarterPlayerScripts.Modules
local Abilties = Modules.Abilities
local Effects = Modules.Effects

-- Packages
local Packages: Folder = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

-- Shared
local Shared = ReplicatedStorage.Shared
local MonsterData = require(Shared.MonsterData)
local AbilityData = require(Shared.AbilityData)

-- Tables
local keyBinds = {
	[1] = "E",
	[2] = "R",
	[3] = "T",
	[4] = "Y",
}

-- Player
local Player = Knit.Player

-- Knit
local AbilityController = Knit.CreateController({
	Name = "AbilityController",
})

function AbilityController:KnitStart()
	self._abilityModules = {}
	self._effectModules = {}
	self._abilityLocked = {}
	self._abilityInPogress = false

	for _, abilityModule in pairs(Abilties:GetChildren()) do
		self._abilityModules[abilityModule.Name] = require(abilityModule)
	end

	for _, effectModule in pairs(Effects:GetChildren()) do
		self._effectModules[effectModule.Name] = require(effectModule)
	end

	self._abilityService.EffectCreated:Connect(function(sourcePlayer, target, effectName, data)
		self:PerformEffect(sourcePlayer, target, effectName, data)
	end)

	self._abilityService.XpAdded:Connect(function(xp)
		self._monsterService:UpdateXp(self._currentMonster, xp)
	end)
	self._abilityService.NPCAbility:Connect(function(abilityName, npcModel)
		self:PerformNPCAbility(abilityName, npcModel)
	end)

	self._monsterService:UpdateData()
end

function AbilityController:PerformAbility(abilityName: string)
	if self._abilityInPogress then
		return
	end
	local abilities = self._displayUI._abilitiesList:get()
	if abilities[abilityName].cooldown > 0 then
		return
	end
	if self._abilityLocked[abilityName] then
		return
	end
	self._abilityInPogress = true
	self._abilityModules[abilityName]()
end

function AbilityController:AbilityEnded()
	self._abilityInPogress = false
end

function AbilityController:PerformNPCAbility(abilityName: string, npcModel: Model)
	self._abilityModules[abilityName](npcModel)
end

function AbilityController:PerformEffect(source, target, effectName, data)
	self._effectModules[effectName](source, target, data)
end

function AbilityController:CreateLocalEffect(source, target, effectName, data)
	if source == Player or source:GetAttribute("isNPC") then
		if data and data.AbilityName and target then
			local info = AbilityData[data.AbilityName]
			if info then
				if info.Damage then
					if source:GetAttribute("isNPC") and target == Player.Character then
						task.spawn(function()
							self._abilityService:DamagePlayer(info.Damage)
						end)
					else
						task.spawn(function()
							target.Humanoid:TakeDamage(info.Damage)
							self:CreateLocalEffect(source, target, "DamageCounter", info)
						end)
					end
				end
				if info.Xp and not source:GetAttribute("isNPC") then
					task.spawn(function()
						self._monsterService:UpdateXp(self._currentMonster, info.Xp)
					end)
				end
			end
		end
		if not target or target == Player.Character or target:GetAttribute("isNPC") then
			self:PerformEffect(source, target, effectName, data)
		end
	end
end

function AbilityController:StartCooldown(abilityName, cooldown)
	local abilities = self._displayUI._abilitiesList:get()
	local scaledCooldown = cooldown * 100

	for index = 0, scaledCooldown do
		abilities[abilityName].cooldown = (scaledCooldown - index) / scaledCooldown
		abilities[abilityName].totalCooldown = math.round(cooldown * 2 * abilities[abilityName].cooldown)
		self._displayUI._abilitiesList:set(abilities)

		task.wait(0.01)
	end
end

function AbilityController:ControlSwitched(isPlayer: boolean, monsterName: string)
	function StartAbility(Event, InputState, InputObject)
		if InputState == Enum.UserInputState.Begin then
			self:PerformAbility(Event)
		end
	end
	local abilitiesList = {}

	if isPlayer then
		local abilities = self._displayUI._abilitiesList:get()
		for abilityName, abilityData in pairs(abilities) do
			ContextActionService:UnbindAction(abilityName)
		end
		self._displayUI._enabled:set(false)
		self._displayUI._abilitiesList:set(abilitiesList)
		self._currentMonster = nil
	else
		self:SetAbilities(monsterName)
	end
end

function AbilityController:SetAbilities(monsterName)
	local abilitiesList = {}
	self._abilityLocked = {}
	local currentMonsterData = MonsterData[monsterName]
	self._currentMonster = monsterName
	local abilities = currentMonsterData.Abilities
	local index = 1
	for abilityName, abilityData in pairs(abilities) do
		local isAbilityLocked, abilityUnlockLevel = self:IsAbilityLocked(abilityName)
		self._abilityLocked[abilityName] = isAbilityLocked
		ContextActionService:UnbindAction(abilityName)
		ContextActionService:BindAction(abilityName, StartAbility, false, Enum.KeyCode[keyBinds[index]])
		abilitiesList[abilityName] = {
			keyBind = keyBinds[index],
			cooldown = 0,
			totalCooldown = 0,
			unlockLevel = abilityUnlockLevel,
		}
		index += 1
	end
	self._displayUI._enabled:set(true)
	self._displayUI._abilitiesList:set(abilitiesList)
end

function AbilityController:IsAbilityLocked(abilityName)
	local playerId = tostring(Player.UserId)
	local myMonsterData = self._monsterData[playerId]
	local currentMonsterData = myMonsterData[self._currentMonster]
	local level = currentMonsterData.Level
	local abilityData = MonsterData[self._currentMonster].Abilities[abilityName]
	local unlockLevel = abilityData.UnlockLevel
	return level < unlockLevel, unlockLevel
end

function AbilityController:SetMonsterLevel()
	local playerId = tostring(Player.UserId)
	local myMonsterData = self._monsterData[playerId]
	local currentMonsterData = myMonsterData[self._currentMonster]
	local level = currentMonsterData.Level
	self._displayUI._currentMonsterLevel:set(level)
end

function AbilityController:CheckForUnlocks() end

function AbilityController:KnitInit()
	-- Services
	self._abilityService = Knit.GetService("AbilityService")
	self._monsterService = Knit.GetService("MonsterService")

	-- vars
	self._monsterData = {}
	self._currentMonster = nil

	self._monsterService.DataFoundSignal:Connect(function(monsterData: {})
		self._monsterData = monsterData
		if self._currentMonster then
			self:SetMonsterLevel()
			self:SetAbilities(self._currentMonster)
		end
	end)
end

return AbilityController
