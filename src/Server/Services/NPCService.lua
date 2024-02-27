--[[
    NPCService.lua
    Author: Jibran Ali
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Modules = ServerStorage:WaitForChild("Modules")
local sessionData = require(Modules.SessionDataModule)
local NPC = require(Modules.NPC)

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

-- Assets
local Assets = ReplicatedStorage.Assets
local NPCs = Assets.NPCs

-- workspace
local NPCsFolder = workspace.NPCs
local Spawns = workspace.Spawns
local NPCSpawns = Spawns.NPC

local NPCService = Knit.CreateService({
	Name = "NPCService",
	Client = {},
})

function NPCService:KnitStart()
	self.NPCIds = 1
	self.NPCEvent = Signal.new()
	self._NPCs = {}
	task.wait(5)
	for _, npc in pairs(NPCSpawns:GetChildren()) do
		task.spawn(function()
			self:SpawnNPC(npc)
		end)
	end
end

function NPCService:SpawnNPC(npcSpawn)
	local npcName = npcSpawn.Name
	local newNPC = NPCs[npcName]:Clone()
	local newID = tostring("NPC " .. self.NPCIds)
	self.NPCIds += 1
	newNPC.Parent = NPCsFolder

	newNPC:SetPrimaryPartCFrame(npcSpawn.CFrame + Vector3.new(0, 2, 0))
	

	
	newNPC.Humanoid.Died:Connect(function()
		task.delay(2, function()
			newNPC:Destroy()
		end)
		self:SpawnNPC(npcSpawn)
	end)
	self._NPCs[newID] = NPC:New(newNPC, newID, NPCsFolder)
	self._NPCs[newID]:StartAi()

end

function NPCService:OnMobEvent(eventData)
	if eventData["Type"] == "MobDied" then
		local mobId = eventData["MobId"]
		local target = eventData["Target"]

		local mobName = eventData["MobName"]

		if target ~= nil then
			sessionData.ChasingMobs[target][mobId] = nil
		end
	elseif eventData["Type"] == "NewTarget" then
		local mobId = eventData["MobId"]
		local oldTarget = eventData["OldTarget"]
		local newTarget = eventData["NewTarget"]

		if oldTarget ~= nil and sessionData.ChasingMobs[oldTarget] ~= nil then
			sessionData.ChasingMobs[oldTarget][mobId] = nil
		end
		if newTarget ~= nil and sessionData.ChasingMobs[newTarget] ~= nil then
			sessionData.ChasingMobs[newTarget][mobId] = true
		end
	end
end

function NPCService:KnitInit() end

return NPCService
