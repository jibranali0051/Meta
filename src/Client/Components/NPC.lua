-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")


-- Packages
local Packages: Folder = ReplicatedStorage.Packages
local Component = require(Packages.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Path
local path = PathfindingService:CreatePath()


-- Player
local Player = Knit.Player

-- Shared
local Shared = ReplicatedStorage.Shared
local NPCData = require(Shared.NPCData)

-- Constants
local DETECTION_DISTANCE = 80
local ATTACK_DISTANCE = 30
local STOP_DISTANCE = 20

-- vars
local waypoints
local nextWaypointIndex
local reachedConnection
local blockedConnection

-- Initializing Component
local NPC = Component.new({
	Tag = "NPC",
})

-- Runtime function | Runs prior to :Start()
function NPC:Construct() end

-- Runtime function | Runs following :Construct()
function NPC:Start()
	if true then return end
	self._npcData = NPCData[self.Instance.Name]
	self._abilities = self._npcData.Abilities
	self._target = nil
	self._onCooldown = {}
	self._abilityInPogress = false
	self._pathInProgress = false
	local characters = {}
	for _, player in pairs(Players:GetPlayers()) do
		table.insert(characters, player.Character)
	end

	self._overlapParams = OverlapParams.new()
	self._overlapParams.FilterDescendantsInstances = { characters }
	self._overlapParams.FilterType = Enum.RaycastFilterType.Whitelist
	self._overlapParams.MaxParts = 3
	self._connection = RunService.Heartbeat:Connect(function(deltaTime)
		self:OnStepped()
	end)
	self.Instance.Humanoid.Died:Connect(function()
		self._connection:Disconnect()
	end)
end

function NPC:PerformAbility()
	math.randomseed(os.time())
	local randomAbilityIndex = math.random(1, #self._abilities)
	if self._onCooldown[self._abilities[randomAbilityIndex].Name] then
		return
	end
	self._abilityInPogress = true
	local cooldown = self._abilities[randomAbilityIndex].Cooldown
	self._onCooldown[self._abilities[randomAbilityIndex].Name] = true
	task.delay(cooldown, function()
		self._onCooldown[self._abilities[randomAbilityIndex].Name] = false
		self._abilityInPogress = false
	end)
	Knit.GetController("AbilityController"):PerformNPCAbility(self._abilities[randomAbilityIndex].Name, self.Instance)
end


function NPC:FollowPath(destination)


	-- Compute the path
	local success, errorMessage = pcall(function()
		path:ComputeAsync(self.Instance.PrimaryPart.Position, destination)
	end)

	if success and path.Status == Enum.PathStatus.Success then
		-- Get the path waypoints
		waypoints = path:GetWaypoints()
		self._pathInProgress = true
		print("here")

		-- Detect if path becomes blocked
		blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
			-- Check if the obstacle is further down the path
			if blockedWaypointIndex >= nextWaypointIndex then
				-- Stop detecting path blockage until path is re-computed
				blockedConnection:Disconnect()
				-- Call function to re-compute new path
				self:FollowPath(destination)
			end
		end)

		-- Detect when movement to next waypoint is complete
		if not reachedConnection then
			reachedConnection = self.Instance.Humanoid.MoveToFinished:Connect(function(reached)
				if reached and nextWaypointIndex < #waypoints then
					-- Increase waypoint index and move to next waypoint
					nextWaypointIndex += 1

					self.Instance.Humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
				else
					reachedConnection:Disconnect()
					blockedConnection:Disconnect()
					self._pathInProgress = false
				end
			end)
		end
		print(waypoints)
		-- Initially move to second waypoint (first waypoint is path start; skip it)
		nextWaypointIndex = 2
		self.Instance.Humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
	else
		warn("Path not computed!", errorMessage)
	end
end

function NPC:OnStepped()
	if self._abilityInPogress then
		return
	end

	local characters = {}
	for _, player in pairs(Players:GetPlayers()) do
		table.insert(characters, player.Character)
	end

	self._overlapParams.FilterDescendantsInstances = { characters }
	local parts =
		workspace:GetPartBoundsInRadius(self.Instance.PrimaryPart.Position, DETECTION_DISTANCE, self._overlapParams)
	if #parts > 1 then
		local model = parts[1]:FindFirstAncestorOfClass("Model")
		if model:GetAttribute("PlayerId") then
			local playerId = model:GetAttribute("PlayerId")
			if tostring(Player.UserId) == playerId then
				self._target = model
			else
				self._target = nil
			end
		end
	else
		self._target = nil
	end
	if self._target then
		-- if (self.Instance.PrimaryPart.Position - self._target.PrimaryPart.Position).Magnitude > STOP_DISTANCE then
		-- 	self.Instance.Humanoid:MoveTo(self._target.HumanoidRootPart.Position)
		-- end

		if not self._pathInProgress then
			self:FollowPath(self._target.HumanoidRootPart.Position)
		end

		if (self.Instance.PrimaryPart.Position - self._target.PrimaryPart.Position).Magnitude < ATTACK_DISTANCE then
			if self._abilityInPogress then
				return
			end
			self:PerformAbility()
		end
	end
end

-- Runs when tag is disconnected from object
function NPC:Stop() end

return NPC




















