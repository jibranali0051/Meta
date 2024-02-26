local utilsModule = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")

local sessionData = require(game.ServerStorage.Modules.SessionDataModule)



function utilsModule.GetNumberOfChasingMobsOfRootPartTarget(target)
	
	if target == nil or target.Parent == nil then return 0 end
	
	local targetPlayer = Players:GetPlayerFromCharacter(target.Parent)
	
	if targetPlayer == nil then return 0 end
	
	local chasingMobs = 0
	
	if sessionData.ChasingMobs[target.Parent.Name] ~= nil then
		for i, v in pairs(sessionData.ChasingMobs[target.Parent.Name]) do
			chasingMobs = chasingMobs + 1
		end
	end
	
	return chasingMobs
end

function utilsModule.CalculateModelMass(model)
	
	local mass = 0

	for i, v in pairs(model:GetDescendants()) do
		if v:IsA("Part") or v:IsA("BasePart") then
			mass += v:GetMass()
		end
	end

	return mass
end


function utilsModule.GetPlayerFromName(name)
	for i, player in pairs(Players:GetPlayers()) do
		if player.Name:lower() == name:lower() then
			return player
		end
	end
end



function utilsModule.MaxValueInDictionary(dict)
	
	local max = 0
	
	for i, v in pairs(dict) do
		if v > max then max = v end
	end
	
	return max
end



function utilsModule.SetCollisionGroupRecursive(object, collisionGroupName)
	
	if object:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(object, collisionGroupName)
	end
	
	for i, child in ipairs(object:GetChildren()) do
		utilsModule.SetCollisionGroupRecursive(child, collisionGroupName)
	end
end

function utilsModule.GetCollisionGroupId(name)
	local ok, groupId = pcall(PhysicsService.GetCollisionGroupId, PhysicsService, name)
	return ok and groupId or nil
end

function utilsModule.HasValue(tab, val)
	
	for index, value in ipairs(tab) do
		if value == val then return true end
	end
	
	return false
end

function utilsModule.GetNumberOfKeysInTable(tab)
	
	local count = 0
	
	for k,v in pairs(tab) do
		count = count + 1
	end
	
	return count
end





return utilsModule