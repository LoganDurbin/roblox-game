--!strict
-- Belt timing. Shared so the client animates offers with the same clock the
-- server enforces. Pack pricing lives in PackConfig; modifier odds live in
-- ModifierCatalog.

local ConveyorConfig = {
	-- A new pack offer spawns on each player's belt this often (seconds).
	SPAWN_INTERVAL = 2,

	-- How long an offer takes to slide across the belt. Once elapsed, the
	-- offer expires server-side and can no longer be bought.
	-- TRAVEL_TIME / SPAWN_INTERVAL = packs visible at once (7.5 by design:
	-- unaffordable high-modifier packs drifting past are intentional — they
	-- seed the Robux instant-unlock temptation, planned as a dev product).
	TRAVEL_TIME = 15,
}

return ConveyorConfig
