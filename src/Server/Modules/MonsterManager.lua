--[[
	This script implements the functionality of demon class
]]
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Signal = require(ReplicatedStorage.Packages.Signal)

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Monsters = Assets:WaitForChild("Monsters")
local Scripts = Assets:WaitForChild("Scripts")
local MonstersFolder = workspace:WaitForChild("Monsters")

local MonsterManager = {}
MonsterManager.__index = MonsterManager

function MonsterManager.new(player)
	local self = setmetatable({}, MonsterManager)
	self._name = "MonsterManager"
	self._player = player
	self._monsters = {}
	self._character = nil
	self._currentMonster = nil
	self._isPlayer = true
	self._monsterDeathConnection = nil

	self._trove = Trove.new()

	self._MonsterService = Knit.GetService("MonsterService")

	self._trove:Add(self._MonsterService.Client.SpawnMonster:Connect(function(player, monsterName)
		if player == self._player then
			self:SpawnMonster(monsterName)
		end
	end))

	self._trove:Add(self._MonsterService.Client.SwitchToPlayer:Connect(function(player)
		if player == self._player then
			self:SwitchToPlayer()
		end
	end))

	self._trove:Add(self._MonsterService.Client.SwitchToMonster:Connect(function(player, monsterName)
		if player == self._player then
			self:SwitchToMonster(monsterName)
		end
	end))

	return self
end

function MonsterManager:SpawnMonster(monsterName)
	local selectchar = Monsters:FindFirstChild(monsterName)
	if not selectchar then
		warn("Cannot find the avatar ")
		return
	end
	if self._monsters[monsterName] ~= nil then
		return
	end

	local lastpos = nil
	local char = selectchar:Clone()
	if not char.PrimaryPart then
		char.PrimaryPart = char:FindFirstChild("HumanoidRootPart")
	end

	-- spawn character with the HumanoidDescription
	char.Name = self._player.Name
	if self._player.Character then
		lastpos = self._player.Character:GetPrimaryPartCFrame()
	end

	self:PreserveAvatar()
	self._player.Character = char

	char.Parent = MonstersFolder
	char:SetAttribute("PlayerId", tostring(self._player.UserId))

	self:AddAnimator(char)
	self._isPlayer = false

	char:SetPrimaryPartCFrame(lastpos + Vector3.new(3, 3, 3))
	self._monsters[monsterName] = char
	self._currentMonster = monsterName
	SetNetworkOwnerDescendants(self._player.Character, self._player)
	self._MonsterService.Client.MonsterSpawned:Fire(self._player, self._character)
	self:SetupDeathConnection()
end

function MonsterManager:PreserveAvatar(isMonster)
	self._player.Character.Archivable = true
	if not isMonster then
		self._character = self._player.Character:Clone()
		self._character.Parent = workspace
		if self._character:FindFirstChild("Animate") then
			self._character.Animate:Destroy()
		end
		if self._character.Humanoid:FindFirstChild("Animator") then
			self._character.Humanoid.Animator:Destroy()
		end
	else
		

		self._monsters[self._currentMonster] = self._player.Character:Clone()

		self._monsters[self._currentMonster].Parent = MonstersFolder
		self._monsters[self._currentMonster]:SetAttribute("PlayerId", tostring(self._player.UserId))

		if self._monsters[self._currentMonster]:FindFirstChild("Animate") then
			self._monsters[self._currentMonster].Animate:Destroy()
		end
		if self._monsters[self._currentMonster].Humanoid:FindFirstChild("Animator") then
			self._monsters[self._currentMonster].Humanoid.Animator:Destroy()
		end
		self:SetupDeathConnection()
	end
end

function MonsterManager:SetupDeathConnection()
	if self._monsterDeathConnection then
		self._monsterDeathConnection:Disconnect()
		self._monsterDeathConnection = nil
	end
	self._monsterDeathConnection = self._monsters[self._currentMonster].Humanoid.Died:Connect(function()
		if self._isPlayer then
			Debris:AddItem(self._monsters[self._currentMonster],1)
		end
		self._monsters[self._currentMonster] = nil
		self._currentMonster = nil
		self._MonsterService.Client.MonsterDespawned:Fire(self._player)
		self:SwitchToPlayer()
	end)
end

function MonsterManager:SwitchToMonster(monsterName)
	if self._monsters[monsterName] == nil then
		return
	end

	local char = self._monsters[monsterName]

	-- spawn character with the HumanoidDescription
	self:PreserveAvatar()
	self._player.Character = char
	self:AddAnimator(char)

	self._isPlayer = false
	self._MonsterService.Client.CharacterSwitched:Fire(self._player, false, self._character)
end

function MonsterManager:AddAnimator(char)
	local humanoid = char:WaitForChild("Humanoid")
	local animator = Instance.new("Animator", humanoid)

	local animate = Scripts.Animate:Clone()
	animate.Parent = char
end

function MonsterManager:SwitchToPlayer()
	if self._currentMonster then
		self:PreserveAvatar(true)
	end

	if self._character == nil then
		self._player:LoadCharacter()
	end

	self._player.Character = self._character
	local humanoid = self._character:WaitForChild("Humanoid")
	local animator = Instance.new("Animator", humanoid)

	local animate = Scripts.Animate:Clone()
	animate.Parent = self._player.Character

	self._isPlayer = true
	local standbyCharacter = if self._currentMonster  then self._monsters[self._currentMonster] else nil
	self._MonsterService.Client.CharacterSwitched:Fire(self._player, true, standbyCharacter)
end

function MonsterManager:HideTarget(targetPlayer)
	for _, v in pairs(targetPlayer.Character:GetDescendants()) do
		if v:IsA("Part") or v:IsA("MeshPart") or v:IsA("BasePart") then
			v.Transparency = 1
			v.CanCollide = false
		end
	end
	targetPlayer.Character.Humanoid.WalkSpeed = 0
end

function MonsterManager:ShowTarget(targetPlayer)
	for _, v in pairs(targetPlayer.Character:GetDescendants()) do
		if v:IsA("MeshPart") then
			v.Transparency = 0
			v.CanCollide = false
		elseif v.Name == "HumanoidRootPart" then
			v.CanCollide = true
		end
	end
	targetPlayer.Character.Humanoid.WalkSpeed = 18
end

function SetNetworkOwnerDescendants(model, player)
	for _, v in pairs(model:GetDescendants()) do
		if v:IsA("Part") or v:IsA("MeshPart") or v:IsA("BasePart") then
			v:SetNetworkOwner(player)
		end
	end
end

function MonsterManager:Destroy()
	self._trove:Clean()
end

return MonsterManager
