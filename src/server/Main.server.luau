--!strict
local Players = game:GetService("Players")
local PlayerData = require(script.Parent.PlayerData)
local Shop = require(script.Parent.Shop)

PlayerData.Init()
Shop.Init()

-- DEMO ONLY: passive income so you have Cash to spend.
while true do
	task.wait(1)
	for _, player in Players:GetPlayers() do
		PlayerData.Increment(player, "Cash", 5)
	end
end