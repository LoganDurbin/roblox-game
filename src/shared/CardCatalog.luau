--!strict
-- Card definitions for the index. Roster is a placeholder starter set:
-- 5 cards per page (2 Common, 1 Rare, 1 Epic, 1 Legendary). Expand freely.
-- NOTE: names drawn from living traditions (Hindu, Yoruba, Aboriginal, etc.)
-- should get a cultural-sensitivity pass before launch.

export type Card = {
	id: string,
	name: string,
	page: string, -- PageCatalog id
	rarity: string, -- "Common" | "Rare" | "Epic" | "Legendary"
	baseIncome: number, -- Coins/sec at 1 copy
}

-- Base income per rarity, applied uniformly for now (tune later).
local INCOME = { Common = 1, Rare = 3, Epic = 8, Legendary = 20 }

-- { id, name, page, rarity }
local defs: { { string } } = {
	-- Greek
	{ "hermes", "Hermes", "greek", "Common" },
	{ "apollo", "Apollo", "greek", "Common" },
	{ "athena", "Athena", "greek", "Rare" },
	{ "poseidon", "Poseidon", "greek", "Epic" },
	{ "zeus", "Zeus", "greek", "Legendary" },
	-- Norse
	{ "heimdall", "Heimdall", "norse", "Common" },
	{ "baldur", "Baldur", "norse", "Common" },
	{ "freya", "Freya", "norse", "Rare" },
	{ "thor", "Thor", "norse", "Epic" },
	{ "odin", "Odin", "norse", "Legendary" },
	-- Egyptian
	{ "bastet", "Bastet", "egyptian", "Common" },
	{ "thoth", "Thoth", "egyptian", "Common" },
	{ "anubis", "Anubis", "egyptian", "Rare" },
	{ "horus", "Horus", "egyptian", "Epic" },
	{ "ra", "Ra", "egyptian", "Legendary" },
	-- Hindu
	{ "ganesha", "Ganesha", "hindu", "Common" },
	{ "hanuman", "Hanuman", "hindu", "Common" },
	{ "saraswati", "Saraswati", "hindu", "Rare" },
	{ "vishnu", "Vishnu", "hindu", "Epic" },
	{ "shiva", "Shiva", "hindu", "Legendary" },
	-- Celtic
	{ "brigid", "Brigid", "celtic", "Common" },
	{ "cernunnos", "Cernunnos", "celtic", "Common" },
	{ "lugh", "Lugh", "celtic", "Rare" },
	{ "morrigan", "The Morrigan", "celtic", "Epic" },
	{ "dagda", "The Dagda", "celtic", "Legendary" },
	-- Roman
	{ "mercury", "Mercury", "roman", "Common" },
	{ "venus", "Venus", "roman", "Common" },
	{ "mars", "Mars", "roman", "Rare" },
	{ "neptune", "Neptune", "roman", "Epic" },
	{ "jupiter", "Jupiter", "roman", "Legendary" },
	-- Japanese
	{ "inari", "Inari", "japanese", "Common" },
	{ "tsukuyomi", "Tsukuyomi", "japanese", "Common" },
	{ "susanoo", "Susanoo", "japanese", "Rare" },
	{ "raijin", "Raijin", "japanese", "Epic" },
	{ "amaterasu", "Amaterasu", "japanese", "Legendary" },
	-- Chinese
	{ "nezha", "Nezha", "chinese", "Common" },
	{ "change", "Chang'e", "chinese", "Common" },
	{ "sun-wukong", "Sun Wukong", "chinese", "Rare" },
	{ "guanyin", "Guanyin", "chinese", "Epic" },
	{ "jade-emperor", "Jade Emperor", "chinese", "Legendary" },
	-- Aztec
	{ "xochiquetzal", "Xochiquetzal", "aztec", "Common" },
	{ "tlaloc", "Tlaloc", "aztec", "Common" },
	{ "tezcatlipoca", "Tezcatlipoca", "aztec", "Rare" },
	{ "huitzilopochtli", "Huitzilopochtli", "aztec", "Epic" },
	{ "quetzalcoatl", "Quetzalcoatl", "aztec", "Legendary" },
	-- Mayan
	{ "ix-chel", "Ix Chel", "mayan", "Common" },
	{ "chaac", "Chaac", "mayan", "Common" },
	{ "camazotz", "Camazotz", "mayan", "Rare" },
	{ "kukulkan", "Kukulkan", "mayan", "Epic" },
	{ "itzamna", "Itzamna", "mayan", "Legendary" },
	-- Slavic
	{ "mokosh", "Mokosh", "slavic", "Common" },
	{ "svarog", "Svarog", "slavic", "Common" },
	{ "morana", "Morana", "slavic", "Rare" },
	{ "veles", "Veles", "slavic", "Epic" },
	{ "perun", "Perun", "slavic", "Legendary" },
	-- Yoruba
	{ "oshun", "Oshun", "yoruba", "Common" },
	{ "eshu", "Eshu", "yoruba", "Common" },
	{ "ogun", "Ogun", "yoruba", "Rare" },
	{ "yemoja", "Yemoja", "yoruba", "Epic" },
	{ "shango", "Shango", "yoruba", "Legendary" },
	-- Polynesian
	{ "hina", "Hina", "polynesian", "Common" },
	{ "tane", "Tane", "polynesian", "Common" },
	{ "ku", "Ku", "polynesian", "Rare" },
	{ "pele", "Pele", "polynesian", "Epic" },
	{ "maui", "Maui", "polynesian", "Legendary" },
	-- Persian
	{ "anahita", "Anahita", "persian", "Common" },
	{ "atar", "Atar", "persian", "Common" },
	{ "mithra", "Mithra", "persian", "Rare" },
	{ "zurvan", "Zurvan", "persian", "Epic" },
	{ "ahura-mazda", "Ahura Mazda", "persian", "Legendary" },
	-- Inuit
	{ "nanook", "Nanook", "inuit", "Common" },
	{ "pinga", "Pinga", "inuit", "Common" },
	{ "malina", "Malina", "inuit", "Rare" },
	{ "torngarsuk", "Torngarsuk", "inuit", "Epic" },
	{ "sedna", "Sedna", "inuit", "Legendary" },
	-- Australian Aboriginal
	{ "tiddalik", "Tiddalik", "aboriginal", "Common" },
	{ "yara-ma-yha-who", "Yara-ma-yha-who", "aboriginal", "Common" },
	{ "bunjil", "Bunjil", "aboriginal", "Rare" },
	{ "baiame", "Baiame", "aboriginal", "Epic" },
	{ "rainbow-serpent", "Rainbow Serpent", "aboriginal", "Legendary" },
}

local Catalog: { [string]: Card } = {}
for _, d in defs do
	local id, name, page, rarity = d[1], d[2], d[3], d[4]
	Catalog[id] = {
		id = id,
		name = name,
		page = page,
		rarity = rarity,
		baseIncome = INCOME[rarity] :: number,
	}
end

return Catalog
