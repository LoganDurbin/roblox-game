--!strict
-- Pack economy tuning. Shared for display; every roll and validation happens
-- on the server.

local PackConfig = {
	-- Flat Coin price for any page pack on the belt. A modifier on the pack
	-- does NOT change the price — modifiers are a lucky roll at the same
	-- cost (jackpot feel). Premium/priced tiers can come later as products.
	PACK_PRICE = 100,

	-- In-pack card odds by rarity (per card, not per bucket). Fixed — Luck
	-- and MutationLuck never touch these; they only shape what appears on
	-- the belt. With a 4C/2R/2E/1L page this lands at roughly:
	-- each Common ~20%, each Rare ~6%, each Epic ~3%, the Legendary ~1%.
	RARITY_WEIGHT = {
		Common = 20,
		Rare = 6,
		Epic = 3,
		Legendary = 1,
	},

	-- Max seconds of income a card can hold before it stops accruing and
	-- must be claimed. Flat for now; becomes an upgradeable stat in M3.
	STORAGE_CAP_SECONDS = 3600, -- 1 hour

	-- How many packs can sit placed (opening) at once. Flat for now;
	-- becomes an upgradeable stat in M3.
	PLACEMENT_LIMIT = 4,
}

return PackConfig
