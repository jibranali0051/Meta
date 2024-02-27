--[[
    AvatarService.lua
    Author: Jibran Ali
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Shared
local Shared = ReplicatedStorage.Shared
local LevelData = require(Shared.LevelData)

local AvatarService = Knit.CreateService({
	Name = "AvatarService",
	Client = {
		DataFoundSignal = Knit.CreateSignal(),
	},
})

function AvatarService:KnitStart()
	self._AvatarManagers = {}
	self._AvatarData = {}

	Players.PlayerAdded:Connect(function(player) end)

	Players.PlayerRemoving:Connect(function(player)
		self:UpdateAvatarData(player)
		--self:Despawn(player)
	end)
end

-- Writing data to profile store
function AvatarService:UpdateAvatarData(player)
	local playerContainer = self._playerService:GetContainer(player, true)
	if not playerContainer then
		return
	end
	playerContainer.Replica:Write("UpdateAvatarConfig", self._AvatarData[player.UserId])
	self.Client.DataFoundSignal:Fire(player, self._AvatarData)
end

-- Update gamestate xp data
function AvatarService:UpdateXp(player, xp)
	local currentData = self._AvatarData[player.UserId]
	if not currentData then
		return
	end
	local currentXp = currentData.Xp
	local currentLevel = currentData.Level
	local xpToNextLevel = LevelData["Level" .. tostring(currentLevel)]
	currentXp += xp
	if currentXp >= xpToNextLevel then
		if LevelData["Level" .. tostring(currentLevel + 1)] ~= nil then
			currentXp = 0
			currentLevel += 1
		else
			currentXp = xpToNextLevel
		end
	end
	self._AvatarData[player.UserId].Level = currentLevel
	self._AvatarData[player.UserId].Xp = currentXp
	self.Client.DataFoundSignal:Fire(player, self._AvatarData)
end

function AvatarService:UpdateData(player: Player)
	local playerContainer = self._playerService:GetContainer(player, true)
	if not playerContainer then
		self._AvatarData[player.UserId] = {}
	else
		while not playerContainer.Profile do
			task.wait()
			playerContainer = self._playerService:GetContainer(player, true)
		end
		self._AvatarData[player.UserId] = playerContainer.Profile.Data.Avatar
	end
	-- Send to client to prepare any local effects per checkpoint
	if not player.Character then
		player.CharacterAdded:Wait()
	end
	self.Client.DataFoundSignal:Fire(player, self._AvatarData)
end

function AvatarService:GetData(player: Player)
	self.Client.DataFoundSignal:Fire(player, self._AvatarData)
end

function AvatarService:KnitInit()
	-- Services
	self._playerService = Knit.GetService("PlayerService")
end

-- Client functions

function AvatarService.Client:UpdateData(player: Player)
	self.Server:UpdateData(player)
end

function AvatarService.Client:GetData(player: Player)
	self.Server:GetData(player)
end

function AvatarService.Client:UpdateXp(player: Player, AvatarName: string, xp: number)
	self.Server:UpdateXp(player, AvatarName, xp)
end

return AvatarService
