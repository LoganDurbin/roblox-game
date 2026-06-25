--!strict
local Players = game:GetService("Players")
local PlayerData = require(script.Parent.PlayerData)

PlayerData.Init()

-- DEMO ONLY: passive income so you can watch the client HUD tick up.
-- Delete this loop once real generators exist.
while true do
	task.wait(1)
	for _, player in Players:GetPlayers() do
		PlayerData.Increment(player, "Cash", 5)
	end
end