--[[
    NPCController.lua
    Author: Jibran Ali
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

-- Assets
local Assets = ReplicatedStorage.Assets
local NPCs = Assets.NPCs

-- workspace
local NPCsFolder = workspace.NPCs
local Spawns = workspace.Spawns
local NPCSpawns = Spawns.NPC

--Player
local Player = Knit.Player

local NPCController = Knit.CreateController({ Name = "NPCController" })

function NPCController:KnitStart()


end


function NPCController:KnitInit() end

return NPCController
