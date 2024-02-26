local mob = {}

mob.__index = mob

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

-- Shared
local Shared = ReplicatedStorage.Shared
local NPCData = require(Shared.NPCData)

local utilsMod = require(game.ServerStorage.Modules.UtilsModule)
local machine = require(game.ServerStorage.Modules.StateMachineModule)
local sessionData = require(game.ServerStorage.Modules.SessionDataModule)

local directionArray = {

	[1] = Vector3.new(1, 0, 0),
	[2] = Vector3.new(0, 0, 1),
	[3] = Vector3.new(0, 0, -1),
	[4] = Vector3.new(-1, 0, 0),
	[5] = Vector3.new(1, 0, 1).Unit,
	[6] = Vector3.new(-1, 0, 1).Unit,
	[7] = Vector3.new(1, 0, -1).Unit,
	[8] = Vector3.new(-1, 0, -1).Unit,
}

function mob:New(mobModel, mobId, folder)
	local newMob = {}

	setmetatable(newMob, self)

	newMob.MobId = mobId
	newMob.Folder = folder
	newMob.Model = mobModel
	newMob.MyHumanoid = newMob.Model.Humanoid
	newMob.MyRootPart = mobModel.HumanoidRootPart

	newMob.OriginRootCFrame = newMob.MyRootPart.CFrame

	newMob.Target = nil
	newMob.ComboCount = 1
	newMob.Started = false
	newMob.Activated = false
	newMob.DiedConnection = nil
	newMob.LastAttackTime = tick()
	newMob.LastDoubleJump = tick()
	newMob.LastPathCalculation = tick()
	newMob.OffsetVector = directionArray[1]

	newMob.NextWaypointIndex = 2
	newMob.ReachedConnection = nil
	newMob.Path = PathfindingService:CreatePath({ AgentHeight = 18 })

	newMob.Name = mobModel.Name
	newMob.Health = 100
	newMob.ChasingSpeed = 23
	newMob.RunAnimation = workspace.Animations.Run
	newMob.IdleAnimation = workspace.Animations.Idle
	newMob.AttackWaitTime = 1.5
	newMob.MyHumanoid.MaxHealth = 100
	newMob.UpperBodyAnimation = workspace.Animations.UpperBody
	newMob.FindTargetDistance = 50
	newMob.MaxChasingDistance = 300
	newMob.ChaseTargetDistance = 80
	newMob.OutOfBoundsDistance = 500
	newMob.MaxDistanceForAttack = 25
	newMob.StopDistanceForAttack = 20
	newMob.TargetWaitTime = 1

	newMob.CurrentSpeed = 13
	newMob.MyHumanoid.Health = 100
	newMob.MyHumanoid.WalkSpeed = 13

	newMob.Rotator = Instance.new("BodyGyro")
	newMob.Rotator.MaxTorque = Vector3.new(0, 0, 0)
	newMob.Rotator.Name = "Rotator"
	newMob.Rotator.D = 200
	newMob.Rotator.P = 9000
	newMob.Rotator.Parent = newMob.MyRootPart

	newMob._npcData = NPCData[newMob.Name]
	newMob._abilities = newMob._npcData.Abilities
	newMob._onCooldown = {}
	newMob._abilityInPogress = false

	local attackersFolder = Instance.new("Folder")
	attackersFolder.Name = "Attackers"
	attackersFolder.Parent = newMob.Model

	local mobIdFlag = Instance.new("StringValue")
	mobIdFlag.Name = "MobId"
	mobIdFlag.Value = newMob.MobId
	mobIdFlag.Parent = newMob.Model

	for i, child in pairs(newMob.Model:GetDescendants()) do
		if child:IsA("BasePart") then
			child.Anchored = false
			child.CanCollide = false
			child:SetNetworkOwner(nil)
		end
	end

	newMob.MyHumanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)

	return newMob
end

function mob:UpdateNetworkOwnership()
	task.spawn(function()
		local connection
		connection = RunService.Heartbeat:Connect(function(step)
			if not self.MyHumanoid then
				connection:Disconnect()
				return
			end

			if not self.MyHumanoid then
				connection:Disconnect()
				return
			end
			if self.MyHumanoid.Health <= 0 then
				connection:Disconnect()
				return
			end

			for i, child in pairs(self.Model:GetDescendants()) do
				if child:IsA("BasePart") then
					child.Anchored = false
					child.CanCollide = false
					if child:FindFirstChild("Anchor") then
						repeat
							task.wait()
						until child:FindFirstChild("Anchor") == nil
					end
					child:SetNetworkOwner(nil)
				end
			end
		end)
	end)
