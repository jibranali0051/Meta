--[[
    MonsterController.lua
    Author: Jibran Ali
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

--Player
local Player = Knit.Player

local MonsterController = Knit.CreateController({ Name = "MonsterController" })

function MonsterController:SpawnMonster()
	self._currentMonster = "TemplateMonster"
	self._MonsterService.SpawnMonster:Fire("TemplateMonster")
end

function MonsterController:SwitchToPlayer()
	if self._abilityController._abilityInPogress then return end
	self._MonsterService.SwitchToPlayer:Fire()

	self._displayUI._isPlayer:set(true)
end

function MonsterController:SwitchToMonster()
	self._MonsterService.SwitchToMonster:Fire(self._currentMonster)

	self._displayUI._isPlayer:set(false)
end

function MonsterController:KnitStart()
	-- Services
	self._MonsterService = Knit.GetService("MonsterService")

	-- Controllers
	self._abilityController = Knit.GetController("AbilityController")

	-- vars
	self._currentMonster = nil
	self._monsterData = {}

	self._MonsterService.DataFoundSignal:Connect(function(monsterData: {})
		self._monsterData = monsterData
	end)

	-- Connections
	self._MonsterService.MonsterSpawned:Connect(function(otherChracter)
		self:ShiftCameraFocus()
		self._displayUI._monsterExists:set(true)
		self._displayUI._isPlayer:set(false)
		self._displayUI._standbyCharacter:set(otherChracter)
		self._abilityController:ControlSwitched(false, self._currentMonster)
	end)

	self._MonsterService.MonsterDespawned:Connect(function()
		self._displayUI._monsterExists:set(false)
		self._currentMonster = nil
		self._displayUI._isPlayer:set(true)
		self._displayUI._standbyCharacter:set(nil)
		self._abilityController:ControlSwitched(true, self._currentMonster)
	end)

	self._MonsterService.CharacterSwitched:Connect(function(isPlayer, otherChracter)
		self:ShiftCameraFocus()
		self._displayUI._isPlayer:set(isPlayer)
		self._displayUI._standbyCharacter:set(otherChracter)
		self._abilityController:ControlSwitched(isPlayer, self._currentMonster)
	end)
end

function MonsterController:ShiftCameraFocus()
	local humanoid = Knit.Player.Character:FindFirstChildOfClass("Humanoid")
	workspace.CurrentCamera.CameraSubject = humanoid
end

function MonsterController:KnitInit() end

return MonsterController
