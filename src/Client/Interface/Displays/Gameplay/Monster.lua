--[[
    Monster.lua
    Author(s): Jibran

    Description: Monster Grid for minigame
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts
local Players = game:GetService("Players")

-- Player
local Player: Player = Players.LocalPlayer
local PlayerGui: PlayerGui = Player.PlayerGui

-- Packages
local Packages: Folder = ReplicatedStorage.Packages
local Fusion = require(Packages.Fusion)
local Knit = require(Packages.Knit)

-- Modules
local Interface = StarterPlayerScripts.Interface
local Components = Interface.Components
local Common = Components.Common
local TextLabel = require(Common.TextLabel)
local ImageButton = require(Common.ImageButton)

-- Fusion Constant Declarations
local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local Spring = Fusion.Spring
local Observer = Fusion.Observer
local OnEvent = Fusion.OnEvent

-- module class table
local Monster = {}

-- Initializing match display UI in player GUI
function Monster:Initialize()
	-- Knit Controllers
	self._MonsterController = Knit.GetController("MonsterController")

	-- Initialize Fusion Values
	self._currentMonsterText = Value("")
	self._currentText = Value("")
	self._enabled = Value(true)
	self._isPlayer = Value(true)
	self._monsterExists = Value(false)
	self._standbyCharacter = Value(nil)
	local currentUI = self:CreateUI()
	currentUI.Parent = PlayerGui
	local billboardGui = self:CreateBillboardUI()
	billboardGui.Parent = PlayerGui

	self._MonsterController._displayUI = self
end

-- Creating UI from props defined
function Monster:CreateUI()
	-- GUIObjectProps

	local spawnLabelProps = {
		Name = "Spawn",
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Text = "Spawn Monster",
		Size = UDim2.fromScale(0.8, 0.35),
		Font = Enum.Font.SourceSansBold,
		BackgroundTransparency = 1,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(0, 0, 0),
		ZIndex = 6,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	}

	local spawnButtonProps = {
		Name = "Spawn",
		Position = Spring(Computed(function()
			if self._enabled:get() then
				return UDim2.fromScale(0.9, 0.2)
			else
				return UDim2.fromScale(0.9, 2)
			end
		end)),
		AnchorPoint = Vector2.new(0.9, 0.2),
		Size = UDim2.fromScale(0.1, 0.1),
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		Image = "rbxassetid://15661327736",
		HoverImage = "rbxassetid://15661327973",
		PressedImage = "rbxassetid://15661327736",
		ZIndex = 5,
		LayoutOrder = 1,
		callback = function()
			self._MonsterController:SpawnMonster()
		end,
		Children = {

			TextLabel(spawnLabelProps),
		},
	}

	local switchLabelProps = {
		Name = "Switch",
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Text = Spring(Computed(function()
			if self._isPlayer:get() then
				return "Switch To Monster"
			else
				return "Switch To Player"
			end
		end)),
		Size = UDim2.fromScale(0.8, 0.35),
		Font = Enum.Font.SourceSansBold,
		BackgroundTransparency = 1,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(0, 0, 0),
		ZIndex = 6,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	}

	local switchButtonProps = {
		Name = "Spawn",
		Position = Spring(Computed(function()
			if self._monsterExists:get() then
				return UDim2.fromScale(0.9, 0.4)
			else
				return UDim2.fromScale(0.9, 2)
			end
		end)),
		AnchorPoint = Vector2.new(0.9, 0.4),
		Size = UDim2.fromScale(0.1, 0.1),
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		Image = "rbxassetid://15661327736",
		HoverImage = "rbxassetid://15661327973",
		PressedImage = "rbxassetid://15661327736",
		ZIndex = 5,
		LayoutOrder = 1,
		callback = function()
			if self._isPlayer:get() then
				self._MonsterController:SwitchToMonster()
			else
				self._MonsterController:SwitchToPlayer()
			end
		end,
		Children = {

			TextLabel(switchLabelProps),
		},
	}

	-- Creating GUI with elements
	return New("ScreenGui")({
		Name = "Monster",
		Enabled = true,
		ResetOnSpawn = false,
		[Children] = {
			ImageButton(spawnButtonProps),
			ImageButton(switchButtonProps),
		},
	})
end

function Monster:CreateBillboardUI()
	local indicatorLabelProps = {
		Name = "Indicator",
		Position = UDim2.fromScale(0.5, 0.2),
		AnchorPoint = Vector2.new(0.5, 0.2),
		Text = Spring(Computed(function()
			if self._isPlayer:get() then
				return "Your Monster"
			else
				return "Your Player"
			end
		end)),
		Size = UDim2.fromScale(0.8, 0.8),
		Font = Enum.Font.SourceSansBold,
		BackgroundTransparency = 0.5,
		BackgroundColor3 = Color3.fromRGB(237, 224, 224),
		TextScaled = true,
		TextColor3 = Color3.fromRGB(0, 0, 0),
		ZIndex = 4,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Children = {
			New("UICorner")({
				CornerRadius = UDim.new(0.5, 0),
			}),
		},
	}

	return New("BillboardGui")({
		Name = "Indicator",
		Adornee = Spring(Computed(function()
			local standbyCharacter = self._standbyCharacter:get()
			if standbyCharacter then
				return standbyCharacter.HumanoidRootPart
			end
		end)),
		Size = UDim2.fromScale(4, 1),
		AlwaysOnTop = false,
		ExtentsOffsetWorldSpace = Spring(Computed(function()
			if self._isPlayer:get() then
				return Vector3.new(0, 10, 0)
			else
				return Vector3.new(0, 5, 0)
			end
		end)),
		Active = true,
		MaxDistance = 200,
		Enabled = Spring(Computed(function()
			return self._monsterExists:get()
		end)),
		[Children] = {

			TextLabel(indicatorLabelProps),
		},
	})
end

return Monster