end

function mob:AttackFunction()
	if self.Target then
		self.Model.PrimaryPart.CFrame = CFrame.lookAt(self.Model.PrimaryPart.CFrame.Position, self.Target.CFrame.Position)
	end
	task.wait(0.1)
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
	if self.TargetPlayer then
		Knit.GetService("AbilityService").Client.NPCAbility
			:Fire(self.TargetPlayer, self._abilities[randomAbilityIndex].Name, self.Model)
	end
end

function mob:ChaseAndJump()
	if self.Model == nil then
		return
	end
	if self.Target == nil then
		return
	end
	if self.MyHumanoid == nil then
		return
	end

	local moveToPos = self:GetMoveToPos()

	local rayData = RaycastParams.new()
	rayData.FilterType = Enum.RaycastFilterType.Whitelist
	rayData.FilterDescendantsInstances = { workspace.Monsters }

	local origin1 = self.MyRootPart.Position
	local origin2 = self.MyRootPart.Position + Vector3.new(0, 0, self.MyRootPart.Size.Z / 1.5)
	local origin3 = self.MyRootPart.Position - Vector3.new(0, 0, self.MyRootPart.Size.Z / 1.5)
	local end1 = self.Target.Position
	local res1 = game.Workspace:Raycast(origin1, end1 - origin1, rayData)
	local res2 = game.Workspace:Raycast(origin2, end1 - origin2, rayData)
	local res3 = game.Workspace:Raycast(origin3, end1 - origin3, rayData)

	if (res1 or res2 or res3) and tick() - self.LastPathCalculation > 2 then
		self.NextWaypointIndex = 2
		self.LastPathCalculation = tick()
		self.Path:ComputeAsync(self.MyRootPart.Position, moveToPos)
		local waypoints = self.Path:GetWaypoints()

		if #waypoints >= 2 then
			self.MyHumanoid:MoveTo(waypoints[self.NextWaypointIndex].Position)
		else
			self.MyHumanoid:MoveTo(moveToPos)
			if self.ReachedConnection then
				self.ReachedConnection:Disconnect()
				self.ReachedConnection = nil
			end
		end

		if not self.ReachedConnection then
			self.ReachedConnection = self.MyHumanoid.MoveToFinished:Connect(function(reached)
				local waypoints = self.Path:GetWaypoints()
				if reached == true and self.NextWaypointIndex < #waypoints then
					self.NextWaypointIndex += 1
					self.MyHumanoid:MoveTo(waypoints[self.NextWaypointIndex].Position)
				else
					self.ReachedConnection:Disconnect()
					self.ReachedConnection = nil
				end
			end)
		end
	elseif not res1 and not res2 and not res3 then
		self.MyHumanoid:MoveTo(moveToPos)

		if self.ReachedConnection then
			self.ReachedConnection:Disconnect()
			self.ReachedConnection = nil
		end
	end

	local originPosition = self.MyRootPart.Position
	local endPosition = (self.MyRootPart.CFrame * CFrame.new(0, 0, -3)).Position
	local result = game.Workspace:Raycast(originPosition, (endPosition - originPosition).Unit * 5, rayData)

	if result and tick() - self.LastDoubleJump > 3 then
		if result.Instance.Parent:FindFirstChild("HumanoidRootPart") then
			return
		end
		self.MyHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		self.MyHumanoid.JumpPower = 80
		wait(0.32)
		self.DoubleJumpAnimationTrack:Play()
		self.MyHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		self.LastDoubleJump = tick()
		self.MyHumanoid.JumpPower = 50
	end
end

function mob:IsInWater()
	if self.MyRootPart.Position.Y < 24 and self.MyRootPart.Position.Y > -100 then
		return true
	end
	return false
end

function mob:IsOutOfBounds()
	if (self.MyRootPart.Position - self.OriginRootCFrame.Position).magnitude > self.OutOfBoundsDistance then
		return true
	end
	return false
end

