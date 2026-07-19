--!strict
-- Income claims. Cards accrue Coins lazily (see CardStats); claiming banks
-- rate × min(elapsed, storage cap) into Coins and resets the card's clock.
-- Auto-Collect (M3) will simply drive these same paths server-side.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local CardStats = require(Shared:WaitForChild("CardStats"))
local PlayerData = require(script.Parent.PlayerData)

local Claim = {}

local function tryClaimCard(player: Player, cardId: any)
	if type(cardId) ~= "string" then
		return
	end
	local data = PlayerData.Get(player)
	if not data or not data.Cards[cardId] then
		return
	end

	local now = os.time()
	PlayerData.Mutate(player, function(d)
		local entry = d.Cards[cardId]
		if not entry then
			return
		end
		local completionMult = CardStats.completionMult(d.Cards)
		local rate = CardStats.rateFor(cardId, entry, completionMult)
		d.Coins += CardStats.pendingFor(rate, entry, now)
		entry.lastClaimAt = now
	end)
end

local function tryClaimAll(player: Player)
	local data = PlayerData.Get(player)
	if not data then
		return
	end

	local now = os.time()
	local banked = 0
	PlayerData.Mutate(player, function(d)
		local completionMult = CardStats.completionMult(d.Cards)
		for cardId, entry in d.Cards do
			local rate = CardStats.rateFor(cardId, entry, completionMult)
			banked += CardStats.pendingFor(rate, entry, now)
			entry.lastClaimAt = now
		end
		d.Coins += banked
	end)

	if banked > 0 then
		Remotes.Notify:FireClient(player, `Collected {math.floor(banked)} Coins!`)
	end
end

function Claim.Init()
	Remotes.ClaimCard.OnServerEvent:Connect(tryClaimCard)
	Remotes.ClaimAll.OnServerEvent:Connect(tryClaimAll)
end

return Claim
