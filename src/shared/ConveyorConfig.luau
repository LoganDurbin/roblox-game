--!strict
-- Card-shop conveyor tuning. Shared so the client can render the belt with
-- the same timings/prices the server enforces. The RNG roll itself only ever
-- happens on the server (Conveyor.luau).

local ConveyorConfig = {
	-- A new card offer spawns on each player's belt this often (seconds).
	SPAWN_INTERVAL = 3,

	-- How long an offer takes to slide across the belt. Once elapsed, the
	-- offer expires server-side and can no longer be bought.
	TRAVEL_TIME = 12,

	-- Buy price per rarity.
	PRICE = {
		Common = 50,
		Rare = 150,
		Epic = 400,
		Legendary = 1200,
	},

	-- Base spawn weight per rarity. A player's Luck stat multiplies the
	-- non-Common weights, shifting rolls toward rarer cards.
	WEIGHT = {
		Common = 70,
		Rare = 20,
		Epic = 8,
		Legendary = 2,
	},
}

return ConveyorConfig
