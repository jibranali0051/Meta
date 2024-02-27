-- create collision groups here
game:GetService("PhysicsService"):RegisterCollisionGroup("Players")
game:GetService("PhysicsService"):RegisterCollisionGroup("Effects")


game:GetService("PhysicsService"):CollisionGroupSetCollidable("Players", "Players", false)
game:GetService("PhysicsService"):CollisionGroupSetCollidable("Players", "Effects", false)



local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Packages: Folder = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local ReplicatedTweenign = require(game:GetService("ReplicatedStorage").ReplicatedTweening)
-- Constants
local START_TIME: number = workspace:GetServerTimeNow()



Knit.AddServicesDeep(ServerStorage:WaitForChild("Services"))



Knit.Start({
    Middleware = {
        Inbound = { }
    }}):catch(warn):finally(function()
    -- Initialize Components
    for _, component: ModuleScript? in ipairs( ServerStorage:WaitForChild("Components"):GetChildren() ) do
        if not component:IsA("ModuleScript") then continue end
        require(component)
    end

   
    -- Display how long it took to load the server
    local msTimeDifference: number = math.round((workspace:GetServerTimeNow() - START_TIME) * 1000)
    print(`✅ Server has loaded! Took ~{msTimeDifference}ms`)
end)