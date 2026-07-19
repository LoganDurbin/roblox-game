--!strict
-- Index pages (collection themes). Listed in POPULARITY order — that order
-- IS the progression ladder: `tier` (= list position) drives pack price and
-- card income scaling (see PackConfig.CLIMB_RATE), so Greek is the cheap
-- starter rung and each later page costs/earns CLIMB_RATE× the previous.
-- `order` doubles as display order in the index UI. `completionBonus` is a
-- multiplicative income bonus granted while every card on the page is owned
-- (computed live from Cards, no claim state).

export type Page = {
	id: string,
	name: string,
	order: number,
	tier: number, -- ladder rung (1 = starter); scales pack price + income
	completionBonus: number,
}

local defs: { { any } } = {
	{ "greek", "Greek" },
	{ "norse", "Norse" },
	{ "egyptian", "Egyptian" },
	{ "hindu", "Hindu" },
	{ "celtic", "Celtic" },
	{ "roman", "Roman" },
	{ "japanese", "Japanese" },
	{ "chinese", "Chinese" },
	{ "aztec", "Aztec" },
	{ "mayan", "Mayan" },
	{ "slavic", "Slavic" },
	{ "yoruba", "Yoruba" },
	{ "polynesian", "Polynesian" },
	{ "persian", "Persian" },
	{ "inuit", "Inuit" },
	{ "aboriginal", "Australian Aboriginal" },
}

local Catalog: { [string]: Page } = {}
for i, d in defs do
	Catalog[d[1]] = {
		id = d[1],
		name = d[2],
		order = i,
		tier = i,
		completionBonus = 1.25, -- uniform for now; tune per page later
	}
end

return Catalog
