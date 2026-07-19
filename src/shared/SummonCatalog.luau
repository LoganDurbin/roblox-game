--!strict
-- Summon banners. Pools are built at require time from CardCatalog using
-- per-rarity weights. Shared so the client can DISPLAY costs/odds; the roll
-- itself only ever happens on the server (Summon.luau).

local CardCatalog = require(script.Parent.CardCatalog)

export type PoolEntry = { id: string, weight: number }
export type Banner = {
	id: string,
	name: string,
	cost: number, -- Coins per summon
	pool: { PoolEntry },
	totalWeight: number,
}

-- Relative pull weight per rarity (per card, not per bucket).
local RARITY_WEIGHT = { Common = 70, Rare = 20, Epic = 8, Legendary = 2 }

local function buildPool(filter: (CardCatalog.Card) -> boolean): ({ PoolEntry }, number)
	local pool: { PoolEntry } = {}
	local total = 0
	for _, card in CardCatalog do
		if filter(card) then
			local weight = RARITY_WEIGHT[card.rarity] :: number
			table.insert(pool, { id = card.id, weight = weight })
			total += weight
		end
	end
	-- Deterministic order (map iteration isn't), so odds display is stable.
	table.sort(pool, function(a, b)
		return a.id < b.id
	end)
	return pool, total
end

local standardPool, standardTotal = buildPool(function()
	return true -- every card, all pages
end)

local Catalog: { [string]: Banner } = {
	standard = {
		id = "standard",
		name = "Standard Summon",
		cost = 100,
		pool = standardPool,
		totalWeight = standardTotal,
	},
}

return Catalog
