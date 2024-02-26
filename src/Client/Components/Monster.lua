-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts

-- Packages
local Packages: Folder = ReplicatedStorage.Packages
local Component = require(Packages.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(Packages.Fusion)

-- Modules
local Interface = StarterPlayerScripts.Interface
local Components = Interface.Components
local Common = Components.Common
local TextLabel = require(Common.TextLabel)

-- Shared
local Shared = ReplicatedStorage.Shared
local LevelData = require(Shared.LevelData)

--- Constant Declarations
local New = Fusion.New
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local Computed = Fusion.Computed
local Spring = Fusion.Spring

-- Initializing Component
local Monster = Component.new({
	Tag = "Monster",
})

-- Runtime function | Runs prior to :Start()
function Monster:Construct() end

-- Runtime function | Runs following :Construct()
function Monster:Start()
	task.wait(1)
	self._level = Value(1)
	self._xp = Value(0)
	self._xpToNextLevel = Value(100)
	self._health = Value(100)
	self._playerId = self.Instance:GetAttribute("PlayerId")
	self._name = self.Instance:GetAttribute("Name")
	local gui = self:CreateUI()
	gui.Parent = self.Instance:WaitForChild("HumanoidRootPart")

	self.Instance.Humanoid.HealthChanged:Connect(function(health)
		self._health:set(health)
	end)
	Knit.GetService("MonsterService").DataFoundSignal:Connect(function(monsterData: {})
		self:UpdateUI(monsterData)
	end)
	Knit.GetService("MonsterService"):GetData()
end

function Monster:UpdateUI(monsterData)
	local myData = monsterData[self._playerId]
	local currentMonsterData = myData[self._name]
	local level = currentMonsterData.Level
	local xp = currentMonsterData.Xp
	local xpToNextLevel = LevelData["Level" .. tostring(level)]
	self._level:set(level)
	self._xp:set(xp)
	self._xpToNextLevel:set(xpToNextLevel)
end

function Monster:CreateUI()
	local levelLabelProps = {
		Name = "Level",
		Position = UDim2.fromScale(0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		Text = Spring(Computed(function()
			local currentLevel = self._level:get()
			if self._xp:get() == self._xpToNextLevel:get() then
				if LevelData["Level" .. tostring(currentLevel + 1)] == nil then
					return "Lvl: Max"
				else
					return "Lvl: " .. tostring(currentLevel)
				end
			else
				return "Lvl: " .. tostring(currentLevel)
			end
		end)),
		Size = UDim2.fromScale(0.8, 0.3),
		Font = Enum.Font.SourceSansBold,
		BackgroundTransparency = 0.5,
		BackgroundColor3 = Color3.fromRGB(68, 48, 102),
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255, 248, 248),
		ZIndex = 4,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Children = {
			New("UICorner")({
				CornerRadius = UDim.new(0.5, 0),
			}),
		},
	}

	local xpLabelProps = {
		Name = "Xp",
		Position = UDim2.fromScale(0.5, 0.45),
		AnchorPoint = Vector2.new(0.5, 0.45),
		Text = Spring(Computed(function()
			return "Xp: " .. tostring(self._xp:get() .. " / " .. tostring(self._xpToNextLevel:get()))
		end)),
		Size = UDim2.fromScale(1, 0.2),
		Font = Enum.Font.SourceSansBold,
		BackgroundTransparency = 0.5,
		BackgroundColor3 = Color3.fromRGB(102, 56, 48),
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255, 248, 248),
		ZIndex = 4,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Children = {
			New("UICorner")({
				CornerRadius = UDim.new(0.5, 0),
			}),
		},
	}

	local healthLabelProps = {
		Name = "Health",
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Text = Spring(Computed(function()
			return tostring(self._health:get() .. " / " .. tostring(100))
		end)),
		Size = UDim2.fromScale(0.8, 0.8),
		Font = Enum.Font.SourceSansBold,
		BackgroundTransparency = 1,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255, 248, 248),
		ZIndex = 4,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	}

	return New("BillboardGui")({
		Name = self.Instance.Name,
		Adornee = self.Instance.HumanoidRootPart,
		Size = UDim2.fromScale(4, 3),
		AlwaysOnTop = false,
		Enabled = true,
		ExtentsOffsetWorldSpace = Vector3.new(0, 6, 0),
		Active = true,
		MaxDistance = 50,
		[Children] = {

			TextLabel(levelLabelProps),
			TextLabel(xpLabelProps),
			New("Frame")({
				Name = "Health",
				Position = UDim2.fromScale(0.5, 0.85),
				AnchorPoint = Vector2.new(0.5, 0.85),
				Size = UDim2.fromScale(1, 0.2),
				BackgroundTransparency = 0,
				BackgroundColor3 = Color3.fromRGB(255, 0, 0),
				ZIndex = 1,
				[Children] = {
					New("UICorner")({
						CornerRadius = UDim.new(0.5, 0),
					}),
					TextLabel(healthLabelProps),
					New("Frame")({
						Name = "HealthBar",
						Position = UDim2.fromScale(1, 0.5),
						AnchorPoint = Vector2.new(1, 0.5),
						Size = Spring(Computed(function()
							local sizeX = self._health:get() / 100
							return UDim2.fromScale(sizeX, 1)
						end)),
						BackgroundTransparency = 0,
						ZIndex = 3,
						BackgroundColor3 = Color3.fromRGB(0, 255, 0),
						[Children] = {
							New("UICorner")({
								CornerRadius = UDim.new(0.5, 0),
							}),
						},
					}),
				},
			}),
		},
	})
end

function Monster:RemoveGUI()
	local gui = self.Instance:WaitForChild("Head"):FindFirstChild("Monster")
	if not gui then
		return
	end
	gui:Destroy()
end

-- Runs when tag is disconnected from object
function Monster:Stop() end

return Monster
