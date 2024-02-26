--[[
    Ability.lua
    Author(s): Jibran

    Description: Ability Grid for minigame
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
local ForPairs = Fusion.ForPairs

-- module class table
local Ability = {}

-- Initializing match display UI in player GUI
function Ability:Initialize()
	-- Knit Controllers
	self._AbilityController = Knit.GetController("AbilityController")

	-- Initialize Fusion Values
	self._abilitiesList = Value({})
	self._enabled = Value(false)
	self._isPlayer = Value(true)
	self._AbilityExists = Value(false)
	self._currentMonsterLevel = Value(1)

	local currentUI = self:CreateUI()
	currentUI.Parent = PlayerGui

	self._AbilityController._displayUI = self
end

-- Creating UI from props defined
function Ability:CreateUI()
	-- GUIObjectProps

	self._abilities = ForPairs(self._abilitiesList, function(abilityName: string, dataTable: table)
		local abilityLabelProps = {
			Name = abilityName,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Text = abilityName,
			Size = UDim2.fromScale(0.8, 0.35),
			Font = Enum.Font.SourceSansBold,
			BackgroundTransparency = 1,
			TextScaled = true,
			TextColor3 = Color3.fromRGB(0, 0, 0),
			ZIndex = 4,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		}
		local unlockLabelProps = {
			Name = abilityName,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Text = Spring(Computed(function()
				local currentMonsteLevel = self._currentMonsterLevel:get()
				if dataTable.unlockLevel <= currentMonsteLevel then
					return ""
				else
					return "Unlocks at Level " .. tostring(dataTable.unlockLevel)
				end
			end)),
			Size = UDim2.fromScale(0.8, 0.35),
			Font = Enum.Font.SourceSansBold,
			BackgroundTransparency = 1,
			TextScaled = true,
			TextColor3 = Color3.fromRGB(248, 246, 246),
			ZIndex = 6,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		}

		local keyLabelProps = {
			Name = "KeyBind",
			Position = UDim2.fromScale(1.1, -0.1),
			AnchorPoint = Vector2.new(1, 0),
			Text = dataTable.keyBind,
			Size = UDim2.fromScale(0.2, 0.6),
			Font = Enum.Font.SourceSansBold,
			BackgroundTransparency = 1,
			TextScaled = true,
			TextColor3 = Color3.fromRGB(0, 0, 0),
			ZIndex = 4,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		}
		local cooldownLabelProps = {
			Name = "Cooldown",
			Position = UDim2.fromScale(1.1, 1.1),
			AnchorPoint = Vector2.new(1, 1),
			Text = Spring(Computed(function()
				local abiltiesList = self._abilitiesList:get()
				if abiltiesList[abilityName] then
					return tostring(abiltiesList[abilityName].totalCooldown)
				else
					return 0
				end
			end)),
			Size = UDim2.fromScale(0.2, 0.6),
			Font = Enum.Font.SourceSansBold,
			BackgroundTransparency = 1,
			RichText = true,
			TextScaled = true,
			TextColor3 = Color3.fromRGB(57, 33, 97),
			ZIndex = 4,
			Visible = Spring(Computed(function()
				local abiltiesList = self._abilitiesList:get()
				if abiltiesList[abilityName] then
					if abiltiesList[abilityName].cooldown > 0 then
						return true
					else
						return false
					end
				else
					return false
				end
			end)),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		}
		local abilityButtonProps = {
			Name = abilityName,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.1, 0.8),
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.new(0, 0, 0),
			ScaleType = Enum.ScaleType.Stretch,
			Image = "rbxassetid://15661327736",
			HoverImage = "rbxassetid://15661327973",
			PressedImage = "rbxassetid://15661327736",
			ZIndex = 4,
			LayoutOrder = 1,
			callback = function()
				self._AbilityController:PerformAbility(abilityName)
			end,
			Children = {
				New("Frame")({
					Name = "Disabled",
					BackgroundColor3 = Color3.new(0, 0, 0),
					BackgroundTransparency = Spring(Computed(function()
						local abiltiesList = self._abilitiesList:get()
						local currentMonsteLevel = self._currentMonsterLevel:get()
						if abiltiesList[abilityName] then
							if abiltiesList[abilityName].unlockLevel <= currentMonsteLevel then
								return 1 - abiltiesList[abilityName].cooldown
							else
								return 0.1
							end
						else
							return 1
						end
					end)),
					ZIndex = 5,
					Size = UDim2.fromScale(1, 1),
					[Children] = {
						TextLabel(unlockLabelProps),
					},
				}),
				TextLabel(keyLabelProps),
				TextLabel(abilityLabelProps),
				TextLabel(cooldownLabelProps),
			},
		}

		local abilityButton = ImageButton(abilityButtonProps)

		return abilityName, abilityButton
	end, Fusion.cleanup)

	-- Creating GUI with elements
	return New("ScreenGui")({
		Name = "Ability",
		Enabled = true,
		ResetOnSpawn = false,
		[Children] = {
			New("Frame")({
				AnchorPoint = Vector2.new(0.5, 1),
				Position = Spring(Computed(function()
					if self._enabled:get() then
						return UDim2.fromScale(0.5, 1)
					else
						return UDim2.fromScale(0.5, 2)
					end
				end)),
				Size = UDim2.fromScale(0.5, 0.8),
				BackgroundTransparency = 0.8,
				BackgroundColor3 = Color3.new(0, 0, 0),
				[Children] = {
					New("UIAspectRatioConstraint")({
						AspectRatio = 15,
					}),
					New("UIListLayout")({
						Padding = UDim.new(0.05, 0),
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),
					self._abilities,
				},
			}),
		},
	})
end

return Ability
