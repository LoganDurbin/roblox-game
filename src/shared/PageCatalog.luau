--!strict
-- Index pages (collection themes). `order` controls display order in the
-- index UI. `completionBonus` is a multiplicative income bonus granted while
-- every card on the page is owned (computed live from Cards, no claim state).

export type Page = {
	id: string,
	name: string,
	order: number,
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
		completionBonus = 1.25, -- uniform for now; tune per page later
	}
end

return Catalog
