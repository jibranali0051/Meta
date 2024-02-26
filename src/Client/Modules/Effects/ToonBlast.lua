local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Assets
local Assets = ReplicatedStorage.Assets
local vfx = Assets.VFX.ToonBlast

local effectDuration = 1

return function(source, target)
	local connection = nil

	local targetRootPart = if target:IsA("Model")
		then target:FindFirstChild("HumanoidRootPart")
		else target.Character:FindFirstChild("HumanoidRootPart")

	local effect = vfx:Clone()
	effect.CFrame = targetRootPart.CFrame + targetRootPart.CFrame.LookVector * 2
	effect.Parent = targetRootPart

	local function onStepped(time, deltaTime)
		if effect then
			effect.Position = targetRootPart.CFrame.Position + targetRootPart.CFrame.LookVector * 2
		else
			connection:Disconnect()
		end
	end

	connection = RunService.Stepped:Connect(onStepped)
	Debris:AddItem(effect, effectDuration)
	task.delay(effectDuration, function()
		connection:Disconnect()
	end)
end
