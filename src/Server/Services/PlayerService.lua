--[[
    PlayerService.lua
    Author: Jibran

    Description: Manage player spawning and interactions with the server involving data
]]

-- Services
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local CollectionService = game:GetService("CollectionService")

-- Modules
local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")
local PlayerContainer = require(Modules.PlayerContainer)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)
local Promise = require(Packages.Promise)

local AVATAR_TAG = "Avatar"

local PlayerService = Knit.CreateService({
	Name = "PlayerService",
	Client = {
		SendFirstTime = Knit.CreateSignal(),
		CharacterLoaded = Knit.CreateSignal(),
	},
})

-- Get the player's container to interact with it
function PlayerService:GetContainer(player, isYielding: boolean?)
	-- ensure player exists
	if not player then
		warn("Cannot get container of nonexistent player")
		return
	end

	local container = self._players[player]
	if isYielding and not container then
		repeat
			task.wait()
			container = self._players[player]
		until not player or container
	end

	if container then
		return container
	else
		warn("Could not get container for " .. tostring(player))
	end

	return nil
end

-- Useful if other things need to be done before/after a character is loaded
function PlayerService:CustomLoadCharacter(player)
	player:LoadCharacter()
end

-- Called when player loads their data replica for the first time, then "yields" until character loads
function PlayerService.Client:DidLoadReplica(player: Player)
	local thisContainer = self.Server._players[player]
	if not player.Character then
		--self.Server:CustomLoadCharacter(player, thisContainer.Profile.Data.Kit)
	end

	self.SendFirstTime:Fire(player)
	return true
end

function PlayerService:KnitStart()
	self._joinTimes = {}

	-- instantiate player function
	local function initPlayer(player)
		local newContainer = PlayerContainer.new(player)
		self._players[player] = newContainer
		self.ContainerCreated:Fire(player, newContainer)

		self._joinTimes[player] = os.time()

		-- create leader stats
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player

		-- // create individual leaderstat values!

		--[[ // example:
        local sos = Instance.new("IntValue")
        sos.Name = "H/Rs"
        sos.Value = 0
        sos.Parent = leaderstats
        --]]

		-- initialize data
		-- spawn player
		player.CharacterAdded:Connect(function(character)
			task.wait()
			for _, v in ipairs(character:GetChildren()) do
				if v:IsA("BasePart") then
					local x: BasePart
					v.CollisionGroup = "Players" -- // useful for disabling player-player collisions
				end
			end

			task.wait(2)

			CollectionService:AddTag(character, AVATAR_TAG)
		end)
	end

	-- cleanup player function
	local function cleanupPlayer(player)
		-- remove player object
		assert(self._players[player], "Could not find player object for " .. player.Name)
		local playerContainer = self._players[player]

		playerContainer:Destroy()

		self._players[player] = nil
		self._joinTimes[player] = nil
	end

	Players.PlayerAdded:Connect(initPlayer)
	Players.PlayerRemoving:Connect(cleanupPlayer)

	task.wait(2)
	-- load players that joined before
	for _, player in Players:GetPlayers() do
		if not self._players[player] then
			initPlayer(player)
		end
		if not CollectionService:HasTag(player.Character, AVATAR_TAG) then
			CollectionService:AddTag(player.Character, AVATAR_TAG)
		end
	end
end

function PlayerService:ResetData(player: Player)
	local container = self:GetContainer(player, true)
	if not container then
		return
	end
	container:ResetData()
	print("Reset data for " .. player.Name)
end

-- Client
function PlayerService.Client:ResetData(player: Player)
	return self.Server:ResetData(player)
end

function PlayerService:KnitInit()
	self._players = {}

	self.CharacterLoadedEvent = Signal.new()
	self.ContainerCreated = Signal.new()
end

return PlayerService
