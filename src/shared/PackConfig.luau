--!strict
-- Pack economy tuning. Shared for display; every roll and validation happens
-- on the server.

local PackConfig = {
	-- Tier-1 (Greek) pack price. Every rung above multiplies by CLIMB_RATE.
	BASE_PRICE = 100,

	-- R, the master climb dial. Pack price AND card income both scale by
	-- R^(tier-1), so each page earns close enough to accrue the next rung —
	-- per-rung climb time stays roughly constant no matter how big the
	-- absolute numbers get (tier 16 lands in the trillions; that's fine).
	-- Raise R for a steeper, flashier ladder; income tracks price so no
	-- rung ever becomes unreachable.
	CLIMB_RATE = 5,

	-- In-pack card odds by rarity (per card, not per bucket). Fixed — no
	-- stat ever touches these; Luck/MutationLuck only shape what appears on
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

-- Coin price of an UNMODIFIED pack for a page tier.
function PackConfig.pagePrice(tier: number): number
	return PackConfig.BASE_PRICE * PackConfig.CLIMB_RATE ^ (tier - 1)
end

-- Income multiplier every card on a page tier carries (tracks pagePrice so
-- the rungs stay climbable).
function PackConfig.tierIncomeMult(tier: number): number
	return PackConfig.CLIMB_RATE ^ (tier - 1)
end

-- Full belt price of an offer: page price × the modifier's multiplier.
-- A modifier scales the pack's cost by exactly what it'll scale the card's
-- income — money-neutral on paper, but the boost is permanent and skips the
-- leveling grind (that's the allure, and why lucky rolls can't shortcut the
-- ladder).
function PackConfig.offerPrice(tier: number, modifierMult: number): number
	return math.floor(PackConfig.pagePrice(tier) * modifierMult + 0.5)
end

return PackConfig
