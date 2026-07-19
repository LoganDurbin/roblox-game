--!strict
-- Pack modifiers ("mutations"): rolled server-side when a pack spawns on the
-- belt. The modifier rides the pack, and the card opened from it inherits the
-- income multiplier permanently (best-wins per card — an equal or worse pull
-- never downgrades a card's stored modifier).
--
-- Weights are the pre-upgrade defaults (out of 10000). The MutationLuck stat
-- multiplies every non-Mortal weight, shifting rolls up the ladder. Higher
-- tiers also take longer to open once placed — the wait is part of the chase
-- (and gives timer-skip products something to sell later).

export type Modifier = {
	id: string,
	name: string,
	rank: number, -- ladder position; higher beats lower for best-wins
	mult: number, -- income multiplier applied to the opened card
	weight: number, -- spawn weight out of 10000 at MutationLuck 1
	openTime: number, -- seconds a placed pack takes before it can be opened
	color: Color3, -- display color (belt, inventory, index)
}

local list: { Modifier } = {
	{
		id = "mortal",
		name = "Mortal",
		rank = 1,
		mult = 1,
		weight = 9000, -- 90%
		openTime = 15,
		color = Color3.fromRGB(200, 200, 200),
	},
	{
		id = "blessed",
		name = "Blessed",
		rank = 2,
		mult = 2,
		weight = 600, -- 6%
		openTime = 45,
		color = Color3.fromRGB(150, 230, 150),
	},
	{
		id = "hallowed",
		name = "Hallowed",
		rank = 3,
		mult = 5,
		weight = 250, -- 2.5%
		openTime = 90,
		color = Color3.fromRGB(255, 215, 90),
	},
	{
		id = "divine",
		name = "Divine",
		rank = 4,
		mult = 10,
		weight = 100, -- 1%
		openTime = 180,
		color = Color3.fromRGB(90, 220, 255),
	},
	{
		id = "ascendant",
		name = "Ascendant",
		rank = 5,
		mult = 20,
		weight = 40, -- 0.4%
		openTime = 360,
		color = Color3.fromRGB(200, 110, 255),
	},
	{
		id = "celestial",
		name = "Celestial",
		rank = 6,
		mult = 50,
		weight = 9, -- 0.09%
		openTime = 720,
		color = Color3.fromRGB(120, 140, 255),
	},
	{
		id = "primordial",
		name = "Primordial",
		rank = 7,
		mult = 75,
		weight = 1, -- 0.01%
		openTime = 1200,
		color = Color3.fromRGB(255, 80, 80),
	},
}

local byId: { [string]: Modifier } = {}
for _, mod in list do
	byId[mod.id] = mod
end

return {
	list = list, -- rank order, Mortal first
	byId = byId,
}