function mob:FindTarget()
	local target = nil
	local smallestMagnitude = math.huge
	local distance = self.FindTargetDistance

	if self.Model == nil then
		return
	end
	if self.MyHumanoid == nil then
		return
	end

	for i, v in ipairs(workspace.Monsters:GetChildren()) do
		local candidateHumanoid = v:FindFirstChild("Humanoid")
		local candidateRootPart = v:FindFirstChild("HumanoidRootPart")

		if candidateRootPart == nil then
			continue
		end
		if candidateHumanoid == nil then
			continue
		end

		local chasingMobs = 0 -- utilsMod.GetNumberOfChasingMobsOfRootPartTarget(candidateRootPart)

		if chasingMobs >= 2 and self.Target == nil then
			continue
		end

		if candidateHumanoid and candidateRootPart then
			if
				(self.MyRootPart.Position - candidateRootPart.Position).magnitude < distance
				and candidateHumanoid.Health > 0
			then
				distance = (self.MyRootPart.Position - candidateRootPart.Position).magnitude
				if distance < smallestMagnitude then
					smallestMagnitude = distance
					target = candidateRootPart
				end
			end
		end
	end

	if not target and self.Model:FindFirstChild("LastAttacker") then
		local lastAttacker = self.Model.LastAttacker.Value

		local lastAttackerPlayer = utilsMod.GetPlayerFromName(lastAttacker)

		if lastAttackerPlayer then
			local lastAttackerCharacter = lastAttackerPlayer.Character

			if lastAttackerCharacter then
				local invincibleFlag = lastAttackerCharacter:FindFirstChild("Invincible")
				local lastAttackerHumanoid = lastAttackerCharacter:FindFirstChild("Humanoid")
				local lastAttackerRootPart = lastAttackerCharacter:FindFirstChild("HumanoidRootPart")

				if lastAttackerHumanoid and lastAttackerRootPart and not invincibleFlag then
					distance = (self.MyRootPart.Position - lastAttackerRootPart.Position).magnitude
					if distance < self.MaxChasingDistance then
						target = lastAttackerRootPart
					end
				end
			end
		end
	end

	if not target and not self.Model:FindFirstChild("LastAttacker") and self.Target ~= nil then
		local lastTargetCharacter = self.Target.Parent

		if lastTargetCharacter == nil then
			return
		end

		local lastTargetPlayer = utilsMod.GetPlayerFromName(lastTargetCharacter.Name)

		if lastTargetPlayer then
			local lastTargetHumanoid = lastTargetCharacter:FindFirstChild("Humanoid")

			if lastTargetCharacter and lastTargetHumanoid then
				distance = (self.MyRootPart.Position - self.Target.Position).magnitude
				if distance < self.ChaseTargetDistance then
					target = self.Target
				end
			end
		end
	end

	if target ~= self.Target then
		local eventData = {}

		eventData["Type"] = "NewTarget"

		eventData["MobId"] = self.MobId

		if target ~= nil then
			eventData["NewTarget"] = target.Parent.Name
		end

		if self.Target ~= nil and self.Target.Parent ~= nil then
			eventData["OldTarget"] = self.Target.Parent.Name
		end

		Knit.GetService("NPCService"):OnMobEvent(eventData)

		local chasingMobs = utilsMod.GetNumberOfChasingMobsOfRootPartTarget(target)

		self.OffsetVector = directionArray[(chasingMobs % 8) + 1]
	end
	if target then
		self.TargetPlayer = Players:GetPlayerFromCharacter(target.Parent)
	end
	return target
end

function mob:GetMoveToPos()
	if not self.Target then
		return self.MyRootPart.Position
	end

	local chasingMobs = utilsMod.GetNumberOfChasingMobsOfRootPartTarget(self.Target)

	if chasingMobs <= 1 then
		return self.Target.Position
	else
		return self.Target.Position + (self.OffsetVector * 3)
	end
end

function mob:LoadAnimations()
	self.RunAnimationTrack = self.MyHumanoid:LoadAnimation(self.RunAnimation)

	self.IdleAnimationTrack = self.MyHumanoid:LoadAnimation(self.IdleAnimation)

	if self.UpperBodyAnimation then
		self.UpperBodyAnimationTrack = self.MyHumanoid:LoadAnimation(self.UpperBodyAnimation)
	end

	self.DoubleJumpAnimationTrack = self.MyHumanoid:LoadAnimation(workspace.Animations.DoubleJump)
end

function mob:PlayRunAnimation()
	local isRunAnimationPlaying = false
	local isUpperBodyAnimationPlaying = false

	local animationTracks = self.MyHumanoid:GetPlayingAnimationTracks()

	for i, track in pairs(animationTracks) do
		if track.Name == "Run" then
			isRunAnimationPlaying = true
		end
		if self.UpperBodyAnimation and track.Name == self.UpperBodyAnimation.Name then
			isUpperBodyAnimationPlaying = true
		end
	end

	self.IdleAnimationTrack:Stop()

	if isRunAnimationPlaying == false then
		self.RunAnimationTrack:Play()
	end

	if self.UpperBodyAnimationTrack and isUpperBodyAnimationPlaying == false then
		self.UpperBodyAnimationTrack:Play()
	end
