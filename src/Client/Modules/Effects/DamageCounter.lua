local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function QuadraticBezier(t, p0, p1, p2)
	return (1 - t) ^ 2 * p0 + 2 * (1 - t) * t * p1 + t ^ 2 * p2
end

return function(source,target, data)
	local head = target:FindFirstChild("Head")

	if not head then
		return
	end

	local cFrameX = math.random(-12, 12)

	--Other distance
	local cFrameY = math.random(0, 4)

	local stickPart = Instance.new("Part", workspace.Debris)
	stickPart.Name = "GetDamage"
	stickPart.Transparency = 1
	stickPart.Anchored = true
	stickPart.CanCollide = false

	local damagePlayer = data.Damage

	--Start point
	local begpoint = Vector3.new(0, 3, 0)

	--Middle point
	local curvepoint = Vector3.new(cFrameX, 6, cFrameY)

	--End point
	local endpoint = Vector3.new(cFrameX, -2, cFrameY)

	local gui = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Gui").DamageCounterGui:Clone()
	gui.Parent = stickPart
	gui.TextLabel.Text = damagePlayer

	local hitCFrame = head.CFrame

	Debris:AddItem(stickPart, 1.5)

	for t = 0, 1, 0.025 do
		RunService.Heartbeat:Wait()
		local targetPosition = CFrame.new(QuadraticBezier(t, begpoint, curvepoint, endpoint))
		stickPart.CFrame = hitCFrame * targetPosition
	end

	local tweenInfo = TweenInfo.new(0.4)

	if gui:FindFirstChild("TextLabel") then
		local tween =
			TweenService:Create(gui.TextLabel, tweenInfo, { TextTransparency = 1, TextStrokeTransparency = 1 })

		tween:Play()

		tween.Completed:Wait()

		stickPart:Destroy()
	else
		stickPart:Destroy()
	end
end
