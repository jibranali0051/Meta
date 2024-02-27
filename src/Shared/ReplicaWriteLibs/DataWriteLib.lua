--[[
    DataWriteLib.lua
    Author: Jibran
    Description: Write libs to safely mutate data for player profile through defined
    methods as opposed to direct manipulations. These methods also automatically propogate
    to the client via ReplicaService, and can be listened to using DataController

]]
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(game.ReplicatedStorage.Packages.Knit)

local Shared = ReplicatedStorage.Shared

local DEBUG_TAG = "[" .. script.Name .. "]"

-- verify these on the server and stuff
local DataWriteLib = {

	-- Update Avatar Configuration
	UpdateAvatarConfig = function(replica, AvatarData: table)
		replica:SetValue("Avatar", AvatarData)
	end,
}

return DataWriteLib