end

function mob:StopRunAnimation()
	self.RunAnimationTrack:Stop()
end

function mob:PlayIdleAnimation()
	local isIdleAnimationPlaying = false

	local animationTracks = self.MyHumanoid:GetPlayingAnimationTracks()
	local idleName = self.IdleAnimation.Name
	local upperIdleName = nil

	if self.UpperBodyAnimation then
		upperIdleName = self.UpperBodyAnimation.Name
	end

	for i, track in pairs(animationTracks) do
		if track.Name == idleName then
			isIdleAnimationPlaying = true
		end
		if self.UpperBodyAnimationTrack and track.Name == upperIdleName then
			self.UpperBodyAnimationTrack:Stop()
		end
	end

	if isIdleAnimationPlaying == false then
		self.IdleAnimationTrack:Play()
	end
end

function mob:PlayUpperBodyIdleAnimation()
	if not self.UpperBodyAnimation then
		return
	end

	local isUpperBodyIdleAnimationPlaying = false

	local animationTracks = self.MyHumanoid:GetPlayingAnimationTracks()
	local idleName = self.IdleAnimation.Name
	local upperIdleName = self.UpperBodyAnimation.Name

	for i, track in pairs(animationTracks) do
		if track.Name == upperIdleName then
			isUpperBodyIdleAnimationPlaying = true
		end
		if track.Name == idleName then
			self.IdleAnimationTrack:Stop()
		end
	end

	if isUpperBodyIdleAnimationPlaying == false then
		self.UpperBodyAnimationTrack:Play()
	end
end

function mob:RemoveMob()
	self.DiedConnection:Disconnect()

	-- self.MyHumanoid.Health = 0

	-- self.Model.Parent = workspace.Debris

	-- game.ReplicatedStorage.RemoteEvents.LocalSkillEvent:FireAllClients(
	-- 	"OtherUseableEffects",
	-- 	"DieEffect",
	-- 	{ Character = self.Model, rootPart = self.MyRootPart }
	-- )

	Debris:AddItem(self.Model, 3)

	local mobEventData = {}

	mobEventData["Type"] = "MobDied"
	mobEventData["MobId"] = self.MobId
	mobEventData["MobName"] = self.Name
	mobEventData["Folder"] = self.Folder
	mobEventData["OriginRootCFrame"] = self.OriginRootCFrame

	if self.Target ~= nil and self.Target.Parent ~= nil then
		mobEventData["Target"] = self.Target.Parent.Name
	end

	Knit.GetService("NPCService"):OnMobEvent(mobEventData)

	if sessionData.MobsData[self.MobId] then
		sessionData.MobsData[self.MobId] = nil
	end
end

function mob:Activate()

	-- local function MobDied(player, multiplier)
	-- 	local attackersList = {}

	-- 	for i, v in pairs(self.Model.Attackers:GetChildren()) do
	-- 		local playerName = v.Name
	-- 		local damage = v.Value
	-- 		attackersList[playerName] = damage
	-- 	end

	-- 	for playerName, damage in pairs(attackersList) do
	-- 		local player = utilsMod.GetPlayerFromName(playerName)

	-- 		if not player then
	-- 			continue
	-- 		end

	-- 		local multiplier = (damage / self.MyHumanoid.MaxHealth)

	-- 		if multiplier > 1 then
	-- 			multiplier = 1
	-- 		end

	-- 		GiveRewards(player, multiplier)
	-- 	end

	-- 	self:RemoveMob()
	-- end

	-- self.DiedConnection = self.MyHumanoid.Died:Connect(MobDied)
end

function mob:Idle(fsm, event, from, to)
	task.wait()

	self.MyHumanoid.WalkSpeed = 0

	self:StopRunAnimation()

	self:PlayIdleAnimation()

	if self.ComboWaitTime and self.ComboCount == 1 and tick() - self.LastAttackTime < self.ComboWaitTime then
		repeat
			task.wait()
		until tick() - self.LastAttackTime >= self.ComboWaitTime
	end

	self.Target = self:FindTarget()

	local idleTime = 0

	while not self.Target do
		task.wait(0.1)

		if self.MyHumanoid.Health <= 0 then
			fsm:die()
			return
		end

		self.Target = self:FindTarget()

		idleTime = idleTime + 0.1
	end

	if self.Started == false then
		self.Started = true
		self:UpdateNetworkOwnership()
	end

	if self.Activated == false then
		self.Activated = true
		local activated = Instance.new("BoolValue")
		activated.Name = "Activated"
		activated.Value = true
		activated.Parent = self.Model
	end

	fsm:chase()
