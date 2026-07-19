--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CardStats = require(Shared:WaitForChild("CardStats"))
local PlayerData = require(script.Parent.PlayerData)

local TICK_SECONDS = 1

local Income = {}

function Income.Init()
	-- 1 Hz payout: each player's collection income (CardStats.totalIncome
	-- already folds in completed-page bonuses). Players with no cards earn 0.
	task.spawn(function()
		while true do
			task.wait(TICK_SECONDS)
			for _, player in Players:GetPlayers() do
				local data = PlayerData.Get(player)
				if data and data.Cards then
					local perSecond = CardStats.totalIncome(data.Cards)
					if perSecond > 0 then
						PlayerData.Increment(player, "Coins", perSecond * TICK_SECONDS)
					end
				end
			end
		end
	end)
end

return Income
