--[[
    AbilityController.lua
    Author(s): Jibran

    Description: Manages Abilities
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts
-- Modules
local Modules = StarterPlayerScripts.Modules
local Abilties = Modules.Abilities
local Effects = Modules.Effects

-- Packages
local Packages: Folder = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

-- Shared
local Shared = ReplicatedStorage.Shared
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

-- Consts
local AVATAR_TAG = "Avatar"

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
		self._AvatarService:UpdateXp(xp)
	end)
	self._abilityService.NPCAbility:Connect(function(abilityName, npcModel)
		self:PerformNPCAbility(abilityName, npcModel)
	end)

	Player.CharacterAdded:Connect(function(character)
		if self._AvatarData.Level then
			self:SetAbilities()
		end
	end)

	self._AvatarService:UpdateData()
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

-- Start Ability Cooldown

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

-- mapping abilities on keybind and fusion UI
function AbilityController:SetAbilities()
	function StartAbility(Event, InputState, InputObject)
		if InputState == Enum.UserInputState.Begin then
			self:PerformAbility(Event)
		end
	end
	local abilitiesList = {}
	self._abilityLocked = {}

	local abilities = AbilityData
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
			Name = abilityData.Name
		}
		index += 1
	end
	self._displayUI._enabled:set(true)
	self._displayUI._abilitiesList:set(abilitiesList)
end

-- check for ability unlock
function AbilityController:IsAbilityLocked(abilityName)
	local playerId = tostring(Player.UserId)
	local myAvatarData = self._AvatarData[playerId]
	local level = myAvatarData.Level
	local abilityData = AbilityData[abilityName]
	local unlockLevel = abilityData.UnlockLevel
	return level < unlockLevel, unlockLevel
end

-- set player level on Fusion UI
function AbilityController:SetAvatarLevel()
	local playerId = tostring(Player.UserId)
	local myAvatarData = self._AvatarData[playerId]
	local level = myAvatarData.Level

	self._displayUI._currentAvatarLevel:set(level)
end

function AbilityController:KnitInit()
	-- Services
	self._abilityService = Knit.GetService("AbilityService")
	self._AvatarService = Knit.GetService("AvatarService")

	-- vars
	self._AvatarData = {}

	-- connections
	self._AvatarService.DataFoundSignal:Connect(function(AvatarData: {})
		self._AvatarData = AvatarData
		self:SetAvatarLevel()
		self:SetAbilities()
		if not Player.Character then
			Player.CharacterAdded:Wait()
		end
	end)
end

return AbilityController
