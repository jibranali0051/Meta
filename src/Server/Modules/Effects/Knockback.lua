local RunService = game:GetService("RunService")

local function QuadraticBezier(t, p0, p1, p2)
	return (1 - t) ^ 2 * p0 + 2 * (1 - t) * t * p1 + t ^ 2 * p2
end

return function(source, target)
	local attackerRootPart = if source:IsA("Model")
		then source:FindFirstChild("HumanoidRootPart")
		else source.Character:FindFirstChild("HumanoidRootPart")
	local targetRootPart = if target:IsA("Model")
		then target:FindFirstChild("HumanoidRootPart")
		else target.Character:FindFirstChild("HumanoidRootPart")
	local knockbackTime = 0.7
	local height = 5
	local distance = 30
	local kbCFrame = CFrame.new(
		targetRootPart.CFrame.Position,
		attackerRootPart.CFrame.Position + attackerRootPart.CFrame.LookVector.Unit * 400
	)

	local targetHumanoid = targetRootPart.Parent.Humanoid
	local attackerHumanoid = attackerRootPart.Parent:FindFirstChild("Humanoid")

	local targetHeight = targetHumanoid.HipHeight + targetRootPart.Size.Y * 0.5
	local attackerHeight = attackerHumanoid.HipHeight + attackerRootPart.Size.Y * 0.5

	local basePosition = targetRootPart.CFrame
	local curvePosition = CFrame.new(kbCFrame * Vector3.new(0, height + targetHeight - attackerHeight, -distance / 2))
	local targetPosition = CFrame.new(kbCFrame * Vector3.new(0, attackerHeight - targetHeight, -distance))

	local totalTime = 0
	local connection = nil

	local kbAnimation = workspace.Animations.GettingKnockback

	local kbAnimationTrack = targetHumanoid:LoadAnimation(kbAnimation)
	kbAnimationTrack.Name = "Hit"
	kbAnimationTrack:Play()

	task.delay(0.1, function()
		kbAnimationTrack:AdjustSpeed(0)
	end)

	task.delay(knockbackTime, function()
		kbAnimationTrack:Stop()
	end)

	local function onStepped(time, deltaTime)
		if targetRootPart == nil then
			connection:Disconnect()
			return
		end

		if targetRootPart.Parent == nil then
			connection:Disconnect()
			return
		end

		local actualPosition = QuadraticBezier(
			totalTime / knockbackTime,
			basePosition.Position,
			curvePosition.Position,
			targetPosition.Position
		)

		totalTime = totalTime + deltaTime

		local nextPosition = QuadraticBezier(
			(totalTime + 0.05) / knockbackTime,
			basePosition.Position,
			curvePosition.Position,
			targetPosition.Position
		)

		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		raycastParams.FilterDescendantsInstances = {
			targetRootPart.Parent,
		}

		local hitPoint1 =
			workspace:Raycast(actualPosition, CFrame.new(actualPosition, nextPosition).LookVector * 0.5, raycastParams)
		local hitPoint2 =
			workspace:Raycast(actualPosition, CFrame.new(actualPosition, nextPosition).LookVector * 0.1, raycastParams)
		local hitPoint3 =
			workspace:Raycast(actualPosition, CFrame.new(actualPosition, nextPosition).LookVector * 1, raycastParams)

		local hit1 = workspace:Raycast(targetRootPart.Position, Vector3.new(0, -(targetHeight - 0.1), 0), raycastParams)
		local hit2 = workspace:Raycast(targetRootPart.Position, Vector3.new(0, 0, -4), raycastParams)
		local hit3 = workspace:Raycast(targetRootPart.Position, Vector3.new(0, 0, 4), raycastParams)
		local hit4 = workspace:Raycast(targetRootPart.Position, Vector3.new(4, 0, 0), raycastParams)
		local hit5 = workspace:Raycast(targetRootPart.Position, Vector3.new(-4, 0, 0), raycastParams)

		-- if hit1 or hit2 or hit3 or hit4 or hit5 or hitPoint1 or hitPoint2 or hitPoint3 then

		-- 	if targetRootPart:FindFirstChild("Knockback") then
		-- 		targetRootPart:FindFirstChild("Knockback"):Destroy()
		-- 	end

		-- 	connection:Disconnect()

		-- 	if kbAnimationTrack ~= nil then
		-- 		kbAnimationTrack:AdjustSpeed(2)
		-- 		task.delay(0.1, function()
		-- 			kbAnimationTrack:Stop()
		-- 		end)
		-- 	end

		-- 	return
		-- end

		if totalTime >= knockbackTime then
			connection:Disconnect()

			kbAnimationTrack:AdjustSpeed(1)
			task.delay(0.1, function()
				kbAnimationTrack:Stop()
			end)

			return
		end

		targetRootPart.CFrame = CFrame.new(nextPosition)
			* CFrame.Angles(
				math.rad(targetRootPart.Orientation.X),
				math.rad(targetRootPart.Orientation.Y),
				math.rad(targetRootPart.Orientation.Z)
			)
	end

	connection = RunService.Stepped:Connect(onStepped)
end
