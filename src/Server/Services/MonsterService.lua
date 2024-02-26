--[[
    MonsterService.lua
    Author: Jibran Ali
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Modules = ServerStorage:WaitForChild("Modules")
local MonsterManager = require(Modules.MonsterManager)

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

-- Shared
local Shared = ReplicatedStorage.Shared
local LevelData = require(Shared.LevelData)

local MonsterService = Knit.CreateService({
	Name = "MonsterService",
	Client = {
		SpawnMonster = Knit.CreateSignal(),
		SwitchToMonster = Knit.CreateSignal(),
		SwitchToPlayer = Knit.CreateSignal(),
		MonsterSpawned = Knit.CreateSignal(),
		MonsterDespawned = Knit.CreateSignal(),
		CharacterSwitched = Knit.CreateSignal(),
		DataFoundSignal = Knit.CreateSignal(),
	},
})

function MonsterService:KnitStart()
	self._monsterManagers = {}
	self._MonsterData = {}

	Players.PlayerAdded:Connect(function(player)
		if not self._monsterManagers[player] then
			self._monsterManagers[player] = MonsterManager.new(player)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:UpdateMonsterData(player)
		--self:Despawn(player)
	end)

	task.delay(2, function()
		for _, player in ipairs(Players:GetPlayers()) do
			if not self._monsterManagers[player] then
				self._monsterManagers[player] = MonsterManager.new(player)
			end
		end
	end)
end

function MonsterService:UpdateMonsterData(player)
	local playerContainer = self._playerService:GetContainer(player, true)
	if not playerContainer then
		return
	end
	playerContainer.Replica:Write("UpdateMonsterConfig", self._MonsterData[player.UserId])
	self.Client.DataFoundSignal:Fire(player, self._MonsterData)
end

function MonsterService:UpdateXp(player, monsterName, xp)
	local currentData = self._MonsterData[player.UserId]
	if not currentData[monsterName] then return end
	local currentXp = currentData[monsterName].Xp
	local currentLevel = currentData[monsterName].Level
	local xpToNextLevel = LevelData["Level" .. tostring(currentLevel)]
	currentXp += xp
	if currentXp >= xpToNextLevel then
		if LevelData["Level" .. tostring(currentLevel+1)] ~= nil then
			currentXp = 0
			currentLevel += 1
		else
			currentXp = xpToNextLevel
		end
	end
	self._MonsterData[player.UserId][monsterName].Level = currentLevel
	self._MonsterData[player.UserId][monsterName].Xp = currentXp
	self.Client.DataFoundSignal:Fire(player, self._MonsterData)
end

function MonsterService:UpdateData(player: Player)
	local playerContainer = self._playerService:GetContainer(player, true)
	if not playerContainer then
		self._MonsterData[player.UserId] = {}
	else
		self._MonsterData[player.UserId] = playerContainer.Profile.Data.Monsters
	end
	-- Send to client to prepare any local effects per checkpoint
	if not player.Character then
		player.CharacterAdded:Wait()
	end
	self.Client.DataFoundSignal:Fire(player, self._MonsterData)
end


function MonsterService:GetData(player: Player)
	self.Client.DataFoundSignal:Fire(player, self._MonsterData)
end

function MonsterService:KnitInit()
	-- Services
	self._playerService = Knit.GetService("PlayerService")
end

-- Client functions

function MonsterService.Client:UpdateData(player: Player)
	self.Server:UpdateData(player)
end

function MonsterService.Client:GetData(player: Player)
	self.Server:GetData(player)
end

function MonsterService.Client:UpdateXp(player: Player, monsterName: string, xp: number)
	self.Server:UpdateXp(player, monsterName, xp)
end



return MonsterService
