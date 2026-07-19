--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local CardCatalog = require(Shared:WaitForChild("CardCatalog"))
local SummonCatalog = require(Shared:WaitForChild("SummonCatalog"))
local PlayerData = require(script.Parent.PlayerData)

local Summon = {}

-- One RNG stream for all summons. Rolls happen HERE, never on the client —
-- a client-rolled gacha gets re-rolled/duped instantly.
local rng = Random.new()

local function rollPool(banner: SummonCatalog.Banner): string
	local pick = rng:NextNumber() * banner.totalWeight
	local acc = 0
	for _, entry in banner.pool do
		acc += entry.weight
		if pick < acc then
			return entry.id
		end
	end
	-- Float-edge fallback: last entry.
	return banner.pool[#banner.pool].id
end

local function trySummon(player: Player, bannerId: any)
	-- 1. Validate the input itself. The client can send anything.
	if type(bannerId) ~= "string" then
		return
	end
	local banner = SummonCatalog[bannerId]
	if not banner then
		Remotes.Notify:FireClient(player, "That banner doesn't exist.")
		return
	end

	-- 2. Read authoritative state.
	local data = PlayerData.Get(player)
	if not data then
		return
	end

	-- 3. Validate affordability.
	if data.Coins < banner.cost then
		Remotes.Notify:FireClient(player, `Not enough Coins ({banner.cost} needed).`)
		return
	end

	-- 4. Roll, then apply atomically — no yields between the check above and
	--    here, or two rapid summons could both pass step 3 and overspend.
	local cardId = rollPool(banner)
	local card = CardCatalog[cardId]

	local isNew = false
	PlayerData.Mutate(player, function(d)
		d.Coins -= banner.cost
		local copies = (d.Cards[cardId] or 0) + 1
		d.Cards[cardId] = copies
		isNew = copies == 1
	end)

	if isNew then
		Remotes.Notify:FireClient(player, `NEW! {card.name} ({card.rarity})`)
	else
		Remotes.Notify:FireClient(player, `{card.name} ({card.rarity}) leveled up!`)
	end
end

function Summon.Init()
	Remotes.Summon.OnServerEvent:Connect(trySummon)
end

return Summon