end

function mob:WaitTargetTime()
	task.wait(self.TargetWaitTime)
end

function mob:StartAi()
	self:Activate()

	self:LoadAnimations()

	local fsm = machine.create({

		events = {

			{ name = "die", from = { "chasing", "idling", "attacking" }, to = "dead" },
			{ name = "idle", from = { "attacking", "chasing" }, to = "idling" },
			{ name = "startup", from = { "none", "resetting" }, to = "idling" },
			{ name = "chase", from = { "idling", "attacking", "stunning" }, to = "chasing" },
			{ name = "attack", from = { "chasing" }, to = "attacking" },
			{ name = "reset", from = { "idling", "chasing" }, to = "resetting" },
		},

		callbacks = {

			onidling = function(fsm, event, from, to)
				task.wait()

				if self.Model == nil then
					return
				end

				if self.MyHumanoid == nil then
					return
				end

				self:Idle(fsm, event, from, to)
			end,

			onchasing = function(fsm, event, from, to)
				task.wait()

				while self.Target do
					task.wait()

					if self.MyHumanoid.Health <= 0 then
						fsm:die()
						return
					end

					if self.MyRootPart == nil then
						fsm:die()
						return
					end

					-- if self:IsInWater() then
					-- 	fsm:reset(false)
					-- 	return
					-- end

					-- if self:IsOutOfBounds() then
					-- 	fsm:reset(true)
					-- 	return
					-- end

					self:PlayRunAnimation()

					local targetPos = self:GetMoveToPos()

					local distance = (self.MyRootPart.Position - Vector3.new(
						targetPos.X,
						self.MyRootPart.Position.Y,
						targetPos.Z
					)).magnitude

					if distance >= self.StopDistanceForAttack then
						self.MyHumanoid.WalkSpeed = self.CurrentSpeed

						if self.MyRootPart:FindFirstChild("Rotator") then
							self.MyRootPart.Rotator.MaxTorque = Vector3.new(0, 0, 0)
						end

						self:ChaseAndJump()
					elseif distance < self.StopDistanceForAttack then
						self:StopRunAnimation()

						fsm:attack()

						return
					end

					task.wait()

					self.Target = self:FindTarget()
				end

				fsm:idle()
			end,

			onstunning = function(fsm, event, from, to)
				self:OnStun(fsm, event, from, to)
			end,

			onattacking = function(fsm, event, from, to)
				if self.MyHumanoid.Health <= 0 then
					fsm:die()
					return
				end

				if self.MyRootPart == nil then
					fsm:die()
					return
				end

				self.Target = self:FindTarget()

				if not self.Target then
					fsm:idle()
					return
				end

				self.MyHumanoid.WalkSpeed = 0

				self:PlayUpperBodyIdleAnimation()

				while self.Target do
					if self.MyHumanoid.Health <= 0 then
						fsm:die()
						return
					end

					--self:WaitTargetTime()

					local targetPos = self:GetMoveToPos()

					local distance = (self.MyRootPart.Position - Vector3.new(
						targetPos.X,
						self.MyRootPart.Position.Y,
						targetPos.Z
					)).magnitude

					if
						distance < self.MaxDistanceForAttack
						and tick() - self.LastAttackTime > self.AttackWaitTime
						and self.MyHumanoid.Health > 0
					then
						self.MyRootPart.Rotator.CFrame = CFrame.new(
							self.MyRootPart.Position,
							Vector3.new(self.Target.Position.X, self.MyRootPart.Position.Y, self.Target.Position.Z)
						)
						self.MyRootPart.Rotator.MaxTorque = Vector3.new(0, 1, 1) * 500000

						self.LastAttackTime = tick()

						self:AttackFunction()

						task.wait()
					elseif distance >= self.MaxDistanceForAttack then
						fsm:chase()

						return
					end

					task.wait()

					self.Target = self:FindTarget()
				end

				fsm:idle()
			end,

			ondead = function(fsm, event, from, to)
				task.wait()

				return
			end,

			onresetting = function(fsm, event, from, to, restoreHealth)
				task.wait()

				--self:Reset(restoreHealth)

				fsm:startup()
			end,
		},
	})

	fsm:startup()
end

return mob
