local sessionData = {}

sessionData.MobsData = {}
sessionData.PlayersData = {}
sessionData.ChasingMobs = {}

function sessionData.CleanupPlayerData(player)
	
	local playerUserId = "Player_" .. player.UserId
	sessionData.PlayersData[playerUserId] = nil
	sessionData.PlayersData[player.Name] = nil
	
	for key,v in pairs(sessionData) do
		if type(v) == 'function' then continue end 
		v[playerUserId] = nil
		v[player.Name] = nil
	end
end

return sessionData