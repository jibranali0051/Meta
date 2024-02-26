-- Services
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts

-- Packages
local Packages: Folder = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

-- Modules
local Modules = StarterPlayerScripts.Modules
local Utility = Modules.Utility
local RayModule = require(Utility.RayModule)

local HitBox = {}

function HitBox:GetSquarePoints(CF, x, y)
	local hSizex, hSizey = 2, 5
	local splitx, splity = 1 + math.floor(x / hSizex), 1 + math.floor(y / hSizey)
	local studPerPointX = x / splitx
	local studPerPointY = y / splity

	local startCFrame = CF * CFrame.new(-x / 2 - studPerPointX / 2, -y / 2 - studPerPointY / 2, 0)
	local points = { CF }

	for x = 1, splitx do
		for y = 1, splity do
			points[#points + 1] = startCFrame * CFrame.new(studPerPointX * x, studPerPointY * y, 0)
		end
	end

	return points
end

function HitBox:CastProjectileHitbox(Data)
	local Direction = Data.Direction
	local Velocity = Data.Velocity
	local Lifetime = Data.Lifetime
	local Iterations = Data.Iterations
	local Visualize = Data.Visualize
	local VisuaLizeColor = Data.VisualizeColor
	local Points = Data.Points

	local Callback = Data.Callback or function()
		warn("There was no function provided for projectile hitbox")
	end

	local Ignore = Data.Ignore or {}
	local WhiteList = Data.WhiteList
	local Start = os.clock()

	task.spawn(function()
		local LastCast = nil
		local Interception = false
		local CastInterval = Lifetime / Iterations

		while os.clock() - Start < Lifetime and not Interception do
			local Delta = LastCast and os.clock() - LastCast or CastInterval

			if not LastCast or Delta >= CastInterval then
				local Distance = Velocity * Delta

				LastCast = os.clock()

				for Index, Point in ipairs(Points) do
					local StartPosition = Point.Position
					local EndPosition = StartPosition + Direction * Distance

					local Result

					if WhiteList then
						Result = RayModule:Cast(
							StartPosition,
							EndPosition,
							WhiteList,
							Enum.RaycastFilterType.Whitelist,
							true
						)
					else
						Result =
							RayModule:Cast(StartPosition, EndPosition, Ignore, Enum.RaycastFilterType.Blacklist, true)
					end

					if Visualize then
						RayModule:Visualize(StartPosition, EndPosition, VisuaLizeColor)
					end

					if Result then
						Callback(Result)

						if
							Result.Instance:FindFirstAncestorOfClass("Model"):FindFirstChild("HumanoidRootPart") ~= nil
						then
							Interception = true
							break
						end
					end
				end
			end

			game:GetService("RunService").Stepped:Wait()
		end
	end)
end

return HitBox
